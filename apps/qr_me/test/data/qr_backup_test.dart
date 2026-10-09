import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:qr_me/data/database.dart';
import 'package:qr_me/data/qr_backup_source.dart';
import 'package:qr_me/data/qr_repository.dart';
import 'package:qr_me/domain/qr_content.dart';
import 'package:qr_me/domain/qr_encoder.dart';
import 'package:qr_me/domain/qr_style.dart';

/// Il backup completo **con un logo foto** fa andata e ritorno: lo ZIP vero di
/// `BackupService`, scritto e riletto da disco fra due "telefoni" (due database in memoria e
/// due cartelle documenti diverse). Stesso schema del test di Film Tracker.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late QrDatabase vecchioDb;
  late QrRepository vecchio;
  late AppPaths vecchiePaths;
  late QrDatabase nuovoDb;
  late QrRepository nuovo;
  late AppPaths nuovePaths;
  final now = DateTime.utc(2026, 10, 9, 12);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('qrme_backup_');
    vecchiePaths = AppPaths.underRoot(Directory('${tmp.path}/vecchio'));
    nuovePaths = AppPaths.underRoot(Directory('${tmp.path}/nuovo'));
    await vecchiePaths.ensureAll();
    await nuovePaths.ensureAll();
    vecchioDb = QrDatabase.memory();
    vecchio = QrRepository(vecchioDb, images: ImageStore(paths: vecchiePaths), clock: () => now);
    nuovoDb = QrDatabase.memory();
    nuovo = QrRepository(nuovoDb, images: ImageStore(paths: nuovePaths), clock: () => now);
  });

  tearDown(() async {
    await vecchioDb.close();
    await nuovoDb.close();
    await tmp.delete(recursive: true);
  });

  Future<String> logo(AppPaths paths, String nome) async {
    final name = 'images/${QrLogoFiles.bucket}/$nome.jpg';
    for (final rel in QrLogoFiles.filesOf(name)) {
      final f = paths.resolve(rel);
      await f.parent.create(recursive: true);
      await f.writeAsString('byte di $rel');
    }
    return name;
  }

  Future<int> mostra(QrRepository repo, QrContent c, {QrStyle style = QrStyle.plain}) =>
      repo.recordShown(content: c, payload: QrEncoder.encode(c), source: QrSource.form, style: style);

  Future<File> backup() async {
    final service = BackupService(paths: vecchiePaths, appVersion: '1.0.0');
    final r = await service.createBackup(QrBackupSource(vecchioDb, paths: vecchiePaths), includeImages: true);
    return r.valueOrNull!;
  }

  test('andata e ritorno con un logo foto', () async {
    final foto = await logo(vecchiePaths, 'casa');
    final stile = QrStyle(foreground: 0xFF1B5E20, logo: PhotoLogo(imageName: foto, round: true));
    const wifi = WifiContent(ssid: 'Casa;1', password: r'p,w:"\');
    final fav = await mostra(vecchio, wifi, style: stile);
    await vecchio.saveAsFavorite(fav, title: 'Wi-Fi di casa');
    await mostra(vecchio, const TextContent('una nota'));
    await mostra(vecchio, const ContactContent(name: 'Mario Rossi', phone: '333'));

    final source = QrBackupSource(vecchioDb);
    expect(await source.counts(), {'favorites': 1, 'history': 2});
    expect(await source.imagePaths(), QrLogoFiles.filesOf(foto));

    final file = await backup();
    final restore = await BackupService(paths: nuovePaths, appVersion: '1.0.0')
        .restore(file, QrBackupSource(nuovoDb, paths: nuovePaths), mode: ImportMode.replaceAll);
    expect(restore.isOk, isTrue, reason: '${restore.errorOrNull}');

    final preferiti = await nuovo.watchFavorites().first;
    expect(preferiti.single.title, 'Wi-Fi di casa');
    expect(preferiti.single.content, wifi);
    expect(preferiti.single.style, stile);
    expect(preferiti.single.payload, QrEncoder.encode(wifi));
    final storia = await nuovo.watchHistory().first;
    expect(storia.map((r) => r.content).toSet(), {
      const TextContent('una nota'),
      const ContactContent(name: 'Mario Rossi', phone: '333'),
    });
    // Il file del logo e' arrivato sul telefono nuovo, allo stesso percorso relativo.
    for (final rel in QrLogoFiles.filesOf(foto)) {
      expect(await nuovePaths.resolve(rel).readAsString(), 'byte di $rel');
    }
  });

  test('ripristinare due volte in unione non crea doppioni', () async {
    await mostra(vecchio, const TextContent('una'));
    final file = await backup();
    final service = BackupService(paths: nuovePaths, appVersion: '1.0.0');
    for (var i = 0; i < 2; i++) {
      final r = await service.restore(file, QrBackupSource(nuovoDb, paths: nuovePaths), mode: ImportMode.mergeKeepExisting);
      expect(r.isOk, isTrue);
    }
    expect(await nuovo.watchHistory().first, hasLength(1));
  });

  test('"sostituisci tutto" cancella i loghi che il backup non riporta', () async {
    final orfano = await logo(nuovePaths, 'del_telefono_nuovo');
    await mostra(nuovo, const TextContent('locale'), style: QrStyle(logo: PhotoLogo(imageName: orfano)));
    await mostra(vecchio, const TextContent('dal backup'));
    final file = await backup();
    final r = await BackupService(paths: nuovePaths, appVersion: '1.0.0')
        .restore(file, QrBackupSource(nuovoDb, paths: nuovePaths), mode: ImportMode.replaceAll);
    expect(r.isOk, isTrue);
    expect((await nuovo.watchHistory().first).single.payload, 'dal backup');
    expect(nuovePaths.resolve(orfano).existsSync(), isFalse);
  });

  test('un file malformato e\' una FormatException, e non tocca il database', () async {
    await mostra(nuovo, const TextContent('resto qui'));
    final source = QrBackupSource(nuovoDb);
    final cattivi = <Map<String, Object?>>[
      {'codes': [{'kind': 'ologramma', 'payload': 'x', 'title': 'x', 'source': 'typed'}]},
      {'codes': [{'kind': 'text', 'payload': 'x', 'title': 'x', 'source': 'boh'}]},
      {'codes': [{'kind': 'text', 'payload': 3, 'title': 'x', 'source': 'typed'}]},
      {'codes': [{'kind': 'text', 'payload': 'x', 'title': '', 'source': 'typed'}]},
      {
        'codes': [
          {'kind': 'text', 'payload': 'x', 'title': 'x', 'source': 'typed', 'style': {'logo': {'type': 'photo', 'image': '../../segreto'}}},
        ],
      },
    ];
    for (final p in cattivi) {
      await expectLater(source.importPayload(p, mode: ImportMode.replaceAll), throwsFormatException, reason: '$p');
    }
    expect((await nuovo.watchHistory().first).single.payload, 'resto qui');
  });
}
