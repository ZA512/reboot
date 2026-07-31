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
    expect(
      find.text('Choisissez le résultat que REBOOT doit créer'),
      findsOneWidget,
    );
  });

  testWidgets('saves a balance trajectory and shows the first weekly budget', (
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
    await service.createCashFlows(
      CreateCashFlowsCommand(
        definitions: [
          _monthlyFlow(
            title: 'Salaire 1',
            direction: CashFlowDirection.income,
            minorUnits: 300000,
          ),
          _monthlyFlow(
            title: 'Logement',
            direction: CashFlowDirection.outflow,
            minorUnits: 120000,
          ),
        ],
        effectiveFromCycleStart: LocalDate(2026, 4, 4),
        businessDate: LocalDate(2026, 4, 1),
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

    expect(find.text('Équilibre'), findsOneWidget);
    final calculate = find.text('Calculer mon budget semaine');
    await tester.scrollUntilVisible(
      calculate,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(calculate);
    await tester.pumpAndSettle();

    expect(service.configuration.annualCommitments, hasLength(1));
    expect(
      service.configuration.annualCommitments.single.strategy,
      TrajectoryStrategy.balance,
    );
    expect(
      service
          .buildAnnualBudget(LocalDate(2026, 4, 4))
          .recommendedWeeklyBudget
          .minorUnits,
      41500,
    );
    expect(find.text('Votre prochain budget semaine'), findsOneWidget);
    expect(find.textContaining('415'), findsWidgets);
    expect(find.byKey(const ValueKey('add-expense')), findsNothing);
    expect(find.textContaining('commence le samedi 4 avril'), findsOneWidget);
    expect(journal.entries, hasLength(4));
  });

  testWidgets('records, splits, displays, and deletes a quick expense', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    final journal = _MemoryJournal();
    final service = await _readyService(journal);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localRebootServiceProvider.overrideWith((ref) async => service),
          onboardingDeviceContextProvider.overrideWith(
            (ref) async => OnboardingDeviceContext(
              localDate: LocalDate(2026, 4, 5),
              timeZone: IanaTimeZoneId('Europe/Paris'),
            ),
          ),
        ],
        child: const RebootApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vous pouvez encore dépenser'), findsOneWidget);
    expect(find.byKey(const ValueKey('weekly-remaining')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-expense')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('expense-amount')), '150');
    await tester.enterText(
      find.byKey(const ValueKey('expense-label')),
      'Réparation',
    );
    await tester.tap(find.byKey(const ValueKey('expense-cycle-count')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 semaines').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('save-expense')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('save-expense')));
    await tester.pumpAndSettle();

    final projection = service.buildRollingBudget(LocalDate(2026, 4, 5));
    expect(projection.cycles.first.remaining.minorUnits, 36500);
    expect(find.text('Réparation'), findsOneWidget);
    expect(journal.entries, hasLength(6));

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Les 3 parts hebdomadaires seront toutes retirées ensemble. '
        'Leur historique d’audit restera dans le journal local.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    expect(service.expenses.activeExpenses, isEmpty);
    expect(
      service
          .buildRollingBudget(LocalDate(2026, 4, 5))
          .cycles
          .first
          .remaining
          .minorUnits,
      41500,
    );
    expect(journal.entries, hasLength(7));
  });

  testWidgets('separates a strong latest-week alert from a healthy trend', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    final journal = _MemoryJournal();
    final service = await _readyService(journal);
    await service.recordExpense(
      RecordExpenseCommand(
        amount: Money.fromMinorUnits(50000, Currency.eur),
        label: 'Semaine exceptionnelle',
        purchaseDate: LocalDate(2026, 5, 3),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localRebootServiceProvider.overrideWith((ref) async => service),
          onboardingDeviceContextProvider.overrideWith(
            (ref) async => OnboardingDeviceContext(
              localDate: LocalDate(2026, 5, 9),
              timeZone: IanaTimeZoneId('Europe/Paris'),
            ),
          ),
        ],
        child: const RebootApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Une correction mérite d’être envisagée'), findsOneWidget);
    await tester.tap(find.text('Une correction mérite d’être envisagée'));
    await tester.pumpAndSettle();

    expect(find.text('Tendances hebdomadaires'), findsOneWidget);
    expect(
      find.textContaining('Dernière semaine : dépassement'),
      findsOneWidget,
    );
    expect(find.textContaining('Trajectoire globale : +'), findsOneWidget);
    expect(
      find.textContaining('Le budget de la semaine suivante reste inchangé'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('observed-trend-balance')),
      findsOneWidget,
    );
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

CashFlowDefinition _monthlyFlow({
  required String title,
  required CashFlowDirection direction,
  required int minorUnits,
}) {
  return CashFlowDefinition.fixed(
    title: title,
    direction: direction,
    schedule: RecurringSchedule(
      firstOccurrence: LocalDate(2026, 4, 30),
      frequency: RecurrenceFrequency.monthly,
    ),
    amountPerOccurrence: Money.fromMinorUnits(minorUnits, Currency.eur),
    lastConfirmedOn: LocalDate(2026, 4, 1),
  );
}

Future<LocalRebootService> _readyService(_MemoryJournal journal) async {
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
  await service.createCashFlows(
    CreateCashFlowsCommand(
      definitions: [
        _monthlyFlow(
          title: 'Salaire 1',
          direction: CashFlowDirection.income,
          minorUnits: 300000,
        ),
        _monthlyFlow(
          title: 'Logement',
          direction: CashFlowDirection.outflow,
          minorUnits: 120000,
        ),
      ],
      effectiveFromCycleStart: LocalDate(2026, 4, 4),
      businessDate: LocalDate(2026, 4, 1),
    ),
  );
  await service.setTrajectoryPlan(
    SetTrajectoryPlanCommand(
      strategy: TrajectoryStrategy.balance,
      reserveContributions: Money.zero(Currency.eur),
      projectContributions: Money.zero(Currency.eur),
      safetyMargin: Money.zero(Currency.eur),
      effectiveFromCycleStart: LocalDate(2026, 4, 4),
      businessDate: LocalDate(2026, 4, 1),
    ),
  );
  return service;
}
