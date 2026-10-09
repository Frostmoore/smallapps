import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../l10n/generated/app_localizations.dart';
import 'entitlement.dart';

/// I testi del paywall di QR Me (develop_microapps.md F17.1.9).
///
/// ⚑ L'ordine e' quello che vende: prima lo stile (e' cio' che si vede), poi i moduli (il
/// Wi-Fi per gli ospiti), preferiti e cronologia, l'immagine, il backup.
///
/// ⚑ **Sei righe e non le «quattro piu' backup» della spec**: la spec mette «Preferiti e
/// cronologia senza limite» in una riga, ma sono due chiavi (`unlimitedEntities`,
/// `fullHistory`) e il test di coerenza vuole una riga per chiave limitata. Due righe dicono
/// anche meglio cosa cambia: la cronologia senza limite vale «da adesso in poi» (F17.1.4).
///
/// ☠ Ogni beneficio corrisponde a una chiave limitata in `qrFeatureLimits`
/// (`feature_limits.dart`) e viceversa: lo verifica test/widget/paywall_config_test.dart.
PaywallConfig buildQrPaywall(L l) => PaywallConfig(
  appName: l.appTitle,
  headline: l.paywall_headline,
  subhead: l.paywall_subhead,
  buyLabel: (price) => price == null ? l.paywall_buy : l.paywall_buyWithPrice(price),
  restoreLabel: l.paywall_restore,
  pendingLabel: l.paywall_pending,
  thanksLabel: l.paywall_thanks,
  nothingToRestoreLabel: l.paywall_restoredNothing,
  unavailableLabel: l.paywall_unavailable,
  productUnavailableLabel: l.paywall_productUnavailable,
  retryLabel: l.common_retry,
  oneTimeNotice: l.paywall_subhead,
  benefits: [
    PaywallBenefit(
      key: FeatureKey.themeCustomization,
      icon: Icons.palette_outlined,
      title: l.paywall_benefitStyleTitle,
      description: l.paywall_benefitStyleBody,
    ),
    PaywallBenefit(
      key: FeatureKey.customCategories,
      icon: Icons.wifi,
      title: l.paywall_benefitFormsTitle,
      description: l.paywall_benefitFormsBody,
    ),
    PaywallBenefit(
      key: FeatureKey.unlimitedEntities,
      icon: Icons.star_outline,
      title: l.paywall_benefitFavoritesTitle,
      description: l.paywall_benefitFavoritesBody,
    ),
    PaywallBenefit(
      key: FeatureKey.fullHistory,
      icon: Icons.history,
      title: l.paywall_benefitHistoryTitle,
      description: l.paywall_benefitHistoryBody,
    ),
    PaywallBenefit(
      key: FeatureKey.imageExport,
      icon: Icons.ios_share,
      title: l.paywall_benefitImageTitle,
      description: l.paywall_benefitImageBody,
    ),
    PaywallBenefit(
      key: FeatureKey.backupRestore,
      icon: Icons.cloud_download_outlined,
      title: l.paywall_benefitBackupTitle,
      description: l.paywall_benefitBackupBody,
    ),
  ],
);

/// Apre il paywall, con la funzione che l'ha innescato evidenziata. `true` se si esce con il
/// Pro attivo.
Future<bool> showQrPaywall(BuildContext context, WidgetRef ref, {FeatureKey? highlight}) =>
    PaywallPage.show(
      context,
      config: buildQrPaywall(L.of(context)),
      service: ref.read(entitlementProvider.notifier).service,
      highlight: highlight,
    );
