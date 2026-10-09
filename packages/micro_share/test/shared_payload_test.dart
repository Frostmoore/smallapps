import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:micro_share/micro_share.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

SharedMediaFile _media(String path, SharedMediaType type, {String? mimeType}) =>
    SharedMediaFile(path: path, type: type, mimeType: mimeType);

void main() {
  group('payloadsFromMedia', () {
    test('un testo diventa SharedText', () {
      final out = payloadsFromMedia([
        _media('ciao mondo', SharedMediaType.text, mimeType: 'text/plain'),
      ]);
      expect(out, [const SharedText('ciao mondo')]);
    });

    test('un url diventa SharedText con il link (il plugin lo mette in path)', () {
      final out = payloadsFromMedia([_media('https://example.com/a?b=1', SharedMediaType.url)]);
      expect(out, [const SharedText('https://example.com/a?b=1')]);
    });

    test("un'immagine diventa SharedImage con il percorso", () {
      final out = payloadsFromMedia([
        _media('/data/cache/foto.jpg', SharedMediaType.image, mimeType: 'image/jpeg'),
      ]);
      expect(out, [const SharedImage('/data/cache/foto.jpg')]);
    });

    test('video e file generici sono ignorati', () {
      final out = payloadsFromMedia([
        _media('/data/cache/film.mp4', SharedMediaType.video),
        _media('/data/cache/doc.pdf', SharedMediaType.file),
      ]);
      expect(out, isEmpty);
    });

    test('consegna mista: tiene testo e immagine nell ordine, scarta il video', () {
      final out = payloadsFromMedia([
        _media('/c/v.mp4', SharedMediaType.video),
        _media('Guarda qui', SharedMediaType.text),
        _media('/c/i.png', SharedMediaType.image),
        _media('https://x.it', SharedMediaType.url),
      ]);
      expect(out, [
        const SharedText('Guarda qui'),
        const SharedImage('/c/i.png'),
        const SharedText('https://x.it'),
      ]);
    });

    test('testi vuoti o di soli spazi sono scartati, gli altri ripuliti', () {
      final out = payloadsFromMedia([
        _media('', SharedMediaType.text),
        _media('   \n\t ', SharedMediaType.text),
        _media('', SharedMediaType.url),
        _media('  testo con spazi \n', SharedMediaType.text),
      ]);
      expect(out, [const SharedText('testo con spazi')]);
    });

    test('immagine senza percorso scartata', () {
      expect(payloadsFromMedia([_media('', SharedMediaType.image)]), isEmpty);
    });

    test('lo stesso elemento due volte nella stessa consegna resta uno', () {
      final out = payloadsFromMedia([
        _media('https://x.it', SharedMediaType.url),
        _media('https://x.it', SharedMediaType.text),
        _media('/c/i.png', SharedMediaType.image),
        _media('/c/i.png', SharedMediaType.image),
      ]);
      expect(out, [const SharedText('https://x.it'), const SharedImage('/c/i.png')]);
    });

    test('lista vuota → lista vuota, e il risultato non si modifica', () {
      expect(payloadsFromMedia([]), isEmpty);
      final out = payloadsFromMedia([_media('a', SharedMediaType.text)]);
      expect(() => out.add(const SharedText('b')), throwsUnsupportedError);
    });

    test('copre ogni SharedMediaType del plugin', () {
      // ☠ Se una versione futura del plugin aggiunge un tipo, lo switch in
      //   payloadsFromMedia smette di compilare; questo test ricorda quali si conoscono.
      expect(SharedMediaType.values.map((t) => t.value).toSet(), {
        'image',
        'video',
        'text',
        'file',
        'url',
      });
    });
  });

  group('SharedPayload', () {
    test('uguaglianza per valore e per tipo', () {
      expect(const SharedText('a'), const SharedText('a'));
      expect(const SharedText('a').hashCode, const SharedText('a').hashCode);
      expect(const SharedText('a'), isNot(const SharedText('b')));
      expect(const SharedImage('a'), const SharedImage('a'));
      // Stessa stringa ma tipo diverso: non sono lo stesso elemento.
      expect(const SharedText('/x.png') == const SharedImage('/x.png'), isFalse);
      expect(const SharedText('/x.png').hashCode == const SharedImage('/x.png').hashCode, isFalse);
    });

    test('toString leggibile', () {
      expect(const SharedText('ciao').toString(), 'SharedText(ciao)');
      expect(const SharedImage('/a.png').toString(), 'SharedImage(/a.png)');
    });

    test('lo switch sulla classe sigillata e esaustivo', () {
      String describe(SharedPayload p) => switch (p) {
        SharedText(:final text) => 't:$text',
        SharedImage(:final path) => 'i:$path',
      };
      expect(describe(const SharedText('a')), 't:a');
      expect(describe(const SharedImage('b')), 'i:b');
    });
  });

  group('FakeShareInbox', () {
    late FakeShareInbox inbox;

    setUp(() => inbox = FakeShareInbox(initial: [const SharedText('avvio')]));
    tearDown(() => inbox.close());

    test('initial restituisce cio che ha aperto l app finche non si fa reset', () async {
      expect(await inbox.initial(), [const SharedText('avvio')]);
      expect(await inbox.initial(), [const SharedText('avvio')]);
      expect(inbox.initialCount, 2);

      await inbox.reset();
      expect(inbox.resetCount, 1);
      expect(await inbox.initial(), isEmpty);
    });

    test('setInitial sostituisce la condivisione di avvio', () async {
      inbox.setInitial([const SharedImage('/a.png')]);
      expect(await inbox.initial(), [const SharedImage('/a.png')]);
    });

    test('push consegna su incoming, le liste vuote no', () async {
      final ricevuti = <List<SharedPayload>>[];
      final sub = inbox.incoming.listen(ricevuti.add);

      inbox.push([const SharedText('uno')]);
      inbox.push([]);
      inbox.push([const SharedImage('/b.png'), const SharedText('due')]);
      await pumpEventQueue();

      expect(ricevuti, [
        [const SharedText('uno')],
        [const SharedImage('/b.png'), const SharedText('due')],
      ]);
      await sub.cancel();
    });

    test('incoming e broadcast: due ascoltatori ricevono la stessa consegna', () async {
      final a = <List<SharedPayload>>[];
      final b = <List<SharedPayload>>[];
      final s1 = inbox.incoming.listen(a.add);
      final s2 = inbox.incoming.listen(b.add);

      inbox.push([const SharedText('x')]);
      await pumpEventQueue();

      expect(a, b);
      expect(a, hasLength(1));
      await s1.cancel();
      await s2.cancel();
    });

    test('pushError arriva come errore sullo stream', () async {
      final errori = <Object>[];
      final sub = inbox.incoming.listen((_) {}, onError: errori.add);

      inbox.pushError(StateError('piattaforma'));
      await pumpEventQueue();

      expect(errori.single, isA<StateError>());
      await sub.cancel();
    });
  });

  group('RsiShareInbox sul plugin finto', () {
    test('initial converte, reset svuota, incoming filtra le consegne vuote', () async {
      final stream = StreamController<List<SharedMediaFile>>.broadcast();
      addTearDown(stream.close);
      ReceiveSharingIntent.setMockValues(
        initialMedia: [
          _media('https://avvio.it', SharedMediaType.url),
          _media('/c/v.mp4', SharedMediaType.video),
        ],
        mediaStream: stream.stream,
      );
      final inbox = RsiShareInbox();

      expect(await inbox.initial(), [const SharedText('https://avvio.it')]);
      await inbox.reset();
      expect(await inbox.initial(), isEmpty);

      final ricevuti = <List<SharedPayload>>[];
      final sub = inbox.incoming.listen(ricevuti.add);
      stream.add([_media('/c/solo_video.mp4', SharedMediaType.video)]);
      stream.add([_media('/c/i.png', SharedMediaType.image)]);
      await pumpEventQueue();

      expect(ricevuti, [
        [const SharedImage('/c/i.png')],
      ]);
      await sub.cancel();
    });

    test('il plugin passato con plugin: vince sull istanza statica', () async {
      final inbox = RsiShareInbox(plugin: _PluginFisso());
      expect(await inbox.initial(), [const SharedText('dal plugin iniettato')]);
    });
  });
}

class _PluginFisso extends ReceiveSharingIntent {
  @override
  Future<List<SharedMediaFile>> getInitialMedia() async => [
    _media('dal plugin iniettato', SharedMediaType.text),
  ];

  @override
  Stream<List<SharedMediaFile>> getMediaStream() => const Stream.empty();

  @override
  Future<dynamic> reset() async {}
}
