import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

/// Come il License Server conosce QR Me: la chiave della tabella `apps` e di `APP_SECRETS` sul
/// server.
///
/// ☠ **Non e' `appId`.** `appId` (`qr_me`) da' il nome alle cartelle e alle preferenze sul
/// telefono; il server usa gli id senza trattino basso (F5.0 punto 7, pagato con Full Freezer).
const String licenseAppId = 'qrme';

/// La configurazione di QR Me. La forma vive in `micro_core`, qui solo i valori.
///
/// Verde `#3BD13B`: il verde acceso dell'icona del proprietario (F17.0 punto 9), confermato come
/// accento «neon» dalla grafica «A · Neon» scelta il 2026-10-09 (F17.6; colori in
/// `lib/app/qr_palette.dart`). **Tema scuro di default** (scelta del proprietario con la
/// grafica): il QR resta comunque nero su un pannello bianco. Corpo in Plus Jakarta Sans,
/// titoli in Space Grotesk.
MicroAppConfig buildQrConfig() => MicroAppConfig.fromEnvironment(
  appId: 'qr_me',
  appName: 'QR Me',
  // Immutabile dopo la pubblicazione: uno SKU pubblicato non si cancella ne' si riusa.
  proSku: 'qrme_pro_lifetime',
  seedColor: const Color(0xFF3BD13B),
  fontFamily: 'PlusJakartaSans',
  defaultBrightness: Brightness.dark,
);
