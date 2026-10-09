import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/entitlement.dart';
import '../../app/labels.dart';
import '../../app/paywall_config.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../domain/qr_content.dart';
import '../../domain/qr_style.dart';
import '../../l10n/generated/app_localizations.dart';

/// Le azioni su un QR condivise da piu' pagine (QR mostrato, risultato della lettura, elenchi),
/// ognuna con **il suo** controllo Pro.
///
/// ⚑ Il controllo Pro sta qui, nella funzione, e non solo nel pulsante: la stessa azione si
/// raggiunge da piu' pagine, e un controllo dimenticato in una di esse regalerebbe la funzione.
/// Le pagine Pro hanno comunque il loro `ProGate` sulla rotta (F17.0 punto 11).
///
/// Chiavi (F17.0 punto 6): preferiti oltre il primo → `unlimitedEntities`; stile →
/// `themeCustomization`; PNG → `imageExport`; moduli → `customCategories`; cronologia oltre 5 →
/// `fullHistory` (potatura).

/// Quante righe di cronologia tenere: 5 nel piano gratuito, nessun limite (null) col Pro.
int? historyKeep(FeatureGate gate) => gate.isPro ? null : gate.freeLimitOf(FeatureKey.fullHistory);

/// Registra un QR mostrato o letto **solo se la cronologia e' accesa** (F17.0 punto 7), poi
/// pota la cronologia al limite del piano. Restituisce l'id della riga, o null se non si e'
/// scritto niente.
///
/// ⚑ Cronologia gratis = 5 righe **vere** (F17.1.4): le altre si cancellano qui, subito.
Future<int?> recordIfEnabled(
  WidgetRef ref, {
  required QrContent content,
  required String payload,
  required String source,
  QrStyle style = QrStyle.plain,
}) async {
  if (!ref.read(historyEnabledProvider)) return null;
  final repo = ref.read(repositoryProvider);
  try {
    final id = await repo.recordShown(
      content: content,
      payload: payload,
      source: source,
      style: style,
    );
    await repo.pruneHistory(keep: historyKeep(ref.read(featureGateProvider)));
    return id;
  } on Object catch (error, stack) {
    // Un QR che non si registra si mostra lo stesso: la cronologia e' un di piu'.
    MicroLog.e('cronologia: registrazione fallita', error: error, stackTrace: stack);
    return null;
  }
}

/// «Salva nei preferiti»: controllo del limite (1 gratis), nome, scrittura. Restituisce l'id del
/// preferito, o null se non si e' salvato (limite, annullato).
///
/// ⚑ Con la cronologia spenta il QR non ha ancora una riga: si crea qui ([existingId] null),
/// perche' salvarlo e' esattamente la scelta esplicita che la cronologia spenta aspetta.
Future<int?> saveAsFavorite(
  BuildContext context,
  WidgetRef ref, {
  required QrDisplayArgs args,
  int? existingId,
}) async {
  final l = L.of(context);
  final repo = ref.read(repositoryProvider);
  final count = await repo.countFavorites();
  if (!context.mounted) return null;
  if (!ref.read(featureGateProvider).withinLimit(FeatureKey.unlimitedEntities, count)) {
    await showQrPaywall(context, ref, highlight: FeatureKey.unlimitedEntities);
    return null;
  }
  final title = await askTitle(context, title: l.save_title, initial: args.content.autoTitle);
  if (title == null || !context.mounted) return null;
  final id =
      existingId ??
      await repo.recordShown(
        content: args.content,
        payload: args.payload,
        source: args.source,
        style: args.style,
      );
  await repo.saveAsFavorite(id, title: title);
  if (context.mounted) MicroSnack.success(context, l.save_done);
  return id;
}

/// Il dialogo del nome (salvataggio e «Rinomina»). Null se si annulla o il nome e' vuoto.
Future<String?> askTitle(
  BuildContext context, {
  required String title,
  required String initial,
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (_) => _TitleDialog(title: title, initial: initial),
  );
  final t = result?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

/// ☠ Un widget con stato e non un controller creato e chiuso in [askTitle]: il dialogo si
/// ridisegna ancora durante l'animazione di chiusura, e un controller gia' chiuso li' fa
/// esplodere il campo di testo ("A TextEditingController was used after being disposed").
class _TitleDialog extends StatefulWidget {
  const _TitleDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_TitleDialog> createState() => _TitleDialogState();
}

class _TitleDialogState extends State<_TitleDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const ValueKey('title_field'),
        controller: _controller,
        autofocus: true,
        maxLength: 80,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: l.save_name),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.common_cancel)),
        TextButton(
          key: const ValueKey('title_ok'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l.common_save),
        ),
      ],
    );
  }
}

/// «Stile» (Pro, `themeCustomization`): apre `/style` e restituisce lo stile applicato, o null.
Future<QrStyle?> openStyle(BuildContext context, WidgetRef ref, QrDisplayArgs args) async {
  if (!ref.read(featureGateProvider).allows(FeatureKey.themeCustomization)) {
    // ⚑ Comprato il Pro dal paywall, si prosegue: chi ha toccato il pulsante vuole la funzione.
    if (!await showQrPaywall(context, ref, highlight: FeatureKey.themeCustomization) ||
        !context.mounted) {
      return null;
    }
  }
  return context.push<QrStyle>(Routes.style, extra: StyleArgs(display: args));
}

/// «Modifica» di un preferito con modulo (Pro, `customCategories`).
Future<void> openEditForm(
  BuildContext context,
  WidgetRef ref, {
  required QrKind kind,
  required int id,
}) async {
  if (!ref.read(featureGateProvider).allows(FeatureKey.customCategories)) {
    // ⚑ Comprato il Pro dal paywall, si prosegue: chi ha toccato il pulsante vuole la funzione.
    if (!await showQrPaywall(context, ref, highlight: FeatureKey.customCategories) ||
        !context.mounted) {
      return;
    }
  }
  await context.push(Routes.formOf(kind, id: id));
}

/// Un modulo nuovo (Pro, `customCategories`). ⚑ Senza il Pro si apre subito il paywall e non la
/// pagina col lucchetto: un passaggio in meno (come le statistiche di Film Tracker).
Future<void> openNewForm(BuildContext context, WidgetRef ref, QrKind kind) async {
  if (!ref.read(featureGateProvider).allows(FeatureKey.customCategories)) {
    // ⚑ Comprato il Pro dal paywall, si prosegue: chi ha toccato il pulsante vuole la funzione.
    if (!await showQrPaywall(context, ref, highlight: FeatureKey.customCategories) ||
        !context.mounted) {
      return;
    }
  }
  await context.push(Routes.formOf(kind));
}

/// «Condividi immagine» (Pro, `imageExport`): il PNG da 1024 px con lo stesso stile visto a
/// schermo (`QrRenderer.png`), condiviso con il foglio di sistema.
Future<void> shareQrImage(
  BuildContext context,
  WidgetRef ref, {
  required QrDisplayArgs args,
  required String title,
}) async {
  if (!ref.read(featureGateProvider).allows(FeatureKey.imageExport)) {
    // ⚑ Comprato il Pro dal paywall, si prosegue: chi ha toccato il pulsante vuole la funzione.
    if (!await showQrPaywall(context, ref, highlight: FeatureKey.imageExport) || !context.mounted) {
      return;
    }
  }
  final l = L.of(context);
  try {
    final logo = await ref.read(logoImageProvider(logoKeyOf(args.style)).future);
    final png = await ref
        .read(qrRendererProvider)
        .png(payload: args.payload, style: args.style, logo: logo);
    final paths = ref.read(appPathsProvider);
    final file = paths.file(paths.exports, 'qr-me-${DateTime.now().millisecondsSinceEpoch}.png');
    await AtomicFile.writeBytes(file, png);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        subject: title,
      ),
    );
  } on Object catch (error, stack) {
    MicroLog.e('PNG del QR non condiviso', error: error, stackTrace: stack);
    if (context.mounted) MicroSnack.error(context, l.display_shareFailed);
  }
}

/// «Copia»: il contenuto in chiaro (`plainText`), password compresa: chi tocca Copia la vuole.
Future<void> copyContent(BuildContext context, QrContent content) async {
  final l = L.of(context);
  await Clipboard.setData(ClipboardData(text: plainText(l, content)));
  if (context.mounted) MicroSnack.show(context, l.common_copied);
}

/// Copia un testo qualsiasi (una password, un campo del contatto) e lo dice.
Future<void> copyText(BuildContext context, String text) async {
  final l = L.of(context);
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) MicroSnack.show(context, l.common_copied);
}

/// Apre il contenuto con l'app giusta; se nessuna app sa farlo, lo dice.
Future<void> openContent(BuildContext context, WidgetRef ref, QrContent content) async {
  final l = L.of(context);
  final ok = await ref.read(contentActionsProvider).open(content);
  if (!ok && context.mounted) MicroSnack.error(context, l.result_noApp);
}

/// Il paywall generico (dalla riga della cronologia gratuita).
void openPro(BuildContext context, WidgetRef ref, FeatureKey key) =>
    unawaited(showQrPaywall(context, ref, highlight: key));
