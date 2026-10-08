import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:micro_core/micro_core.dart';

import '../../data/database.dart';
import '../../data/film_repository.dart';
import '../../domain/roll_status.dart';
import '../../l10n/generated/app_localizations.dart';

/// I pezzi comuni ai moduli di sviluppo e stampa (F6.7): costi in centesimi, date di
/// consegna e ritorno, autocompletamento del laboratorio, stato suggerito del rullino.
///
/// ⚑ Stanno qui, e non dentro una delle due pagine, perche' sviluppo e stampa sono due form
/// separate (F6.7) con gli stessi campi di laboratorio: due copie divergerebbero alla prima
/// correzione. Li usa anche il foglio della pellicola personalizzata (il campo con i
/// suggerimenti, per la marca).

// ── Costi ────────────────────────────────────────────────────────────────────

/// Gli euro digitati in centesimi interi: "12,50" -> 1250, "6.5" -> 650, "6,50 €" -> 650.
/// Null per un campo vuoto, un testo non numerico o un importo negativo.
///
/// ⚑ Passa da `Money.tryParse` di micro_core (F6.7: "costi in `Money`"), che capisce la
/// virgola e il punto e scarta il simbolo dell'euro. I costi si salvano in centesimi interi
/// perche' le somme in `double` sbagliano all'ultimo centesimo nelle statistiche (F6.10).
int? parseCostCents(String input) {
  if (input.trim().isEmpty) return null;
  final money = Money.tryParse(input);
  if (money == null || money.isNegative) return null;
  return money.cents;
}

/// Un campo costo e' valido se vuoto (i costi sono tutti facoltativi) o se e' un importo >= 0.
bool isCostTextValid(String input) => input.trim().isEmpty || parseCostCents(input) != null;

/// I centesimi come testo modificabile nel campo: "12,50" in italiano, "12.50" in inglese.
/// Rilegge uguale con [parseCostCents].
String costCentsToText(int? cents, String locale) =>
    cents == null ? '' : Money.cents(cents).formatPlain(locale: locale);

/// I centesimi come importo da leggere: "12,50 €".
String formatCostCents(int cents, String locale) => Money.cents(cents).format(locale: locale);

/// Il campo di un costo in euro, con l'errore quando il testo non e' un importo.
class CostField extends StatelessWidget {
  const CostField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.fieldKey,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  /// La chiave del `TextField`, per i test.
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final ok = isCostTextValid(controller.text);
    return TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: '€',
        helperText: l.common_optional,
        errorText: ok ? null : l.dev_costInvalid,
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

// ── Date ─────────────────────────────────────────────────────────────────────

/// Una data facoltativa (consegna, ritorno): la riga apre il calendario, la crocetta la
/// toglie.
///
/// ⚑ Il calendario e' limitato da [firstDate] e [lastDate], che il modulo calcola dall'altra
/// data: il ritorno non puo' precedere la consegna. Lo vieta anche un CHECK dello schema, ma
/// un errore SQL al salvataggio sarebbe incomprensibile; impedirlo nel calendario no.
class LabDateTile extends StatelessWidget {
  const LabDateTile({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.icon = Icons.event_outlined,
    super.key,
  });

  final String label;
  final CivilDate? value;
  final ValueChanged<CivilDate?> onChanged;
  final CivilDate firstDate;
  final CivilDate lastDate;
  final IconData icon;

  Future<void> _pick(BuildContext context) async {
    // La data proposta deve stare dentro i limiti, o showDatePicker fallisce un assert.
    var initial = value ?? lastDate;
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.toLocalMidnight(),
      firstDate: firstDate.toLocalMidnight(),
      lastDate: lastDate.toLocalMidnight(),
    );
    if (picked != null) onChanged(CivilDate.fromDateTime(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final v = value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(v == null ? l.dev_dateNone : DateFormat.yMMMMd(locale).format(v.toLocalMidnight())),
      trailing: v == null
          ? const Icon(Icons.chevron_right)
          : IconButton(
              tooltip: l.dev_dateClear,
              icon: const Icon(Icons.close),
              onPressed: () => onChanged(null),
            ),
      onTap: () => _pick(context),
    );
  }
}

// ── Testo con suggerimenti ───────────────────────────────────────────────────

/// Un campo di testo che suggerisce i valori gia' usati mentre si scrive: il laboratorio
/// (F6.7, dai nomi di sviluppi e stampe) e la marca della pellicola personalizzata.
///
/// ⚑ `RawAutocomplete` con il controller **del modulo**, e non `Autocomplete`: il modulo
/// deve poter precompilare il campo (modifica di uno sviluppo esistente) e leggerlo al
/// salvataggio, e `Autocomplete` tiene il controller per se'. Si suggeriscono i nomi che
/// **contengono** il testo, senza maiuscole: "foto" trova "Fotoservice Roma".
class SuggestionTextField extends StatefulWidget {
  const SuggestionTextField({
    required this.controller,
    required this.suggestions,
    required this.label,
    this.helperText,
    this.maxLength,
    this.fieldKey,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;

  /// I valori da proporre, nell'ordine in cui proporli (il repository li da' dal piu' usato).
  final List<String> suggestions;
  final String label;
  final String? helperText;
  final int? maxLength;
  final Key? fieldKey;
  final VoidCallback? onChanged;

  @override
  State<SuggestionTextField> createState() => _SuggestionTextFieldState();
}

class _SuggestionTextFieldState extends State<SuggestionTextField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Iterable<String> _options(TextEditingValue value) {
    final q = value.text.trim().toLowerCase();
    if (q.isEmpty) return widget.suggestions.take(6);
    return widget.suggestions
        // Il nome gia' scritto per intero non si propone: non c'e' niente da completare.
        .where((s) => s.toLowerCase().contains(q) && s.toLowerCase() != q)
        .take(6);
  }

  @override
  Widget build(BuildContext context) => RawAutocomplete<String>(
    textEditingController: widget.controller,
    focusNode: _focus,
    optionsBuilder: _options,
    onSelected: (_) => widget.onChanged?.call(),
    fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextField(
      key: widget.fieldKey,
      controller: controller,
      focusNode: focusNode,
      textCapitalization: TextCapitalization.words,
      maxLength: widget.maxLength,
      decoration: InputDecoration(labelText: widget.label, helperText: widget.helperText),
      onChanged: (_) => widget.onChanged?.call(),
      onSubmitted: (_) => onSubmitted(),
    ),
    optionsViewBuilder: (context, onSelected, options) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              for (final o in options)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.history, size: 20),
                  title: Text(o),
                  onTap: () => onSelected(o),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ── Stato del rullino ────────────────────────────────────────────────────────

/// Dopo aver salvato uno sviluppo o una stampa, porta il rullino [rollId] nello stato che gli
/// eventi suggeriscono (`FilmRepository.suggestedStatus`). Restituisce il nuovo stato, o null
/// se non e' cambiato niente.
///
/// ⚑ **Lo fa da solo, senza chiedere**, e lo dice con uno snack. Chi registra "consegnato il
/// 5 ottobre" ha appena detto che il rullino e' in laboratorio: chiederglielo una seconda volta
/// sarebbe una domanda con una sola risposta sensata, ripetuta a ogni rullino. Lo stato resta
/// comunque modificabile a mano dal dettaglio (F6.3: "suggerisce, non impone").
///
/// ⚑ **Solo in avanti**: si applica una transizione ammessa da `RollStatusMachine`, mai una
/// forzata, con un'eccezione. Se il rullino e' ancora `loaded`, un evento di laboratorio vuol
/// dire che e' uscito dalla macchina (l'utente non ha toccato "Rullino terminato"): li' si
/// forza, perche' lasciarlo "in macchina" con i negativi gia' tornati sarebbe falso. Non si
/// torna mai indietro da soli: togliere la data di ritorno a uno sviluppo non riporta un
/// rullino `developed` in laboratorio (potrebbe essere una correzione, non un evento).
Future<RollStatus?> applySuggestedStatus(FilmRepository repo, int rollId) async {
  final roll = await repo.rollById(rollId);
  final suggested = await repo.suggestedStatus(rollId);
  if (roll == null || suggested == null) return null;
  final current = roll.statusEnum;
  if (suggested == current) return null;
  final allowed = const RollStatusMachine().canTransition(current, suggested);
  if (!allowed && current != RollStatus.loaded) return null;
  await repo.setRollStatus(rollId, suggested, force: !allowed);
  return suggested;
}

/// Il messaggio di salvataggio, che dice anche lo stato nuovo del rullino se e' cambiato.
String labSavedMessage(L l, RollStatus? newStatus) => switch (newStatus) {
  RollStatus.exposed => l.dev_savedNowExposed,
  RollStatus.sentForDevelopment => l.dev_savedNowAtLab,
  RollStatus.developed => l.dev_savedNowDeveloped,
  RollStatus.printed => l.dev_savedNowPrinted,
  _ => l.dev_saved,
};
