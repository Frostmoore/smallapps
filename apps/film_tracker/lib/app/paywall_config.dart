import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../l10n/generated/app_localizations.dart';
import 'entitlement.dart';

/// I testi del paywall di Film Tracker.
///
/// ⚑ L'ordine e' quello che vende: prima le statistiche e i costi (quanto spendi in pellicola
/// e laboratorio e' la domanda che chi scatta in analogico si fa), poi il PDF dell'anno, le
/// altre macchine, il resto.
///
/// ☠ Ogni beneficio corrisponde a una chiave limitata in `filmFeatureLimits`
/// (`feature_limits.dart`) e viceversa: lo verifica test/widget/paywall_config_test.dart.
PaywallConfig buildFilmPaywall(L l) => PaywallConfig(
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
      key: FeatureKey.statistics,
      icon: Icons.insights_outlined,
      title: l.paywall_benefitStatsTitle,
      description: l.paywall_benefitStatsBody,
    ),
    PaywallBenefit(
      key: FeatureKey.pdfReport,
      icon: Icons.picture_as_pdf_outlined,
      title: l.paywall_benefitPdfTitle,
      description: l.paywall_benefitPdfBody,
    ),
    PaywallBenefit(
      key: FeatureKey.secondaryEntities,
      icon: Icons.photo_camera_outlined,
      title: l.paywall_benefitCamerasTitle,
      description: l.paywall_benefitCamerasBody,
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
Future<bool> showFilmPaywall(BuildContext context, WidgetRef ref, {FeatureKey? highlight}) =>
    PaywallPage.show(
      context,
      config: buildFilmPaywall(L.of(context)),
      service: ref.read(entitlementProvider.notifier).service,
      highlight: highlight,
    );
