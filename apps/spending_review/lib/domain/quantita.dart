import 'package:meta/meta.dart';

/// L'unita' di un prezzo a misura: al kg (pesi) o al litro (volumi).
enum UnitaMisura { kg, l }

/// Quanti pezzi, o quanto peso/volume (develop_microapps.md F12.1.3).
///
/// ⚑ Pesi e volumi in **millesimi interi** (grammi, millilitri): nessun `double` nei conti.
sealed class Quantita {
  const Quantita();
}

/// Pezzi interi, 1..999.
@immutable
final class Pezzi extends Quantita {
  const Pezzi(this.n);

  final int n;

  /// Il limite della colonna `righe.pezzi` (CHECK 1..999).
  static const int massimo = 999;

  @override
  bool operator ==(Object other) => other is Pezzi && other.n == n;

  @override
  int get hashCode => n.hashCode;

  @override
  String toString() => 'Pezzi($n)';
}

/// Peso (grammi, [UnitaMisura.kg]) o volume (millilitri, [UnitaMisura.l]), 1..99999 millesimi.
@immutable
final class AMisura extends Quantita {
  const AMisura(this.millesimi, this.unita);

  final int millesimi;
  final UnitaMisura unita;

  /// Il limite della colonna `righe.millesimi` (CHECK 1..99999): quasi 100 kg o 100 litri.
  static const int massimo = 99999;

  @override
  bool operator ==(Object other) =>
      other is AMisura && other.millesimi == millesimi && other.unita == unita;

  @override
  int get hashCode => Object.hash(millesimi, unita);

  @override
  String toString() => 'AMisura($millesimi ${unita.name})';
}
