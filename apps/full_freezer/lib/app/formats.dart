import 'package:intl/intl.dart';

/// I litri come li legge una persona: "1,2 L" in italiano, "1.2 L" in inglese, senza
/// decimali inutili ("70 L", non "70,0 L").
String formatLiters(double liters, String locale) {
  // Sotto il litro due decimali al massimo ("0,25 L": con uno solo la misura "piccolo" si
  // leggeva 0,3, visto sull'emulatore il 2026-10-07); fino a 10 uno; oltre nessuno.
  final f = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = liters >= 10 ? 0 : (liters < 1 ? 2 : 1);
  return '${f.format(liters)} L';
}

/// Una quantita' senza decimali inutili: "2", "1,5", "0,25".
String formatQuantity(double q, String locale) {
  final f = NumberFormat.decimalPattern(locale)..maximumFractionDigits = 2;
  return f.format(q);
}

/// Legge un numero scritto da una persona, con la virgola o con il punto.
///
/// ⚑ Tutte e due: chi ha il telefono in italiano scrive "1,5", ma la tastiera numerica di
/// alcuni produttori mostra solo il punto. Rifiutare uno dei due vorrebbe dire un campo che
/// "non accetta il numero" senza che si capisca perche'.
double? parseUserNumber(String input) {
  final cleaned = input.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}
