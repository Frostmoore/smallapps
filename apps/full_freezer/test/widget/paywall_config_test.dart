import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:full_freezer/app/feature_limits.dart';
import 'package:full_freezer/app/paywall_config.dart';
import 'package:full_freezer/l10n/generated/app_localizations.dart';
import 'package:micro_core/micro_core.dart';

/// F4.10: il Pro di Full Freezer.
void main() {
  test('ogni funzione bloccata e nel paywall, e il paywall non promette altro', () {
    // ☠ Trappola gia' pagata in TrashCan: un beneficio senza blocco promette una cosa che
    // l'utente ha gia'; un blocco senza beneficio e' una funzione a pagamento che nessuno
    // gli ha detto.
    final locked = {
      for (final e in freezerFeatureLimits.entries)
        if (e.value.isLockedForFree || e.value.freeMax != null) e.key,
    };
    for (final locale in const [Locale('it'), Locale('en')]) {
      final benefits = buildFreezerPaywall(lookupL(locale)).benefits.map((b) => b.key).toSet();
      expect(benefits, locked, reason: 'lingua $locale');
    }
  });

  test('ogni chiave e dichiarata: nessuna funzione resta nel dubbio', () {
    expect(freezerFeatureLimits.keys.toSet(), FeatureKey.values.toSet());
  });

  group('il piano gratuito', () {
    final gratis = FeatureGate(limits: freezerFeatureLimits, isPro: false);
    final pro = FeatureGate(limits: freezerFeatureLimits, isPro: true);

    test('un freezer si', () {
      expect(gratis.withinLimit(FeatureKey.unlimitedEntities, 0), isTrue);
    });

    test('il secondo freezer no, con il Pro si', () {
      expect(gratis.withinLimit(FeatureKey.unlimitedEntities, 1), isFalse);
      expect(pro.withinLimit(FeatureKey.unlimitedEntities, 7), isTrue);
    });

    test('foto, scomparti e widget sono gratis (decisioni del 2026-10-06)', () {
      expect(gratis.allows(FeatureKey.photos), isTrue);
      expect(gratis.withinLimit(FeatureKey.secondaryEntities, 50), isTrue);
      expect(gratis.allows(FeatureKey.advancedWidget), isTrue);
    });

    test('notifiche, storico, statistiche, CSV, backup e categorie sono Pro', () {
      for (final k in const [
        FeatureKey.notifications,
        FeatureKey.fullHistory,
        FeatureKey.statistics,
        FeatureKey.csvExport,
        FeatureKey.backupRestore,
        FeatureKey.customCategories,
      ]) {
        expect(gratis.allows(k), isFalse, reason: '$k');
        expect(pro.allows(k), isTrue, reason: '$k');
      }
    });
  });
}
