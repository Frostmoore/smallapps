import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../data/database.dart';
import '../../l10n/generated/app_localizations.dart';
import 'image_store_provider.dart';
import 'photo_actions.dart';
import 'roll_photos_section.dart' show rollImageHeroTag;

/// Le foto di un rullino a schermo intero (F6.9, `Routes.photo`): zoom con due dita o doppio
/// tocco, scorrimento fra le foto, copertina ed eliminazione.
///
/// ⚑ Fondo nero anche nel tema chiaro: e' il fondo su cui l'occhio legge meglio una fotografia
/// (lo stesso motivo del tema scuro di default, F6.1), e i provini sono spesso negativi chiari.
///
/// ⚑ `InteractiveViewer` di Flutter e non un pacchetto di galleria: zoom e spostamento sono
/// tutto quello che serve, e un pacchetto in piu' e' codice nativo o gesti da mantenere.
class PhotoViewerPage extends ConsumerStatefulWidget {
  const PhotoViewerPage({required this.rollId, required this.imageId, super.key});

  final int rollId;
  final int imageId;

  @override
  ConsumerState<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends ConsumerState<PhotoViewerPage> {
  PageController? _controller;
  int _index = 0;
  bool _zoomed = false;
  bool _chrome = true;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final images = ref.watch(rollImagesProvider(widget.rollId)).value;
    final coverId = ref.watch(rollProvider(widget.rollId)).value?.coverImageId;

    if (images == null) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }
    if (images.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: Center(child: Text(l.photo_missing, style: const TextStyle(color: Colors.white70))),
      );
    }

    // La prima volta si parte dalla foto toccata nella griglia.
    if (_controller == null) {
      final start = images.indexWhere((i) => i.id == widget.imageId);
      _index = start < 0 ? 0 : start;
      _controller = PageController(initialPage: _index);
    }
    // Dopo una cancellazione la lista si accorcia: si resta sull'ultima foto che esiste.
    if (_index > images.length - 1) {
      _index = images.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (_controller?.hasClients ?? false)) _controller!.jumpToPage(_index);
      });
    }
    final current = images[_index];
    final isCover = current.id == coverId;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _chrome
          ? AppBar(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.photo_position(_index + 1, images.length)),
                  Text(
                    isCover
                        ? '${rollImageKindLabel(l, current.kindEnum)} · ${l.photo_cover}'
                        : rollImageKindLabel(l, current.kindEnum),
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
              actions: [
                if (!isCover)
                  IconButton(
                    tooltip: l.photo_setCover,
                    icon: const Icon(Icons.star_outline),
                    onPressed: () =>
                        unawaited(setRollCover(context, ref, rollId: widget.rollId, imageId: current.id)),
                  ),
                IconButton(
                  tooltip: l.photo_delete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => unawaited(_delete(images, current, coverId)),
                ),
              ],
            )
          : null,
      body: PageView.builder(
        controller: _controller,
        // ⚑ Con la foto ingrandita lo scorrimento orizzontale serve a spostarsi dentro la foto:
        // se la pagina potesse scorrere, il trascinamento lo vincerebbe lei (riconosce il gesto
        // prima di InteractiveViewer) e la foto ingrandita non si potrebbe esplorare.
        physics: _zoomed ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
        itemCount: images.length,
        onPageChanged: (i) => setState(() {
          _index = i;
          _zoomed = false;
        }),
        itemBuilder: (context, i) => _ZoomablePhoto(
          key: ValueKey(images[i].id),
          image: images[i],
          onZoomChanged: (zoomed) {
            if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
          },
          onTap: () => setState(() => _chrome = !_chrome),
        ),
      ),
    );
  }

  Future<void> _delete(List<RollImage> images, RollImage image, int? coverId) async {
    final deleted = await confirmAndDeleteRollPhoto(
      context,
      ref,
      rollId: widget.rollId,
      image: image,
      images: images,
      coverId: coverId,
    );
    // Era l'ultima foto: non resta niente da guardare.
    if (deleted && images.length == 1 && mounted) Navigator.of(context).maybePop();
  }
}

/// Una foto con lo zoom: due dita, oppure doppio tocco (2,5x nel punto toccato, poi indietro).
class _ZoomablePhoto extends ConsumerStatefulWidget {
  const _ZoomablePhoto({required this.image, required this.onZoomChanged, required this.onTap, super.key});

  final RollImage image;
  final ValueChanged<bool> onZoomChanged;
  final VoidCallback onTap;

  @override
  ConsumerState<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends ConsumerState<_ZoomablePhoto> {
  final _transform = TransformationController();
  Offset _doubleTapAt = Offset.zero;

  static const double _doubleTapScale = 2.5;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  bool get _isZoomed => _transform.value.getMaxScaleOnAxis() > 1.01;

  void _toggleZoom() {
    if (_isZoomed) {
      _transform.value = Matrix4.identity();
    } else {
      final p = _doubleTapAt;
      // Ingrandisce intorno al punto toccato: trasla in modo che quel punto resti fermo.
      _transform.value = Matrix4.identity()
        ..translateByDouble(-p.dx * (_doubleTapScale - 1), -p.dy * (_doubleTapScale - 1), 0, 1)
        ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1);
    }
    widget.onZoomChanged(_isZoomed);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final file = rollImageFile(ref.watch(appPathsProvider), widget.image.path);
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _transform,
        maxScale: 6,
        onInteractionEnd: (_) => widget.onZoomChanged(_isZoomed),
        child: SizedBox.expand(
          child: Hero(
            tag: rollImageHeroTag(widget.image.id),
            child: Image.file(
              file,
              fit: BoxFit.contain,
              // Mentre la grande si carica resta la miniatura: niente lampo nero.
              frameBuilder: (context, child, frame, sync) => frame == null && !sync
                  ? RollImageThumb(image: widget.image, fit: BoxFit.contain)
                  : child,
              errorBuilder: (_, _, _) => Center(
                child: Padding(
                  padding: MicroSpacing.card,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                      MicroSpacing.gapS,
                      Text(l.photo_missing, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
