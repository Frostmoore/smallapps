import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/qr_palette.dart';
import '../../app/routes.dart';
import '../../domain/qr_content.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/neon.dart';

/// Le strade del modulo Contatto (develop_microapps.md F17.10 punto 2).
///
/// - **«Scegli dalla rubrica»**: il selettore di sistema, **senza permesso dei contatti**
///   (`ContactPicker`) → [onPicked]: il modulo si apre gia' compilato, da controllare e
///   completare (il selettore da' nome e telefono, non l'email).
/// - **«Io»**: la propria scheda, salvata una volta (`myContactProvider`) → [onMe], che mostra
///   subito il QR. Se non c'e' ancora, si apre `/me` per sceglierla o compilarla, e al ritorno
///   si prosegue con quella. La matita accanto la modifica.
/// - **«Inserisci a mano»**: ultima riga, piccola → [onManual].
class ContactSources extends ConsumerWidget {
  const ContactSources({
    required this.onPicked,
    required this.onMe,
    required this.onManual,
    super.key,
  });

  final ValueChanged<ContactContent> onPicked;
  final ValueChanged<ContactContent> onMe;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final me = ref.watch(myContactProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: MicroSpacing.m),
          child: Text(
            l.contactSource_intro,
            style: TextStyle(fontSize: 14, color: QrPalette.of(context).inkMuted, height: 1.4),
          ),
        ),
        SourceCard(
          key: const ValueKey('contact_source_pick'),
          icon: Icons.contacts_outlined,
          title: l.contactSource_pick,
          body: l.contactSource_pickBody,
          onTap: () async {
            final c = await pickContact(context, ref);
            if (c != null) onPicked(c);
          },
        ),
        SourceCard(
          key: const ValueKey('contact_source_me'),
          icon: Icons.badge_outlined,
          title: l.contactSource_me,
          body: me == null ? l.contactSource_meEmpty : l.contactSource_meSaved(me.name),
          trailing: me == null
              ? null
              : IconButton(
                  key: const ValueKey('contact_me_edit'),
                  tooltip: l.myContact_edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => unawaited(context.push<ContactContent>(Routes.myContact)),
                ),
          onTap: () async {
            final saved = me ?? await context.push<ContactContent>(Routes.myContact);
            if (saved != null) onMe(saved);
          },
        ),
        MicroSpacing.gapS,
        Center(
          child: TextButton(
            key: const ValueKey('contact_manual'),
            onPressed: onManual,
            child: Text(l.wifiSource_manual, style: const TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

/// Apre il selettore di sistema; il contatto scelto o null (annullato, o errore gia' detto).
Future<ContactContent?> pickContact(BuildContext context, WidgetRef ref) async {
  final l = L.of(context);
  try {
    final picked = await ref.read(contactPickerProvider).pick();
    // ⚑ Solo l'esito, mai il contatto: il log resta sul telefono ma non deve contenere dati.
    MicroLog.i('rubrica: ${picked == null ? 'nessun contatto' : 'contatto scelto'}');
    return picked;
  } on Object catch (error, stack) {
    MicroLog.e('selettore dei contatti', error: error, stackTrace: stack);
    if (context.mounted) MicroSnack.error(context, l.contactSource_pickFailed);
    return null;
  }
}
