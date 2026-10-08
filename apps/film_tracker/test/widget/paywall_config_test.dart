import 'package:film_tracker/app/feature_limits.dart';
import 'package:film_tracker/app/paywall_config.dart';
import 'package:film_tracker/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';

/// Il Pro di Film Tracker (F6.0: foto gratis, una macchina gratis, 4,99 €).
void main() {
  test('ogni funzione bloccata e nel paywall, e il paywall non promette altro', () {
    // ☠ Trappola gia' pagata in TrashCan: un beneficio senza blocco promette una cosa che
    // l'utente ha gia'; un blocco senza beneficio e' una funzione a pagamento che nessuno
    // gli ha detto.
    final locked = {
      for (final e in filmFeatureLimits.entries)
        if (e.value.isLockedForFree || e.value.freeMax != null) e.key,
    };
    for (final locale in const [Locale('it'), Locale('en')]) {
      final benefits = buildFilmPaywall(lookupL(locale)).benefits.map((b) => b.key).toSet();
      expect(benefits, locked, reason: 'lingua $locale');
    }
  });

  test('ogni chiave e dichiarata: nessuna funzione resta nel dubbio', () {
    expect(filmFeatureLimits.keys.toSet(), FeatureKey.values.toSet());
  });

  group('il piano gratuito', () {
    final gratis = FeatureGate(limits: filmFeatureLimits, isPro: false);
    final pro = FeatureGate(limits: filmFeatureLimits, isPro: true);

    test('una macchina si, la seconda solo con il Pro', () {
      expect(gratis.withinLimit(FeatureKey.secondaryEntities, 0), isTrue);
      expect(gratis.withinLimit(FeatureKey.secondaryEntities, 1), isFalse);
      expect(pro.withinLimit(FeatureKey.secondaryEntities, 6), isTrue);
    });

    test('foto e rullini sono gratis (F6.0 punto 3)', () {
      expect(gratis.allows(FeatureKey.photos), isTrue);
      expect(gratis.withinLimit(FeatureKey.unlimitedEntities, 500), isTrue);
    });

    test('statistiche, PDF, CSV e backup sono Pro', () {
      for (final k in const [FeatureKey.statistics, FeatureKey.pdfReport, FeatureKey.csvExport, FeatureKey.backupRestore]) {
        expect(gratis.allows(k), isFalse, reason: '$k');
        expect(pro.allows(k), isTrue, reason: '$k');
      }
    });
  });
}
