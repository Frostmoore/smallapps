import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/sr_palette.dart';
import '../../l10n/generated/app_localizations.dart';

/// LA schermata (develop_microapps.md F12.1.12). ⚑ **Bootstrap (F12.2c)**: per ora solo il totale
/// della spesa in corso, letto dal repository, per provare che app, tema, font, database e provider
/// stanno in piedi insieme. Il tastierino, la lista, la barra del budget e i due tasti arrivano con
/// F12.4 («C · Una mano» completa).
class SpesaPage extends ConsumerWidget {
  const SpesaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = SrPalette.of(context);
    final l = L.of(context);
    final totale = ref.watch(spesaInCorsoProvider).value?.totale ?? Money.zero;
    return Scaffold(
      appBar: AppBar(title: Text(l.appTitle)),
      body: Center(
        child: Semantics(
          label: l.spesa_title,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(totale.formatPlain(locale: 'it'), style: p.numeri(size: 64, letterSpacing: -64 * 0.03)),
              const SizedBox(width: 6),
              Text('€', style: p.numeri(size: 30, color: p.testoSecondario)),
            ],
          ),
        ),
      ),
    );
  }
}
