import 'package:film_tracker/data/database.dart';
import 'package:film_tracker/data/film_repository.dart';
import 'package:film_tracker/l10n/generated/app_localizations.dart';
import 'package:film_tracker/services/csv_export.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// F6.11: il CSV dei rullini, riga per riga, come lo apre Excel in italiano (`;`, BOM,
/// virgola decimale, date ISO).
void main() {
  final l = lookupL(const Locale('it'));

  const om2 = Camera(id: 1, manufacturer: 'Olympus', model: 'OM-2', format: '35mm', active: true, sortOrder: 0);

  FilmRoll roll(int id, {String? title, String? note, int? cost, String status = 'archived', int nominal = 400, int exposed = 400}) =>
      FilmRoll(
        id: id,
        sequenceNumber: id,
        filmName: 'Kodak Portra 400',
        format: '35mm',
        nominalIso: nominal,
        exposedIso: exposed,
        cameraId: 1,
        loadedAt: '2026-0$id-01',
        finishedAt: '2026-0$id-20',
        frames: 36,
        title: title,
        note: note,
        status: status,
        costCents: cost,
        createdAt: 0,
      );

  test('intestazione, BOM e una riga per rullino dal numero piu\' basso', () {
    final items = [
      // Il #2 arriva prima, come dalla home: il CSV li rimette in ordine.
      RollListItem(
        roll: roll(2, title: 'Praga; settembre', note: 'detto "il buono"', cost: 1590, nominal: 250, exposed: 500, status: 'printed'),
        camera: om2,
        development: const Development(
          id: 1,
          filmRollId: 2,
          laboratory: 'Fotoservice',
          submittedAt: '2026-02-21',
          returnedAt: '2026-02-28',
          developmentCostCents: 900,
          scanCostCents: 505,
          process: 'C-41',
          selfDeveloped: false,
        ),
        prints: const [
          PrintOrder(id: 1, filmRollId: 2, laboratory: 'Fotoservice', numberOfPrints: 12, costCents: 600),
          PrintOrder(id: 2, filmRollId: 2, laboratory: 'fotoservice', numberOfPrints: 3),
          PrintOrder(id: 3, filmRollId: 2, laboratory: 'Lab Roma', costCents: 250),
        ],
      ),
      RollListItem(roll: roll(1, status: 'exposed')),
    ];
    final out = buildRollsCsv(l: l, items: items).build();

    expect(out.startsWith('﻿'), isTrue, reason: 'senza BOM Excel legge gli accenti come ANSI');
    final lines = out.substring(1).split('\r\n');
    expect(lines.last, '', reason: 'ogni riga finisce con CRLF');
    expect(lines, hasLength(4));

    expect(
      lines[0],
      'Numero;Titolo;Pellicola;Formato;ISO nominale;ISO di esposizione;Macchina;Stato;Caricato;Terminato;'
      'Fotogrammi;Costo pellicola (€);Laboratorio sviluppo;Consegnato al laboratorio;Ritirato dal laboratorio;'
      'Processo;Sviluppato in casa;Costo sviluppo (€);Costo scansioni (€);Ordini di stampa;Copie stampate;'
      'Laboratori stampa;Costo stampe (€);Costo totale (€);Nota',
    );
    // Il #1: niente sviluppo, niente stampe, niente costi -> celle vuote, totale vuoto (non 0).
    expect(lines[1], '1;;Kodak Portra 400;35 mm;400;400;;Terminato;2026-01-01;2026-01-20;36;;;;;;;;;;;;;;');
    // Il #2: il titolo con `;` e la nota con le virgolette sono quotati; costi in euro con due
    // decimali e virgola; i laboratori delle stampe senza doppioni di maiuscole.
    expect(
      lines[2],
      '2;"Praga; settembre";Kodak Portra 400;35 mm;250;500;Olympus OM-2;Stampato;2026-02-01;2026-02-20;36;15,90;'
      'Fotoservice;2026-02-21;2026-02-28;C-41;No;9,00;5,05;3;15;Fotoservice, Lab Roma;8,50;38,45;'
      '"detto ""il buono"""',
    );
  });

  test('sviluppo in casa senza costi: "Sì" e totale vuoto', () {
    final out = buildRollsCsv(
      l: l,
      items: [
        RollListItem(
          roll: roll(3),
          development: const Development(id: 9, filmRollId: 3, process: 'BW', selfDeveloped: true),
        ),
      ],
    ).build();
    final row = out.substring(1).split('\r\n')[1].split(';');
    expect(row[15], 'Bianco e nero');
    expect(row[16], 'Sì');
    expect(row[23], '', reason: 'nessun costo scritto: non saputo, non gratis');
  });
}
