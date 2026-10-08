import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../l10n/generated/app_localizations.dart';

/// La home a tre sezioni (F6.8): In macchina, In laboratorio, Archivio.
///
/// Per ora solo lo scheletro del bootstrap (F6.1): le sezioni si riempiono con i rullini
/// quando arrivano data layer e schermate (F6.2-F6.8).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          IconButton(
            tooltip: l.settings_title,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final titolo in [l.home_inCamera, l.home_atLab, l.home_archive]) ...[
            Text(titolo.toUpperCase(), style: text.labelLarge?.copyWith(letterSpacing: 1.4)),
            const SizedBox(height: 8),
            Text(l.home_emptySection, style: text.bodyMedium),
            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }
}
