import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/freezer_palette.dart';
import '../../app/providers.dart';
import '../../l10n/generated/app_localizations.dart';

/// Le foto dei prodotti (F4.5b; **gratis**, decisione del 2026-10-06).
///
/// ⚑ Il lavoro lo fa `ImageStore` di micro_core: ridimensiona in un isolate (una foto da 12
/// megapixel congelerebbe la UI per secondi su un telefono economico), salva una miniatura e
/// restituisce percorsi **relativi** (quelli assoluti cambiano a ogni aggiornamento su iOS e
/// fra un ripristino e l'altro su Android). Qui c'e' solo la scelta della sorgente.

/// Il lato lungo delle foto conservate: un sacchetto nel freezer non ha bisogno dei 1600 px
/// di un provino di Film Tracker. Circa 150 KB a foto.
const int itemPhotoMaxSide = 1280;

/// La cartella delle foto dei prodotti dentro `images/`.
const String itemPhotoBucket = 'items';

/// Il percorso della miniatura di una foto salvata da `ImageStore`.
///
/// ⚑ Nel database c'e' solo `photoPath`: la miniatura sta in `images/thumbs/<bucket>/<nome>`
/// per convenzione di `ImageStore.importBytes`, quindi si ricava invece di salvarla due volte.
String thumbPathOf(String photoPath) => photoPath.replaceFirst('images/', 'images/thumbs/');

/// Fa scegliere fra fotocamera e galleria, importa la foto e ne restituisce il percorso
/// relativo; null se l'utente rinuncia o la foto non si legge (lo dice uno snackbar).
Future<String?> pickItemPhoto(BuildContext context, WidgetRef ref) async {
  final l = L.of(context);
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l.photo_camera),
            onTap: () => Navigator.of(sheet).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l.photo_gallery),
            onTap: () => Navigator.of(sheet).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final XFile? picked;
  try {
    picked = await ImagePicker().pickImage(source: source);
  } on Exception catch (e, s) {
    // Permesso negato, fotocamera assente (emulatori), galleria non disponibile.
    MicroLog.e('scelta foto fallita', error: e, stackTrace: s);
    if (context.mounted) MicroSnack.error(context, l.photo_failed);
    return null;
  }
  if (picked == null) return null;

  final store = ImageStore(paths: ref.read(appPathsProvider));
  final source0 = File(picked.path);
  final result = await store.importFile(source0, bucket: itemPhotoBucket, maxLongSide: itemPhotoMaxSide);
  // image_picker lascia una copia nella cache dell'app (visto sull'emulatore, 2026-10-07):
  // dopo l'importazione non serve piu', e una foto a scatto si accumulerebbe finche' il
  // sistema non decide di pulire. Solo se sta davvero nella cache: dalla galleria, su
  // alcune versioni, il percorso e' l'originale dell'utente, che non si tocca.
  if (source0.path.contains('/cache/')) {
    try {
      await source0.delete();
    } on FileSystemException {
      // Gia' sparita: va bene cosi'.
    }
  }
  switch (result) {
    case Ok(:final value):
      return value.path;
    case Err():
      if (context.mounted) MicroSnack.error(context, l.photo_failed);
      return null;
  }
}

/// Cancella una foto e la sua miniatura (quando la si toglie o la si sostituisce).
///
/// Prende [AppPaths] e non un `ref` perche' si chiama anche da `dispose`, dove `ref` non
/// si puo' piu' usare.
Future<void> deleteItemPhoto(AppPaths paths, String photoPath) async {
  for (final relative in [photoPath, thumbPathOf(photoPath)]) {
    final f = paths.resolve(relative);
    if (f.existsSync()) await f.delete();
  }
}

/// La miniatura di una foto, ritagliata quadrata. Se il file manca (un ripristino senza
/// foto, una cancellazione a meta') mostra [fallback] invece di un errore.
class ItemPhotoThumb extends ConsumerWidget {
  const ItemPhotoThumb({required this.photoPath, required this.size, required this.fallback, this.radius = 10, super.key});

  final String photoPath;
  final double size;
  final double radius;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(appPathsProvider).resolve(thumbPathOf(photoPath));
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (_, __, ___) => SizedBox.square(dimension: size, child: fallback),
      ),
    );
  }
}

/// La foto grande nella pagina dell'alimento, con "Cambia" e "Togli"; senza foto, i due
/// pulsanti per aggiungerla.
class ItemPhotoEditor extends ConsumerWidget {
  const ItemPhotoEditor({required this.photoPath, required this.onChanged, super.key});

  final String? photoPath;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = FreezerPalette.of(context);
    final path = photoPath;
    if (path == null) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.add_a_photo_outlined),
        label: Text(l.photo_add),
        onPressed: () async {
          final added = await pickItemPhoto(context, ref);
          if (added != null) onChanged(added);
        },
      );
    }
    final file = ref.watch(appPathsProvider).resolve(path);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: p.iconTile,
                child: Icon(Icons.broken_image_outlined, color: p.onIconTile, size: 40),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: Text(l.photo_remove),
              onPressed: () => onChanged(null),
            ),
            TextButton.icon(
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(l.photo_change),
              onPressed: () async {
                final added = await pickItemPhoto(context, ref);
                if (added != null) onChanged(added);
              },
            ),
          ],
        ),
      ],
    );
  }
}
