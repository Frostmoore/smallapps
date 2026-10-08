import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../l10n/generated/app_localizations.dart';
import 'image_store_provider.dart';
import 'photo_actions.dart';
import 'photo_logic.dart';

/// Le foto di un rullino nel suo dettaglio (F6.9, **gratis**: F6.0 punto 3).
///
/// Griglia delle miniature con la copertina segnata; "Aggiungi" (fotocamera o galleria, piu'
/// foto insieme); "Riordina" con il trascinamento; tocco = visualizzatore a schermo intero;
/// pressione lunga = copertina, apri, elimina (con conferma).
///
/// ⚑ Contratto con il dettaglio del rullino (`lib/features/rolls/`): nome e firma
/// `RollPhotosSection({required int rollId})` non cambiano. La sezione non scorre da sola
/// (griglia `shrinkWrap`): vive dentro la lista del dettaglio, che scorre per tutti.
class RollPhotosSection extends ConsumerWidget {
  const RollPhotosSection({required this.rollId, super.key});

  final int rollId;

  /// Colonne della griglia: tre miniature su un telefono, di piu' su un iPad.
  static int columnsFor(double width) => (width / 130).floor().clamp(3, 6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final images = ref.watch(rollImagesProvider(rollId)).value;
    final coverId = ref.watch(rollProvider(rollId)).value?.coverImageId;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(l.photo_sectionTitle, style: theme.textTheme.titleMedium)),
            if (images != null && images.length >= 2)
              TextButton(
                onPressed: () => unawaited(_reorder(context, ref, images)),
                child: Text(l.photo_reorder),
              ),
            TextButton.icon(
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(l.photo_add),
              onPressed: () => unawaited(addRollPhotos(context, ref, rollId)),
            ),
          ],
        ),
        MicroSpacing.gapS,
        if (images == null)
          const SizedBox(height: 96, child: Center(child: CircularProgressIndicator()))
        else if (images.isEmpty)
          _EmptyPhotos(onAdd: () => unawaited(addRollPhotos(context, ref, rollId)))
        else
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnsFor(constraints.maxWidth),
                mainAxisSpacing: MicroSpacing.xs + 2,
                crossAxisSpacing: MicroSpacing.xs + 2,
              ),
              itemCount: images.length,
              itemBuilder: (context, i) => _PhotoTile(
                image: images[i],
                index: i,
                isCover: images[i].id == coverId,
                onTap: () => context.push(Routes.photoOf(rollId, images[i].id)),
                onLongPress: () => unawaited(_actions(context, ref, images, images[i], coverId)),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _actions(
    BuildContext context,
    WidgetRef ref,
    List<RollImage> images,
    RollImage image,
    int? coverId,
  ) async {
    final l = L.of(context);
    final choice = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_full),
              title: Text(l.photo_open),
              onTap: () => Navigator.of(sheet).pop(_PhotoAction.open),
            ),
            if (image.id != coverId)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: Text(l.photo_setCover),
                onTap: () => Navigator.of(sheet).pop(_PhotoAction.cover),
              ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(sheet).colorScheme.error),
              title: Text(l.photo_delete),
              onTap: () => Navigator.of(sheet).pop(_PhotoAction.delete),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case _PhotoAction.open:
        unawaited(context.push(Routes.photoOf(rollId, image.id)));
      case _PhotoAction.cover:
        await setRollCover(context, ref, rollId: rollId, imageId: image.id);
      case _PhotoAction.delete:
        await confirmAndDeleteRollPhoto(
          context,
          ref,
          rollId: rollId,
          image: image,
          images: images,
          coverId: coverId,
        );
    }
  }

  Future<void> _reorder(BuildContext context, WidgetRef ref, List<RollImage> images) async {
    final ids = await showModalBottomSheet<List<int>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _ReorderSheet(images: images),
    );
    if (ids == null) return;
    final before = [for (final i in images) i.id];
    if (_sameOrder(before, ids)) return;
    await ref.read(repositoryProvider).reorderImages(ids);
  }

  static bool _sameOrder(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

enum _PhotoAction { open, cover, delete }

/// Il riquadro vuoto: dice che cosa si puo' mettere e invita ad aggiungere.
class _EmptyPhotos extends StatelessWidget {
  const _EmptyPhotos({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: MicroRadius.card,
      child: InkWell(
        borderRadius: MicroRadius.card,
        onTap: onAdd,
        child: Padding(
          padding: MicroSpacing.card,
          child: Row(
            children: [
              Icon(Icons.photo_library_outlined, size: 36, color: scheme.primary),
              MicroSpacing.hGapL,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.photo_emptyTitle, style: theme.textTheme.titleSmall),
                    MicroSpacing.gapXS,
                    Text(
                      l.photo_emptyBody,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una miniatura della griglia, con il segno della copertina.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.image,
    required this.index,
    required this.isCover,
    required this.onTap,
    required this.onLongPress,
  });

  final RollImage image;
  final int index;
  final bool isCover;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: isCover ? '${l.photo_thumbLabel(index + 1)}, ${l.photo_cover}' : l.photo_thumbLabel(index + 1),
      child: ClipRRect(
        borderRadius: MicroRadius.chip,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ⚑ Hero con l'id dell'immagine: il visualizzatore usa lo stesso tag, e la miniatura
            // "si apre" invece di sparire (F6.14).
            Hero(tag: rollImageHeroTag(image.id), child: RollImageThumb(image: image)),
            if (isCover)
              Positioned(
                left: MicroSpacing.xs,
                top: MicroSpacing.xs,
                child: Container(
                  padding: const EdgeInsets.all(MicroSpacing.xxs + 1),
                  decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                  child: Icon(Icons.star, size: 14, color: scheme.onPrimary),
                ),
              ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: onTap, onLongPress: onLongPress),
            ),
          ],
        ),
      ),
    );
  }
}

/// Il tag `Hero` di un'immagine, condiviso con il visualizzatore.
String rollImageHeroTag(int imageId) => 'roll-image-$imageId';

/// Il foglio "Riordina": la lista delle foto da trascinare. "Fatto" restituisce il nuovo
/// ordine degli id; chiuderlo in altro modo non cambia niente.
///
/// ⚑ Una lista e non la griglia: Flutter riordina con il trascinamento solo le liste
/// (`ReorderableListView`), e un pacchetto per riordinare una griglia sarebbe una dipendenza
/// per un gesto che si fa di rado.
class _ReorderSheet extends StatefulWidget {
  const _ReorderSheet({required this.images});

  final List<RollImage> images;

  @override
  State<_ReorderSheet> createState() => _ReorderSheetState();
}

class _ReorderSheetState extends State<_ReorderSheet> {
  late List<int> _ids = [for (final i in widget.images) i.id];
  late final Map<int, RollImage> _byId = {for (final i in widget.images) i.id: i};

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: MicroSpacing.pageH,
              child: Row(
                children: [
                  Expanded(child: Text(l.photo_reorderHint, style: theme.textTheme.bodyMedium)),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_ids),
                    child: Text(l.photo_done),
                  ),
                ],
              ),
            ),
            MicroSpacing.gapS,
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                itemCount: _ids.length,
                onReorderItem: (oldIndex, newIndex) =>
                    setState(() => _ids = reorderIds(_ids, oldIndex, newIndex)),
                itemBuilder: (context, i) {
                  final id = _ids[i];
                  return ListTile(
                    key: ValueKey(id),
                    leading: ClipRRect(
                      borderRadius: MicroRadius.chip,
                      child: SizedBox.square(dimension: 56, child: RollImageThumb(image: _byId[id])),
                    ),
                    title: Text(l.photo_thumbLabel(i + 1)),
                    subtitle: Text(rollImageKindLabel(l, _byId[id]!.kindEnum)),
                    trailing: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
