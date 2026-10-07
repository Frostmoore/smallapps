/// I percorsi di navigazione di Scorte Calore, in un posto solo.
///
/// Stanno in costanti perche' le notifiche e il widget aprono l'app con un deep link
/// (ADR-005): un percorso scritto a mano in due posti diverge.
///
/// ⚑ Qui ci sono solo i percorsi che esistono: una costante che punta a una pagina
/// inesistente e' un deep link rotto in attesa di essere usato.
abstract final class Routes {
  static const String home = '/';

  /// Il primo avvio: la configurazione della prima fonte (F5.5).
  static const String welcome = '/welcome';

  static const String settings = '/settings';

  /// Nuova fonte (oltre la prima passa da `openNewSource`, che controlla il limite gratuito).
  static const String sourceNew = '/sources/new';
  static const String sourceEdit = '/sources/:sourceId/edit';
  static String sourceEditOf(int id) => '/sources/$id/edit';

  /// Schema dei deep link che arrivano dalle notifiche e dal widget.
  static const String scheme = 'scortecalore';
}
