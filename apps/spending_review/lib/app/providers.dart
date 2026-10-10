import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_ocr/micro_ocr.dart';

import '../data/database.dart';
import '../data/spending_backup_source.dart';
import '../data/spesa_repository.dart';
import '../domain/spesa.dart';
import '../domain/tastierino.dart';
import '../services/aptica.dart';
import '../services/csv_export.dart';
import '../services/fotocamera.dart';
import '../services/impostazioni_sistema.dart';
import '../services/lettura_service.dart';
import 'entitlement.dart' show appVersion, featureGateProvider;

/// I provider radice dell'app (§8.T), stesso schema di QR Me.
///
/// ⚑ Perche' tutto passa da qui e niente e' globale: un singleton in una variabile di modulo non si
/// puo' sostituire nei test, e obbliga a inizializzare in `main` cose che servono solo a una
/// schermata. Con i provider l'inizializzazione e' pigra e ogni test inietta il proprio doppio.
/// ⚑ Bootstrap (F12.2c), dati (F12.3), servizi e stato delle schermate (F12.4): ogni servizio con
/// un lato nativo (OCR, fotocamera, selettore delle foto, impostazioni di sistema, vibrazione) ha
/// il suo provider, cosi' i test di widget lo sostituiscono con un doppio finto.

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

/// Le chiavi delle preferenze proprie di Spending Review (quelle comuni sono in `SettingKeys`),
/// develop_microapps.md F12.1.10.
///
/// ⚑ **Niente `preferisciPrezzoCarta`**: la risposta D4 del proprietario (2026-10-11) ha tolto il
/// default; quando un cartellino ha due prezzi, il foglio li mostra entrambi e si sceglie ogni
/// volta.
abstract final class SrSettingKeys {
  /// Il «budget abituale» che precompila quello della spesa nuova (int centesimi; assente = nessuno).
  static const String budgetPredefinito = 'budget_predefinito';

  /// Il tetto del MESE (risposta D3, Pro): int centesimi; assente = nessuno.
  /// ⚑ Una preferenza e non una tabella: un tetto solo, uguale per tutti i mesi (lo si cambia
  /// quando si vuole). Un tetto diverso per ogni mese non e' stato chiesto.
  static const String budgetMensile = 'budget_mensile';

  /// Vibrazioni brevi a ogni tasto e alle soglie del budget (default acceso).
  static const String vibrazione = 'vibrazione';

  /// Il suggerimento «Lo scritto a mano non lo leggo» del mirino, mostrato una volta.
  static const String suggerimentoMirinoVisto = 'suggerimento_mirino_visto';
}

/// Il tema scelto dall'utente, persistito. ⚑ Scuro di default: la grafica «C · Una mano» (F12.0
/// punto 6) e' disegnata sul nero.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.watch(settingsProvider).getString(SettingKeys.themeMode);
    return switch (saved) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsProvider).setString(SettingKeys.themeMode, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Un importo in centesimi salvato nelle preferenze (budget abituale, tetto del mese); null se
/// assente o non positivo.
class _MoneySetting extends Notifier<Money?> {
  _MoneySetting(this._chiave);

  final String _chiave;

  @override
  Money? build() {
    final c = ref.watch(settingsProvider).getInt(_chiave, orElse: 0);
    return c > 0 ? Money.cents(c) : null;
  }

  Future<void> set(Money? valore) async {
    state = valore == null || valore.cents <= 0 ? null : valore;
    final s = ref.read(settingsProvider);
    if (state == null) {
      await s.remove(_chiave);
    } else {
      await s.setInt(_chiave, state!.cents);
    }
  }
}

final budgetPredefinitoProvider = NotifierProvider<_MoneySetting, Money?>(
  () => _MoneySetting(SrSettingKeys.budgetPredefinito),
);

final budgetMensileProvider = NotifierProvider<_MoneySetting, Money?>(
  () => _MoneySetting(SrSettingKeys.budgetMensile),
);

/// Un interruttore salvato nelle preferenze.
class _BoolSetting extends Notifier<bool> {
  _BoolSetting(this._chiave, {required this.predefinito});

  final String _chiave;
  final bool predefinito;

  @override
  bool build() => ref.watch(settingsProvider).getBool(_chiave, orElse: predefinito);

  Future<void> set(bool valore) async {
    state = valore;
    await ref.read(settingsProvider).setBool(_chiave, valore);
  }
}

/// Le vibrazioni brevi (default accese, F12.1.10).
final vibrazioneProvider = NotifierProvider<_BoolSetting, bool>(
  () => _BoolSetting(SrSettingKeys.vibrazione, predefinito: true),
);

/// Il suggerimento «Lo scritto a mano non lo leggo» del mirino, mostrato una volta.
final suggerimentoMirinoVistoProvider = NotifierProvider<_BoolSetting, bool>(
  () => _BoolSetting(SrSettingKeys.suggerimentoMirinoVisto, predefinito: false),
);

// ── Servizi (F12.1.13) ───────────────────────────────────────────────────────────────────────

/// L'orologio: iniettabile (banner «Spesa iniziata ieri», date di chiusura) nei test.
final oraProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Il motore OCR vero: Vision su iOS, PP-OCRv5 su ORT 1.28.0 su Android (packages/micro_ocr).
/// I test lo sostituiscono con `FakeOcrEngine`.
final ocrEngineProvider = Provider<OcrEngine>((ref) => CanaleOcrEngine());

final letturaServiceProvider = Provider<LetturaService>(
  (ref) => LetturaService(motore: ref.watch(ocrEngineProvider), ora: ref.watch(oraProvider)),
);

/// Una fotocamera nuova per ogni pagina col mirino (la pagina la apre e la chiude).
final obiettivoProvider = Provider<Obiettivo Function()>((ref) => ObiettivoCamera.new);

/// Il ritaglio della foto al mirino (`Fotocamera.ritagliaAlMirino`, in un isolate). I test di
/// widget lo sostituiscono: la fotocamera finta non produce un JPEG vero.
typedef Ritaglio = Future<String> Function(String percorsoFoto, Rect mirino, {required Size anteprima});

final ritaglioProvider = Provider<Ritaglio>(
  (ref) => (foto, mirino, {required anteprima}) => Fotocamera.ritagliaAlMirino(foto, mirino, anteprima: anteprima),
);

/// «Da una foto».
final scegliFotoProvider = Provider<ScegliFoto>((ref) => scegliFotoDiSistema);

final impostazioniSistemaProvider = Provider<ImpostazioniSistema>((ref) => const ImpostazioniSistema());

final apticaProvider = Provider<Aptica>((ref) => Aptica(attiva: ref.watch(vibrazioneProvider)));

final csvExportProvider = Provider<CsvExport>((ref) => const CsvExport());

// ── Stato delle schermate ────────────────────────────────────────────────────────────────────

/// Il tastierino della spesa in corso. ⚑ Un provider e non lo stato della pagina: il «Batti a
/// mano» del foglio del cartellino deve poterci scrivere il prezzo letto (F12.1.12), e il valore
/// a meta' battitura sopravvive a un giro nello storico.
class TastierinoNotifier extends Notifier<TastierinoState> {
  @override
  TastierinoState build() => const TastierinoState.vuoto();

  /// Il tocco di un tasto: aggiorna il display e ritorna l'effetto (che applica la pagina).
  EffettoTasto premi(TastoTastierino tasto) {
    final (nuovo, effetto) = state.premi(tasto);
    state = nuovo;
    return effetto;
  }

  void svuota() => state = state.svuota();

  /// «Batti a mano»: il prezzo letto nel display, da correggere o confermare con «+».
  void precompila(Money prezzo) => state = TastierinoState.daPrezzo(prezzo);
}

final tastierinoProvider = NotifierProvider<TastierinoNotifier, TastierinoState>(TastierinoNotifier.new);

// ── Dati ─────────────────────────────────────────────────────────────────────────────────────

/// Il database, aperto alla prima lettura e chiuso con il `ProviderScope`.
final databaseProvider = Provider<SpendingDatabase>((ref) {
  final db = SpendingDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final spesaRepositoryProvider = Provider<SpesaRepository>(
  (ref) => SpesaRepository(ref.watch(databaseProvider)),
);

/// La spesa in corso (null finche' non si batte il primo prezzo: si crea pigramente).
final spesaInCorsoProvider = StreamProvider<Spesa?>((ref) => ref.watch(spesaRepositoryProvider).osservaInCorso());

/// Le spese chiuse VISIBILI: le ultime 5 nel gratis, tutte con il Pro (risposta D1: le altre
/// restano nel database, nascoste). ⚑ Il limite viene da `FeatureGate` (`fullHistory`), non da un
/// numero scritto qui.
final speseChiuseProvider = StreamProvider<List<Spesa>>((ref) {
  final gate = ref.watch(featureGateProvider);
  final limite = gate.isPro ? null : gate.freeLimitOf(FeatureKey.fullHistory);
  return ref.watch(spesaRepositoryProvider).osservaChiuse(limite: limite);
});

/// Tutte le spese chiuse, senza limite: statistiche e CSV (Pro), e il conto delle nascoste.
/// ⚑ Separato da [speseChiuseProvider]: la lista dello storico gratis non deve caricare le
/// righe di tutte le spese per mostrarne cinque.
final tutteLeChiuseProvider = StreamProvider<List<Spesa>>((ref) => ref.watch(spesaRepositoryProvider).osservaChiuse());

/// Quante spese chiuse ci sono sul telefono (anche quelle nascoste nel gratis).
final numeroChiuseProvider = StreamProvider<int>((ref) => ref.watch(spesaRepositoryProvider).osservaNumeroChiuse());

/// I negozi, per nome.
final negoziProvider = StreamProvider<List<Negozio>>((ref) => ref.watch(spesaRepositoryProvider).osservaNegozi());

/// Il backup (Pro) e il ripristino (gratis) di micro_core, con le cartelle e la versione dell'app.
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(paths: ref.watch(appPathsProvider), appVersion: appVersion),
);

final backupSourceProvider = Provider<SpendingBackupSource>(
  (ref) => SpendingBackupSource(ref.watch(databaseProvider)),
);
