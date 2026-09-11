/// I percorsi di navigazione di TrashCan, in un posto solo.
///
/// Stanno in costanti e non in stringhe sparse perche' le notifiche e il widget
/// Android aprono l'app con un deep link (ADR-005): un percorso scritto a mano in due
/// posti diversi diverge, e il sintomo e' un tap sulla notifica che non porta da
/// nessuna parte.
abstract final class Routes {
  static const String home = '/';
  static const String onboarding = '/onboarding';

  static const String calendars = '/calendars';
  static const String calendarNew = '/calendars/new';
  static const String calendarEdit = '/calendars/:calendarId/edit';

  static const String wasteTypes = '/waste-types';
  static const String wasteTypeNew = '/waste-types/new';
  static const String wasteTypeEdit = '/waste-types/:wasteTypeId/edit';

  static const String rules = '/waste-types/:wasteTypeId/rules';
  static const String ruleNew = '/waste-types/:wasteTypeId/rules/new';
  static const String ruleEdit = '/waste-types/:wasteTypeId/rules/:ruleId/edit';

  static const String exceptions = '/exceptions';
  static const String day = '/day/:date';

  static const String backup = '/settings/backup';

  static const String restore = '/settings/restore';

  static const String settings = '/settings';
  static const String notifications = '/settings/notifications';
  static const String about = '/settings/about';
  static const String paywall = '/pro';

  /// Il percorso del giorno, con la data gia' inserita.
  static String dayOf(String isoDate) => '/day/$isoDate';

  static String calendarEditOf(int id) => '/calendars/$id/edit';

  static String wasteTypeEditOf(int id) => '/waste-types/$id/edit';

  static String rulesOf(int wasteTypeId) => '/waste-types/$wasteTypeId/rules';

  /// Schema dei deep link che arrivano dalle notifiche e dal widget.
  ///
  /// Esempio: `trashcan://day/2026-09-10`.
  static const String scheme = 'trashcan';
}
