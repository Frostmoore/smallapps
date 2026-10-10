import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../data/database.dart' show Negozio;
import '../../l10n/generated/app_localizations.dart';
import '../common/una_mano.dart';

/// I negozi (develop_microapps.md F12.1.12, `/impostazioni/negozi`): rinomina, elimina.
///
/// ⚑ Eliminare un negozio non elimina le sue spese: restano «Senza negozio» (`ON DELETE SET
/// NULL`, F12.1.10). Il dialogo lo dice, perche' «elimina» fa pensare al peggio.
/// ⚑ Niente «aggiungi»: un negozio nasce quando lo si sceglie chiudendo una spesa.
class NegoziPage extends ConsumerWidget {
  const NegoziPage({super.key});

  Future<void> _rinomina(BuildContext context, WidgetRef ref, Negozio n) async {
    final l = L.of(context);
    final c = TextEditingController(text: n.nome);
    final nuovo = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.negozi_rinomina),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLength: 60,
          decoration: InputDecoration(labelText: l.negozio_nome),
          onSubmitted: (v) => Navigator.of(d).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(d).pop(), child: Text(l.common_cancel)),
          TextButton(onPressed: () => Navigator.of(d).pop(c.text), child: Text(l.common_save)),
        ],
      ),
    );
    c.dispose();
    if (nuovo == null || nuovo.trim().isEmpty) return;
    try {
      await ref.read(spesaRepositoryProvider).rinominaNegozio(n.id, nuovo);
    } on Object {
      // ☠ Il nome e' UNIQUE COLLATE NOCASE: un doppione non si salva.
      if (context.mounted) MicroSnack.error(context, l.negozi_doppione);
    }
  }

  Future<void> _elimina(BuildContext context, WidgetRef ref, Negozio n) async {
    final l = L.of(context);
    final ok = await MicroConfirmSheet.show(
      context,
      title: l.negozi_eliminaTitolo(n.nome),
      message: l.negozi_eliminaTesto,
      confirmLabel: l.common_delete,
      cancelLabel: l.common_cancel,
      destructive: true,
    );
    if (ok) await ref.read(spesaRepositoryProvider).eliminaNegozio(n.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final negozi = ref.watch(negoziProvider).value ?? const <Negozio>[];
    return PaginaUnaMano(
      titolo: l.negozi_titolo,
      corpo: negozi.isEmpty
          ? MicroEmptyState(icon: Icons.storefront_outlined, title: l.negozi_vuotoTitolo, message: l.negozi_vuotoTesto)
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final n in negozi)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(n.nome),
                    onTap: () => unawaited(_rinomina(context, ref, n)),
                    trailing: IconButton(
                      tooltip: l.common_delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => unawaited(_elimina(context, ref, n)),
                    ),
                  ),
              ],
            ),
    );
  }
}
