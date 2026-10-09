/// Ricezione da Share Sheet per le MicroApps (F17.2b).
///
/// Le app importano solo questo file, mai `package:micro_share/src/...`.
/// Vedi `codebase_reference.md` del package.
library;

export 'src/rsi_share_inbox.dart' show RsiShareInbox, payloadsFromMedia;
export 'src/share_inbox.dart' show FakeShareInbox, ShareInbox;
export 'src/shared_payload.dart' show SharedImage, SharedPayload, SharedText;
