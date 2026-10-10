import 'package:micro_core/micro_core.dart';

/// I limiti del piano gratuito di Spending Review, in un posto solo (ADR-017; develop_microapps.md
/// F12.0 punto 5 e F12.1.14). «Spesa gratis, revisione Pro», Pro a 2,99 € una tantum.
///
/// **Gratis**: tastierino, totale, quantita', sconti, budget della spesa, lettura illimitata dei
/// cartellini, peso a mano ed etichetta della bilancia, le ultime 5 spese.
///
/// **Il Pro vende**: lo Scontrino (controllo alla cassa e registrazione), tutte le spese, le
/// statistiche con il budget del mese (risposta D3 del proprietario), il CSV, il backup.
///
/// ☠ Ogni chiave limitata compare fra i benefici del paywall e viceversa: lo verifica
/// test/widget/paywall_config_test.dart (trappola pagata in TrashCan). E ogni chiave di
/// `FeatureKey.values` e' scritta qui, anche quelle aperte.
const FeatureLimits srFeatureLimits = <FeatureKey, FeatureLimit>{
  // ⚑ 5 spese chiuse VISIBILI: le altre restano nel database, nascoste (risposta D1 del
  // proprietario, 2026-10-11). Il limite lo applica la LETTURA (`osservaChiuse(limite: 5)`),
  // mai una cancellazione: chi compra il Pro dopo tre mesi ritrova tutto, statistiche piene.
  FeatureKey.fullHistory: FeatureLimit.count(freeMax: 5),

  // Lo Scontrino: confronto alla cassa e registrazione della spesa dallo scontrino (chiave nata
  // con Spending Review, F12.2a: «leggere un documento intero e ricavarne i dati»).
  FeatureKey.documentScan: FeatureLimit.locked(),

  // Statistiche per mese e per negozio, media, sforamenti, e il budget del MESE (D3).
  FeatureKey.statistics: FeatureLimit.locked(),

  FeatureKey.csvExport: FeatureLimit.locked(),

  // Il backup e' Pro; il ripristino resta gratis, come in tutte le app.
  FeatureKey.backupRestore: FeatureLimit.locked(),

  // Aperte: Spending Review non le vende o non le ha. Stare qui rende leggibile cosa NON e' a
  // pagamento e tiene buono l'assert di FeatureGate.
  FeatureKey.unlimitedEntities: FeatureLimit.open(),
  FeatureKey.secondaryEntities: FeatureLimit.open(),
  // ⚑ `photos` vuol dire «allegare foto ai record»: qui nessuna foto si conserva (F12.1.15).
  FeatureKey.photos: FeatureLimit.open(),
  FeatureKey.pdfReport: FeatureLimit.open(),
  FeatureKey.advancedWidget: FeatureLimit.open(),
  FeatureKey.notifications: FeatureLimit.open(),
  FeatureKey.multipleNotifications: FeatureLimit.open(),
  FeatureKey.calendarSync: FeatureLimit.open(),
  FeatureKey.customCategories: FeatureLimit.open(),
  FeatureKey.themeCustomization: FeatureLimit.open(),
  FeatureKey.imageExport: FeatureLimit.open(),
};
