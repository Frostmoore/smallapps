import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/labels.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../domain/film_types.dart';
import '../../l10n/generated/app_localizations.dart';

/// Le macchine fotografiche (F6.5): produttore, modello, formato e quanti rullini ha
/// scattato ognuna. Un tocco apre la modifica, dove sta anche l'eliminazione.
///
/// ⚑ **Un inventario, non una collezione**: niente foto della macchina, numero di serie,
/// anno o valore (F6.5, la spec lo dice esplicitamente). La macchina serve a sapere con cosa
/// si e' scattato un rullino.
class CamerasPage extends ConsumerWidget {
  const CamerasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final cameras = ref.watch(camerasProvider);
    final counts = ref.watch(rollCountByCameraProvider).value ?? const <int, int>{};
    final gate = ref.watch(featureGateProvider);
    final n = cameras.value?.length ?? 0;
    // Il distintivo Pro sul pulsante dice prima del tocco che la prossima macchina e' Pro.
    final full = !gate.withinLimit(FeatureKey.secondaryEntities, n);

    return Scaffold(
      appBar: AppBar(title: Text(l.camera_title)),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('camera_add'),
        onPressed: () => unawaited(openNewCamera(context, ref)),
        icon: const Icon(Icons.add),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.camera_add),
            if (full) ...[MicroSpacing.hGapS, const ProBadge()],
          ],
        ),
      ),
      body: cameras.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? MicroEmptyState(
                icon: Icons.photo_camera_outlined,
                title: l.camera_emptyTitle,
                message: l.camera_emptyBody,
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(0, MicroSpacing.s, 0, 96),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, i) => _CameraTile(camera: list[i], rolls: counts[list[i].id] ?? 0),
              ),
      ),
    );
  }
}

/// Apre la creazione di una macchina, passando dal paywall se il piano gratuito e' pieno
/// (una macchina gratis, `FeatureKey.secondaryEntities`). Restituisce l'id della macchina
/// creata, o null.
///
/// ⚑ Il conteggio si chiede **al repository** (`cameraCount()`), non al provider: chiamata
/// da una pagina che non ascolta il conteggio (il form del rullino), `.value` sarebbe null,
/// cioe' zero, cioe' la seconda macchina gratis. ☠ E `ref.read(cameraCountProvider.future)`
/// non arriva mai: Riverpod 3 mette in pausa i provider che nessuno ascolta, e lo stream
/// resta fermo in caricamento (visto in un test il 2026-10-08).
///
/// La pagina di creazione e' protetta anche da sola (`NewCameraGate`): questa e' la porta
/// gentile, quella la serratura.
Future<int?> openNewCamera(BuildContext context, WidgetRef ref) async {
  final count = await ref.read(repositoryProvider).cameraCount();
  if (!context.mounted) return null;
  if (!ref.read(featureGateProvider).withinLimit(FeatureKey.secondaryEntities, count)) {
    final unlocked = await showFilmPaywall(context, ref, highlight: FeatureKey.secondaryEntities);
    if (!unlocked || !context.mounted) return null;
  }
  if (!context.mounted) return null;
  return context.push<int>(Routes.cameraNew);
}

class _CameraTile extends StatelessWidget {
  const _CameraTile({required this.camera, required this.rolls});

  final Camera camera;
  final int rolls;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final format = FilmFormat.byKey(camera.format);
    final note = camera.note;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        foregroundColor: scheme.onSecondaryContainer,
        child: const Icon(Icons.photo_camera_outlined),
      ),
      title: Text(camera.displayName),
      subtitle: Text(
        [if (format != null) formatName(l, format), if (!camera.active) l.camera_inactive, ?note].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(l.camera_rollCount(rolls), style: Theme.of(context).textTheme.labelLarge),
      onTap: () => unawaited(context.push(Routes.cameraEditOf(camera.id))),
    );
  }
}
