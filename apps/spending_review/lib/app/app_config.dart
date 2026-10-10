import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

/// Come il License Server conosce Spending Review: la chiave della tabella `apps` e di
/// `APP_SECRETS` sul server.
///
/// ☠ **Non e' `appId`.** `appId` (`spending_review`) da' il nome alle cartelle e alle preferenze
/// sul telefono; il server usa gli id senza trattino basso (F5.0 punto 7, pagato con Full Freezer).
const String licenseAppId = 'spendingreview';

/// La configurazione di Spending Review (develop_microapps.md F12.0 punto 1). La forma vive in
/// `micro_core`, qui solo i valori, **immutabili dopo la pubblicazione**.
///
/// Verde `#4ADE80`: l'accento della grafica «C · Una mano» scelta dal proprietario il 2026-10-10
/// (F12.0 punto 6; colori esatti in `lib/app/sr_palette.dart`). **Tema scuro di default**: la
/// tavola e' disegnata sul nero. Corpo in Plus Jakarta Sans, numeri in Space Grotesk.
MicroAppConfig buildSrConfig() => MicroAppConfig.fromEnvironment(
  appId: 'spending_review',
  appName: 'Spending Review',
  // Immutabile dopo la pubblicazione: uno SKU pubblicato non si cancella ne' si riusa.
  proSku: 'spendingreview_pro_lifetime',
  seedColor: const Color(0xFF4ADE80),
  fontFamily: 'PlusJakartaSans',
  defaultBrightness: Brightness.dark,
);
