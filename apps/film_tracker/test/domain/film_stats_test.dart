import 'package:film_tracker/domain/film_stats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';

/// F6.10: le aggregazioni per anno su un dataset noto, calcolato a mano.
void main() {
  const calc = FilmStatsCalculator();
  CivilDate d(String iso) => CivilDate.parse(iso);

  // Il dataset. Anno 2026: cinque rullini; 2025: uno; 2024: uno.
  final rolls = <StatsRoll>[
    // 1. Gennaio, macchina 1, Portra 400, 36 pose. Pellicola 1890, sviluppo 1200 + scan 800
    //    a "Fotoservice", due stampe da 1450 e 900 a "Fotoservice " e "Labo".
    StatsRoll(
      date: d('2026-01-10'),
      frames: 36,
      filmName: 'Kodak Portra 400',
      cameraId: 1,
      costCents: 1890,
      development: const StatsDevelopment(
        laboratory: 'Fotoservice',
        developmentCostCents: 1200,
        scanCostCents: 800,
      ),
      prints: const [
        StatsPrint(laboratory: 'fotoservice ', costCents: 1450),
        StatsPrint(laboratory: 'Labo', costCents: 900),
      ],
    ),
    // 2. Gennaio, macchina 2, HP5+, sviluppato in casa (300), nessuna scansione.
    StatsRoll(
      date: d('2026-01-25'),
      frames: 36,
      filmName: 'Ilford HP5+',
      cameraId: 2,
      costCents: 1050,
      development: const StatsDevelopment(
        laboratory: 'Casa',
        developmentCostCents: 300,
        selfDeveloped: true,
      ),
    ),
    // 3. Marzo, macchina 1, Portra 400 in 120 (12 pose), sviluppo 1500 a "Labo".
    StatsRoll(
      date: d('2026-03-03'),
      frames: 12,
      filmName: 'kodak portra 400',
      cameraId: 1,
      costCents: 1400,
      development: const StatsDevelopment(laboratory: 'Labo', developmentCostCents: 1500),
    ),
    // 4. Agosto, nessuna macchina, nessun costo: regalato e non ancora sviluppato.
    StatsRoll(date: d('2026-08-15'), frames: 24, filmName: 'Kodak Gold 200'),
    // 5. Dicembre, macchina 2, Tri-X, sviluppo senza costo a "Labo".
    StatsRoll(
      date: d('2026-12-31'),
      frames: 36,
      filmName: 'Kodak Tri-X 400',
      cameraId: 2,
      costCents: 1290,
      development: const StatsDevelopment(laboratory: 'Labo'),
    ),
    // Fuori anno: il 31 dicembre 2025 e il 2024.
    StatsRoll(date: d('2025-12-31'), frames: 36, filmName: 'Kodak Ektar 100', costCents: 99999),
    StatsRoll(date: d('2024-06-01'), frames: 36, filmName: 'Kodak Ektar 100'),
  ];

  group('forYear(2026)', () {
    final s = calc.forYear(2026, rolls);

    test('rullini e fotogrammi potenziali', () {
      expect(s.rollCount, 5);
      expect(s.potentialFrames, 36 + 36 + 12 + 24 + 36);
      expect(s.isEmpty, isFalse);
    });

    test('la spesa divisa per voce e il totale, in centesimi', () {
      expect(s.filmCents, 1890 + 1050 + 1400 + 1290);
      expect(s.developmentCents, 1200 + 300 + 1500);
      expect(s.scanCents, 800);
      expect(s.printCents, 1450 + 900);
      expect(s.totalCents, 5630 + 3000 + 800 + 2350);
    });

    test('le medie contano solo i rullini con almeno un costo', () {
      // Il rullino 4 (regalato) non ha costi: entra nei conteggi ma non nelle medie.
      expect(s.costedRollCount, 4);
      expect(s.costedFrames, 36 + 36 + 12 + 36);
      expect(s.averageCentsPerRoll, (11780 / 4).round());
      expect(s.estimatedCentsPerFrame, closeTo(11780 / 120, 1e-9));
    });

    test('il laboratorio piu\' usato ignora maiuscole e spazi e lo sviluppo in casa', () {
      // Labo: stampa del 1, sviluppo del 3, sviluppo del 5 = 3. Fotoservice: 2. Casa: 0.
      expect(s.topLaboratory, const RankedName('Labo', 3));
      expect(s.selfDevelopedCount, 1);
    });

    test('l\'emulsione piu\' usata, con la grafia vista per prima', () {
      expect(s.topEmulsion, const RankedName('Kodak Portra 400', 2));
    });

    test('la macchina piu\' usata: a parita\' vince l\'id piu\' basso', () {
      expect(s.topCameraId, 1);
      expect(s.topCameraRolls, 2);
    });

    test('rullini per mese, gennaio in posizione 0', () {
      expect(s.rollsPerMonth, [2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1]);
    });
  });

  test('il 31 dicembre appartiene al suo anno, non al successivo', () {
    final s = calc.forYear(2025, rolls);
    expect(s.rollCount, 1);
    expect(s.totalCents, 99999);
    expect(s.rollsPerMonth[11], 1);
  });

  test('un anno senza costi ha le medie null, non zero', () {
    final s = calc.forYear(2024, rolls);
    expect(s.rollCount, 1);
    expect(s.costedRollCount, 0);
    expect(s.averageCentsPerRoll, isNull);
    expect(s.estimatedCentsPerFrame, isNull);
    expect(s.topLaboratory, isNull);
    expect(s.topCameraId, isNull);
    expect(s.topEmulsion, const RankedName('Kodak Ektar 100', 1));
  });

  test('un anno vuoto e\' tutto a zero, mai null', () {
    final s = calc.forYear(2030, rolls);
    expect(s.isEmpty, isTrue);
    expect(s.totalCents, 0);
    expect(s.rollsPerMonth, List.filled(12, 0));
    expect(s.topEmulsion, isNull);
  });

  test('years: gli anni con rullini, dal piu\' recente', () {
    expect(calc.years(rolls), [2026, 2025, 2024]);
    expect(calc.years(const []), isEmpty);
  });
}
