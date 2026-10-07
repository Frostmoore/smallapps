import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';

/// Apre una pagina Pro, passando dal paywall (con quella funzione evidenziata) se serve.
Future<void> openProFeature(BuildContext context, WidgetRef ref, FeatureKey key, String route) async {
  if (!ref.read(featureGateProvider).allows(key)) {
    final unlocked = await showFreezerPaywall(context, ref, highlight: key);
    if (!unlocked || !context.mounted) return;
  }
  if (context.mounted) await context.push(route);
}

/// Apre la creazione di un freezer, passando dal paywall se il piano gratuito e' pieno.
///
/// ⚑ In una funzione sola perche' "aggiungi un freezer" si tocca da piu' punti
/// (impostazioni, "Dove sono"): chi scrivesse il controllo in ogni pagina prima o poi ne
/// dimenticherebbe uno, e il secondo freezer diventerebbe gratis da quella porta.
Future<void> openNewFreezer(BuildContext context, WidgetRef ref) async {
  final count = ref.read(freezersProvider).value?.length ?? 0;
  if (!ref.read(featureGateProvider).withinLimit(FeatureKey.unlimitedEntities, count)) {
    final unlocked = await showFreezerPaywall(context, ref, highlight: FeatureKey.unlimitedEntities);
    if (!unlocked || !context.mounted) return;
  }
  if (context.mounted) await context.push(Routes.freezerNew);
}
