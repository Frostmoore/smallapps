import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/labels.dart';
import '../../app/sr_palette.dart';
import '../../domain/offerta.dart';
import '../../domain/quantita.dart';
import '../../domain/riga_spesa.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cartellino/peso_sheet.dart';
import '../common/una_mano.dart';

/// Cosa torna dal foglio della riga.
sealed class EsitoRiga {
  const EsitoRiga();
}

final class RigaSalvata extends EsitoRiga {
  const RigaSalvata(this.riga);

  final RigaSpesa riga;
}

final class RigaEliminata extends EsitoRiga {
  const RigaEliminata();
}

/// Modifica o elimina una riga (develop_microapps.md F12.1.12, tocco su una riga della lista):
/// nome, quantita' ±, prezzo, offerta, elimina.
///
/// ⚑ **Peso a mano dopo un prezzo al kg**: una riga battuta a un pezzo senza offerta si trasforma
/// in «prezzo al kg» con «E' un prezzo al kg» (si apre il foglio del peso). E' la strada del
/// tastierino per i prodotti a peso senza cartellino letto (F12.0 punto 4: «entrambe le strade»).
/// ⚑ Una riga con il totale stampato (bilancia) mostra e modifica **quel** totale: e' lui che conta
/// (F12.1.5 punto 4); peso e prezzo restano informativi.
class RigaSheet extends StatefulWidget {
  const RigaSheet({required this.riga, super.key});

  final RigaSpesa riga;

  static Future<EsitoRiga?> show(BuildContext context, RigaSpesa riga) =>
      mostraFoglio<EsitoRiga>(context, (_) => RigaSheet(riga: riga));

  @override
  State<RigaSheet> createState() => _RigaSheetState();
}

class _RigaSheetState extends State<RigaSheet> {
  late RigaSpesa _riga = widget.riga;
  late final TextEditingController _nome = TextEditingController(text: widget.riga.nome);
  late final TextEditingController _prezzo = TextEditingController(
    text: importo(widget.riga.totaleStampato ?? widget.riga.prezzoUnitario),
  );

  @override
  void dispose() {
    _nome.dispose();
    _prezzo.dispose();
    super.dispose();
  }

  bool get _stampato => _riga.totaleStampato != null;

  /// La riga con i campi di testo applicati; null se il prezzo non e' valido.
  RigaSpesa? get _risultato {
    final testo = _prezzo.text.trim().replaceAll('−', '-');
    final m = Money.tryParse(testo);
    if (m == null || m.isZero) return null;
    // ⚑ Uno sconto resta uno sconto: il segno lo decide la riga, non il campo (che si batte senza).
    final segnato = _riga.eSconto && !m.isNegative ? Money.zero - m : m;
    final nome = _nome.text.trim();
    return _stampato
        ? _riga.copyWith(nome: nome, totaleStampato: segnato)
        : _riga.copyWith(nome: nome, prezzoUnitario: segnato);
  }

  Future<void> _aPeso() async {
    final r = _risultato ?? _riga;
    final esito = await PesoSheet.show(
      context,
      alKg: r.prezzoUnitario,
      unita: switch (r.quantita) {
        AMisura(:final unita) => unita,
        Pezzi() => UnitaMisura.kg,
      },
      nome: r.nome,
      millesimiIniziali: switch (r.quantita) {
        AMisura(:final millesimi) => millesimi,
        Pezzi() => null,
      },
      mostraBilancia: false,
    );
    if (esito is PesoScelto && mounted) {
      setState(() => _riga = r.copyWith(quantita: esito.quantita, togliOfferta: true));
    }
  }

  void _offerta(Offerta? o) => setState(() => _riga = o == null ? _riga.copyWith(togliOfferta: true) : _riga.copyWith(offerta: o));

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final pezzi = _riga.pezzi;
    final risultato = _risultato;
    final offerta = _riga.offerta;
    final offertePronte = <Offerta>[
      const OffertaNxM(prendi: 3, paghi: 2),
      const OffertaNxM(prendi: 2, paghi: 1),
      const OffertaSecondoAPercento(50),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TitoloFoglio(l.riga_titolo),
        TextField(
          key: const ValueKey('riga_nome'),
          controller: _nome,
          maxLength: RigaSpesa.nomeMassimo,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l.riga_nome, hintText: nomeRiga(l, _riga), counterText: ''),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('riga_prezzo'),
          controller: _prezzo,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: InputDecoration(
            labelText: _stampato
                ? l.riga_totaleStampato
                : switch (_riga.quantita) {
                    AMisura(:final unita) => l.riga_prezzoAl(unitaTesto(unita)),
                    Pezzi() => l.riga_prezzo,
                  },
            suffixText: '€',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (pezzi != null && !_riga.eSconto)
          Row(
            children: [
              Text(l.riga_quantita, style: stileEtichetta(p)),
              const Spacer(),
              IconButton.outlined(
                key: const ValueKey('riga_meno'),
                tooltip: l.riga_menoUno,
                onPressed: pezzi > 1 ? () => setState(() => _riga = _riga.copyWith(quantita: Pezzi(pezzi - 1))) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 48,
                child: Text('$pezzi', key: const ValueKey('riga_pezzi'), textAlign: TextAlign.center, style: p.numeri(size: 22)),
              ),
              IconButton.outlined(
                key: const ValueKey('riga_piu'),
                tooltip: l.riga_piuUno,
                onPressed: pezzi < Pezzi.massimo
                    ? () => setState(() => _riga = _riga.copyWith(quantita: Pezzi(pezzi + 1)))
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        if (_riga.quantita case AMisura(:final millesimi, :final unita))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${millesimiTesto(millesimi)} ${unitaTesto(unita)}', style: p.numeri(size: 20)),
            subtitle: Text(l.riga_peso),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _stampato ? null : () => _aPeso(),
          ),
        if (pezzi == 1 && !_riga.eSconto && offerta == null && !_stampato)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('riga_aPeso'),
              onPressed: () => _aPeso(),
              icon: const Icon(Icons.scale_outlined),
              label: Text(l.riga_ePrezzoAlKg),
            ),
          ),
        if (pezzi != null && !_riga.eSconto && !_stampato) ...[
          const SizedBox(height: 8),
          Text(l.riga_offerta, style: stileEtichetta(p)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                key: const ValueKey('riga_offertaNessuna'),
                label: Text(l.riga_offertaNessuna),
                selected: offerta == null,
                onSelected: (_) => _offerta(null),
              ),
              for (final o in offertePronte)
                ChoiceChip(
                  label: Text(offertaBreve(o)!),
                  selected: offerta == o,
                  onSelected: (_) => _offerta(o),
                ),
              if (offerta != null && !offertePronte.contains(offerta))
                ChoiceChip(label: Text(offertaTesto(l, offerta) ?? ''), selected: true, onSelected: (_) {}),
            ],
          ),
        ],
        const SizedBox(height: 16),
        if (risultato != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(l.riga_totale(importo(risultato.totale)), style: stileEtichetta(p, colore: p.testo)),
          ),
        FilledButton(
          key: const ValueKey('riga_salva'),
          onPressed: risultato == null ? null : () => Navigator.of(context).pop(RigaSalvata(risultato)),
          child: Text(l.common_save),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          key: const ValueKey('riga_elimina'),
          style: TextButton.styleFrom(foregroundColor: p.rosso),
          onPressed: () => Navigator.of(context).pop(const RigaEliminata()),
          icon: const Icon(Icons.delete_outline),
          label: Text(l.common_delete),
        ),
      ],
    );
  }
}
