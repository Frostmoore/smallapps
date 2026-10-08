import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:scorte_calore/app/feature_limits.dart';
import 'package:scorte_calore/app/paywall_config.dart';
import 'package:scorte_calore/l10n/generated/app_localizations.dart';

/// Il Pro di Scorte Calore (F5.0: notifiche Pro, widget gratis, 2,99 €).
void main() {
  test('ogni funzione bloccata e nel paywall, e il paywall non promette altro', () {
    // ☠ Trappola gia' pagata in TrashCan: un beneficio senza blocco promette una cosa che
    // l'utente ha gia'; un blocco senza beneficio e' una funzione a pagamento che nessuno
    // gli ha detto.
    final locked = {
      for (final e in scorteFeatureLimits.entries)
        if (e.value.isLockedForFree || e.value.freeMax != null) e.key,
    };
    for (final locale in const [Locale('it'), Locale('en')]) {
      final benefits = buildScortePaywall(lookupL(locale)).benefits.map((b) => b.key).toSet();
      expect(benefits, locked, reason: 'lingua $locale');
    }
  });

  test('ogni chiave e dichiarata: nessuna funzione resta nel dubbio', () {
    expect(scorteFeatureLimits.keys.toSet(), FeatureKey.values.toSet());
  });

  group('il piano gratuito', () {
    final gratis = FeatureGate(limits: scorteFeatureLimits, isPro: false);
    final pro = FeatureGate(limits: scorteFeatureLimits, isPro: true);

    test('una fonte si, la seconda solo con il Pro', () {
      expect(gratis.withinLimit(FeatureKey.unlimitedEntities, 0), isTrue);
      expect(gratis.withinLimit(FeatureKey.unlimitedEntities, 1), isFalse);
      expect(pro.withinLimit(FeatureKey.unlimitedEntities, 5), isTrue);
    });

    test('il widget e gratis (ADR-019)', () {
      expect(gratis.allows(FeatureKey.advancedWidget), isTrue);
    });

    test('notifiche, statistiche, calendario, CSV e backup sono Pro', () {
      for (final k in const [
        FeatureKey.notifications,
        FeatureKey.statistics,
        FeatureKey.calendarSync,
        FeatureKey.csvExport,
        FeatureKey.backupRestore,
      ]) {
        expect(gratis.allows(k), isFalse, reason: '$k');
        expect(pro.allows(k), isTrue, reason: '$k');
      }
    });
  });
}
