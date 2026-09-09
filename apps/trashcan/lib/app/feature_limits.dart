import 'package:micro_core/micro_core.dart';

/// I limiti del piano gratuito di TrashCan, dichiarati in un posto solo (ADR-017).
///
/// Nessuna pagina scrive `if (isPro)`: si passa sempre da [FeatureGate], costruito da
/// questa mappa. Spostare un tetto e' una riga qui, non un refactoring.
///
/// **Il piano gratuito e' volutamente generoso.** TrashCan gratuito deve essere l'app
/// migliore della sua categoria: se non lo e', non viene installata, e senza
/// installazioni non c'e' nessuno a cui vendere il Pro. Restano gratuiti i tipi di
/// rifiuto illimitati, le regole illimitate, le eccezioni illimitate, il promemoria
/// serale, il widget di base e la condivisione del calendario.
///
/// Il Pro vende il **secondo calendario**: la seconda casa, casa dei genitori,
/// l'ufficio. Chi ne ha bisogno ha gia' dimostrato di avere il problema che l'app
/// risolve, ed e' il profilo che paga volentieri tre euro.
const FeatureLimits trashcanFeatureLimits = <FeatureKey, FeatureLimit>{
  // Calendari: uno gratis, illimitati con Pro.
  FeatureKey.unlimitedEntities: FeatureLimit.count(freeMax: 1),

  // Piu' di un promemoria per la stessa raccolta, es. 18:00 e 20:00.
  FeatureKey.multipleNotifications: FeatureLimit.locked(),

  // Widget a colori, con scelta del calendario e prossimi tre giorni.
  FeatureKey.advancedWidget: FeatureLimit.locked(),

  // Backup completo e ripristino. Da non confondere con la condivisione di un singolo
  // calendario, che resta gratuita: quella e' un canale di acquisizione (un utente ne
  // porta un altro), il backup e' una comodita' personale. Si regala l'acquisizione e
  // si vende la comodita', non il contrario.
  FeatureKey.backupRestore: FeatureLimit.locked(),

  // Colori e icone liberi per ogni tipo di rifiuto.
  FeatureKey.themeCustomization: FeatureLimit.locked(),

  // Esportazione dell'elenco delle raccolte.
  FeatureKey.csvExport: FeatureLimit.locked(),

  // Dichiarate esplicitamente come aperte: TrashCan non le vende e non le limita.
  // Comparire qui evita che l'assert di FeatureGate segnali una chiave dimenticata e
  // rende leggibile, in un colpo d'occhio, cosa NON e' a pagamento.
  FeatureKey.secondaryEntities: FeatureLimit.open(),
  FeatureKey.photos: FeatureLimit.open(),
  FeatureKey.statistics: FeatureLimit.open(),
  FeatureKey.fullHistory: FeatureLimit.open(),
  FeatureKey.pdfReport: FeatureLimit.open(),
  FeatureKey.calendarSync: FeatureLimit.open(),
  FeatureKey.customCategories: FeatureLimit.open(),
};
