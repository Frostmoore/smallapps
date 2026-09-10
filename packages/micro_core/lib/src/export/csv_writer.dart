import 'dart:convert';
import 'dart:io';

import '../storage/app_paths.dart';

/// Costruisce un CSV che Excel apre correttamente in italiano.
///
/// Trappole disinnescate, entrambe scoperte da chiunque abbia mai mandato un CSV a un
/// utente reale:
///
/// 1. **Separatore `;` e non `,`.** Excel con impostazioni italiane interpreta il punto e
///    virgola come separatore di colonna e la virgola come separatore decimale. Con `,`
///    l'intero file finisce in una colonna sola.
/// 2. **BOM UTF-8 in testa.** Senza, Excel legge il file come ANSI e ogni accento diventa
///    un carattere strano. Il pubblico di queste app apre i CSV con Excel, non con pandas.
class CsvWriter {
  CsvWriter({this.separator = ';', this.lineEnding = '\r\n', this.withBom = true});

  final String separator;
  final String lineEnding;
  final bool withBom;

  final StringBuffer _buffer = StringBuffer();
  int _columns = 0;

  void addHeader(List<String> columns) {
    _columns = columns.length;
    _writeRow(columns);
  }

  void addRow(List<Object?> values) {
    assert(
      _columns == 0 || values.length == _columns,
      'riga con ${values.length} valori, ma intestazione con $_columns',
    );
    _writeRow(values.map(_stringify).toList());
  }

  void addBlankLine() => _buffer.write(lineEnding);

  String build() => withBom ? '\uFEFF$_buffer' : _buffer.toString();

  Future<File> writeTo(File target) async {
    await AtomicFile.writeBytes(target, utf8.encode(build()));
    return target;
  }

  void _writeRow(List<String> cells) {
    _buffer
      ..write(cells.map(_escape).join(separator))
      ..write(lineEnding);
  }

  String _stringify(Object? value) => switch (value) {
    null => '',
    final DateTime d => d.toIso8601String(),
    // I decimali con la virgola: e' cio' che Excel italiano si aspetta, coerentemente
    // con il separatore di colonna scelto.
    final double d => d.toString().replaceAll('.', ','),
    _ => value.toString(),
  };

  String _escape(String value) {
    final needsQuotes =
        value.contains(separator) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
