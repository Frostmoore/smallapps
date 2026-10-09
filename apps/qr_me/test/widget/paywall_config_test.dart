import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro_core/micro_core.dart';
import 'package:qr_me/app/feature_limits.dart';
import 'package:qr_me/app/paywall_config.dart';
import 'package:qr_me/l10n/generated/app_localizations.dart';

/// Il Pro di QR Me (F17.0 punto 6, F17.1.9): «base generosa», 1,99 €.
void main() {
  test('ogni funzione bloccata e\' nel paywall, e il paywall non promette altro', () {
    // ☠ Trappola gia' pagata in TrashCan: un beneficio senza blocco promette una cosa che
    // l'utente ha gia'; un blocco senza beneficio e' una funzione a pagamento che nessuno
    // gli ha detto.
    final locked = {
      for (final e in qrFeatureLimits.entries)
        if (e.value.isLockedForFree || e.value.freeMax != null) e.key,
    };
    for (final locale in const [Locale('it'), Locale('en')]) {
      final benefits = buildQrPaywall(lookupL(locale)).benefits.map((b) => b.key).toList();
      expect(benefits.toSet(), locked, reason: 'lingua $locale');
      expect(benefits, hasLength(benefits.toSet().length), reason: 'una riga per chiave');
    }
  });

  test('ogni chiave e\' dichiarata: nessuna funzione resta nel dubbio', () {
    expect(qrFeatureLimits.keys.toSet(), FeatureKey.values.toSet());
  });

  group('il piano gratuito (F17.0 punto 6)', () {
    final gratis = FeatureGate(limits: qrFeatureLimits, isPro: false);
    final pro = FeatureGate(limits: qrFeatureLimits, isPro: true);

    test('cronologia: 5 gratis', () {
      expect(gratis.withinLimit(FeatureKey.fullHistory, 4), isTrue);
      expect(gratis.withinLimit(FeatureKey.fullHistory, 5), isFalse);
      expect(pro.withinLimit(FeatureKey.fullHistory, 5000), isTrue);
    });

    test('preferiti: uno gratis, il secondo solo con il Pro', () {
      expect(gratis.withinLimit(FeatureKey.unlimitedEntities, 0), isTrue);
      expect(gratis.withinLimit(FeatureKey.unlimitedEntities, 1), isFalse);
      expect(pro.withinLimit(FeatureKey.unlimitedEntities, 99), isTrue);
    });

    test('moduli, stile, immagine e backup sono Pro', () {
      for (final k in const [
        FeatureKey.customCategories,
        FeatureKey.themeCustomization,
        FeatureKey.imageExport,
        FeatureKey.backupRestore,
      ]) {
        expect(gratis.allows(k), isFalse, reason: '$k');
        expect(pro.allows(k), isTrue, reason: '$k');
      }
    });

    test('nient\'altro e\' a pagamento', () {
      for (final k in const [FeatureKey.photos, FeatureKey.statistics, FeatureKey.notifications, FeatureKey.csvExport]) {
        expect(gratis.allows(k), isTrue, reason: '$k');
      }
    });
  });
}
