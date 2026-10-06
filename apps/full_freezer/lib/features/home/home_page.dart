import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

import '../../l10n/generated/app_localizations.dart';

/// La home di Full Freezer.
///
/// In F4.1 e' solo lo stato vuoto: serve a provare tema, font, lingue e navigazione su
/// Android e iOS prima che arrivino i dati. La home vera (testata con riempimento,
/// "Da usare prima", "Tutto il resto", "Dove sono") e' F4.4.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return MicroPageScaffold(
      title: l.appTitle,
      scrollable: false,
      body: MicroEmptyState(
        icon: Icons.kitchen_outlined,
        title: l.home_emptyTitle,
        message: l.home_emptyBody,
      ),
    );
  }
}
