import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:micro_core/micro_core.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../app/waste_presets.dart';
import '../../domain/recurrence.dart';
import '../../l10n/generated/app_localizations.dart';

/// L'elenco dei tipi di rifiuto del calendario attivo.
class WasteTypesPage extends ConsumerWidget {
  const WasteTypesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final bundle = ref.watch(activeBundleProvider).value;
    final types = bundle?.wasteTypes ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l.wasteTypes_title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.wasteTypeNew),
        icon: const Icon(Icons.add),
        label: Text(l.common_add),
      ),
      body: SafeArea(
        child: types.isEmpty
            ? MicroEmptyState(
                icon: Icons.delete_outline,
                title: l.wasteTypes_empty,
                message: l.wasteTypes_emptyHint,
                actionLabel: l.common_add,
                onAction: () => context.push(Routes.wasteTypeNew),
              )
            : ListView(
                padding: MicroSpacing.page,
                children: [
                  for (final type in types)
                    Padding(
                      padding: const EdgeInsets.only(bottom: MicroSpacing.s),
                      child: MicroCard(
                        padding: EdgeInsets.zero,
                        child: MicroListTile(
                          title: type.name,
                          subtitle: _describeRule(context, ref, type.id),
                          leading: Icon(
                            WasteIcons.resolve(type.iconKey),
                            color: Color(type.colorValue),
                          ),
                          onTap: () => context.push(Routes.wasteTypeEditOf(type.id)),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  /// Un riassunto della regola, letto dal bundle gia' in memoria.
  ///
  /// Non si interroga il database qui: il bundle contiene gia' le regole tradotte, e una
  /// query per riga trasformerebbe una lista di dieci voci in dieci letture.
  String _describeRule(BuildContext context, WidgetRef ref, int wasteTypeId) {
    final l = L.of(context);
    final bundle = ref.watch(activeBundleProvider).value;
    final rule = bundle?.rules.where((r) => r.wasteTypeId == wasteTypeId).firstOrNull;
    if (rule == null) return l.rules_empty;
    return switch (rule.recurrence) {
      WeeklyRecurrence() => l.rules_kindWeekly,
      EveryNWeeksRecurrence(:final intervalWeeks) => l.rules_kindEveryNWeeks(intervalWeeks),
      MonthlyDayRecurrence() => l.rules_kindMonthlyDay,
      MonthlyNthWeekdayRecurrence() => l.rules_kindMonthlyNthWeekday,
      ManualDatesRecurrence() => l.rules_kindManual,
    };
  }
}
