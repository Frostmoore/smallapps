/// Cio' che un'altra app ha condiviso verso la nostra, gia' ridotto ai due casi che le
/// MicroApps sanno trattare.
///
/// Dart puro: nessuna dipendenza da Flutter o dal plugin, cosi' le app lo usano nel
/// dominio e nei test senza tirarsi dietro la piattaforma.
library;

/// Un elemento condiviso. Sigillata: chi la consuma fa uno `switch` esaustivo e il
/// compilatore avvisa se un giorno si aggiunge un terzo caso.
sealed class SharedPayload {
  const SharedPayload();
}

/// Testo **e link**: un URL condiviso da un browser arriva come testo, e distinguerlo e'
/// compito dell'app (QR Me lo riconosce nel suo dominio, non qui).
final class SharedText extends SharedPayload {
  const SharedText(this.text);

  /// Il testo condiviso. Quando arriva da `payloadsFromMedia` e' gia' ripulito degli spazi
  /// in testa e in coda e non e' mai vuoto.
  final String text;

  @override
  bool operator ==(Object other) => other is SharedText && other.text == text;

  @override
  int get hashCode => Object.hash(SharedText, text);

  @override
  String toString() => 'SharedText($text)';
}

/// Un'immagine condivisa: percorso di un file locale **gia' copiato** dal plugin nella
/// cache dell'app (Android: dalla `content://` del mittente; iOS: dal contenitore
/// dell'App Group). L'app lo legge e, se le serve tenerlo, lo copia altrove.
final class SharedImage extends SharedPayload {
  const SharedImage(this.path);

  /// Percorso assoluto del file. Quando arriva da `payloadsFromMedia` non e' mai vuoto.
  final String path;

  @override
  bool operator ==(Object other) => other is SharedImage && other.path == path;

  @override
  int get hashCode => Object.hash(SharedImage, path);

  @override
  String toString() => 'SharedImage($path)';
}
