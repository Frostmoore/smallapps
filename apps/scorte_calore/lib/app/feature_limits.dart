import 'package:micro_core/micro_core.dart';

/// I limiti del piano gratuito di Scorte Calore, in un posto solo (ADR-017).
///
/// **Il gratuito risponde alla domanda dell'app**: una fonte, misurazioni illimitate, stima
/// del consumo, autonomia e data di riordino, in app e nel widget.
///
/// **Il Pro vende** (develop_microapps.md F5.0, F5.11): la notifica prima di restare senza
/// (decisione del proprietario, 2026-10-07), le altre fonti, lo storico per confrontare gli
/// inverni con i grafici, il calendario, i costi, CSV e backup.
///
/// ☠ Ogni chiave limitata compare fra i benefici del paywall e viceversa: lo verifica
/// test/widget/paywall_config_test.dart (trappola pagata in TrashCan col widget).
const FeatureLimits scorteFeatureLimits = <FeatureKey, FeatureLimit>{
  // Fonti: una gratis (la stufa o il bombolone), illimitate con il Pro.
  FeatureKey.unlimitedEntities: FeatureLimit.count(freeMax: 1),

  // Le notifiche di riordino e di superamento (F5.8). Decisione del proprietario, 2026-10-07.
  FeatureKey.notifications: FeatureLimit.locked(),

  // Lo storico: 90 giorni bastano alla stima ma non a confrontare le stagioni (F5.9).
  // ⚑ Le misurazioni piu' vecchie restano nel database: chi compra il Pro le ritrova.
  FeatureKey.fullHistory: FeatureLimit.count(freeMax: 90),

  // Grafici, acquisti, costi e spesa stagionale (F5.9, F5.11).
  FeatureKey.statistics: FeatureLimit.locked(),

  // L'evento di riordino nel calendario del telefono (F5.10).
  FeatureKey.calendarSync: FeatureLimit.locked(),

  FeatureKey.csvExport: FeatureLimit.locked(),
  FeatureKey.backupRestore: FeatureLimit.locked(),

  // Aperte: Scorte Calore non le vende o non le ha. Stare qui rende leggibile cosa NON e' a
  // pagamento e tiene buono l'assert di FeatureGate.
  // ADR-019: il widget non e' una leva del Pro (F5.0 punto 3).
  FeatureKey.advancedWidget: FeatureLimit.open(),
  FeatureKey.secondaryEntities: FeatureLimit.open(),
  FeatureKey.multipleNotifications: FeatureLimit.open(),
  FeatureKey.photos: FeatureLimit.open(),
  FeatureKey.customCategories: FeatureLimit.open(),
  FeatureKey.pdfReport: FeatureLimit.open(),
  FeatureKey.themeCustomization: FeatureLimit.open(),
  // Nessuna esportazione di immagini in questa app (chiave nata con QR Me, F17.2a).
  FeatureKey.imageExport: FeatureLimit.open(),
};
