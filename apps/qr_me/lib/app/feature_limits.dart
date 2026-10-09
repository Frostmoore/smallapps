import 'package:micro_core/micro_core.dart';

/// I limiti del piano gratuito di QR Me, in un posto solo (ADR-017; develop_microapps.md
/// F17.0 punto 6 e F17.1.9). «Base generosa», Pro a 1,99 € una tantum.
///
/// **Gratis**: la condivisione verso l'app con il QR a tutto schermo, testo e link scritti o
/// incollati, la **lettura** dalla fotocamera e da un'immagine (decisione del proprietario),
/// gli ultimi 5 in cronologia e **un** preferito.
///
/// **Il Pro vende**: i moduli speciali, lo stile, i preferiti e la cronologia senza limite,
/// il QR come immagine, il backup.
///
/// ☠ Ogni chiave limitata compare fra i benefici del paywall e viceversa: lo verifica
/// test/widget/paywall_config_test.dart (trappola pagata in TrashCan). E ogni chiave di
/// `FeatureKey.values` e' scritta qui, anche quelle aperte.
const FeatureLimits qrFeatureLimits = <FeatureKey, FeatureLimit>{
  // Cronologia: 5 righe VERE (le altre si cancellano con pruneHistory, F17.1.4).
  FeatureKey.fullHistory: FeatureLimit.count(freeMax: 5),

  // ⚑ Un preferito gratis e non zero (F17.0 punto 6): fa capire a cosa servono (il Wi-Fi di
  // casa sempre a portata) e rende il limite comprensibile. Se il proprietario preferisce zero,
  // si cambia questa riga e il test di coerenza.
  FeatureKey.unlimitedEntities: FeatureLimit.count(freeMax: 1),

  // I moduli Wi-Fi, contatto, email, SMS, telefono. ⚑ Un QR LETTO con un modulo speciale si
  // mostra e si ri-mostra gratis: il Pro serve a compilarne o modificarne uno.
  FeatureKey.customCategories: FeatureLimit.locked(),

  // Colori, forma dei moduli e degli occhi, logo.
  FeatureKey.themeCustomization: FeatureLimit.locked(),

  // Condividere il QR come PNG (chiave nata con QR Me, F17.2a).
  FeatureKey.imageExport: FeatureLimit.locked(),

  // Il backup e' Pro; il ripristino resta gratis, come nelle altre app.
  FeatureKey.backupRestore: FeatureLimit.locked(),

  // Aperte: QR Me non le vende o non le ha. Stare qui rende leggibile cosa NON e' a pagamento
  // e tiene buono l'assert di FeatureGate.
  FeatureKey.secondaryEntities: FeatureLimit.open(),
  FeatureKey.photos: FeatureLimit.open(),
  FeatureKey.statistics: FeatureLimit.open(),
  FeatureKey.csvExport: FeatureLimit.open(),
  FeatureKey.pdfReport: FeatureLimit.open(),
  FeatureKey.advancedWidget: FeatureLimit.open(),
  FeatureKey.notifications: FeatureLimit.open(),
  FeatureKey.multipleNotifications: FeatureLimit.open(),
  FeatureKey.calendarSync: FeatureLimit.open(),
};
