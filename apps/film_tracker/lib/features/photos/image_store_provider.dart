import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../data/database.dart';

/// L'archivio delle immagini dei rullini (F6.9), condiviso da foto, home e QR.
///
/// ⚑ Un provider e non `ImageStore(paths: ...)` sparso nelle pagine: i test sostituiscono
/// `appPathsProvider` con una cartella temporanea e tutto il resto segue da solo.
final imageStoreProvider = Provider<ImageStore>(
  (ref) => ImageStore(paths: ref.watch(appPathsProvider)),
);

/// La cartella delle foto dei rullini dentro `images/` (e `images/thumbs/`).
///
/// ⚑ Una sola cartella per tutti i rullini e non una per rullino: i nomi sono UUID, quindi non
/// si scontrano, e la cancellazione di un rullino passa comunque dai percorsi che restituisce
/// `FilmRepository.deleteRollAndCollectImagePaths`, non dalla cartella.
const String rollImageBucket = 'rolls';

/// Il file di un percorso **relativo** salvato nel database (`RollImage.path` o
/// `RollImage.thumbPath`, `StoredImage.path`).
///
/// Per la home: `rollImageFile(ref.watch(appPathsProvider), item.cover!.thumbPath)`.
File rollImageFile(AppPaths paths, String relativePath) => paths.resolve(relativePath);

/// La miniatura di un'immagine del rullino, ritagliata a riempire lo spazio che riceve.
///
/// Senza immagine ([image] null) o con il file sparito (un ripristino senza foto, una
/// cancellazione a meta') mostra [placeholder], o un riquadro neutro con un'icona: un'immagine
/// rotta non deve mai diventare un errore rosso nella griglia o nella home.
///
/// [full] usa l'immagine grande invece della miniatura (copertine grandi, oltre i 400 px).
class RollImageThumb extends ConsumerWidget {
  const RollImageThumb({
    required this.image,
    this.full = false,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.cacheWidth,
    super.key,
  });

  final RollImage? image;
  final bool full;
  final BoxFit fit;
  final Widget? placeholder;

  /// Larghezza di decodifica in pixel fisici; null la ricava dallo spazio disponibile.
  final int? cacheWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final img = image;
    if (img == null) return placeholder ?? const _ThumbPlaceholder();
    final file = rollImageFile(ref.watch(appPathsProvider), full ? img.path : img.thumbPath);
    return LayoutBuilder(
      builder: (context, constraints) {
        // ⚑ Decodificare alla dimensione mostrata: una griglia di miniature da 400 px piene in
        // memoria e' poco, ma la stessa griglia con le immagini da 1600 px non lo e'.
        final width = constraints.hasBoundedWidth
            ? (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context)).round()
            : null;
        return Image.file(
          file,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: cacheWidth ?? width,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => placeholder ?? const _ThumbPlaceholder(broken: true),
        );
      },
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder({this.broken = false});

  final bool broken;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          broken ? Icons.broken_image_outlined : Icons.photo_outlined,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
