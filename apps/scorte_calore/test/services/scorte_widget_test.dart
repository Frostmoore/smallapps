import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:scorte_calore/domain/consumption.dart';
import 'package:scorte_calore/l10n/generated/app_localizations.dart';
import 'package:scorte_calore/services/scorte_widget.dart';

/// Il payload del widget (ADR-018): date, non giorni. Il formato e' letto da
/// ScorteCaloreWidgetProvider.kt e da VistaScorte.swift: se cambia qui, cambia in tre posti.
ConsumptionEstimate _stima({required EstimateQuality quality, CivilDate? depletion, CivilDate? reorder}) =>
    ConsumptionEstimate(
      dailyRate: quality == EstimateQuality.insufficient ? null : 2,
      currentQuantity: 100,
      daysRemaining: quality == EstimateQuality.insufficient ? null : 50,
      depletionDate: depletion,
      reorderDate: reorder,
      quality: quality,
      intervalsUsed: 2,
      spanDays: 20,
      lastMeasurementDate: CivilDate(2026, 10, 1),
      referenceQuantity: 200,
    );

void main() {
  const us = '\u001F';

  test('una stima pronta porta esaurimento, riordino e la data breve', () {
    final riga = ScorteWidget.buildRow(
      name: 'Stufa soggiorno',
      estimate: _stima(quality: EstimateQuality.good, depletion: CivilDate(2026, 12, 9), reorder: CivilDate(2026, 12, 1)),
      reorderShort: '1 dic',
    );
    expect(riga, 'Stufa soggiorno${us}2026-12-09${us}2026-12-01${us}1 dic');
  });

  test('senza stima le date restano vuote ma i campi sono quattro', () {
    for (final e in [null, _stima(quality: EstimateQuality.insufficient)]) {
      final riga = ScorteWidget.buildRow(name: 'Caldaia', estimate: e, reorderShort: 'ignorata');
      expect(riga.split(us), ['Caldaia', '', '', '']);
    }
  });

  test('un a capo nel nome non spezza le righe', () {
    final riga = ScorteWidget.buildRow(name: 'Stufa\nsala', estimate: null, reorderShort: '');
    expect(riga.contains('\n'), isFalse);
  });

  test('il modello dei giorni ha il segnaposto e la parola dell app', () {
    final it = ScorteWidget.daysTemplate(lookupL(const Locale('it')));
    final en = ScorteWidget.daysTemplate(lookupL(const Locale('en')));
    expect(it, startsWith('{n} '));
    expect(en, startsWith('{n} '));
    expect(it, isNot(en));
  });
}
