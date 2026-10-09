import 'dart:async';

import 'shared_payload.dart';

/// La «cassetta della posta» delle condivisioni: da qui l'app riceve cio' che altre app le
/// hanno mandato con Condividi.
///
/// ⚑ E' un'interfaccia perche' le pagine e i router delle app si testano con
/// [FakeShareInbox], senza piattaforma e senza plugin.
abstract interface class ShareInbox {
  /// Cio' che ha **aperto** l'app quando era chiusa. Va letto una volta all'avvio, e subito
  /// dopo va chiamato [reset]: altrimenti la stessa condivisione torna a galla (anche su
  /// [incoming]). Lista vuota se l'app e' stata aperta normalmente.
  Future<List<SharedPayload>> initial();

  /// Cio' che arriva mentre l'app e' gia' aperta (o in background). Stream broadcast:
  /// piu' ascoltatori sono ammessi. Le liste vuote non vengono emesse.
  Stream<List<SharedPayload>> get incoming;

  /// Dice al plugin che l'ultima condivisione e' stata consumata.
  Future<void> reset();
}

/// Finta [ShareInbox] per i test delle app.
///
/// ```dart
/// final inbox = FakeShareInbox(initial: [const SharedText('ciao')]);
/// // ... monta la pagina con inbox ...
/// inbox.push([const SharedImage('/tmp/a.png')]); // arriva su incoming
/// expect(inbox.resetCount, 1);
/// ```
class FakeShareInbox implements ShareInbox {
  /// [initial] e' cio' che restituira' [ShareInbox.initial] finche' non si chiama [reset].
  FakeShareInbox({List<SharedPayload> initial = const []})
    : _initial = List<SharedPayload>.of(initial);

  List<SharedPayload> _initial;
  final StreamController<List<SharedPayload>> _incoming =
      StreamController<List<SharedPayload>>.broadcast();

  /// Quante volte e' stato chiamato [reset]: i test verificano che l'app lo chiami
  /// dopo aver letto [initial].
  int get resetCount => _resetCount;
  int _resetCount = 0;

  /// Quante volte e' stato chiamato [initial].
  int get initialCount => _initialCount;
  int _initialCount = 0;

  /// Sostituisce cio' che [initial] restituira' alla prossima chiamata, come se l'app
  /// fosse stata aperta da una nuova condivisione.
  void setInitial(List<SharedPayload> payloads) {
    _initial = List<SharedPayload>.of(payloads);
  }

  /// Simula una condivisione arrivata con l'app aperta. Una lista vuota non viene
  /// emessa, come nell'implementazione vera.
  void push(List<SharedPayload> payloads) {
    if (payloads.isEmpty) return;
    _incoming.add(List<SharedPayload>.unmodifiable(payloads));
  }

  /// Simula un errore della piattaforma sullo stream.
  void pushError(Object error) => _incoming.addError(error);

  /// Chiude lo stream. Da chiamare nel `tearDown` dei test.
  Future<void> close() => _incoming.close();

  @override
  Future<List<SharedPayload>> initial() async {
    _initialCount++;
    return List<SharedPayload>.unmodifiable(_initial);
  }

  @override
  Stream<List<SharedPayload>> get incoming => _incoming.stream;

  /// Come il plugin vero: dopo il reset [initial] restituisce una lista vuota.
  @override
  Future<void> reset() async {
    _resetCount++;
    _initial = const [];
  }
}
