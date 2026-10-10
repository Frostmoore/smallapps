import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/labels.dart';
import '../../app/sr_palette.dart';
import '../../domain/lettura/cartellino_parser.dart';
import '../../domain/nomi.dart';
import '../../domain/offerta.dart';
import '../../domain/quantita.dart';
import '../../domain/riga_spesa.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/una_mano.dart';

/// Cosa torna dal foglio di conferma del cartellino.
sealed class EsitoCartellino {
  const EsitoCartellino();
}

/// Una riga nuova da aggiungere.
final class CartellinoAggiungi extends EsitoCartellino {
  const CartellinoAggiungi(this.riga);

  final RigaSpesa riga;
}

/// Lo stesso prodotto e' gia' nella spesa: +[pezzi] alla riga [esistente] («Aggiungi (ora 2)»).
final class CartellinoIncrementa extends EsitoCartellino {
  const CartellinoIncrementa(this.esistente, this.pezzi);

  final RigaSpesa esistente;
  final int pezzi;
}

/// «Riprova»: di nuovo la fotocamera.
final class CartellinoRiprova extends EsitoCartellino {
  const CartellinoRiprova();
}

/// «Batti a mano»: il prezzo letto va nel display del tastierino.
final class CartellinoBattiAMano extends EsitoCartellino {
  const CartellinoBattiAMano(this.prezzo);

  final Money? prezzo;
}

/// La proposta da **confermare con un tocco** (develop_microapps.md F12.1.12,
/// `ConfermaCartellinoSheet`). ☠ **Mai aggiunta da sola** (F12.0 punto 4, f12-ocr.md §7): il
/// foglio si chiude con una riga solo se l'utente tocca Aggiungi.
///
/// - Nome modificabile; **prezzo da pagare grande** (Space Grotesk 40), modificabile con un tocco;
///   il prezzo pieno barrato se c'e'; il prezzo al kg/l stampato; la pillola dell'offerta.
/// - Quantita' con − e +, default 1; con un'offerta NxM il default e' N (⚑ chi guarda un 3x2 di
///   solito ne prende 3).
/// - Affidabilita' < 0,6 o prezzi alternativi: «Controlla il prezzo» in ambra e i chip.
/// - **Due prezzi (con e senza carta fedelta')**: due bottoni, uno per prezzo, e nessun default
///   (risposta D4 del proprietario, 2026-10-10: «chiedi ogni volta»). ⚑ Ogni bottone e' gia'
///   l'«Aggiungi» di quel prezzo: un tocco solo, come per gli altri cartellini.
/// - Prodotto gia' nella spesa (stesso nome normalizzato, stesso prezzo): «Aggiungi (ora 2)»
///   incrementa la riga esistente (⚑ cosi' un 3x2 scattato tre volte fa scattare l'offerta).
class ConfermaCartellinoSheet extends StatefulWidget {
  const ConfermaCartellinoSheet({required this.proposta, this.esistenti = const [], super.key});

  final PropostaCartellino proposta;

  /// Le righe contate della spesa in corso, per riconoscere un prodotto gia' preso.
  final List<RigaSpesa> esistenti;

  static Future<EsitoCartellino?> show(
    BuildContext context, {
    required PropostaCartellino proposta,
    List<RigaSpesa> esistenti = const [],
  }) => mostraFoglio<EsitoCartellino>(
    context,
    (_) => ConfermaCartellinoSheet(proposta: proposta, esistenti: esistenti),
  );

  @override
  State<ConfermaCartellinoSheet> createState() => _ConfermaCartellinoSheetState();
}

class _ConfermaCartellinoSheetState extends State<ConfermaCartellinoSheet> {
  late final TextEditingController _nome = TextEditingController(text: widget.proposta.nome);
  late final TextEditingController _prezzoTesto = TextEditingController();

  /// Il prezzo scelto o corretto (null = quello della proposta).
  Money? _prezzo;
  bool _modificaPrezzo = false;
  late int _pezzi = switch (widget.proposta.offerta) {
    OffertaNxM(:final prendi) => prendi,
    _ => 1,
  };

  @override
  void dispose() {
    _nome.dispose();
    _prezzoTesto.dispose();
    super.dispose();
  }

  Money? get _prezzoEffettivo => _prezzo ?? widget.proposta.prezzo;

  /// La riga che si aggiungerebbe con la proposta [prop] (gia' scelta la carta, se serve).
  RigaSpesa? _riga(PropostaCartellino prop, {Money? prezzo}) {
    final pz = prezzo ?? _prezzo ?? prop.prezzo;
    if (pz == null || pz.cents <= 0) return null;
    final unitario = prop.unitario;
    return RigaSpesa(
      nome: _nome.text.trim(),
      quantita: Pezzi(_pezzi),
      prezzoUnitario: pz,
      offerta: prop.offerta,
      prezzoRiferimento: unitario?.valore,
      unitaRiferimento: unitario?.unita,
      origine: OrigineRiga.cartellino,
    );
  }

  /// La riga gia' nella spesa con lo stesso nome normalizzato e lo stesso prezzo, a pezzi.
  RigaSpesa? _gemella(RigaSpesa nuova) {
    final nome = Nomi.normalizza(nuova.nome);
    if (nome.isEmpty) return null;
    for (final r in widget.esistenti.reversed) {
      if (r.pezzi == null || r.eSconto || r.totaleStampato != null) continue;
      if (r.prezzoUnitario == nuova.prezzoUnitario && Nomi.normalizza(r.nome) == nome) return r;
    }
    return null;
  }

  void _conferma(RigaSpesa? riga) {
    if (riga == null) return;
    final g = _gemella(riga);
    Navigator.of(context).pop(
      g == null ? CartellinoAggiungi(riga) : CartellinoIncrementa(g, _pezzi),
    );
  }

  void _salvaPrezzo() {
    final m = Money.tryParse(_prezzoTesto.text);
    setState(() {
      if (m != null && m.cents > 0) _prezzo = m;
      _modificaPrezzo = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final prop = widget.proposta;
    final carta = prop.carta;
    final prezzo = _prezzoEffettivo;
    final unitario = prop.unitario;
    final daControllare = prop.affidabilita < 0.6 || prop.alternative.isNotEmpty;
    final riga = carta == null ? _riga(prop) : null;
    final gemella = riga == null ? null : _gemella(riga);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TitoloFoglio(l.cartellino_conferma),
        TextField(
          key: const ValueKey('conferma_nome'),
          controller: _nome,
          maxLength: RigaSpesa.nomeMassimo,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l.riga_nome, hintText: l.riga_senzaNome, counterText: ''),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (carta == null) ...[
          if (_modificaPrezzo)
            TextField(
              key: const ValueKey('conferma_prezzoCampo'),
              controller: _prezzoTesto,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.riga_prezzo, suffixText: '€'),
              onSubmitted: (_) => _salvaPrezzo(),
              onTapOutside: (_) => _salvaPrezzo(),
            )
          else
            Semantics(
              button: true,
              label: l.cartellino_prezzoSemantica(prezzo == null ? '—' : importo(prezzo)),
              excludeSemantics: true,
              child: InkWell(
                key: const ValueKey('conferma_prezzo'),
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() {
                  _prezzoTesto.text = prezzo == null ? '' : importo(prezzo);
                  _modificaPrezzo = true;
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(prezzo == null ? '—' : importo(prezzo), style: p.numeri(size: 40)),
                      const SizedBox(width: 6),
                      Text('€', style: p.numeri(size: 22, color: p.testoSecondario)),
                      const SizedBox(width: 8),
                      Icon(Icons.edit_outlined, size: 18, color: p.testoSecondario),
                      const Spacer(),
                      if (prop.prezzoPieno != null && prop.prezzoPieno != prezzo)
                        Text(
                          importo(prop.prezzoPieno!),
                          key: const ValueKey('conferma_barrato'),
                          style: p.numeri(size: 20, color: p.testoSecondario).copyWith(
                            decoration: TextDecoration.lineThrough,
                            decorationColor: p.testoSecondario,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ] else
          Text(l.cartellino_cartaDomanda, style: stileEtichetta(p, colore: p.testo)),
        if (prop.offerta != null && prezzo != null && carta == null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              key: const ValueKey('conferma_offerta'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: p.accento.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                offertaLunga(l, prop.offerta!, prezzo),
                style: TextStyle(color: p.testo, fontWeight: FontWeight.w700, fontVariations: const [FontVariation('wght', 700)]),
              ),
            ),
          ),
        ],
        if (unitario != null) ...[
          const SizedBox(height: 6),
          Text(
            '${importo(unitario.valore)} €/${unitaTesto(unitario.unita)}',
            key: const ValueKey('conferma_alKg'),
            style: stileEtichetta(p),
          ),
        ],
        if (daControllare && carta == null) ...[
          const SizedBox(height: 12),
          AvvisoAmbra(testo: l.cartellino_controlla, icona: Icons.visibility_outlined),
          if (prop.alternative.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in prop.alternative)
                  ActionChip(
                    key: ValueKey('conferma_alternativa_${a.cents}'),
                    label: Text(importo(a), style: p.numeri(size: 16)),
                    onPressed: () => setState(() => _prezzo = a),
                  ),
              ],
            ),
          ],
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Text(l.riga_quantita, style: stileEtichetta(p)),
            const Spacer(),
            IconButton.outlined(
              key: const ValueKey('conferma_meno'),
              tooltip: l.riga_menoUno,
              onPressed: _pezzi > 1 ? () => setState(() => _pezzi--) : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 48,
              child: Text('$_pezzi', key: const ValueKey('conferma_pezzi'), textAlign: TextAlign.center, style: p.numeri(size: 22)),
            ),
            IconButton.outlined(
              key: const ValueKey('conferma_piu'),
              tooltip: l.riga_piuUno,
              onPressed: _pezzi < 99 ? () => setState(() => _pezzi++) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (carta != null) ...[
          FilledButton(
            key: const ValueKey('conferma_conCarta'),
            onPressed: () => _conferma(_riga(prop.scegliCarta(conCarta: true), prezzo: carta.conCarta)),
            child: Text(l.cartellino_conCarta(importo(carta.conCarta))),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const ValueKey('conferma_senzaCarta'),
            onPressed: () => _conferma(_riga(prop.scegliCarta(conCarta: false), prezzo: carta.senzaCarta)),
            child: Text(l.cartellino_senzaCarta(importo(carta.senzaCarta))),
          ),
        ] else
          FilledButton(
            key: const ValueKey('conferma_aggiungi'),
            onPressed: riga == null ? null : () => _conferma(riga),
            child: Text(gemella == null ? l.common_add : l.cartellino_aggiungiOra((gemella.pezzi ?? 1) + _pezzi)),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                key: const ValueKey('conferma_riprova'),
                onPressed: () => Navigator.of(context).pop(const CartellinoRiprova()),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(l.common_retry),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                key: const ValueKey('conferma_battiAMano'),
                onPressed: () => Navigator.of(context).pop(CartellinoBattiAMano(prezzo ?? carta?.conCarta)),
                icon: const Icon(Icons.dialpad),
                label: Text(l.cartellino_battiAMano),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Piu' cartellini nella stessa foto: «Ho visto 2 cartellini: quale?» (F12.1.12).
class SceltaCartellinoSheet extends StatelessWidget {
  const SceltaCartellinoSheet({required this.proposte, super.key});

  final List<PropostaCartellino> proposte;

  static Future<PropostaCartellino?> show(BuildContext context, List<PropostaCartellino> proposte) =>
      mostraFoglio<PropostaCartellino>(context, (_) => SceltaCartellinoSheet(proposte: proposte));

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TitoloFoglio(l.cartellino_quale(proposte.length)),
        for (final (i, prop) in proposte.indexed)
          ListTile(
            key: ValueKey('scelta_$i'),
            contentPadding: EdgeInsets.zero,
            minTileHeight: 56,
            title: Text(prop.nome.trim().isEmpty ? l.riga_senzaNome : prop.nome),
            trailing: Text(
              prop.prezzo != null
                  ? importo(prop.prezzo!)
                  : (prop.unitario != null ? '${importo(prop.unitario!.valore)} €/${unitaTesto(prop.unitario!.unita)}' : '—'),
              style: p.numeri(size: 20),
            ),
            onTap: () => Navigator.of(context).pop(prop),
          ),
      ],
    );
  }
}
