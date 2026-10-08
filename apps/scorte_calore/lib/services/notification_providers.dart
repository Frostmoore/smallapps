import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../app/entitlement.dart';
import '../app/locale_resolution.dart';
import '../app/providers.dart';
import '../l10n/generated/app_localizations.dart';
import 'scorte_scheduler.dart';

/// I provider delle notifiche di riordino (F5.8). Stesso schema di Full Freezer
/// (`apps/full_freezer/lib/app/providers.dart`), in un file suo perche' `providers.dart`
/// resti quello dei dati.

/// Le traduzioni per i testi delle notifiche, che si scrivono fuori da ogni widget: la
/// lingua e' quella del telefono, risolta come fa l'app (`resolveAppLocale`).
L _systemL() => lookupL(resolveAppLocale(PlatformDispatcher.instance.locales, kSupportedLocales));

/// Il servizio delle notifiche, inizializzato pigramente (non serve al primo frame).
final notificationServiceProvider = FutureProvider<NotificationService>((ref) async {
  final service = await NotificationService.create(
    // ☠ L'icona della barra di stato e' monocromatica su trasparente: Android ne usa solo
    // l'alfa. Con l'icona del launcher, opaca, verrebbe una macchia bianca.
    androidIconResource: '@drawable/ic_notification',
    channels: <MicroNotificationChannel>[scorteChannel(_systemL())],
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Lo scheduler, ricostruito quando cambia il Pro o arriva il servizio: la ricostruzione
/// fa ripartire [notificationSyncProvider], che ripianifica (o cancella, se il Pro e' finito).
final scorteSchedulerProvider = Provider<ScorteScheduler>(
  (ref) => ScorteScheduler(
    repo: ref.watch(repositoryProvider),
    settings: ref.watch(settingsProvider),
    gate: ref.watch(featureGateProvider),
    l: _systemL(),
    notifications: ref.watch(notificationServiceProvider).value,
  ),
);

/// Tiene il piano delle notifiche allineato ai dati: una passata all'avvio e una dopo ogni
/// modifica a fonti e misure, con mezzo secondo di attesa perche' un salvataggio fa piu'
/// scritture (la misura, poi magari la fonte). Lo tiene vivo `app.dart` con un `ref.watch`.
///
/// ⚑ Su `watchAnyChange` e non su `sourcesProvider`/`estimateProvider`: le stime esistono
/// solo per le fonti che una pagina sta guardando, mentre le notifiche servono per tutte.
/// Cosi' "si ripianificano a ogni nuova misurazione" (F5.8) vale da qualunque punto la
/// misura arrivi (foglio di aggiornamento, storico, ripristino di un backup).
final notificationSyncProvider = Provider<void>((ref) {
  final scheduler = ref.watch(scorteSchedulerProvider);
  final repo = ref.watch(repositoryProvider);
  if (scheduler.isReady) unawaited(scheduler.rescheduleAll());

  Timer? debounce;
  final sub = repo.watchAnyChange().listen((_) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () => unawaited(scheduler.rescheduleAll()));
  });
  ref.onDispose(() {
    debounce?.cancel();
    unawaited(sub.cancel());
  });
});

/// L'interruttore delle notifiche. Spegnerlo cancella subito quelle in attesa.
///
/// ☠ **Parte spento**, come in Full Freezer. Le notifiche sono Pro e il permesso si chiede
/// solo quando le si accende. Con il default acceso l'interruttore si mostrava acceso senza
/// che il permesso fosse mai stato chiesto, e il primo tocco lo SPEGNEVA (trovato in Full
/// Freezer sull'emulatore il 2026-10-07).
class NotificationsEnabled extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsProvider).getBool(SettingKeys.notificationsEnabled, orElse: false);

  Future<void> set(bool value) async {
    state = value;
    await ref.read(settingsProvider).setBool(SettingKeys.notificationsEnabled, value);
    await ref.read(scorteSchedulerProvider).rescheduleAll();
  }
}

final notificationsEnabledProvider = NotifierProvider<NotificationsEnabled, bool>(NotificationsEnabled.new);

/// `true` se il sistema mostrera' le notifiche (permesso concesso e non spente dalle
/// impostazioni del telefono). La sezione delle impostazioni lo usa per dire perche' un
/// interruttore acceso non produce niente.
///
/// ⚑ `autoDispose`: si rilegge ogni volta che si riapre la pagina, cosi' chi torna dalle
/// impostazioni di sistema dopo aver concesso il permesso non vede piu' l'avviso.
final notificationPermissionProvider = FutureProvider.autoDispose<bool>((ref) async {
  final service = await ref.watch(notificationServiceProvider.future);
  return service.hasPermission();
});
