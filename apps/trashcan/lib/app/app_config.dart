import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

/// La configurazione di TrashCan.
///
/// La forma della classe vive in `micro_core`: qui ci sono solo i valori di questa app.
/// Si legge una volta in `main()` e si inietta nel `ProviderScope`.
///
/// Il verde e' quello della raccolta differenziata, scuro a sufficienza da reggere il
/// testo bianco della card "Stasera", che e' l'elemento piu' importante dell'app e deve
/// essere leggibile a un metro di distanza, di sera, con le mani occupate.
MicroAppConfig buildTrashcanConfig() => MicroAppConfig.fromEnvironment(
  appId: 'trashcan',
  appName: 'TrashCan',
  // Immutabile dopo la pubblicazione: uno SKU pubblicato non si cancella ne si
  // riusa. Vedi develop_microapps.md §1.3.
  proSku: 'trashcan_pro_lifetime',
  seedColor: const Color(0xFF2E7D5B),
  fontFamily: 'Outfit',
  defaultBrightness: Brightness.light,
);
