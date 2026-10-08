import 'package:intl/intl.dart';

/// La logica pura delle foto dei rullini (F6.9): niente Flutter, niente database, quindi si
/// prova con test semplici (`test/features/photos/photo_logic_test.dart`).

/// L'ordine degli id dopo aver spostato la foto in posizione [oldIndex] nella posizione
/// [newIndex] (indice finale, gia' corretto: la semantica di
/// `ReorderableListView.onReorderItem`).
///
/// ☠ Il vecchio `onReorder` (deprecato da Flutter 3.41) passava un indice che contava ancora
/// l'elemento trascinato: spostando in avanti quello vero era `newIndex - 1`. Qui si riceve
/// l'indice finale; chi usasse ancora `onReorder` deve correggerlo prima.
List<int> reorderIds(List<int> ids, int oldIndex, int newIndex) {
  if (oldIndex < 0 || oldIndex >= ids.length) return List.of(ids);
  final target = newIndex.clamp(0, ids.length - 1);
  final result = List.of(ids);
  final moved = result.removeAt(oldIndex);
  result.insert(target, moved);
  return result;
}

/// La copertina dopo aver cancellato [deletedId] da un rullino con le foto [idsInOrder] e la
/// copertina [currentCover].
///
/// ⚑ Se si cancella la copertina, diventa copertina la prima foto rimasta e non "nessuna":
/// il database la azzera (`onDelete: setNull`), ma un rullino con le foto e senza anteprima
/// nell'archivio e' un difetto (stessa regola di `FilmRepository.addImage`). Null solo se non
/// resta nessuna foto.
int? coverAfterDelete({
  required List<int> idsInOrder,
  required int? currentCover,
  required int deletedId,
}) {
  if (currentCover != null && currentCover != deletedId && idsInOrder.contains(currentCover)) {
    return currentCover;
  }
  for (final id in idsInOrder) {
    if (id != deletedId) return id;
  }
  return null;
}

/// Lo spazio occupato in forma leggibile: "850 KB", "12,3 MB", "1,2 GB" (separatore decimale
/// della lingua [locale]).
///
/// ⚑ Unita' decimali (1 MB = 1000 KB) come le mostrano le impostazioni di iOS e Android:
/// con quelle binarie l'app direbbe un numero diverso da quello del telefono per gli stessi file.
String formatBytes(int bytes, String locale) {
  if (bytes < 1000) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1000;
  var unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }
  // Una cifra decimale sotto 100 ("12,3 MB"), nessuna sopra ("230 MB").
  final pattern = value < 100 ? '0.#' : '0';
  return '${NumberFormat(pattern, locale).format(value)} ${units[unit]}';
}

/// Stato di un import in corso: quante foto su quante, e se l'utente ha chiesto di fermarsi.
class ImportProgress {
  const ImportProgress({required this.done, required this.total, this.cancelling = false});

  final int done;
  final int total;
  final bool cancelling;

  /// Fra 0 e 1, per la barra.
  double get fraction => total == 0 ? 1 : done / total;

  ImportProgress copyWith({int? done, bool? cancelling}) =>
      ImportProgress(done: done ?? this.done, total: total, cancelling: cancelling ?? this.cancelling);
}

/// Com'e' andato un import: [imported] foto salvate, [failed] illeggibili, [cancelled] se
/// l'utente l'ha fermato prima della fine.
class ImportOutcome {
  const ImportOutcome({required this.imported, required this.failed, required this.cancelled});

  final int imported;
  final int failed;
  final bool cancelled;
}

/// Il segnale "fermati" di un import. Lo controlla l'importatore fra una foto e l'altra.
class ImportCancellation {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}
