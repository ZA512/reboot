import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reboot_app/infrastructure/device_context_providers.dart';
import 'package:reboot_app/infrastructure/profile_providers.dart';
import 'package:reboot_app/src/reboot_app.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

void main() {
  testWidgets('keeps onboarding hidden while the profile is opening', (
    tester,
  ) async {
    _useLocale(tester, const Locale('en'));
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
    expect(find.text('Your encrypted local profile is ready.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows onboarding only after the local profile is ready', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
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
    _useLocale(tester, const Locale('fr'));
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

  testWidgets('uses English as the source locale', (tester) async {
    _useLocale(tester, const Locale('en'));
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

    expect(
      find.text('Take back control of your spending, one week at a time.'),
      findsOneWidget,
    );
    expect(find.text('Set up my REBOOT'), findsOneWidget);
  });

  testWidgets('creates the recommended shared Saturday profile atomically', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    final journal = _MemoryJournal();
    final service = await LocalRebootService.restore(journal: journal);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localRebootServiceProvider.overrideWith((ref) async => service),
          onboardingDeviceContextProvider.overrideWith(
            (ref) async => OnboardingDeviceContext(
              localDate: LocalDate(2026, 4, 1),
              timeZone: IanaTimeZoneId('Europe/Paris'),
            ),
          ),
        ],
        child: const RebootApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Configurer mon REBOOT'));
    await tester.pumpAndSettle();
    expect(find.text('Samedi'), findsOneWidget);
    expect(find.textContaining('Commencer le samedi 4 avril'), findsOneWidget);

    final submit = find.text('Créer mon profil REBOOT');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    final household = service.configuration.household!;
    expect(household.householdKind, HouseholdKind.sharedMainAccount);
    expect(household.cyclePolicies.single.anchorWeekday, Weekday.saturday);
    expect(household.cyclePolicies.single.effectiveFrom, LocalDate(2026, 4, 4));
    expect(journal.entries, hasLength(1));
    expect(
      find.text('Listez toutes les entrées et sorties d’argent'),
      findsOneWidget,
    );
  });

  testWidgets('allows solo catch-up from the previous complete cycle', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    final service = await LocalRebootService.restore(journal: _MemoryJournal());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localRebootServiceProvider.overrideWith((ref) async => service),
          onboardingDeviceContextProvider.overrideWith(
            (ref) async => OnboardingDeviceContext(
              localDate: LocalDate(2026, 4, 1),
              timeZone: IanaTimeZoneId('Europe/Paris'),
            ),
          ),
        ],
        child: const RebootApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configurer mon REBOOT'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Moi uniquement'));
    final previousStart = find.textContaining(
      'Commencer depuis le samedi 28 mars',
    );
    await tester.ensureVisible(previousStart);
    await tester.tap(previousStart);
    final submit = find.text('Créer mon profil REBOOT');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    final household = service.configuration.household!;
    expect(household.householdKind, HouseholdKind.solo);
    expect(
      household.cyclePolicies.single.effectiveFrom,
      LocalDate(2026, 3, 28),
    );
    expect(
      find.text('Listez toutes les entrées et sorties d’argent'),
      findsOneWidget,
    );
  });

  testWidgets('saves initial income and charges together before ready state', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    final journal = _MemoryJournal();
    final service = await LocalRebootService.restore(journal: journal);
    await service.initializeHousehold(
      InitializeHouseholdCommand(
        householdKind: HouseholdKind.sharedMainAccount,
        onboardingDate: LocalDate(2026, 4, 1),
        anchorWeekday: Weekday.saturday,
        timeZone: IanaTimeZoneId('Europe/Paris'),
        firstCycleChoice: FirstCycleStartChoice.nextAnchor,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localRebootServiceProvider.overrideWith((ref) async => service),
          onboardingDeviceContextProvider.overrideWith(
            (ref) async => OnboardingDeviceContext(
              localDate: LocalDate(2026, 4, 1),
              timeZone: IanaTimeZoneId('Europe/Paris'),
            ),
          ),
        ],
        child: const RebootApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salaire 1'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '3000,00');
    await tester.scrollUntilVisible(
      find.text('Ajouter cette ligne'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ajouter cette ligne'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Logement'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Logement'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '1200');
    await tester.scrollUntilVisible(
      find.text('Ajouter cette ligne'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ajouter cette ligne'));
    await tester.pumpAndSettle();

    final confirm = find.text('Confirmer les revenus et charges');
    await tester.scrollUntilVisible(
      confirm,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(service.configuration.cashFlows, hasLength(2));
    expect(journal.entries, hasLength(3));
    expect(find.text('Votre profil REBOOT commun est prêt.'), findsOneWidget);
  });

  testWidgets('does not expose a device time-zone failure', (tester) async {
    _useLocale(tester, const Locale('en'));
    final service = await LocalRebootService.restore(journal: _MemoryJournal());

    await tester.pumpWidget(
      ProviderScope(
        retry: (retryCount, error) => null,
        overrides: [
          localRebootServiceProvider.overrideWith((ref) async => service),
          onboardingDeviceContextProvider.overrideWith(
            (ref) => throw StateError('secret platform zone detail'),
          ),
        ],
        child: const RebootApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set up my REBOOT'));
    await tester.pumpAndSettle();

    expect(
      find.text('The device time zone could not be verified.'),
      findsNWidgets(2),
    );
    expect(find.textContaining('secret platform'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Create my REBOOT profile'),
          )
          .onPressed,
      isNull,
    );
  });
}

void _useLocale(WidgetTester tester, Locale locale) {
  tester.binding.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
}

final class _MemoryJournal implements LocalEventJournal {
  final List<LocalJournalEntry> _entries = [];

  List<LocalJournalEntry> get entries => List.unmodifiable(_entries);

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
