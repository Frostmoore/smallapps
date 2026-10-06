import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

/// La configurazione di Full Freezer.
///
/// La forma della classe vive in `micro_core`: qui ci sono solo i valori di questa app.
/// Si legge una volta in `main()` e si inietta nel `ProviderScope`.
///
/// Il blu e' quello dell'icona del proprietario (`#0461E5`, misurato da
/// `tool/genera_icone.py`): pulsanti, testate e barra di riempimento devono sembrare la
/// stessa app dell'icona. Sostituisce l'azzurro `#3A7CA5` del piano originale (decisione
/// del 2026-10-06, develop_microapps.md F4.1).
MicroAppConfig buildFreezerConfig() => MicroAppConfig.fromEnvironment(
  appId: 'full_freezer',
  appName: 'Full Freezer',
  // Immutabile dopo la pubblicazione: uno SKU pubblicato non si cancella ne' si riusa.
  // Vedi develop_microapps.md §1.3.
  proSku: 'fullfreezer_pro_lifetime',
  seedColor: const Color(0xFF0461E5),
  fontFamily: 'PlusJakartaSans',
  defaultBrightness: Brightness.light,
);
