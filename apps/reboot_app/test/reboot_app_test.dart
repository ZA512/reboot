import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reboot_app/bonuses/received_bonus_screen.dart';
import 'package:reboot_app/health/health_screen.dart';
import 'package:reboot_app/infrastructure/device_context_providers.dart';
import 'package:reboot_app/infrastructure/profile_providers.dart';
import 'package:reboot_app/l10n/app_localizations.dart';
import 'package:reboot_app/refunds/refunds_screen.dart';
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
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('expense-nature-necessary')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('expense-nature-necessary')));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('expense-cycle-count')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();
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
    await tester.scrollUntilVisible(
      find.text('Réparation'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Réparation'), findsOneWidget);
    expect(
      service.expenses.activeExpenses.single.nature,
      ExpenseNature.necessary,
    );
    expect(journal.entries, hasLength(7));

    await tester.scrollUntilVisible(
      find.byIcon(Icons.delete_outline),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();
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
    expect(journal.entries, hasLength(8));
  });

  testWidgets('reuses a frequent label and its latest optional nature', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    final service = await _readyService(_MemoryJournal());
    await service.recordExpense(
      RecordExpenseCommand(
        amount: Money.fromMinorUnits(8000, Currency.eur),
        label: 'Courses',
        purchaseDate: LocalDate(2026, 4, 5),
        nature: ExpenseNature.necessary,
      ),
    );
    await service.recordExpense(
      RecordExpenseCommand(
        amount: Money.fromMinorUnits(6000, Currency.eur),
        label: 'Courses',
        purchaseDate: LocalDate(2026, 4, 5),
        nature: ExpenseNature.pleasure,
      ),
    );

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
    await tester.tap(find.byKey(const ValueKey('add-expense')));
    await tester.pumpAndSettle();

    expect(find.text('Raccourcis récents et fréquents'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'Courses'));
    await tester.pumpAndSettle();
    final labelField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('expense-label')),
    );
    expect(labelField.controller!.text, 'Courses');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('expense-nature-pleasure')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('expense-nature-pleasure')),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('schedules income and charge changes for the next REBOOT only', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    final journal = _MemoryJournal();
    final service = await _readyService(journal);
    final currentCycle = LocalDate(2026, 4, 4);
    final nextCycle = LocalDate(2026, 4, 11);
    final currentBudget = service
        .buildAnnualBudget(currentCycle)
        .recommendedWeeklyBudget;

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
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open-assumptions')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('open-assumptions')));
    await tester.pumpAndSettle();

    expect(find.text('Revenus et charges'), findsOneWidget);
    expect(
      find.textContaining('La semaine déjà commencée ne change jamais'),
      findsOneWidget,
    );

    final salaryTile = find.ancestor(
      of: find.text('Salaire 1'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: salaryTile, matching: find.byIcon(Icons.more_vert)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier').last);
    await tester.pumpAndSettle();
    expect(find.text('Modifier cette hypothèse'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), '3200');
    await tester.scrollUntilVisible(
      find.text('Planifier cette modification'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Planifier cette modification'));
    await tester.pumpAndSettle();

    final salary = service.configuration.cashFlows.values.singleWhere(
      (flow) =>
          flow.definitionForCycleStarting(currentCycle)?.title == 'Salaire 1',
    );
    expect(salary.revisions, hasLength(2));
    expect(salary.latestRevision.effectiveFromCycleStart, nextCycle);
    expect(
      salary
          .definitionForCycleStarting(currentCycle)!
          .referenceAmountPerOccurrence
          .minorUnits,
      300000,
    );
    expect(
      salary
          .definitionForCycleStarting(nextCycle)!
          .referenceAmountPerOccurrence
          .minorUnits,
      320000,
    );
    expect(
      service.buildAnnualBudget(currentCycle).recommendedWeeklyBudget,
      currentBudget,
    );
    expect(
      service.buildAnnualBudget(nextCycle).recommendedWeeklyBudget,
      isNot(currentBudget),
    );
    expect(find.textContaining('Nouvelle valeur à partir du'), findsOneWidget);

    final housingTile = find.ancestor(
      of: find.text('Logement'),
      matching: find.byType(ListTile),
    );
    final housingMenu = find.descendant(
      of: housingTile,
      matching: find.byIcon(Icons.more_vert),
    );
    await tester.ensureVisible(housingMenu);
    await tester.pumpAndSettle();
    await tester.tap(housingMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();
    expect(find.text('Mettre fin à cette hypothèse ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    final housing = service.configuration.cashFlows.values.singleWhere(
      (flow) =>
          flow.definitionForCycleStarting(currentCycle)?.title == 'Logement',
    );
    expect(housing.definitionForCycleStarting(currentCycle), isNotNull);
    expect(housing.definitionForCycleStarting(nextCycle), isNull);
    expect(find.textContaining('Prend fin le'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Ajouter').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Essence');
    await tester.enterText(find.byType(TextFormField).at(1), '100');
    await tester.scrollUntilVisible(
      find.text('Ajouter cette ligne'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ajouter cette ligne'));
    await tester.pumpAndSettle();

    final fuel = service.configuration.cashFlows.values.singleWhere(
      (flow) => flow.definitionForCycleStarting(nextCycle)?.title == 'Essence',
    );
    expect(fuel.definitionForCycleStarting(currentCycle), isNull);
    expect(fuel.latestRevision.effectiveFromCycleStart, nextCycle);
    expect(find.text('Essence'), findsOneWidget);
  });

  testWidgets('schedules a new trajectory without changing the current week', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = await _readyService(_MemoryJournal());
    final currentCycle = LocalDate(2026, 4, 4);
    final nextCycle = LocalDate(2026, 4, 11);
    final currentBudget = service
        .buildAnnualBudget(currentCycle)
        .recommendedWeeklyBudget;

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
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open-trajectory')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('open-trajectory')));
    await tester.pumpAndSettle();

    expect(find.text('Trajectoire REBOOT'), findsOneWidget);
    expect(find.text('Trajectoire acceptée'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit-trajectory')));
    await tester.pumpAndSettle();

    expect(find.text('Modifier la trajectoire'), findsOneWidget);
    await tester.tap(find.text('Construire un coussin'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '5200');
    await tester.scrollUntilVisible(
      find.text('Planifier cette trajectoire'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Planifier cette trajectoire'));
    await tester.pumpAndSettle();

    expect(service.configuration.annualCommitments, hasLength(2));
    final current = service.configuration.commitmentsForCycleStarting(
      currentCycle,
    )!;
    final future = service.configuration.commitmentsForCycleStarting(
      nextCycle,
    )!;
    expect(current.strategy, TrajectoryStrategy.balance);
    expect(future.strategy, TrajectoryStrategy.cushion);
    expect(future.effectiveFromCycleStart, nextCycle);
    expect(future.reserveContributions.minorUnits, 520000);
    expect(
      service.buildAnnualBudget(currentCycle).recommendedWeeklyBudget,
      currentBudget,
    );
    expect(
      service.buildAnnualBudget(nextCycle).recommendedWeeklyBudget.minorUnits,
      currentBudget.minorUnits - 10000,
    );
    expect(find.text('Prochaine trajectoire'), findsOneWidget);
    expect(
      find.textContaining('Une nouvelle trajectoire est planifiée'),
      findsOneWidget,
    );
  });

  testWidgets('schedules a new REBOOT day through one visible transition', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = await _readyService(_MemoryJournal());

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
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open-cycle-settings')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('open-cycle-settings')));
    await tester.pumpAndSettle();

    expect(find.text('Rythme hebdomadaire'), findsOneWidget);
    expect(find.text('Samedi'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('new-reboot-day')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lundi').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Transition du'), findsOneWidget);
    expect(find.textContaining('2 jours'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save-reboot-day')));
    await tester.pumpAndSettle();

    final household = service.configuration.household!;
    expect(household.cyclePolicies, hasLength(2));
    expect(household.latestCyclePolicy.anchorWeekday, Weekday.monday);
    expect(household.latestCyclePolicy.effectiveFrom, LocalDate(2026, 4, 11));
    expect(
      household.latestCyclePolicy.firstNormalCycleStart,
      LocalDate(2026, 4, 13),
    );
    final transition = household.cycleContaining(LocalDate(2026, 4, 12));
    expect(transition.kind, WeeklyCycleKind.transition);
    expect(transition.start, LocalDate(2026, 4, 11));
    expect(transition.endExclusive, LocalDate(2026, 4, 13));
    expect(find.text('Rythme hebdomadaire'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('open-cycle-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Samedi'), findsOneWidget);
    expect(find.textContaining('Lundi est déjà planifié'), findsOneWidget);
    expect(find.byKey(const ValueKey('new-reboot-day')), findsNothing);
  });

  testWidgets('uses a real reserve without reducing the weekly budget', (
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
    final weeklyBefore = service
        .buildRollingBudget(LocalDate(2026, 4, 5))
        .cycles
        .first
        .remaining;

    await tester.scrollUntilVisible(
      find.text('Créer votre première réserve'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer votre première réserve'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-reserve')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reserve-name')),
      'Imprévus',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reserve-opening-balance')),
      '500',
    );
    await tester.tap(find.text('Réserve virtuelle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compte de réserve réel').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-create-reserve')));
    await tester.pumpAndSettle();

    expect(service.reserves.reserves.values.single.balance.minorUnits, 50000);
    await tester.tap(find.widgetWithText(FilledButton, 'Utiliser'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('expense-amount')), '125');
    await tester.enterText(
      find.byKey(const ValueKey('expense-label')),
      'Vétérinaire',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('save-expense')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('save-expense')));
    await tester.pumpAndSettle();

    expect(find.text('Rappel de virement'), findsOneWidget);
    expect(
      find.textContaining('REBOOT n’effectuera ni ne vérifiera'),
      findsOneWidget,
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'J’ai compris, enregistrer'),
    );
    await tester.pumpAndSettle();

    expect(service.reserves.reserves.values.single.balance.minorUnits, 37500);
    expect(service.expenses.activeExpenses, isEmpty);
    expect(
      service.buildRollingBudget(LocalDate(2026, 4, 5)).cycles.first.remaining,
      weeklyBefore,
    );
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

    await tester.scrollUntilVisible(
      find.text('Une correction mérite d’être envisagée'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Une correction mérite d’être envisagée'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(
        of: find.text('Une correction mérite d’être envisagée'),
        matching: find.byType(ListTile),
      ),
    );
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
    await tester.scrollUntilVisible(
      find.text('À quoi le budget semaine a servi'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('À quoi le budget semaine a servi'), findsOneWidget);
    expect(find.text('Non qualifié'), findsOneWidget);
  });

  testWidgets('records a same-week refund from its original purchase', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    final journal = _MemoryJournal();
    final service = await _readyService(journal);
    await service.recordExpense(
      RecordExpenseCommand(
        amount: Money.fromMinorUnits(10000, Currency.eur),
        label: 'Chaussures',
        purchaseDate: LocalDate(2026, 4, 5),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localRebootServiceProvider.overrideWith((ref) async => service),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RefundsScreen(service: service, today: LocalDate(2026, 4, 6)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saisir un remboursement'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '40');
    await tester.tap(
      find.widgetWithText(FilledButton, 'Saisir un remboursement').last,
    );
    await tester.pumpAndSettle();

    expect(
      service.expenses.activeExpenses.single.refundedAmount.minorUnits,
      4000,
    );
    expect(
      service
          .buildRollingBudget(LocalDate(2026, 4, 6))
          .cycles
          .first
          .remaining
          .minorUnits,
      35500,
    );
    expect(find.textContaining('restauré sur la semaine'), findsOneWidget);
  });

  testWidgets('enables optional health tracking and records an expense', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    final service = await _readyService(_MemoryJournal());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localRebootServiceProvider.overrideWith((ref) async => service),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HealthScreen(service: service, today: LocalDate(2026, 4, 6)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activer le suivi Santé'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Enregistrer les réglages'),
    );
    await tester.pumpAndSettle();
    expect(service.health.tracking!.enabled, isTrue);
    expect(service.health.tracking!.delayWeeks, 4);
    expect(service.health.tracking!.alertThreshold.minorUnits, 5000);

    await tester.tap(find.widgetWithText(FilledButton, 'Dépense de santé'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '75');
    await tester.enterText(find.byType(TextFormField).at(1), 'Pharmacie');
    await tester.tap(
      find.widgetWithText(FilledButton, 'Enregistrer la saisie'),
    );
    await tester.pumpAndSettle();

    expect(service.health.tracking!.activeEntries, hasLength(1));
    expect(
      service.health.tracking!.activeEntries.single.amount.minorUnits,
      7500,
    );
    expect(find.text('Pharmacie'), findsOneWidget);
  });

  testWidgets('adds a received bonus without rewriting the current week', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    final service = await _readyService(_MemoryJournal());
    final currentCycle = LocalDate(2026, 4, 4);
    final nextCycle = LocalDate(2026, 4, 11);
    final currentBudgetBefore = service.weeklyBudgetForCycleStarting(
      currentCycle,
    );
    final nextBudgetBefore = service.weeklyBudgetForCycleStarting(nextCycle);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localRebootServiceProvider.overrideWith((ref) async => service),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReceivedBonusScreen(
            service: service,
            today: LocalDate(2026, 4, 5),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create-received-bonus')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('received-bonus-title')),
      'Prime annuelle',
    );
    await tester.enterText(
      find.byKey(const ValueKey('received-bonus-amount')),
      '52',
    );
    await tester.tap(find.byKey(const ValueKey('save-received-bonus')));
    await tester.pumpAndSettle();

    expect(service.configuration.receivedBonuses, hasLength(1));
    expect(find.text('Prime annuelle'), findsOneWidget);
    expect(
      service.weeklyBudgetForCycleStarting(currentCycle),
      currentBudgetBefore,
    );
    expect(
      service.weeklyBudgetForCycleStarting(nextCycle).minorUnits,
      nextBudgetBefore.minorUnits + 100,
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
