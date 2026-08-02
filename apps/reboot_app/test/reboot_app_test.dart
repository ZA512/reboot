import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:reboot_app/bonuses/received_bonus_screen.dart';
import 'package:reboot_app/health/health_screen.dart';
import 'package:reboot_app/history/cycle_history_detail_screen.dart';
import 'package:reboot_app/infrastructure/device_context_providers.dart';
import 'package:reboot_app/infrastructure/profile_providers.dart';
import 'package:reboot_app/l10n/app_localizations.dart';
import 'package:reboot_app/method/budget_explanation_screen.dart';
import 'package:reboot_app/refunds/refunds_screen.dart';
import 'package:reboot_app/reserves/reserves_screen.dart';
import 'package:reboot_app/src/reboot_app.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

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
    expect(find.text('Vérifier votre point de départ'), findsOneWidget);
    expect(find.text('1. Votre objectif de solde'), findsOneWidget);
    expect(find.byKey(const ValueKey('add-expense')), findsNothing);
    expect(journal.entries, hasLength(4));
  });

  testWidgets(
    'separates a minus 1500 balance objective from its timing cushion',
    (tester) async {
      _useLocale(tester, const Locale('fr'));
      final journal = _MemoryJournal();
      final service = await _serviceBeforeStartup(journal);

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
            currentInstantProvider.overrideWith(
              (ref) => DateTime.utc(2026, 4, 1, 8),
            ),
          ],
          child: const RebootApp(),
        ),
      );
      await tester.pumpAndSettle();

      await _tapStartupContinue(tester);
      await tester.enterText(
        find.byKey(const ValueKey('startup-booked-balance')),
        '-1500',
      );
      await tester.enterText(
        find.byKey(const ValueKey('startup-authorized-overdraft')),
        '5000',
      );
      await _tapStartupContinue(tester);
      await _tapStartupContinue(tester);
      await tester.enterText(
        find.byKey(const ValueKey('startup-minimum-viable')),
        '100',
      );
      await _tapStartupContinue(tester);

      expect(find.textContaining('Budget semaine durable'), findsOneWidget);
      expect(find.textContaining('Point bas'), findsOneWidget);
      expect(find.textContaining('Coussin nécessaire'), findsOneWidget);
      await _tapStartupContinue(tester);

      await tester.enterText(
        find.byKey(const ValueKey('startup-owned-cushion')),
        '0',
      );
      await tester.pump();
      expect(
        find.textContaining('Part financée par le découvert'),
        findsOneWidget,
      );
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('startup-bank-risk')),
          )
          .onChanged!(true);
      await tester.pump();
      await _tapStartupContinue(tester);

      await tester.ensureVisible(
        find.byKey(const ValueKey('startup-viability-comfortable')),
      );
      await tester.tap(
        find.byKey(const ValueKey('startup-viability-comfortable')),
      );
      await _tapStartupContinue(tester);

      expect(
        find.textContaining('Votre objectif de solde : 0'),
        findsOneWidget,
      );
      expect(find.textContaining('Point le plus bas accepté'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('startup-commitment')),
      );
      await tester.tap(find.byKey(const ValueKey('startup-commitment')));
      await _tapStartupContinue(tester);
      await tester.pumpAndSettle();

      expect(service.startup.isReady, isTrue);
      expect(find.text('Votre prochain budget semaine'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('startup-launch-progress')),
        findsOneWidget,
      );
      expect(journal.entries, hasLength(9));
    },
  );

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
    expect(journal.entries, hasLength(12));

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
    expect(journal.entries, hasLength(13));
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
    await tester.tap(find.text('Variable'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '3200');
    await tester.scrollUntilVisible(
      find.text('Planifier cette modification'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();
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
    expect(find.textContaining('Source : Saisie manuelle'), findsWidgets);
    expect(
      find.textContaining('Méthode : Estimation variable · Prudente'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Dernière confirmation : dimanche 5 avril 2026'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Logement'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
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

  testWidgets('confirms unchanged assumptions from the next REBOOT', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    final service = await _readyService(_MemoryJournal());
    final currentCycle = LocalDate(2026, 4, 4);
    final nextCycle = LocalDate(2026, 4, 11);
    final currentBudget = service.weeklyBudgetForCycleStarting(currentCycle);
    final nextBudget = service.weeklyBudgetForCycleStarting(nextCycle);

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

    final salaryTile = find.ancestor(
      of: find.text('Salaire 1'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: salaryTile, matching: find.byIcon(Icons.more_vert)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer ces valeurs'));
    await tester.pumpAndSettle();

    expect(
      find.text('Ces valeurs sont-elles toujours correctes ?'),
      findsOneWidget,
    );
    expect(
      find.textContaining('la semaine en cours ne changera pas'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
    await tester.pumpAndSettle();
    var salary = service.configuration.cashFlows.values.singleWhere(
      (flow) =>
          flow.definitionForCycleStarting(currentCycle)?.title == 'Salaire 1',
    );
    expect(salary.revisions, hasLength(1));

    await tester.tap(
      find.descendant(of: salaryTile, matching: find.byIcon(Icons.more_vert)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer ces valeurs'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-assumption-values')));
    await tester.pumpAndSettle();

    salary = service.configuration.cashFlows.values.singleWhere(
      (flow) =>
          flow.definitionForCycleStarting(currentCycle)?.title == 'Salaire 1',
    );
    expect(salary.revisions, hasLength(2));
    expect(
      salary.definitionForCycleStarting(currentCycle)!.lastConfirmedOn,
      LocalDate(2026, 4, 1),
    );
    expect(
      salary.definitionForCycleStarting(nextCycle)!.lastConfirmedOn,
      LocalDate(2026, 4, 5),
    );
    expect(service.weeklyBudgetForCycleStarting(currentCycle), currentBudget);
    expect(service.weeklyBudgetForCycleStarting(nextCycle), nextBudget);
    expect(find.textContaining('Confirmation à partir du'), findsOneWidget);
    expect(find.textContaining('Nouvelle valeur à partir du'), findsNothing);
  });

  testWidgets('explains every accepted input behind the weekly budget', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = await _readyService(_MemoryJournal());
    final cycleStart = LocalDate(2026, 4, 4);
    final projection = service.buildAnnualBudget(cycleStart);
    final moneyFormat = NumberFormat.simpleCurrency(
      locale: 'fr',
      name: 'EUR',
      decimalDigits: 2,
    );
    String format(Money money) => moneyFormat.format(money.minorUnits / 100);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BudgetExplanationScreen(
          service: service,
          today: LocalDate(2026, 4, 6),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Comment ce budget est calculé'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('explained-weekly-budget')))
          .data,
      format(projection.recommendedWeeklyBudget),
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('budget-explanation-income-total')),
          )
          .data,
      format(projection.totalIncome),
    );
    final outflowTotal = find.byKey(
      const ValueKey('budget-explanation-outflow-total'),
    );
    await tester.scrollUntilVisible(
      outflowTotal,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.widget<Text>(outflowTotal).data,
      format(projection.totalOutflows),
    );
    expect(projection.totalIncome.minorUnits, 3600000);
    expect(projection.totalOutflows.minorUnits, 1440000);

    final salary = find.byKey(const ValueKey('explained-cash-flow-Salaire 1'));
    await tester.scrollUntilVisible(
      salary,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(salary);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: salary, matching: find.text('12 occurrences')),
      findsOneWidget,
    );
    expect(find.text('Montant par occurrence'), findsOneWidget);
    expect(find.text('Fixe'), findsOneWidget);
    expect(find.text('Saisie manuelle'), findsOneWidget);
    expect(find.text('Dernière confirmation'), findsOneWidget);
    expect(find.text('mercredi 1 avril 2026'), findsOneWidget);
  });

  testWidgets('states the real local protection and recovery limits', (
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

    await tester.tap(find.byKey(const ValueKey('open-data-privacy')));
    await tester.pumpAndSettle();

    expect(find.text('Données et confidentialité'), findsOneWidget);
    expect(find.text('Profil local chiffré'), findsOneWidget);
    expect(find.text('Sauvegarde système Android désactivée'), findsOneWidget);
    expect(find.text('Aucune télémétrie'), findsOneWidget);
    expect(find.text('Sauvegarde de récupération chiffrée'), findsOneWidget);

    final assumptions = find.text('2 hypothèses actives');
    await tester.scrollUntilVisible(
      assumptions,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(assumptions, findsOneWidget);
    expect(find.text('2 fixes · 0 variables'), findsOneWidget);
    expect(
      find.textContaining('Confirmation la plus ancienne : 1 avr. 2026'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('manage-financial-assumptions')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Revenus et charges'), findsOneWidget);
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
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
    await tester.pumpAndSettle();
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
    await tester.tap(find.widgetWithText(OutlinedButton, 'Ajouter des fonds'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reserve-funding-amount')),
      '25',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reserve-funding-label')),
      'Surplus conservé',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-reserve-funding')));
    await tester.pumpAndSettle();

    expect(find.text('Rappel de virement'), findsOneWidget);
    expect(find.textContaining('du compte principal vers'), findsOneWidget);
    expect(service.reserves.reserves.values.single.balance.minorUnits, 50000);
    await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
    await tester.pumpAndSettle();
    expect(service.reserves.reserves.values.single.balance.minorUnits, 50000);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Ajouter des fonds'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reserve-funding-amount')),
      '25',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reserve-funding-label')),
      'Surplus conservé',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-reserve-funding')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('confirm-real-reserve-funding')),
    );
    await tester.pumpAndSettle();
    expect(service.reserves.reserves.values.single.balance.minorUnits, 52500);

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

    expect(service.reserves.reserves.values.single.balance.minorUnits, 40000);
    expect(service.expenses.activeExpenses, isEmpty);
    expect(
      service.buildRollingBudget(LocalDate(2026, 4, 5)).cycles.first.remaining,
      weeklyBefore,
    );
  });

  testWidgets('funds a virtual reserve without a bank transfer reminder', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    final service = await _readyService(_MemoryJournal());
    await service.createReserve(
      CreateReserveCommand(
        name: 'Coussin virtuel',
        kind: ReserveKind.virtual,
        openingBalance: Money.zero(Currency.eur),
        businessDate: LocalDate(2026, 4, 5),
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
          home: ReservesScreen(service: service, today: LocalDate(2026, 4, 5)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Ajouter des fonds'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reserve-funding-amount')),
      '25',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reserve-funding-label')),
      'Surplus conservé',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-reserve-funding')));
    await tester.pumpAndSettle();

    expect(find.text('Rappel de virement'), findsNothing);
    expect(service.reserves.reserves.values.single.balance.minorUnits, 2500);
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

    final completedCycle = find.byKey(
      const ValueKey('cycle-history-2026-05-02'),
    );
    await tester.scrollUntilVisible(
      completedCycle,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(completedCycle);
    await tester.pumpAndSettle();

    expect(find.text('Détail de la semaine'), findsOneWidget);
    expect(find.text('Dépenses affectées à cette semaine'), findsOneWidget);
    expect(find.text('Semaine exceptionnelle'), findsOneWidget);
    expect(find.textContaining('Dépense réelle : 500'), findsOneWidget);
  });

  testWidgets('shows exact allocations already committed to future weeks', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = await _readyService(_MemoryJournal());
    await service.recordExpense(
      RecordExpenseCommand(
        amount: Money.fromMinorUnits(15000, Currency.eur),
        label: 'Réparation',
        purchaseDate: LocalDate(2026, 4, 5),
        allocationCycleCount: 3,
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

    final open = find.byKey(const ValueKey('open-future-commitments'));
    await tester.scrollUntilVisible(
      open,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(open);
    await tester.pumpAndSettle();

    expect(find.text('Engagements futurs'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('future-commitments-total')))
          .data,
      contains('100'),
    );
    expect(
      find.byKey(const ValueKey('future-cycle-2026-04-11')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('future-cycle-2026-04-18')),
      findsOneWidget,
    );
    expect(find.text('Réparation'), findsNWidgets(2));
    expect(find.textContaining('Dépense réelle : 150'), findsNWidgets(2));
  });

  testWidgets('shows late refunds inside their historical receipt week', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    final service = await _readyService(_MemoryJournal());
    final purchase = await service.recordExpense(
      RecordExpenseCommand(
        amount: Money.fromMinorUnits(10000, Currency.eur),
        label: 'Chaussures',
        purchaseDate: LocalDate(2026, 4, 5),
      ),
    );
    await service.recordExpenseRefund(
      RecordExpenseRefundCommand(
        expenseId: purchase.expenseId,
        amount: Money.fromMinorUnits(4000, Currency.eur),
        receivedDate: LocalDate(2026, 5, 3),
      ),
    );
    final observation = service
        .buildTrends(LocalDate(2026, 5, 9))
        .observedCycles
        .singleWhere((item) => item.cycle.start == LocalDate(2026, 5, 2));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CycleHistoryDetailScreen(
          service: service,
          observation: observation,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Aucune dépense active n’est affectée à cette semaine.'),
      findsOneWidget,
    );
    expect(
      find.text('Remboursements reçus pendant cette semaine'),
      findsOneWidget,
    );
    expect(find.text('Chaussures'), findsOneWidget);
    expect(find.textContaining('+40'), findsWidgets);
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

  testWidgets('offers the private Android widget from the dashboard', (
    tester,
  ) async {
    _useLocale(tester, const Locale('fr'));
    const widgetChannel = MethodChannel('com.za512.reboot/weekly_widget');
    final nativeCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, (call) async {
          nativeCalls.add(call);
          return call.method == 'requestPinWeeklyWidget';
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(widgetChannel, null),
    );
    final service = await _readyService(_MemoryJournal());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localRebootServiceProvider.overrideWith((ref) async => service),
          onboardingDeviceContextProvider.overrideWith(
            (ref) async => OnboardingDeviceContext(
              localDate: LocalDate(2026, 4, 6),
              timeZone: IanaTimeZoneId('Europe/Paris'),
            ),
          ),
        ],
        child: const RebootApp(),
      ),
    );
    await tester.pumpAndSettle();

    final install = find.byKey(const ValueKey('install-weekly-widget'));
    await tester.scrollUntilVisible(install, 250);
    await tester.ensureVisible(install);
    await tester.pumpAndSettle();
    await tester.tap(install);
    await tester.pumpAndSettle();

    expect(
      nativeCalls.map((call) => call.method),
      containsAll(['updateWeeklyWidget', 'requestPinWeeklyWidget']),
    );
    expect(
      find.text('Confirmez l’ajout du widget sur votre écran d’accueil.'),
      findsOneWidget,
    );
  });

  testWidgets('counts a cash withdrawal once as a weekly expense', (
    tester,
  ) async {
    _useLocale(tester, const Locale('en'));
    final service = await _readyService(_MemoryJournal());
    final today = LocalDate(2026, 4, 6);
    final remainingBefore = service
        .buildRollingBudget(today)
        .cycles
        .first
        .remaining;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localRebootServiceProvider.overrideWith((ref) async => service),
          onboardingDeviceContextProvider.overrideWith(
            (ref) async => OnboardingDeviceContext(
              localDate: today,
              timeZone: IanaTimeZoneId('Europe/Paris'),
            ),
          ),
        ],
        child: const RebootApp(),
      ),
    );
    await tester.pumpAndSettle();

    final cashCard = find.byKey(const ValueKey('open-cash'));
    await tester.scrollUntilVisible(cashCard, 250);
    await tester.tap(cashCard);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('cash-method-withdrawal-expense')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('record-cash-withdrawal')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('cash-withdrawal-amount')),
      '50',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-cash-withdrawal')));
    await tester.pumpAndSettle();

    expect(service.expenses.activeExpenses, hasLength(1));
    expect(service.expenses.activeExpenses.single.amount.minorUnits, 5000);
    expect(service.cash.walletTransfers, isEmpty);
    expect(
      service.buildRollingBudget(today).cycles.first.remaining.minorUnits,
      remainingBefore.minorUnits - 5000,
    );
    expect(
      find.textContaining('Do not enter later cash purchases again'),
      findsOneWidget,
    );
  });

  testWidgets('keeps a cash-wallet transfer outside the weekly budget', (
    tester,
  ) async {
    _useLocale(tester, const Locale('en'));
    final service = await _readyService(_MemoryJournal());
    final today = LocalDate(2026, 4, 6);
    final remainingBefore = service
        .buildRollingBudget(today)
        .cycles
        .first
        .remaining;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localRebootServiceProvider.overrideWith((ref) async => service),
          onboardingDeviceContextProvider.overrideWith(
            (ref) async => OnboardingDeviceContext(
              localDate: today,
              timeZone: IanaTimeZoneId('Europe/Paris'),
            ),
          ),
        ],
        child: const RebootApp(),
      ),
    );
    await tester.pumpAndSettle();

    final cashCard = find.byKey(const ValueKey('open-cash'));
    await tester.scrollUntilVisible(cashCard, 250);
    await tester.tap(cashCard);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cash-method-wallet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('record-cash-withdrawal')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('cash-withdrawal-amount')),
      '50',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-cash-withdrawal')));
    await tester.pumpAndSettle();

    expect(service.expenses.activeExpenses, isEmpty);
    expect(service.cash.activeWalletTransfers, hasLength(1));
    expect(
      service.buildRollingBudget(today).cycles.first.remaining,
      remainingBefore,
    );
    expect(find.textContaining('not a wallet balance'), findsOneWidget);

    final reverseTransfer = find.byTooltip('Reverse transfer');
    await tester.scrollUntilVisible(reverseTransfer, 200);
    await tester.ensureVisible(reverseTransfer);
    await tester.pumpAndSettle();
    await tester.tap(reverseTransfer);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reverse transfer'));
    await tester.pumpAndSettle();

    expect(service.cash.activeWalletTransfers, isEmpty);
    expect(service.cash.walletTransfers.single.isReversed, isTrue);
    expect(find.text('Erroneous transfer reversed'), findsOneWidget);
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

Future<void> _tapStartupContinue(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('startup-continue'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<LocalRebootService> _serviceBeforeStartup(_MemoryJournal journal) async {
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

Future<LocalRebootService> _readyService(_MemoryJournal journal) async {
  final service = await _serviceBeforeStartup(journal);
  final start = LocalDate(2026, 4, 4);
  final annual = service.buildAnnualBudget(start);
  final openingCash = Money.fromMinorUnits(10000000, Currency.eur);
  final liquidity = LiquiditySnapshot(
    capturedAtUtc: DateTime.utc(2026, 4, 1, 8),
    bookedBalance: openingCash,
    source: LiquiditySnapshotSource.manual,
    confidence: StartupDataConfidence.high,
  );
  final projection = StartupCashProjectionEngine.project(
    cycles: annual.cycles,
    initialUsableCash: openingCash,
    movements: StartupCashProjectionEngine.movementsFromAnnualBudget(annual),
    weeklyBudgetsByCycleStart: {
      for (final cycle in annual.cycles)
        cycle.start: annual.recommendedWeeklyBudget,
    },
  );
  final cushion =
      projection.technicalCashCushion + annual.recommendedWeeklyBudget;
  final funding = CashCushionFunding(
    targetBalance: Money.zero(Currency.eur),
    ownedCash: cushion,
    authorizedOverdraft: Money.zero(Currency.eur),
    overdraftFundedCash: Money.zero(Currency.eur),
  );
  final assessment = StartupLiquidityAssessment(
    projection: projection,
    uncertaintyMargin: annual.recommendedWeeklyBudget,
    funding: funding,
  );
  await service.acceptStartupPlan(
    AcceptStartupPlanCommand(
      liquidity: liquidity,
      householdNeeds: HouseholdNeedsProfile(
        fullTimePersons14OrOlder: 1,
        fullTimeChildrenUnder14: 0,
        weeklyBudgetScope: const {WeeklyBudgetCategory.groceries},
        minimumViableWeeklyBudget: Money.fromMinorUnits(100, Currency.eur),
      ),
      assessment: assessment,
      startDate: start,
      decisionState: LaunchDecisionState.readyWithExistingCushion,
      viabilityAnswer: StartupViabilityAnswer.comfortable,
      businessDate: LocalDate(2026, 4, 1),
      acceptedBankFundingRisk: false,
    ),
  );
  return service;
}
