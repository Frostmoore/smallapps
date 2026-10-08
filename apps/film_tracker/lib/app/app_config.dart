import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

/// Come il License Server conosce Film Tracker: la chiave della tabella `apps` e di
/// `APP_SECRETS` sul server.
///
/// ☠ **Non e' `appId`.** `appId` (`film_tracker`) da' il nome alle cartelle e alle
/// preferenze sul telefono; il server usa gli id senza trattino basso (F5.0 punto 7, pagato
/// con Full Freezer).
const String licenseAppId = 'filmtracker';

/// La configurazione di Film Tracker. La forma vive in `micro_core`, qui solo i valori.
///
/// Ambra `#E0A458` dal piano (§2): e' solo il seme da cui `MicroTheme` parte; i colori veri
/// li impone la palette "C · Provino" (`film_palette.dart`, F6.0 punto 6). **Tema scuro di
/// default** (F6.1): le foto su fondo chiaro perdono contrasto.
MicroAppConfig buildFilmConfig() => MicroAppConfig.fromEnvironment(
  appId: 'film_tracker',
  appName: 'Film Tracker',
  // Immutabile dopo la pubblicazione: uno SKU pubblicato non si cancella ne' si riusa.
  proSku: 'filmtracker_pro_lifetime',
  seedColor: const Color(0xFFE0A458),
  fontFamily: 'PlusJakartaSans',
  defaultBrightness: Brightness.dark,
);
