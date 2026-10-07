import 'package:flutter/foundation.dart';
import 'package:micro_core/micro_core.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Il microfono dell'inserimento rapido (F4.12): ascolta una frase e la restituisce come
/// testo. Il significato lo estrae `VoiceItemParser`, qui non si interpreta niente.
///
/// ⚑ Il riconoscimento lo fa **il telefono** (Google su Android, Apple su iOS), non l'app:
/// l'app non parla con nessun server. Il motore di sistema puo' pero' usare i server del
/// produttore, e l'informativa privacy del sito lo dice (develop_microapps.md F4.12).
///
/// ⚑ Un oggetto per foglio, non un singleton: `SpeechToText` tiene uno stato (sta
/// ascoltando o no) che deve morire con il foglio che l'ha acceso.
class VoiceInput {
  VoiceInput({SpeechToText? engine}) : _engine = engine ?? SpeechToText();

  final SpeechToText _engine;

  bool get isListening => _engine.isListening;

  /// Chiede il permesso del microfono (la prima volta) e prepara il motore.
  ///
  /// `false` se il permesso e' negato o il telefono non ha un riconoscitore: il chiamante
  /// lo dice all'utente, il campo di testo resta li'.
  Future<bool> prepare({void Function(String status)? onStatus}) async {
    try {
      return await _engine.initialize(onStatus: onStatus, onError: (e) => MicroLog.d('voce: ${e.errorMsg}'));
    } on Object catch (error) {
      MicroLog.d('riconoscimento vocale non disponibile: $error');
      return false;
    }
  }

  /// Ascolta una frase. [onWords] riceve il testo man mano ([isFinal] false) e alla fine
  /// ([isFinal] true). [languageTag] e' la lingua dell'app ("it", "en").
  ///
  /// ⚑ `ListenMode.dictation` e pausa di tre secondi: si detta una frase sola, e chi si
  /// ferma a pensare "due porzioni di... lasagne" non deve vedersi chiudere il microfono a
  /// meta'. Il limite di 15 secondi evita un microfono acceso per sbaglio.
  Future<void> listen({
    required String languageTag,
    required void Function(String words, {required bool isFinal}) onWords,
  }) => _engine.listen(
    onResult: (r) => onWords(r.recognizedWords, isFinal: r.finalResult),
    listenOptions: SpeechListenOptions(
      localeId: localeIdFor(languageTag),
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: true,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 15),
    ),
  );

  Future<void> stop() => _engine.stop();

  Future<void> cancel() => _engine.cancel();

  /// La lingua del riconoscitore per la lingua dell'app. Fissa e non letta dal telefono:
  /// l'app parla italiano o inglese, e il parser capisce quelle due.
  @visibleForTesting
  static String localeIdFor(String languageTag) => languageTag.startsWith('it') ? 'it_IT' : 'en_US';
}
