import 'dart:async';

import 'package:camera/camera.dart' show CameraException;
import 'package:flutter/material.dart';
import 'package:micro_core/micro_core.dart';

import '../../l10n/generated/app_localizations.dart';

/// Il mirino delle pagine con la fotocamera (Cartellino 4:3 orizzontale, Scontrino 3:5 verticale):
/// angoli verdi come nell'icona, velo nero al 55% fuori (develop_microapps.md F12.1.12).

/// Il rettangolo del mirino dentro [area]: [larghezza] frazione della larghezza, rapporto
/// [rapporto] = larghezza / altezza, centrato e alzato di [alzato] (lascia spazio ai bottoni in
/// basso). ⚑ Se l'altezza non ci sta, si riduce tutto mantenendo il rapporto.
Rect rettangoloMirino(Size area, {required double larghezza, required double rapporto, double alzato = 40}) {
  var w = area.width * larghezza;
  var h = w / rapporto;
  final hMassima = area.height * 0.62;
  if (h > hMassima) {
    h = hMassima;
    w = h * rapporto;
  }
  final centro = area.center(Offset.zero) - Offset(0, alzato);
  return Rect.fromCenter(center: centro, width: w, height: h);
}

/// Il mirino in frazioni 0..1 dell'area (quello che vuole `Fotocamera.ritagliaAlMirino`).
Rect inFrazioni(Rect r, Size area) =>
    Rect.fromLTRB(r.left / area.width, r.top / area.height, r.right / area.width, r.bottom / area.height);

/// Il velo e gli angoli.
class PittoreMirino extends CustomPainter {
  const PittoreMirino({required this.mirino, required this.colore});

  final Rect mirino;
  final Color colore;

  @override
  void paint(Canvas canvas, Size size) {
    final velo = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(mirino, const Radius.circular(16)));
    canvas.drawPath(velo, Paint()..color = Colors.black.withValues(alpha: 0.55));
    final tratto = Paint()
      ..color = colore
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final lato = (mirino.shortestSide * 0.16).clamp(18.0, 40.0);
    final r = mirino;
    for (final (punto, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(punto, punto + Offset(lato * dx, 0), tratto)
        ..drawLine(punto, punto + Offset(0, lato * dy), tratto);
    }
  }

  @override
  bool shouldRepaint(PittoreMirino old) => old.mirino != mirino || old.colore != colore;
}

/// La fotocamera non parte: permesso negato o nessuna fotocamera (come `ScanErrorView` di QR Me).
///
/// ⚑ Permesso negato: «Apri le impostazioni» (la sola via d'uscita dopo un rifiuto definitivo) e
/// sotto «Riprova» (che basta dopo un rifiuto singolo su Android). Non si sa quale dei due sia
/// (servirebbe `permission_handler`, che non si usa): si offrono entrambe, su Android e su iOS.
/// «Da una foto» resta usabile: la pagina lo lascia in basso.
class ErroreFotocamera extends StatelessWidget {
  const ErroreFotocamera({required this.errore, required this.onRiprova, required this.onImpostazioni, super.key});

  final Object errore;
  final VoidCallback onRiprova;
  final Future<void> Function() onImpostazioni;

  /// `CameraAccessDenied…` su Android e iOS (anche `…WithoutPrompt`: negato in passato).
  static bool negato(Object e) => e is CameraException && e.code.startsWith('CameraAccessDenied');

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final no = negato(errore);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MicroEmptyState(
                key: const ValueKey('fotocamera_errore'),
                icon: Icons.no_photography_outlined,
                title: no ? l.fotocamera_negataTitolo : l.fotocamera_erroreTitolo,
                message: no ? l.fotocamera_negataTesto : l.fotocamera_erroreTesto,
                actionLabel: no ? l.fotocamera_apriImpostazioni : l.common_retry,
                onAction: no ? () => unawaited(onImpostazioni()) : onRiprova,
              ),
              if (no) TextButton(onPressed: onRiprova, child: Text(l.common_retry)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Il bottone di scatto: 72 dp, anello bianco, centro accento.
class BottoneScatto extends StatelessWidget {
  const BottoneScatto({required this.onTap, required this.semantica, this.colore, super.key});

  final VoidCallback? onTap;
  final String semantica;
  final Color? colore;

  @override
  Widget build(BuildContext context) {
    final attivo = onTap != null;
    return Semantics(
      button: true,
      enabled: attivo,
      label: semantica,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: attivo ? 1 : 0.4), width: 4),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (colore ?? Colors.white).withValues(alpha: attivo ? 1 : 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un bottone tondo sul nero (torcia, «Da una foto»), con l'etichetta sotto.
class BottoneTondo extends StatelessWidget {
  const BottoneTondo({required this.icona, required this.etichetta, required this.onTap, super.key});

  final IconData icona;
  final String etichetta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: etichetta,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: SizedBox(
          width: 84,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.16)),
                child: Icon(icona, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                etichetta,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
