import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../data/database.dart';
import '../data/freezer_repository.dart';
import '../domain/home_view.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/freezer_scheduler.dart';
import '../services/freezer_widget.dart';
import '../services/voice_input.dart';
import 'entitlement.dart';
import 'locale_resolution.dart';

/// I provider radice dell'app.
///
/// ⚑ Perche' tutto passa da qui e niente e' globale: un singleton in una variabile di
/// modulo non si puo' sostituire nei test, e obbliga a inizializzare in `main` cose che
/// servono solo a una schermata. Con i provider l'inizializzazione e' pigra e ogni test
/// inietta il proprio doppio con un `override`. Stesso schema di apps/trashcan.

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

/// Il database, aperto alla prima lettura e chiuso con il `ProviderScope`.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<FreezerRepository>(
  (ref) => FreezerRepository(ref.watch(databaseProvider)),
);

/// Le preferenze proprie di Full Freezer. Stanno qui e non in `SettingKeys` di micro_core
/// perche' non riguardano le altre app.
abstract final class FreezerSettingKeys {
  /// Il freezer guardato in home; assente = "Tutti".
  static const String selectedFreezer = 'selected_freezer';

  /// Ultimo freezer, scomparto e unita' usati nell'inserimento rapido (F4.5: "posizione =
  /// ultima usata", "unita' = ultima usata"). Sono le scelte che si ripetono sempre uguali.
  static const String lastFreezer = 'last_freezer';
  static const String lastCompartment = 'last_compartment';
  static const String lastUnit = 'last_unit';
}

/// Fabbrica del microfono dell'inserimento rapido: un `VoiceInput` nuovo per ogni foglio
/// (vedi `VoiceInput`). Un provider solo perche' i test possano dare al foglio un motore
/// finto (test/widget/quick_add_test.dart).
final voiceInputFactoryProvider = Provider<VoiceInput Function()>((ref) => VoiceInput.new);

/// "Oggi", in un provider: i test lo fissano e le pagine non leggono mai l'orologio da sole.
///
/// ⚑ Si ricalcola quando l'app torna in primo piano (lo invalida `FullFreezerApp`): chi
/// lascia l'app aperta da ieri deve vedere i giorni di oggi.
final todayProvider = Provider<CivilDate>((ref) => CivilDate.today());

final freezersProvider = StreamProvider<List<Freezer>>(
  (ref) => ref.watch(repositoryProvider).watchFreezers(),
);

final storedItemsProvider = StreamProvider<List<Item>>(
  (ref) => ref.watch(repositoryProvider).watchStoredItems(),
);

/// Gli alimenti usciti, i piu' recenti per primi (storico e statistiche, F4.7).
final removedItemsProvider = StreamProvider<List<Item>>(
  (ref) => ref.watch(repositoryProvider).watchRemovedItems(),
);

/// Gli scomparti di tutti i freezer, raggruppati per freezer.
/// Le categorie personalizzate (Pro). Esistono anche senza Pro: chi lo perde (rimborso)
/// continua a vederle sugli alimenti, solo non ne crea di nuove.
final customCategoriesProvider = StreamProvider<List<CustomCategory>>(
  (ref) => ref.watch(repositoryProvider).watchCustomCategories(),
);

final compartmentsByFreezerProvider = StreamProvider<Map<int, List<Compartment>>>(
  (ref) => ref.watch(repositoryProvider).watchAllCompartments().map((all) {
    final map = <int, List<Compartment>>{};
    for (final c in all) {
      (map[c.freezerId] ??= <Compartment>[]).add(c);
    }
    return map;
  }),
);

/// `true` dopo che il primo freezer e' stato creato.
///
/// ⚑ Una preferenza e non "esiste almeno un freezer": il redirect del router deve
/// rispondere subito, mentre lo stream del database arriva dopo il primo frame. Con la
/// query, l'app aprirebbe l'onboarding per un istante anche a chi l'ha gia' fatto.
final onboardingDoneProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider).getBool(SettingKeys.onboardingDone, orElse: false),
);

/// Il freezer guardato in home, o null per "Tutti". Persistito.
class SelectedFreezer extends Notifier<int?> {
  @override
  int? build() {
    final saved = ref.watch(settingsProvider).getInt(FreezerSettingKeys.selectedFreezer, orElse: -1);
    return saved < 0 ? null : saved;
  }

  Future<void> select(int? freezerId) async {
    state = freezerId;
    final settings = ref.read(settingsProvider);
    if (freezerId == null) {
      await settings.remove(FreezerSettingKeys.selectedFreezer);
    } else {
      await settings.setInt(FreezerSettingKeys.selectedFreezer, freezerId);
    }
  }
}

final selectedFreezerProvider = NotifierProvider<SelectedFreezer, int?>(SelectedFreezer.new);

/// La home pronta da disegnare. Null finche' i dati non sono arrivati.
final homeViewProvider = Provider<HomeView?>((ref) {
  final freezers = ref.watch(freezersProvider).value;
  final items = ref.watch(storedItemsProvider).value;
  if (freezers == null || items == null) return null;
  var selected = ref.watch(selectedFreezerProvider);
  // Un freezer selezionato e poi cancellato: si torna a "Tutti" invece di una home vuota.
  if (selected != null && !freezers.any((f) => f.id == selected)) selected = null;
  // Con un freezer solo, "Tutti" e quel freezer sono la stessa cosa: si mostra il freezer,
  // cosi' la testata ha la sua barra di riempimento.
  if (selected == null && freezers.length == 1) selected = freezers.single.id;
  return buildHomeView(
    freezers: freezers,
    storedItems: items,
    selectedFreezerId: selected,
    today: ref.watch(todayProvider),
  );
});

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

/// Il servizio delle notifiche, inizializzato pigramente (non serve al primo frame).
final notificationServiceProvider = FutureProvider<NotificationService>((ref) async {
  final service = await NotificationService.create(
    // ☠ L'icona della barra di stato e' monocromatica su trasparente: Android ne usa solo
    // l'alfa. Con l'icona del launcher, opaca, verrebbe una macchia bianca.
    androidIconResource: '@drawable/ic_notification',
    channels: const <MicroNotificationChannel>[freezerChannel],
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Le traduzioni per i testi delle notifiche, che si scrivono fuori da ogni widget.
L _systemL() => lookupL(resolveAppLocale(PlatformDispatcher.instance.locales, kSupportedLocales));

final schedulerProvider = Provider<FreezerScheduler>(
  (ref) => FreezerScheduler(
    repo: ref.watch(repositoryProvider),
    settings: ref.watch(settingsProvider),
    gate: ref.watch(featureGateProvider),
    l: _systemL(),
    notifications: ref.watch(notificationServiceProvider).value,
  ),
);

/// Tiene il piano delle notifiche allineato ai dati: una passata all'avvio e una (con mezzo
/// secondo di attesa, perche' un'azione fa piu' scritture) dopo ogni modifica, preceduta
/// dalla valutazione della capienza. Stesso schema di TrashCan.
final notificationSyncProvider = Provider<void>((ref) {
  final scheduler = ref.watch(schedulerProvider);
  final repo = ref.watch(repositoryProvider);
  if (scheduler.isReady) unawaited(scheduler.rescheduleAll());

  // Il widget (F4.11) segue gli stessi eventi delle notifiche: all'avvio e a ogni modifica.
  Future<void> publishWidget() async => FreezerWidget.publish(
    stored: await repo.storedItems(),
    custom: await repo.watchCustomCategories().first,
  );
  unawaited(publishWidget());
  unawaited(FreezerWidget.scheduleDailyRefresh());

  Timer? debounce;
  final sub = repo.watchAnyChange().listen((_) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () async {
      await scheduler.evaluateCapacity();
      await scheduler.rescheduleAll();
      await publishWidget();
    });
  });
  ref.onDispose(() {
    debounce?.cancel();
    unawaited(sub.cancel());
  });
});

/// L'interruttore delle notifiche. Spegnerlo cancella subito quelle in attesa.
///
/// ☠ **Parte spento**, al contrario di TrashCan. Li' il primo avvio chiede il permesso; qui
/// gli avvisi sono Pro e il permesso si chiede solo quando li si accende. Con il default
/// acceso l'interruttore si mostrava acceso senza che il permesso fosse mai stato chiesto,
/// e il primo tocco lo SPEGNEVA (trovato sull'emulatore il 2026-10-07).
class NotificationsEnabled extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsProvider).getBool(SettingKeys.notificationsEnabled, orElse: false);

  Future<void> set(bool value) async {
    state = value;
    await ref.read(settingsProvider).setBool(SettingKeys.notificationsEnabled, value);
    await ref.read(schedulerProvider).rescheduleAll();
  }
}

final notificationsEnabledProvider = NotifierProvider<NotificationsEnabled, bool>(NotificationsEnabled.new);

/// Ogni quanto arriva il riepilogo (F4.9).
class DigestFrequencyNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(settingsProvider).getString(NotificationSettingKeys.digestFrequency) ?? 'weekly';

  Future<void> set(String value) async {
    state = value;
    await ref.read(settingsProvider).setString(NotificationSettingKeys.digestFrequency, value);
    await ref.read(schedulerProvider).rescheduleAll();
  }
}

final digestFrequencyProvider = NotifierProvider<DigestFrequencyNotifier, String>(DigestFrequencyNotifier.new);
