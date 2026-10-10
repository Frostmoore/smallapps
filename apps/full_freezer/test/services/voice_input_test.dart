import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/services/voice_input.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Un motore finto: registra cosa gli si chiede, non tocca microfono ne' canali.
///
/// ⚑ `noSuchMethod` e non override uno per uno: `listen` ha una dozzina di parametri
/// deprecati, e una firma ricopiata a mano si rompe al primo aggiornamento del plugin.
class MotoreFinto implements SpeechToText {
  MotoreFinto({this.initOk = true});

  final bool initOk;
  int inizializzazioni = 0;
  final ascolti = <SpeechListenOptions>[];
  Object? erroreAscolto;
  void Function(SpeechRecognitionError)? onError;

  @override
  dynamic noSuchMethod(Invocation i) {
    switch (i.memberName) {
      case #initialize:
        inizializzazioni++;
        onError = i.namedArguments[#onError] as void Function(SpeechRecognitionError)?;
        return Future.value(initOk);
      case #listen:
        final errore = erroreAscolto;
        if (errore != null) return Future<void>.error(errore);
        ascolti.add(i.namedArguments[#listenOptions]! as SpeechListenOptions);
        return Future<void>.value();
      case #isListening:
        return false;
      case #stop:
      case #cancel:
        return Future<void>.value();
    }
    return null; // i setter statusListener/errorListener
  }
}

/// Decisione del 2026-10-10 (regola "dati solo sul telefono"): la dettatura e' solo sul
/// dispositivo, mai sui server di Apple o Google, e senza ripieghi.
void main() {
  group('solo sul telefono', () {
    test('le opzioni chiedono sempre il riconoscimento sul dispositivo', () {
      for (final lingua in ['it', 'en']) {
        expect(VoiceInput.listenOptionsFor(lingua).onDevice, isTrue, reason: lingua);
      }
      expect(VoiceInput.listenOptionsFor('it').localeId, 'it_IT');
      expect(VoiceInput.listenOptionsFor('en').localeId, 'en_US');
    });

    test('listen passa onDevice: true al motore', () async {
      final motore = MotoreFinto();
      final voce = VoiceInput(engine: motore, probe: (_) async => true);
      expect(await voce.prepare(languageTag: 'it'), isNull);
      expect(await voce.listen(languageTag: 'it', onWords: (_, {required isFinal}) {}), isNull);
      expect(motore.ascolti.single.onDevice, isTrue);
      expect(motore.ascolti.single.localeId, 'it_IT');
    });

    test('il controllo riceve la lingua del riconoscitore', () async {
      final chieste = <String>[];
      final voce = VoiceInput(
        engine: MotoreFinto(),
        probe: (id) async {
          chieste.add(id);
          return true;
        },
      );
      await voce.prepare(languageTag: 'it');
      expect(chieste, ['it_IT']);
    });

    test('senza riconoscimento sul telefono: non chiede il permesso e non ascolta', () async {
      final motore = MotoreFinto();
      final voce = VoiceInput(engine: motore, probe: (_) async => false);
      expect(await voce.prepare(languageTag: 'it'), VoiceProblem.notOnDevice);
      expect(motore.inizializzazioni, 0, reason: 'niente richiesta del microfono per niente');
      expect(motore.ascolti, isEmpty);
    });

    test('se il controllo fallisce, nel dubbio non si ascolta', () async {
      final motore = MotoreFinto();
      final voce = VoiceInput(engine: motore, probe: (_) => Future<bool>.error(StateError('canale assente')));
      expect(await voce.onDeviceAvailable('it'), isFalse);
      expect(await voce.prepare(languageTag: 'it'), VoiceProblem.notOnDevice);
      expect(motore.inizializzazioni, 0);
    });

    test('permesso negato: problema diverso, da sistemare nelle impostazioni', () async {
      final voce = VoiceInput(engine: MotoreFinto(initOk: false), probe: (_) async => true);
      expect(await voce.prepare(languageTag: 'it'), VoiceProblem.unavailable);
    });

    test('iOS: onDeviceError all\'avvio diventa "non disponibile sul telefono"', () async {
      final motore = MotoreFinto()..erroreAscolto = ListenFailedException('on device recognition is not supported');
      final voce = VoiceInput(engine: motore, probe: (_) async => true);
      await voce.prepare(languageTag: 'it');
      expect(await voce.listen(languageTag: 'it', onWords: (_, {required isFinal}) {}), VoiceProblem.notOnDevice);
    });

    test('Android: modello della lingua mancante mentre si ascolta lo dice; il silenzio no', () async {
      final motore = MotoreFinto();
      final problemi = <VoiceProblem>[];
      final voce = VoiceInput(engine: motore, probe: (_) async => true);
      await voce.prepare(languageTag: 'it', onProblem: problemi.add);
      motore.onError!(SpeechRecognitionError('error_no_match', true));
      expect(problemi, isEmpty, reason: 'nessuna parola capita: si riprova, non e\' un problema');
      motore.onError!(SpeechRecognitionError('error_language_unavailable', true));
      expect(problemi, [VoiceProblem.notOnDevice]);
    });
  });
}
