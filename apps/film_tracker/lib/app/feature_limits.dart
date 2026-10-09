import 'package:micro_core/micro_core.dart';

/// I limiti del piano gratuito di Film Tracker, in un posto solo (ADR-017).
///
/// **Il gratuito risponde alla domanda dell'app**: rullini illimitati, una macchina, il
/// catalogo delle pellicole, sviluppo e stampe, l'archivio con **tutte le foto** (decisione
/// del proprietario, F6.0 punto 3) e il QR del rullino (F6.12: la funzione piu' raccontabile).
///
/// **Il Pro vende** (F6.0 punto 3): le altre macchine, le statistiche e i costi per anno, il
/// PDF di riepilogo annuale, CSV e backup completo.
///
/// ☠ Ogni chiave limitata compare fra i benefici del paywall e viceversa: lo verifica
/// test/widget/paywall_config_test.dart (trappola pagata in TrashCan).
const FeatureLimits filmFeatureLimits = <FeatureKey, FeatureLimit>{
  // Le macchine fotografiche: una gratis (F6.5). I rullini no: sono il cuore dell'app.
  FeatureKey.secondaryEntities: FeatureLimit.count(freeMax: 1),

  // Statistiche e costi per anno (F6.10).
  FeatureKey.statistics: FeatureLimit.locked(),

  // Il PDF di riepilogo annuale (F6.11).
  FeatureKey.pdfReport: FeatureLimit.locked(),

  FeatureKey.csvExport: FeatureLimit.locked(),
  FeatureKey.backupRestore: FeatureLimit.locked(),

  // Aperte: Film Tracker non le vende o non le ha. Stare qui rende leggibile cosa NON e' a
  // pagamento e tiene buono l'assert di FeatureGate.
  // ⚑ Le foto sono gratis (F6.0 punto 3): l'archivio con le anteprime e' l'identita' dell'app.
  FeatureKey.photos: FeatureLimit.open(),
  FeatureKey.unlimitedEntities: FeatureLimit.open(),
  FeatureKey.fullHistory: FeatureLimit.open(),
  FeatureKey.notifications: FeatureLimit.open(),
  FeatureKey.multipleNotifications: FeatureLimit.open(),
  FeatureKey.calendarSync: FeatureLimit.open(),
  FeatureKey.advancedWidget: FeatureLimit.open(),
  FeatureKey.customCategories: FeatureLimit.open(),
  FeatureKey.themeCustomization: FeatureLimit.open(),
  // Nessuna esportazione di immagini in questa app (chiave nata con QR Me, F17.2a).
  FeatureKey.imageExport: FeatureLimit.open(),
};
