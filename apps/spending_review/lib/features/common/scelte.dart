import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/sr_palette.dart';
import '../../data/database.dart' show Negozio;
import '../../domain/spesa.dart';
import '../../l10n/generated/app_localizations.dart';
import 'una_mano.dart';

/// Il negozio di una spesa: i chip dei 5 piu' recenti e «Altro…» (develop_microapps.md F12.1.12,
/// `ChiusuraPage`). Si sceglie un **nome**: chi salva lo trasforma in id con
/// `SpesaRepository.negozioPerNome` (trova senza distinguere le maiuscole, o crea).
///
/// ⚑ Un nome e non un id: il negozio dello scontrino («ESSELUNGA S.P.A.» ripulito) non esiste
/// ancora nella tabella, e crearlo prima che l'utente salvi lascerebbe negozi orfani a ogni
/// «indietro».
class SceltaNegozio extends ConsumerWidget {
  const SceltaNegozio({required this.valore, required this.onCambia, super.key});

  final String? valore;
  final ValueChanged<String?> onCambia;

  /// Quanti negozi recenti come chip.
  static const int recenti = 5;

  /// I nomi dei negozi in ordine di uso recente (dalle spese chiuse visibili), poi gli altri.
  static List<String> ordinati(List<Negozio> negozi, List<int?> idRecenti) {
    final perId = {for (final n in negozi) n.id: n.nome};
    final nomi = <String>[];
    for (final id in idRecenti) {
      final n = perId[id];
      if (n != null && !nomi.contains(n)) nomi.add(n);
    }
    for (final n in negozi) {
      if (!nomi.contains(n.nome)) nomi.add(n.nome);
    }
    return nomi;
  }

  Future<void> _altro(BuildContext context, List<String> tutti) async {
    final l = L.of(context);
    final scelto = await showDialog<String>(
      context: context,
      builder: (ctx) => _DialogoNegozio(tutti: tutti, iniziale: valore ?? ''),
    );
    if (scelto == null) return;
    final pulito = scelto.trim();
    onCambia(pulito.isEmpty ? null : pulito);
    if (pulito.isEmpty && context.mounted) MicroSnack.show(context, l.negozio_nessuno);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final negozi = ref.watch(negoziProvider).value ?? const <Negozio>[];
    final recentiId = [for (final s in ref.watch(speseChiuseProvider).value ?? const <Spesa>[]) s.negozioId];
    final tutti = ordinati(negozi, recentiId);
    final chip = tutti.take(recenti).toList();
    final v = valore;
    final vInChip = v != null && chip.any((c) => c.toLowerCase() == v.toLowerCase());
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (v != null && !vInChip)
          ChoiceChip(label: Text(v), selected: true, onSelected: (_) => onCambia(null)),
        for (final c in chip)
          ChoiceChip(
            label: Text(c),
            selected: v != null && c.toLowerCase() == v.toLowerCase(),
            onSelected: (sel) => onCambia(sel ? c : null),
          ),
        ActionChip(
          key: const ValueKey('negozio_altro'),
          avatar: const Icon(Icons.edit_outlined, size: 18),
          label: Text(l.negozio_altro),
          onPressed: () => unawaited(_altro(context, tutti)),
        ),
      ],
    );
  }
}

class _DialogoNegozio extends StatefulWidget {
  const _DialogoNegozio({required this.tutti, required this.iniziale});

  final List<String> tutti;
  final String iniziale;

  @override
  State<_DialogoNegozio> createState() => _DialogoNegozioState();
}

class _DialogoNegozioState extends State<_DialogoNegozio> {
  late final TextEditingController _c = TextEditingController(text: widget.iniziale);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final testo = _c.text.trim().toLowerCase();
    final suggeriti = testo.isEmpty
        ? widget.tutti.take(8).toList()
        : widget.tutti.where((n) => n.toLowerCase().contains(testo)).take(8).toList();
    return AlertDialog(
      title: Text(l.negozio_titolo),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('negozio_campo'),
              controller: _c,
              autofocus: true,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.negozio_nome, counterText: ''),
              onChanged: (_) => setState(() {}),
              onSubmitted: (v) => Navigator.of(context).pop(v),
            ),
            for (final s in suggeriti)
              ListTile(dense: true, title: Text(s), onTap: () => Navigator.of(context).pop(s)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.common_cancel)),
        TextButton(onPressed: () => Navigator.of(context).pop(_c.text), child: Text(l.common_ok)),
      ],
    );
  }
}

/// La data di una spesa, con il selettore di sistema. ⚑ `CivilDate`: un giorno, non un istante
/// (ADR-008): la spesa del 3 resta del 3 in qualunque fuso.
class SceltaData extends StatelessWidget {
  const SceltaData({required this.data, required this.onCambia, super.key});

  final CivilDate data;
  final ValueChanged<CivilDate> onCambia;

  @override
  Widget build(BuildContext context) {
    final p = SrPalette.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return OutlinedButton.icon(
      key: const ValueKey('scelta_data'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48), alignment: Alignment.centerLeft),
      onPressed: () async {
        final oggi = DateTime.now();
        final scelta = await showDatePicker(
          context: context,
          initialDate: data.toLocalMidnight(),
          firstDate: DateTime(2020),
          lastDate: DateTime(oggi.year + 1, 12, 31),
        );
        if (scelta != null) onCambia(CivilDate.fromDateTime(scelta));
      },
      icon: Icon(Icons.event_outlined, color: p.testoSecondario),
      label: Text(DateFormat.yMMMMEEEEd(locale).format(data.toLocalMidnight())),
    );
  }
}

/// Un'etichetta di sezione delle pagine secondarie (13, 700, testo secondario), con margini.
class Sezione extends StatelessWidget {
  const Sezione(this.testo, {super.key});

  final String testo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
    child: Semantics(header: true, child: Text(testo, style: stileEtichetta(SrPalette.of(context)))),
  );
}
