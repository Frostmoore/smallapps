import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';
import '../data/repository.dart';
import '../domain/occurrence_engine.dart';
import '../services/trashcan_scheduler.dart';
import '../services/trashcan_widget.dart';
import 'app_themes.dart';
import 'feature_limits.dart';

/// I provider radice dell'app.
///
/// ⚑ Perché tutto passa da qui e niente è globale: un singleton in una variabile di
/// modulo non si può sostituire nei test, e obbliga a inizializzare in `main` cose che
/// servono solo a una schermata. Con i provider l'inizializzazione è pigra e ogni test
/// può iniettare il proprio doppio con un `override`.

/// Sovrascritti in `main()`: senza, l'app non parte.
final appConfigProvider = Provider<MicroAppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider va sovrascritto in main()'),
);

final appPathsProvider = Provider<AppPaths>(
  (ref) => throw UnimplementedError('appPathsProvider va sovrascritto in main()'),
);

final settingsProvider = Provider<SettingsStore>(
  (ref) => throw UnimplementedError('settingsProvider va sovrascritto in main()'),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<TrashcanRepository>(
  (ref) => TrashcanRepository(ref.watch(databaseProvider)),
);

final installIdProvider = FutureProvider<InstallId>(
  (ref) => InstallId.load(appId: ref.watch(appConfigProvider).appId),
);

final purchaseGatewayProvider = Provider<PurchaseGateway>((ref) {
  final config = ref.watch(appConfigProvider);
  final gateway = switch (config.billingMode) {
    BillingMode.store => StorePurchaseGateway(),
    // Il gateway finto parte già posseduto solo se qualcuno lo chiede esplicitamente:
    // di default si vede il paywall, che è ciò che si vuole provare durante lo sviluppo.
    BillingMode.fake => FakePurchaseGateway.withProduct(config.proSku),
  };
  ref.onDispose(gateway.dispose);
  return gateway;
});

/// Lo stato dell'entitlement come lo vede la UI.
///
/// ⚑ Perché un tipo a parte invece di esporre il servizio: `EntitlementService` è un
/// `ChangeNotifier`, e Riverpod 3 ha spostato `ChangeNotifierProvider` fra le API legacy.
/// Invece di appoggiarsi a uno shim in via di rimozione, si tiene il servizio dietro un
/// `Notifier` che ne rispecchia lo stato in un valore immutabile. Costa venti righe e
/// rende esplicito **cosa** fa ridisegnare la UI, che con un `ChangeNotifier` è sempre
/// "qualunque cosa sia cambiata".
@immutable
class EntitlementView {
  const EntitlementView({
    required this.entitlement,
    required this.busy,
    required this.storeAvailable,
    this.product,
    this.error,
  });

  final Entitlement entitlement;
  final bool busy;
  final bool storeAvailable;
  final MicroProduct? product;
  final MicroError? error;

  bool get isPro => entitlement.isPro;
  bool get isPending => entitlement.isPending;

  @override
  bool operator ==(Object other) =>
      other is EntitlementView &&
      other.entitlement == entitlement &&
      other.busy == busy &&
      other.storeAvailable == storeAvailable &&
      other.product?.id == product?.id &&
      other.product?.formattedPrice == product?.formattedPrice &&
      other.error?.code == error?.code;

  @override
  int get hashCode => Object.hash(entitlement, busy, storeAvailable, product?.id, error?.code);
}

class EntitlementNotifier extends Notifier<EntitlementView> {
  EntitlementService? _service;

  /// Il servizio, per invocare le azioni. La UI legge lo stato da [state].
  EntitlementService get service => _service!;

  @override
  EntitlementView build() {
    final config = ref.watch(appConfigProvider);
    final paths = ref.watch(appPathsProvider);
    final installId = ref.watch(installIdProvider).value;

    // Il client del server lo costruisce questo provider, quindi tocca a lui chiuderlo.
    // Il gateway no: quello vive in purchaseGatewayProvider, che se ne occupa da solo.
    // Vedi il commento su EntitlementService.dispose: un servizio non chiude niente che
    // non abbia costruito, e questo build() viene rieseguito almeno una volta a ogni
    // avvio, appena l'id di installazione finisce di caricarsi.
    final api = (config.serverEnabled && installId != null)
        ? LicenseApiClient(
            baseUri: config.licenseBaseUrl!,
            appId: config.appId,
            appSecret: config.appSecret,
            installId: installId.value,
            appVersion: appVersion,
          )
        : null;

    final service = EntitlementService(
      appId: config.appId,
      proSku: config.proSku,
      gateway: ref.watch(purchaseGatewayProvider),
      store: EntitlementStore(file: paths.file(paths.support, 'entitlement.json')),
      // Finché l'id non è stato letto si usa un segnaposto: il servizio funziona lo
      // stesso in locale, e appena l'id arriva questo provider si ricostruisce.
      installId: installId ?? InstallId.fixed('00000000-0000-0000-0000-000000000000'),
      api: api,
    );
    _service = service;
    service.addListener(_sync);
    ref.onDispose(() {
      service.removeListener(_sync);
      service.dispose();
      api?.close();
    });

    // Il bootstrap parte da solo: la UI non deve ricordarsi di chiamarlo, e dimenticarlo
    // significherebbe un'app che non si accorge di un acquisto già fatto.
    unawaited(service.bootstrap());
    return _snapshot(service);
  }

  void _sync() {
    final service = _service;
    if (service == null) return;
    state = _snapshot(service);
  }

  static EntitlementView _snapshot(EntitlementService service) => EntitlementView(
    entitlement: service.current,
    busy: service.isBusy,
    storeAvailable: service.storeAvailable,
    product: service.proProduct,
    error: service.lastError,
  );

  Future<void> buyPro() => service.buyPro();

  Future<void> restore() => service.restorePurchases();
}

final entitlementProvider = NotifierProvider<EntitlementNotifier, EntitlementView>(
  EntitlementNotifier.new,
);

final isProProvider = Provider<bool>((ref) => ref.watch(entitlementProvider).isPro);

final featureGateProvider = Provider<FeatureGate>(
  (ref) => FeatureGate(limits: trashcanFeatureLimits, isPro: ref.watch(isProProvider)),
);

/// La versione dell'app, in un posto solo: compare nel backup, nelle chiamate al server
/// e nella schermata delle informazioni, e tenerla in tre posti garantisce che divergano.
const String appVersion = '0.1.0';

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(paths: ref.watch(appPathsProvider), appVersion: appVersion),
);

/// Il tema scelto dall'utente, persistito.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.watch(settingsProvider).getString(SettingKeys.themeMode);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsProvider).setString(SettingKeys.themeMode, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// `true` se il wizard iniziale è già stato completato.
final onboardingDoneProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider).getBool(SettingKeys.onboardingDone, orElse: false),
);

/// L'id del calendario attualmente selezionato.
///
/// Nel piano gratuito ce n'è uno solo, ma il concetto esiste dal primo giorno: aggiungere
/// il selettore dopo significherebbe riscrivere ogni query della home.
class SelectedCalendar extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? id) => state = id;
}

final selectedCalendarProvider = NotifierProvider<SelectedCalendar, int?>(SelectedCalendar.new);

/// I calendari esistenti.
final calendarsProvider = StreamProvider<List<CollectionCalendar>>(
  (ref) => ref.watch(databaseProvider).watchCalendars(),
);

/// Il calendario da mostrare: quello scelto, oppure il primo disponibile.
final activeCalendarProvider = Provider<CollectionCalendar?>((ref) {
  final calendars = ref.watch(calendarsProvider).value ?? const <CollectionCalendar>[];
  if (calendars.isEmpty) return null;
  final selected = ref.watch(selectedCalendarProvider);
  if (selected == null) return calendars.first;
  return calendars.where((c) => c.id == selected).firstOrNull ?? calendars.first;
});

/// Il pacchetto completo del calendario attivo: tipi, regole ed eccezioni già tradotte.
final activeBundleProvider = StreamProvider<CalendarBundle?>((ref) {
  final calendar = ref.watch(activeCalendarProvider);
  if (calendar == null) return Stream.value(null);
  return ref.watch(databaseProvider).watchBundle(calendar.id);
});

const _engine = OccurrenceEngine();

/// Le raccolte dei prossimi [_horizonDays] giorni, calcolate **una volta sola**.
///
/// ☠ Trappola disinnescata: `OccurrenceEngine.expand` è O(giorni × regole) e alloca un
/// oggetto per ogni raccolta. Chiamarlo dentro un `build` significa rifare quel lavoro a
/// ogni frame, e su un telefono di fascia bassa si vede. Le pagine leggono da qui, e
/// questo si ricalcola solo quando cambiano i dati.
const int _horizonDays = 120;

final occurrencesProvider = Provider<List<CollectionOccurrence>>((ref) {
  final bundle = ref.watch(activeBundleProvider).value;
  if (bundle == null || bundle.rules.isEmpty) return const <CollectionOccurrence>[];
  final today = CivilDate.today();
  return _engine.expand(
    rules: bundle.rules,
    // Si parte da ieri e non da oggi: la vista dei prossimi giorni deve poter mostrare
    // anche la raccolta di stamattina, che è già passata ma è ancora informativa.
    from: today.addDays(-1),
    to: today.addDays(_horizonDays),
  );
});

/// Cosa va portato fuori **stasera**, cioè la raccolta di domani.
final tonightProvider = Provider<List<CollectionOccurrence>>((ref) {
  final tomorrow = CivilDate.today().addDays(1);
  return ref.watch(occurrencesProvider).where((o) => o.date == tomorrow).toList();
});

/// La prima raccolta successiva a stasera.
final nextOccurrenceProvider = Provider<CollectionOccurrence?>((ref) {
  final afterTomorrow = CivilDate.today().addDays(2);
  return ref
      .watch(occurrencesProvider)
      .where((o) => o.date.isSameOrAfter(afterTomorrow))
      .firstOrNull;
});

/// Le raccolte dei prossimi sette giorni, da oggi compreso.
final upcomingWeekProvider = Provider<List<CollectionOccurrence>>((ref) {
  final today = CivilDate.today();
  final limit = today.addDays(7);
  return ref
      .watch(occurrencesProvider)
      .where((o) => o.date.isSameOrAfter(today) && o.date.isSameOrBefore(limit))
      .toList();
});

// ── Notifiche ──────────────────────────────────────────────────────────────────────

/// Il servizio di notifiche, creato al primo uso e non in `main()`.
///
/// ⚑ Inizializzarlo all'avvio costa decine di millisecondi prima del primo frame, per una
/// cosa che serve solo dopo che esiste un calendario. Chi lo osserva riceve `null` finche'
/// non e' pronto, e il pianificatore semplicemente non consegna niente in quell'istante.
final notificationServiceProvider = FutureProvider<NotificationService>((ref) async {
  final service = await NotificationService.create(
    // ☠ L'icona della barra di stato deve essere monocromatica su fondo trasparente:
    // Android ne usa solo il canale alfa e la ridisegna in bianco. Con @mipmap/ic_launcher,
    // che e' opaca su tutta la superficie, il risultato e' una macchia bianca senza forma.
    androidIconResource: '@drawable/ic_notification',
    channels: const <MicroNotificationChannel>[trashcanChannel],
  );
  ref.onDispose(service.dispose);
  return service;
});

final schedulerProvider = Provider<TrashcanScheduler>(
  (ref) => TrashcanScheduler(
    db: ref.watch(databaseProvider),
    settings: ref.watch(settingsProvider),
    gate: ref.watch(featureGateProvider),
    appName: ref.watch(appConfigProvider).appName,
    // Si osserva il Future: quando il servizio e' pronto il pianificatore viene ricostruito
    // con dentro il servizio vero, e la sincronizzazione qui sotto riparte da sola.
    notifications: ref.watch(notificationServiceProvider).value,
  ),
);

/// Tiene allineato ai dati tutto cio' che vive **fuori** dall'app: il piano delle
/// notifiche e il contenuto del widget.
///
/// ⛑ Perche' insieme e non due collegamenti separati: sono la stessa domanda ("cosa si
/// raccoglie e quando") posta da due posti diversi, e cambiano sempre insieme. Due
/// sottoscrizioni distinte allo stesso flusso di modifiche vorrebbero dire due debounce da
/// tenere allineati e la possibilita' concreta che il widget dica una cosa e la notifica
/// un'altra.
///
/// La ripianificazione e' ritardata di mezzo secondo perche' una singola azione dell'utente
/// puo' produrre piu' scritture (creare un tipo e la sua regola, riordinare dieci righe):
/// ricalcolare a ogni scrittura significa fare lo stesso lavoro tre volte di fila.
final notificationSyncProvider = Provider<void>((ref) {
  final scheduler = ref.watch(schedulerProvider);
  final db = ref.watch(databaseProvider);
  final calendarId = ref.watch(activeCalendarProvider)?.id;
  final pro = ref.watch(isProProvider);

  Future<void> refreshWidget() =>
      TrashcanWidget.publish(db: db, calendarId: calendarId, pro: pro);

  // ☠ Una passata all'avvio, appena il servizio e' pronto. Senza, il piano si
  // ricostruiva solo quando i dati cambiavano: chi installa l'app, la configura e poi non
  // la tocca piu' per due mesi non riceveva niente dopo i primi sessanta giorni, e chi
  // ripristinava un backup non riceveva niente e basta. Costa una ripianificazione per
  // avvio, cioe' quello che il guardiano dell'ora considera comunque accettabile.
  if (scheduler.isReady) unawaited(scheduler.rescheduleAll());
  unawaited(refreshWidget());
  unawaited(TrashcanWidget.scheduleDailyRefresh());

  Timer? debounce;
  final subscription = db.watchAnyChange().listen((_) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(scheduler.rescheduleAll());
      unawaited(refreshWidget());
    });
  });

  ref.onDispose(() {
    debounce?.cancel();
    unawaited(subscription.cancel());
  });
});

/// L'interruttore generale dei promemoria.
///
/// Spegnerlo cancella subito tutto quello che era in attesa invece di limitarsi a non
/// pianificare piu' nulla: le notifiche gia' consegnate ad Android sopravvivono
/// all'impostazione, e continuerebbero ad arrivare per i sessanta giorni successivi.
class NotificationsEnabled extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(settingsProvider).getBool(SettingKeys.notificationsEnabled, orElse: true);

  Future<void> set(bool value) async {
    state = value;
    await ref.read(settingsProvider).setBool(SettingKeys.notificationsEnabled, value);
    await ref.read(schedulerProvider).rescheduleAll();
  }
}

final notificationsEnabledProvider = NotifierProvider<NotificationsEnabled, bool>(
  NotificationsEnabled.new,
);

/// Il colore generale dell'app, scelto dall'utente (funzione Pro).
///
/// ⛑ Il valore si legge sempre, anche senza Pro: chi compra, sceglie un colore e poi si
/// fa rimborsare non deve ritrovarsi l'app di un colore che non ha piu' diritto di vedere
/// ma nemmeno modo di cambiare. Il cancello sta dove si **sceglie**, non dove si legge.
class SeedColor extends Notifier<Color> {
  @override
  Color build() => AppSeeds.resolve(ref.watch(settingsProvider).getString(AppSeeds.settingKey));

  Future<void> set(Color color) async {
    state = color;
    await ref.read(settingsProvider).setString(AppSeeds.settingKey, AppSeeds.keyOf(color));
  }
}

final seedColorProvider = NotifierProvider<SeedColor, Color>(SeedColor.new);
