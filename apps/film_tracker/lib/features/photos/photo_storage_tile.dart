import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import 'image_store_provider.dart';
import 'photo_logic.dart';

/// Quanto spazio occupano le foto (immagini e miniature) e il ricalcolo dopo una pulizia.
///
/// ⚑ Un `FutureProvider` che si invalida, non un numero tenuto dalla voce: dopo "Libera
/// spazio" (o un import) chi lo legge vede il valore nuovo senza dover passare dalla voce.
final photoStorageBytesProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(imageStoreProvider).totalBytes(),
);

/// La voce delle impostazioni "Spazio delle foto" (F6.9): lo spazio occupato e, al tocco,
/// "Libera spazio", che cancella i file che nessun rullino referenzia piu'.
///
/// ⚑ "Libera spazio" non tocca mai una foto in uso: l'elenco di cio' che si tiene viene dal
/// database (`FilmRepository.allImagePaths`, immagini **e** miniature), e
/// `ImageStore.pruneOrphans` cancella solo cio' che non e' in quell'elenco. Gli orfani nascono
/// da cancellazioni interrotte fra la riga e il file (vedi `confirmAndDeleteRollPhoto`).
///
/// ☠ Non lanciarlo durante un import: il file di una foto appena convertita esiste un istante
/// prima della sua riga. In pratica non succede, perche' l'import blocca lo schermo con la sua
/// finestra e le impostazioni non sono raggiungibili.
class PhotoStorageTile extends ConsumerWidget {
  const PhotoStorageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final bytes = ref.watch(photoStorageBytesProvider);
    return ListTile(
      leading: const Icon(Icons.photo_library_outlined),
      title: Text(l.photo_storageTitle),
      subtitle: Text(switch (bytes) {
        AsyncData(:final value) => l.photo_storageUsed(formatBytes(value, locale)),
        _ => l.photo_storageLoading,
      }),
      onTap: () => _free(context, ref),
    );
  }

  Future<void> _free(BuildContext context, WidgetRef ref) async {
    final l = L.of(context);
    final ok = await MicroConfirmSheet.show(
      context,
      title: l.photo_freeTitle,
      message: l.photo_freeBody,
      confirmLabel: l.photo_freeConfirm,
      cancelLabel: l.common_cancel,
    );
    if (!ok) return;
    final keep = await ref.read(repositoryProvider).allImagePaths();
    final removed = await ref.read(imageStoreProvider).pruneOrphans(keep);
    ref.invalidate(photoStorageBytesProvider);
    if (!context.mounted) return;
    MicroSnack.show(context, removed == 0 ? l.photo_freedNothing : l.photo_freed(removed));
  }
}
