import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/qr_palette.dart';
import '../../app/routes.dart';
import '../../domain/qr_content.dart';
import '../../domain/qr_decoder.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/readability_check.dart' show QrReaderUnavailable;
import '../../services/wifi_name_reader.dart';
import '../common/neon.dart';

/// Le strade del modulo Wi-Fi (develop_microapps.md F17.10 punto 1). Il proprietario, dopo la
/// prova su iPad: «Non mi deve far inserire dati a mano, così è ridicolo».
///
/// 1. **«Inquadra il QR della rete»** → `/scan/wifi` (la `ScanPage` in modalita' solo Wi-Fi), che
///    torna con il [WifiContent] letto → [onRead].
/// 2. **«Da un'immagine»** → il selettore di sistema e `QrImageReader` (lo screenshot del QR che
///    Android mostra in Impostazioni › Wi-Fi › Condividi, la foto dell'etichetta del router) →
///    [onRead]. Un'immagine senza QR di rete: messaggio, nessun salvataggio.
/// 3. **«La rete a cui sei connesso»** → il nome dal telefono ([WifiNameReader]), con il permesso
///    di posizione chiesto **solo qui** e dopo una spiegazione → [onConnected] con l'SSID; la
///    password poi si incolla (`WifiForm.pasteHelp`). Se il nome non si legge, un riquadro dice
///    perche' e offre la strada a mano.
/// 4. **«Inserisci a mano»**: ultima riga, piccola → [onManual].
class WifiSources extends ConsumerStatefulWidget {
  const WifiSources({
    required this.onRead,
    required this.onConnected,
    required this.onManual,
    super.key,
  });

  /// Una rete letta da un QR (fotocamera o immagine): la pagina la mostra subito come QR.
  final ValueChanged<WifiContent> onRead;

  /// Il nome della rete connessa: la pagina apre il modulo con il nome gia' scritto.
  final ValueChanged<String> onConnected;

  final VoidCallback onManual;

  @override
  ConsumerState<WifiSources> createState() => _WifiSourcesState();
}

class _WifiSourcesState extends ConsumerState<WifiSources> {
  /// Perche' l'ultimo tentativo di leggere il nome non e' andato; null se non c'e' niente da dire.
  WifiNameStatus? _notice;
  bool _reading = false;

  Future<void> _scan() async {
    final wifi = await context.push<WifiContent>(Routes.scanWifi);
    if (wifi != null && mounted) widget.onRead(wifi);
  }

  Future<void> _fromImage() async {
    final l = L.of(context);
    final path = await ref.read(pickImageProvider)();
    if (path == null || !mounted) return;
    List<String> values;
    try {
      values = await ref.read(qrImageReaderProvider).read(path);
    } on QrReaderUnavailable {
      if (mounted) MicroSnack.error(context, l.scan_readerUnavailable);
      return;
    }
    if (!mounted) return;
    if (values.isEmpty) {
      MicroSnack.show(context, l.share_noQrInImage);
      return;
    }
    final wifi = QrDecoder.firstWifi(values);
    if (wifi == null) {
      MicroSnack.show(context, l.wifiSource_notWifiImage);
      return;
    }
    widget.onRead(wifi);
  }

  Future<void> _connected() async {
    final reader = ref.read(wifiNameReaderProvider);
    // ⚑ La spiegazione **prima** del dialogo del sistema: «posizione» per leggere il nome di una
    // rete sembra un abuso, se nessuno dice perche' lo chiede Android (o iOS).
    if (await reader.needsPermission()) {
      if (!mounted || !await _explain()) return;
    }
    if (!mounted) return;
    setState(() {
      _reading = true;
      _notice = null;
    });
    final result = await reader.lookup();
    if (!mounted) return;
    setState(() => _reading = false);
    final ssid = result.ssid;
    if (result.status == WifiNameStatus.found && ssid != null) {
      widget.onConnected(ssid);
    } else {
      setState(() => _notice = result.status);
    }
  }

  Future<bool> _explain() async {
    final l = L.of(context);
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l.wifiSource_permissionTitle),
        content: SingleChildScrollView(
          child: Text(ios ? l.wifiSource_permissionIos : l.wifiSource_permissionAndroid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l.common_cancel),
          ),
          TextButton(
            key: const ValueKey('wifi_permission_ok'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(l.wifiSource_permissionContinue),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final notice = _notice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: MicroSpacing.m),
          child: Text(
            l.wifiSource_intro,
            style: TextStyle(fontSize: 14, color: QrPalette.of(context).inkMuted, height: 1.4),
          ),
        ),
        SourceCard(
          key: const ValueKey('wifi_source_scan'),
          icon: Icons.qr_code_scanner,
          title: l.wifiSource_scan,
          body: l.wifiSource_scanBody,
          onTap: () => unawaited(_scan()),
        ),
        SourceCard(
          key: const ValueKey('wifi_source_image'),
          icon: Icons.photo_library_outlined,
          title: l.wifiSource_image,
          body: l.wifiSource_imageBody,
          onTap: () => unawaited(_fromImage()),
        ),
        SourceCard(
          key: const ValueKey('wifi_source_connected'),
          icon: Icons.wifi,
          title: l.wifiSource_connected,
          body: l.wifiSource_connectedBody,
          busy: _reading,
          onTap: () => unawaited(_connected()),
        ),
        if (notice != null) _Notice(status: notice, onManual: widget.onManual),
        MicroSpacing.gapS,
        Center(
          child: TextButton(
            key: const ValueKey('wifi_manual'),
            onPressed: widget.onManual,
            child: Text(l.wifiSource_manual, style: const TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

/// Perche' il nome della rete non si e' letto, e cosa fare.
class _Notice extends ConsumerWidget {
  const _Notice({required this.status, required this.onManual});

  final WifiNameStatus status;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final p = QrPalette.of(context);
    final text = switch (status) {
      WifiNameStatus.denied => l.wifiSource_denied,
      WifiNameStatus.deniedForever => l.wifiSource_deniedForever,
      WifiNameStatus.locationOff => l.wifiSource_locationOff,
      WifiNameStatus.unavailable || WifiNameStatus.found => l.wifiSource_unavailable,
    };
    return Container(
      key: const ValueKey('wifi_notice'),
      margin: const EdgeInsets.only(top: MicroSpacing.xs),
      padding: const EdgeInsets.all(MicroSpacing.m),
      decoration: p.card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.warning),
              MicroSpacing.hGapS,
              Expanded(
                child: Text(text, style: TextStyle(fontSize: 14, color: p.ink, height: 1.35)),
              ),
            ],
          ),
          MicroSpacing.gapS,
          Wrap(
            spacing: MicroSpacing.s,
            runSpacing: MicroSpacing.xs,
            alignment: WrapAlignment.end,
            children: [
              if (status == WifiNameStatus.deniedForever)
                TextButton(
                  key: const ValueKey('wifi_notice_settings'),
                  onPressed: () => unawaited(ref.read(appSettingsProvider).open()),
                  child: Text(l.scan_openSettings),
                ),
              TextButton(
                key: const ValueKey('wifi_notice_manual'),
                onPressed: onManual,
                child: Text(l.wifiSource_manual),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
