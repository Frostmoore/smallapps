import 'package:micro_core/micro_core.dart';

/// I limiti del piano gratuito di Full Freezer, in un posto solo (ADR-017).
///
/// Nessuna pagina scrive `if (isPro)`: si passa sempre da `FeatureGate`, costruito da
/// questa mappa. Spostare un tetto e' una riga qui, non un refactoring.
///
/// **Il gratuito e' un'app completa**: freezer con modello e riempimento, scomparti,
/// prodotti illimitati, inserimento rapido, foto, ricerca, widget. Chi lo usa ha gia'
/// risolto il problema "cosa c'e' nel freezer e da quanto".
///
/// **Il Pro vende** (develop_microapps.md F4.0 punto 10, F4.10): il secondo freezer (chi ha
/// il pozzetto in garage ha gia' dimostrato di avere il problema), il richiamo delle
/// notifiche, e i numeri dello spreco.
///
/// ☠ Ogni chiave `locked()` deve comparire fra i benefici del paywall e viceversa: lo
/// verifica test/widget/paywall_config_test.dart. Un blocco senza beneficio e' una funzione
/// a pagamento che il paywall non nomina; un beneficio senza blocco promette una cosa che
/// l'utente ha gia' (trappola gia' pagata in TrashCan con il widget).
const FeatureLimits freezerFeatureLimits = <FeatureKey, FeatureLimit>{
  // Freezer: uno gratis, illimitati con il Pro.
  FeatureKey.unlimitedEntities: FeatureLimit.count(freeMax: 1),

  // Il riepilogo periodico e gli avvisi "quasi pieno" / "quasi vuoto" (F4.9).
  // Decisione del proprietario, 2026-10-06.
  FeatureKey.notifications: FeatureLimit.locked(),

  // Lo storico di consumati e buttati (F4.7). Gli usciti restano comunque nel database:
  // chi compra il Pro trova gia' i dati di prima.
  FeatureKey.fullHistory: FeatureLimit.locked(),

  // Le statistiche dello spreco (F4.10).
  FeatureKey.statistics: FeatureLimit.locked(),

  // L'elenco in un foglio di calcolo.
  FeatureKey.csvExport: FeatureLimit.locked(),

  // Backup completo e ripristino su un telefono nuovo.
  FeatureKey.backupRestore: FeatureLimit.locked(),

  // Categorie oltre a quelle predefinite.
  FeatureKey.customCategories: FeatureLimit.locked(),

  // Dichiarate aperte: Full Freezer non le vende. Stare qui rende leggibile, a colpo
  // d'occhio, cosa NON e' a pagamento, e tiene buono l'assert di FeatureGate.
  //
  // Le foto sono gratis per decisione del proprietario (2026-10-06): fanno parte del gesto
  // di inserimento, e toglierle al gratuito peggiora l'app che deve farsi installare.
  FeatureKey.photos: FeatureLimit.open(),
  // Gli scomparti: illimitati per tutti (F4.6).
  FeatureKey.secondaryEntities: FeatureLimit.open(),
  // ADR-019: il widget non e' una leva del Pro.
  FeatureKey.advancedWidget: FeatureLimit.open(),
  // Funzioni che Full Freezer non ha: aperte, cosi' nessuno incontra un blocco per qualcosa
  // che l'app non sa fare.
  FeatureKey.multipleNotifications: FeatureLimit.open(),
  FeatureKey.pdfReport: FeatureLimit.open(),
  FeatureKey.calendarSync: FeatureLimit.open(),
  FeatureKey.themeCustomization: FeatureLimit.open(),
  // Nessuna esportazione di immagini in questa app (chiave nata con QR Me, F17.2a).
  FeatureKey.imageExport: FeatureLimit.open(),
  // Nessuna lettura di documenti in questa app (chiave nata con Spending Review, F12.2a).
  FeatureKey.documentScan: FeatureLimit.open(),
};
