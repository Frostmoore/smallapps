import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../data/database.dart';
import '../../data/film_repository.dart';
import '../../domain/film_types.dart';
import '../../l10n/generated/app_localizations.dart';
import 'image_store_provider.dart';
import 'photo_logic.dart';

/// Le azioni sulle foto di un rullino (F6.9, **gratis** per F6.0 punto 3): aggiungere
/// (fotocamera o galleria, piu' foto insieme), cancellare, scegliere la copertina.
///
/// ⚑ Qui e non dentro i widget perche' le usano sia la griglia del dettaglio
/// (`roll_photos_section.dart`) sia il visualizzatore (`photo_viewer_page.dart`): una sola
/// regola per "cancello la copertina, chi diventa copertina?".

/// Il selettore di foto, in un provider per poterlo sostituire nei test.
final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

/// Importa [files] nel rullino [rollId], una alla volta, e restituisce com'e' andata.
///
/// Ogni foto passa da `ImageStore.importFile`, che la ridimensiona a 1600 px sul lato lungo
/// (miniatura a 400, JPEG qualita' 82) **in un isolate** (`compute`): dieci foto da 12
/// megapixel sul thread della UI la congelerebbero per secondi (trappola di F6.9).
///
/// ⚑ Una foto alla volta e non dieci isolate insieme: su un telefono economico dieci decodifiche
/// in parallelo da 12 megapixel (circa 48 MB di pixel l'una) finiscono la memoria; in fila la
/// memoria resta quella di una foto e la barra avanza in modo leggibile.
///
/// [cancellation] si controlla **fra** una foto e l'altra: quella gia' in conversione si finisce
/// e si tiene (il lavoro e' fatto, e il testo della UI dice "mi fermo dopo questa foto"); quelle
/// gia' salvate restano. [onProgress] riceve quante foto sono state lavorate.
///
/// Le copie temporanee che `image_picker` lascia nella cache dell'app si cancellano dopo
/// l'import (lezione di Full Freezer, `item_photo.dart`); gli originali dell'utente no.
Future<ImportOutcome> importRollPhotos({
  required FilmRepository repository,
  required ImageStore store,
  required int rollId,
  required List<File> files,
  RollImageKind kind = RollImageKind.contactSheet,
  ImportCancellation? cancellation,
  void Function(int done)? onProgress,
}) async {
  var imported = 0;
  var failed = 0;
  var done = 0;
  for (final file in files) {
    if (cancellation?.isCancelled ?? false) break;
    final Result<StoredImage> result;
    try {
      result = await store.importFile(file, bucket: rollImageBucket);
      // ☠ Su un file corrotto o di un formato che il pacchetto `image` non conosce, il decoder
      // puo' lanciare un *Error* (RangeError, visto il 2026-10-08 con quattro byte a caso) e non
      // un'Exception: `ImageStore.importBytes` cattura solo le Exception, quindi l'errore
      // attraverserebbe tutto e fermerebbe l'import a meta' con la finestra aperta. Qui conta
      // come una foto illeggibile e si passa alla successiva.
      // ignore: avoid_catches_without_on_clauses
    } catch (e, s) {
      MicroLog.e('import foto fallito', error: e, stackTrace: s);
      failed++;
      await _discardPickerCopy(file);
      done++;
      onProgress?.call(done);
      continue;
    }
    switch (result) {
      case Ok(:final value):
        try {
          await repository.addImage(rollId: rollId, image: value, kind: kind);
          imported++;
        } on Exception catch (e, s) {
          // Il rullino e' stato cancellato mentre si importava: il file resterebbe orfano.
          MicroLog.e('registrazione foto fallita', error: e, stackTrace: s);
          await store.delete(value);
          failed++;
        }
      case Err():
        failed++;
    }
    await _discardPickerCopy(file);
    done++;
    onProgress?.call(done);
  }
  return ImportOutcome(
    imported: imported,
    failed: failed,
    cancelled: done < files.length,
  );
}

/// Cancella la copia di `image_picker` se sta nella cache dell'app. Dalla galleria, su alcune
/// versioni di Android, il percorso e' l'originale dell'utente: quello non si tocca mai.
Future<void> _discardPickerCopy(File file) async {
  final path = file.path.replaceAll(r'\', '/');
  if (!path.contains('/cache/') && !path.contains('/tmp/')) return;
  try {
    await file.delete();
  } on FileSystemException {
    // Gia' sparita: va bene cosi'.
  }
}

/// La scelta dell'utente nel foglio "Aggiungi": da dove e che tipo di immagine.
typedef PhotoPick = ({ImageSource source, RollImageKind kind});

/// Il foglio "Aggiungi": tipo dell'immagine (provini di default) e sorgente.
Future<PhotoPick?> showPhotoSourceSheet(BuildContext context) => showModalBottomSheet<PhotoPick>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => const _PhotoSourceSheet(),
);

class _PhotoSourceSheet extends StatefulWidget {
  const _PhotoSourceSheet();

  @override
  State<_PhotoSourceSheet> createState() => _PhotoSourceSheetState();
}

class _PhotoSourceSheetState extends State<_PhotoSourceSheet> {
  RollImageKind _kind = RollImageKind.contactSheet;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(MicroSpacing.l, 0, MicroSpacing.l, MicroSpacing.s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.photo_kindLabel, style: Theme.of(context).textTheme.titleSmall),
            MicroSpacing.gapS,
            // ⚑ Il tipo si sceglie qui, prima della foto, perche' costa un tocco e vale per
            // tutte quelle scelte insieme (di solito dieci scansioni o un foglio di provini).
            Wrap(
              spacing: MicroSpacing.s,
              runSpacing: MicroSpacing.xs,
              children: [
                for (final k in RollImageKind.values)
                  ChoiceChip(
                    label: Text(rollImageKindLabel(l, k)),
                    selected: _kind == k,
                    onSelected: (_) => setState(() => _kind = k),
                  ),
              ],
            ),
            MicroSpacing.gapM,
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l.photo_camera),
              onTap: () => Navigator.of(context).pop((source: ImageSource.camera, kind: _kind)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.photo_gallery),
              subtitle: Text(l.photo_galleryHint),
              onTap: () => Navigator.of(context).pop((source: ImageSource.gallery, kind: _kind)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Il nome di un tipo di immagine nella lingua dell'app.
String rollImageKindLabel(L l, RollImageKind kind) => switch (kind) {
  RollImageKind.contactSheet => l.photo_kind_contactSheet,
  RollImageKind.print => l.photo_kind_print,
  RollImageKind.scan => l.photo_kind_scan,
  RollImageKind.other => l.photo_kind_other,
};

/// Il flusso completo di "Aggiungi": foglio, fotocamera o galleria (selezione multipla), import
/// con la barra di avanzamento e "Annulla", messaggio finale.
Future<void> addRollPhotos(BuildContext context, WidgetRef ref, int rollId) async {
  final l = L.of(context);
  final pick = await showPhotoSourceSheet(context);
  if (pick == null || !context.mounted) return;

  final picker = ref.read(imagePickerProvider);
  final List<XFile> picked;
  try {
    picked = switch (pick.source) {
      ImageSource.camera => [?await picker.pickImage(source: ImageSource.camera)],
      // ⚑ Niente maxWidth/imageQuality qui: il ridimensionamento lo fa ImageStore, in un isolate
      // e con l'orientamento EXIF applicato ai pixel. Farlo fare anche al picker vorrebbe dire
      // ricomprimere due volte lo stesso JPEG.
      ImageSource.gallery => await picker.pickMultiImage(),
    };
  } on Exception catch (e, s) {
    // Permesso negato, fotocamera assente (emulatori), galleria non disponibile.
    MicroLog.e('scelta foto fallita', error: e, stackTrace: s);
    if (context.mounted) MicroSnack.error(context, l.photo_pickFailed);
    return;
  }
  if (picked.isEmpty || !context.mounted) return;

  final progress = ValueNotifier(ImportProgress(done: 0, total: picked.length));
  final cancellation = ImportCancellation();
  final navigator = Navigator.of(context, rootNavigator: true);
  final dialog = showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => _ImportDialog(
      progress: progress,
      onCancel: () {
        cancellation.cancel();
        progress.value = progress.value.copyWith(cancelling: true);
      },
    ),
  );

  final outcome = await importRollPhotos(
    repository: ref.read(repositoryProvider),
    store: ref.read(imageStoreProvider),
    rollId: rollId,
    files: [for (final x in picked) File(x.path)],
    kind: pick.kind,
    cancellation: cancellation,
    onProgress: (done) => progress.value = progress.value.copyWith(done: done),
  );
  navigator.pop();
  await dialog;
  progress.dispose();

  if (!context.mounted) return;
  if (outcome.failed > 0) {
    MicroSnack.error(context, l.photo_importFailed(outcome.failed));
  } else if (outcome.imported > 0) {
    MicroSnack.success(context, l.photo_imported(outcome.imported));
  }
}

/// La finestra dell'import: "Importo 3 di 10", la barra, "Annulla".
///
/// ⚑ Non si chiude con il tocco fuori ne' con "indietro": chiudendola l'import continuerebbe
/// senza che l'utente lo veda, e un secondo "Aggiungi" lo raddoppierebbe.
class _ImportDialog extends StatelessWidget {
  const _ImportDialog({required this.progress, required this.onCancel});

  final ValueNotifier<ImportProgress> progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return PopScope(
      canPop: false,
      child: ValueListenableBuilder<ImportProgress>(
        valueListenable: progress,
        builder: (context, p, _) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.cancelling
                    ? l.photo_importCancelling
                    // La foto in lavorazione e' la successiva a quelle finite.
                    : l.photo_importing((p.done + 1).clamp(1, p.total), p.total),
              ),
              MicroSpacing.gapM,
              LinearProgressIndicator(value: p.fraction),
            ],
          ),
          actions: [
            TextButton(
              onPressed: p.cancelling ? null : onCancel,
              child: Text(l.common_cancel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chiede conferma e cancella una foto: riga, file, miniatura. Se era la copertina, la
/// copertina passa alla prima foto rimasta ([coverAfterDelete]). True se l'ha cancellata.
Future<bool> confirmAndDeleteRollPhoto(
  BuildContext context,
  WidgetRef ref, {
  required int rollId,
  required RollImage image,
  required List<RollImage> images,
  required int? coverId,
}) async {
  final l = L.of(context);
  final ok = await MicroConfirmSheet.show(
    context,
    title: l.photo_deleteTitle,
    message: l.photo_deleteBody,
    confirmLabel: l.common_delete,
    cancelLabel: l.common_cancel,
    destructive: true,
  );
  if (!ok) return false;

  final repo = ref.read(repositoryProvider);
  final stored = await repo.deleteImage(image.id);
  // ⚑ Prima la riga e poi i file: al contrario, un'interruzione a meta' lascerebbe una riga che
  // punta al nulla (una miniatura rotta nella griglia). Cosi' resta al massimo un file orfano,
  // che "Libera spazio" (PhotoStorageTile) toglie.
  if (stored != null) await ref.read(imageStoreProvider).delete(stored);
  if (coverId == image.id) {
    final next = coverAfterDelete(
      idsInOrder: [for (final i in images) i.id],
      currentCover: coverId,
      deletedId: image.id,
    );
    if (next != null) await repo.setCoverImage(rollId, next);
  }
  if (context.mounted) MicroSnack.show(context, l.photo_deleted);
  return true;
}

/// Sceglie [imageId] come copertina del rullino e lo dice.
Future<void> setRollCover(BuildContext context, WidgetRef ref, {required int rollId, required int imageId}) async {
  final l = L.of(context);
  await ref.read(repositoryProvider).setCoverImage(rollId, imageId);
  if (context.mounted) MicroSnack.show(context, l.photo_coverSet);
}
