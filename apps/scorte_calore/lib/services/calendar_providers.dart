import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../data/database.dart';
import 'calendar_sync.dart';

/// Il servizio del calendario (F5.10).
final calendarSyncProvider = Provider<CalendarSyncService>(
  (ref) => CalendarSyncService(ref.watch(repositoryProvider)),
);

/// I promemoria nel calendario, per fonte.
final remindersProvider = StreamProvider<Map<int, CalendarReminder>>(
  (ref) => ref.watch(repositoryProvider).watchReminders().map((all) => {for (final r in all) r.fuelSourceId: r}),
);
