import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

enum LogLevel {
  debug(0, 'D'),
  info(1, 'I'),
  warn(2, 'W'),
  error(3, 'E');

  const LogLevel(this.rank, this.tag);
  final int rank;
  final String tag;
}

/// Log su file, a rotazione.
///
/// ⚑ Perché non `print`: la lint `avoid_print` è attiva, e in release `print` non arriva
/// da nessuna parte. Con un file, quando un utente scrive "le notifiche non arrivano" gli
/// si può chiedere di esportare il log dalle impostazioni, che è l'unico modo di
/// diagnosticare un problema di pianificazione su una ROM che uccide i processi.
///
/// ⚑ Perché a rotazione e non infinito: un log che cresce senza limite riempie lo spazio
/// del telefono di un utente che non sa nemmeno di averlo. Due file da mezzo mega bastano
/// a coprire giorni di uso normale.
abstract final class MicroLog {
  static File? _file;
  static LogLevel _minLevel = LogLevel.info;
  static int _maxBytes = 512 * 1024;
  static IOSink? _sink;

  /// Se `false`, il log non scrive niente: è lo stato prima di [init].
  static bool get isActive => _file != null;

  static File? get file => _file;

  static void init({
    required File file,
    LogLevel minLevel = LogLevel.info,
    int maxBytes = 512 * 1024,
  }) {
    _file = file;
    _minLevel = kDebugMode ? LogLevel.debug : minLevel;
    _maxBytes = maxBytes;
    _sink = null;
  }

  static void d(String message, {Object? data}) => _write(LogLevel.debug, message, data: data);

  static void i(String message, {Object? data}) => _write(LogLevel.info, message, data: data);

  static void w(String message, {Object? error}) => _write(LogLevel.warn, message, data: error);

  static void e(String message, {Object? error, StackTrace? stackTrace}) =>
      _write(LogLevel.error, message, data: error, stackTrace: stackTrace);

  static void _write(LogLevel level, String message, {Object? data, StackTrace? stackTrace}) {
    if (level.rank < _minLevel.rank) return;

    final line = StringBuffer()
      ..write(DateTime.now().toIso8601String())
      ..write(' [')
      ..write(level.tag)
      ..write('] ')
      ..write(message);
    if (data != null) line.write(' | $data');
    if (stackTrace != null) line.write('\n$stackTrace');

    if (kDebugMode) {
      // In debug conviene vederlo anche in console. `debugPrint` limita il volume per
      // non far scartare righe ad Android quando il log è fitto.
      debugPrint(line.toString());
    }

    final target = _file;
    if (target == null) return;

    try {
      _rotateIfNeeded(target);
      (_sink ??= target.openWrite(mode: FileMode.append)).writeln(line);
    } on FileSystemException {
      // Un log che non riesce a scrivere non deve far cadere l'app: è diagnostica, non
      // funzionalità. Si perde la riga e si prosegue.
      _sink = null;
    }
  }

  static void _rotateIfNeeded(File target) {
    if (!target.existsSync()) return;
    if (target.lengthSync() < _maxBytes) return;
    _sink?.close();
    _sink = null;
    final previous = File('${target.path}.1');
    if (previous.existsSync()) previous.deleteSync();
    target.renameSync(previous.path);
  }

  /// Il log corrente più quello ruotato, concatenati in un unico file condivisibile.
  static Future<File?> export({required Directory into}) async {
    final target = _file;
    if (target == null) return null;
    await _sink?.flush();

    final buffer = StringBuffer();
    final previous = File('${target.path}.1');
    if (previous.existsSync()) buffer.write(await previous.readAsString());
    if (target.existsSync()) buffer.write(await target.readAsString());
    if (buffer.isEmpty) return null;

    if (!into.existsSync()) await into.create(recursive: true);
    final out = File('${into.path}/log-${DateTime.now().millisecondsSinceEpoch}.txt');
    await out.writeAsString(buffer.toString(), flush: true);
    return out;
  }

  static Future<void> clear() async {
    await _sink?.close();
    _sink = null;
    final target = _file;
    if (target == null) return;
    for (final f in [target, File('${target.path}.1')]) {
      if (f.existsSync()) await f.delete();
    }
  }

  static Future<void> dispose() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }
}
