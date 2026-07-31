import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';
import 'package:test/test.dart';

void main() {
  group('LocalRebootService onboarding', () {
    test('starts at the next REBOOT day by default', () async {
      final harness = await _Harness.create();

      final result = await harness.service.initializeHousehold(
        _initialize(FirstCycleStartChoice.nextAnchor),
      );

      expect(result.firstCycleStart, LocalDate(2026, 4, 4));
      expect(harness.service.configuration.household!.id, result.householdId);
      expect(
        harness.service.configuration.household!.householdKind,
        HouseholdKind.sharedMainAccount,
      );
      expect(harness.journal.entries, hasLength(1));
    });

    test('can catch up from the previous REBOOT day', () async {
      final harness = await _Harness.create();

      final result = await harness.service.initializeHousehold(
        _initialize(FirstCycleStartChoice.previousAnchorWithExpenseCatchUp),
      );

      expect(result.firstCycleStart, LocalDate(2026, 3, 28));
    });

    test('rejects a second household without appending it', () async {
      final harness = await _Harness.create();
      await harness.service.initializeHousehold(
        _initialize(FirstCycleStartChoice.nextAnchor),
      );

      expect(
        () => harness.service.initializeHousehold(
          _initialize(FirstCycleStartChoice.nextAnchor),
        ),
        throwsA(isA<ProjectionConflictException>()),
      );
      expect(harness.journal.entries, hasLength(1));
    });
  });

  group('LocalRebootService expenses', () {
    test(
      'records and allocates an expense atomically over three cycles',
      () async {
        final harness = await _Harness.initialized();

        final result = await harness.service.recordExpense(
          RecordExpenseCommand(
            amount: Money.fromMinorUnits(2800, Currency.eur),
            label: '  Courses  ',
            purchaseDate: LocalDate(2026, 4, 5),
            allocationCycleCount: 3,
          ),
        );

        expect(result.expense.label, 'Courses');
        expect(
          result.expense.cycleAssignment.cycleStart,
          LocalDate(2026, 4, 4),
        );
        expect(
          result.expense.allocations!.map((part) => part.amount.minorUnits),
          [933, 933, 934],
        );
        expect(result.expense.allocations!.map((part) => part.cycleStart), [
          LocalDate(2026, 4, 4),
          LocalDate(2026, 4, 11),
          LocalDate(2026, 4, 18),
        ]);
        expect(harness.journal.entries, hasLength(3));
      },
    );

    test('serializes rapid expense commands in journal order', () async {
      final harness = await _Harness.initialized();

      final first = harness.service.recordExpense(_expense('Courses', 4200));
      final second = harness.service.recordExpense(_expense('Cinéma', 2500));
      final results = await Future.wait([first, second]);

      expect(results.map((result) => result.expense.label), [
        'Courses',
        'Cinéma',
      ]);
      expect(harness.journal.entries.map((entry) => entry.position.value), [
        1,
        2,
        3,
        4,
        5,
      ]);
      expect(harness.service.expenses.activeExpenses, hasLength(2));
    });

    test('tombstones the complete expense and allocation plan', () async {
      final harness = await _Harness.initialized();
      final recorded = await harness.service.recordExpense(
        _expense('Erreur', 15000),
      );

      final deleted = await harness.service.deleteExpense(
        expenseId: recorded.expenseId,
        deletionDate: LocalDate(2026, 4, 5),
      );

      expect(deleted.isDeleted, isTrue);
      expect(deleted.allocations, isNotNull);
      expect(harness.service.expenses.activeExpenses, isEmpty);
      expect(harness.journal.entries, hasLength(4));
    });

    test('does not append an expense before onboarding', () async {
      final harness = await _Harness.create();

      expect(
        () => harness.service.recordExpense(_expense('Courses', 4200)),
        throwsA(isA<IncompleteConfigurationException>()),
      );
      expect(harness.journal.entries, isEmpty);
    });

    test('restores both projections solely from journal history', () async {
      final harness = await _Harness.initialized();
      await harness.service.recordExpense(_expense('Courses', 4200));

      final restored = await LocalRebootService.restore(
        journal: harness.journal,
        clock: const _FixedClock(),
        identities: _SequentialIdentities(100),
      );

      expect(restored.configuration.household, isNotNull);
      expect(restored.expenses.activeExpenses.single.label, 'Courses');
      expect(restored.expenses.lastPosition, LocalJournalPosition(3));
    });
  });

  group('LocalRebootService configuration', () {
    test('creates initial cash flows in one journal batch', () async {
      final harness = await _Harness.initialized();

      final ids = await harness.service.createCashFlows(
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
              minorUnits: 100000,
            ),
          ],
          effectiveFromCycleStart: LocalDate(2026, 4, 4),
          businessDate: LocalDate(2026, 4, 1),
        ),
      );

      expect(ids, hasLength(2));
      expect(ids.toSet(), hasLength(2));
      expect(harness.service.configuration.cashFlows, hasLength(2));
      expect(harness.journal.entries, hasLength(3));
      expect(harness.journal.appendCallCount, 2);
      expect(
        harness.journal.entries.skip(1).map((entry) => entry.event.eventType),
        everyElement('cash-flow.created'),
      );
    });

    test('refuses an empty initial cash-flow batch', () async {
      expect(
        () => CreateCashFlowsCommand(
          definitions: const [],
          effectiveFromCycleStart: LocalDate(2026, 4, 4),
          businessDate: LocalDate(2026, 4, 1),
        ),
        throwsArgumentError,
      );
    });

    test(
      'builds the annual recommendation from accepted assumptions',
      () async {
        final harness = await _Harness.initialized();
        await harness.service.createCashFlow(
          CreateCashFlowCommand(
            definition: _monthlyFlow(
              title: 'Salaire 1',
              direction: CashFlowDirection.income,
              minorUnits: 300000,
            ),
            effectiveFromCycleStart: LocalDate(2026, 4, 4),
            businessDate: LocalDate(2026, 4, 1),
          ),
        );
        await harness.service.createCashFlow(
          CreateCashFlowCommand(
            definition: _monthlyFlow(
              title: 'Logement',
              direction: CashFlowDirection.outflow,
              minorUnits: 100000,
            ),
            effectiveFromCycleStart: LocalDate(2026, 4, 4),
            businessDate: LocalDate(2026, 4, 1),
          ),
        );
        await harness.service.setAnnualCommitments(
          SetAnnualCommitmentsCommand(
            reserveContributions: _eur(120000),
            projectContributions: _eur(60000),
            safetyMargin: _eur(24000),
            effectiveFromCycleStart: LocalDate(2026, 4, 4),
            businessDate: LocalDate(2026, 4, 1),
          ),
        );

        final projection = harness.service.buildAnnualBudget(
          LocalDate(2026, 4, 4),
        );

        expect(projection.totalIncome.minorUnits, 3600000);
        expect(projection.totalOutflows.minorUnits, 1200000);
        expect(projection.deductions.total.minorUnits, 204000);
        expect(projection.recommendedWeeklyBudget.minorUnits, 42200);
        expect(projection.unallocatedAnnualMargin.minorUnits, 1600);
      },
    );

    test(
      'builds a live horizon without carrying a weekly difference',
      () async {
        final harness = await _Harness.initialized();
        await harness.service.createCashFlows(
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
        await harness.service.setTrajectoryPlan(
          SetTrajectoryPlanCommand(
            strategy: TrajectoryStrategy.balance,
            reserveContributions: _eur(0),
            projectContributions: _eur(0),
            safetyMargin: _eur(0),
            effectiveFromCycleStart: LocalDate(2026, 4, 4),
            businessDate: LocalDate(2026, 4, 1),
          ),
        );
        await harness.service.recordExpense(
          RecordExpenseCommand(
            amount: _eur(15000),
            label: 'Réparation',
            purchaseDate: LocalDate(2026, 4, 5),
            allocationCycleCount: 3,
          ),
        );

        final projection = harness.service.buildRollingBudget(
          LocalDate(2026, 4, 7),
        );

        expect(projection.cycles, hasLength(52));
        expect(projection.cycles.first.cycle.start, LocalDate(2026, 4, 4));
        expect(projection.cycles.first.budget.minorUnits, 41500);
        expect(projection.cycles.first.allocatedExpenses.minorUnits, 5000);
        expect(projection.cycles.first.remaining.minorUnits, 36500);
        expect(projection.cycles[1].budget.minorUnits, 41500);
        expect(projection.cycles[1].remaining.minorUnits, 36500);
        expect(projection.cycles[3].remaining.minorUnits, 41500);
      },
    );

    test('builds completed-cycle trends with historical budgets', () async {
      final harness = await _Harness.initialized();
      final flows = await harness.service.createCashFlows(
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
      await harness.service.setTrajectoryPlan(
        SetTrajectoryPlanCommand(
          strategy: TrajectoryStrategy.balance,
          reserveContributions: _eur(0),
          projectContributions: _eur(0),
          safetyMargin: _eur(0),
          effectiveFromCycleStart: LocalDate(2026, 4, 4),
          businessDate: LocalDate(2026, 4, 1),
        ),
      );
      await harness.service.replaceCashFlow(
        ReplaceCashFlowCommand(
          cashFlowId: flows.first,
          definition: _monthlyFlow(
            title: 'Salaire 1',
            direction: CashFlowDirection.income,
            minorUnits: 400000,
          ),
          effectiveFromCycleStart: LocalDate(2026, 4, 25),
          businessDate: LocalDate(2026, 4, 20),
        ),
      );
      await harness.service.recordExpense(
        RecordExpenseCommand(
          amount: _eur(80000),
          label: 'Semaine chargée',
          purchaseDate: LocalDate(2026, 5, 3),
        ),
      );

      final trends = harness.service.buildTrends(LocalDate(2026, 5, 9));

      expect(trends.observedCycles, hasLength(5));
      expect(trends.observedCycles.first.cycle.start, LocalDate(2026, 4, 4));
      expect(trends.observedCycles.last.cycle.start, LocalDate(2026, 5, 2));
      expect(trends.observedCycles.first.budget.minorUnits, 41500);
      expect(trends.observedCycles.last.budget.minorUnits, 64600);
      expect(trends.latestOverspend.minorUnits, 15400);
      expect(trends.latestOverspendRatio?.severity, TrendAlertSeverity.strong);
      expect(trends.cumulativeNegativeRatio, isNull);
      expect(trends.severity, TrendAlertSeverity.strong);
      expect(trends.window(4).observedCycles, hasLength(4));
    });

    test('returns no trend before one complete cycle exists', () async {
      final harness = await _Harness.initialized();

      final trends = harness.service.buildTrends(LocalDate(2026, 4, 4));

      expect(trends.observedCycles, isEmpty);
      expect(trends.balance, Money.zero(Currency.eur));
      expect(trends.severity, TrendAlertSeverity.none);
    });

    test('persists and projects an overdraft-exit trajectory', () async {
      final harness = await _Harness.initialized();
      await harness.service.createCashFlow(
        CreateCashFlowCommand(
          definition: _monthlyFlow(
            title: 'Salaire 1',
            direction: CashFlowDirection.income,
            minorUnits: 300000,
          ),
          effectiveFromCycleStart: LocalDate(2026, 4, 4),
          businessDate: LocalDate(2026, 4, 1),
        ),
      );
      final revision = await harness.service.setTrajectoryPlan(
        SetTrajectoryPlanCommand(
          strategy: TrajectoryStrategy.overdraftExit,
          reserveContributions: _eur(0),
          projectContributions: _eur(0),
          safetyMargin: _eur(0),
          overdraftExitGoal: OverdraftExitGoal(
            currentOverdraftDepth: _eur(100000),
            targetCushion: _eur(50000),
            targetDate: LocalDate(2026, 10, 1),
          ),
          effectiveFromCycleStart: LocalDate(2026, 4, 4),
          businessDate: LocalDate(2026, 4, 1),
        ),
      );

      final projection = harness.service.buildAnnualBudget(
        LocalDate(2026, 4, 4),
      );
      expect(revision.strategy, TrajectoryStrategy.overdraftExit);
      expect(revision.overdraftExitGoal!.totalToRecover, _eur(150000));
      expect(projection.overdraftRecovery, isNotNull);
      expect(
        harness.journal.entries.last.event.eventType,
        'trajectory-plan.set',
      );
    });

    test('preserves cash-flow replacements and future tombstones', () async {
      final harness = await _Harness.initialized();
      final cashFlowId = await harness.service.createCashFlow(
        CreateCashFlowCommand(
          definition: _monthlyFlow(
            title: 'Salaire 1',
            direction: CashFlowDirection.income,
            minorUnits: 300000,
          ),
          effectiveFromCycleStart: LocalDate(2026, 4, 4),
          businessDate: LocalDate(2026, 4, 1),
        ),
      );

      final replaced = await harness.service.replaceCashFlow(
        ReplaceCashFlowCommand(
          cashFlowId: cashFlowId,
          definition: _monthlyFlow(
            title: 'Salaire 1',
            direction: CashFlowDirection.income,
            minorUnits: 320000,
          ),
          effectiveFromCycleStart: LocalDate(2026, 4, 11),
          businessDate: LocalDate(2026, 4, 8),
        ),
      );
      final deleted = await harness.service.deleteCashFlow(
        DeleteCashFlowCommand(
          cashFlowId: cashFlowId,
          effectiveFromCycleStart: LocalDate(2026, 4, 18),
          businessDate: LocalDate(2026, 4, 15),
        ),
      );

      expect(replaced.revisions, hasLength(2));
      expect(
        replaced
            .definitionForCycleStarting(LocalDate(2026, 4, 11))!
            .referenceAmountPerOccurrence
            .minorUnits,
        320000,
      );
      expect(deleted.latestRevision.isDeletion, isTrue);
      expect(
        deleted.definitionForCycleStarting(LocalDate(2026, 4, 17)),
        isNotNull,
      );
      expect(
        deleted.definitionForCycleStarting(LocalDate(2026, 4, 18)),
        isNull,
      );
    });

    test('assigns expenses to an explicit anchor-change transition', () async {
      final harness = await _Harness.initialized();
      final next = await harness.service.changeCyclePolicy(
        ChangeCyclePolicyCommand(
          anchorWeekday: Weekday.monday,
          timeZone: IanaTimeZoneId('Europe/Paris'),
          effectiveFrom: LocalDate(2026, 4, 8),
          businessDate: LocalDate(2026, 4, 8),
        ),
      );

      final result = await harness.service.recordExpense(
        RecordExpenseCommand(
          amount: _eur(2000),
          label: 'Courses',
          purchaseDate: LocalDate(2026, 4, 12),
          allocationCycleCount: 2,
        ),
      );

      expect(next.version, 2);
      expect(result.expense.cycleAssignment.cycleStart, LocalDate(2026, 4, 4));
      expect(result.expense.cycleAssignment.policyVersion, 1);
      expect(result.expense.allocations!.map((part) => part.cycleStart), [
        LocalDate(2026, 4, 4),
        LocalDate(2026, 4, 13),
      ]);
    });
  });

  group('LocalRebootService reserves', () {
    test('creates, funds, spends, reverses, and restores a reserve', () async {
      final harness = await _Harness.initialized();
      final created = await harness.service.createReserve(
        CreateReserveCommand(
          name: ' Imprévus ',
          kind: ReserveKind.virtual,
          openingBalance: _eur(50000),
          businessDate: LocalDate(2026, 4, 1),
        ),
      );
      await harness.service.addReserveFunds(
        AddReserveFundsCommand(
          reserveId: created.id,
          amount: _eur(10000),
          label: ' Surplus ',
          businessDate: LocalDate(2026, 4, 8),
        ),
      );
      final usage = await harness.service.useReserve(
        UseReserveCommand(
          reserveId: created.id,
          amount: _eur(15000),
          label: ' Vétérinaire ',
          purchaseDate: LocalDate(2026, 4, 9),
        ),
      );

      expect(created.name, 'Imprévus');
      expect(usage.reserve.balance.minorUnits, 45000);
      expect(usage.requiresBankTransfer, isFalse);
      expect(harness.service.expenses.activeExpenses, isEmpty);

      await harness.service.reverseReserveMovement(
        ReverseReserveMovementCommand(
          reserveId: created.id,
          movementEventId: usage.movement.eventId,
          businessDate: LocalDate(2026, 4, 10),
        ),
      );
      expect(
        harness.service.reserves.reserves[created.id]!.balance.minorUnits,
        60000,
      );

      final restored = await LocalRebootService.restore(
        journal: harness.journal,
        clock: const _FixedClock(),
        identities: _SequentialIdentities(100),
      );
      expect(restored.reserves.reserves[created.id]!.balance.minorUnits, 60000);
      expect(
        restored.reserves.reserves[created.id]!.movements.last.isReversed,
        isTrue,
      );
    });

    test('requires a transfer reminder for real reserves', () async {
      final harness = await _Harness.initialized();
      final reserve = await harness.service.createReserve(
        CreateReserveCommand(
          name: 'Compte secours',
          kind: ReserveKind.real,
          openingBalance: _eur(20000),
          businessDate: LocalDate(2026, 4, 1),
        ),
      );

      final result = await harness.service.useReserve(
        UseReserveCommand(
          reserveId: reserve.id,
          amount: _eur(5000),
          label: 'Réparation',
          purchaseDate: LocalDate(2026, 4, 5),
        ),
      );

      expect(result.requiresBankTransfer, isTrue);
    });

    test('does not append a reserve expense beyond its balance', () async {
      final harness = await _Harness.initialized();
      final reserve = await harness.service.createReserve(
        CreateReserveCommand(
          name: 'Secours',
          kind: ReserveKind.real,
          openingBalance: _eur(5000),
          businessDate: LocalDate(2026, 4, 1),
        ),
      );
      final entryCount = harness.journal.entries.length;

      await expectLater(
        harness.service.useReserve(
          UseReserveCommand(
            reserveId: reserve.id,
            amount: _eur(5001),
            label: 'Trop élevé',
            purchaseDate: LocalDate(2026, 4, 5),
          ),
        ),
        throwsA(isA<InsufficientReserveBalanceException>()),
      );
      expect(harness.journal.entries, hasLength(entryCount));
    });
  });
}

InitializeHouseholdCommand _initialize(FirstCycleStartChoice choice) {
  return InitializeHouseholdCommand(
    householdKind: HouseholdKind.sharedMainAccount,
    onboardingDate: LocalDate(2026, 4, 1),
    anchorWeekday: Weekday.saturday,
    timeZone: IanaTimeZoneId('Europe/Paris'),
    firstCycleChoice: choice,
  );
}

RecordExpenseCommand _expense(String label, int minorUnits) {
  return RecordExpenseCommand(
    amount: Money.fromMinorUnits(minorUnits, Currency.eur),
    label: label,
    purchaseDate: LocalDate(2026, 4, 5),
  );
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
    amountPerOccurrence: _eur(minorUnits),
    lastConfirmedOn: LocalDate(2026, 4, 1),
  );
}

Money _eur(int minorUnits) {
  return Money.fromMinorUnits(minorUnits, Currency.eur);
}

final class _Harness {
  const _Harness({required this.journal, required this.service});

  static Future<_Harness> create() async {
    final journal = _MemoryJournal();
    final service = await LocalRebootService.restore(
      journal: journal,
      clock: const _FixedClock(),
      identities: _SequentialIdentities(1),
    );
    return _Harness(journal: journal, service: service);
  }

  static Future<_Harness> initialized() async {
    final harness = await create();
    await harness.service.initializeHousehold(
      _initialize(FirstCycleStartChoice.nextAnchor),
    );
    return harness;
  }

  final _MemoryJournal journal;
  final LocalRebootService service;
}

final class _FixedClock implements RebootClock {
  const _FixedClock();

  @override
  DateTime nowUtc() => DateTime.utc(2026, 4, 1, 10);
}

final class _SequentialIdentities implements RebootIdentityGenerator {
  _SequentialIdentities(this._next);

  int _next;

  @override
  EntityId nextEntityId() => EntityId(_uuid(_next++));

  @override
  EventId nextEventId() => EventId(_uuid(_next++));

  String _uuid(int value) {
    return '01970000-0000-7000-8000-${value.toString().padLeft(12, '0')}';
  }
}

final class _MemoryJournal implements LocalEventJournal {
  final List<LocalJournalEntry> entries = [];
  bool _closed = false;
  int appendCallCount = 0;

  @override
  Future<List<LocalJournalEntry>> appendAll(List<EventRecord> events) async {
    if (_closed) {
      throw StateError('closed');
    }
    appendCallCount += 1;
    await Future<void>.delayed(Duration.zero);
    final appended = <LocalJournalEntry>[];
    for (final event in events) {
      final entry = LocalJournalEntry(
        position: LocalJournalPosition(entries.length + 1),
        event: event,
      );
      entries.add(entry);
      appended.add(entry);
    }
    return List<LocalJournalEntry>.unmodifiable(appended);
  }

  @override
  Future<List<LocalJournalEntry>> readAll() async {
    return List<LocalJournalEntry>.unmodifiable(entries);
  }

  @override
  Future<void> close() async {
    _closed = true;
  }
}
