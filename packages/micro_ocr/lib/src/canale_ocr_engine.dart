import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'ocr_engine.dart';
import 'riga_ocr.dart';

/// Il motore vero, dietro il MethodChannel 'micro_ocr'. Lo stesso canale su iOS
/// (Vision) e su Android (PP-OCRv5 su ORT 1.28.0).
class CanaleOcrEngine implements OcrEngine {
  CanaleOcrEngine({this.canale = const MethodChannel('micro_ocr')});

  /// Il canale (iniettabile nei test).
  final MethodChannel canale;

  @override
  Future<String> nome() async => (await _chiama<String>('nome')) ?? 'sconosciuto';

  @override
  Future<void> prepara() => _chiama<void>('prepara');

  @override
  Future<List<RigaOcr>> leggi(String percorsoImmagine, {required OcrModo modo}) async {
    final List<Map<Object?, Object?>>? grezze;
    try {
      grezze = await canale.invokeListMethod<Map<Object?, Object?>>('leggi', {
        'percorso': percorsoImmagine,
        'modo': modo.name,
      });
    } on PlatformException catch (e) {
      throw OcrNonDisponibile(e);
    } on MissingPluginException catch (e) {
      throw OcrNonDisponibile(e);
    }
    return [for (final m in grezze ?? const <Map<Object?, Object?>>[]) rigaDaMappa(m)];
  }

  @override
  Future<void> rilascia() => _chiama<void>('rilascia');

  /// Converte una mappa del canale in [RigaOcr].
  ///
  /// iOS manda il riquadro come lo da' Vision, con `'origine': 'basso'`: si converte
  /// con [Riquadro.daVision]. Android manda gia' l'origine in alto.
  @visibleForTesting
  static RigaOcr rigaDaMappa(Map<Object?, Object?> m) {
    final json = <String, Object?>{for (final e in m.entries) '${e.key}': e.value};
    final riga = RigaOcr.fromJson(json);
    if (json['origine'] != 'basso') return riga;
    final r = riga.riquadro;
    return RigaOcr(
      testo: riga.testo,
      riquadro: Riquadro.daVision(r.sinistra, r.alto, r.larghezza, r.altezza),
      confidenza: riga.confidenza,
    );
  }

  // ⚑ Ogni errore del canale diventa OcrNonDisponibile: l'app ha UNA sola eccezione
  // da gestire (ripiego sul tastierino), qualunque sia la piattaforma.
  Future<T?> _chiama<T>(String metodo) async {
    try {
      return await canale.invokeMethod<T>(metodo);
    } on PlatformException catch (e) {
      throw OcrNonDisponibile(e);
    } on MissingPluginException catch (e) {
      throw OcrNonDisponibile(e);
    }
  }
}
