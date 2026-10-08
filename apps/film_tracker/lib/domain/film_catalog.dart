import 'package:meta/meta.dart';

import 'film_types.dart';

/// Il catalogo delle pellicole precaricato al primo avvio (develop_microapps.md F6.2, F6.4).
///
/// ⚑ **Perche' sta nel dominio e non nel database**: il seed di `AppDatabase` e i test lo
/// leggono dallo stesso posto. Una lista copiata nel seed e un'altra nei test divergerebbero
/// alla prima emulsione aggiunta, e il test continuerebbe a passare.
///
/// ⚑ **Perche' un catalogo locale**: 25 emulsioni coprono quasi tutto l'uso reale, e chi usa
/// la ventiseiesima la aggiunge a mano (`FilmRepository.addCustomStock`). Un catalogo remoto
/// costerebbe un backend e una dipendenza di rete per un guadagno marginale.
///
/// ⚑ **Il formato del catalogo e' `35mm` per tutte**: molte (Portra, HP5+, Velvia...)
/// esistono anche in 120, ma una riga per formato raddoppierebbe la lista che l'utente
/// scorre. Il formato vero e' quello del **rullino** (`film_rolls.format`), che il form
/// preimposta dalla macchina scelta e non dalla pellicola.
///
/// ⚑ **"Pellicola personalizzata" non e' una riga**: e' la voce sempre presente nella UI che
/// apre la creazione di una pellicola dell'utente (F6.4). Non ha marca ne' ISO, e il suo nome
/// va tradotto: come riga del database sarebbe un dato finto in ogni statistica.

/// Una pellicola del catalogo, come dato puro (marca, nome, ISO, processo, formato).
@immutable
class CatalogStock {
  const CatalogStock(
    this.brand,
    this.name,
    this.iso, {
    required this.process,
    this.format = FilmFormat.mm35,
  });

  /// "Kodak". E' un nome proprio: non si traduce.
  final String brand;

  /// "Portra 400".
  final String name;

  /// Sensibilita' nominale.
  final int iso;

  final FilmProcess process;

  final FilmFormat format;

  /// "Kodak Portra 400": il valore che `film_rolls.filmName` copia (denormalizzato).
  String get displayName => '$brand $name';

  @override
  bool operator ==(Object other) =>
      other is CatalogStock &&
      other.brand == brand &&
      other.name == name &&
      other.iso == iso &&
      other.process == process &&
      other.format == format;

  @override
  int get hashCode => Object.hash(brand, name, iso, process, format);

  @override
  String toString() => 'CatalogStock($displayName, ISO $iso, ${process.key}, ${format.key})';
}

/// Le 25 emulsioni precaricate, nell'ordine del piano (F6.2).
///
/// ☠ Si scrive nel database **una volta sola**, alla creazione (`AppDatabase.migration`,
/// `onCreate`). Aggiungere una voce qui dopo il rilascio non la porta agli utenti esistenti:
/// serve un passo di migrazione che la inserisca se manca.
///
/// Note di dominio: XP2 Super e' un bianco e nero **cromogenico**, si sviluppa in C-41;
/// le Cinestill sono pellicole cinema (ECN-2) vendute senza remjet per lo sviluppo C-41.
const List<CatalogStock> kFilmCatalog = [
  CatalogStock('Kodak', 'Gold 200', 200, process: FilmProcess.c41),
  CatalogStock('Kodak', 'Portra 160', 160, process: FilmProcess.c41),
  CatalogStock('Kodak', 'Portra 400', 400, process: FilmProcess.c41),
  CatalogStock('Kodak', 'Portra 800', 800, process: FilmProcess.c41),
  CatalogStock('Kodak', 'Ultramax 400', 400, process: FilmProcess.c41),
  CatalogStock('Kodak', 'ColorPlus 200', 200, process: FilmProcess.c41),
  CatalogStock('Kodak', 'Tri-X 400', 400, process: FilmProcess.bw),
  CatalogStock('Kodak', 'T-Max 100', 100, process: FilmProcess.bw),
  CatalogStock('Kodak', 'T-Max 400', 400, process: FilmProcess.bw),
  CatalogStock('Kodak', 'Ektar 100', 100, process: FilmProcess.c41),
  CatalogStock('Ilford', 'HP5+', 400, process: FilmProcess.bw),
  CatalogStock('Ilford', 'FP4+', 125, process: FilmProcess.bw),
  CatalogStock('Ilford', 'Delta 100', 100, process: FilmProcess.bw),
  CatalogStock('Ilford', 'Delta 400', 400, process: FilmProcess.bw),
  CatalogStock('Ilford', 'XP2 Super', 400, process: FilmProcess.c41),
  CatalogStock('Fomapan', '100', 100, process: FilmProcess.bw),
  CatalogStock('Fomapan', '200', 200, process: FilmProcess.bw),
  CatalogStock('Fomapan', '400', 400, process: FilmProcess.bw),
  CatalogStock('Fujifilm', 'C200', 200, process: FilmProcess.c41),
  CatalogStock('Fujifilm', 'Superia X-TRA 400', 400, process: FilmProcess.c41),
  CatalogStock('Fujifilm', 'Velvia 50', 50, process: FilmProcess.e6),
  CatalogStock('Fujifilm', 'Provia 100F', 100, process: FilmProcess.e6),
  CatalogStock('Cinestill', '800T', 800, process: FilmProcess.c41),
  CatalogStock('Cinestill', '400D', 400, process: FilmProcess.c41),
  CatalogStock('Lomography', 'Color 400', 400, process: FilmProcess.c41),
];
