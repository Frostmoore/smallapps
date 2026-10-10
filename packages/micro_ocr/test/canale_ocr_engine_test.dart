import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_ocr/micro_ocr.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canale = MethodChannel('micro_ocr_test');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final chiamate = <MethodCall>[];

  void risponde(Future<Object?>? Function(MethodCall c) gestore) {
    messenger.setMockMethodCallHandler(canale, (c) {
      chiamate.add(c);
      return gestore(c);
    });
  }

  setUp(chiamate.clear);
  tearDown(() => messenger.setMockMethodCallHandler(canale, null));

  test('leggi passa percorso e modo e converte le mappe (Android, origine in alto)', () async {
    risponde(
      (c) async => [
        {'t': '2,49', 'x': 0.4, 'y': 0.3, 'w': 0.2, 'h': 0.1, 'c': 0.9},
      ],
    );
    final righe = await CanaleOcrEngine(canale: canale).leggi('/tmp/a.jpg', modo: OcrModo.scontrino);
    expect(chiamate.single.method, 'leggi');
    expect(chiamate.single.arguments, {'percorso': '/tmp/a.jpg', 'modo': 'scontrino'});
    expect(righe.single.testo, '2,49');
    expect(righe.single.riquadro.alto, 0.3);
    expect(righe.single.confidenza, 0.9);
  });

  test('origine basso (iOS Vision) si converte con daVision', () async {
    risponde(
      (c) async => [
        {'t': 'TOTALE', 'x': 0.1, 'y': 0.0, 'w': 0.5, 'h': 0.1, 'c': 1.0, 'origine': 'basso'},
      ],
    );
    final righe = await CanaleOcrEngine(canale: canale).leggi('p', modo: OcrModo.cartellino);
    expect(righe.single.riquadro.alto, closeTo(0.9, 1e-12));
    expect(righe.single.riquadro.sinistra, 0.1);
  });

  test('null dal canale = nessuna riga', () async {
    risponde((c) async => null);
    expect(await CanaleOcrEngine(canale: canale).leggi('p', modo: OcrModo.cartellino), isEmpty);
  });

  test('nome, prepara, rilascia', () async {
    risponde((c) async => c.method == 'nome' ? 'ppocrv5-ort-1.28.0' : null);
    final motore = CanaleOcrEngine(canale: canale);
    expect(await motore.nome(), 'ppocrv5-ort-1.28.0');
    await motore.prepara();
    await motore.rilascia();
    expect(chiamate.map((c) => c.method), ['nome', 'prepara', 'rilascia']);
  });

  test("PlatformException('non_disponibile') diventa OcrNonDisponibile", () async {
    risponde((c) async => throw PlatformException(code: 'non_disponibile', message: 'modelli'));
    final motore = CanaleOcrEngine(canale: canale);
    await expectLater(
      motore.leggi('p', modo: OcrModo.cartellino),
      throwsA(isA<OcrNonDisponibile>().having((e) => e.causa, 'causa', isA<PlatformException>())),
    );
    await expectLater(motore.prepara(), throwsA(isA<OcrNonDisponibile>()));
  });

  test('MissingPluginException (nessun plugin) diventa OcrNonDisponibile', () async {
    // Nessun gestore registrato: il canale lancia MissingPluginException.
    final motore = CanaleOcrEngine(canale: canale);
    await expectLater(
      motore.leggi('p', modo: OcrModo.cartellino),
      throwsA(isA<OcrNonDisponibile>().having((e) => e.causa, 'causa', isA<MissingPluginException>())),
    );
    await expectLater(motore.nome(), throwsA(isA<OcrNonDisponibile>()));
  });
}
