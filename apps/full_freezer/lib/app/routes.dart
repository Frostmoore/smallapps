/// I percorsi di navigazione di Full Freezer, in un posto solo.
///
/// Stanno in costanti e non in stringhe sparse perche' le notifiche e il widget aprono
/// l'app con un deep link (ADR-005): un percorso scritto a mano in due posti diverge, e il
/// sintomo e' un tocco sulla notifica che non porta da nessuna parte.
///
/// ⚑ Qui ci sono solo i percorsi che esistono. Gli altri (freezer, alimento, ricerca,
/// statistiche, impostazioni) entrano con le sottofasi che li disegnano: una costante che
/// punta a una pagina inesistente e' un deep link rotto in attesa di essere usato.
abstract final class Routes {
  static const String home = '/';

  /// Schema dei deep link che arrivano dalle notifiche e dal widget.
  static const String scheme = 'fullfreezer';
}
