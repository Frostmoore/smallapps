import 'package:meta/meta.dart';

/// I combustibili che l'app sa seguire (develop_microapps.md F5.2, colonna `fuelType`).
///
/// [key] e' il valore salvato in `fuel_sources.fuelType`: **non si rinomina mai**, anche se
/// si rinomina il valore dell'enum. Per questo e' scritto a mano e non e' `name`.
///
/// I nomi visibili ("Pellet", "GPL"...) NON stanno qui: il dominio porta solo chiavi, i testi
/// li risolve la UI dagli ARB (`fuel_<key>`, vedi `fuelName` in lib/app/labels.dart), cosi' il dominio resta Dart puro e
/// traducibile senza toccarlo.
enum FuelType {
  pellet('pellet', defaultUnitKey: FuelUnits.bags),

  /// ☠ GPL: un bombolone non si riempie mai oltre l'80% della capacita' geometrica (spazio
  /// per l'espansione della fase gassosa). Per questo la sua frazione utile di default e'
  /// 0,80 e non 1: senza, l'app sovrastima la scorta di un quarto (F5.2).
  lpg('lpg', defaultUnitKey: FuelUnits.liters, defaultUsableFraction: 0.80, usesTank: true),
  diesel('diesel', defaultUnitKey: FuelUnits.liters, usesTank: true),
  wood('wood', defaultUnitKey: FuelUnits.quintals),
  biomass('biomass', defaultUnitKey: FuelUnits.kg);

  const FuelType(
    this.key, {
    required this.defaultUnitKey,
    this.defaultUsableFraction = 1.0,
    this.usesTank = false,
  });

  /// Valore stabile salvato nel database.
  final String key;

  /// L'unita' proposta dal wizard (F5.5) quando l'utente sceglie questo combustibile.
  final String defaultUnitKey;

  /// Default di `fuel_sources.usableFraction` (F5.2): 0,80 per `lpg`, 1,0 per gli altri.
  final double defaultUsableFraction;

  /// Se ha un serbatoio con capacita' e manometro: solo allora il wizard chiede capacita' e
  /// frazione utile, e l'aggiornamento della scorta offre lo switch quantita'/percentuale
  /// (F5.5, F5.7).
  final bool usesTank;

  /// Default di `fuel_sources.warningDays` (F5.2): giorni di anticipo del riordino.
  static const int defaultWarningDays = 7;

  /// Il combustibile salvato con [key]; null se la chiave e' sconosciuta (dato corrotto, o
  /// scritto da una versione futura dell'app).
  static FuelType? byKey(String? key) {
    for (final t in values) {
      if (t.key == key) return t;
    }
    return null;
  }
}

/// Un'unita' di misura della scorta (F5.4).
///
/// ⚑ Rispetto alla firma del piano mancano `label` e `shortLabel` **di proposito**: niente
/// stringhe localizzate nel dominio. "sacchi"/"bags" e "sacchi"/"sacco" (plurali) li risolve
/// la UI dagli ARB con la chiave (`unit_<key>`, vedi `unitName` in lib/app/labels.dart); una stringa
/// italiana fissa qui finirebbe tale e quale nell'app inglese.
@immutable
class FuelUnit {
  const FuelUnit({required this.key, required this.decimals, required this.supportsWeight});

  /// Chiave stabile, salvata in `fuel_sources.unit`. **Non si rinomina mai.**
  final String key;

  /// Cifre decimali con cui la UI mostra una quantita' in questa unita'. E' solo
  /// presentazione: i calcoli usano sempre il double pieno.
  final int decimals;

  /// Se ha senso chiedere "quanto pesa uno?" (`fuel_sources.unitWeightKg`): vero per i
  /// contenitori discreti (sacco, bancale, cassetta), falso per le unita' che sono gia' un
  /// peso, un volume o una percentuale.
  ///
  /// ⚑ Lo stero e' falso anche se e' un "contenitore": un metro stero di faggio e uno di
  /// abete pesano diversamente e l'umidita' cambia tutto (F5.4). Un peso medio chiesto
  /// all'utente sembrerebbe un dato e sarebbe una supposizione.
  final bool supportsWeight;

  @override
  bool operator ==(Object other) =>
      other is FuelUnit &&
      other.key == key &&
      other.decimals == decimals &&
      other.supportsWeight == supportsWeight;

  @override
  int get hashCode => Object.hash(key, decimals, supportsWeight);

  @override
  String toString() => 'FuelUnit($key)';
}

/// Il catalogo delle unita' e quali valgono per ogni combustibile (F5.4).
abstract final class FuelUnits {
  static const String bags = 'bags';
  static const String kg = 'kg';
  static const String pallets = 'pallets';
  static const String liters = 'liters';
  static const String percent = 'percent';
  static const String quintals = 'quintals';
  static const String steres = 'steres';
  static const String crates = 'crates';

  /// Tutte le unita', una sola volta ciascuna.
  ///
  /// I decimali: i sacchi con un decimale (si apre un sacco, ne resta mezzo), i bancali con
  /// due (un bancale da 72 sacchi si consuma a frazioni piccole), litri, chili, cassette e
  /// percentuale interi (nessun manometro legge i decimali), quintali e steri con uno.
  static const List<FuelUnit> all = <FuelUnit>[
    FuelUnit(key: bags, decimals: 1, supportsWeight: true),
    FuelUnit(key: kg, decimals: 0, supportsWeight: false),
    FuelUnit(key: pallets, decimals: 2, supportsWeight: true),
    FuelUnit(key: liters, decimals: 0, supportsWeight: false),
    FuelUnit(key: percent, decimals: 0, supportsWeight: false),
    FuelUnit(key: quintals, decimals: 1, supportsWeight: false),
    FuelUnit(key: steres, decimals: 1, supportsWeight: false),
    FuelUnit(key: crates, decimals: 0, supportsWeight: true),
  ];

  /// Le unita' ammesse per tipo, nell'ordine in cui le propone il wizard: la prima e' la
  /// predefinita ([FuelType.defaultUnitKey]).
  ///
  /// ⚑ `percent` per GPL e gasolio: chi ha solo il manometro e non vuole conti tiene la
  /// scorta direttamente in percentuale. Si consuma "2% al giorno" e la stima funziona
  /// uguale (vedi `QuantityConverter`).
  static const Map<FuelType, List<String>> _keysByType = <FuelType, List<String>>{
    FuelType.pellet: <String>[bags, kg, pallets],
    FuelType.lpg: <String>[liters, percent],
    FuelType.diesel: <String>[liters, percent],
    FuelType.wood: <String>[quintals, steres, crates, kg],
    FuelType.biomass: <String>[kg, quintals, bags],
  };

  static List<FuelUnit> forType(FuelType type) =>
      _keysByType[type]!.map(byKey).toList(growable: false);

  /// Se [unitKey] e' ammessa per [type]: il data layer lo controlla prima di salvare.
  static bool isAllowed(FuelType type, String unitKey) => _keysByType[type]!.contains(unitKey);

  /// L'unita' predefinita del combustibile.
  static FuelUnit defaultFor(FuelType type) => byKey(type.defaultUnitKey);

  /// L'unita' con chiave [key].
  ///
  /// ☠ Lancia [ArgumentError] su una chiave sconosciuta invece di ripiegare in silenzio su
  /// un'altra unita': mostrare "12 litri" per 12 sacchi e' peggio di un errore visibile.
  /// Per i dati che arrivano da fuori (backup) usare [tryByKey].
  static FuelUnit byKey(String key) =>
      tryByKey(key) ?? (throw ArgumentError.value(key, 'key', 'Unita\' sconosciuta'));

  static FuelUnit? tryByKey(String? key) {
    for (final u in all) {
      if (u.key == key) return u;
    }
    return null;
  }
}
