import 'package:meta/meta.dart';
import 'package:micro_core/micro_core.dart';

/// Le statistiche per anno solare (develop_microapps.md F6.10, Pro). Dart puro: niente
/// Flutter, niente Drift. Il repository prepara gli ingressi (`FilmRepository.statsRolls`).
///
/// ⚑ Tutto in **centesimi interi**, come nel database: sommare euro in `double` porta a
/// 419,99999 dopo dieci rullini. Le sole divisioni sono le medie: quella per rullino si
/// arrotonda al centesimo, quella per fotogramma resta `double` (un fotogramma da 0,347 € e'
/// un dato vero) e la arrotonda chi la mostra.
///
/// ⚑ **Un rullino appartiene all'anno della sua data** ([StatsRoll.date]: caricamento, o
/// creazione se manca), **con tutti i suoi costi**: anche lo sviluppo pagato a gennaio di un
/// rullino caricato a dicembre. Dividere i costi per data dell'evento renderebbe il costo
/// medio per rullino privo di senso (rullini di un anno, sviluppi di un altro).

/// Lo sviluppo di un rullino, per le statistiche.
@immutable
class StatsDevelopment {
  const StatsDevelopment({
    this.laboratory,
    this.developmentCostCents,
    this.scanCostCents,
    this.selfDeveloped = false,
  });

  final String? laboratory;
  final int? developmentCostCents;
  final int? scanCostCents;

  /// Sviluppo in casa: il "laboratorio" non conta fra i laboratori piu' usati.
  final bool selfDeveloped;
}

/// Un ordine di stampa, per le statistiche.
@immutable
class StatsPrint {
  const StatsPrint({this.laboratory, this.costCents});

  final String? laboratory;
  final int? costCents;
}

/// Un rullino con i suoi eventi, per le statistiche.
@immutable
class StatsRoll {
  const StatsRoll({
    required this.date,
    required this.frames,
    required this.filmName,
    this.cameraId,
    this.costCents,
    this.development,
    this.prints = const [],
  });

  /// La data che decide anno e mese: `loadedAt`, o il giorno di creazione se manca.
  final CivilDate date;

  /// Fotogrammi **nominali** (36, 24, 12...).
  final int frames;

  /// L'emulsione, denormalizzata (`film_rolls.filmName`).
  final String filmName;

  final int? cameraId;

  /// Costo della pellicola.
  final int? costCents;

  final StatsDevelopment? development;
  final List<StatsPrint> prints;

  /// Se almeno un costo e' stato scritto: solo questi rullini entrano nelle medie.
  bool get hasAnyCost =>
      costCents != null ||
      development?.developmentCostCents != null ||
      development?.scanCostCents != null ||
      prints.any((p) => p.costCents != null);
}

/// Un nome (laboratorio, emulsione) con quante volte compare.
@immutable
class RankedName {
  const RankedName(this.name, this.count);

  final String name;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is RankedName && other.name == name && other.count == count;

  @override
  int get hashCode => Object.hash(name, count);

  @override
  String toString() => 'RankedName($name, $count)';
}

/// Le statistiche di un anno.
@immutable
class YearStats {
  const YearStats({
    required this.year,
    required this.rollCount,
    required this.potentialFrames,
    required this.filmCents,
    required this.developmentCents,
    required this.scanCents,
    required this.printCents,
    required this.costedRollCount,
    required this.costedFrames,
    required this.rollsPerMonth,
    this.topLaboratory,
    this.topEmulsion,
    this.topCameraId,
    this.topCameraRolls = 0,
    this.selfDevelopedCount = 0,
  });

  final int year;

  final int rollCount;

  /// Somma dei fotogrammi nominali: quanti se ne **potevano** scattare.
  final int potentialFrames;

  /// Spesa in pellicola (`film_rolls.costCents`).
  final int filmCents;

  /// Spesa in sviluppo (`developments.developmentCostCents`).
  final int developmentCents;

  /// Spesa in scansioni (`developments.scanCostCents`).
  final int scanCents;

  /// Spesa in stampe (`print_orders.costCents`).
  final int printCents;

  /// I rullini con almeno un costo scritto, e i loro fotogrammi nominali: la base delle
  /// medie.
  ///
  /// ⚑ Un rullino senza nessun costo (regalato, scontrino perso, dati non ancora inseriti)
  /// abbasserebbe la media a torto: stessa regola del costo medio di Scorte Calore.
  final int costedRollCount;
  final int costedFrames;

  /// Dodici interi, gennaio in posizione 0: il grafico a barre di F6.10.
  final List<int> rollsPerMonth;

  /// Il laboratorio con piu' sviluppi e ordini di stampa nell'anno (in casa escluso).
  final RankedName? topLaboratory;

  /// L'emulsione con piu' rullini.
  final RankedName? topEmulsion;

  /// La macchina con piu' rullini (il nome lo risolve la UI dall'id), e quanti.
  final int? topCameraId;
  final int topCameraRolls;

  /// Rullini sviluppati in casa.
  final int selfDevelopedCount;

  int get totalCents => filmCents + developmentCents + scanCents + printCents;

  /// Costo medio per rullino, al centesimo; null se nessun rullino ha costi.
  int? get averageCentsPerRoll =>
      costedRollCount == 0 ? null : (totalCents / costedRollCount).round();

  /// Costo medio per fotogramma, in centesimi, sui fotogrammi **nominali**.
  ///
  /// ☠ E' una **stima** e la UI deve dirlo (F6.10): non tutti i fotogrammi vengono scattati
  /// o riescono. Presentarla come dato esatto sarebbe falso.
  double? get estimatedCentsPerFrame => costedFrames == 0 ? null : totalCents / costedFrames;

  bool get isEmpty => rollCount == 0;
}

/// Il motore delle statistiche.
class FilmStatsCalculator {
  const FilmStatsCalculator();

  /// Gli anni che hanno almeno un rullino, dal piu' recente: il selettore della pagina.
  List<int> years(Iterable<StatsRoll> rolls) {
    final ys = {for (final r in rolls) r.date.year}.toList()..sort((a, b) => b.compareTo(a));
    return ys;
  }

  /// Le statistiche dell'anno [year]. Su un anno senza rullini restituisce tutto a zero
  /// (con [YearStats.isEmpty] vero), mai null: la pagina mostra lo stato vuoto da li'.
  YearStats forYear(int year, Iterable<StatsRoll> rolls) {
    final mine = rolls.where((r) => r.date.year == year).toList();
    var frames = 0, film = 0, dev = 0, scan = 0, prints = 0, costed = 0, costedFrames = 0;
    var self = 0;
    final perMonth = List<int>.filled(12, 0);
    final labs = _Counter();
    final emulsions = _Counter();
    final cameras = <int, int>{};

    for (final r in mine) {
      frames += r.frames;
      perMonth[r.date.month - 1]++;
      film += r.costCents ?? 0;
      final d = r.development;
      if (d != null) {
        dev += d.developmentCostCents ?? 0;
        scan += d.scanCostCents ?? 0;
        if (d.selfDeveloped) {
          self++;
        } else {
          labs.add(d.laboratory);
        }
      }
      for (final p in r.prints) {
        prints += p.costCents ?? 0;
        labs.add(p.laboratory);
      }
      if (r.hasAnyCost) {
        costed++;
        costedFrames += r.frames;
      }
      emulsions.add(r.filmName);
      if (r.cameraId != null) cameras[r.cameraId!] = (cameras[r.cameraId!] ?? 0) + 1;
    }

    int? topCamera;
    var topCameraRolls = 0;
    for (final e in cameras.entries) {
      // A parita' vince l'id piu' basso: la macchina registrata prima. Deterministico.
      if (e.value > topCameraRolls || (e.value == topCameraRolls && e.key < topCamera!)) {
        topCamera = e.key;
        topCameraRolls = e.value;
      }
    }

    return YearStats(
      year: year,
      rollCount: mine.length,
      potentialFrames: frames,
      filmCents: film,
      developmentCents: dev,
      scanCents: scan,
      printCents: prints,
      costedRollCount: costed,
      costedFrames: costedFrames,
      rollsPerMonth: List.unmodifiable(perMonth),
      topLaboratory: labs.top(),
      topEmulsion: emulsions.top(),
      topCameraId: topCamera,
      topCameraRolls: topCameraRolls,
      selfDevelopedCount: self,
    );
  }
}

/// Conta nomi digitati a mano senza farsi ingannare da maiuscole e spazi ("Fotoservice " e
/// "fotoservice" sono lo stesso laboratorio). Mostra la grafia vista per prima.
class _Counter {
  final Map<String, int> _counts = {};
  final Map<String, String> _display = {};

  void add(String? raw) {
    final name = raw?.trim();
    if (name == null || name.isEmpty) return;
    final key = name.toLowerCase();
    _counts[key] = (_counts[key] ?? 0) + 1;
    _display.putIfAbsent(key, () => name);
  }

  /// Il piu' frequente; a parita', il primo in ordine alfabetico. Null se vuoto.
  RankedName? top() {
    String? best;
    for (final key in _counts.keys) {
      if (best == null ||
          _counts[key]! > _counts[best]! ||
          (_counts[key] == _counts[best] && key.compareTo(best) < 0)) {
        best = key;
      }
    }
    return best == null ? null : RankedName(_display[best]!, _counts[best]!);
  }
}
