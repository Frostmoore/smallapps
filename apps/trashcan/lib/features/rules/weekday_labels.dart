import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

/// I nomi dei giorni della settimana nella lingua del dispositivo, e il selettore che li
/// mostra.
///
/// ⚑ Perché in un file a parte: i giorni si scelgono in tre punti diversi (wizard, editor
/// del tipo di rifiuto, editor della regola) e devono avere esattamente lo stesso aspetto e
/// le stesse etichette. Tre copie divergono al primo ritocco, e l'utente si accorge che
/// "MO" da una parte e "Lun" dall'altra sono la stessa cosa solo dopo averci pensato.

/// Una data campione che cade di lunedì, usata per ricavare i nomi dei giorni.
///
/// 2026-09-07 è un lunedì: sommando il numero del giorno della settimana (1 = lunedì) si
/// ottiene la data corrispondente senza tabelle di stringhe scritte a mano, che andrebbero
/// tradotte a mano per ogni lingua nuova.
DateTime _sample(int weekday) => DateTime(2026, 9, 6 + weekday);

/// L'iniziale del giorno, per i selettori a sette colonne.
///
/// ☠ In inglese lunedì e martedì iniziano entrambi per M, e martedì e giovedì per T: con
/// una lettera sola due colonne su sette diventano indistinguibili. Per questo in inglese se
/// ne usano due. In italiano una basta e sta meglio su schermi stretti.
String weekdayInitial(String locale, int weekday) {
  final name = DateFormat('EEEE', locale).format(_sample(weekday));
  return name.substring(0, locale.startsWith('it') ? 1 : 2).toUpperCase();
}

/// Il nome abbreviato: "mar", "Tue".
String weekdayShort(String locale, int weekday) =>
    DateFormat('EEE', locale).format(_sample(weekday));

/// Il nome per esteso: "martedì", "Tuesday".
String weekdayFull(String locale, int weekday) =>
    DateFormat('EEEE', locale).format(_sample(weekday));

/// L'elenco abbreviato dei giorni scelti, in ordine di settimana: "mar, ven".
String weekdayListShort(String locale, Set<int> weekdays) {
  final ordered = weekdays.toList()..sort();
  return ordered.map((d) => weekdayShort(locale, d)).join(', ');
}

/// La riga di sette cerchi con cui si scelgono i giorni della settimana.
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({
    required this.selected,
    required this.onToggle,
    this.color,
    super.key,
  });

  final Set<int> selected;
  final ValueChanged<int> onToggle;

  /// Il colore del tipo di rifiuto: i giorni selezionati lo usano come sfondo, così la
  /// pagina resta legata visivamente alla voce che si sta modificando.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
          _DayCircle(
            label: weekdayInitial(locale, weekday),
            selected: selected.contains(weekday),
            color: color ?? Theme.of(context).colorScheme.primary,
            onTap: () => onToggle(weekday),
          ),
      ],
    );
  }
}

class _DayCircle extends StatelessWidget {
  const _DayCircle({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: MicroDuration.quick,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? color : scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? MicroCard.foregroundOn(color) : scheme.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
