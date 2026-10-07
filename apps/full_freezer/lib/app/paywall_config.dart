import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../l10n/generated/app_localizations.dart';
import 'entitlement.dart';

/// I testi del paywall di Full Freezer (F4.10).
///
/// ⚑ L'ordine dei benefici e' quello che vende: prima il secondo freezer (chi ha il
/// pozzetto in garage ha gia' il problema e paga volentieri), poi gli avvisi (il richiamo
/// che fa tornare nell'app), poi i numeri dello spreco. Il resto e' contorno.
///
/// ☠ Ogni beneficio corrisponde a una chiave `locked()` in `freezer_feature_limits` e
/// viceversa: lo verifica test/widget/paywall_config_test.dart.
PaywallConfig buildFreezerPaywall(L l) => PaywallConfig(
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
      key: FeatureKey.unlimitedEntities,
      icon: Icons.kitchen_outlined,
      title: l.paywall_benefitFreezersTitle,
      description: l.paywall_benefitFreezersBody,
    ),
    PaywallBenefit(
      key: FeatureKey.notifications,
      icon: Icons.notifications_active_outlined,
      title: l.paywall_benefitAlertsTitle,
      description: l.paywall_benefitAlertsBody,
    ),
    PaywallBenefit(
      key: FeatureKey.statistics,
      icon: Icons.insights_outlined,
      title: l.paywall_benefitStatsTitle,
      description: l.paywall_benefitStatsBody,
    ),
    PaywallBenefit(
      key: FeatureKey.fullHistory,
      icon: Icons.history,
      title: l.paywall_benefitHistoryTitle,
      description: l.paywall_benefitHistoryBody,
    ),
    PaywallBenefit(
      key: FeatureKey.backupRestore,
      icon: Icons.cloud_download_outlined,
      title: l.paywall_benefitBackupTitle,
      description: l.paywall_benefitBackupBody,
    ),
    PaywallBenefit(
      key: FeatureKey.csvExport,
      icon: Icons.table_chart_outlined,
      title: l.paywall_benefitCsvTitle,
      description: l.paywall_benefitCsvBody,
    ),
    PaywallBenefit(
      key: FeatureKey.customCategories,
      icon: Icons.category_outlined,
      title: l.paywall_benefitCategoriesTitle,
      description: l.paywall_benefitCategoriesBody,
    ),
  ],
);

/// Apre il paywall, con la funzione che l'ha innescato evidenziata. Restituisce `true` se si
/// esce con il Pro attivo.
Future<bool> showFreezerPaywall(BuildContext context, WidgetRef ref, {FeatureKey? highlight}) =>
    PaywallPage.show(
      context,
      config: buildFreezerPaywall(L.of(context)),
      service: ref.read(entitlementProvider.notifier).service,
      highlight: highlight,
    );
