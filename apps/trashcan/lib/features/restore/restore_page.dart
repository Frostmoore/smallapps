import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../l10n/generated/app_localizations.dart';

/// Come riavere il Pro su un telefono nuovo.
///
/// ⚑ Perché una pagina intera per una cosa che Google fa da sola: **quasi** da sola. Il
/// ripristino automatico funziona finché il telefono nuovo usa lo stesso account Google, e
/// in quel caso basta un tocco. Ma l'account cambia più spesso di quanto sembri, e chi ha
/// pagato e si ritrova l'app in versione gratuita non apre un ticket: lascia una recensione
/// da una stella. Le due strade stanno qui, in ordine di quanto sono probabili, e quella
/// rara dice esplicitamente quando serve.
class RestorePage extends ConsumerStatefulWidget {
  const RestorePage({super.key});

  @override
  ConsumerState<RestorePage> createState() => _RestorePageState();
}

class _RestorePageState extends ConsumerState<RestorePage> {
  bool _busy = false;
  RestoreCode? _created;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// La strada normale: Play sa cosa ha comprato questo account.
  Future<void> _restoreFromPlay() async {
    final l = L.of(context);
    final service = ref.read(entitlementProvider.notifier).service;
    final result = await service.restorePurchases();
    if (!mounted) return;

    result.fold(
      ok: (_) => MicroSnack.show(context, service.isPro ? l.restore_done : l.restore_nothing),
      err: (error) => MicroSnack.error(context, error.message),
    );
  }

  Future<void> _createCode() async {
    final service = ref.read(entitlementProvider.notifier).service;
    final result = await service.createRestoreCode();
    if (!mounted) return;

    result.fold(
      ok: (code) => setState(() => _created = code),
      err: (error) => MicroSnack.error(context, error.message),
    );
  }

  Future<void> _claimCode() async {
    final l = L.of(context);
    final code = await _askCode(l);
    if (code == null || code.trim().isEmpty || !mounted) return;

    final service = ref.read(entitlementProvider.notifier).service;
    final result = await service.claimRestoreCode(code.trim());
    if (!mounted) return;

    result.fold(
      ok: (_) => MicroSnack.show(context, l.restore_done),
      err: (error) => MicroSnack.error(context, error.message),
    );
  }

  Future<String?> _askCode(L l) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.restore_codeEnter),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: l.restore_codeLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l.common_done),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    // Il codice di trasferimento passa dal server delle licenze: senza, l'unica strada e'
    // quella di Play. Si dice, invece di offrire un bottone che fallisce.
    final serverAvailable = ref.watch(appConfigProvider).serverEnabled;
    final created = _created;

    // ☠ Su iPhone questa pagina parlava di "account Google" e offriva un codice di
    //   trasferimento che passa da un server che la build iOS non contatta. Su iOS si
    //   ripristina con l'ID Apple, e basta: la sezione del codice non si mostra.
    final ios = defaultTargetPlatform == TargetPlatform.iOS;

    return Scaffold(
      appBar: AppBar(title: Text(l.restore_title)),
      body: SafeArea(
        child: ListView(
          padding: MicroSpacing.page,
          children: [
            MicroSectionHeader(title: ios ? l.restore_appleTitle : l.restore_playTitle),
            MicroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ios ? l.restore_appleBody : l.restore_playBody,
                    style: theme.textTheme.bodyMedium,
                  ),
                  MicroSpacing.gapL,
                  MicroPrimaryButton(
                    label: l.restore_playAction,
                    loading: _busy,
                    onPressed: () => unawaited(_run(_restoreFromPlay)),
                  ),
                ],
              ),
            ),

            if (!ios) ...[
            MicroSpacing.gapXXL,
            MicroSectionHeader(title: l.restore_codeTitle),
            MicroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serverAvailable ? l.restore_codeBody : l.restore_codeUnavailable,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (serverAvailable) ...[
                    if (created != null) ...[
                      MicroSpacing.gapL,
                      SelectableText(
                        l.restore_codeCreated(created.code),
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(
                        l.restore_codeExpires(
                          DateFormat('d MMMM, HH:mm', locale).format(created.expiresAt.toLocal()),
                        ),
                        style: theme.textTheme.cardMeta.copyWith(
                          color: theme.colorScheme.mutedText,
                        ),
                      ),
                    ],
                    MicroSpacing.gapL,
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy ? null : () => unawaited(_run(_createCode)),
                            child: Text(l.restore_codeCreate),
                          ),
                        ),
                        MicroSpacing.hGapM,
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy ? null : () => unawaited(_run(_claimCode)),
                            child: Text(l.restore_codeEnter),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            ],
          ],
        ),
      ),
    );
  }
}
