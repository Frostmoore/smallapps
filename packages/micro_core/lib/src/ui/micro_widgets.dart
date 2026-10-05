import 'package:flutter/material.dart';

import '../theme/micro_tokens.dart';

/// Impalcatura standard di una pagina.
///
/// Esiste perché ogni schermata delle quattro app abbia gli stessi margini, la stessa
/// altezza del titolo e lo stesso comportamento allo scroll. Senza, ogni pagina finisce
/// con un padding leggermente diverso.
class MicroPageScaffold extends StatelessWidget {
  const MicroPageScaffold({
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const <Widget>[],
    this.floatingAction,
    this.scrollable = true,
    this.padding = MicroSpacing.page,
    this.leading,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingAction;
  final bool scrollable;
  final EdgeInsets padding;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(padding: padding, child: body);

    return Scaffold(
      appBar: AppBar(
        leading: leading,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            if (subtitle != null)
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.mutedText),
              ),
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(
        child: scrollable ? SingleChildScrollView(child: content) : content,
      ),
      floatingActionButton: floatingAction,
    );
  }
}

/// Contenitore di base. Sostituisce `Container` + `BoxDecoration` scritti a mano.
///
/// Con [accent] valorizzato la card diventa piena di quel colore e il testo viene
/// scelto per contrasto: è la forma usata dal blocco "Stasera" di TrashCan.
class MicroCard extends StatelessWidget {
  const MicroCard({
    required this.child,
    this.onTap,
    this.accent,
    this.padding = MicroSpacing.card,
    this.emphasized = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? accent;
  final EdgeInsets padding;
  final bool emphasized;

  /// Il colore di testo leggibile su [background].
  ///
  /// ☠ Il colore di un tipo di rifiuto lo sceglie l'utente e può essere qualunque cosa.
  /// Scrivere testo bianco su un giallo chiaro lo rende illeggibile proprio nella card
  /// più importante dell'app. Si stima la luminosità e si sceglie di conseguenza.
  static Color foregroundOn(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : const Color(0xFF10130F);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = accent != null;
    final background = filled ? accent! : scheme.cardSurface;
    final foreground = filled ? foregroundOn(background) : scheme.onSurface;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: MicroRadius.card,
        border: filled ? null : Border.all(color: scheme.subtleBorder),
      ),
      // ☠ Una superficie Material trasparente fra il fondo e il contenuto. Senza, le voci
      //   d'elenco dentro la card (RadioListTile, ListTile) disegnano l'effetto del tocco
      //   sul Material piu' vicino, che sta **sotto** questo fondo colorato: l'effetto c'e'
      //   ma non si vede, e toccare "Chiaro" o "Scuro" non da' nessun segno di risposta.
      //   Flutter lo segnala con un avviso in debug, ed e' cosi' che e' emerso: il test che
      //   produce gli screenshot degli store falliva per quell'avviso.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding, child: child),
      ),
    );

    return DefaultTextStyle.merge(
      style: TextStyle(color: foreground),
      child: IconTheme.merge(
        data: IconThemeData(color: foreground),
        child: onTap == null
            ? card
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: MicroRadius.card,
                  child: card,
                ),
              ),
      ),
    );
  }
}

/// Titolo di sezione con conteggio opzionale.
class MicroSectionHeader extends StatelessWidget {
  const MicroSectionHeader({required this.title, this.count, this.trailing, super.key});

  final String title;
  final String? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MicroSpacing.s, top: MicroSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.sectionLabel.copyWith(color: theme.colorScheme.mutedText),
            ),
          ),
          if (count != null) ...[
            Text(
              count!,
              style: theme.textTheme.sectionLabel.copyWith(color: theme.colorScheme.mutedText),
            ),
            if (trailing != null) MicroSpacing.hGapS,
          ],
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Riga di lista con pallino colorato, titolo, sottotitolo e testo a destra.
class MicroListTile extends StatelessWidget {
  const MicroListTile({
    required this.title,
    this.subtitle,
    this.trailingText,
    this.leading,
    this.accent,
    this.onTap,
    this.dense = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? trailingText;
  final Widget? leading;
  final Color? accent;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: MicroRadius.card,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MicroSpacing.m,
          vertical: dense ? MicroSpacing.s : MicroSpacing.m,
        ),
        child: Row(
          children: [
            if (leading != null)
              leading!
            else if (accent != null)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
            if (leading != null || accent != null) MicroSpacing.hGapM,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: theme.textTheme.cardTitle),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.cardMeta.copyWith(color: scheme.mutedText),
                    ),
                ],
              ),
            ),
            if (trailingText != null) ...[
              MicroSpacing.hGapS,
              Text(
                trailingText!,
                style: theme.textTheme.numeric.copyWith(color: scheme.mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Stato vuoto: icona, titolo, spiegazione e una sola azione.
///
/// ⚑ Uno stato vuoto è la prima cosa che un utente nuovo vede in metà delle schermate.
/// Lasciarlo bianco fa sembrare l'app rotta; riempirlo di opzioni fa sembrare complicato
/// qualcosa che non lo è. Una frase e un bottone.
class MicroEmptyState extends StatelessWidget {
  const MicroEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MicroSpacing.xl,
          vertical: MicroSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.mutedText),
            MicroSpacing.gapL,
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            MicroSpacing.gapS,
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.mutedText),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              MicroSpacing.gapXL,
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottone di azione primaria, con stato di caricamento.
class MicroPrimaryButton extends StatelessWidget {
  const MicroPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), MicroSpacing.hGapS],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = FilledButton(
      // Durante il caricamento il bottone è disabilitato: un doppio tocco su "acquista"
      // è un modo eccellente per generare due acquisti e un rimborso.
      onPressed: loading ? null : onPressed,
      child: child,
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Chip selezionabile, con colore proprio opzionale.
class MicroChip extends StatelessWidget {
  const MicroChip({
    required this.label,
    this.selected = false,
    this.color,
    this.icon,
    this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    final background = selected ? tint : scheme.surfaceContainerLow;
    final foreground = selected ? MicroCard.foregroundOn(tint) : scheme.onSurface;

    return Material(
      color: background,
      borderRadius: MicroRadius.chip,
      child: InkWell(
        onTap: onTap,
        borderRadius: MicroRadius.chip,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MicroSpacing.m,
            vertical: MicroSpacing.s,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: MicroSpacing.xs),
              ],
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: foreground, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Foglio di conferma per le azioni distruttive.
class MicroConfirmSheet extends StatelessWidget {
  const MicroConfirmSheet._({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  /// Restituisce `true` solo se l'utente conferma. Chiudere il foglio significa no.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Annulla',
    bool destructive = false,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MicroConfirmSheet._(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MicroSpacing.l,
          0,
          MicroSpacing.l,
          MicroSpacing.l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            MicroSpacing.gapS,
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.mutedText),
            ),
            MicroSpacing.gapXL,
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    )
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
            MicroSpacing.gapS,
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Messaggi brevi in fondo allo schermo.
abstract final class MicroSnack {
  static void show(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    IconData? icon,
    Color? iconColor,
  }) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: iconColor),
              MicroSpacing.hGapM,
            ],
            Expanded(child: Text(message)),
          ],
        ),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
        // ⚑ Sei secondi e non quattro: se lo snack porta un "Annulla", il tempo di
        // leggerlo e decidere deve starci dentro.
        duration: onAction != null ? const Duration(seconds: 6) : const Duration(seconds: 3),
      ),
    );
  }

  static void success(
    BuildContext context,
    String message, {
    String? undoLabel,
    VoidCallback? onUndo,
  }) => show(
    context,
    message,
    actionLabel: undoLabel,
    onAction: onUndo,
    icon: Icons.check_circle_outline,
    iconColor: Theme.of(context).colorScheme.success,
  );

  static void error(BuildContext context, String message) => show(
    context,
    message,
    icon: Icons.error_outline,
    iconColor: Theme.of(context).colorScheme.error,
  );
}

/// Un numero grande con la sua etichetta. Il mattone delle dashboard.
class MicroStatTile extends StatelessWidget {
  const MicroStatTile({
    required this.label,
    required this.value,
    this.hint,
    this.icon,
    this.accent,
    super.key,
  });

  final String label;
  final String value;
  final String? hint;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = accent ?? scheme.primary;

    return MicroCard(
      padding: MicroSpacing.cardTight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: tint),
                const SizedBox(width: MicroSpacing.xs),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.sectionLabel.copyWith(color: scheme.mutedText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          MicroSpacing.gapXS,
          // `statValue` usa cifre a larghezza fissa: senza, affiancando due tile i numeri
          // non si allineano e la riga sembra storta.
          Text(value, style: theme.textTheme.statValue.copyWith(color: tint)),
          if (hint != null)
            Text(
              hint!,
              style: theme.textTheme.cardMeta.copyWith(color: scheme.mutedText),
            ),
        ],
      ),
    );
  }
}

/// Anello di riempimento, con un valore al centro.
///
/// Usato per l'autonomia del combustibile e per i riempimenti in genere. Il valore e'
/// sempre limitato fra 0 e 1: una stima puo' superare il 100% e l'anello non deve
/// disegnarsi addosso.
class MicroProgressRing extends StatelessWidget {
  const MicroProgressRing({
    required this.value,
    required this.centerLabel,
    this.centerSubLabel,
    this.color,
    this.size = 140,
    super.key,
  });

  final double value;
  final String centerLabel;
  final String? centerSubLabel;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = color ?? scheme.primary;
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: clamped),
              duration: MicroDuration.slow,
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) => CircularProgressIndicator(
                value: animated,
                strokeWidth: size / 12,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(tint),
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: theme.textTheme.statValue.copyWith(fontSize: size / 4),
              ),
              if (centerSubLabel != null)
                Text(
                  centerSubLabel!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.cardMeta.copyWith(color: scheme.mutedText),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
