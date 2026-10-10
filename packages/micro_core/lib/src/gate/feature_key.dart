/// Le categorie di valore che le MicroApps vendono.
///
/// E' una enum condivisa, non una lista per app, perche' le quattro app vendono
/// sostanzialmente le stesse cose sotto nomi diversi: il secondo calendario di
/// TrashCan, il secondo freezer di Full Freezer e la seconda fonte di Scorte Calore
/// sono lo stesso concetto ([unlimitedEntities]). Una enum comune permette di scrivere
/// una sola pagina di paywall che elenca i benefici leggendo la mappa dei limiti,
/// invece di quattro liste di testi che divergono al primo ritocco.
///
/// Aggiungere una voce qui e' una modifica che tocca tutte e quattro le app: si fa solo
/// quando la funzione esiste davvero in almeno una, e si documenta nell'atlante.
enum FeatureKey {
  /// L'entita' principale dell'app: calendari, freezer, fonti di combustibile,
  /// rullini. Nel piano gratuito ne esiste un numero limitato.
  unlimitedEntities,

  /// Entita' di contorno: macchine fotografiche, scomparti aggiuntivi.
  secondaryEntities,

  /// Allegare fotografie ai record.
  photos,

  /// Grafici e aggregazioni.
  statistics,

  /// Storico completo invece che troncato a un numero di giorni o di record.
  fullHistory,

  /// Esportazione in CSV.
  csvExport,

  /// Riepilogo in PDF.
  pdfReport,

  /// Backup completo e ripristino.
  backupRestore,

  /// Widget home screen nella versione ricca.
  advancedWidget,

  /// I promemoria in se': l'app avvisa, oppure resta un registro da consultare.
  ///
  /// ⛑ Distinta da [multipleNotifications], che vende il *secondo* orario. Un'app puo'
  /// regalare il promemoria e vendere il secondo, oppure vendere il promemoria e basta:
  /// sono due decisioni commerciali diverse e vanno potute prendere separatamente.
  notifications,

  /// Piu' di un promemoria per evento.
  multipleNotifications,

  /// Sincronizzazione con il calendario del dispositivo.
  calendarSync,

  /// Categorie definite dall'utente oltre a quelle predefinite.
  customCategories,

  /// Colori, icone e tema personalizzabili.
  themeCustomization,

  /// Esportare come immagine un contenuto generato dall'app (es. il QR di QR Me in PNG).
  ///
  /// ⛑ Distinta da [csvExport] e [pdfReport]: e' un'altra decisione commerciale. Aggiunta
  /// il 2026-10-09 con QR Me (F17.2a); le app che non esportano immagini la mappano `open()`
  /// perche' il loro test di coerenza del paywall vuole tutte le chiavi.
  imageExport,

  /// Leggere con la fotocamera un documento lungo e trasformarlo in dati (es. lo scontrino di
  /// Spending Review: controllo alla cassa e registrazione della spesa).
  ///
  /// ⛑ Distinta da [photos] (allegare una foto, gratis nelle altre app) e da [imageExport]
  /// (esportare). Aggiunta il 2026-10-10 con Spending Review (F12.2a); generica perche' F13
  /// la riusera'. Le app che non la usano la mappano `open()`.
  documentScan,
}
