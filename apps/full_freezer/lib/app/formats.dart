import 'package:intl/intl.dart';

/// I litri come li legge una persona: "1,2 L" in italiano, "1.2 L" in inglese, senza
/// decimali inutili ("70 L", non "70,0 L").
String formatLiters(double liters, String locale) {
  final digits = liters >= 10 ? 0 : 1;
  final f = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: digits);
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
