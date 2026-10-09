import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../app/qr_palette.dart';
import '../../app/routes.dart';
import '../../data/database.dart';
import '../../domain/qr_content.dart';
import '../../domain/qr_encoder.dart';
import '../../domain/qr_style.dart';
import '../../l10n/generated/app_localizations.dart';
import '../common/neon.dart';
import '../common/qr_actions.dart';
import 'contact_form.dart';
import 'contact_sources.dart';
import 'email_form.dart';
import 'wifi_form.dart';
import 'wifi_sources.dart';

/// I moduli speciali (Pro, `customCategories`; il `ProGate` e' sulla rotta): **una pagina
/// sola**, un modulo per tipo, anteprima del QR dal vivo in alto (develop_microapps.md F17.1.6).
///
/// Con [id] modifica un preferito: il modulo parte dai suoi campi, e «Salva» riscrive il
/// contenuto della riga (titolo e stile restano) e torna indietro.
///
/// ⚑ «Mostra QR» registra in cronologia con `source: form` e apre `/qr/:id`; **con la
/// cronologia spenta** apre `/show` dalla memoria, senza scrivere (F17.0 punto 7).
///
/// ⚑ **Dopo la prova su iPad (F17.10, supera F17.1.6 per i moduli nuovi)**: Wi-Fi e Contatto
/// nuovi non partono dal modulo vuoto ma dalle loro **strade** ([WifiSources], [ContactSources]);
/// il modulo compare solo dopo («La rete a cui sei connesso», un contatto scelto dalla rubrica)
/// gia' compilato, o con «Inserisci a mano». Un QR di rete letto e la scheda «Io» vanno dritti al
/// QR, senza modulo. L'Email precompilata resta un modulo (non c'e' niente da cui leggerla).
/// La modifica di un preferito ([id]) apre sempre il modulo, come prima.
class FormPage extends ConsumerStatefulWidget {
  const FormPage({required this.kind, this.id, super.key});

  final QrKind kind;
  final int? id;

  @override
  ConsumerState<FormPage> createState() => _FormPageState();
}

/// A che punto e' un modulo nuovo di Wi-Fi o Contatto (F17.10).
enum _Stage {
  /// Le strade ([WifiSources], [ContactSources]), senza modulo.
  sources,

  /// Il modulo gia' compilato da una strada (nome della rete letto, contatto della rubrica).
  seeded,

  /// Il modulo vuoto, «Inserisci a mano» (e sempre per Email e per la modifica).
  manual,
}

class _FormPageState extends ConsumerState<FormPage> {
  QrContent? _content;
  QrCode? _row;
  bool _loading = false;
  bool _busy = false;

  /// Wi-Fi e Contatto nuovi: hanno le strade (e quindi «Altri modi» sopra il modulo).
  bool get _hasSources =>
      widget.id == null && (widget.kind == QrKind.wifi || widget.kind == QrKind.contact);

  /// Solo Wi-Fi e Contatto nuovi partono dalle strade; il resto (Email, modifica) dal modulo.
  late _Stage _stage = _hasSources ? _Stage.sources : _Stage.manual;

  /// Il contenuto con cui parte il modulo dopo una strada (o null: vuoto).
  QrContent? _seed;

  /// ⚑ Cambia a ogni strada: i moduli leggono i valori iniziali solo quando nascono, e una chiave
  /// nuova li fa rinascere con quelli nuovi.
  int _generation = 0;

  void _open(_Stage stage, [QrContent? seed]) => setState(() {
    _stage = stage;
    _seed = seed;
    _content = null;
    _generation++;
  });

  @override
  void initState() {
    super.initState();
    final id = widget.id;
    if (id != null) {
      _loading = true;
      unawaited(
        ref.read(repositoryProvider).byId(id).then((row) {
          if (mounted) {
            setState(() {
              _row = row;
              _loading = false;
            });
          }
        }),
      );
    }
  }

  /// «Mostra QR» (o «Salva» in modifica). [direct]: un contenuto gia' completo che non passa dal
  /// modulo (una rete letta da un QR, la scheda «Io»).
  Future<void> _submit([QrContent? direct]) async {
    final content = direct ?? _content;
    if (content == null || _busy) return;
    setState(() => _busy = true);
    final payload = QrEncoder.encode(content);
    final row = _row;
    try {
      if (row != null) {
        await ref
            .read(repositoryProvider)
            .updateContent(row.id, content: content, payload: payload);
        if (mounted) context.pop();
        return;
      }
      final id = await recordIfEnabled(
        ref,
        content: content,
        payload: payload,
        source: QrSource.form,
      );
      if (!mounted) return;
      if (id != null) {
        context.pushReplacement(Routes.qrOf(id));
      } else {
        context.pushReplacement(
          Routes.show,
          extra: QrDisplayArgs(content: content, payload: payload, source: QrSource.form),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (widget.id != null && _row == null) {
      return Scaffold(
        appBar: AppBar(),
        body: MicroEmptyState(
          icon: Icons.qr_code_2,
          title: l.common_notFound,
          message: l.display_missingBody,
        ),
      );
    }
    final title = Text(
      widget.id == null ? kindName(l, widget.kind) : l.form_editTitle(kindName(l, widget.kind)),
    );

    if (_stage == _Stage.sources) {
      return Scaffold(
        appBar: AppBar(title: title),
        body: ListView(
          padding: MicroSpacing.page,
          children: [
            if (widget.kind == QrKind.wifi)
              WifiSources(
                onRead: (wifi) => unawaited(_submit(wifi)),
                onConnected: (ssid) => _open(_Stage.seeded, WifiContent(ssid: ssid)),
                onManual: () => _open(_Stage.manual),
              )
            else
              ContactSources(
                onPicked: (c) => _open(_Stage.seeded, c),
                onMe: (c) => unawaited(_submit(c)),
                onManual: () => _open(_Stage.manual),
              ),
          ],
        ),
      );
    }

    final initial = _row?.content ?? _seed;
    // ⚑ Una riga di un altro tipo (un `?id=` che punta a un testo) non si apre col modulo
    // sbagliato: si parte vuoti.
    final start = initial?.kind == widget.kind ? initial : null;
    void onChanged(QrContent? c) => setState(() => _content = c);
    final form = switch (widget.kind) {
      QrKind.wifi => WifiForm(
        key: ValueKey('form_wifi_$_generation'),
        initial: start as WifiContent?,
        pasteHelp: _stage == _Stage.seeded,
        onChanged: onChanged,
      ),
      QrKind.contact => ContactForm(
        key: ValueKey('form_contact_$_generation'),
        initial: start as ContactContent?,
        onChanged: onChanged,
      ),
      QrKind.email => EmailForm(initial: start as EmailContent?, onChanged: onChanged),
      // ⚑ SMS e Telefono non hanno piu' un modulo (F17.10 punto 4): la rotta li rifiuta prima di
      // arrivare qui (`formKindOf`). Testo e link non l'hanno mai avuto.
      QrKind.sms || QrKind.phone || QrKind.text || QrKind.url => const SizedBox.shrink(),
    };
    final content = _content;
    final payload = content == null ? null : QrEncoder.encode(content);
    final tooLong =
        payload != null &&
        ref.watch(qrRendererProvider).choose(payload, _row?.style ?? QrStyle.plain).tooLong;

    return Scaffold(
      appBar: AppBar(title: title),
      body: ListView(
        padding: MicroSpacing.page,
        children: [
          if (_hasSources)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('form_otherWays'),
                onPressed: () => _open(_Stage.sources),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(l.form_otherWays),
              ),
            ),
          Center(
            child: _Preview(payload: tooLong ? null : payload, row: _row),
          ),
          if (tooLong)
            Padding(
              padding: const EdgeInsets.only(top: MicroSpacing.s),
              child: Text(
                l.form_tooLong,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          MicroSpacing.gapL,
          form,
          MicroSpacing.gapL,
          NeonButton(
            key: const ValueKey('form_submit'),
            label: widget.id == null ? l.home_show : l.common_save,
            icon: widget.id == null ? Icons.qr_code_2 : Icons.check,
            onPressed: content == null || tooLong || _busy ? null : () => unawaited(_submit()),
          ),
        ],
      ),
    );
  }
}

/// L'anteprima dal vivo: il QR del contenuto valido, o un riquadro vuoto con l'invito a compilare.
class _Preview extends ConsumerWidget {
  const _Preview({required this.payload, required this.row});

  final String? payload;
  final QrCode? row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = QrPalette.of(context);
    const side = 168.0;
    final payload = this.payload;
    if (payload == null) {
      return Container(
        key: const ValueKey('form_preview_empty'),
        width: side + 28,
        height: side + 28,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(MicroSpacing.l),
        decoration: p.card(radius: 26),
        child: Text(
          l.form_fillIn,
          textAlign: TextAlign.center,
          style: TextStyle(color: p.inkMuted),
        ),
      );
    }
    // ⚑ Con i colori del preferito che si modifica, ma senza logo: l'anteprima e' per il
    // contenuto, e il logo si rivede nella pagina del QR.
    final renderer = ref.watch(qrRendererProvider);
    final rowStyle = (row?.style ?? QrStyle.plain).copyWith(logo: const NoLogo());
    final style = renderer.choose(payload, rowStyle).tooLong ? QrStyle.plain : rowStyle;
    return QrPanel(
      key: const ValueKey('form_preview'),
      background: Color(style.background),
      padding: 14,
      glow: false,
      child: renderer.widget(payload: payload, style: style, size: side),
    );
  }
}
