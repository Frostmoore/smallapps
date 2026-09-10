/// Nucleo condiviso delle MicroApps.
///
/// Questa e' l'**unica** superficie pubblica del package: le app importano
/// `package:micro_core/micro_core.dart` e mai `package:micro_core/src/...`.
/// Quello che non compare qui e' dettaglio interno e puo' cambiare senza preavviso.
///
/// Regola non negoziabile: `micro_core` non conosce nessuna delle quattro app. Non
/// esiste un `if (appId == 'trashcan')` da nessuna parte. Tutto cio' che varia si
/// passa come parametro, cosi' che aggiungere una quinta app non richieda di toccare
/// una riga di questo package.
library;
export 'src/backup/backup.dart';
export 'src/billing/fake_purchase_gateway.dart';
export 'src/billing/play_purchase_gateway.dart';
export 'src/billing/purchase_gateway.dart';
export 'src/config/micro_app_config.dart';
export 'src/entitlement/entitlement.dart';
export 'src/entitlement/entitlement_service.dart';
export 'src/entitlement/entitlement_store.dart';
export 'src/entitlement/license_api_client.dart';
export 'src/export/csv_writer.dart';
export 'src/gate/feature_gate.dart';
export 'src/gate/feature_key.dart';
export 'src/gate/feature_limits.dart';
export 'src/gate/paywall.dart';
export 'src/install/install_id.dart';
export 'src/notifications/notification_scheduler.dart';
export 'src/notifications/notification_service.dart';
export 'src/prefs/settings_store.dart';
export 'src/storage/app_paths.dart';
export 'src/storage/image_store.dart';
export 'src/theme/micro_theme.dart';
export 'src/theme/micro_tokens.dart';
export 'src/ui/micro_widgets.dart';
export 'src/util/civil_date.dart';
export 'src/util/micro_log.dart';
export 'src/util/money.dart';
export 'src/util/result.dart';
