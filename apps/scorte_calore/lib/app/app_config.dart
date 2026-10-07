import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

/// Come il License Server conosce Scorte Calore: la chiave della tabella `apps` e di
/// `APP_SECRETS` sul server.
///
/// ☠ **Non e' `appId`.** `appId` (`scorte_calore`) da' il nome alle cartelle e alle
/// preferenze sul telefono; il server usa gli id senza trattino basso. Con Full Freezer
/// mandare l'id locale avrebbe fatto rifiutare ogni verifica d'acquisto Play come "app
/// sconosciuta" (develop_microapps.md F5.0 punto 7).
const String licenseAppId = 'scortecalore';

/// La configurazione di Scorte Calore. La forma vive in `micro_core`, qui solo i valori.
///
/// Il colore e' l'arancio della fiamma dell'icona (`#F4511E`, misurato sull'icona del
/// proprietario il 2026-10-07; F5.0 punto 5): sostituisce il `#C4622D` del piano. Il blu
/// notte delle testate sta nella palette dell'app, non qui.
MicroAppConfig buildScorteConfig() => MicroAppConfig.fromEnvironment(
  appId: 'scorte_calore',
  appName: 'Scorte Calore',
  // Immutabile dopo la pubblicazione: uno SKU pubblicato non si cancella ne' si riusa.
  proSku: 'scortecalore_pro_lifetime',
  seedColor: const Color(0xFFF4511E),
  fontFamily: 'PlusJakartaSans',
  defaultBrightness: Brightness.light,
);
