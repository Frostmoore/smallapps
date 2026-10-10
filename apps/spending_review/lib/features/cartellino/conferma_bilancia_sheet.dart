import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/labels.dart';
import '../../app/sr_palette.dart';
import '../../domain/lettura/bilancia_parser.dart';
import '../../domain/quantita.dart';
import '../../domain/riga_spesa.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/una_mano.dart';

/// Cosa torna dal foglio della bilancia.
sealed class EsitoBilancia {
  const EsitoBilancia();
}

final class BilanciaAggiungi extends EsitoBilancia {
  const BilanciaAggiungi(this.riga);

  final RigaSpesa riga;
}

final class BilanciaRiprova extends EsitoBilancia {
  const BilanciaRiprova();
}

/// L'etichetta della bilancia letta (develop_microapps.md F12.1.12, `ConfermaBilanciaSheet`):
/// prodotto, «0,258 kg × 29,90 €/kg», **totale grande**, riga ambra «Il conto peso × prezzo non
/// torna: controlla» se `coerente == false`; campi modificabili; **Aggiungi** → riga `AMisura` con
/// `totaleStampato`.
///
/// ⚑ Il totale stampato **vince** nel conto (F12.1.5 punto 4): e' quello che la cassa leggera'
/// dal codice a barre, anche se peso × prezzo non torna di un centesimo. Per questo e' lui il
/// numero grande, e il campo modificabile e' lui.
class ConfermaBilanciaSheet extends StatefulWidget {
  const ConfermaBilanciaSheet({required this.lettura, super.key});

  final LetturaBilancia lettura;

  static Future<EsitoBilancia?> show(BuildContext context, LetturaBilancia lettura) =>
      mostraFoglio<EsitoBilancia>(context, (_) => ConfermaBilanciaSheet(lettura: lettura));

  @override
  State<ConfermaBilanciaSheet> createState() => _ConfermaBilanciaSheetState();
}

class _ConfermaBilanciaSheetState extends State<ConfermaBilanciaSheet> {
  late final TextEditingController _nome = TextEditingController(text: widget.lettura.prodotto ?? '');
  late final TextEditingController _peso = TextEditingController(
    text: widget.lettura.pesoNetto == null ? '' : millesimiTesto(widget.lettura.pesoNetto!.millesimi),
  );
  late final TextEditingController _alKg = TextEditingController(
    text: widget.lettura.alKg == null ? '' : importo(widget.lettura.alKg!),
  );
  late final TextEditingController _totale = TextEditingController(
    text: widget.lettura.totale == null ? '' : importo(widget.lettura.totale!),
  );

  @override
  void dispose() {
    _nome.dispose();
    _peso.dispose();
    _alKg.dispose();
    _totale.dispose();
    super.dispose();
  }

  /// «0,258» → 258 grammi. Interi: niente double.
  static int? _grammi(String testo) {
    final t = testo.trim().replaceAll('.', ',');
    final m = RegExp(r'^(\d{1,2})(?:,(\d{1,3}))?$').firstMatch(t);
    if (m == null) return null;
    final v = int.parse(m.group(1)!) * 1000 + int.parse((m.group(2) ?? '').padRight(3, '0'));
    return (v < 1 || v > AMisura.massimo) ? null : v;
  }

  RigaSpesa? get _riga {
    final totale = Money.tryParse(_totale.text);
    if (totale == null || totale.cents <= 0) return null;
    final grammi = _grammi(_peso.text);
    final alKg = Money.tryParse(_alKg.text);
    final aMisura = grammi != null && alKg != null && alKg.cents > 0;
    return RigaSpesa(
      nome: _nome.text.trim(),
      // ⚑ Senza peso o senza €/kg leggibili la riga resta «1 pezzo al totale stampato»: il conto
      // e' comunque giusto, perche' vince il totale.
      quantita: aMisura ? AMisura(grammi, UnitaMisura.kg) : const Pezzi(1),
      prezzoUnitario: aMisura ? alKg : totale,
      totaleStampato: totale,
      origine: OrigineRiga.bilancia,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final riga = _riga;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TitoloFoglio(l.bilancia_titolo),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(riga == null ? '—' : importo(riga.totale), key: const ValueKey('bilancia_totale'), style: p.numeri(size: 40)),
            const SizedBox(width: 6),
            Text('€', style: p.numeri(size: 22, color: p.testoSecondario)),
          ],
        ),
        if (!widget.lettura.coerente) ...[
          const SizedBox(height: 12),
          AvvisoAmbra(testo: l.bilancia_nonTorna),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _nome,
          maxLength: RigaSpesa.nomeMassimo,
          decoration: InputDecoration(labelText: l.riga_nome, hintText: l.riga_senzaNome, counterText: ''),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('bilancia_peso'),
                controller: _peso,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.bilancia_peso, suffixText: 'kg'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _alKg,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.bilancia_alKg, suffixText: '€/kg'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('bilancia_totaleCampo'),
          controller: _totale,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l.bilancia_totaleEtichetta, suffixText: '€'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('bilancia_aggiungi'),
          onPressed: riga == null ? null : () => Navigator.of(context).pop(BilanciaAggiungi(riga)),
          child: Text(l.common_add),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(const BilanciaRiprova()),
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(l.common_retry),
        ),
      ],
    );
  }
}
