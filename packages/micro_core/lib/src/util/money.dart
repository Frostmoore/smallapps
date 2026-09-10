import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

/// Un importo di denaro, in **centesimi interi**.
///
/// ⚑ Perché non `double`: Film Tracker e Scorte Calore sommano decine di importi. Con i
/// numeri in virgola mobile "231,00 €" diventa "230,99999999999997 €" nella schermata
/// delle statistiche, e a quel punto l'utente smette di fidarsi anche di tutti gli altri
/// numeri dell'app. Un intero non ha questo problema.
@immutable
final class Money implements Comparable<Money> {
  const Money.cents(this.cents, {this.currency = 'EUR'});

  /// Da un importo decimale, con arrotondamento al centesimo più vicino.
  factory Money.fromDouble(double amount, {String currency = 'EUR'}) =>
      Money.cents((amount * 100).round(), currency: currency);

  /// Interpreta quello che l'utente ha digitato in un campo di testo.
  ///
  /// Accetta virgola e punto come separatore decimale, spazi, e il simbolo di valuta:
  /// chi scrive "6,50 €" in un campo prezzo si aspetta che funzioni.
  static Money? tryParse(String input, {String currency = 'EUR'}) {
    var cleaned = input.replaceAll(RegExp(r'[^\d,.\-]'), '');
    if (cleaned.isEmpty) return null;

    final lastComma = cleaned.lastIndexOf(',');
    final lastDot = cleaned.lastIndexOf('.');

    if (lastComma >= 0 && lastDot >= 0) {
      // Ci sono entrambi: l'ultimo dei due è il separatore decimale, l'altro è quello
      // delle migliaia. Vale sia per "1.234,56" sia per "1,234.56".
      final decimalSep = lastComma > lastDot ? ',' : '.';
      final thousandsSep = decimalSep == ',' ? '.' : ',';
      cleaned = cleaned.replaceAll(thousandsSep, '').replaceAll(decimalSep, '.');
    } else if (lastComma >= 0) {
      // Solo la virgola: in italiano è sempre il separatore decimale.
      cleaned = cleaned.replaceAll(',', '.');
    } else if (lastDot >= 0) {
      // Solo il punto, ed è ambiguo. "1.000" sono mille, "6.50" sono sei e cinquanta.
      // Si distingue dal numero di cifre che seguono: esattamente tre cifre dopo un
      // punto, con qualcosa prima, è quasi sempre un separatore di migliaia.
      final decimals = cleaned.length - lastDot - 1;
      final hasMultipleDots = cleaned.indexOf('.') != lastDot;
      if (hasMultipleDots || (decimals == 3 && lastDot > 0)) {
        cleaned = cleaned.replaceAll('.', '');
      }
    }

    final value = double.tryParse(cleaned);
    return value == null ? null : Money.fromDouble(value, currency: currency);
  }

  final int cents;
  final String currency;

  static const Money zero = Money.cents(0);

  double get asDouble => cents / 100;

  bool get isZero => cents == 0;
  bool get isNegative => cents < 0;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money.cents(cents + other.cents, currency: currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money.cents(cents - other.cents, currency: currency);
  }

  Money operator *(num factor) => Money.cents((cents * factor).round(), currency: currency);

  /// Divide l'importo, arrotondando al centesimo.
  ///
  /// ☠ Non conserva il totale: dividere 10 € in 3 dà tre volte 3,33 €, cioè 9,99 €. Per
  /// ripartire un importo senza perdere centesimi serve un'allocazione, che qui non c'è
  /// perché nessuna delle app la richiede. Se servisse, va scritta, non improvvisata.
  Money operator /(num divisor) => Money.cents((cents / divisor).round(), currency: currency);

  /// Formattazione localizzata, con il simbolo di valuta.
  String format({String? locale}) =>
      NumberFormat.simpleCurrency(locale: locale, name: currency).format(asDouble);

  /// Solo il numero, senza simbolo. Per le tabelle e i CSV.
  String formatPlain({String? locale}) =>
      NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 2).format(asDouble);

  static Money sum(Iterable<Money> values, {String currency = 'EUR'}) {
    var total = 0;
    for (final v in values) {
      total += v.cents;
    }
    return Money.cents(total, currency: currency);
  }

  /// La media, oppure `null` su una collezione vuota.
  ///
  /// Restituisce `null` invece di zero perché "nessun dato" e "media zero" sono cose
  /// diverse, e mostrarle uguali nasconde all'utente che non ci sono ancora dati.
  static Money? average(Iterable<Money> values, {String currency = 'EUR'}) {
    final list = values.toList();
    if (list.isEmpty) return null;
    return Money.cents(sum(list, currency: currency).cents ~/ list.length, currency: currency);
  }

  void _assertSameCurrency(Money other) {
    assert(
      other.currency == currency,
      'Somma fra valute diverse: $currency e ${other.currency}. '
      'Serve una conversione esplicita, non un operatore.',
    );
  }

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) =>
      other is Money && other.cents == cents && other.currency == currency;

  @override
  int get hashCode => Object.hash(cents, currency);

  @override
  String toString() => 'Money($cents $currency)';
}
