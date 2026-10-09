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
/// Verde `#3BD13B`: il verde acceso dell'icona del proprietario (F17.0 punto 9), seme
/// provvisorio finche' le proposte grafiche (F17.6) non dicono altro. **Tema chiaro di
/// default**: un QR e' nero su bianco, e l'app che lo mostra a tutto schermo nasce chiara.
/// Plus Jakarta Sans come Film Tracker, provvisorio anche lui.
MicroAppConfig buildQrConfig() => MicroAppConfig.fromEnvironment(
  appId: 'qr_me',
  appName: 'QR Me',
  // Immutabile dopo la pubblicazione: uno SKU pubblicato non si cancella ne' si riusa.
  proSku: 'qrme_pro_lifetime',
  seedColor: const Color(0xFF3BD13B),
  fontFamily: 'PlusJakartaSans',
  defaultBrightness: Brightness.light,
);
