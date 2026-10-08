/// I percorsi di navigazione di Film Tracker, in un posto solo.
///
/// ⚑ Fissati tutti insieme prima delle schermate (2026-10-08) perche' tre parti dell'app le
/// scrivono in parallelo e si portano l'una sull'altra: chi scrive il dettaglio del rullino
/// deve sapere dove sta il modulo dello sviluppo senza aspettare chi lo scrive.
abstract final class Routes {
  static const String home = '/';

  static const String settings = '/settings';

  // ── Rullini (F6.6) ──
  /// ⚑ `new` prima di `:rollId`: go_router prova le rotte in ordine.
  static const String rollNew = '/rolls/new';
  static const String roll = '/rolls/:rollId';
  static String rollOf(int id) => '/rolls/$id';
  static const String rollEdit = '/rolls/:rollId/edit';
  static String rollEditOf(int id) => '/rolls/$id/edit';

  // ── Sviluppo e stampe (F6.7) ──
  static const String development = '/rolls/:rollId/development';
  static String developmentOf(int rollId) => '/rolls/$rollId/development';
  static const String printNew = '/rolls/:rollId/prints/new';
  static String printNewOf(int rollId) => '/rolls/$rollId/prints/new';
  static const String printEdit = '/rolls/:rollId/prints/:printId';
  static String printEditOf(int rollId, int printId) => '/rolls/$rollId/prints/$printId';

  // ── Foto (F6.9, gratis) ──
  static const String photo = '/rolls/:rollId/photos/:imageId';
  static String photoOf(int rollId, int imageId) => '/rolls/$rollId/photos/$imageId';

  // ── QR del rullino (F6.12) ──
  static const String qr = '/rolls/:rollId/qr';
  static String qrOf(int rollId) => '/rolls/$rollId/qr';

  // ── Macchine (F6.5) e catalogo pellicole (F6.4) ──
  static const String cameras = '/cameras';
  static const String cameraNew = '/cameras/new';
  static const String cameraEdit = '/cameras/:cameraId';
  static String cameraEditOf(int id) => '/cameras/$id';
  static const String stocks = '/stocks';

  // ── Statistiche (F6.10, Pro) ──
  static const String stats = '/stats';

  /// Lo schema del QR del rullino: `filmtracker://roll/<sequenceNumber>` (F6.12).
  static const String scheme = 'filmtracker';
}
