import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:micro_ocr/micro_ocr.dart';
import 'package:spending_review/domain/lettura/scontrino_parser.dart';
import 'package:spending_review/services/lettura_service.dart';

import '../domain/righe_finte.dart';

/// `LetturaService` con il motore finto (develop_microapps.md F12.1.17): cartellino, bilancia
/// riconosciuta da sola, niente letto, OCR assente, scontrino in piu' parti; e soprattutto
/// ☠ **le foto temporanee non esistono piu' dopo ogni chiamata, anche con un errore** (F12.1.13).
void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('sr_lettura_'));
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  /// Una «foto» finta: il motore finto non la apre, conta solo che esista e poi sparisca.
  String foto([String nome = 'foto.jpg']) {
    final f = File('${tmp.path}/$nome')..writeAsBytesSync([0xFF, 0xD8, 0xFF]);
    return f.path;
  }

  /// Le righe di una fixture del banco (test/fixtures/ocr/ppocrv5).
  List<RigaOcr> fixture(String nome) {
    final json = jsonDecode(File('test/fixtures/ocr/ppocrv5/$nome.json').readAsStringSync()) as Map<String, Object?>;
    return [for (final r in json['righe']! as List<Object?>) RigaOcr.fromJson(r! as Map<String, Object?>)];
  }

  LetturaService servizio(FakeOcrEngine motore, {bool cancellabile = true}) => LetturaService(
    motore: motore,
    ora: () => DateTime(2026, 10, 11, 10),
    cancellabile: (_) async => cancellabile,
  );

  // Un cartellino semplice: nome in alto, prezzo grande sotto.
  final cartellino = [
    r('PASTA FUSILLI 500 g', 0.08, 0.10, 0.70, 0.08),
    r('2,49', 0.30, 0.40, 0.40, 0.25),
  ];

  group('cartellino', () {
    test('un cartellino letto torna come LettoCartellino, e la foto sparisce', () async {
      final f = foto();
      final motore = FakeOcrEngine(righe: cartellino);
      final r = await servizio(motore).cartellino(f, forzaBilancia: false);
      expect(r, isA<LettoCartellino>());
      expect((r as LettoCartellino).lettura.proposte.first.prezzo, Money.cents(249));
      expect(motore.modi.single, OcrModo.cartellino);
      expect(File(f).existsSync(), isFalse);
    });

    test("un'etichetta della bilancia si riconosce da sola, anche in modo Cartellino (niente terzo tasto)", () async {
      final f = foto();
      final r = await servizio(FakeOcrEngine(righe: fixture('b07_rewe_nettarine'))).cartellino(f, forzaBilancia: false);
      expect(r, isA<LettaBilancia>());
      expect((r as LettaBilancia).lettura.utile, isTrue);
      expect(File(f).existsSync(), isFalse);
    });

    test("forzata la bilancia si obbedisce all'utente: il prezzo diventa il totale dell'etichetta", () async {
      final esito = await servizio(FakeOcrEngine(righe: cartellino)).cartellino(foto(), forzaBilancia: true);
      expect((esito as LettaBilancia).lettura.totale, Money.cents(249));
    });

    test('forzata la bilancia senza nessun importo: si ripiega sul cartellino (niente da leggere)', () async {
      final esito = await servizio(FakeOcrEngine(righe: [r('Prezzo al kg', 0.1, 0.1, 0.6, 0.1)]))
          .cartellino(foto(), forzaBilancia: true);
      expect(esito, isA<NienteLetto>());
    });

    test('niente righe: NienteLetto senza «forse a mano»', () async {
      final f = foto();
      final r = await servizio(FakeOcrEngine()).cartellino(f, forzaBilancia: false);
      expect(r, isA<NienteLetto>());
      expect((r as NienteLetto).forseAMano, isFalse);
      expect(File(f).existsSync(), isFalse);
    });

    test('testo senza prezzo (lo scritto a mano): NienteLetto con «forse a mano»', () async {
      final esito = await servizio(FakeOcrEngine(righe: [r('Pomodori del Vesuvio', 0.1, 0.1, 0.8, 0.1)]))
          .cartellino(foto(), forzaBilancia: false);
      expect((esito as NienteLetto).forseAMano, isTrue);
    });

    test('motore assente: OcrAssente, mai un crash, e la foto sparisce', () async {
      final f = foto();
      final r = await servizio(FakeOcrEngine(errore: OcrNonDisponibile(StateError('nessun motore'))))
          .cartellino(f, forzaBilancia: false);
      expect(r, isA<OcrAssente>());
      expect(File(f).existsSync(), isFalse);
    });

    test('un errore inatteso del motore passa, ma la foto sparisce lo stesso', () async {
      final f = foto();
      await expectLater(
        servizio(FakeOcrEngine(errore: StateError('rotto'))).cartellino(f, forzaBilancia: false),
        throwsStateError,
      );
      expect(File(f).existsSync(), isFalse);
    });

    test('☠ una foto fuori dalle cartelle temporanee (un originale) non si tocca mai', () async {
      final f = foto();
      await servizio(FakeOcrEngine(righe: cartellino), cancellabile: false).cartellino(f, forzaBilancia: false);
      expect(File(f).existsSync(), isTrue);
    });
  });

  group('scontrino', () {
    test('le parti si leggono in modo scontrino, in ordine, e spariscono tutte', () async {
      final a = foto('a.jpg');
      final b = foto('b.jpg');
      final motore = FakeOcrEngine(righe: fixture('s01_documento_commerciale_iva_kg'));
      final letto = await servizio(motore).scontrino([a, b]);
      expect(motore.letti, [a, b]);
      expect(motore.modi, everyElement(OcrModo.scontrino));
      expect(letto.parti, 2);
      expect(letto.giunzioniTrovate, hasLength(1));
      expect(letto.lettura.totale, isNotNull);
      expect(File(a).existsSync(), isFalse);
      expect(File(b).existsSync(), isFalse);
    });

    test('motore assente: OcrNonDisponibile esce, e le foto spariscono', () async {
      final a = foto('a.jpg');
      await expectLater(
        servizio(FakeOcrEngine(errore: OcrNonDisponibile(StateError('x')))).scontrino([a]),
        throwsA(isA<OcrNonDisponibile>()),
      );
      expect(File(a).existsSync(), isFalse);
    });

    test('ScontrinoLetto conta le giunzioni mancanti', () {
      const letto = ScontrinoLetto(
        lettura: LetturaScontrino(righe: [], righeIgnorate: 0),
        giunzioniTrovate: [true, false, false],
      );
      expect(letto.parti, 4);
      expect(letto.giunzioniMancanti, 2);
    });
  });
}
