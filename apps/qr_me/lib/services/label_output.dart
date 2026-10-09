import 'dart:typed_data';

import 'package:micro_core/micro_core.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Dove va l'etichetta (F17.10 punto 5): la stampante, con il dialogo di sistema, o il foglio
/// di condivisione come PNG.
///
/// ⚑ Un'interfaccia perche' sotto `flutter test` non ci sono plugin: i test di widget usano un
/// doppio finto ([labelOutputProvider] in lib/app/providers.dart) che registra cosa e' uscito.
abstract interface class LabelOutput {
  /// Apre il dialogo di stampa del sistema. [buildPdf] riceve il foglio scelto li' (A4, Letter,
  /// un'etichetta...) e restituisce il PDF. `false` se la stampa non e' partita.
  Future<bool> printPdf({
    required Future<Uint8List> Function(PdfPageFormat page) buildPdf,
    required String name,
  });

  /// Condivide il PNG con il foglio di sistema, con [title] come oggetto.
  Future<void> sharePng({required Uint8List png, required String title});
}

/// L'implementazione vera: `printing` (Android `PrintManager`, iOS `UIPrintInteractionController`)
/// e `share_plus`.
///
/// ⚑ `printing` era gia' nel monorepo con Film Tracker; ricontrollato per QR Me il 2026-10-09 nel
/// sorgente in pub cache: nessun SDK di terzi, nessuna rete (la sua `networkImage` scarica solo
/// se la si chiama, e QR Me non la chiama).
class SystemLabelOutput implements LabelOutput {
  const SystemLabelOutput({required this.paths});

  final AppPaths paths;

  @override
  Future<bool> printPdf({
    required Future<Uint8List> Function(PdfPageFormat page) buildPdf,
    required String name,
  }) => Printing.layoutPdf(onLayout: buildPdf, name: name);

  @override
  Future<void> sharePng({required Uint8List png, required String title}) async {
    final file = paths.file(
      paths.exports,
      'qr-me-label-${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await AtomicFile.writeBytes(file, png);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        subject: title,
      ),
    );
  }
}
