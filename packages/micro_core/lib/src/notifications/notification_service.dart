import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:meta/meta.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../util/civil_date.dart';
import '../util/micro_log.dart';

enum MicroImportance { low, normal, high }

/// Un canale di notifica Android.
@immutable
class MicroNotificationChannel {
  const MicroNotificationChannel({
    required this.id,
    required this.name,
    required this.description,
    this.importance = MicroImportance.normal,
    this.enableVibration = true,
    this.playSound = true,
  });

  final String id;
  final String name;
  final String description;
  final MicroImportance importance;
  final bool enableVibration;
  final bool playSound;

  Importance get _androidImportance => switch (importance) {
    MicroImportance.low => Importance.low,
    MicroImportance.normal => Importance.defaultImportance,
    MicroImportance.high => Importance.high,
  };

  AndroidNotificationChannel toAndroid() => AndroidNotificationChannel(
    id,
    name,
    description: description,
    importance: _androidImportance,
    enableVibration: enableVibration,
    playSound: playSound,
  );
}

/// Una notifica da pianificare.
@immutable
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.localWhen,
    required this.title,
    required this.body,
    required this.channelId,
    this.payload,
    this.exact = false,
  });

  final int id;
  final DateTime localWhen;
  final String title;
  final String body;
  final String channelId;
  final String? payload;

  /// `true` solo dove l'orario preciso **è** la funzione.
  final bool exact;
}

enum PermissionOutcome { granted, denied, permanentlyDenied, notRequired }

/// Le notifiche locali delle MicroApps.
///
/// Implementa ADR-009: finestra scorrevole, ripianificazione a ogni resume, e un tetto al
/// numero di notifiche pendenti.
class NotificationService {
  NotificationService._(this._plugin, this._channels);

  /// Tetto alle notifiche pendenti per app.
  ///
  /// ⚑ Android ha un limite pratico sugli alarm pendenti (circa 500) e non garantisce
  /// che sopravvivano al riavvio senza receiver. 64 su 60 giorni coprono il caso d'uso
  /// reale, cioè una raccolta ogni due giorni, restando lontanissimi dal limite.
  static const int maxPending = 64;

  final FlutterLocalNotificationsPlugin _plugin;
  final List<MicroNotificationChannel> _channels;
  final StreamController<String> _taps = StreamController<String>.broadcast();
  String? _launchPayload;

  /// I payload delle notifiche toccate mentre l'app è viva.
  Stream<String> get taps => _taps.stream;

  static Future<NotificationService> create({
    required String androidIconResource,
    required List<MicroNotificationChannel> channels,
    FlutterLocalNotificationsPlugin? plugin,
  }) async {
    final instance = plugin ?? FlutterLocalNotificationsPlugin();

    // ☠ Trappola del fuso orario: senza inizializzare il database dei fusi e senza
    // impostare quello locale, `zonedSchedule` interpreta tutto come UTC. In Italia
    // d'estate le notifiche arrivano due ore prima, e per un promemoria delle 20:00
    // significa alle 18:00. Il test `timezone_test.dart` lo verifica.
    tz_data.initializeTimeZones();
    try {
      // getLocalTimezone restituisce un TimezoneInfo: serve l'identificatore IANA,
      // per esempio "Europe/Rome", non l'oggetto intero.
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Exception catch (error) {
      MicroLog.w('fuso locale non determinabile, uso UTC', error: error);
    }

    final service = NotificationService._(instance, channels);

    await instance.initialize(
      settings: InitializationSettings(
        android: AndroidInitializationSettings(androidIconResource),
        // ☠ Senza questa riga su iOS non arriva **nessuna** notifica, e non lo dice
        // nessuno: `InitializationSettings` accetta i soli parametri Android senza
        // lamentarsi, l'app parte, e il difetto si manifesta solo la sera in cui il
        // promemoria doveva suonare.
        //
        // ⚑ I tre permessi sono chiesti a `false` di proposito. Lasciandoli a `true`
        // iOS mostrerebbe il foglio di sistema **al primo avvio in assoluto**, prima che
        // l'utente abbia visto cosa fa l'app e quindi prima che abbia un motivo per dire
        // di sì. Un no a quel foglio è definitivo: si cambia idea solo dalle impostazioni
        // di sistema, che nessuno apre. Il permesso si chiede da [ensurePermission],
        // quando l'utente accende i promemoria, esattamente come su Android.
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: service._onTap,
    );

    final android = instance
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    for (final channel in channels) {
      await android?.createNotificationChannel(channel.toAndroid());
    }

    // Se l'app è stata aperta toccando una notifica mentre era chiusa, il payload arriva
    // solo da qui: lo stream non esisteva ancora quando il tocco è avvenuto.
    final launch = await instance.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      service._launchPayload = launch?.notificationResponse?.payload;
    }

    return service;
  }

  /// Il payload che ha aperto l'app, consumabile una sola volta.
  String? consumeLaunchPayload() {
    final payload = _launchPayload;
    _launchPayload = null;
    return payload;
  }

  /// `true` se il sistema consente già di notificare, **senza chiedere niente**.
  ///
  /// ☠ Esiste perché [ensurePermission] non si può usare per sapere come stiamo: quella
  /// **chiede**, e su iOS il foglio di sistema si può mostrare una volta sola nella vita
  /// dell'installazione. Chiamarla per leggere lo stato brucerebbe l'unica occasione, e il
  /// secondo rifiuto non si recupera piu' se non dalle impostazioni di sistema.
  ///
  /// ☠ Era proprio l'assenza di questo metodo a tenere in piedi il difetto trovato il
  /// 2026-10-04 su un iPad vero: l'interfaccia non aveva modo di sapere se il permesso
  /// mancava, quindi non lo chiedeva mai, e i promemoria non arrivavano **su nessuna delle
  /// due piattaforme**. Vedi `NotificationsPage`.
  ///
  /// ⚑ Su Android risponde `areNotificationsEnabled`, che tiene conto anche del caso in cui
  /// l'utente abbia spento le notifiche dalle impostazioni di sistema dopo averle concesse:
  /// non è la stessa cosa del permesso runtime, ed è la domanda giusta, perché quello che
  /// conta e' se la notifica si vedra'.
  ///
  /// ⚑ Dove non c'è nessuna delle due implementazioni (i test a tavolino) risponde `true`:
  /// l'alternativa sarebbe mostrare per sempre un avviso di permesso mancante su una
  /// piattaforma che non ha permessi.
  Future<bool> hasPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.areNotificationsEnabled() ?? false;

    final darwin = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (darwin != null) {
      final stato = await darwin.checkPermissions();
      // `isEnabled` copre sia il permesso pieno sia quello provvisorio: in entrambi i casi
      // una notifica arriva, che e' la cosa che interessa a chi chiama.
      return stato?.isEnabled ?? false;
    }

    return true;
  }

  /// Chiede il permesso di notificare, sulla piattaforma su cui gira.
  ///
  /// ☠ Qui c'era solo il ramo Android, e su iOS la risoluzione dell'implementazione
  /// Android dà `null`: il metodo rispondeva [PermissionOutcome.notRequired], cioè
  /// «non serve nessun permesso». Su iOS il permesso serve eccome, e senza non arriva
  /// niente. L'interfaccia avrebbe mostrato i promemoria come attivi e funzionanti.
  Future<PermissionOutcome> ensurePermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return (granted ?? false) ? PermissionOutcome.granted : PermissionOutcome.denied;
    }

    final darwin = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (darwin != null) {
      // Gli stessi tre permessi che [create] non ha chiesto all'avvio.
      final granted = await darwin.requestPermissions(alert: true, badge: true, sound: true);
      return (granted ?? false) ? PermissionOutcome.granted : PermissionOutcome.denied;
    }

    return PermissionOutcome.notRequired;
  }

  /// `true` se il sistema consente gli alarm all'orario esatto.
  ///
  /// ☠ Su Android 14+ `SCHEDULE_EXACT_ALARM` non è concesso di default, e Google Play
  /// contesta la richiesta se non c'è una ragione da sveglia o promemoria dell'utente.
  /// Chi non ce l'ha deve comunque ricevere le notifiche, solo con tolleranza maggiore.
  ///
  /// ⚑ Su iOS risponde `false`, ed è corretto così anche se suona al contrario: iOS non
  /// ha il concetto di permesso per l'orario esatto, consegna sempre all'ora chiesta, e
  /// l'unico effetto di questo `false` è scegliere un `androidScheduleMode` che su iOS
  /// viene ignorato. Non va usato per decidere cosa mostrare all'utente: su iOS non
  /// esiste nessuna schermata di sistema da aprire.
  Future<bool> canScheduleExactAlarms() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? false;
  }

  Future<bool> requestExactAlarmPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestExactAlarmsPermission() ?? false;
  }

  Future<void> scheduleOne(ScheduledNotification notification) async {
    final channel = _channels.firstWhere(
      (c) => c.id == notification.channelId,
      orElse: () => _channels.first,
    );

    final when = tz.TZDateTime.from(notification.localWhen, tz.local);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) {
      // Pianificare nel passato non produce errori, produce silenzio: la notifica non
      // arriva e nessuno se ne accorge. Meglio saltarla esplicitamente.
      MicroLog.d('notifica ${notification.id} nel passato, saltata');
      return;
    }

    final useExact = notification.exact && await canScheduleExactAlarms();

    // ☠ **Su iOS, senza permesso, pianificare lancia.** Android accetta la notifica e
    //   semplicemente non la mostra; iOS la rifiuta con `PlatformException` nel dominio
    //   `UNErrorDomain` ("Source is not authorized"). Prima l'eccezione risaliva: la
    //   pianificazione si fermava al primo promemoria e ogni ripianificazione produceva un
    //   errore. Succede a chiunque compri il Pro su iPhone prima di concedere le notifiche.
    //   L'ha trovato il test degli screenshot il 2026-10-05, il primo a comprare il Pro su un
    //   simulatore senza permesso. Quando il permesso arriva, `NotificationsPage` ripianifica
    //   tutto, quindi saltare qui non perde niente.
    try {
      await _plugin.zonedSchedule(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        scheduledDate: when,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: channel._androidImportance,
            priority: Priority.defaultPriority,
            // Il testo lungo va reso con BigTextStyle, altrimenti Android lo tronca al
            // primo rigo e il promemoria perde proprio la parte che dice cosa fare.
            styleInformation: BigTextStyleInformation(notification.body),
          ),
          // ⚑ iOS non ha canali: l'importanza, la vibrazione e la descrizione del canale
          // non hanno dove andare, e il raggruppamento si fa con `threadIdentifier`. Gli si
          // passa l'id del canale, così i promemoria della stessa famiglia si impilano nel
          // centro notifiche invece di presentarsi come avvisi slegati.
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: channel.playSound,
            threadIdentifier: channel.id,
          ),
        ),
        androidScheduleMode: useExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: notification.payload,
      );
    } on PlatformException catch (error) {
      if (!rifiutoDiPermesso(error)) rethrow;
      MicroLog.w('notifica ${notification.id} non pianificata: permesso assente', error: error);
    }
  }

  /// `true` se [error] e' il rifiuto del sistema per mancanza di permesso.
  ///
  /// ⚑ Si riconosce dal dominio `UNErrorDomain`, cioe' il centro notifiche di iOS, e non dal
  ///   testo del messaggio, che cambia con la lingua del sistema. Ogni altro errore risale:
  ///   nasconderli tutti renderebbe invisibile un difetto vero di pianificazione.
  @visibleForTesting
  static bool rifiutoDiPermesso(PlatformException error) => error.details == 'UNErrorDomain';

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<List<PendingNotificationRequest>> pending() => _plugin.pendingNotificationRequests();

  /// Sostituisce l'insieme delle notifiche pianificate con quello dato.
  ///
  /// ⚑ Perché un'unica operazione invece di "cancella tutto" seguito da "pianifica
  /// tutto": la seconda forma lascia una finestra in cui l'app non ha notifiche, e se il
  /// processo muore in mezzo l'utente smette di ricevere promemoria senza accorgersene.
  /// Qui si calcola la differenza e si tocca solo ciò che cambia.
  ///
  /// Restituisce quante notifiche risultano pianificate alla fine.
  Future<int> replaceSchedule(Iterable<ScheduledNotification> wanted) async {
    final desired = wanted.take(maxPending).toList()
      ..sort((a, b) => a.localWhen.compareTo(b.localWhen));
    final desiredIds = desired.map((n) => n.id).toSet();

    final existing = await pending();
    for (final request in existing) {
      if (!desiredIds.contains(request.id)) await _plugin.cancel(id: request.id);
    }

    // `zonedSchedule` sovrascrive una notifica con lo stesso id: ripianificare quelle
    // già presenti è idempotente, ed è il motivo per cui gli id sono derivati da un hash
    // stabile invece che da un contatore (vedi NotificationIds).
    for (final notification in desired) {
      await scheduleOne(notification);
    }

    return desired.length;
  }

  Future<void> dispose() async {
    if (!_taps.isClosed) await _taps.close();
  }

  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && !_taps.isClosed) _taps.add(payload);
  }
}

/// Gli identificatori delle notifiche.
abstract final class NotificationIds {
  /// Sotto questa soglia stanno gli id fissi, per le notifiche uniche.
  static const int reservedMax = 999;

  static const int weeklyDigest = 10;
  static const int reorderWarning = 20;
  static const int reorderOverdue = 21;

  /// Id stabile per una notifica legata a un'entità e a una data.
  ///
  /// ☠ Perché derivato e non progressivo: la ripianificazione (ADR-009) ricrea le
  /// notifiche a ogni resume. Con un contatore, la stessa raccolta riceverebbe ogni volta
  /// un id diverso e i duplicati si accumulerebbero fino a far arrivare la stessa
  /// notifica cinque volte. Con un hash di (entità, data, slot) l'id è sempre lo stesso e
  /// la pianificazione sovrascrive invece di aggiungere.
  static int forOccurrence(int entityId, CivilDate date, int slot) {
    var hash = 17;
    hash = hash * 31 + entityId;
    hash = hash * 31 + date.epochDay;
    hash = hash * 31 + slot;
    // Positivo e sopra la soglia riservata: Android vuole un int a 32 bit.
    return reservedMax + 1 + (hash.abs() % (0x7FFFFFFF - reservedMax - 1));
  }
}
