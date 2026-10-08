import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro_core/micro_core.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/providers.dart';
import '../../data/database.dart';
import '../../l10n/generated/app_localizations.dart';
import 'qr_links.dart';

/// L'etichetta QR del rullino (F6.12, `Routes.qr`; **gratis**: e' la funzione piu' raccontabile
/// dell'app). Codifica `filmtracker://roll/<n>`; sotto, il numero e la pellicola in chiaro.
///
/// ⚑ L'etichetta e' **bianca con inchiostro nero anche nel tema scuro**: si stampa e si
/// fotografa, e i lettori di QR leggono male (o non leggono) i codici chiari su fondo scuro.
/// Il resto della pagina segue il tema.
///
/// ⚑ Il numero in chiaro e' grande quanto basta per leggerlo senza telefono: l'etichetta serve
/// prima di tutto a non confondere due contenitori uguali sul tavolo.
class QrPage extends ConsumerWidget {
  const QrPage({required this.rollId, super.key});

  final int rollId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final roll = ref.watch(rollProvider(rollId));
    return Scaffold(
      appBar: AppBar(title: Text(l.qr_title)),
      body: switch (roll) {
        AsyncData(value: final FilmRoll r) => ListView(
          padding: MicroSpacing.page,
          children: [
            Center(child: RollQrLabel(roll: r)),
            MicroSpacing.gapXL,
            Text(
              l.qr_hint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        AsyncData() => Center(child: Text(l.qr_rollMissing)),
        AsyncError() => Center(child: Text(l.qr_rollMissing)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// L'etichetta vera e propria: il QR, il numero e la pellicola, su carta bianca.
///
/// Pubblica perche' potra' finire anche nel PDF annuale (F6.11) o in un foglio di etichette.
class RollQrLabel extends StatelessWidget {
  const RollQrLabel({required this.roll, this.maxWidth = 360, super.key});

  final FilmRoll roll;
  final double maxWidth;

  static const Color _paper = Colors.white;
  static const Color _ink = Colors.black;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final title = roll.title;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth.clamp(0, maxWidth).toDouble() : maxWidth;
        final qrSize = width - 2 * MicroSpacing.xl;
        return Container(
          width: width,
          padding: const EdgeInsets.all(MicroSpacing.xl),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: MicroRadius.card,
            border: Border.all(color: Colors.black12),
          ),
          // ⚑ Testi con stile esplicito e non del tema: nel tema scuro sarebbero chiari su bianco.
          child: DefaultTextStyle(
            style: const TextStyle(color: _ink),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: rollQrData(roll.sequenceNumber),
                  size: qrSize,
                  backgroundColor: _paper,
                  // M: regge un'etichetta un po' graffiata o piegata sul contenitore, e il link e'
                  // corto, quindi il codice resta a moduli grandi (si legge anche stampato piccolo).
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _ink),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: _ink),
                  semanticsLabel: l.qr_semantics(roll.sequenceNumber),
                ),
                MicroSpacing.gapM,
                Text(
                  l.qr_number(roll.sequenceNumber),
                  style: const TextStyle(color: _ink, fontSize: 44, fontWeight: FontWeight.w800, height: 1.1),
                ),
                Text(
                  roll.filmName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                if (title != null && title.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: MicroSpacing.xs),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black87, fontSize: 15),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
