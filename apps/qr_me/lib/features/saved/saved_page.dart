import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/neon.dart';
import '../common/qr_actions.dart';

enum _RowAction { rename, unfavorite, delete }

/// I preferiti: i QR salvati con nome (develop_microapps.md F17.1.6). Uno gratis, illimitati col
/// Pro (`unlimitedEntities`): il limite si controlla quando si salva (`saveAsFavorite`), qui si
/// vede solo quanto ne resta.
class SavedPage extends ConsumerWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final favorites = ref.watch(favoritesProvider);
    final gate = ref.watch(featureGateProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.saved_title)),
      body: switch (favorites) {
        AsyncData(value: final list) when list.isEmpty => MicroEmptyState(
          icon: Icons.star_outline,
          title: l.saved_emptyTitle,
          message: l.saved_emptyBody,
        ),
        AsyncData(value: final list) => ListView(
          padding: MicroSpacing.page,
          children: [
            for (final f in list)
              QrRow(
                code: f,
                meta: rowMeta(l, f),
                onTap: () => unawaited(context.push(Routes.qrOf(f.id))),
                trailing: _Menu(code: f),
              ),
            if (!gate.isPro)
              Padding(
                padding: const EdgeInsets.only(top: MicroSpacing.s),
                child: TextButton(
                  onPressed: () => openPro(context, ref, FeatureKey.unlimitedEntities),
                  child: Text(l.saved_freeLimit),
                ),
              ),
          ],
        ),
        AsyncError() => Center(child: Text(l.common_loadFailed)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Menu extends ConsumerWidget {
  const _Menu({required this.code});

  final QrCode code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final repo = ref.read(repositoryProvider);
    return PopupMenuButton<_RowAction>(
      tooltip: l.common_more,
      onSelected: (a) async {
        switch (a) {
          case _RowAction.rename:
            final title = await askTitle(context, title: l.saved_rename, initial: code.title);
            if (title != null) await repo.rename(code.id, title);
          case _RowAction.unfavorite:
            // ⚑ Torna in cronologia (e con il piano gratuito la potatura lo tiene solo se e' fra
            // gli ultimi 5): non e' una cancellazione, e non si chiede conferma.
            await repo.unfavorite(code.id);
            await repo.pruneHistory(keep: historyKeep(ref.read(featureGateProvider)));
          case _RowAction.delete:
            if (!context.mounted) return;
            final ok = await MicroConfirmSheet.show(
              context,
              title: l.saved_deleteTitle,
              message: l.saved_deleteBody(code.title),
              confirmLabel: l.common_delete,
              cancelLabel: l.common_cancel,
              destructive: true,
            );
            if (ok) await repo.delete(code.id);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: _RowAction.rename, child: Text(l.saved_rename)),
        PopupMenuItem(value: _RowAction.unfavorite, child: Text(l.saved_unfavorite)),
        PopupMenuItem(value: _RowAction.delete, child: Text(l.common_delete)),
      ],
    );
  }
}
