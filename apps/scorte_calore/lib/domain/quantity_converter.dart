import 'fuel_source.dart';
import 'fuel_units.dart';

/// Conversioni fra percentuale del manometro, quantita' e chili (develop_microapps.md F5.4).
///
/// ⚑ **La `format` del piano non c'e' qui di proposito**: formattare "344 L" o "12,5 sacchi"
/// richiede separatore decimale e nomi delle unita' della lingua dell'utente, cioe' `intl` e
/// gli ARB. La fa la UI con [FuelUnit.decimals] e la chiave dell'unita'; il dominio resta
/// Dart puro e restituisce solo numeri.
class QuantityConverter {
  const QuantityConverter(this.source);

  final FuelSourceSpec source;

  bool get _unitIsPercent => source.unitKey == FuelUnits.percent;

  /// Se questa fonte sa passare da percentuale a quantita': serve una capacita' utile
  /// positiva, oppure una fonte tenuta direttamente in percentuale.
  bool get supportsPercentage {
    if (_unitIsPercent) return true;
    final usable = source.usableCapacity;
    return usable != null && usable > 0;
  }

  /// Dalla lettura del manometro alla quantita' nell'unita' della fonte:
  /// `percent / 100 x capacita' x frazione utile`. 43% di 1000 L con 0,8 -> 344 L.
  ///
  /// ☠ Si moltiplica per la capacita' **utile**, non per quella nominale (F5.2): con la
  /// nominale l'app sovrastimerebbe la scorta di GPL di un quarto e manderebbe l'utente a
  /// secco.
  ///
  /// ⚑ Con l'unita' `percent` la quantita' **e'** la percentuale: la conversione e'
  /// l'identita', e la frazione utile non entra (la scorta si misura in "punti di
  /// manometro" e si esaurisce a 0%).
  ///
  /// Lancia [StateError] se ![supportsPercentage]: la UI non deve offrire lo switch
  /// percentuale a una fonte senza capacita'.
  double fromPercentage(double percent) {
    if (_unitIsPercent) return percent;
    return percent / 100 * _requireUsableCapacity();
  }

  /// L'inverso di [fromPercentage]: quanta percentuale del manometro e' [quantity].
  double toPercentage(double quantity) {
    if (_unitIsPercent) return quantity;
    return quantity / _requireUsableCapacity() * 100;
  }

  /// Il peso in kg di [quantity]; null se non convertibile.
  ///
  /// - `kg`: e' gia' un peso; `quintals`: x 100 (conversione esatta, non una stima);
  /// - unita' con [FuelUnit.supportsWeight] e `unitWeightKg` positivo: x peso unitario;
  /// - tutto il resto (litri, percentuale, steri, contenitori senza peso): null.
  ///
  /// ⚑ Niente densita' per GPL e gasolio e niente peso degli steri: una conversione
  /// approssimativa presentata come esatta produce numeri falsi con un'aria di precisione
  /// (F5.4). Il peso, quando c'e', e' un dato in piu' da mostrare, non entra nella stima.
  double? toKilograms(double quantity) {
    switch (source.unitKey) {
      case FuelUnits.kg:
        return quantity;
      case FuelUnits.quintals:
        return quantity * 100;
    }
    final weight = source.unitWeightKg;
    if (!source.unit.supportsWeight || weight == null || weight <= 0) return null;
    return quantity * weight;
  }

  /// Ricalcola la quantita' di una misurazione dal valore digitato, con la configurazione
  /// **attuale** della fonte. Da chiamare su tutte le misurazioni quando l'utente cambia
  /// capacita' o frazione utile (il motivo per cui esistono `enteredAs` e `rawInput`, F5.2).
  ///
  /// - `absolute`: resta com'e' (la quantita' e' quella digitata);
  /// - `percentage`: `fromPercentage(rawInput)`.
  ///
  /// ☠ Se la fonte ha perso la capacita' (l'utente l'ha cancellata), la misurazione resta
  /// **invariata** invece di lanciare: buttare via la quantita' gia' calcolata sarebbe
  /// perdere un dato per un campo lasciato vuoto un momento.
  Measurement recompute(Measurement m) {
    if (m.enteredAs != EnteredAs.percentage || !supportsPercentage) return m;
    return m.withQuantity(fromPercentage(m.rawInput));
  }

  /// [recompute] su una serie intera, nello stesso ordine.
  List<Measurement> recomputeAll(Iterable<Measurement> measurements) =>
      measurements.map(recompute).toList(growable: false);

  double _requireUsableCapacity() {
    final usable = source.usableCapacity;
    if (usable == null || usable <= 0) {
      throw StateError('La fonte ${source.id} non ha una capacita\' utile: niente percentuali');
    }
    return usable;
  }
}
