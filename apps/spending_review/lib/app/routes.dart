import '../domain/lettura/scontrino_parser.dart';
import '../domain/spesa.dart';

/// I percorsi di navigazione di Spending Review, in un posto solo (develop_microapps.md F12.1.11).
///
/// ⚑ Fissati tutti insieme con il bootstrap (F12.2c), prima delle schermate: F12.4 le scrive, e
/// chi fa una pagina deve sapere dove sta l'altra senza aspettarla. Le pagine che non esistono
/// ancora non sono registrate nel router (`app.dart`): un percorso qui senza pagina porta a «Non
/// trovato», mai a un crash.
abstract final class Routes {
  /// LA schermata: la spesa in corso (creata pigramente al primo «+» o cartellino).
  static const String spesa = '/';

  /// Mirino del cartellino; torna (`pop`) con un `RisultatoCartellino`.
  static const String cartellino = '/cartellino';

  /// Lo stesso mirino in modalita' bilancia (dal foglio del peso).
  static const String cartellinoBilancia = '/cartellino?modo=bilancia';

  /// Pro, `ProGate(FeatureKey.documentScan)` sulla pagina.
  static const String scontrino = '/scontrino';

  /// Pro; `extra: LetturaScontrino`.
  static const String confronto = '/scontrino/confronto';

  /// Pro; `extra: LetturaScontrino`.
  static const String registra = '/scontrino/registra';

  /// `extra: ChiusuraArgs`.
  static const String chiudi = '/chiudi';

  /// Gratis: ultime 5.
  static const String storico = '/storico';

  /// Una spesa nascosta (oltre le 5) dal gratis → paywall, non la pagina.
  static const String dettaglio = '/storico/:id';
  static String dettaglioDi(int id) => '/storico/$id';

  /// Pro, `ProGate(FeatureKey.statistics)`.
  static const String statistiche = '/statistiche';

  static const String impostazioni = '/impostazioni';
  static const String negozi = '/impostazioni/negozi';

  /// SOLO sviluppo (`kDebugMode` o `--dart-define=SR_DEV=true`): in release la rotta non esiste.
  static const String devOcr = '/dev/ocr';

  // ⚑ Nessuna rotta `/pro`: il paywall si apre sempre con `showSrPaywall` (§8.T).
}

/// Cio' che serve a `/chiudi`: quale insieme di righe fa fede e lo scontrino letto, se c'e'.
final class ChiusuraArgs {
  const ChiusuraArgs({this.fonte = FonteRighe.contate, this.lettura});

  final FonteRighe fonte;
  final LetturaScontrino? lettura;
}

/// La rotta di sviluppo `/dev/ocr` esiste? ⚑ Una funzione con i due interruttori iniettati, e non
/// una costante: il test `dev_route_test.dart` (F12.4) la prova con entrambi falsi.
bool rottaDevAttiva({required bool debug, required bool srDev}) => debug || srDev;

/// `--dart-define=SR_DEV=true`.
const bool kSrDev = bool.fromEnvironment('SR_DEV');
