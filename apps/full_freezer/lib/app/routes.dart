/// I percorsi di navigazione di Full Freezer, in un posto solo.
///
/// Stanno in costanti e non in stringhe sparse perche' le notifiche e il widget aprono
/// l'app con un deep link (ADR-005): un percorso scritto a mano in due posti diverge, e il
/// sintomo e' un tocco sulla notifica che non porta da nessuna parte.
///
/// ⚑ Qui ci sono solo i percorsi che esistono. Gli altri (ricerca, statistiche,
/// impostazioni) entrano con le sottofasi che li disegnano: una costante che punta a una
/// pagina inesistente e' un deep link rotto in attesa di essere usato.
abstract final class Routes {
  static const String home = '/';

  /// Il primo avvio: la creazione del primo freezer (F4.6).
  static const String welcome = '/welcome';

  static const String useSoon = '/use-soon';

  static const String search = '/search';

  static const String settings = '/settings';

  static const String freezerNew = '/freezers/new';
  static const String freezer = '/freezers/:freezerId';
  static const String freezerEdit = '/freezers/:freezerId/edit';

  /// Nuovo alimento dalla pagina completa. La bozza dell'inserimento rapido arriva in
  /// `extra` (un `ItemDraft`), non nel percorso: e' uno stato in memoria, non un link.
  static const String itemNew = '/items/new';
  static const String itemEdit = '/items/:itemId';

  static String freezerOf(int id) => '/freezers/$id';
  static String freezerEditOf(int id) => '/freezers/$id/edit';
  static String itemEditOf(int id) => '/items/$id';

  /// Schema dei deep link che arrivano dalle notifiche e dal widget.
  static const String scheme = 'fullfreezer';
}
