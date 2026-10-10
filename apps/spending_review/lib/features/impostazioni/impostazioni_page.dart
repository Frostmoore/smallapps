import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/labels.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/scelte.dart';
import '../common/una_mano.dart';
import '../spesa/budget_sheet.dart';
import 'data_section.dart';

/// Le impostazioni (develop_microapps.md F12.1.12, `/impostazioni`): **Budget abituale**,
/// **Vibrazione**, **Negozi**, **Tema**, **Pro** (stato, acquisto, ripristino), **I tuoi dati**
/// (backup Pro, ripristino gratis, CSV Pro), **Informazioni** (versione, informativa, licenze).
///
/// ⚑ **Niente «Ho la carta fedelta'»** (la specsheet lo prevedeva): la risposta D4 del
/// proprietario (2026-10-11) ha tolto il default, e quando un cartellino ha due prezzi il foglio
/// li mostra entrambi ogni volta.
/// ⚑ Il **tetto del mese** (D3, Pro) si imposta dalle Statistiche, dove si vede.
class ImpostazioniPage extends ConsumerWidget {
  const ImpostazioniPage({this.devAttiva = false, super.key});

  /// Mostra la voce «Strumenti di sviluppo: OCR» (solo se la rotta `/dev/ocr` esiste).
  final bool devAttiva;

  static Future<void> _info(BuildContext context, String titolo, String testo) => showDialog<void>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(titolo),
      content: SingleChildScrollView(child: Text(testo)),
      actions: [TextButton(onPressed: () => Navigator.of(d).pop(), child: Text(L.of(d).common_close))],
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final pro = ref.watch(isProProvider);
    final budget = ref.watch(budgetPredefinitoProvider);
    final tema = ref.watch(themeModeProvider);
    return PaginaUnaMano(
      titolo: l.impostazioni_title,
      corpo: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Sezione(l.impostazioni_spesa),
          ListTile(
            key: const ValueKey('impostazioni_budget'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.savings_outlined),
            title: Text(l.impostazioni_budgetAbituale),
            subtitle: Text(budget == null ? l.impostazioni_budgetNessuno : '${importo(budget)} €'),
            onTap: () async {
              final scelta = await BudgetSheet.show(context, titolo: l.impostazioni_budgetAbituale, attuale: budget);
              if (scelta != null) await ref.read(budgetPredefinitoProvider.notifier).set(scelta.budget);
            },
          ),
          SwitchListTile(
            key: const ValueKey('impostazioni_vibrazione'),
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.vibration),
            title: Text(l.impostazioni_vibrazione),
            subtitle: Text(l.impostazioni_vibrazioneTesto),
            value: ref.watch(vibrazioneProvider),
            onChanged: (v) => unawaited(ref.read(vibrazioneProvider.notifier).set(v)),
          ),
          ListTile(
            key: const ValueKey('impostazioni_negozi'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.storefront_outlined),
            title: Text(l.negozi_titolo),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => unawaited(context.push(Routes.negozi)),
          ),
          Sezione(l.settings_theme),
          SegmentedButton<ThemeMode>(
            key: const ValueKey('impostazioni_tema'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: ThemeMode.dark, label: Text(l.theme_dark)),
              ButtonSegment(value: ThemeMode.light, label: Text(l.theme_light)),
              ButtonSegment(value: ThemeMode.system, label: Text(l.theme_system)),
            ],
            selected: {tema},
            onSelectionChanged: (s) => unawaited(ref.read(themeModeProvider.notifier).set(s.first)),
          ),
          Sezione(l.impostazioni_pro),
          // ⚑ La riga del Pro risponde al tocco su tutta la sua superficie (lezione di TrashCan).
          ListTile(
            key: const ValueKey('impostazioni_pro'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(pro ? Icons.verified : Icons.workspace_premium_outlined),
            title: Text(pro ? l.settings_proActive : l.settings_proCta),
            subtitle: pro ? Text(l.paywall_thanks) : null,
            trailing: pro ? null : const ProBadge(),
            onTap: pro ? null : () => unawaited(showSrPaywall(context, ref)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.restore),
            title: Text(l.paywall_restore),
            subtitle: Text(
              defaultTargetPlatform == TargetPlatform.iOS ? l.settings_restoreApple : l.settings_restoreGoogle,
            ),
            onTap: () async {
              final service = ref.read(entitlementProvider.notifier).service;
              final result = await service.restorePurchases();
              if (!context.mounted) return;
              result.fold(
                ok: (_) => MicroSnack.show(context, service.isPro ? l.paywall_thanks : l.paywall_restoredNothing),
                err: (error) => MicroSnack.error(context, error.message),
              );
            },
          ),
          const DataSection(),
          Sezione(l.impostazioni_informazioni),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l.impostazioni_privacy),
            onTap: () => unawaited(_info(context, l.impostazioni_privacy, l.impostazioni_privacyTesto)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.gavel_outlined),
            title: Text(l.impostazioni_licenze),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l.appTitle,
              applicationVersion: appVersion,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: Text(l.appTitle),
            subtitle: Text(l.settings_version(appVersion)),
          ),
          if (devAttiva)
            ListTile(
              key: const ValueKey('impostazioni_dev'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.developer_mode),
              title: Text(l.dev_titolo),
              onTap: () => unawaited(context.push(Routes.devOcr)),
            ),
        ],
      ),
    );
  }
}
