import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../app/qr_palette.dart';
import '../../app/routes.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/neon.dart';
import '../common/qr_actions.dart';

/// La cronologia completa (develop_microapps.md F17.1.6): gli ultimi 5 gratis, tutta col Pro
/// (`fullHistory`).
///
/// ⚑ Nel piano gratuito non c'e' niente di "nascosto" da mostrare qui: le righe oltre le 5 sono
/// state **cancellate** (F17.1.4). La riga in fondo lo dice, e il Pro vale «da adesso in poi».
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final l = L.of(context);
    final ok = await MicroConfirmSheet.show(
      context,
      title: l.history_clearTitle,
      message: l.history_clearBody,
      confirmLabel: l.history_clear,
      cancelLabel: l.common_cancel,
      destructive: true,
    );
    if (ok) await ref.read(repositoryProvider).clearHistory();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = QrPalette.of(context);
    final history = ref.watch(historyProvider);
    final pro = ref.watch(isProProvider);
    final enabled = ref.watch(historyEnabledProvider);
    final list = history.value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.history_title),
        actions: [
          if (list.isNotEmpty)
            IconButton(
              tooltip: l.history_clear,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => unawaited(_clear(context, ref)),
            ),
        ],
      ),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          if (!enabled)
            Container(
              margin: const EdgeInsets.only(bottom: MicroSpacing.m),
              padding: const EdgeInsets.all(MicroSpacing.m),
              decoration: p.card(radius: 16),
              child: Row(
                children: [
                  Icon(Icons.history_toggle_off, color: p.inkMuted),
                  MicroSpacing.hGapM,
                  Expanded(
                    child: Text(l.history_off, style: TextStyle(color: p.inkMuted)),
                  ),
                  TextButton(
                    onPressed: () => unawaited(context.push(Routes.settings)),
                    child: Text(l.settings_title),
                  ),
                ],
              ),
            ),
          if (list.isEmpty && history.hasValue)
            MicroEmptyState(
              icon: Icons.history,
              title: l.history_emptyTitle,
              message: l.history_emptyBody,
            ),
          for (final h in list)
            QrRow(
              code: h,
              meta: rowMeta(l, h),
              onTap: () => unawaited(context.push(Routes.qrOf(h.id))),
              trailing: IconButton(
                tooltip: l.common_delete,
                icon: Icon(Icons.close, color: p.inkMuted, size: 20),
                onPressed: () => unawaited(ref.read(repositoryProvider).delete(h.id)),
              ),
            ),
          if (!pro && list.isNotEmpty)
            TextButton(
              onPressed: () => openPro(context, ref, FeatureKey.fullHistory),
              child: Text(l.history_freeNote, textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}
