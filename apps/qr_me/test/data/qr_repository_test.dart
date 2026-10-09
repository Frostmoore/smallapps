import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:qr_me/data/database.dart';
import 'package:qr_me/data/qr_repository.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/domain/qr_encoder.dart';
import 'package:qr_me/domain/qr_style.dart';

/// F17.1.4: le regole che vivono nel repository e non nello schema.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late QrDatabase db;
  late QrRepository repo;
  late Directory tmp;
  late AppPaths paths;
  var clock = DateTime.utc(2026, 10, 9, 12);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('qrme_repo_');
    paths = AppPaths.underRoot(tmp);
    db = QrDatabase.memory();
    clock = DateTime.utc(2026, 10, 9, 12);
    repo = QrRepository(db, images: ImageStore(paths: paths), clock: () => clock);
  });

  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  /// Mostra un contenuto, un minuto dopo il precedente.
  Future<int> mostra(QrContent c, {QrStyle style = QrStyle.plain, String source = QrSource.typed}) {
    clock = clock.add(const Duration(minutes: 1));
    return repo.recordShown(content: c, payload: QrEncoder.encode(c), source: source, style: style);
  }

  /// Un logo foto "salvato da ImageStore": i due file su disco.
  Future<String> logo(String nome) async {
    final name = 'images/${QrLogoFiles.bucket}/$nome.jpg';
    for (final rel in QrLogoFiles.filesOf(name)) {
      final f = paths.resolve(rel);
      await f.parent.create(recursive: true);
      await f.writeAsString(rel);
    }
    return name;
  }

  bool esiste(String name) => QrLogoFiles.filesOf(name).every((r) => paths.resolve(r).existsSync());

  test('recordShown salva tipo, payload, titolo, campi e provenienza', () async {
    const wifi = WifiContent(ssid: 'Casa', password: 'p;w');
    final id = await mostra(wifi, source: QrSource.scanned);
    final row = (await repo.byId(id))!;
    expect(row.kind, 'wifi');
    expect(row.payload, r'WIFI:T:WPA;S:Casa;P:p\;w;;');
    expect(row.title, 'Casa');
    expect(row.source, QrSource.scanned);
    expect(row.isFavorite, isFalse);
    expect(row.styleJson, isNull, reason: 'plain = null');
    expect(row.content, wifi);
    expect(jsonDecode(row.fieldsJson!), wifi.toFields());

    // Testo e link: niente campi, si riaprono dal payload.
    final t = (await repo.byId(await mostra(const TextContent('https://x.it con spazio'))))!;
    expect(t.fieldsJson, isNull);
    expect(t.content, const TextContent('https://x.it con spazio'));
    final u = (await repo.byId(await mostra(UrlContent(Uri.parse('https://esempio.it')))))!;
    expect(u.fieldsJson, isNull);
    expect(u.content, UrlContent(Uri.parse('https://esempio.it')));
  });

  test('un testo che sembra un link resta testo se cosi\' e\' stato salvato', () async {
    final id = await repo.recordShown(content: const TextContent('tel:333'), payload: 'tel:333', source: QrSource.shared);
    expect((await repo.byId(id))!.content, const TextContent('tel:333'));
  });

  test('provenienza sconosciuta: ArgumentError', () async {
    expect(
      () => repo.recordShown(content: const TextContent('x'), payload: 'x', source: 'boh'),
      throwsArgumentError,
    );
  });

  test('niente doppioni in cronologia: stesso payload e stile tocca la riga', () async {
    final a = await mostra(const TextContent('ciao'));
    await mostra(const TextContent('altro'));
    final b = await mostra(const TextContent('ciao'));
    expect(b, a);
    final storia = await repo.watchHistory().first;
    expect(storia.map((r) => r.payload), ['ciao', 'altro'], reason: 'il ri-mostrato torna in cima');

    // Stesso payload con un altro stile: e' un altro QR.
    final c = await mostra(const TextContent('ciao'), style: const QrStyle(foreground: 0xFF1B5E20));
    expect(c, isNot(a));
    expect(await repo.watchHistory().first, hasLength(3));
  });

  test('un preferito con lo stesso contenuto non si tocca: la visualizzazione va in cronologia', () async {
    final fav = await mostra(const TextContent('wifi di casa'));
    await repo.saveAsFavorite(fav, title: 'Casa');
    final nuovo = await mostra(const TextContent('wifi di casa'));
    expect(nuovo, isNot(fav));
    expect((await repo.byId(fav))!.title, 'Casa');
    expect(await repo.watchHistory().first, hasLength(1));
  });

  test('potatura a 5: restano gli ultimi 5 non preferiti, i preferiti non si toccano', () async {
    final ids = [for (var i = 0; i < 8; i++) await mostra(TextContent('n$i'))];
    await repo.saveAsFavorite(ids[0], title: 'Il piu\' vecchio, ma preferito');
    final tolti = await repo.pruneHistory(keep: 5);
    expect(tolti, 2);
    final storia = await repo.watchHistory().first;
    expect(storia.map((r) => r.payload), ['n7', 'n6', 'n5', 'n4', 'n3']);
    expect(await repo.byId(ids[0]), isNotNull, reason: 'preferito');
    expect(await repo.byId(ids[1]), isNull, reason: 'cancellato davvero, non nascosto');
    expect(await repo.pruneHistory(keep: null), 0, reason: 'Pro: nessun limite');
    expect(await repo.pruneHistory(keep: 5), 0);
  });

  test('preferiti: salva, rinomina, ordina per titolo, conta, togli', () async {
    final a = await mostra(const TextContent('a'));
    final b = await mostra(const TextContent('b'));
    await repo.saveAsFavorite(a, title: '  zeta ');
    await repo.saveAsFavorite(b, title: 'Alfa');
    expect(await repo.countFavorites(), 2);
    expect(await repo.watchFavoriteCount().first, 2);
    expect((await repo.watchFavorites().first).map((r) => r.title), ['Alfa', 'zeta']);
    await repo.rename(b, 'beta');
    expect((await repo.watchFavorites().first).map((r) => r.title), ['beta', 'zeta']);
    expect(await repo.watchHistory().first, isEmpty);

    await repo.unfavorite(a);
    expect(await repo.countFavorites(), 1);
    expect((await repo.watchHistory().first).single.id, a);
  });

  test('togliere un preferito non crea un doppione in cronologia', () async {
    final fav = await mostra(const TextContent('x'));
    await repo.saveAsFavorite(fav, title: 'X');
    await mostra(const TextContent('x'));
    await repo.unfavorite(fav);
    final storia = await repo.watchHistory().first;
    expect(storia.single.id, fav);
  });

  test('touch riporta in cima', () async {
    final a = await mostra(const TextContent('a'));
    await mostra(const TextContent('b'));
    clock = clock.add(const Duration(minutes: 5));
    await repo.touch(a);
    expect((await repo.watchHistory().first).first.id, a);
  });

  test('clearHistory toglie solo i non preferiti', () async {
    final a = await mostra(const TextContent('a'));
    await mostra(const TextContent('b'));
    await repo.saveAsFavorite(a, title: 'A');
    await repo.clearHistory();
    expect(await repo.watchHistory().first, isEmpty);
    expect(await repo.countFavorites(), 1);
  });

  test('cancellazione del logo foto orfano, e solo se nessun altro lo usa', () async {
    final condiviso = await logo('condiviso');
    final stile = QrStyle(logo: PhotoLogo(imageName: condiviso));
    final a = await mostra(const TextContent('a'), style: stile);
    final b = await mostra(const TextContent('b'), style: stile);
    expect(await repo.usedLogoImages(), {condiviso});

    await repo.delete(a);
    expect(esiste(condiviso), isTrue, reason: 'lo usa ancora b');
    await repo.delete(b);
    expect(esiste(condiviso), isFalse, reason: 'orfano: immagine e miniatura cancellate');
  });

  test('cambiare stile cancella il vecchio logo; potatura e svuotamento pure', () async {
    final vecchio = await logo('vecchio');
    final id = await mostra(const TextContent('a'), style: QrStyle(logo: PhotoLogo(imageName: vecchio)));
    await repo.saveAsFavorite(id, title: 'A');
    await repo.updateStyle(id, const QrStyle(logo: IconLogo('heart')));
    expect(esiste(vecchio), isFalse);
    expect((await repo.byId(id))!.style, const QrStyle(logo: IconLogo('heart')));

    final potato = await logo('potato');
    await mostra(const TextContent('p'), style: QrStyle(logo: PhotoLogo(imageName: potato)));
    await mostra(const TextContent('q'));
    await repo.pruneHistory(keep: 1);
    expect(esiste(potato), isFalse);

    final svuotato = await logo('svuotato');
    await mostra(const TextContent('s'), style: QrStyle(logo: PhotoLogo(imageName: svuotato)));
    await repo.clearHistory();
    expect(esiste(svuotato), isFalse);
  });

  test('il repository non scrive da solo: senza recordShown il database resta vuoto', () async {
    // "Cronologia spenta = nessuna scrittura" e' una regola del chiamante (F17.0 punto 7): qui
    // si verifica che letture, conteggi e potature su un database vuoto non creino righe.
    await repo.watchHistory().first;
    await repo.watchFavorites().first;
    await repo.countFavorites();
    await repo.pruneHistory(keep: 5);
    await repo.clearHistory();
    await repo.touch(42);
    await repo.delete(42);
    expect(await db.select(db.qrCodes).get(), isEmpty);
  });

  test('titolo: rifilato, tagliato a 80, mai vuoto', () async {
    final id = await mostra(const TextContent('x'));
    await repo.rename(id, '   ');
    expect((await repo.byId(id))!.title, '…');
    await repo.rename(id, 'y' * 100);
    expect((await repo.byId(id))!.title, hasLength(80));
  });

  test("updateContent: cambia contenuto e campi, il nome dato dall'utente resta", () async {
    const prima = WifiContent(ssid: 'Casa', password: 'vecchia');
    final id = await mostra(prima);
    await repo.saveAsFavorite(id, title: 'Wi-Fi di casa');
    const dopo = WifiContent(ssid: 'Casa', password: 'nuova;1');
    await repo.updateContent(id, content: dopo, payload: QrEncoder.encode(dopo));
    final row = (await repo.byId(id))!;
    expect(row.title, 'Wi-Fi di casa');
    expect(row.payload, QrEncoder.encode(dopo));
    expect(row.content, dopo);
    expect(row.isFavorite, isTrue);
  });
}
