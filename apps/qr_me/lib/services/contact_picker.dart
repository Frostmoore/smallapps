import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';

import '../domain/qr_content.dart';

/// «Scegli dalla rubrica» del modulo Contatto (develop_microapps.md F17.10 punto 2).
///
/// ⚑ Il **selettore di sistema** (Android `ACTION_PICK` sui telefoni di `ContactsContract`, iOS
/// `CNContactPickerViewController`): **nessun permesso dei contatti**. L'app riceve solo il
/// contatto che la persona tocca, mai la rubrica. Chiedere `READ_CONTACTS` per un QR sarebbe
/// sproporzionato, e su Play un permesso sensibile in piu' da giustificare.
///
/// ⚑ Pacchetto `flutter_native_contact_picker` (F17.10, sorgente controllato il 2026-10-09 in
/// pub cache: nessuna dipendenza, nessuna rete, nessun SDK di terzi; il manifest Android e' vuoto).
/// ☠ Restituisce **solo nome e telefoni**: su Android il selettore e' quello dei numeri, e il
/// permesso temporaneo copre solo la riga scelta, non le email del contatto. L'email e gli altri
/// campi si aggiungono nel modulo, che resta sotto per controllare e completare.
///
/// Un'interfaccia perche' sotto `flutter test` non c'e' nessun plugin: i test di widget usano un
/// doppio finto ([contactPickerProvider] in lib/app/providers.dart).
abstract interface class ContactPicker {
  /// Apre il selettore; il contatto scelto, o null se si annulla.
  ///
  /// ☠ Puo' lanciare (nessuna app della rubrica, selettore gia' aperto): chi chiama lo dice
  /// all'utente.
  Future<ContactContent?> pick();
}

/// Da cio' che restituisce il selettore a un [ContactContent] per il modulo.
///
/// ⚑ Il numero e' il primo (su Android quello toccato: il selettore e' dei numeri). Un nome
/// vuoto resta vuoto: il modulo lo chiede, invece di inventarlo dal numero.
ContactContent? contactFromPicked({String? fullName, List<String>? phones, String? selected}) {
  final name = (fullName ?? '').trim();
  final phone = (selected ?? phones?.where((p) => p.trim().isNotEmpty).firstOrNull)?.trim();
  if (name.isEmpty && (phone == null || phone.isEmpty)) return null;
  return ContactContent(name: name, phone: (phone == null || phone.isEmpty) ? null : phone);
}

/// L'implementazione vera, con `flutter_native_contact_picker`.
class NativeContactPicker implements ContactPicker {
  const NativeContactPicker();

  @override
  Future<ContactContent?> pick() async {
    final c = await FlutterNativeContactPicker().selectContact();
    if (c == null) return null;
    return contactFromPicked(
      fullName: c.fullName,
      phones: c.phoneNumbers,
      selected: c.selectedPhoneNumber,
    );
  }
}
