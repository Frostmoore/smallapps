import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../l10n/generated/app_localizations.dart';
import 'entitlement.dart';

/// I testi del paywall di Scorte Calore (F5.11).
///
/// ⚑ L'ordine e' quello che vende: prima il promemoria (e' il motivo per cui si apre l'app:
/// non restare senza), poi le altre fonti, poi il resto.
///
/// ☠ Ogni beneficio corrisponde a una chiave limitata in `scorteFeatureLimits`
/// (`feature_limits.dart`) e viceversa: lo verifica test/widget/paywall_config_test.dart.
PaywallConfig buildScortePaywall(L l) => PaywallConfig(
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
      key: FeatureKey.notifications,
      icon: Icons.notifications_active_outlined,
      title: l.paywall_benefitAlertsTitle,
      description: l.paywall_benefitAlertsBody,
    ),
    PaywallBenefit(
      key: FeatureKey.unlimitedEntities,
      icon: Icons.local_fire_department_outlined,
      title: l.paywall_benefitSourcesTitle,
      description: l.paywall_benefitSourcesBody,
    ),
    PaywallBenefit(
      key: FeatureKey.fullHistory,
      icon: Icons.history,
      title: l.paywall_benefitHistoryTitle,
      description: l.paywall_benefitHistoryBody,
    ),
    PaywallBenefit(
      key: FeatureKey.statistics,
      icon: Icons.euro_outlined,
      title: l.paywall_benefitCostsTitle,
      description: l.paywall_benefitCostsBody,
    ),
    PaywallBenefit(
      key: FeatureKey.calendarSync,
      icon: Icons.event_outlined,
      title: l.paywall_benefitCalendarTitle,
      description: l.paywall_benefitCalendarBody,
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
  ],
);

/// Apre il paywall, con la funzione che l'ha innescato evidenziata. `true` se si esce con il
/// Pro attivo.
Future<bool> showScortePaywall(BuildContext context, WidgetRef ref, {FeatureKey? highlight}) =>
    PaywallPage.show(
      context,
      config: buildScortePaywall(L.of(context)),
      service: ref.read(entitlementProvider.notifier).service,
      highlight: highlight,
    );
