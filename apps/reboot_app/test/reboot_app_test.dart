import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reboot_app/infrastructure/profile_providers.dart';
import 'package:reboot_app/src/reboot_app.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

void main() {
  testWidgets('keeps onboarding hidden while the profile is opening', (
    tester,
  ) async {
    final pendingService = Completer<LocalRebootService>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localRebootServiceProvider.overrideWith(
            (ref) => pendingService.future,
          ),
        ],
        child: const RebootApp(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Votre profil local chiffré est prêt.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows onboarding only after the local profile is ready', (
    tester,
  ) async {
    final service = await LocalRebootService.restore(journal: _MemoryJournal());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localRebootServiceProvider.overrideWith((ref) async => service),
        ],
        child: const RebootApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Votre profil local chiffré est prêt.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows a generic locked state without technical details', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (retryCount, error) => null,
        overrides: [
          localRebootServiceProvider.overrideWith(
            (ref) => throw StateError('secret path and platform detail'),
          ),
        ],
        child: const RebootApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Le profil local ne peut pas être ouvert.'),
      findsOneWidget,
    );
    expect(find.textContaining('secret path'), findsNothing);
    expect(find.text('Réessayer'), findsOneWidget);
  });
}

final class _MemoryJournal implements LocalEventJournal {
  final List<LocalJournalEntry> _entries = [];

  @override
  Future<List<LocalJournalEntry>> appendAll(List<EventRecord> events) async {
    final appended = <LocalJournalEntry>[];
    for (final event in events) {
      final entry = LocalJournalEntry(
        position: LocalJournalPosition(_entries.length + 1),
        event: event,
      );
      _entries.add(entry);
      appended.add(entry);
    }
    return appended;
  }

  @override
  Future<void> close() async {}

  @override
  Future<List<LocalJournalEntry>> readAll() async => List.of(_entries);
}
