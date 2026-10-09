import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/qr_palette.dart';
import '../../domain/qr_content.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/neon.dart';
import 'contact_form.dart';
import 'contact_sources.dart';

/// La scheda «Io» (`/me`, Pro `customCategories`; develop_microapps.md F17.10 punto 2): la si
/// sceglie dalla rubrica o la si compila **una volta**, e il modulo Contatto la riusa.
///
/// Si apre dal modulo Contatto («Io» la prima volta, o la matita) e dalle impostazioni.
/// «Salva» la scrive nelle preferenze (`myContactProvider`) e torna con la scheda (`pop`): chi
/// arrivava da «Io» vede subito il suo QR.
class MyContactPage extends ConsumerStatefulWidget {
  const MyContactPage({super.key});

  @override
  ConsumerState<MyContactPage> createState() => _MyContactPageState();
}

class _MyContactPageState extends ConsumerState<MyContactPage> {
  QrContent? _content;

  /// La scheda di partenza del modulo: quella salvata, poi quella scelta dalla rubrica.
  late ContactContent? _seed = ref.read(myContactProvider);

  /// ⚑ Cambia a ogni scelta dalla rubrica: il modulo legge i valori iniziali solo quando nasce,
  /// e una chiave nuova lo fa rinascere con quelli scelti.
  int _generation = 0;

  Future<void> _pick() async {
    final c = await pickContact(context, ref);
    if (c == null || !mounted) return;
    setState(() {
      _seed = c;
      _generation++;
    });
  }

  Future<void> _save() async {
    final c = _content;
    if (c is! ContactContent) return;
    await ref.read(myContactProvider.notifier).save(c);
    if (!mounted) return;
    MicroSnack.success(context, L.of(context).myContact_saved);
    if (context.canPop()) context.pop(c);
  }

  Future<void> _delete() async {
    final l = L.of(context);
    final ok = await MicroConfirmSheet.show(
      context,
      title: l.myContact_deleteTitle,
      message: l.myContact_deleteBody,
      confirmLabel: l.common_delete,
      cancelLabel: l.common_cancel,
      destructive: true,
    );
    if (!ok) return;
    await ref.read(myContactProvider.notifier).clear();
    // ⚑ `canPop`: la pagina puo' essere la prima della pila (un test, un percorso futuro).
    if (mounted && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final saved = ref.watch(myContactProvider) != null;
    return Scaffold(
      appBar: AppBar(title: Text(l.myContact_title)),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          Text(
            l.myContact_intro,
            style: TextStyle(fontSize: 14, color: QrPalette.of(context).inkMuted, height: 1.4),
          ),
          MicroSpacing.gapM,
          SourceCard(
            key: const ValueKey('me_pick'),
            icon: Icons.contacts_outlined,
            title: l.contactSource_pick,
            body: l.myContact_pickBody,
            onTap: () => unawaited(_pick()),
          ),
          MicroSpacing.gapM,
          ContactForm(
            key: ValueKey('me_form_$_generation'),
            initial: _seed,
            onChanged: (c) => setState(() => _content = c),
          ),
          MicroSpacing.gapS,
          NeonButton(
            key: const ValueKey('me_save'),
            label: l.common_save,
            icon: Icons.check,
            onPressed: _content == null ? null : () => unawaited(_save()),
          ),
          if (saved)
            Padding(
              padding: const EdgeInsets.only(top: MicroSpacing.s),
              child: Center(
                child: TextButton(
                  key: const ValueKey('me_delete'),
                  onPressed: () => unawaited(_delete()),
                  child: Text(l.myContact_delete),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
