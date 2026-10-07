import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/freezer_palette.dart';
import '../../app/paywall_config.dart';
import '../../l10n/generated/app_localizations.dart';

/// Il Pro controllato **sulla pagina**, non solo sulla porta da cui ci si arriva.
///
/// ⚑ `openProFeature` e `openNewFreezer` mostrano il paywall prima di aprire, ma una porta
/// nuova (un deep link, una notifica, una pagina scritta domani) farebbe `push` diretto e
/// aprirebbe la pagina gratis. Qui, senza il Pro, la pagina mostra un lucchetto con il
/// pulsante del paywall; appena il Pro c'e', mostra se stessa (si ridisegna da sola).
///
/// ☠ Non un `redirect` di go_router: un `push` che redireziona a "/" mette "/" due volte
/// nella pila e go_router mostra la sua pagina d'errore (provato in un test il 2026-10-07).
class ProGate extends ConsumerWidget {
  const ProGate({required this.feature, required this.child, this.allowed, super.key});

  final FeatureKey feature;
  final Widget child;

  /// Per i limiti numerici (freezer multipli): sostituisce il semplice `allows`.
  final bool Function(FeatureGate gate)? allowed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(featureGateProvider);
    final ok = allowed?.call(gate) ?? gate.allows(feature);
    if (ok) return child;

    final l = L.of(context);
    final p = FreezerPalette.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: p.inkMuted),
              MicroSpacing.gapM,
              Text(l.pro_locked, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              MicroSpacing.gapL,
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
                onPressed: () => unawaited(showFreezerPaywall(context, ref, highlight: feature)),
                child: Text(l.paywall_buy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
