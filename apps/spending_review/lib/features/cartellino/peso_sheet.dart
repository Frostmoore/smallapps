import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/labels.dart';
import '../../app/sr_palette.dart';
import '../../domain/arrotonda.dart';
import '../../domain/quantita.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/una_mano.dart';
import '../spesa/tastierino_widget.dart';

/// Cosa torna dal foglio del peso.
sealed class EsitoPeso {
  const EsitoPeso();
}

/// Il peso battuto (grammi o millilitri).
final class PesoScelto extends EsitoPeso {
  const PesoScelto(this.quantita);

  final AMisura quantita;
}

/// «Leggi l'etichetta della bilancia»: si apre la fotocamera in modo bilancia.
final class PesoLeggiBilancia extends EsitoPeso {
  const PesoLeggiBilancia();
}

/// Il peso a mano dopo un prezzo al kg (develop_microapps.md F12.1.12, `PesoSheet`): «1,48 €/kg» in
/// alto, un tastierino uguale a quello della spesa ma per grammi (interi, con «kg» / «g»
/// commutabile: `0,500 kg` = 500 g), l'anteprima «0,500 kg × 1,48 = 0,74 €» in tempo reale
/// (`Arrotonda.perMisura`), **Aggiungi**, e «Leggi l'etichetta della bilancia».
///
/// ⚑ Il bottone della bilancia c'e' perche' alla bilancia self-service il peso esatto lo stampa
/// l'etichetta: battere 0,258 a mano e' piu' lento e sbaglia piu' di una foto.
class PesoSheet extends StatefulWidget {
  const PesoSheet({
    required this.alKg,
    required this.unita,
    this.nome = '',
    this.millesimiIniziali,
    this.mostraBilancia = true,
    super.key,
  });

  /// €/kg o €/l.
  final Money alKg;
  final UnitaMisura unita;
  final String nome;
  final int? millesimiIniziali;
  final bool mostraBilancia;

  static Future<EsitoPeso?> show(
    BuildContext context, {
    required Money alKg,
    required UnitaMisura unita,
    String nome = '',
    int? millesimiIniziali,
    bool mostraBilancia = true,
  }) => mostraFoglio<EsitoPeso>(
    context,
    (_) => PesoSheet(
      alKg: alKg,
      unita: unita,
      nome: nome,
      millesimiIniziali: millesimiIniziali,
      mostraBilancia: mostraBilancia,
    ),
  );

  @override
  State<PesoSheet> createState() => _PesoSheetState();
}

class _PesoSheetState extends State<PesoSheet> {
  /// In grammi (true) o in chili (false).
  bool _grammi = true;

  /// Le cifre battute; in chili con la virgola facoltativa.
  String _testo = '';

  @override
  void initState() {
    super.initState();
    final m = widget.millesimiIniziali;
    if (m != null && m > 0) _testo = '$m';
  }

  /// I millesimi del testo battuto, o null se non e' un peso valido (vuoto, zero, oltre il massimo).
  int? get _millesimi {
    if (_testo.isEmpty) return null;
    final int v;
    if (_grammi) {
      v = int.parse(_testo);
    } else {
      final parti = _testo.split(',');
      final interi = parti[0].isEmpty ? 0 : int.parse(parti[0]);
      final decimali = parti.length > 1 ? parti[1] : '';
      v = interi * 1000 + (decimali.isEmpty ? 0 : int.parse(decimali.padRight(3, '0')));
    }
    return (v < 1 || v > AMisura.massimo) ? null : v;
  }

  /// Un tasto: false se rifiutato.
  bool _aggiungi(String c) {
    final nuovo = _testo + c;
    if (_grammi) {
      if (c == ',' || nuovo.length > 5) return false;
    } else {
      final parti = nuovo.split(',');
      if (parti.length > 2) return false;
      if (parti[0].length > 2) return false;
      if (parti.length == 2 && parti[1].length > 3) return false;
    }
    setState(() => _testo = nuovo);
    return true;
  }

  void _cambiaUnita() {
    final m = _millesimi;
    setState(() {
      _grammi = !_grammi;
      // ⚑ Il valore si conserva: 500 g diventa «0,500», «0,5» kg diventa 500.
      _testo = m == null ? '' : (_grammi ? '$m' : millesimiTesto(m));
    });
  }

  void _conferma() {
    final m = _millesimi;
    if (m == null) return;
    Navigator.of(context).pop(PesoScelto(AMisura(m, widget.unita)));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final u = unitaTesto(widget.unita);
    final piccola = widget.unita == UnitaMisura.kg ? 'g' : 'ml';
    final m = _millesimi;
    final totale = m == null ? null : Arrotonda.perMisura(widget.alKg, m);
    final display = _testo.isEmpty ? '' : (_grammi ? '$_testo $piccola' : '$_testo $u');
    TastoGriglia cifra(String c, [String? sem]) => TastoGriglia(
      etichetta: c,
      semantica: sem ?? c,
      tipo: TipoTasto.cifra,
      onTap: () => _aggiungi(c),
      chiave: ValueKey('peso_$c'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TitoloFoglio(widget.nome.trim().isEmpty ? l.peso_titolo : widget.nome),
        Text('${importo(widget.alKg)} €/$u', style: p.numeri(size: 28)),
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            m == null
                ? l.peso_suggerimento
                : '${millesimiTesto(m)} $u × ${importo(widget.alKg)} = ${importo(totale!)} €',
            key: const ValueKey('peso_anteprima'),
            style: stileEtichetta(p, colore: m == null ? p.testoSecondario : p.testo),
          ),
        ),
        const SizedBox(height: 12),
        PannelloTastierino(
          etichetta: l.peso_etichetta,
          display: display,
          tasti: [
            cifra('7'),
            cifra('8'),
            cifra('9'),
            TastoGriglia(
              etichetta: '⌫',
              semantica: l.tasto_cancella,
              tipo: TipoTasto.operazione,
              icona: Icons.backspace_outlined,
              onTap: () => setState(() => _testo = _testo.isEmpty ? '' : _testo.substring(0, _testo.length - 1)),
            ),
            cifra('4'),
            cifra('5'),
            cifra('6'),
            TastoGriglia(
              etichetta: _grammi ? piccola : u,
              semantica: l.peso_cambiaUnita(_grammi ? u : piccola),
              tipo: TipoTasto.operazione,
              onTap: _cambiaUnita,
              chiave: const ValueKey('peso_unita'),
            ),
            cifra('1'),
            cifra('2'),
            cifra('3'),
            TastoGriglia(
              etichetta: 'C',
              semantica: l.tasto_svuota,
              tipo: TipoTasto.operazione,
              onTap: () => setState(() => _testo = ''),
            ),
            cifra('0'),
            TastoGriglia(
              etichetta: '00',
              semantica: l.tasto_doppioZero,
              tipo: TipoTasto.cifra,
              onTap: () {
                if (_aggiungi('0')) _aggiungi('0');
              },
            ),
            TastoGriglia(
              etichetta: ',',
              semantica: l.tasto_virgola,
              tipo: _grammi ? TipoTasto.operazione : TipoTasto.cifra,
              // ⚑ In grammi la virgola non serve (interi): toccarla passa ai chili, che e' quello
              // che si voleva («0,5» si batte cosi').
              onTap: () {
                if (_grammi) _cambiaUnita();
                _aggiungi(',');
              },
            ),
            TastoGriglia(
              etichetta: '+',
              semantica: l.common_add,
              tipo: TipoTasto.conferma,
              onTap: m == null ? null : _conferma,
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const ValueKey('peso_aggiungi'),
          onPressed: m == null ? null : _conferma,
          child: Text(totale == null ? l.common_add : l.peso_aggiungiPrezzo(importo(totale))),
        ),
        if (widget.mostraBilancia) ...[
          const SizedBox(height: 8),
          BottoneSecondario(
            etichetta: l.peso_leggiBilancia,
            icona: Icons.scale_outlined,
            onPressed: () => Navigator.of(context).pop(const PesoLeggiBilancia()),
          ),
        ],
      ],
    );
  }
}
