import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/paywall_config.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/notification_providers.dart';

/// La riga delle notifiche di riordino nelle impostazioni (F5.8).
///
/// - Senza Pro: `ProBadge` e il tocco apre il paywall con le notifiche evidenziate.
/// - Con Pro: un interruttore. Accenderlo chiede il permesso (vedi [_setNotifications]).
/// - Acceso ma con le notifiche bloccate dal sistema: il sottotitolo lo dice, perche' un
///   interruttore acceso che non produce niente sembra un'app rotta.
///
/// ⚑ La riga risponde al tocco su tutta la superficie, come la riga del Pro: in TrashCan il
/// riquadro non rispondeva e il proprietario l'ha trovato rotto.
class NotificationsSection extends ConsumerWidget {
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final pro = ref.watch(isProProvider);
    final on = ref.watch(notificationsEnabledProvider);
    // Solo quando conta: senza Pro o a interruttore spento non si interroga il sistema.
    final blocked = pro && on && ref.watch(notificationPermissionProvider).value == false;

    return ListTile(
      leading: const Icon(Icons.notifications_active_outlined),
      title: Text(l.settings_notifTitle),
      subtitle: Text(
        blocked ? l.settings_notifDenied : l.settings_notifBody,
        style: blocked ? TextStyle(color: Theme.of(context).colorScheme.error) : null,
      ),
      trailing:
          pro ? Switch(value: on, onChanged: (v) => unawaited(_setNotifications(context, ref, v))) : const ProBadge(),
      onTap: pro
          ? () => unawaited(_setNotifications(context, ref, !on))
          : () => unawaited(showScortePaywall(context, ref, highlight: FeatureKey.notifications)),
    );
  }
}

/// Accende o spegne le notifiche. Accendendole si chiede il permesso: e' il momento in cui
/// l'utente ha un motivo per dire di si' (non al primo avvio, quando un no e' definitivo).
///
/// ☠ Con il permesso negato l'interruttore **resta spento**: acceso, prometterebbe avvisi
/// che il sistema non mostrera'.
Future<void> _setNotifications(BuildContext context, WidgetRef ref, bool on) async {
  final l = L.of(context);
  if (on) {
    final service = await ref.read(notificationServiceProvider.future);
    final outcome = await service.ensurePermission();
    if (outcome == PermissionOutcome.denied || outcome == PermissionOutcome.permanentlyDenied) {
      if (context.mounted) MicroSnack.error(context, l.settings_notifDenied);
      return;
    }
    ref.invalidate(notificationPermissionProvider);
  }
  await ref.read(notificationsEnabledProvider.notifier).set(on);
}
