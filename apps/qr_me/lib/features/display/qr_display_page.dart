import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../app/qr_palette.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../domain/qr_content.dart';
import '../../domain/qr_style.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/screen_boost.dart';
import '../common/neon.dart';
import '../common/qr_actions.dart';

/// IL motivo dell'app: il QR a tutto schermo, luminoso (develop_microapps.md F17.1.6).
///
/// Due ingressi: `/show` con un contenuto in memoria ([QrDisplayPage.args]) e `/qr/:id` con una
/// riga salvata ([QrDisplayPage.saved]), che segue le modifiche (stile, nome, preferito).
class QrDisplayPage extends ConsumerWidget {
  const QrDisplayPage.args(QrDisplayArgs this.args, {super.key}) : id = null;

  const QrDisplayPage.saved(int this.id, {super.key}) : args = null;

  final QrDisplayArgs? args;
  final int? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = this.id;
    if (id == null) return _DisplayBody(args: args!);
    return switch (ref.watch(qrCodeProvider(id))) {
      AsyncData(value: final QrCode row) => _DisplayBody(args: argsOfRow(row), row: row),
      AsyncData() || AsyncError() => const _Missing(),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

/// Gli argomenti di `/show` ricavati da una riga salvata.
QrDisplayArgs argsOfRow(QrCode row) => QrDisplayArgs(
  content: row.content,
  payload: row.payload,
  source: row.source,
  style: row.style,
  qrId: row.id,
);

class _Missing extends StatelessWidget {
  const _Missing();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: MicroEmptyState(
      icon: Icons.qr_code_2,
      title: L.of(context).common_notFound,
      message: L.of(context).display_missingBody,
    ),
  );
}

class _DisplayBody extends ConsumerStatefulWidget {
  const _DisplayBody({required this.args, this.row});

  final QrDisplayArgs args;

  /// La riga salvata, se si arriva da `/qr/:id`.
  final QrCode? row;

  @override
  ConsumerState<_DisplayBody> createState() => _DisplayBodyState();
}

class _DisplayBodyState extends ConsumerState<_DisplayBody> {
  late final ScreenBoost _boost;
  late final AppLifecycleListener _lifecycle;

  /// L'id della riga: quello della riga salvata, quello passato, o quello appena registrato.
  int? _id;

  /// Salvato nei preferiti da questa pagina (per `/show`, che non segue il database).
  bool _savedHere = false;

  /// Lo stile applicato da questa pagina (per `/show`; la riga salvata lo riceve dallo stream).
  QrStyle? _style;

  bool _showPassword = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _id = widget.row?.id ?? widget.args.qrId;
    // ⚑ Luminosita' e schermo acceso appena la pagina esiste, e ripristino **anche in pausa**
    // (F17.1.6). ☠ Solo in dispose, uscendo con il tasto Home il telefono resterebbe a luminosita'
    // piena finche' non si riapre l'app.
    _boost = ref.read(screenBoostProvider);
    unawaited(_boost.enable());
    _lifecycle = AppLifecycleListener(
      onHide: () => unawaited(_boost.disable()),
      onShow: () => unawaited(_boost.enable()),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_record()));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_boost.disable());
    super.dispose();
  }

  /// La cronologia: una riga gia' esistente si "tocca" (torna in cima); un QR nuovo si registra
  /// solo se la cronologia e' accesa (`recordIfEnabled`, con la potatura del piano gratuito).
  Future<void> _record() async {
    final id = _id;
    if (id != null) {
      await ref.read(repositoryProvider).touch(id);
      return;
    }
    final a = widget.args;
    if (ref.read(qrRendererProvider).choose(a.payload, a.style).tooLong) return;
    final recorded = await recordIfEnabled(
      ref,
      content: a.content,
      payload: a.payload,
      source: a.source,
      style: a.style,
    );
    if (recorded != null && mounted) setState(() => _id = recorded);
  }

  QrDisplayArgs get _current {
    final a = widget.args;
    return QrDisplayArgs(
      content: a.content,
      payload: a.payload,
      source: a.source,
      style: _style ?? a.style,
      qrId: _id,
    );
  }

  bool get _isFavorite => widget.row?.isFavorite ?? _savedHere;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = QrPalette.of(context);
    final args = _current;
    final renderer = ref.watch(qrRendererProvider);
    final choice = renderer.choose(args.payload, args.style);
    final title = widget.row?.title ?? args.content.autoTitle;

    if (choice.tooLong) {
      return Scaffold(
        appBar: AppBar(),
        body: MicroEmptyState(
          icon: Icons.format_size,
          title: l.display_tooLongTitle,
          message: l.display_tooLongBody(args.payload.characters.length),
        ),
      );
    }

    final logo = ref.watch(logoImageProvider(logoKeyOf(args.style))).value;
    final labelLocked = !ref.watch(featureGateProvider).allows(FeatureKey.imageExport);
    return Scaffold(
      appBar: AppBar(
        title: Text(kindName(l, args.content.kind)),
        // ⚑ «Genera etichetta» (Pro, F17.10 punto 5) nella barra e non nella griglia: la griglia ha
        // gia' 4-5 azioni, una sesta le stringe sotto i 60 dp e taglia le etichette (al 130% di
        // testo diventano illeggibili), e una seconda riga ruberebbe altezza al QR, che e' il
        // motivo dell'app. Con testo e icona, non solo icona: si deve capire senza tenerla premuta.
        actions: [
          TextButton.icon(
            key: const ValueKey('action_label'),
            onPressed: () => unawaited(openLabel(context, ref, args: args, title: title)),
            icon: Icon(labelLocked ? Icons.lock_outline : Icons.print_outlined, size: 18),
            label: Text(l.display_label),
          ),
          MicroSpacing.hGapS,
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  // Il lato del pannello: il piu' grande possibile, meno 16 per lato (F17.1.6).
                  final panel = math
                      .max(120, math.min(c.maxWidth, c.maxHeight) - 2 * 16)
                      .toDouble();
                  return Center(
                    child: QrPanel(
                      key: const ValueKey('qr_panel'),
                      background: Color(args.style.background),
                      child: renderer.widget(
                        payload: args.payload,
                        style: args.style,
                        size: panel - 44,
                        logo: logo,
                        semanticsLabel: l.display_semantics(title),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(MicroSpacing.l, MicroSpacing.s, MicroSpacing.l, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: p.title(size: 24),
                  ),
                  MicroSpacing.gapXS,
                  _ContentLine(
                    content: args.content,
                    expanded: _expanded,
                    showPassword: _showPassword,
                    onToggleExpanded: () => setState(() => _expanded = !_expanded),
                    onTogglePassword: () => setState(() => _showPassword = !_showPassword),
                  ),
                  if (choice.logoDropped) _Note(text: l.display_logoDropped),
                  if (choice.dense) _Note(text: l.display_dense),
                  MicroSpacing.gapM,
                  _Actions(
                    args: args,
                    title: title,
                    favorite: _isFavorite,
                    canEdit: _isFavorite && kFormKinds.contains(args.content.kind),
                    onSaved: (id) => setState(() {
                      _id = id;
                      _savedHere = true;
                    }),
                    onStyled: (style) => setState(() => _style = style),
                  ),
                  MicroSpacing.gapM,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Il contenuto in chiaro sotto il QR: 3 righe, tocca per espandere. Il Wi-Fi ha la password
/// **nascosta** con l'occhio: il QR si mostra a un ospite, e la password scritta sotto non deve
/// leggerla chi passa (F17.1.6).
class _ContentLine extends StatelessWidget {
  const _ContentLine({
    required this.content,
    required this.expanded,
    required this.showPassword,
    required this.onToggleExpanded,
    required this.onTogglePassword,
  });

  final QrContent content;
  final bool expanded;
  final bool showPassword;
  final VoidCallback onToggleExpanded;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = QrPalette.of(context);
    final style = TextStyle(fontSize: 14, color: p.inkMuted, height: 1.35);
    final c = content;
    if (c is WifiContent && c.security != WifiSecurity.none) {
      return Row(
        children: [
          Expanded(
            child: Text(
              plainText(l, c, withPassword: showPassword),
              key: const ValueKey('content_text'),
              style: style,
            ),
          ),
          IconButton(
            key: const ValueKey('toggle_password'),
            tooltip: showPassword ? l.display_hidePassword : l.display_showPassword,
            icon: Icon(
              showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: p.inkMuted,
            ),
            onPressed: onTogglePassword,
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: onToggleExpanded,
      child: Text(
        plainText(l, c),
        key: const ValueKey('content_text'),
        maxLines: expanded ? null : 3,
        overflow: expanded ? null : TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: MicroSpacing.xs),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.warning),
        MicroSpacing.hGapS,
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ],
    ),
  );
}

/// La griglia delle azioni (F17.1.6): Salva, Stile (Pro), Immagine (Pro), Copia, e per un
/// preferito con modulo Modifica (Pro). Le Pro mostrano il lucchetto finche' non c'e' il Pro.
class _Actions extends ConsumerWidget {
  const _Actions({
    required this.args,
    required this.title,
    required this.favorite,
    required this.canEdit,
    required this.onSaved,
    required this.onStyled,
  });

  final QrDisplayArgs args;
  final String title;
  final bool favorite;
  final bool canEdit;
  final void Function(int id) onSaved;
  final void Function(QrStyle style) onStyled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final gate = ref.watch(featureGateProvider);
    final tiles = <Widget>[
      ActionTile(
        key: const ValueKey('action_save'),
        icon: favorite ? Icons.star : Icons.star_outline,
        label: favorite ? l.display_saved : l.common_save,
        // ⚑ Gia' preferito: niente da fare qui (si rinomina o si toglie dall'elenco Preferiti).
        onTap: favorite
            ? () => MicroSnack.show(context, l.display_alreadySaved)
            : () async {
                final id = await saveAsFavorite(context, ref, args: args, existingId: args.qrId);
                if (id != null) onSaved(id);
              },
      ),
      ActionTile(
        key: const ValueKey('action_style'),
        icon: Icons.palette_outlined,
        label: l.display_style,
        locked: !gate.allows(FeatureKey.themeCustomization),
        onTap: () async {
          final style = await openStyle(context, ref, args);
          if (style != null) onStyled(style);
        },
      ),
      ActionTile(
        key: const ValueKey('action_image'),
        icon: Icons.ios_share,
        label: l.display_image,
        locked: !gate.allows(FeatureKey.imageExport),
        onTap: () => unawaited(shareQrImage(context, ref, args: args, title: title)),
      ),
      ActionTile(
        key: const ValueKey('action_copy'),
        icon: Icons.copy,
        label: l.common_copy,
        onTap: () => unawaited(copyContent(context, args.content)),
      ),
      if (canEdit)
        ActionTile(
          key: const ValueKey('action_edit'),
          icon: Icons.edit_outlined,
          label: l.common_edit,
          locked: !gate.allows(FeatureKey.customCategories),
          onTap: () =>
              unawaited(openEditForm(context, ref, kind: args.content.kind, id: args.qrId!)),
        ),
    ];
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) MicroSpacing.hGapS,
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}
