import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/data/database.dart';
import 'package:full_freezer/l10n/generated/app_localizations.dart';
import 'package:full_freezer/services/freezer_widget.dart';

/// F4.11: cosa finisce nel widget. I giorni NON ci sono (ADR-018): li calcola il widget.
void main() {
  Item item(int id, String name, String frozenAt, {String? category, int? reminder}) => Item(
    id: id,
    freezerId: 1,
    name: name,
    nameNorm: name.toLowerCase(),
    category: category,
    quantity: 1,
    unit: 'portions',
    frozenAt: frozenAt,
    reminderAfterDays: reminder,
    volumeLiters: 0.5,
    volumeManual: false,
    status: ItemStatus.stored,
    createdAt: id,
  );

  List<List<String>> campi(List<String> rows) => [for (final r in rows) r.split(FreezerWidget.fieldSeparator)];

  test('i tre piu\' vecchi, dal piu\' vecchio, con data e non giorni', () {
    final rows = FreezerWidget.buildRows([
      item(1, 'Piselli', '2026-09-01', category: 'vegetables'),
      item(2, 'Spezzatino', '2026-05-23', category: 'meat_red'),
      item(3, 'Gelato', '2026-10-01', category: 'ice_cream'),
      item(4, 'Pane', '2026-07-03', category: 'bread'),
    ], const []);
    expect(campi(rows).map((c) => c[1]), ['Spezzatino', 'Pane', 'Piselli']);
    expect(campi(rows).first, ['2026-05-23', 'Spezzatino', 'meat', '180']);
  });

  test('il promemoria dell\'alimento vince su quello della categoria; senza nessuno resta vuoto', () {
    final rows = campi(FreezerWidget.buildRows([
      item(1, 'Ragù', '2026-01-01', category: 'prepared', reminder: 30),
      item(2, 'Mistero', '2026-01-02'),
    ], const []));
    expect(rows[0][3], '30');
    expect(rows[1][3], '');
    expect(rows[1][2], 'other');
  });

  test('una categoria personalizzata porta la sua icona; un a capo nel nome non spezza la riga', () {
    const custom = CustomCategory(id: 5, name: 'Pappe', iconKey: 'fruit', colorValue: 0);
    final rows = campi(FreezerWidget.buildRows([item(1, 'Pappa\nmela', '2026-01-01', category: 'custom:5')], [custom]));
    expect(rows.single[1], 'Pappa mela');
    expect(rows.single[2], 'fruit');
  });

  test('il modello dei giorni viene dal testo dell\'app', () {
    expect(FreezerWidget.daysTemplate(lookupL(const Locale('it'))), '{n} gg');
    expect(FreezerWidget.daysTemplate(lookupL(const Locale('en'))), '{n} d');
  });

  testWidgets('le icone si disegnano in PNG', (tester) async {
    final png = await tester.runAsync(() => FreezerWidget.renderIcon('meat'));
    expect(png!.sublist(1, 4), 'PNG'.codeUnits);
  });
}
