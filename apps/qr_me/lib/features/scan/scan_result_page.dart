import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/entitlement.dart';
import '../../app/labels.dart';
import '../../app/qr_palette.dart';
import '../../app/routes.dart';
import '../../domain/qr_content.dart';
import '../../domain/qr_decoder.dart';
import '../../domain/qr_style.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/neon.dart';
import '../common/qr_actions.dart';

/// Cosa c'era nel QR letto, con le azioni del suo tipo (develop_microapps.md F17.1.6).
///
/// ⚑ **Un link letto non si apre mai da solo**: si mostra prima, con il **dominio in evidenza**.
/// Un QR puo' portare ovunque (un adesivo sopra quello vero al parcheggio), e il dominio e' la
/// cosa che dice se fidarsi.
///
/// ⚑ Un QR letto con un modulo speciale (un Wi-Fi) si mostra e si ri-mostra **gratis**: e' un
/// contenuto, non un modulo (F17.0 punto 6). Il Pro serve solo per restilizzarlo.
class ScanResultPage extends ConsumerStatefulWidget {
  const ScanResultPage({required this.args, super.key});

  final ScanResultArgs args;

  @override
  ConsumerState<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends ConsumerState<ScanResultPage> {
  late final QrContent _content = QrDecoder.decode(widget.args.raw);
  int? _id;
  bool _saved = false;

  /// Lo stile scelto con «Rigenera con stile». ☠ Senza questo campo lo stile restituito da
  /// `/style` andava perso: con la cronologia spenta del tutto (nessuna riga su cui scriverlo),
  /// con la cronologia accesa a meta' («Mostra come QR» e «Salva» ripartivano dal QR semplice).
  /// Stesso schema di `_DisplayBodyState._style` in qr_display_page.dart.
  QrStyle _style = QrStyle.plain;

  @override
  void initState() {
    super.initState();
    // La lettura entra in cronologia (se accesa) con `source: scanned` / `image`.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final id = await recordIfEnabled(
        ref,
        content: _content,
        payload: widget.args.raw,
        source: widget.args.source,
      );
      if (id != null && mounted) setState(() => _id = id);
    });
  }

  QrDisplayArgs get _display => QrDisplayArgs(
    content: _content,
    payload: widget.args.raw,
    source: widget.args.source,
    style: _style,
    qrId: _id,
  );

  /// «Rigenera con stile»: apre `/style` (Pro) e, applicato lo stile, **mostra subito** il QR
  /// rigenerato. ⚑ Chi ha toccato «Rigenera» vuole vedere il risultato, non tornare al testo
  /// letto; la pagina del QR riceve lo stile negli argomenti e, se la riga esiste, la «tocca»
  /// soltanto (lo stile ce l'ha gia' scritto `StylePage`).
  Future<void> _restyle() async {
    final style = await openStyle(context, ref, _display);
    if (style == null || !mounted) return;
    setState(() => _style = style);
    await context.push(Routes.show, extra: _display);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = QrPalette.of(context);
    final c = _content;
    final gate = ref.watch(featureGateProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.scanResult_title)),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(kindIcon(c.kind), color: p.accent),
              ),
              MicroSpacing.hGapM,
              Text(
                kindName(l, c.kind),
                key: const ValueKey('result_kind'),
                style: p.title(size: 20),
              ),
            ],
          ),
          MicroSpacing.gapL,
          _Body(content: c),
          MicroSpacing.gapL,
          ..._typeActions(context, c),
          MicroSpacing.gapS,
          OutlinedButton.icon(
            key: const ValueKey('result_show'),
            onPressed: () => unawaited(context.push(Routes.show, extra: _display)),
            icon: const Icon(Icons.qr_code_2),
            label: Text(l.result_showAsQr),
          ),
          MicroSpacing.gapS,
          OutlinedButton.icon(
            key: const ValueKey('result_style'),
            onPressed: () => unawaited(_restyle()),
            icon: const Icon(Icons.palette_outlined),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.result_restyle),
                if (!gate.allows(FeatureKey.themeCustomization)) ...[
                  MicroSpacing.hGapS,
                  const ProBadge(compact: true),
                ],
              ],
            ),
          ),
          MicroSpacing.gapS,
          OutlinedButton.icon(
            key: const ValueKey('result_save'),
            onPressed: _saved
                ? null
                : () async {
                    final id = await saveAsFavorite(context, ref, args: _display, existingId: _id);
                    if (id != null && mounted) {
                      setState(() {
                        _id = id;
                        _saved = true;
                      });
                    }
                  },
            icon: Icon(_saved ? Icons.star : Icons.star_outline),
            label: Text(_saved ? l.display_saved : l.common_save),
          ),
        ],
      ),
    );
  }

  /// Le azioni proprie del tipo: Apri, Chiama, Scrivi, Manda, Copia password, Copia.
  List<Widget> _typeActions(BuildContext context, QrContent c) {
    final l = L.of(context);
    Widget primary(String label, IconData icon) => NeonButton(
      key: const ValueKey('result_open'),
      label: label,
      icon: icon,
      onPressed: () => unawaited(openContent(context, ref, c)),
    );
    Widget copy(String label, String text) => Padding(
      padding: const EdgeInsets.only(top: MicroSpacing.s),
      child: OutlinedButton.icon(
        onPressed: () => unawaited(copyText(context, text)),
        icon: const Icon(Icons.copy, size: 18),
        label: Text(label),
      ),
    );
    return switch (c) {
      UrlContent(:final uri) => [
        primary(l.result_open, Icons.open_in_new),
        copy(l.result_copyLink, uri.toString()),
      ],
      PhoneContent(:final number) => [
        primary(l.result_call, Icons.call),
        copy(l.common_copy, number),
      ],
      EmailContent(:final to) => [
        primary(l.result_email, Icons.mail_outline),
        copy(l.common_copy, to),
      ],
      SmsContent(:final number) => [
        primary(l.result_sms, Icons.sms_outlined),
        copy(l.common_copy, number),
      ],
      // ⚑ Connettersi da qui non si fa (F17.1.6): su Android 10+ serve un'API di suggerimento con
      // conferma di sistema, su iOS un'entitlement Hotspot; la fotocamera di sistema lo fa meglio.
      WifiContent(:final password, :final security) => [
        if (security != WifiSecurity.none) copy(l.result_copyPassword, password),
      ],
      ContactContent() || TextContent() => [copy(l.common_copy, plainText(l, c))],
    };
  }
}

/// Il contenuto leggibile. Per un link, il **dominio** grande e l'indirizzo intero sotto.
class _Body extends StatelessWidget {
  const _Body({required this.content});

  final QrContent content;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = QrPalette.of(context);
    final muted = TextStyle(fontSize: 14, color: p.inkMuted, height: 1.4);
    final c = content;
    return Container(
      padding: const EdgeInsets.all(MicroSpacing.l),
      decoration: p.card(),
      child: switch (c) {
        UrlContent(:final uri) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.result_goesTo, style: p.sectionLabel),
            MicroSpacing.gapXS,
            Text(
              uri.host,
              key: const ValueKey('result_domain'),
              style: p.title(size: 22, color: p.accent),
            ),
            MicroSpacing.gapS,
            SelectableText(uri.toString(), style: muted),
          ],
        ),
        _ => SelectableText(
          plainText(l, c),
          key: const ValueKey('result_text'),
          style: TextStyle(fontSize: 16, color: p.ink, height: 1.4),
        ),
      },
    );
  }
}
