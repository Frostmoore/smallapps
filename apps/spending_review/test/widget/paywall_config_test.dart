import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:spending_review/app/feature_limits.dart';
import 'package:spending_review/app/paywall_config.dart';
import 'package:spending_review/l10n/generated/app_localizations.dart';

/// Il Pro di Spending Review (F12.0 punto 5, F12.1.14): «spesa gratis, revisione Pro», 2,99 €.
void main() {
  test('ogni funzione bloccata e\' nel paywall, e il paywall non promette altro', () {
    // ☠ Trappola gia' pagata in TrashCan: un beneficio senza blocco promette una cosa che
    // l'utente ha gia'; un blocco senza beneficio e' una funzione a pagamento che nessuno
    // gli ha detto.
    final locked = {
      for (final e in srFeatureLimits.entries)
        if (e.value.isLockedForFree || e.value.freeMax != null) e.key,
    };
    for (final locale in const [Locale('it'), Locale('en')]) {
      final benefits = buildSrPaywall(lookupL(locale)).benefits.map((b) => b.key).toList();
      expect(benefits.toSet(), locked, reason: 'lingua $locale');
      expect(benefits, hasLength(benefits.toSet().length), reason: 'una riga per chiave');
    }
  });

  test('cinque righe, in quest\'ordine: Scontrino, tutte le spese, statistiche, CSV, backup', () {
    final benefits = buildSrPaywall(lookupL(const Locale('it'))).benefits.map((b) => b.key).toList();
    expect(benefits, [
      FeatureKey.documentScan,
      FeatureKey.fullHistory,
      FeatureKey.statistics,
      FeatureKey.csvExport,
      FeatureKey.backupRestore,
    ]);
  });

  test('ogni chiave e\' dichiarata: nessuna funzione resta nel dubbio', () {
    expect(srFeatureLimits.keys.toSet(), FeatureKey.values.toSet());
  });

  group('il piano gratuito (F12.0 punto 5)', () {
    final gratis = FeatureGate(limits: srFeatureLimits, isPro: false);
    final pro = FeatureGate(limits: srFeatureLimits, isPro: true);

    test('spese: 5 visibili gratis (le altre restano, nascoste: risposta D1)', () {
      expect(gratis.freeLimitOf(FeatureKey.fullHistory), 5);
      expect(gratis.withinLimit(FeatureKey.fullHistory, 4), isTrue);
      expect(gratis.withinLimit(FeatureKey.fullHistory, 5), isFalse);
      expect(pro.withinLimit(FeatureKey.fullHistory, 5000), isTrue);
    });

    test('Scontrino, statistiche (col budget del mese), CSV e backup sono Pro', () {
      for (final k in const [
        FeatureKey.documentScan,
        FeatureKey.statistics,
        FeatureKey.csvExport,
        FeatureKey.backupRestore,
      ]) {
        expect(gratis.allows(k), isFalse, reason: '$k');
        expect(pro.allows(k), isTrue, reason: '$k');
      }
    });

    test('nient\'altro e\' a pagamento (le foto non si conservano: `photos` aperta)', () {
      for (final k in FeatureKey.values) {
        if (const {
          FeatureKey.documentScan,
          FeatureKey.statistics,
          FeatureKey.csvExport,
          FeatureKey.backupRestore,
          FeatureKey.fullHistory,
        }.contains(k)) {
          continue;
        }
        expect(gratis.allows(k), isTrue, reason: '$k');
        expect(gratis.limitOf(k).isOpen, isTrue, reason: '$k');
      }
    });
  });
}
