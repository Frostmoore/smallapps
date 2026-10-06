import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../l10n/generated/app_localizations.dart';
import 'providers.dart';

/// I testi del paywall di TrashCan.
///
/// ⚑ L'ordine dei benefici non è casuale: i calendari multipli stanno per primi perché
/// sono la ragione per cui qualcuno paga. Chi ha una seconda casa ha già dimostrato di
/// avere il problema che l'app risolve; gli altri benefici sono contorno e servono a far
/// sembrare il prezzo giusto, non a convincere.
///
/// ⚑ La riga "un pagamento unico, nessun abbonamento" non è un dettaglio legale: è il
/// motivo principale per cui una persona sceglie questa app invece di una in abbonamento.
PaywallConfig buildTrashcanPaywall(L l) => PaywallConfig(
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
      icon: Icons.home_work_outlined,
      title: l.paywall_benefitCalendarsTitle,
      description: l.paywall_benefitCalendarsBody,
    ),
    // Il promemoria sta per secondo, subito dopo i calendari: e' la funzione per cui l'app
    // viene installata, e dal 2026-09-11 e' interamente a pagamento.
    PaywallBenefit(
      key: FeatureKey.notifications,
      icon: Icons.notifications_outlined,
      title: l.paywall_benefitRemindersTitle,
      description: l.paywall_benefitRemindersBody,
    ),
    PaywallBenefit(
      key: FeatureKey.multipleNotifications,
      icon: Icons.notifications_active_outlined,
      title: l.paywall_benefitNotificationsTitle,
      description: l.paywall_benefitNotificationsBody,
    ),
    // ☠ Qui c'era il widget completo. E' uscito dal paywall il 2026-09-11, quando
    // `advancedWidget` e' passato ad `open()`: il widget mostra tre giorni a tutti. Un
    // beneficio elencato qui che non corrisponde a nessun blocco e' peggio di uno in meno,
    // perche' promette una cosa che l'utente ha gia'. Il test in
    // test/widget/paywall_config_test.dart confronta le due liste e non lo lascia passare.
    PaywallBenefit(
      key: FeatureKey.backupRestore,
      icon: Icons.cloud_download_outlined,
      title: l.paywall_benefitBackupTitle,
      description: l.paywall_benefitBackupBody,
    ),
    PaywallBenefit(
      key: FeatureKey.themeCustomization,
      icon: Icons.palette_outlined,
      title: l.paywall_benefitThemeTitle,
      description: l.paywall_benefitThemeBody,
    ),
  ],
);

/// Apre il paywall. Restituisce `true` se si esce con il Pro attivo.
///
/// Sta qui e non in ogni pagina perche' il paywall va aperto sempre allo stesso modo:
/// stessi testi, stesso servizio, e la funzione che l'ha innescato evidenziata nell'elenco.
/// Chi apre il paywall "a mano" prima o poi dimentica l'evidenziazione, e l'utente si
/// trova davanti un elenco generico invece della riga che stava cercando di usare.
Future<bool> showTrashcanPaywall(
  BuildContext context,
  WidgetRef ref, {
  FeatureKey? highlight,
}) => PaywallPage.show(
  context,
  config: buildTrashcanPaywall(L.of(context)),
  service: ref.read(entitlementProvider.notifier).service,
  highlight: highlight,
);
