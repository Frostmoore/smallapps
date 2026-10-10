import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/labels.dart';
import '../../app/sr_palette.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/una_mano.dart';

/// Cosa torna dal foglio del budget: il nuovo budget (null = nessuno) e se usarlo anche come
/// budget abituale delle prossime spese.
typedef SceltaBudget = ({Money? budget, bool abituale});

/// Il budget di **questa** spesa (develop_microapps.md F12.1.12, tocco sulla riga di stato), e lo
/// stesso foglio per il budget abituale e il tetto del mese (Impostazioni, Statistiche).
///
/// ⚑ Il budget e' della spesa, non una tabella (F12.1.3): la spesa grande del sabato non e' quella
/// del pane. Le scorciatoie (30, 50, 80, 100) coprono le cifre tonde che si scelgono davvero; il
/// campo serve per le altre.
class BudgetSheet extends StatefulWidget {
  const BudgetSheet({
    required this.titolo,
    this.attuale,
    this.chiediAbituale = false,
    this.scorciatoie = const [3000, 5000, 8000, 10000],
    super.key,
  });

  final String titolo;
  final Money? attuale;

  /// Mostra «Usalo anche per le prossime spese».
  final bool chiediAbituale;

  /// In centesimi.
  final List<int> scorciatoie;

  static Future<SceltaBudget?> show(
    BuildContext context, {
    required String titolo,
    Money? attuale,
    bool chiediAbituale = false,
    List<int> scorciatoie = const [3000, 5000, 8000, 10000],
  }) => mostraFoglio<SceltaBudget>(
    context,
    (_) => BudgetSheet(titolo: titolo, attuale: attuale, chiediAbituale: chiediAbituale, scorciatoie: scorciatoie),
  );

  @override
  State<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<BudgetSheet> {
  late final TextEditingController _campo = TextEditingController(
    text: widget.attuale == null ? '' : importo(widget.attuale!),
  );
  bool _abituale = false;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  Money? get _valore {
    final m = Money.tryParse(_campo.text);
    return (m == null || m.cents <= 0) ? null : m;
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TitoloFoglio(widget.titolo),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in widget.scorciatoie)
              ChoiceChip(
                key: ValueKey('budget_$c'),
                label: Text('${c ~/ 100} €', style: p.numeri(size: 16)),
                selected: _valore?.cents == c,
                onSelected: (_) => setState(() => _campo.text = importo(Money.cents(c))),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('budget_campo'),
          controller: _campo,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l.budget_importo, suffixText: '€'),
          onChanged: (_) => setState(() {}),
        ),
        if (widget.chiediAbituale)
          CheckboxListTile(
            key: const ValueKey('budget_abituale'),
            contentPadding: EdgeInsets.zero,
            value: _abituale,
            onChanged: (v) => setState(() => _abituale = v ?? false),
            title: Text(l.budget_usaAbituale),
          ),
        const SizedBox(height: 12),
        FilledButton(
          key: const ValueKey('budget_salva'),
          onPressed: _valore == null ? null : () => Navigator.of(context).pop((budget: _valore, abituale: _abituale)),
          child: Text(l.common_save),
        ),
        if (widget.attuale != null) ...[
          const SizedBox(height: 8),
          TextButton(
            key: const ValueKey('budget_nessuno'),
            onPressed: () => Navigator.of(context).pop((budget: null, abituale: _abituale)),
            child: Text(l.budget_nessuno),
          ),
        ],
      ],
    );
  }
}
