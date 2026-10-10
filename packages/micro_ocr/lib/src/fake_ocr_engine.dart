import 'ocr_engine.dart';
import 'riga_ocr.dart';

/// Motore finto per i test delle app: restituisce [righe] (o lancia [errore]) dopo
/// [ritardo], e registra i percorsi richiesti in [letti].
class FakeOcrEngine implements OcrEngine {
  FakeOcrEngine({List<RigaOcr> righe = const [], this.ritardo = Duration.zero, this.errore})
    : righe = List.of(righe);

  /// Modificabile fra un leggi e l'altro.
  List<RigaOcr> righe;

  final Duration ritardo;

  /// Se non nullo, [leggi] lo lancia (dopo [ritardo]). Un [OcrNonDisponibile] simula
  /// il motore assente.
  final Object? errore;

  /// I percorsi richiesti, per le asserzioni.
  final List<String> letti = [];

  /// I modi richiesti, nello stesso ordine di [letti].
  final List<OcrModo> modi = [];

  /// Quante volte [prepara] e [rilascia] sono state chiamate.
  int preparazioni = 0;
  int rilasci = 0;

  @override
  Future<String> nome() async => 'fake';

  @override
  Future<void> prepara() async => preparazioni++;

  @override
  Future<List<RigaOcr>> leggi(String percorsoImmagine, {required OcrModo modo}) async {
    letti.add(percorsoImmagine);
    modi.add(modo);
    if (ritardo > Duration.zero) await Future<void>.delayed(ritardo);
    final e = errore;
    if (e != null) throw e;
    return List.unmodifiable(righe);
  }

  @override
  Future<void> rilascia() async => rilasci++;
}
