import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/sr_palette.dart';
import '../../domain/confronto.dart';
import '../../domain/riga_spesa.dart';
import '../../domain/spesa.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/lettura_service.dart';
import '../common/una_mano.dart';

/// «Scontrino contro conto» (develop_microapps.md F12.1.12, seconda schermata della tavola; Pro,
/// `ProGate(documentScan)` sulla rotta).
///
/// 1. Testata; 2. due card «Scontrino 45,35» e «Contato 43,70»; 3. la differenza: verde «Tutto
/// torna» (✔ come **icona**, mai nel testo) o ambra «Differenza da guardare» «+1,65»; 4. le righe
/// sospette col delta, e ripiegate «Righe che tornano (N)»; 5. gli avvisi (totale che non quadra,
/// foto unite senza giunzione); 6. **Chiudi la spesa** e «Rifotografa lo scontrino».
///
/// ⚑ All'apertura le righe dello scontrino si **salvano** nella spesa in corso (insieme
/// 'scontrino', affiancate alle contate: F12.1.10): alla chiusura si sceglie quale insieme fa fede,
/// e nel dettaglio dello storico si vedono entrambi.
class ConfrontoPage extends ConsumerStatefulWidget {
  const ConfrontoPage({required this.letto, super.key});

  final ScontrinoLetto letto;

  @override
  ConsumerState<ConfrontoPage> createState() => _ConfrontoPageState();
}

class _ConfrontoPageState extends ConsumerState<ConfrontoPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_salva());
  }

  Future<void> _salva() async {
    final repo = ref.read(spesaRepositoryProvider);
    final id = ref.read(spesaInCorsoProvider).value?.id ??
        await repo.assicuraInCorso(budgetPredefinito: ref.read(budgetPredefinitoProvider));
    await repo.salvaScontrino(id, widget.letto.lettura);
  }

  void _dettaglio(RigaSospetta s) {
    final l = L.of(context);
    final (contata, scontrino) = switch (s) {
      PrezzoDiverso(:final contata, :final scontrino) => (contata, scontrino),
      SoloSulloScontrino(:final scontrino) => (null, scontrino),
      NonSulloScontrino(:final contata) => (contata, null),
      ForseDoppia(:final contata, :final scontrino) => (contata, scontrino),
    };
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(_nome(l, s)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.confronto_rigaContata(contata == null ? '—' : '${nomeRiga(l, contata)} · ${importo(contata.totale)}')),
              const SizedBox(height: 8),
              Text(l.confronto_rigaScontrino(
                  scontrino == null ? '—' : '${scontrino.descrizione} · ${importo(scontrino.importo)}')),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l.common_ok))],
        ),
      ),
    );
  }

  static String _nome(L l, RigaSospetta s) => switch (s) {
    PrezzoDiverso(:final contata) => nomeRiga(l, contata),
    SoloSulloScontrino(:final scontrino) => scontrino.descrizione,
    NonSulloScontrino(:final contata) => nomeRiga(l, contata),
    ForseDoppia(:final scontrino) => scontrino.descrizione,
  };

  static String _nota(L l, RigaSospetta s) => switch (s) {
    PrezzoDiverso(:final contata, :final scontrino) =>
      l.confronto_notaPrezzo(importo(contata.totale), importo(scontrino.importo)),
    SoloSulloScontrino() => l.confronto_notaSoloScontrino,
    NonSulloScontrino() => l.confronto_notaNonScontrino,
    ForseDoppia() => l.confronto_notaDoppia,
  };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final lettura = widget.letto.lettura;
    final spesa = ref.watch(spesaInCorsoProvider).value;
    final contate = spesa?.righe ?? const <RigaSpesa>[];
    final esito = Confronto.confronta(contate, lettura);
    final torna = esito.tuttoTorna;
    return PaginaUnaMano(
      titolo: l.confronto_titolo,
      fondo: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            key: const ValueKey('confronto_chiudi'),
            onPressed: () => unawaited(
              context.push(
                Routes.chiudi,
                extra: ChiusuraArgs(fonte: lettura.quadra ? FonteRighe.scontrino : FonteRighe.contate, lettura: lettura),
              ),
            ),
            child: Text(l.chiusura_titolo),
          ),
          const SizedBox(height: 8),
          BottoneSecondario(
            etichetta: l.confronto_rifotografa,
            icona: Icons.photo_camera_outlined,
            onPressed: () => context.pushReplacement(Routes.scontrino),
          ),
        ],
      ),
      corpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          Row(
            children: [
              Expanded(child: CardNumero(etichetta: l.confronto_scontrino, valore: importo(esito.totaleScontrino))),
              const SizedBox(width: 10),
              Expanded(child: CardNumero(etichetta: l.confronto_contato, valore: importo(esito.totaleContato))),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            key: ValueKey(torna ? 'confronto_torna' : 'confronto_differenza'),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: torna ? p.accento.withValues(alpha: 0.14) : p.ambraFondo,
              border: Border.all(color: torna ? p.accento : p.ambraBordo),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(torna ? Icons.check_circle : Icons.error_outline, color: torna ? p.accento : p.ambraValore),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    torna ? l.confronto_tuttoTorna : l.confronto_daGuardare,
                    style: TextStyle(
                      color: torna ? p.testo : p.ambraTesto,
                      fontWeight: FontWeight.w700,
                      fontVariations: const [FontVariation('wght', 700)],
                    ),
                  ),
                ),
                if (!torna)
                  Text(
                    importoConSegno(esito.differenza),
                    key: const ValueKey('confronto_delta'),
                    style: p.numeri(size: 26, color: p.ambraValore),
                  ),
              ],
            ),
          ),
          if (!lettura.quadra) ...[
            const SizedBox(height: 10),
            AvvisoAmbra(testo: l.confronto_nonQuadra(lettura.righeIgnorate)),
          ],
          if (widget.letto.giunzioniMancanti > 0) ...[
            const SizedBox(height: 10),
            AvvisoAmbra(testo: l.confronto_giunzione(widget.letto.parti), icona: Icons.call_split),
          ],
          if (esito.sospette.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l.confronto_sospette, style: stileEtichetta(p)),
            for (final (i, s) in esito.sospette.indexed)
              InkWell(
                key: ValueKey('confronto_sospetta_$i'),
                onTap: () => _dettaglio(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nome(l, s),
                              style: TextStyle(
                                color: p.testo,
                                fontWeight: FontWeight.w700,
                                fontVariations: const [FontVariation('wght', 700)],
                              ),
                            ),
                            Text(_nota(l, s), style: TextStyle(fontSize: 12, color: p.testoSecondario)),
                          ],
                        ),
                      ),
                      Text(importoConSegno(s.delta), style: p.numeri(size: 17, color: p.ambraValore)),
                    ],
                  ),
                ),
              ),
          ],
          if (esito.abbinate.isNotEmpty)
            ExpansionTile(
              key: const ValueKey('confronto_tornano'),
              tilePadding: EdgeInsets.zero,
              title: Text(l.confronto_tornano(esito.abbinate.length), style: stileEtichetta(p)),
              children: [
                for (final a in esito.abbinate)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(nomeRiga(l, a.contata)),
                    subtitle: Text(a.scontrino.descrizione),
                    trailing: Text(importo(a.scontrino.importo), style: p.numeri(size: 15)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
