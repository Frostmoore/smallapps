import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../l10n/generated/app_localizations.dart';
import 'entitlement.dart';

/// I testi del paywall di Spending Review (develop_microapps.md F12.1.14).
///
/// ⚑ **Cinque righe, una per chiave limitata, in quest'ordine**: prima lo Scontrino (e' la cosa
/// che si vede alla cassa, ed e' l'unica che il gratis non ha in nessuna forma), poi tutte le
/// spese, le statistiche (con il budget del MESE: risposta D3 del proprietario, 2026-10-10), il
/// CSV, il backup.
///
/// ☠ Ogni beneficio corrisponde a una chiave limitata in `srFeatureLimits`
/// (`feature_limits.dart`) e viceversa: lo verifica test/widget/paywall_config_test.dart.
PaywallConfig buildSrPaywall(L l) => PaywallConfig(
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
      key: FeatureKey.documentScan,
      icon: Icons.receipt_long_outlined,
      title: l.paywall_benefitReceiptTitle,
      description: l.paywall_benefitReceiptBody,
    ),
    PaywallBenefit(
      key: FeatureKey.fullHistory,
      icon: Icons.history,
      title: l.paywall_benefitHistoryTitle,
      description: l.paywall_benefitHistoryBody,
    ),
    PaywallBenefit(
      key: FeatureKey.statistics,
      icon: Icons.bar_chart,
      title: l.paywall_benefitStatsTitle,
      description: l.paywall_benefitStatsBody,
    ),
    PaywallBenefit(
      key: FeatureKey.csvExport,
      icon: Icons.table_chart_outlined,
      title: l.paywall_benefitCsvTitle,
      description: l.paywall_benefitCsvBody,
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
Future<bool> showSrPaywall(BuildContext context, WidgetRef ref, {FeatureKey? highlight}) =>
    PaywallPage.show(
      context,
      config: buildSrPaywall(L.of(context)),
      service: ref.read(entitlementProvider.notifier).service,
      highlight: highlight,
    );
