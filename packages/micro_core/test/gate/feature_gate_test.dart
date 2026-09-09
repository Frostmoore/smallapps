import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';

/// Mappa di prova che contiene una funzione per ciascuna delle tre forme di limite.
const FeatureLimits limits = <FeatureKey, FeatureLimit>{
  FeatureKey.unlimitedEntities: FeatureLimit.count(freeMax: 1),
  FeatureKey.secondaryEntities: FeatureLimit.count(freeMax: 3),
  FeatureKey.statistics: FeatureLimit.locked(),
  FeatureKey.backupRestore: FeatureLimit.locked(),
  FeatureKey.photos: FeatureLimit.open(),
};

void main() {
  const free = FeatureGate(limits: limits, isPro: false);
  const pro = FeatureGate(limits: limits, isPro: true);

  group('funzioni sempre aperte', () {
    test('disponibili con e senza Pro', () {
      expect(free.allows(FeatureKey.photos), isTrue);
      expect(pro.allows(FeatureKey.photos), isTrue);
      expect(free.check(FeatureKey.photos), isA<GateAllowed>());
    });

    test('non hanno tetto', () {
      expect(free.withinLimit(FeatureKey.photos, 9999), isTrue);
      expect(free.remaining(FeatureKey.photos, 9999), isNull);
      expect(free.freeLimitOf(FeatureKey.photos), isNull);
    });
  });

  group('funzioni solo Pro', () {
    test('bloccate senza Pro, con motivo proOnly', () {
      expect(free.allows(FeatureKey.statistics), isFalse);
      final verdict = free.check(FeatureKey.statistics);
      expect(verdict, isA<GateBlocked>());
      expect((verdict as GateBlocked).reason, BlockReason.proOnly);
      expect(verdict.key, FeatureKey.statistics);
    });

    test('aperte con Pro', () {
      expect(pro.allows(FeatureKey.statistics), isTrue);
      expect(pro.check(FeatureKey.statistics), isA<GateAllowed>());
      expect(pro.withinLimit(FeatureKey.statistics, 100), isTrue);
    });

    test('il conteggio non le sblocca', () {
      expect(free.withinLimit(FeatureKey.statistics, 0), isFalse);
      expect(free.remaining(FeatureKey.statistics, 0), 0);
    });
  });

  group('funzioni a quantita: i bordi del tetto', () {
    // Il tetto e' 1: l'utente gratuito puo' averne uno, non due.
    test('con zero elementi puo aggiungerne', () {
      expect(free.withinLimit(FeatureKey.unlimitedEntities, 0), isTrue);
      expect(free.check(FeatureKey.unlimitedEntities, currentCount: 0), isA<GateAllowed>());
      expect(free.remaining(FeatureKey.unlimitedEntities, 0), 1);
    });

    test('raggiunto il tetto non puo aggiungerne', () {
      expect(free.withinLimit(FeatureKey.unlimitedEntities, 1), isFalse);
      final verdict = free.check(FeatureKey.unlimitedEntities, currentCount: 1);
      expect(verdict, isA<GateBlocked>());
      expect((verdict as GateBlocked).reason, BlockReason.limitReached);
      expect(verdict.freeMax, 1);
      expect(free.remaining(FeatureKey.unlimitedEntities, 1), 0);
    });

    test('oltre il tetto resta bloccato e remaining non va sotto zero', () {
      expect(free.withinLimit(FeatureKey.unlimitedEntities, 5), isFalse);
      expect(free.remaining(FeatureKey.unlimitedEntities, 5), 0);
    });

    test('tetto a 3: i quattro bordi', () {
      const key = FeatureKey.secondaryEntities;
      expect(free.withinLimit(key, 0), isTrue, reason: 'nessuno');
      expect(free.withinLimit(key, 2), isTrue, reason: 'freeMax - 1');
      expect(free.withinLimit(key, 3), isFalse, reason: 'freeMax esatto');
      expect(free.withinLimit(key, 4), isFalse, reason: 'oltre il tetto');
      expect(free.remaining(key, 0), 3);
      expect(free.remaining(key, 2), 1);
      expect(free.remaining(key, 3), 0);
    });

    test('la funzione resta accessibile anche se il tetto e raggiunto', () {
      // allows() dice "puoi usarla", withinLimit() dice "puoi aggiungerne un'altra".
      // Un utente gratuito con un calendario pieno usa comunque quel calendario.
      expect(free.allows(FeatureKey.unlimitedEntities), isTrue);
      expect(free.withinLimit(FeatureKey.unlimitedEntities, 1), isFalse);
    });

    test('con Pro il tetto non esiste', () {
      expect(pro.withinLimit(FeatureKey.unlimitedEntities, 0), isTrue);
      expect(pro.withinLimit(FeatureKey.unlimitedEntities, 1), isTrue);
      expect(pro.withinLimit(FeatureKey.unlimitedEntities, 10000), isTrue);
      expect(pro.remaining(FeatureKey.unlimitedEntities, 10000), isNull);
      expect(pro.check(FeatureKey.unlimitedEntities, currentCount: 10000), isA<GateAllowed>());
    });
  });

  group('elenchi per il paywall', () {
    test('proOnlyFeatures elenca solo le bloccate', () {
      expect(free.proOnlyFeatures.toSet(), {FeatureKey.statistics, FeatureKey.backupRestore});
    });

    test('limitedFeatures elenca solo quelle a quantita', () {
      expect(free.limitedFeatures.toSet(), {
        FeatureKey.unlimitedEntities,
        FeatureKey.secondaryEntities,
      });
    });

    test('gli elenchi non dipendono dallo stato Pro', () {
      expect(pro.proOnlyFeatures, free.proOnlyFeatures);
      expect(pro.limitedFeatures, free.limitedFeatures);
    });
  });

  group('cancello senza limiti', () {
    test('unlimited lascia passare tutto', () {
      const gate = FeatureGate.unlimited();
      for (final key in FeatureKey.values) {
        expect(gate.allows(key), isTrue, reason: key.name);
        expect(gate.withinLimit(key, 99999), isTrue, reason: key.name);
        expect(gate.check(key, currentCount: 99999), isA<GateAllowed>(), reason: key.name);
      }
    });
  });

  group('copyWith', () {
    test('cambia solo lo stato Pro', () {
      final upgraded = free.copyWith(isPro: true);
      expect(upgraded.isPro, isTrue);
      expect(upgraded.limits, same(free.limits));
      expect(upgraded.check(FeatureKey.statistics), isA<GateAllowed>());
      expect(
        free.check(FeatureKey.statistics),
        isA<GateBlocked>(),
        reason: 'l originale non cambia',
      );
    });
  });

  group('forme di FeatureLimit', () {
    test('locked', () {
      const limit = FeatureLimit.locked();
      expect(limit.isLockedForFree, isTrue);
      expect(limit.isCounted, isFalse);
      expect(limit.isOpen, isFalse);
      expect(limit.freeMax, 0);
    });

    test('count', () {
      const limit = FeatureLimit.count(freeMax: 5);
      expect(limit.isLockedForFree, isFalse);
      expect(limit.isCounted, isTrue);
      expect(limit.isOpen, isFalse);
      expect(limit.freeMax, 5);
    });

    test('open', () {
      const limit = FeatureLimit.open();
      expect(limit.isLockedForFree, isFalse);
      expect(limit.isCounted, isFalse);
      expect(limit.isOpen, isTrue);
      expect(limit.freeMax, isNull);
    });

    test('uguaglianza per valore', () {
      expect(const FeatureLimit.count(freeMax: 3), const FeatureLimit.count(freeMax: 3));
      expect(const FeatureLimit.count(freeMax: 3), isNot(const FeatureLimit.count(freeMax: 4)));
      expect(const FeatureLimit.locked(), isNot(const FeatureLimit.open()));
    });
  });
}
