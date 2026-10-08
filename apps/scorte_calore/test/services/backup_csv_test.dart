import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:scorte_calore/data/database.dart';
import 'package:scorte_calore/data/scorte_repository.dart';
import 'package:scorte_calore/domain/fuel_source.dart';
import 'package:scorte_calore/domain/fuel_units.dart';
import 'package:scorte_calore/l10n/generated/app_localizations.dart';
import 'package:scorte_calore/services/csv_export.dart';
import 'package:scorte_calore/services/scorte_backup_source.dart';

/// F5.11: il backup riporta fonti, misurazioni (con il valore digitato) e acquisti, lascia
/// fuori i promemoria del calendario, e il CSV e' leggibile da Excel in italiano.
void main() {
  // Due database in memoria distinti (telefono vecchio e nuovo): l'avviso di drift sulle
  // istanze multiple riguarda chi condivide lo stesso file, non questo caso.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase origine;
  late ScorteRepository repo;
  final now = DateTime.utc(2026, 10, 7, 12);
  CivilDate d(String iso) => CivilDate.parse(iso);

  setUp(() {
    origine = AppDatabase.memory();
    repo = ScorteRepository(origine, clock: () => now);
  });
  tearDown(() => origine.close());

  /// Un telefono "pieno": una stufa a pellet (disattivata, con una nota), un bombolone GPL
  /// misurato in percentuale, acquisti con e senza costo, un promemoria del calendario.
  Future<({int stufa, int gpl})> riempi() async {
    final stufa = await repo.addSource(name: 'Stufa soggiorno', fuelType: FuelType.pellet, costPerUnitCents: 650);
    final gpl = await repo.addSource(name: 'Bombolone', fuelType: FuelType.lpg, tankCapacity: 1000);
    await repo.upsertMeasurement(stufa, Measurement.absolute(date: d('2026-10-01'), quantity: 40), note: 'cantina; garage');
    await repo.upsertMeasurement(stufa, Measurement.absolute(date: d('2026-10-05'), quantity: 32.5));
    await repo.upsertMeasurement(
      gpl,
      Measurement(date: d('2026-10-02'), quantity: 0, enteredAs: EnteredAs.percentage, rawInput: 43),
    );
    await repo.addPurchase(sourceId: stufa, date: d('2026-10-03'), quantity: 70, totalCostCents: 45500, supplier: 'Agraria Rossi');
    await repo.addPurchase(sourceId: gpl, date: d('2026-09-20'), quantity: 500);
    await repo.setSourceActive(stufa, false);
    await repo.upsertReminder(sourceId: gpl, calendarId: 'cal-1', externalEventId: 'evt-9', calculatedDate: d('2026-11-01'));
    return (stufa: stufa, gpl: gpl);
  }

  /// Il payload passa da JSON come nel file vero: interi e double tornano `num`.
  Future<Map<String, Object?>> esporta() async =>
      (jsonDecode(jsonEncode(await ScorteBackupSource(origine).exportPayload())) as Map).cast<String, Object?>();

  group('backup', () {
    test('sostituisci tutto riporta fonti, misure in percentuale con il rawInput e acquisti', () async {
      await riempi();
      final payload = await esporta();
      expect(jsonEncode(payload), isNot(contains('evt-9')), reason: 'l\'id dell\'evento vale solo su quel telefono');

      final destinazione = AppDatabase.memory();
      addTearDown(destinazione.close);
      final altro = ScorteRepository(destinazione, clock: () => now);
      await altro.addSource(name: 'Camino', fuelType: FuelType.wood);
      final source = ScorteBackupSource(destinazione, clock: () => now);
      await source.importPayload(payload, mode: ImportMode.replaceAll);

      final fonti = await altro.allSources();
      expect(fonti.map((s) => s.name), ['Stufa soggiorno', 'Bombolone'], reason: 'il camino sparisce, l\'ordine resta');
      final stufa = fonti.first;
      expect(stufa.active, isFalse);
      expect(stufa.costPerUnitCents, 650);
      final gpl = fonti.last;
      expect(gpl.tankCapacity, 1000);
      expect(gpl.usableFraction, 0.8);

      final misureGpl = await altro.allMeasurements(gpl.id);
      expect(misureGpl.single.enteredAs, EnteredAs.percentage.key);
      expect(misureGpl.single.rawInput, 43);
      expect(misureGpl.single.quantity, closeTo(344, 1e-9), reason: '43% di 1000 L utili all\'80%');

      final misureStufa = await altro.allMeasurements(stufa.id);
      expect(misureStufa.map((m) => m.quantity), [40, 32.5]);
      expect(misureStufa.first.note, 'cantina; garage');

      final acquisti = await altro.allPurchases();
      expect(acquisti.map((p) => (p.date, p.totalCostCents, p.supplier)), [
        ('2026-10-03', 45500, 'Agraria Rossi'),
        ('2026-09-20', null, null),
      ]);

      expect(await destinazione.select(destinazione.calendarReminders).get(), isEmpty);
      expect(await source.counts(), {'sources': 2, 'measurements': 3, 'purchases': 2});
      expect(await source.imagePaths(), isEmpty);
    });

    test('la percentuale si ricalcola dal rawInput anche se il file porta un\'altra quantita\'', () async {
      await riempi();
      final payload = await esporta();
      final gpl = (payload['sources']! as List).cast<Map<String, Object?>>().singleWhere((s) => s['name'] == 'Bombolone');
      ((gpl['measurements']! as List).single as Map)['quantity'] = 999;

      final destinazione = AppDatabase.memory();
      addTearDown(destinazione.close);
      await ScorteBackupSource(destinazione).importPayload(payload, mode: ImportMode.replaceAll);
      final misura = await destinazione.select(destinazione.stockMeasurements).get();
      expect(misura.singleWhere((m) => m.enteredAs == EnteredAs.percentage.key).quantity, closeTo(344, 1e-9));
    });

    test('aggiungi salta le fonti con lo stesso nome e mette le nuove in fondo', () async {
      await riempi();
      final payload = await esporta();

      final destinazione = AppDatabase.memory();
      addTearDown(destinazione.close);
      final altro = ScorteRepository(destinazione, clock: () => now);
      final mia = await altro.addSource(name: 'Bombolone', fuelType: FuelType.lpg, tankCapacity: 500);
      await altro.upsertMeasurement(mia, Measurement.absolute(date: d('2026-10-06'), quantity: 100));

      await ScorteBackupSource(destinazione).importPayload(payload, mode: ImportMode.mergeKeepExisting);

      final fonti = await altro.allSources();
      expect(fonti.map((s) => s.name), ['Bombolone', 'Stufa soggiorno']);
      expect(fonti.first.tankCapacity, 500, reason: 'quella del telefono resta');
      expect((await altro.allMeasurements(mia)).map((m) => m.quantity), [100], reason: 'niente misure del backup sulla fonte omonima');
      expect(fonti.last.sortOrder, greaterThan(fonti.first.sortOrder));
      expect(await altro.allMeasurements(fonti.last.id), hasLength(2));
      expect((await altro.allPurchases()).single.supplier, 'Agraria Rossi');
    });

    test('un file con un combustibile sconosciuto fallisce come Exception e non scrive niente', () async {
      await riempi();
      final payload = await esporta();
      (payload['sources']! as List).cast<Map<String, Object?>>().last['fuelType'] = 'idrogeno';

      final destinazione = AppDatabase.memory();
      addTearDown(destinazione.close);
      await ScorteRepository(destinazione, clock: () => now).addSource(name: 'Camino', fuelType: FuelType.wood);
      await expectLater(
        ScorteBackupSource(destinazione).importPayload(payload, mode: ImportMode.replaceAll),
        throwsA(isA<FormatException>()),
      );
      final fonti = await destinazione.select(destinazione.fuelSources).get();
      expect(fonti.map((s) => s.name), ['Camino'], reason: 'la transazione annulla anche la cancellazione');
    });

    test('un campo del tipo sbagliato diventa FormatException, non TypeError', () async {
      final destinazione = AppDatabase.memory();
      addTearDown(destinazione.close);
      await expectLater(
        ScorteBackupSource(destinazione).importPayload(
          {
            'sources': [
              {'name': 42, 'fuelType': 'pellet', 'unit': 'bags'},
            ],
          },
          mode: ImportMode.replaceAll,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('CSV', () {
    test('BOM, punto e virgola, una colonna Tipo, lettura % solo per le misure in percentuale', () async {
      await riempi();
      final l = lookupL(const Locale('it'));
      final sources = await repo.allSources();
      final csv = buildScorteCsv(
        l: l,
        sources: sources,
        measurements: [for (final s in sources) ...await repo.allMeasurements(s.id)],
        purchases: await repo.allPurchases(),
      ).build();

      expect(csv.startsWith('﻿'), isTrue, reason: 'senza BOM Excel rovina gli accenti');
      final righe = const LineSplitter().convert(csv.substring(1));
      expect(righe.first, 'Tipo;Fonte;Data;Quantità;Unità;Lettura %;Costo (€);Fornitore;Nota');
      expect(righe.skip(1), [
        // Stufa: in ordine di data, misure e acquisti mescolati. Il punto e virgola nella nota
        // non deve spezzare la colonna.
        'Misurazione;Stufa soggiorno;2026-10-01;40;sacchi;;;;"cantina; garage"',
        'Acquisto;Stufa soggiorno;2026-10-03;70;sacchi;;455,00;Agraria Rossi;',
        'Misurazione;Stufa soggiorno;2026-10-05;32,5;sacchi;;;;',
        'Acquisto;Bombolone;2026-09-20;500;L;;;;',
        'Misurazione;Bombolone;2026-10-02;344;L;43;;;',
      ]);
    });

    test('csvDecimal: virgola, niente migliaia, niente zeri inutili', () {
      expect(csvDecimal(1200), '1200');
      expect(csvDecimal(343.99999999999994), '344');
      expect(csvDecimal(0.25), '0,25');
      expect(csvDecimal(12.5, fixed: true), '12,50');
      expect(csvDecimal(0), '0');
    });
  });
}
