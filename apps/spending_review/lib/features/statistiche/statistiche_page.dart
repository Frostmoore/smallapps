import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../app/sr_palette.dart';
import '../../data/database.dart' show Negozio;
import '../../domain/spesa.dart';
import '../../domain/statistiche.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/scelte.dart';
import '../common/una_mano.dart';
import '../spesa/budget_sheet.dart';
import 'grafico_mesi.dart';

/// Le statistiche (develop_microapps.md F12.1.12, `/statistiche`, **Pro**: la rotta e' avvolta in
/// `ProGate(FeatureKey.statistics)`).
///
/// Selettore del mese (frecce); il **budget del mese** (risposta D3 del proprietario: speso nel
/// mese contro un tetto, con la spesa in corso dentro); quattro tessere: **Totale del mese**,
/// **Spese**, **Spesa media**, **Sforamenti** («2 su 5 con budget»); il grafico degli **ultimi 6
/// mesi** (fino a quello scelto); la tabella **per negozio** per il mese o per gli ultimi 12 mesi.
///
/// ⚑ Legge **tutte** le spese chiuse (`tutteLeChiuseProvider`), anche quelle che il gratis
/// nascondeva: chi compra il Pro dopo tre mesi trova le statistiche gia' piene (D1).
class StatistichePage extends ConsumerStatefulWidget {
  const StatistichePage({super.key});

  @override
  ConsumerState<StatistichePage> createState() => _StatistichePageState();
}

class _StatistichePageState extends ConsumerState<StatistichePage> {
  late CivilDate _mese = CivilDate.fromDateTime(ref.read(oraProvider)()).firstDayOfMonth;
  bool _dodiciMesi = false;

  Future<void> _tetto(Money? attuale) async {
    final l = L.of(context);
    final scelta = await BudgetSheet.show(
      context,
      titolo: l.statistiche_tettoTitolo,
      attuale: attuale,
      scorciatoie: const [20000, 30000, 40000, 60000],
    );
    if (scelta == null) return;
    await ref.read(budgetMensileProvider.notifier).set(scelta.budget);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final chiuse = ref.watch(tutteLeChiuseProvider).value ?? const <Spesa>[];
    final inCorso = ref.watch(spesaInCorsoProvider).value;
    final tetto = ref.watch(budgetMensileProvider);
    final negozi = {for (final Negozio n in ref.watch(negoziProvider).value ?? const []) n.id: n.nome};
    final oggi = CivilDate.fromDateTime(ref.watch(oraProvider)());
    final questoMese = oggi.firstDayOfMonth;
    final mese = StatisticheSpesa.mese(chiuse, _mese.year, _mese.month);
    final media = mese.media;
    final budgetMese = tetto == null
        ? null
        : StatisticheSpesa.budgetMese(chiuse, tetto, _mese.year, _mese.month, inCorso: inCorso);
    final (da, a) = _dodiciMesi
        ? (questoMese.addMonths(-11), oggi.lastDayOfMonth)
        : (_mese, _mese.lastDayOfMonth);
    final perNegozio = StatisticheSpesa.perNegozio(chiuse, negozi, da, a, senzaNegozio: l.negozio_nessuno);
    final nomeMese = toBeginningOfSentenceCase(DateFormat.yMMMM(locale).format(_mese.toLocalMidnight()));

    return PaginaUnaMano(
      titolo: l.statistiche_title,
      corpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Row(
            children: [
              IconButton(
                key: const ValueKey('statistiche_prima'),
                tooltip: l.statistiche_mesePrima,
                onPressed: () => setState(() => _mese = _mese.addMonths(-1)),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(nomeMese, key: const ValueKey('statistiche_mese'), textAlign: TextAlign.center, style: stileTitolo(p)),
              ),
              IconButton(
                key: const ValueKey('statistiche_dopo'),
                tooltip: l.statistiche_meseDopo,
                onPressed: _mese.isBefore(questoMese) ? () => setState(() => _mese = _mese.addMonths(1)) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _BudgetMese(budget: budgetMese, onTetto: () => unawaited(_tetto(tetto))),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              MicroStatTile(label: l.statistiche_totaleMese, value: '${importo(mese.totale)} €', icon: Icons.euro),
              MicroStatTile(label: l.statistiche_spese, value: '${mese.spese}', icon: Icons.shopping_cart_outlined),
              MicroStatTile(
                label: l.statistiche_media,
                value: media == null ? '—' : '${importo(media)} €',
                icon: Icons.functions,
              ),
              MicroStatTile(
                label: l.statistiche_sforamenti,
                value: '${mese.sforamenti}',
                hint: l.statistiche_sforamentiSu(mese.conBudget),
                icon: Icons.trending_up,
              ),
            ],
          ),
          Sezione(l.statistiche_ultimiSei),
          GraficoMesi(mesi: StatisticheSpesa.ultimiMesi(chiuse, _mese), evidenziato: (_mese.year, _mese.month)),
          Sezione(l.statistiche_perNegozio),
          SegmentedButton<bool>(
            key: const ValueKey('statistiche_periodo'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text(l.statistiche_questoMese)),
              ButtonSegment(value: true, label: Text(l.statistiche_dodiciMesi)),
            ],
            selected: {_dodiciMesi},
            onSelectionChanged: (s) => setState(() => _dodiciMesi = s.first),
          ),
          const SizedBox(height: 8),
          if (perNegozio.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(l.statistiche_nessunaSpesa, style: TextStyle(color: p.testoSecondario)),
            )
          else
            Table(
              columnWidths: const {0: FlexColumnWidth(3), 1: IntrinsicColumnWidth(), 2: FlexColumnWidth(2), 3: FlexColumnWidth(2)},
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  children: [
                    for (final t in [l.statistiche_negozio, l.statistiche_spese, l.statistiche_totale, l.statistiche_media])
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
                        child: Text(t, style: stileEtichetta(p), textAlign: t == l.statistiche_negozio ? TextAlign.start : TextAlign.end),
                      ),
                  ],
                ),
                for (final v in perNegozio)
                  TableRow(
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: p.superficieOp))),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 10, 8, 10),
                        child: Text(v.nome, style: TextStyle(color: v.negozioId == null ? p.testoSecondario : p.testoLista)),
                      ),
                      Padding(padding: const EdgeInsets.only(right: 8), child: Text('${v.spese}', textAlign: TextAlign.end)),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(importo(v.totale), textAlign: TextAlign.end, style: p.numeri(size: 15)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(importo(v.media), textAlign: TextAlign.end, style: p.numeri(size: 15, color: p.testoSecondario)),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Il budget del MESE (D3): «Speso 182,40 su 400» con la barra, il residuo, e il tetto da cambiare.
class _BudgetMese extends StatelessWidget {
  const _BudgetMese({required this.budget, required this.onTetto});

  final BudgetMese? budget;
  final VoidCallback onTetto;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final b = budget;
    return Container(
      key: const ValueKey('statistiche_budgetMese'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.superficie, borderRadius: BorderRadius.circular(18)),
      child: b == null
          ? Row(
              children: [
                Expanded(child: Text(l.statistiche_tettoNessuno, style: TextStyle(color: p.testoSecondario))),
                TextButton(key: const ValueKey('statistiche_tetto'), onPressed: onTetto, child: Text(l.statistiche_tettoImposta)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(l.statistiche_budgetMese, style: stileEtichetta(p))),
                    TextButton(key: const ValueKey('statistiche_tetto'), onPressed: onTetto, child: Text(l.statistiche_tettoCambia)),
                  ],
                ),
                Text(
                  l.statistiche_spesoSu(importo(b.speso), importoTondo(b.tetto)),
                  key: const ValueKey('statistiche_speso'),
                  style: p.numeri(size: 22),
                ),
                const SizedBox(height: 10),
                BarraBudget(frazione: b.speso.cents / b.tetto.cents, colore: p.coloreBudget(b.livello) ?? p.accento),
                const SizedBox(height: 6),
                Text(
                  b.residuo.isNegative
                      ? l.statistiche_tettoSforato(importo(Money.zero - b.residuo))
                      : l.statistiche_tettoResiduo(importo(b.residuo)),
                  style: stileEtichetta(p, colore: p.coloreBudget(b.livello)),
                ),
              ],
            ),
    );
  }
}
