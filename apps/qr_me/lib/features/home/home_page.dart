import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../app/qr_palette.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../domain/qr_decoder.dart';
import '../../domain/qr_encoder.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/neon.dart';
import '../common/qr_actions.dart';

/// Quanti preferiti mostra la home prima di «Vedi tutti».
const int kHomeFavorites = 3;

/// Quanti recenti mostra la home: gli stessi 5 della cronologia gratuita.
const int kHomeRecents = 5;

/// La home (develop_microapps.md F17.1.6): scrivi o incolla, leggi un QR, moduli, preferiti,
/// recenti.
///
/// ⚑ Lo stato vuoto non e' decorazione: «Condividi un link o un testo da qualunque app e scegli
/// QR Me» e' **la spiegazione dell'app**. Chi la apre dall'icona deve capire che il modo giusto
/// di usarla e' dalla condivisione.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// «Incolla»: legge gli appunti. Su iOS il sistema mostra il suo avviso di incolla: e' normale.
  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      if (mounted) MicroSnack.show(context, L.of(context).home_clipboardEmpty);
      return;
    }
    _text.text = text;
    _text.selection = TextSelection.collapsed(offset: text.length);
  }

  /// «Mostra QR»: un link scritto senza schema diventa un link (`decodeTyped`), il resto testo.
  void _show() {
    final raw = _text.text;
    if (raw.trim().isEmpty) return;
    final content = QrDecoder.decodeTyped(raw);
    FocusScope.of(context).unfocus();
    unawaited(
      context.push(
        Routes.show,
        extra: QrDisplayArgs(
          content: content,
          payload: QrEncoder.encode(content),
          source: QrSource.typed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = QrPalette.of(context);
    final pro = ref.watch(isProProvider);
    final favorites = ref.watch(favoritesProvider).value ?? const <QrCode>[];
    final history = ref.watch(historyProvider).value ?? const <QrCode>[];
    final historyOn = ref.watch(historyEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'QR '),
              TextSpan(
                text: 'Me',
                style: TextStyle(color: p.accent),
              ),
            ],
          ),
          style: p.title(size: 26),
        ),
        actions: [
          IconButton(
            key: const ValueKey('home_settings'),
            tooltip: l.settings_title,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => unawaited(context.push(Routes.settings)),
          ),
        ],
      ),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          SectionLabel(l.home_writeLabel),
          TextField(
            key: const ValueKey('home_text'),
            controller: _text,
            minLines: 2,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(hintText: l.home_writeHint),
          ),
          MicroSpacing.gapM,
          Row(
            children: [
              OutlinedButton.icon(
                key: const ValueKey('home_paste'),
                onPressed: () => unawaited(_paste()),
                icon: const Icon(Icons.content_paste, size: 18),
                label: Text(l.home_paste),
              ),
              MicroSpacing.hGapM,
              Expanded(
                child: NeonButton(
                  key: const ValueKey('home_show'),
                  label: l.home_show,
                  icon: Icons.qr_code_2,
                  onPressed: _text.text.trim().isEmpty ? null : _show,
                ),
              ),
            ],
          ),
          MicroSpacing.gapL,
          _ScanRow(onTap: () => unawaited(context.push(Routes.scan))),
          SectionLabel(l.home_formsLabel),
          Wrap(
            spacing: MicroSpacing.s,
            runSpacing: MicroSpacing.s,
            children: [
              for (final kind in kFormKinds)
                _FormChip(
                  key: ValueKey('form_chip_${kind.name}'),
                  icon: kindIcon(kind),
                  label: kindName(l, kind),
                  pro: !pro,
                  onTap: () => unawaited(openNewForm(context, ref, kind)),
                ),
            ],
          ),
          if (favorites.isNotEmpty) ...[
            SectionLabel(
              l.home_favoritesLabel,
              trailing: TextButton(
                onPressed: () => unawaited(context.push(Routes.saved)),
                child: Text(l.home_seeAll),
              ),
            ),
            for (final f in favorites.take(kHomeFavorites))
              QrRow(
                code: f,
                meta: rowMeta(l, f),
                onTap: () => unawaited(context.push(Routes.qrOf(f.id))),
              ),
          ],
          if (history.isNotEmpty) ...[
            SectionLabel(
              l.home_recentLabel,
              trailing: TextButton(
                key: const ValueKey('home_seeHistory'),
                onPressed: () => unawaited(context.push(Routes.history)),
                child: Text(l.home_seeAll),
              ),
            ),
            for (final h in history.take(kHomeRecents))
              QrRow(
                code: h,
                meta: rowMeta(l, h),
                onTap: () => unawaited(context.push(Routes.qrOf(h.id))),
              ),
            if (!pro && historyOn)
              Padding(
                padding: const EdgeInsets.only(top: MicroSpacing.xs),
                child: InkWell(
                  key: const ValueKey('home_freeHistory'),
                  onTap: () => openPro(context, ref, FeatureKey.fullHistory),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${l.home_freeHistory} '),
                        TextSpan(
                          text: l.home_freeHistoryCta,
                          style: TextStyle(
                            color: p.accent,
                            fontWeight: FontWeight.w700,
                            fontVariations: const [FontVariation('wght', 700)],
                          ),
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 13, color: p.inkMuted),
                  ),
                ),
              ),
          ],
          if (favorites.isEmpty && history.isEmpty) const _EmptyHint(),
        ],
      ),
    );
  }
}

/// «Leggi un QR»: la riga grande alta 64, con il quadratino verde dell'icona.
class _ScanRow extends StatelessWidget {
  const _ScanRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = QrPalette.of(context);
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('home_scan'),
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: MicroSpacing.m),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.qr_code_scanner, color: p.accent, size: 22),
                ),
                MicroSpacing.hGapM,
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.home_scan,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation('wght', 700)],
                          color: p.ink,
                        ),
                      ),
                      Text(l.home_scanBody, style: TextStyle(fontSize: 12, color: p.inkMuted)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: p.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Un modulo speciale: pillola alta 36, con il badge PRO quando il Pro non c'e'.
class _FormChip extends StatelessWidget {
  const _FormChip({
    required this.icon,
    required this.label,
    required this.pro,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool pro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = QrPalette.of(context);
    return Material(
      color: p.surface,
      shape: StadiumBorder(side: BorderSide(color: p.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: p.ink),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontVariations: const [FontVariation('wght', 600)],
                    color: p.ink,
                  ),
                ),
                if (pro) ...[const SizedBox(width: 6), const ProBadge(compact: true)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = QrPalette.of(context);
    return Padding(
      key: const ValueKey('home_empty'),
      padding: const EdgeInsets.only(top: MicroSpacing.xxl),
      child: Column(
        children: [
          Icon(Icons.ios_share, size: 44, color: p.accent),
          MicroSpacing.gapM,
          Text(l.home_emptyTitle, textAlign: TextAlign.center, style: p.title(size: 18)),
          MicroSpacing.gapS,
          Text(
            l.home_emptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: p.inkMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
