import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'share_inbox.dart';
import 'shared_payload.dart';

/// [ShareInbox] vera, su `receive_sharing_intent` 1.9.
///
/// Android: intent `ACTION_SEND` sulla `MainActivity` (`launchMode="singleTask"`).
/// iOS: estensione di condivisione creata da `tool/aggiungi_share_extension_ios.rb`, che
/// salva nell'App Group e riapre l'app con lo schema `ShareMedia-<bundle id>`.
class RsiShareInbox implements ShareInbox {
  /// `plugin:` si passa solo nei test; di norma resta `null` e si usa
  /// `ReceiveSharingIntent.instance`. (Parametro formale privato: chi chiama scrive
  /// `RsiShareInbox(plugin: ...)`, senza trattino basso.)
  RsiShareInbox({this._plugin});

  final ReceiveSharingIntent? _plugin;

  // ☠ Letto a ogni uso e non fissato nel costruttore: `ReceiveSharingIntent.setMockValues`
  //   sostituisce l'istanza statica, e un riferimento preso prima resterebbe quello vero.
  ReceiveSharingIntent get _rsi => _plugin ?? ReceiveSharingIntent.instance;

  @override
  Future<List<SharedPayload>> initial() async => payloadsFromMedia(await _rsi.getInitialMedia());

  @override
  Stream<List<SharedPayload>> get incoming =>
      _rsi.getMediaStream().map(payloadsFromMedia).where((p) => p.isNotEmpty);

  @override
  Future<void> reset() async {
    await _rsi.reset();
  }
}

/// Converte cio' che consegna il plugin nei due casi che le app trattano.
///
/// - `SharedMediaType.text` e `SharedMediaType.url` → [SharedText] con il valore di
///   `path` (il plugin ci mette il testo o l'URL, non un percorso), ripulito degli spazi;
/// - `SharedMediaType.image` → [SharedImage] con il percorso del file gia' copiato;
/// - `SharedMediaType.video` e `SharedMediaType.file` → ignorati;
/// - testi vuoti (o di soli spazi) e immagini senza percorso → scartati;
/// - lo stesso elemento ripetuto nella stessa consegna → tenuto una volta sola (Safari puo'
///   allegare la stessa pagina due volte), nell'ordine di arrivo.
///
/// Funzione pura: e' la parte che i test coprono senza piattaforma.
List<SharedPayload> payloadsFromMedia(List<SharedMediaFile> files) {
  final out = <SharedPayload>[];
  for (final file in files) {
    final SharedPayload? payload = switch (file.type) {
      SharedMediaType.text || SharedMediaType.url => _text(file.path),
      SharedMediaType.image => file.path.trim().isEmpty ? null : SharedImage(file.path),
      SharedMediaType.video || SharedMediaType.file => null,
    };
    if (payload != null && !out.contains(payload)) out.add(payload);
  }
  return List<SharedPayload>.unmodifiable(out);
}

SharedText? _text(String value) {
  final text = value.trim();
  return text.isEmpty ? null : SharedText(text);
}
