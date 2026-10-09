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

  // ☠ I promemoria **in generale**, non solo i doppi.
  //
  // Decisione del proprietario, 2026-09-11. Vale la pena scrivere qui il compromesso che
  // comporta, perche' e' la scelta commerciale piu' pesante dell'app: TrashCan gratuito
  // diventa un calendario che bisogna ricordarsi di aprire, cioe' non risolve piu' il
  // problema per cui la si installa. Se le installazioni o le recensioni ne risentono,
  // si torna indietro cambiando questa sola riga in `FeatureLimit.open()`.
  FeatureKey.notifications: FeatureLimit.locked(),

  // Piu' di un promemoria per la stessa raccolta, es. 18:00 e 20:00.
  FeatureKey.multipleNotifications: FeatureLimit.locked(),

  // Backup completo e ripristino. Da non confondere con la condivisione di un singolo
  // calendario, che resta gratuita: quella e' un canale di acquisizione (un utente ne
  // porta un altro), il backup e' una comodita' personale. Si regala l'acquisizione e
  // si vende la comodita', non il contrario.
  FeatureKey.backupRestore: FeatureLimit.locked(),

  // Colori e icone liberi per ogni tipo di rifiuto.
  FeatureKey.themeCustomization: FeatureLimit.locked(),
  // Nessuna esportazione di immagini in questa app (chiave nata con QR Me, F17.2a).
  FeatureKey.imageExport: FeatureLimit.open(),


  // Dichiarate esplicitamente come aperte: TrashCan non le vende e non le limita.
  // Comparire qui evita che l'assert di FeatureGate segnali una chiave dimenticata e
  // rende leggibile, in un colpo d'occhio, cosa NON e' a pagamento.
  // TrashCan non ha nessuna esportazione in CSV, e quindi non la vende: un elenco di
  // date di raccolta in un foglio di calcolo non serve a niente a nessuno. Le due
  // esportazioni che esistono sono la condivisione di un calendario (gratuita, e' un
  // canale di acquisizione) e il backup completo (Pro, e' una comodita' personale).
  //
  // ☠ Questa chiave era `locked()`. Bloccare una funzione che non esiste significa che
  // il paywall non la elenca fra i benefici, e prima o poi qualcuno incontra un blocco
  // per qualcosa che l'app non sa fare. Il test in test/widget/paywall_config_test.dart
  // confronta i limiti con i benefici proprio per impedirlo.
  // ☠ Anche questa era `locked()`: il widget mostrava un giorno solo senza il Pro e tre
  // con il Pro. Decisione del proprietario, 2026-09-11, presa guardando il widget vero sul
  // proprio telefono. Una riga sola in mezzo a meta' widget bianca non si legge come
  // "funzione a pagamento": si legge come "il widget e' rotto", ed e' quello che ha
  // pensato lui, che l'app l'ha commissionata.
  //
  // Il conto commerciale: un widget che sembra rotto costa recensioni, e le recensioni
  // costano installazioni. Il Pro resta venduto da cinque cose, e quella che vende davvero
  // e' il promemoria della sera. Questo giorno in piu' non valeva il rischio.
  FeatureKey.advancedWidget: FeatureLimit.open(),

  FeatureKey.csvExport: FeatureLimit.open(),
  FeatureKey.secondaryEntities: FeatureLimit.open(),
  FeatureKey.photos: FeatureLimit.open(),
  FeatureKey.statistics: FeatureLimit.open(),
  FeatureKey.fullHistory: FeatureLimit.open(),
  FeatureKey.pdfReport: FeatureLimit.open(),
  FeatureKey.calendarSync: FeatureLimit.open(),
  FeatureKey.customCategories: FeatureLimit.open(),
};
