import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';

/// Una sorgente di backup finta, con dati in memoria.
class _FakeSource implements BackupSource {
  _FakeSource({this.id = 'testapp', this.version = 1, Map<String, Object?>? data})
    : _data = data ?? <String, Object?>{'voci': <String>['a', 'b']};

  final String id;
  final int version;
  Map<String, Object?> _data;
  ImportMode? lastMode;

  @override
  String get schemaId => id;

  @override
  int get schemaVersion => version;

  @override
  Future<Map<String, Object?>> exportPayload() async => _data;

  @override
  Future<void> importPayload(Map<String, Object?> payload, {required ImportMode mode}) async {
    lastMode = mode;
    _data = payload;
  }

  @override
  Future<List<String>> imagePaths() async => const <String>[];

  @override
  Future<Map<String, int>> counts() async => <String, int>{'voci': 2};
}

void main() {
  group('Money', () {
    test('la somma non perde centesimi, cosa che con i double succede', () {
      // Con i double questa somma darebbe 230,99999999999997 e l'utente smetterebbe di
      // fidarsi di tutti i numeri dell'app.
      final importi = List.generate(3, (_) => Money.fromDouble(77.0));
      expect(Money.sum(importi).cents, 23100);
      expect(Money.sum(importi).asDouble, 231.0);
    });

    test('centesimi da decimale, con arrotondamento', () {
      expect(Money.fromDouble(6.5).cents, 650);
      expect(Money.fromDouble(6.505).cents, 651);
      expect(Money.fromDouble(6.504).cents, 650);
    });

    test('tryParse accetta quello che l utente digita davvero', () {
      expect(Money.tryParse('6,50')?.cents, 650);
      expect(Money.tryParse('6.50')?.cents, 650);
      expect(Money.tryParse('6,50 €')?.cents, 650);
      expect(Money.tryParse('  12 ')?.cents, 1200);
      expect(Money.tryParse('1.000')?.cents, 100000, reason: 'mille, non uno virgola zero');
      expect(Money.tryParse('1.234,56')?.cents, 123456);
      expect(Money.tryParse('1,234.56')?.cents, 123456);
      expect(Money.tryParse('-3,20')?.cents, -320);
      expect(Money.tryParse('niente'), isNull);
      expect(Money.tryParse(''), isNull);
    });

    test('operatori', () {
      const dieci = Money.cents(1000);
      const tre = Money.cents(300);
      expect((dieci + tre).cents, 1300);
      expect((dieci - tre).cents, 700);
      expect((dieci * 3).cents, 3000);
      expect((dieci / 4).cents, 250);
    });

    test('la media su una collezione vuota e null, non zero', () {
      // "nessun dato" e "media zero" sono cose diverse: mostrarle uguali nasconde
      // all'utente che non ci sono ancora dati.
      expect(Money.average(const <Money>[]), isNull);
      expect(Money.average(const [Money.cents(100), Money.cents(300)])?.cents, 200);
    });

    test('ordinamento e uguaglianza', () {
      final lista = [const Money.cents(300), const Money.cents(100)]..sort();
      expect(lista.first.cents, 100);
      expect(const Money.cents(100), const Money.cents(100));
      expect(const Money.cents(100), isNot(const Money.cents(100, currency: 'USD')));
    });
  });

  group('CsvWriter', () {
    test('BOM e separatore punto e virgola, per Excel italiano', () {
      final csv = CsvWriter()
        ..addHeader(['nome', 'costo'])
        ..addRow(['Pellet', 6.5]);
      final out = csv.build();
      expect(out.codeUnitAt(0), 0xFEFF, reason: 'senza BOM Excel rovina gli accenti');
      expect(out, contains('nome;costo'));
      expect(out, contains('Pellet;6,5'), reason: 'decimali con la virgola');
    });

    test('i valori che contengono il separatore vengono quotati', () {
      final csv = CsvWriter()..addRow(['con;dentro', 'normale']);
      expect(csv.build(), contains('"con;dentro";normale'));
    });

    test('le virgolette si raddoppiano', () {
      final csv = CsvWriter()..addRow(['dice "ciao"']);
      expect(csv.build(), contains('"dice ""ciao"""'));
    });

    test('gli a capo vengono quotati', () {
      final csv = CsvWriter()..addRow(['prima\nseconda']);
      expect(csv.build(), contains('"prima\nseconda"'));
    });

    test('i null diventano celle vuote', () {
      final csv = CsvWriter()..addRow([null, 'x']);
      expect(csv.build(), contains(';x'));
    });

    test('senza BOM su richiesta', () {
      final csv = CsvWriter(withBom: false)..addRow(['a']);
      expect(csv.build().codeUnitAt(0), isNot(0xFEFF));
    });
  });

  group('backup', () {
    late Directory temp;
    late BackupService service;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('micro_backup_');
      service = BackupService(
        paths: AppPaths.underRoot(temp),
        appVersion: '1.0.0',
      );
    });

    tearDown(() {
      try {
        if (temp.existsSync()) temp.deleteSync(recursive: true);
      } on FileSystemException {
        // la ripulisce il sistema
      }
    });

    test('round-trip completo', () async {
      final source = _FakeSource();
      final created = await service.createBackup(source, label: 'prima di reinstallare');
      expect(created.isOk, isTrue);

      final file = created.valueOrNull!;
      final manifest = await service.inspect(file);
      expect(manifest.valueOrNull?.schemaId, 'testapp');
      expect(manifest.valueOrNull?.label, 'prima di reinstallare');
      expect(manifest.valueOrNull?.totalItems, 2);

      final restored = await service.restore(
        file,
        source,
        mode: ImportMode.replaceAll,
      );
      expect(restored.isOk, isTrue);
      expect(source.lastMode, ImportMode.replaceAll);
    });

    test('il backup di un altra app viene rifiutato', () async {
      final created = await service.createBackup(_FakeSource());
      final altra = _FakeSource(id: 'un_altra_app');
      final restored = await service.restore(
        created.valueOrNull!,
        altra,
        mode: ImportMode.replaceAll,
      );
      expect(restored.isErr, isTrue);
      expect(restored.errorOrNull?.code, MicroErrorCodes.unsupportedVersion);
      expect(altra.lastMode, isNull, reason: 'non deve aver toccato i dati');
    });

    test('un backup di schema piu recente viene rifiutato', () async {
      final futuro = _FakeSource(version: 99);
      final created = await service.createBackup(futuro);
      final attuale = _FakeSource();
      final restored = await service.restore(
        created.valueOrNull!,
        attuale,
        mode: ImportMode.replaceAll,
      );
      expect(restored.isErr, isTrue);
      expect(attuale.lastMode, isNull);
    });

    test('un file che non e un backup viene riconosciuto', () {
      final decoded = JsonBackupCodec.decode('{"qualcosa": 1}');
      expect(decoded.isErr, isTrue);
      expect(decoded.errorOrNull?.code, MicroErrorCodes.corruptedFile);
    });

    test('un file illeggibile non fa lanciare', () {
      expect(JsonBackupCodec.decode('non json').isErr, isTrue);
    });

    test('un formato futuro viene rifiutato con il codice giusto', () {
      final futuro = jsonEncode(<String, Object?>{
        'magic': JsonBackupCodec.magic,
        'formatVersion': JsonBackupCodec.formatVersion + 1,
        'manifest': <String, Object?>{'schemaId': 'x', 'schemaVersion': 1},
        'payload': <String, Object?>{},
      });
      final decoded = JsonBackupCodec.decode(futuro);
      expect(decoded.errorOrNull?.code, MicroErrorCodes.unsupportedVersion);
    });

    test('zip slip: una voce che esce dalla cartella non viene scritta', () async {
      // Un backup vero, poi rimpacchettato a mano con una voce maligna accanto a una buona.
      final json = await service.createBackup(_FakeSource());
      final dati = await json.valueOrNull!.readAsString();
      final archivio = Archive()
        ..addFile(ArchiveFile.string('data.json', dati))
        ..addFile(ArchiveFile.bytes('images/images/rolls/buona.jpg', [1, 2, 3]))
        ..addFile(ArchiveFile.bytes('images/../../fuori.txt', [9, 9, 9]));
      final zip = File('${temp.path}/maligno.zip')..writeAsBytesSync(ZipEncoder().encode(archivio));

      final restored = await service.restore(zip, _FakeSource(), mode: ImportMode.replaceAll);

      expect(restored.isOk, isTrue);
      final paths = AppPaths.underRoot(temp);
      expect(paths.resolve('images/rolls/buona.jpg').existsSync(), isTrue);
      expect(File('${temp.parent.path}/fuori.txt').existsSync(), isFalse);
      expect(paths.resolve('../../fuori.txt').existsSync(), isFalse);
    });

    test('ripristinare un file inesistente non lancia', () async {
      final restored = await service.restore(
        File('${temp.path}/non-esiste.json'),
        _FakeSource(),
        mode: ImportMode.replaceAll,
      );
      expect(restored.isErr, isTrue);
      expect(restored.errorOrNull?.code, MicroErrorCodes.notFound);
    });
  });

  group('AtomicFile', () {
    late Directory temp;

    setUp(() => temp = Directory.systemTemp.createTempSync('micro_atomic_'));
    tearDown(() {
      try {
        if (temp.existsSync()) temp.deleteSync(recursive: true);
      } on FileSystemException {
        // ignorata
      }
    });

    test('scritture concorrenti sullo stesso file non si sabotano', () async {
      // E' il difetto trovato dai test dell'entitlement: due percorsi asincroni che
      // scrivono lo stesso file usavano lo stesso temporaneo e uno dei due falliva.
      final target = File('${temp.path}/stato.json');
      await Future.wait([
        for (var i = 0; i < 20; i++) AtomicFile.writeString(target, 'valore $i'),
      ]);
      final contenuto = await AtomicFile.readStringOrNull(target);
      expect(contenuto, isNotNull);
      expect(contenuto, startsWith('valore '));
      expect(
        temp.listSync().whereType<File>().where((f) => f.path.endsWith('.tmp')),
        isEmpty,
        reason: 'nessun temporaneo deve restare in giro',
      );
    });

    test('un file inesistente si legge come null invece di lanciare', () async {
      expect(await AtomicFile.readStringOrNull(File('${temp.path}/mai-scritto')), isNull);
    });

    test('la scrittura crea le cartelle mancanti', () async {
      final nested = File('${temp.path}/a/b/c/file.txt');
      await AtomicFile.writeString(nested, 'ciao');
      expect(nested.existsSync(), isTrue);
    });
  });

  group('AppPaths', () {
    test('i percorsi relativi sopravvivono a un cambio di radice', () {
      // E' il motivo per cui nel database si salva il relativo: la sandbox di Android
      // cambia percorso fra un aggiornamento e l'altro.
      final prima = AppPaths.underRoot(Directory('/vecchia/sandbox'));
      final dopo = AppPaths.underRoot(Directory('/nuova/sandbox'));
      const relativo = 'images/rolls/foto.jpg';
      expect(prima.resolve(relativo).path, isNot(dopo.resolve(relativo).path));
      expect(prima.resolve(relativo).path, contains('vecchia'));
      expect(dopo.resolve(relativo).path, contains('nuova'));
    });

    test('relativize e l inverso di resolve', () {
      final paths = AppPaths.underRoot(Directory.systemTemp.createTempSync('micro_paths_'));
      const relativo = 'images/x/y.jpg';
      expect(paths.relativize(paths.resolve(relativo)), relativo);
    });
  });

  group('NotificationIds', () {
    test('lo stesso evento produce sempre lo stesso id', () {
      // E' la proprieta' che rende idempotente la ripianificazione: con un contatore, la
      // stessa raccolta prenderebbe un id nuovo a ogni resume e i duplicati si
      // accumulerebbero fino a far arrivare la notifica cinque volte.
      final a = NotificationIds.forOccurrence(3, CivilDate(2026, 9, 10), 0);
      final b = NotificationIds.forOccurrence(3, CivilDate(2026, 9, 10), 0);
      expect(a, b);
    });

    test('eventi diversi producono id diversi', () {
      final base = NotificationIds.forOccurrence(3, CivilDate(2026, 9, 10), 0);
      expect(NotificationIds.forOccurrence(4, CivilDate(2026, 9, 10), 0), isNot(base));
      expect(NotificationIds.forOccurrence(3, CivilDate(2026, 9, 11), 0), isNot(base));
      expect(NotificationIds.forOccurrence(3, CivilDate(2026, 9, 10), 1), isNot(base));
    });

    test('gli id stanno sopra la soglia riservata e dentro i 32 bit', () {
      for (var giorno = 1; giorno <= 28; giorno++) {
        for (var slot = 0; slot < 3; slot++) {
          final id = NotificationIds.forOccurrence(giorno, CivilDate(2026, 2, giorno), slot);
          expect(id, greaterThan(NotificationIds.reservedMax));
          expect(id, lessThan(0x7FFFFFFF));
        }
      }
    });
  });

  group('InstallId', () {
    test('l identificatore per Play e derivato e lungo 64 caratteri', () {
      // Play limita il campo a 64 caratteri e chiede che non sia ricostruibile.
      final id = InstallId.fixed('11111111-2222-3333-4444-555555555555');
      expect(id.obfuscatedAccountId.length, 64);
      expect(id.obfuscatedAccountId, isNot(contains(id.value)));
    });

    test('lo stesso valore produce sempre lo stesso identificatore', () {
      const raw = '11111111-2222-3333-4444-555555555555';
      expect(
        InstallId.fixed(raw).obfuscatedAccountId,
        InstallId.fixed(raw).obfuscatedAccountId,
      );
    });

    test('la forma breve e leggibile ad alta voce', () {
      expect(InstallId.fixed('abcdef12-0000-0000-0000-000000000000').short, 'ABCDEF12');
    });
  });
}
