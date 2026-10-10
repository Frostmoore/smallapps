import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/sr_palette.dart';
import '../../domain/spesa.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/scelte.dart';
import '../common/una_mano.dart';

/// Chiudere e salvare la spesa (develop_microapps.md F12.1.12, `/chiudi`).
///
/// Totale grande; esito del budget («Dentro il budget di 3,20» / «Sforato di 4,10»); **Negozio**
/// (chip dei 5 piu' recenti + «Altro…»); **Data** (oggi, o quella dello scontrino); con uno
/// scontrino letto la scelta **«Salva le righe dello scontrino»** (default se quadra) /
/// **«Salva le righe contate»**; **Salva** → storico. Spesa senza righe: «Non c'e' niente da
/// salvare» e **Butta via**.
///
/// ⚑ Il totale scritto alla chiusura non cambiera' piu' (F12.1.10): e' quello di questa pagina, con
/// la fonte scelta qui.
/// ⚑ Dopo il salvataggio, nel gratis e con piu' di 5 spese chiuse, lo snack lo dice subito («le
/// altre restano sul telefono»): nessuna sorpresa aprendo lo storico.
class ChiusuraPage extends ConsumerStatefulWidget {
  const ChiusuraPage({this.args = const ChiusuraArgs(), super.key});

  final ChiusuraArgs args;

  @override
  ConsumerState<ChiusuraPage> createState() => _ChiusuraPageState();
}

class _ChiusuraPageState extends ConsumerState<ChiusuraPage> {
  late FonteRighe _fonte = widget.args.fonte;
  late String? _negozio = widget.args.lettura?.negozioMostrato;
  late CivilDate _data = widget.args.lettura?.data ?? CivilDate.fromDateTime(ref.read(oraProvider)());
  bool _salvo = false;

  Future<void> _salva() async {
    if (_salvo) return;
    setState(() => _salvo = true);
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(spesaRepositoryProvider);
      final nome = _negozio?.trim();
      final negozioId = (nome == null || nome.isEmpty) ? null : await repo.negozioPerNome(nome);
      await repo.chiudi(data: _data, negozioId: negozioId, fonte: _fonte);
      ref.read(tastierinoProvider.notifier).svuota();
      final gate = ref.read(featureGateProvider);
      final limite = gate.freeLimitOf(FeatureKey.fullHistory);
      final chiuse = await repo.contaChiuse();
      final nascoste = !gate.isPro && limite != null && chiuse > limite;
      if (!mounted) return;
      context.go(Routes.storico);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(nascoste ? l.chiusura_salvataGratis : l.chiusura_salvata)));
    } finally {
      if (mounted) setState(() => _salvo = false);
    }
  }

  Future<void> _buttaVia() async {
    await ref.read(spesaRepositoryProvider).scartaInCorso();
    ref.read(tastierinoProvider.notifier).svuota();
    if (mounted) context.go(Routes.spesa);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = SrPalette.of(context);
    final spesa = ref.watch(spesaInCorsoProvider).value;
    final lettura = widget.args.lettura;
    final vuota = spesa == null || (spesa.righe.isEmpty && spesa.righeScontrino.isEmpty && lettura == null);
    if (vuota) {
      return PaginaUnaMano(
        titolo: l.chiusura_titolo,
        corpo: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(l.chiusura_niente, key: const ValueKey('chiusura_niente'), textAlign: TextAlign.center),
          ),
        ),
        fondo: spesa == null
            ? null
            : BottoneSecondario(etichetta: l.chiusura_buttaVia, onPressed: () => unawaited(_buttaVia())),
      );
    }
    // Il totale con la fonte scelta: la stessa regola di SpesaRepository.chiudi.
    final conFonte = Spesa(
      stato: StatoSpesa.inCorso,
      iniziataIl: spesa.iniziataIl,
      budget: spesa.budget,
      righe: spesa.righe,
      righeScontrino: spesa.righeScontrino,
      totaleScontrino: spesa.totaleScontrino ?? lettura?.totale,
      fonte: _fonte,
    );
    final residuo = conFonte.residuoBudget;
    return PaginaUnaMano(
      titolo: l.chiusura_titolo,
      fondo: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            key: const ValueKey('chiusura_salva'),
            onPressed: _salvo ? null : () => unawaited(_salva()),
            child: Text(l.common_save),
          ),
          const SizedBox(height: 4),
          TextButton(
            key: const ValueKey('chiusura_buttaVia'),
            style: TextButton.styleFrom(foregroundColor: p.rosso),
            onPressed: _salvo
                ? null
                : () async {
                    final ok = await MicroConfirmSheet.show(
                      context,
                      title: l.chiusura_buttaViaTitolo,
                      message: l.chiusura_buttaViaTesto,
                      confirmLabel: l.chiusura_buttaVia,
                      cancelLabel: l.common_cancel,
                      destructive: true,
                    );
                    if (ok) await _buttaVia();
                  },
            child: Text(l.chiusura_buttaVia),
          ),
        ],
      ),
      corpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(importo(conFonte.totale), key: const ValueKey('chiusura_totale'), style: p.numeri(size: 56)),
              const SizedBox(width: 6),
              Text('€', style: p.numeri(size: 26, color: p.testoSecondario)),
            ],
          ),
          if (residuo != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                residuo.isNegative
                    ? l.chiusura_sforato(importo(Money.zero - residuo))
                    : l.chiusura_dentro(importo(residuo)),
                key: const ValueKey('chiusura_budget'),
                style: stileEtichetta(p, colore: p.coloreBudget(conFonte.livelloBudget)),
              ),
            ),
          if (lettura != null) ...[
            Sezione(l.chiusura_quali),
            RadioGroup<FonteRighe>(
              groupValue: _fonte,
              onChanged: (v) => setState(() => _fonte = v ?? _fonte),
              child: Column(
                children: [
                  RadioListTile<FonteRighe>(
                    key: const ValueKey('chiusura_fonteScontrino'),
                    contentPadding: EdgeInsets.zero,
                    value: FonteRighe.scontrino,
                    title: Text(l.chiusura_righeScontrino),
                    subtitle: Text(importo(lettura.totale ?? lettura.sommaRighe)),
                  ),
                  RadioListTile<FonteRighe>(
                    key: const ValueKey('chiusura_fonteContate'),
                    contentPadding: EdgeInsets.zero,
                    value: FonteRighe.contate,
                    title: Text(l.chiusura_righeContate),
                    subtitle: Text(importo(spesa.totaleContato)),
                  ),
                ],
              ),
            ),
          ],
          Sezione(l.chiusura_negozio),
          SceltaNegozio(valore: _negozio, onCambia: (v) => setState(() => _negozio = v)),
          Sezione(l.chiusura_data),
          SceltaData(data: _data, onCambia: (d) => setState(() => _data = d)),
        ],
      ),
    );
  }
}
