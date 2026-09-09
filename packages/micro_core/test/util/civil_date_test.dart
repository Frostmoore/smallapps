import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';

void main() {
  group('parse e serializzazione', () {
    test('round-trip ISO', () {
      const iso = '2026-09-09';
      expect(CivilDate.parse(iso).toIso(), iso);
    });

    test('tryParse rifiuta formati non canonici', () {
      expect(CivilDate.tryParse(null), isNull);
      expect(CivilDate.tryParse(''), isNull);
      expect(CivilDate.tryParse('2026-9-9'), isNull, reason: 'niente zero padding');
      expect(CivilDate.tryParse('09/09/2026'), isNull);
      expect(CivilDate.tryParse('2026-13-01'), isNull, reason: 'mese inesistente');
      expect(CivilDate.tryParse('2026-02-30'), isNull, reason: 'giorno inesistente');
      expect(CivilDate.tryParse('2026-02-29'), isNull, reason: '2026 non e bisestile');
      expect(CivilDate.tryParse('2024-02-29'), isNotNull, reason: '2024 e bisestile');
    });

    test('parse lancia su input non valido', () {
      expect(() => CivilDate.parse('non-una-data'), throwsFormatException);
    });

    test('toString coincide con toIso', () {
      final d = CivilDate(2026, 1, 5);
      expect(d.toString(), d.toIso());
      expect(d.toString(), '2026-01-05');
    });
  });

  group('ora legale (ADR-008)', () {
    // In Europa/Roma l'ora legale 2026 inizia domenica 29 marzo e finisce domenica
    // 25 ottobre. Una data civile non deve accorgersene in alcun modo.
    test('il giorno del passaggio a ora legale non slitta', () {
      final sabato = CivilDate(2026, 3, 28);
      final domenica = sabato.addDays(1);
      final lunedi = domenica.addDays(1);
      expect(domenica.toIso(), '2026-03-29');
      expect(lunedi.toIso(), '2026-03-30');
      expect(sabato.daysUntil(lunedi), 2);
    });

    test('il giorno del ritorno a ora solare non slitta', () {
      final sabato = CivilDate(2026, 10, 24);
      expect(sabato.addDays(1).toIso(), '2026-10-25');
      expect(sabato.addDays(2).toIso(), '2026-10-26');
    });

    test('attraversare entrambi i cambi conta i giorni giusti', () {
      final marzo = CivilDate(2026, 3, 1);
      final novembre = CivilDate(2026, 11, 1);
      expect(marzo.daysUntil(novembre), 245);
    });
  });

  group('aritmetica sui mesi', () {
    test('31 gennaio piu un mese fa 28 febbraio, non 3 marzo', () {
      expect(CivilDate(2026, 1, 31).addMonths(1).toIso(), '2026-02-28');
    });

    test('31 gennaio piu un mese in anno bisestile fa 29 febbraio', () {
      expect(CivilDate(2024, 1, 31).addMonths(1).toIso(), '2024-02-29');
    });

    test('31 marzo piu un mese fa 30 aprile', () {
      expect(CivilDate(2026, 3, 31).addMonths(1).toIso(), '2026-04-30');
    });

    test('il clamp non e permanente: si somma sempre alla data originale', () {
      // Trappola classica: sommare un mese alla volta a partire dal risultato gia'
      // clampato porta al 28 per sempre. Chi usa addMonths deve partire dall'origine.
      final gennaio = CivilDate(2026, 1, 31);
      expect(gennaio.addMonths(1).toIso(), '2026-02-28');
      expect(gennaio.addMonths(2).toIso(), '2026-03-31');
      expect(gennaio.addMonths(3).toIso(), '2026-04-30');
    });

    test('mesi negativi', () {
      expect(CivilDate(2026, 1, 15).addMonths(-1).toIso(), '2025-12-15');
      expect(CivilDate(2026, 3, 31).addMonths(-1).toIso(), '2026-02-28');
    });

    test('addYears clampa il 29 febbraio', () {
      expect(CivilDate(2024, 2, 29).addYears(1).toIso(), '2025-02-28');
      expect(CivilDate(2024, 2, 29).addYears(4).toIso(), '2028-02-29');
    });
  });

  group('anni bisestili', () {
    test('regola dei 400 anni', () {
      expect(CivilDate(2000, 2, 1).daysInMonth, 29, reason: '2000 divisibile per 400');
      expect(CivilDate(1900, 2, 1).daysInMonth, 28, reason: '1900 divisibile per 100 ma non 400');
      expect(CivilDate(2024, 2, 1).daysInMonth, 29);
      expect(CivilDate(2026, 2, 1).daysInMonth, 28);
    });
  });

  group('epochDay e ordinamento', () {
    test('epoch', () {
      expect(CivilDate(1970, 1, 1).epochDay, 0);
      expect(CivilDate(1970, 1, 2).epochDay, 1);
      expect(CivilDate(1969, 12, 31).epochDay, -1);
    });

    test('fromEpochDay e inverso di epochDay', () {
      for (final d in [
        CivilDate(1970, 1, 1),
        CivilDate(2026, 9, 9),
        CivilDate(2024, 2, 29),
        CivilDate(1999, 12, 31),
      ]) {
        expect(CivilDate.fromEpochDay(d.epochDay), d);
      }
    });

    test('ordinamento cronologico', () {
      final dates = [
        CivilDate(2026, 12, 1),
        CivilDate(2025, 1, 1),
        CivilDate(2026, 1, 2),
        CivilDate(2026, 1, 1),
      ]..sort();
      expect(dates.map((d) => d.toIso()).toList(), [
        '2025-01-01',
        '2026-01-01',
        '2026-01-02',
        '2026-12-01',
      ]);
    });

    test('confronti', () {
      final a = CivilDate(2026, 1, 1);
      final b = CivilDate(2026, 1, 2);
      expect(a.isBefore(b), isTrue);
      expect(b.isAfter(a), isTrue);
      expect(a.isSameOrBefore(a), isTrue);
      expect(a.isSameOrAfter(a), isTrue);
      expect(a.isBefore(a), isFalse);
    });
  });

  group('giorno della settimana', () {
    test('9 settembre 2026 e un mercoledi', () {
      expect(CivilDate(2026, 9, 9).weekday, DateTime.wednesday);
    });

    test('il weekday e stabile attraverso il cambio d ora', () {
      expect(CivilDate(2026, 3, 29).weekday, DateTime.sunday);
      expect(CivilDate(2026, 10, 25).weekday, DateTime.sunday);
    });
  });

  group('intervalli', () {
    test('rangeTo e inclusivo agli estremi', () {
      final range = CivilDate(2026, 1, 1).rangeTo(CivilDate(2026, 1, 4)).toList();
      expect(range.map((d) => d.day).toList(), [1, 2, 3, 4]);
    });

    test('rangeTo con fine precedente e vuoto', () {
      expect(CivilDate(2026, 1, 5).rangeTo(CivilDate(2026, 1, 1)), isEmpty);
    });

    test('rangeTo su un solo giorno', () {
      final d = CivilDate(2026, 1, 1);
      expect(d.rangeTo(d).toList(), [d]);
    });

    test('primo e ultimo del mese', () {
      final d = CivilDate(2026, 2, 14);
      expect(d.firstDayOfMonth.toIso(), '2026-02-01');
      expect(d.lastDayOfMonth.toIso(), '2026-02-28');
    });
  });

  group('costruzione da DateTime', () {
    test('un istante UTC viene letto nel fuso locale', () {
      final utc = DateTime.utc(2026, 9, 9, 23, 30);
      expect(CivilDate.fromDateTime(utc), CivilDate.fromDateTime(utc.toLocal()));
    });

    test('today accetta un presente fissato', () {
      final now = DateTime(2026, 9, 9, 14, 30);
      expect(CivilDate.today(now: now).toIso(), '2026-09-09');
      expect(CivilDate(2026, 9, 9).isToday(now: now), isTrue);
      expect(CivilDate(2026, 9, 10).isToday(now: now), isFalse);
    });
  });

  group('normalizzazione del costruttore', () {
    test('valori fuori intervallo si normalizzano come DateTime', () {
      expect(CivilDate(2026, 13, 1).toIso(), '2027-01-01');
      expect(CivilDate(2026, 1, 32).toIso(), '2026-02-01');
      expect(CivilDate(2026, 0, 1).toIso(), '2025-12-01');
    });
  });

  group('uguaglianza', () {
    test('due date uguali sono lo stesso valore', () {
      expect(CivilDate(2026, 9, 9), CivilDate.parse('2026-09-09'));
      expect(CivilDate(2026, 9, 9).hashCode, CivilDate.parse('2026-09-09').hashCode);
      expect(CivilDate(2026, 9, 9), isNot(CivilDate(2026, 9, 10)));
    });
  });
}
