import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:micro_core/micro_core.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Chiede al sistema se il riconoscimento **sul telefono** c'e' per [localeId] ("it_IT").
typedef OnDeviceProbe = Future<bool> Function(String localeId);

/// Perche' la dettatura non e' partita (o si e' fermata).
enum VoiceProblem {
  /// Il telefono non sa riconoscere la voce da solo per questa lingua: niente server, quindi
  /// niente dettatura. Si scrive (anche con il microfono della tastiera).
  notOnDevice,

  /// Permesso negato o nessun riconoscitore: si sistema dalle impostazioni del telefono.
  unavailable,
}

/// Il microfono dell'inserimento rapido (F4.12): ascolta una frase e la restituisce come
/// testo. Il significato lo estrae `VoiceItemParser`, qui non si interpreta niente.
///
/// ⚑ **Solo sul telefono** (decisione del 2026-10-10, regola "dati solo sul telefono"): la
/// voce non va ai server di Apple ne' di Google, mai. `onDevice: true` da solo NON basta, per
/// come e' fatto speech_to_text 7.5.0:
/// - ☠ **Android**: se `SpeechRecognizer.isOnDeviceRecognitionAvailable` e' falso (o API
///   < 31) il plugin crea **in silenzio** il riconoscitore normale, che usa la rete, e si
///   limita a chiedergli `EXTRA_PREFER_OFFLINE` (una preferenza, non un vincolo).
/// - ☠ **iOS**: con un riconoscitore senza modello locale il plugin risponde `onDeviceError`
///   ma **non esce** dal metodo (manca un `return`) e risponde una seconda volta al canale.
///   La richiesta resta `requiresOnDeviceRecognition = true`, quindi niente server, ma e'
///   un percorso rotto da non percorrere.
///
/// Percio' prima di ascoltare si chiede al sistema, con un canale nostro
/// (`full_freezer/voice`, in `MainActivity.kt` e `AppDelegate.swift`), se il riconoscimento
/// sul telefono c'e'. Se non c'e', o se la domanda fallisce, non si ascolta: **nessun
/// ripiego verso i server**, mai.
///
/// ⚑ Un oggetto per foglio: lo stato del foglio (sta ascoltando, a chi vanno gli errori)
/// muore con il foglio. Il motore sotto (`SpeechToText()`) e' invece un singleton del
/// plugin: per questo [prepare] rilega i listener a ogni foglio.
class VoiceInput {
  VoiceInput({SpeechToText? engine, OnDeviceProbe? probe})
    : _engine = engine ?? SpeechToText(),
      _probe = probe ?? _askPlatform;

  final SpeechToText _engine;
  final OnDeviceProbe _probe;

  static const _channel = MethodChannel('full_freezer/voice');

  /// Errori del motore, arrivati mentre si ascolta, che vogliono dire «questa lingua sul
  /// telefono non c'e'»: Android (`ERROR_LANGUAGE_NOT_SUPPORTED`/`UNAVAILABLE`, modello
  /// della lingua non scaricato) e iOS (codice 102, asset non installati).
  ///
  /// ⚑ Gli altri errori (nessuna parola capita, silenzio) restano solo nel log, come prima:
  /// non sono un problema da spiegare, basta riprovare.
  @visibleForTesting
  static const notOnDeviceErrors = {
    'error_language_not_supported',
    'error_language_unavailable',
    'error_assets_not_installed',
  };

  bool get isListening => _engine.isListening;

  /// True se il telefono sa riconoscere [languageTag] ("it", "en") senza server.
  ///
  /// ⚑ Non chiede permessi e non accende niente: si chiama all'apertura del foglio per
  /// mostrare subito il microfono barrato. Se la domanda fallisce (piattaforma senza canale,
  /// test, errore nativo) la risposta e' `false`: nel dubbio non si ascolta.
  Future<bool> onDeviceAvailable(String languageTag) async {
    try {
      return await _probe(localeIdFor(languageTag));
    } on Object catch (error) {
      MicroLog.d("voce: impossibile sapere se c'e' il riconoscimento sul telefono: $error");
      return false;
    }
  }

  /// Controlla che il riconoscimento sul telefono ci sia, poi chiede il permesso del
  /// microfono (la prima volta) e prepara il motore. `null` se si puo' ascoltare.
  ///
  /// ⚑ Prima il controllo e poi il permesso: chi non puo' dettare non deve vedersi chiedere
  /// il microfono per niente. [onProblem] riceve i problemi che arrivano piu' tardi, mentre
  /// si ascolta (vedi [notOnDeviceErrors]).
  Future<VoiceProblem?> prepare({
    required String languageTag,
    void Function(String status)? onStatus,
    void Function(VoiceProblem problem)? onProblem,
  }) async {
    if (!await onDeviceAvailable(languageTag)) return VoiceProblem.notOnDevice;
    void onError(SpeechRecognitionError e) {
      MicroLog.d('voce: ${e.errorMsg}');
      if (notOnDeviceErrors.contains(e.errorMsg)) onProblem?.call(VoiceProblem.notOnDevice);
    }

    try {
      final ok = await _engine.initialize(onStatus: onStatus, onError: onError);
      if (!ok) return VoiceProblem.unavailable;
      // ☠ `SpeechToText()` e' un singleton e `initialize`, gia' riuscito una volta, esce
      // subito senza toccare i listener: dal secondo foglio in poi stato ed errori andavano
      // al primo foglio (gia' chiuso) e il microfono restava "acceso" a vuoto. Si rilegano.
      _engine
        ..statusListener = onStatus
        ..errorListener = onError;
      return null;
    } on Object catch (error) {
      MicroLog.d('riconoscimento vocale non disponibile: $error');
      return VoiceProblem.unavailable;
    }
  }

  /// Ascolta una frase. [onWords] riceve il testo man mano ([isFinal] false) e alla fine
  /// ([isFinal] true). [languageTag] e' la lingua dell'app ("it", "en"). `null` se
  /// l'ascolto e' partito.
  ///
  /// Va chiamato solo dopo un [prepare] andato bene, che ha gia' verificato il
  /// riconoscimento sul telefono.
  Future<VoiceProblem?> listen({
    required String languageTag,
    required void Function(String words, {required bool isFinal}) onWords,
  }) async {
    try {
      await _engine.listen(
        onResult: (r) => onWords(r.recognizedWords, isFinal: r.finalResult),
        listenOptions: listenOptionsFor(languageTag),
      );
      return null;
    } on ListenFailedException catch (error) {
      // iOS: `onDeviceError`, il riconoscitore della lingua non ha il modello locale.
      MicroLog.d('voce: ascolto non partito: ${error.message}');
      return VoiceProblem.notOnDevice;
    } on Object catch (error) {
      MicroLog.d('voce: ascolto non partito: $error');
      return VoiceProblem.unavailable;
    }
  }

  Future<void> stop() => _engine.stop();

  Future<void> cancel() => _engine.cancel();

  /// Le opzioni dell'ascolto. Separate per poterle verificare in un test.
  ///
  /// ⚑ `onDevice: true` sempre, anche dopo il controllo: su iOS diventa
  /// `requiresOnDeviceRecognition`, un vincolo vero (senza modello locale fallisce, non usa
  /// i server), e su Android fa scegliere `createOnDeviceSpeechRecognizer`.
  ///
  /// ⚑ `ListenMode.dictation` e pausa di tre secondi: si detta una frase sola, e chi si
  /// ferma a pensare "due porzioni di... lasagne" non deve vedersi chiudere il microfono a
  /// meta'. Il limite di 15 secondi evita un microfono acceso per sbaglio.
  @visibleForTesting
  static SpeechListenOptions listenOptionsFor(String languageTag) => SpeechListenOptions(
    localeId: localeIdFor(languageTag),
    onDevice: true,
    listenMode: ListenMode.dictation,
    partialResults: true,
    cancelOnError: true,
    pauseFor: const Duration(seconds: 3),
    listenFor: const Duration(seconds: 15),
  );

  /// La lingua del riconoscitore per la lingua dell'app. Fissa e non letta dal telefono:
  /// l'app parla italiano o inglese, e il parser capisce quelle due.
  @visibleForTesting
  static String localeIdFor(String languageTag) => languageTag.startsWith('it') ? 'it_IT' : 'en_US';

  /// ⚑ Un canale nostro e non `SpeechToTextPlatform.hasOnDeviceSupport`: l'interfaccia
  /// 2.5.0 lo dichiara, ma il codice nativo di speech_to_text 7.5.0 non lo implementa
  /// (nessun `has_on_device_support` in Kotlin ne' in Swift), e la chiamata finirebbe in
  /// `MissingPluginException`.
  static Future<bool> _askPlatform(String localeId) async =>
      await _channel.invokeMethod<bool>('onDeviceAvailable', <String, Object?>{'localeId': localeId}) ?? false;
}
