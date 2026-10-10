import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/sr_palette.dart';
import '../../domain/lettura/scontrino_parser.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/lettura_service.dart';
import '../common/scelte.dart';
import '../common/una_mano.dart';

/// La registrazione pura dallo scontrino (develop_microapps.md F12.1.12, `/scontrino/registra`,
/// Pro): niente spesa contata, lo scontrino **e'** la spesa.
///
/// Negozio (dallo scontrino, modificabile), data (dallo scontrino o oggi), righe lette
/// (modificabili, eliminabili, con lo stato «stornata»), totale stampato e avviso se non quadra;
/// **Salva la spesa** → `SpesaRepository.registraDaScontrino` → il dettaglio nello storico.
/// ⚑ Il totale salvato e' quello STAMPATO (o la somma se manca): e' cio' che si e' pagato.
class RegistraScontrinoPage extends ConsumerStatefulWidget {
  const RegistraScontrinoPage({required this.letto, super.key});

  final ScontrinoLetto letto;

  @override
  ConsumerState<RegistraScontrinoPage> createState() => _RegistraScontrinoPageState();
}

class _RegistraScontrinoPageState extends ConsumerState<RegistraScontrinoPage> {
  late final LetturaScontrino _l = widget.letto.lettura;
  late String? _negozio = _l.negozioMostrato;
  late CivilDate _data = _l.data ?? CivilDate.fromDateTime(ref.read(oraProvider)());
  late final List<RigaScontrino> _righe = List.of(_l.righe);
  bool _salvo = false;

  Money get _somma => Money.sum(_righe.map((r) => r.importo));

  Future<void> _modifica(int i) async {
    final l = L.of(context);
    final r = _righe[i];
    final nome = TextEditingController(text: r.descrizione);
    final importoCampo = TextEditingController(text: importo(r.importo));
    final nuova = await showDialog<RigaScontrino>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.riga_titolo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nome, decoration: InputDecoration(labelText: l.riga_nome)),
            TextField(
              controller: importoCampo,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(labelText: l.riga_importo, suffixText: '€'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l.common_cancel)),
          TextButton(
            onPressed: () {
              final m = Money.tryParse(importoCampo.text.replaceAll('−', '-'));
              if (m == null || m.isZero) return;
              Navigator.of(ctx).pop(
                RigaScontrino(
                  descrizione: nome.text.trim(),
                  importo: m,
                  tipo: r.tipo,
                  quantita: m == r.importo ? r.quantita : null,
                  prezzoUnitario: m == r.importo ? r.prezzoUnitario : null,
                  stornata: r.stornata,
                ),
              );
            },
            child: Text(l.common_save),
          ),
        ],
      ),
    );
    nome.dispose();
    importoCampo.dispose();
    if (nuova != null && mounted) setState(() => _righe[i] = nuova);
  }

  Future<void> _salva() async {
    if (_salvo) return;
    setState(() => _salvo = true);
    try {
      final repo = ref.read(spesaRepositoryProvider);
      final nome = _negozio?.trim();
      final negozioId = (nome == null || nome.isEmpty) ? null : await repo.negozioPerNome(nome);
      final id = await repo.registraDaScontrino(
        LetturaScontrino(
          negozio: _l.negozio,
          data: _data,
          righe: _righe,
          totale: _l.totale,
          righeIgnorate: _l.righeIgnorate,
        ),
        data: _data,
        negozioId: negozioId,
      );
      if (mounted) context.go(Routes.dettaglioDi(id));
    } finally {
      if (mounted) setState(() => _salvo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final totale = _l.totale;
    final quadra = totale != null && totale == _somma;
    return PaginaUnaMano(
      titolo: l.registra_titolo,
      fondo: FilledButton(
        key: const ValueKey('registra_salva'),
        onPressed: _salvo || (_righe.isEmpty && totale == null) ? null : () => unawaited(_salva()),
        child: Text(l.registra_salva),
      ),
      corpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          CardNumero(
            etichetta: totale == null ? l.registra_sommaRighe : l.registra_totaleStampato,
            valore: importo(totale ?? _somma),
            dimensione: 36,
          ),
          if (!quadra) ...[
            const SizedBox(height: 10),
            AvvisoAmbra(
              testo: totale == null
                  ? l.registra_senzaTotale
                  : l.registra_nonQuadra(_l.righeIgnorate, importo(_somma)),
            ),
          ],
          if (widget.letto.giunzioniMancanti > 0) ...[
            const SizedBox(height: 10),
            AvvisoAmbra(testo: l.confronto_giunzione(widget.letto.parti), icona: Icons.call_split),
          ],
          Sezione(l.chiusura_negozio),
          SceltaNegozio(valore: _negozio, onCambia: (v) => setState(() => _negozio = v)),
          Sezione(l.chiusura_data),
          SceltaData(data: _data, onCambia: (d) => setState(() => _data = d)),
          Sezione(l.registra_righe(_righe.length)),
          for (final (i, r) in _righe.indexed)
            Dismissible(
              key: ObjectKey(r),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: p.rosso.withValues(alpha: 0.25),
                child: Icon(Icons.delete_outline, color: p.rosso),
              ),
              onDismissed: (_) => setState(() => _righe.removeAt(i)),
              child: ListTile(
                key: ValueKey('registra_riga_$i'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  r.descrizione.isEmpty ? l.riga_senzaNome : r.descrizione,
                  style: TextStyle(
                    color: r.stornata ? p.testoSecondario : p.testoLista,
                    decoration: r.stornata ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: r.stornata
                    ? Text(l.registra_stornata)
                    : (r.tipo == TipoRigaScontrino.sconto ? Text(l.riga_sconto) : null),
                trailing: Text(importo(r.importo), style: p.numeri(size: 16)),
                onTap: () => unawaited(_modifica(i)),
              ),
            ),
        ],
      ),
    );
  }
}
