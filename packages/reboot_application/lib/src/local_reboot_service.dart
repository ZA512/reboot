import 'dart:async';

import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

import 'local_event_journal.dart';
import 'runtime_ports.dart';

/// User choices required to establish the one local household.
final class InitializeHouseholdCommand {
  /// Creates a validated onboarding command.
  const InitializeHouseholdCommand({
    required this.householdKind,
    required this.onboardingDate,
    required this.anchorWeekday,
    required this.timeZone,
    required this.firstCycleChoice,
  });

  /// Solo or shared-principal-account household.
  final HouseholdKind householdKind;

  /// Civil date on which onboarding is confirmed.
  final LocalDate onboardingDate;

  /// User-selected REBOOT weekday.
  final Weekday anchorWeekday;

  /// Auditable household time zone.
  final IanaTimeZoneId timeZone;

  /// Start at the next anchor or catch up from the previous anchor.
  final FirstCycleStartChoice firstCycleChoice;
}

/// Accepted result of household initialization.
final class HouseholdInitializationResult {
  /// Creates the immutable command result.
  const HouseholdInitializationResult({
    required this.householdId,
    required this.firstCycleStart,
  });

  /// Stable household entity identity.
  final EntityId householdId;

  /// First complete cycle selected during onboarding.
  final LocalDate firstCycleStart;
}

/// Creates one recurring income or outflow assumption.
final class CreateCashFlowCommand {
  /// Creates the command.
  const CreateCashFlowCommand({
    required this.definition,
    required this.effectiveFromCycleStart,
    required this.businessDate,
  });

  /// Complete fixed or variable definition.
  final CashFlowDefinition definition;

  /// First weekly cycle using the assumption.
  final LocalDate effectiveFromCycleStart;

  /// Civil date on which the user confirmed the assumption.
  final LocalDate businessDate;
}

/// Atomically creates the complete set of initial financial assumptions.
final class CreateCashFlowsCommand {
  /// Creates one onboarding batch effective from the same weekly cycle.
  CreateCashFlowsCommand({
    required Iterable<CashFlowDefinition> definitions,
    required this.effectiveFromCycleStart,
    required this.businessDate,
  }) : definitions = List<CashFlowDefinition>.unmodifiable(definitions) {
    if (this.definitions.isEmpty) {
      throw ArgumentError.value(
        definitions,
        'definitions',
        'At least one cash-flow definition is required.',
      );
    }
  }

  /// Complete income and outflow definitions confirmed together.
  final List<CashFlowDefinition> definitions;

  /// First weekly cycle using every assumption in the batch.
  final LocalDate effectiveFromCycleStart;

  /// Civil date on which the user confirmed the batch.
  final LocalDate businessDate;
}

/// Replaces an existing cash flow from a future weekly cycle.
final class ReplaceCashFlowCommand {
  /// Creates the command.
  const ReplaceCashFlowCommand({
    required this.cashFlowId,
    required this.definition,
    required this.effectiveFromCycleStart,
    required this.businessDate,
  });

  /// Stable cash-flow entity to replace.
  final EntityId cashFlowId;

  /// Complete replacement definition.
  final CashFlowDefinition definition;

  /// First weekly cycle using the replacement.
  final LocalDate effectiveFromCycleStart;

  /// Civil date on which the user confirmed the change.
  final LocalDate businessDate;
}

/// Removes an existing cash flow from a future weekly cycle.
final class DeleteCashFlowCommand {
  /// Creates the command.
  const DeleteCashFlowCommand({
    required this.cashFlowId,
    required this.effectiveFromCycleStart,
    required this.businessDate,
  });

  /// Stable cash-flow entity to tombstone.
  final EntityId cashFlowId;

  /// First weekly cycle without the assumption.
  final LocalDate effectiveFromCycleStart;

  /// Civil date on which the user confirmed the deletion.
  final LocalDate businessDate;
}

/// Replaces the complete annual reserve, project, and safety commitments.
final class SetAnnualCommitmentsCommand {
  /// Creates the command.
  const SetAnnualCommitmentsCommand({
    required this.reserveContributions,
    required this.projectContributions,
    required this.safetyMargin,
    required this.effectiveFromCycleStart,
    required this.businessDate,
  });

  /// Total allocated to reserves over the 52-cycle horizon.
  final Money reserveContributions;

  /// Total allocated to named projects over the horizon.
  final Money projectContributions;

  /// Explicit annual safety margin.
  final Money safetyMargin;

  /// First weekly cycle using this complete snapshot.
  final LocalDate effectiveFromCycleStart;

  /// Civil date on which the user confirmed the snapshot.
  final LocalDate businessDate;
}

/// Sets the initial trajectory strategy and its explicit annual amounts.
final class SetTrajectoryPlanCommand {
  /// Creates one complete plan snapshot.
  const SetTrajectoryPlanCommand({
    required this.strategy,
    required this.reserveContributions,
    required this.projectContributions,
    required this.safetyMargin,
    required this.effectiveFromCycleStart,
    required this.businessDate,
    this.overdraftExitGoal,
  });

  /// Balance, cushion, or time-bound overdraft exit.
  final TrajectoryStrategy strategy;

  /// Ordinary annual reserve contribution.
  final Money reserveContributions;

  /// Annual contribution to named projects.
  final Money projectContributions;

  /// Explicit annual conservative margin.
  final Money safetyMargin;

  /// First weekly cycle using the plan.
  final LocalDate effectiveFromCycleStart;

  /// Civil confirmation date.
  final LocalDate businessDate;

  /// Required only for an overdraft-exit strategy.
  final OverdraftExitGoal? overdraftExitGoal;
}

/// Schedules a new day or time zone without rewriting historical cycles.
final class ChangeCyclePolicyCommand {
  /// Creates the command.
  const ChangeCyclePolicyCommand({
    required this.anchorWeekday,
    required this.timeZone,
    required this.effectiveFrom,
    required this.businessDate,
  });

  /// New REBOOT weekday.
  final Weekday anchorWeekday;

  /// New auditable household time zone.
  final IanaTimeZoneId timeZone;

  /// Earliest civil date from which the new policy may begin.
  final LocalDate effectiveFrom;

  /// Civil date on which the user confirmed the change.
  final LocalDate businessDate;
}

/// User input for one real expense and its immutable virtual allocation.
final class RecordExpenseCommand {
  /// Creates a quick-expense command.
  const RecordExpenseCommand({
    required this.amount,
    required this.label,
    required this.purchaseDate,
    this.allocationCycleCount = 1,
    this.nature,
  });

  /// Exact real amount paid.
  final Money amount;

  /// User-visible label or shortcut.
  final String label;

  /// Civil purchase date in the household time zone.
  final LocalDate purchaseDate;

  /// Number of weekly cycles over which the amount is virtually allocated.
  final int allocationCycleCount;

  /// Optional behavioral qualification used only for insights.
  final ExpenseNature? nature;
}

/// Accepted result of an expense command.
final class ExpenseRecordingResult {
  /// Creates the immutable command result.
  const ExpenseRecordingResult({
    required this.expenseId,
    required this.expense,
  });

  /// Stable expense entity identity.
  final EntityId expenseId;

  /// Fully projected expense, including its allocation plan.
  final ProjectedExpense expense;
}

/// Records a partial or total refund against its original expense.
final class RecordExpenseRefundCommand {
  const RecordExpenseRefundCommand({
    required this.expenseId,
    required this.amount,
    required this.receivedDate,
  });

  final EntityId expenseId;
  final Money amount;
  final LocalDate receivedDate;
}

/// Accepted refund with its immediate weekly-impact classification.
final class ExpenseRefundResult {
  const ExpenseRefundResult({
    required this.expense,
    required this.refund,
    required this.restoresOriginalCycle,
  });

  final ProjectedExpense expense;
  final ProjectedExpenseRefund refund;
  final bool restoresOriginalCycle;
}

/// Corrects an erroneous refund entry without deleting journal history.
final class ReverseExpenseRefundCommand {
  const ReverseExpenseRefundCommand({
    required this.expenseId,
    required this.refundEventId,
    required this.businessDate,
  });

  final EntityId expenseId;
  final EventId refundEventId;
  final LocalDate businessDate;
}

/// Creates one named real or virtual reserve.
final class CreateReserveCommand {
  const CreateReserveCommand({
    required this.name,
    required this.kind,
    required this.openingBalance,
    required this.businessDate,
  });

  final String name;
  final ReserveKind kind;
  final Money openingBalance;
  final LocalDate businessDate;
}

/// Records money explicitly assigned to an existing reserve.
final class AddReserveFundsCommand {
  const AddReserveFundsCommand({
    required this.reserveId,
    required this.amount,
    required this.label,
    required this.businessDate,
  });

  final EntityId reserveId;
  final Money amount;
  final String label;
  final LocalDate businessDate;
}

/// Records one real expense financed by a reserve, not the weekly budget.
final class UseReserveCommand {
  const UseReserveCommand({
    required this.reserveId,
    required this.amount,
    required this.label,
    required this.purchaseDate,
  });

  final EntityId reserveId;
  final Money amount;
  final String label;
  final LocalDate purchaseDate;
}

/// Result of a reserve-funded expense.
final class ReserveUsageResult {
  const ReserveUsageResult({
    required this.reserve,
    required this.movement,
    required this.requiresBankTransfer,
  });

  final ProjectedReserve reserve;
  final ProjectedReserveMovement movement;
  final bool requiresBankTransfer;
}

/// Reverses one erroneous reserve credit or expense without deleting history.
final class ReverseReserveMovementCommand {
  const ReverseReserveMovementCommand({
    required this.reserveId,
    required this.movementEventId,
    required this.businessDate,
  });

  final EntityId reserveId;
  final EventId movementEventId;
  final LocalDate businessDate;
}

/// Enables, disables, or updates aggregate health tracking.
final class ConfigureHealthTrackingCommand {
  const ConfigureHealthTrackingCommand({
    required this.enabled,
    required this.delayWeeks,
    required this.alertThreshold,
    required this.businessDate,
  });

  final bool enabled;
  final int delayWeeks;
  final Money alertThreshold;
  final LocalDate businessDate;
}

/// Records an aggregate or individual health flow or regularization.
final class RecordHealthEntryCommand {
  const RecordHealthEntryCommand({
    required this.kind,
    required this.amount,
    required this.label,
    required this.businessDate,
  });

  final HealthEntryKind kind;
  final Money amount;
  final String label;
  final LocalDate businessDate;
}

/// Corrects one erroneous health entry.
final class ReverseHealthEntryCommand {
  const ReverseHealthEntryCommand({
    required this.entryEventId,
    required this.businessDate,
  });

  final EventId entryEventId;
  final LocalDate businessDate;
}

/// Local-first command boundary owning one journal and its live projections.
///
/// All mutations are serialized to prevent two rapid UI actions from deriving
/// events from the same in-memory state. Other writers must not append to the
/// journal while this service owns it.
final class LocalRebootService {
  LocalRebootService._(
    this._journal,
    this._clock,
    this._identities,
    this._configuration,
    this._expenses,
    this._reserves,
    this._health,
  );

  /// Restores all observable state from the append-only journal.
  static Future<LocalRebootService> restore({
    required LocalEventJournal journal,
    RebootClock clock = const SystemRebootClock(),
    RebootIdentityGenerator? identities,
  }) async {
    final entries = await journal.readAll();
    return LocalRebootService._(
      journal,
      clock,
      identities ?? UuidV7RebootIdentityGenerator(),
      ConfigurationLedger.replay(entries),
      ExpenseLedger.replay(entries),
      ReserveLedger.replay(entries),
      HealthLedger.replay(entries),
    );
  }

  final LocalEventJournal _journal;
  final RebootClock _clock;
  final RebootIdentityGenerator _identities;
  ConfigurationLedger _configuration;
  ExpenseLedger _expenses;
  ReserveLedger _reserves;
  HealthLedger _health;
  Future<void> _commandTail = Future<void>.value();
  bool _closed = false;

  /// Current household and annual configuration projection.
  ConfigurationLedger get configuration => _configuration;

  /// Current expense projection, including deleted history.
  ExpenseLedger get expenses => _expenses;

  /// Current named reserves and their event-derived balances.
  ReserveLedger get reserves => _reserves;

  /// Optional aggregate health tracking projection.
  HealthLedger get health => _health;

  /// Establishes the household exactly once.
  Future<HouseholdInitializationResult> initializeHousehold(
    InitializeHouseholdCommand command,
  ) {
    return _runExclusive(() async {
      _requireOpen();
      final firstCycleStart = CycleCalendar.firstCycleStart(
        onboardingDate: command.onboardingDate,
        anchorWeekday: command.anchorWeekday,
        choice: command.firstCycleChoice,
      );
      final householdId = _identities.nextEntityId();
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: command.onboardingDate,
        target: EntityReference(kind: EntityKind.household, id: householdId),
        payload: HouseholdCreatedPayload(
          householdKind: command.householdKind,
          currency: Currency.eur,
          initialCyclePolicy: CyclePolicy(
            version: 1,
            effectiveFrom: firstCycleStart,
            anchorWeekday: command.anchorWeekday,
            timeZone: command.timeZone,
          ),
        ),
      );

      await _appendValidated([event]);
      return HouseholdInitializationResult(
        householdId: householdId,
        firstCycleStart: firstCycleStart,
      );
    });
  }

  /// Creates one fixed or variable income or outflow assumption.
  Future<EntityId> createCashFlow(CreateCashFlowCommand command) {
    return _runExclusive(() async {
      _requireOpen();
      final cashFlowId = _identities.nextEntityId();
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: command.businessDate,
        target: EntityReference(kind: EntityKind.cashFlow, id: cashFlowId),
        payload: CashFlowCreatedPayload(
          definition: command.definition,
          effectiveFromCycleStart: command.effectiveFromCycleStart,
        ),
      );
      await _appendValidated([event]);
      return cashFlowId;
    });
  }

  /// Creates initial income and outflow assumptions as one journal batch.
  Future<List<EntityId>> createCashFlows(CreateCashFlowsCommand command) {
    return _runExclusive(() async {
      _requireOpen();
      final cashFlowIds = <EntityId>[];
      final events = <EventRecord>[];
      final recordedAtUtc = _clock.nowUtc();
      for (final definition in command.definitions) {
        final cashFlowId = _identities.nextEntityId();
        cashFlowIds.add(cashFlowId);
        events.add(
          EventRecord(
            id: _identities.nextEventId(),
            recordedAtUtc: recordedAtUtc,
            businessDate: command.businessDate,
            target: EntityReference(kind: EntityKind.cashFlow, id: cashFlowId),
            payload: CashFlowCreatedPayload(
              definition: definition,
              effectiveFromCycleStart: command.effectiveFromCycleStart,
            ),
          ),
        );
      }
      await _appendValidated(events);
      return List<EntityId>.unmodifiable(cashFlowIds);
    });
  }

  /// Replaces one assumption while preserving its complete history.
  Future<ProjectedCashFlow> replaceCashFlow(ReplaceCashFlowCommand command) {
    return _runExclusive(() async {
      _requireOpen();
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: command.businessDate,
        target: EntityReference(
          kind: EntityKind.cashFlow,
          id: command.cashFlowId,
        ),
        payload: CashFlowReplacedPayload(
          definition: command.definition,
          effectiveFromCycleStart: command.effectiveFromCycleStart,
        ),
      );
      await _appendValidated([event]);
      return _configuration.cashFlows[command.cashFlowId]!;
    });
  }

  /// Tombstones one assumption from a future cycle.
  Future<ProjectedCashFlow> deleteCashFlow(DeleteCashFlowCommand command) {
    return _runExclusive(() async {
      _requireOpen();
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: command.businessDate,
        target: EntityReference(
          kind: EntityKind.cashFlow,
          id: command.cashFlowId,
        ),
        payload: CashFlowDeletedPayload(
          effectiveFromCycleStart: command.effectiveFromCycleStart,
        ),
      );
      await _appendValidated([event]);
      return _configuration.cashFlows[command.cashFlowId]!;
    });
  }

  /// Sets the complete annual commitment snapshot from a future cycle.
  Future<AnnualCommitmentsRevision> setAnnualCommitments(
    SetAnnualCommitmentsCommand command,
  ) {
    return _runExclusive(() async {
      _requireOpen();
      final planId =
          _configuration.annualBudgetPlanId ?? _identities.nextEntityId();
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: command.businessDate,
        target: EntityReference(kind: EntityKind.annualBudgetPlan, id: planId),
        payload: AnnualCommitmentsSetPayload(
          effectiveFromCycleStart: command.effectiveFromCycleStart,
          reserveContributions: command.reserveContributions,
          projectContributions: command.projectContributions,
          safetyMargin: command.safetyMargin,
        ),
      );
      await _appendValidated([event]);
      return _configuration.annualCommitments.last;
    });
  }

  /// Persists the user's complete initial trajectory strategy.
  Future<AnnualCommitmentsRevision> setTrajectoryPlan(
    SetTrajectoryPlanCommand command,
  ) {
    return _runExclusive(() async {
      _requireOpen();
      final planId =
          _configuration.annualBudgetPlanId ?? _identities.nextEntityId();
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: command.businessDate,
        target: EntityReference(kind: EntityKind.annualBudgetPlan, id: planId),
        payload: TrajectoryPlanSetPayload(
          effectiveFromCycleStart: command.effectiveFromCycleStart,
          strategy: command.strategy,
          reserveContributions: command.reserveContributions,
          projectContributions: command.projectContributions,
          safetyMargin: command.safetyMargin,
          overdraftExitGoal: command.overdraftExitGoal,
        ),
      );
      await _appendValidated([event]);
      return _configuration.annualCommitments.last;
    });
  }

  /// Schedules a new cycle policy and materializes transitions on demand.
  Future<CyclePolicy> changeCyclePolicy(ChangeCyclePolicyCommand command) {
    return _runExclusive(() async {
      _requireOpen();
      final household = _configuration.household;
      if (household == null) {
        throw const IncompleteConfigurationException(
          'The household must be initialized before changing its cycle.',
        );
      }
      final previous = household.latestCyclePolicy;
      if (previous.anchorWeekday == command.anchorWeekday &&
          previous.timeZone == command.timeZone) {
        throw ArgumentError('The new cycle policy must change one setting.');
      }
      final next = CyclePolicy(
        version: previous.version + 1,
        effectiveFrom: command.effectiveFrom,
        anchorWeekday: command.anchorWeekday,
        timeZone: command.timeZone,
      );
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: command.businessDate,
        target: EntityReference(kind: EntityKind.household, id: household.id),
        payload: HouseholdCyclePolicyChangedPayload(nextPolicy: next),
      );
      await _appendValidated([event]);
      return next;
    });
  }

  /// First weekly boundary on which a configuration change may take effect.
  ///
  /// Before the household's first cycle, changes participate in that first
  /// budget. Once a cycle has started, its accepted budget is immutable and a
  /// durable assumption change starts at the following boundary.
  LocalDate nextConfigurationCycleStart(LocalDate businessDate) {
    _requireOpen();
    final household = _configuration.household;
    if (household == null) {
      throw const IncompleteConfigurationException(
        'The household must be initialized before changing configuration.',
      );
    }
    if (businessDate.isBefore(household.firstCycleStart)) {
      return household.firstCycleStart;
    }
    return household.cycleContaining(businessDate).endExclusive;
  }

  /// Calculates the explainable 52-cycle recommendation from [firstCycleStart].
  AnnualBudgetProjection buildAnnualBudget(LocalDate firstCycleStart) {
    _requireOpen();
    final household = _configuration.household;
    if (household == null) {
      throw const IncompleteConfigurationException(
        'The household must be initialized before projecting a budget.',
      );
    }
    final cycles = household.cyclesFromDate(firstCycleStart, count: 52);
    if (cycles.first.start != firstCycleStart) {
      throw ArgumentError.value(
        firstCycleStart,
        'firstCycleStart',
        'An annual projection must begin on a REBOOT cycle boundary.',
      );
    }
    return _configuration.buildAnnualBudget(cycles);
  }

  /// Projects the live weekly balances from the cycle containing [asOfDate].
  ///
  /// Before the first configured cycle, the horizon starts on that first
  /// boundary. Every cycle deliberately receives the same current weekly
  /// recommendation: an underspend or overspend never changes the next one.
  Rolling52Projection buildRollingBudget(LocalDate asOfDate) {
    _requireOpen();
    final household = _configuration.household;
    if (household == null) {
      throw const IncompleteConfigurationException(
        'The household must be initialized before projecting a budget.',
      );
    }
    final projectionStart = asOfDate.isBefore(household.firstCycleStart)
        ? household.firstCycleStart
        : household.cycleContaining(asOfDate).start;
    final cycles = household.cyclesFromDate(projectionStart, count: 52);
    final annualBudget = _configuration.buildAnnualBudget(cycles);
    return Rolling52Projection.build(
      cycles: cycles,
      budgetsByCycleStart: {
        for (final cycle in cycles)
          cycle.start: annualBudget.recommendedWeeklyBudget,
      },
      expenseLedger: _expenses,
    );
  }

  /// Builds historical trends from completed cycles only, capped at 52.
  ///
  /// Every cycle is recomputed with the configuration revision that applied
  /// at its own start. Exceptional anchor-change transitions are supplied to
  /// the pure engine so it can exclude and report them explicitly.
  TrendProjection buildTrends(LocalDate asOfDate) {
    _requireOpen();
    final household = _configuration.household;
    if (household == null) {
      throw const IncompleteConfigurationException(
        'The household must be initialized before projecting trends.',
      );
    }
    if (!asOfDate.isAfter(household.firstCycleStart)) {
      return TrendProjection.build(const []);
    }

    final currentCycle = household.cycleContaining(asOfDate);
    final reverseCompleted = <WeeklyCycle>[];
    var normalCycleCount = 0;
    var cursor = currentCycle.start.addDays(-1);
    while (!cursor.isBefore(household.firstCycleStart) &&
        normalCycleCount < 52) {
      final cycle = household.cycleContaining(cursor);
      reverseCompleted.add(cycle);
      if (cycle.includedInNormalTrends) normalCycleCount++;
      if (cycle.start == household.firstCycleStart) break;
      cursor = cycle.start.addDays(-1);
    }

    final completed = reverseCompleted.reversed;
    return TrendProjection.build([
      for (final cycle in completed)
        TrendCycleObservation(
          cycle: cycle,
          budget: _configuration
              .buildAnnualBudget(
                household.cyclesFromDate(cycle.start, count: 52),
              )
              .recommendedWeeklyBudget,
          allocatedExpenses: _allocatedExpensesFor(cycle.start),
          trajectoryCredits: _refundCreditsFor(cycle.start),
        ),
    ]);
  }

  Money _allocatedExpensesFor(LocalDate cycleStart) {
    var total = Money.zero(Currency.eur);
    for (final expense in _expenses.activeExpenses) {
      for (final allocation
          in expense.allocations ?? const <ExpenseAllocation>[]) {
        if (allocation.cycleStart == cycleStart) {
          total = total + allocation.amount;
        }
      }
    }
    return total;
  }

  Money _refundCreditsFor(LocalDate cycleStart) {
    var total = Money.zero(Currency.eur);
    for (final expense in _expenses.activeExpenses) {
      for (final refund in expense.activeRefunds) {
        if (refund.receiptCycleStart == cycleStart) {
          total = total + refund.amount;
        }
      }
    }
    return total;
  }

  /// Frequent and recent labels derived from active expense history.
  List<ExpenseLabelSuggestion> expenseSuggestions({int limit = 5}) {
    _requireOpen();
    return ExpenseInsights.suggestions(_expenses, limit: limit);
  }

  /// Optional behavioral allocation breakdown for selected cycle starts.
  ExpenseNatureBreakdown buildExpenseNatureBreakdown(
    Iterable<LocalDate> cycleStarts,
  ) {
    _requireOpen();
    return ExpenseInsights.natureBreakdown(_expenses, cycleStarts);
  }

  /// Records a real expense and its complete 1-to-12-cycle allocation atomically.
  Future<ExpenseRecordingResult> recordExpense(RecordExpenseCommand command) {
    return _runExclusive(() async {
      _requireOpen();
      if (command.allocationCycleCount < 1 ||
          command.allocationCycleCount > 12) {
        throw RangeError.range(
          command.allocationCycleCount,
          1,
          12,
          'allocationCycleCount',
        );
      }
      final household = _configuration.household;
      if (household == null) {
        throw const IncompleteConfigurationException(
          'The household must be initialized before recording expenses.',
        );
      }
      final cycles = household.cyclesFromDate(
        command.purchaseDate,
        count: command.allocationCycleCount,
      );
      final expenseId = _identities.nextEntityId();
      final recordedAt = _clock.nowUtc();
      final target = EntityReference(kind: EntityKind.expense, id: expenseId);
      final recorded = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: recordedAt,
        businessDate: command.purchaseDate,
        target: target,
        payload: ExpenseRecordedPayload(
          amount: command.amount,
          label: command.label.trim(),
          cycleAssignment: ExpenseCycleAssignment(
            cycleStart: cycles.first.start,
            policyVersion: cycles.first.policy.version,
            timeZone: cycles.first.policy.timeZone,
          ),
        ),
      );
      final allocated = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: recordedAt,
        businessDate: command.purchaseDate,
        target: target,
        payload: ExpenseAllocationsPlannedPayload.evenly(
          expenseAmount: command.amount,
          cycleStarts: [for (final cycle in cycles) cycle.start],
        ),
      );

      final natureSet = switch (command.nature) {
        final nature? => EventRecord(
          id: _identities.nextEventId(),
          recordedAtUtc: recordedAt,
          businessDate: command.purchaseDate,
          target: target,
          payload: ExpenseNatureSetPayload(nature: nature),
        ),
        null => null,
      };

      await _appendValidated([recorded, allocated, ?natureSet]);
      return ExpenseRecordingResult(
        expenseId: expenseId,
        expense: _expenses.expenses[expenseId]!,
      );
    });
  }

  /// Tombstones an erroneous expense and all of its virtual allocations.
  Future<ProjectedExpense> deleteExpense({
    required EntityId expenseId,
    required LocalDate deletionDate,
  }) {
    return _runExclusive(() async {
      _requireOpen();
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: deletionDate,
        target: EntityReference(kind: EntityKind.expense, id: expenseId),
        payload: const ExpenseDeletedPayload(),
      );
      await _appendValidated([event]);
      return _expenses.expenses[expenseId]!;
    });
  }

  /// Records a refund without changing an existing installment plan.
  Future<ExpenseRefundResult> recordExpenseRefund(
    RecordExpenseRefundCommand command,
  ) {
    return _runExclusive(() async {
      _requireOpen();
      final household = _configuration.household;
      if (household == null) {
        throw const IncompleteConfigurationException(
          'The household must be initialized before recording refunds.',
        );
      }
      final existing = _expenses.expenses[command.expenseId];
      if (existing == null || existing.isDeleted) {
        throw ArgumentError.value(
          command.expenseId,
          'expenseId',
          'A refund requires an active original expense.',
        );
      }
      if (command.receivedDate.isBefore(existing.purchaseDate)) {
        throw ArgumentError.value(
          command.receivedDate,
          'receivedDate',
          'A refund cannot precede its original expense.',
        );
      }
      final receiptCycle = household.cycleContaining(command.receivedDate);
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: command.receivedDate,
        target: EntityReference(
          kind: EntityKind.expense,
          id: command.expenseId,
        ),
        payload: ExpenseRefundedPayload(
          amount: command.amount,
          receiptCycleStart: receiptCycle.start,
        ),
      );
      await _appendValidated([event]);
      final expense = _expenses.expenses[command.expenseId]!;
      final refund = expense.refunds.last;
      return ExpenseRefundResult(
        expense: expense,
        refund: refund,
        restoresOriginalCycle:
            refund.receiptCycleStart == expense.cycleAssignment.cycleStart,
      );
    });
  }

  /// Neutralizes one erroneous refund while retaining both events.
  Future<ProjectedExpense> reverseExpenseRefund(
    ReverseExpenseRefundCommand command,
  ) {
    return _runExclusive(() async {
      _requireOpen();
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: command.businessDate,
        target: EntityReference(
          kind: EntityKind.expense,
          id: command.expenseId,
        ),
        payload: ExpenseRefundReversedPayload(
          refundEventId: command.refundEventId,
        ),
      );
      await _appendValidated([event]);
      return _expenses.expenses[command.expenseId]!;
    });
  }

  /// Starts tracking one reserve without changing income or weekly spending.
  Future<ProjectedReserve> createReserve(CreateReserveCommand command) {
    return _runExclusive(() async {
      _requireOpen();
      if (_configuration.household == null) {
        throw const IncompleteConfigurationException(
          'The household must be initialized before creating reserves.',
        );
      }
      final reserveId = _identities.nextEntityId();
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: command.businessDate,
        target: EntityReference(kind: EntityKind.reserve, id: reserveId),
        payload: ReserveCreatedPayload(
          name: command.name.trim(),
          kind: command.kind,
          openingBalance: command.openingBalance,
        ),
      );
      await _appendValidated([event]);
      return _reserves.reserves[reserveId]!;
    });
  }

  /// Records an explicit transfer-like credit into a reserve.
  Future<ProjectedReserve> addReserveFunds(AddReserveFundsCommand command) {
    return _runExclusive(() async {
      _requireOpen();
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: command.businessDate,
        target: EntityReference(
          kind: EntityKind.reserve,
          id: command.reserveId,
        ),
        payload: ReserveFundsAddedPayload(
          amount: command.amount,
          label: command.label.trim(),
        ),
      );
      await _appendValidated([event]);
      return _reserves.reserves[command.reserveId]!;
    });
  }

  /// Records an expense against a reserve with no weekly allocation.
  Future<ReserveUsageResult> useReserve(UseReserveCommand command) {
    return _runExclusive(() async {
      _requireOpen();
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: command.purchaseDate,
        target: EntityReference(
          kind: EntityKind.reserve,
          id: command.reserveId,
        ),
        payload: ReserveExpenseRecordedPayload(
          amount: command.amount,
          label: command.label.trim(),
        ),
      );
      await _appendValidated([event]);
      final reserve = _reserves.reserves[command.reserveId]!;
      return ReserveUsageResult(
        reserve: reserve,
        movement: reserve.movements.last,
        requiresBankTransfer: reserve.kind == ReserveKind.real,
      );
    });
  }

  /// Corrects one erroneous reserve movement while retaining its audit trail.
  Future<ProjectedReserve> reverseReserveMovement(
    ReverseReserveMovementCommand command,
  ) {
    return _runExclusive(() async {
      _requireOpen();
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: command.businessDate,
        target: EntityReference(
          kind: EntityKind.reserve,
          id: command.reserveId,
        ),
        payload: ReserveMovementReversedPayload(
          movementEventId: command.movementEventId,
        ),
      );
      await _appendValidated([event]);
      return _reserves.reserves[command.reserveId]!;
    });
  }

  /// Persists an explicit aggregate health-tracking configuration.
  Future<ProjectedHealthTracking> configureHealthTracking(
    ConfigureHealthTrackingCommand command,
  ) {
    return _runExclusive(() async {
      _requireOpen();
      if (_configuration.household == null) {
        throw const IncompleteConfigurationException(
          'The household must exist before configuring health tracking.',
        );
      }
      final trackerId = _health.tracking?.id ?? _identities.nextEntityId();
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: command.businessDate,
        target: EntityReference(kind: EntityKind.healthTracking, id: trackerId),
        payload: HealthTrackingConfiguredPayload(
          enabled: command.enabled,
          delayWeeks: command.delayWeeks,
          alertThreshold: command.alertThreshold,
        ),
      );
      await _appendValidated([event]);
      return _health.tracking!;
    });
  }

  /// Records one health expense, reimbursement, or handled amount.
  Future<ProjectedHealthTracking> recordHealthEntry(
    RecordHealthEntryCommand command,
  ) {
    return _runExclusive(() async {
      _requireOpen();
      final tracker = _health.tracking;
      if (tracker == null || !tracker.enabled) {
        throw const IncompleteConfigurationException(
          'Health tracking must be enabled before recording entries.',
        );
      }
      final payload = switch (command.kind) {
        HealthEntryKind.expense => HealthExpenseRecordedPayload(
          amount: command.amount,
          label: command.label.trim(),
        ),
        HealthEntryKind.reimbursement => HealthReimbursementRecordedPayload(
          amount: command.amount,
          label: command.label.trim(),
        ),
        HealthEntryKind.regularization => HealthRegularizationRecordedPayload(
          amount: command.amount,
          label: command.label.trim(),
        ),
      };
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: command.businessDate,
        target: EntityReference(
          kind: EntityKind.healthTracking,
          id: tracker.id,
        ),
        payload: payload,
      );
      await _appendValidated([event]);
      return _health.tracking!;
    });
  }

  /// Neutralizes one erroneous health entry while retaining its audit trail.
  Future<ProjectedHealthTracking> reverseHealthEntry(
    ReverseHealthEntryCommand command,
  ) {
    return _runExclusive(() async {
      _requireOpen();
      final tracker = _health.tracking;
      if (tracker == null) {
        throw const IncompleteConfigurationException(
          'Health tracking must exist before correcting entries.',
        );
      }
      final event = EventRecord(
        id: _identities.nextEventId(),
        recordedAtUtc: _clock.nowUtc(),
        businessDate: command.businessDate,
        target: EntityReference(
          kind: EntityKind.healthTracking,
          id: tracker.id,
        ),
        payload: HealthEntryReversedPayload(entryEventId: command.entryEventId),
      );
      await _appendValidated([event]);
      return _health.tracking!;
    });
  }

  /// Closes the owned journal after all earlier commands have completed.
  Future<void> close() {
    return _runExclusive(() async {
      if (_closed) {
        return;
      }
      _closed = true;
      await _journal.close();
    });
  }

  Future<void> _appendValidated(List<EventRecord> events) async {
    var nextConfiguration = _configuration;
    var nextExpenses = _expenses;
    var nextReserves = _reserves;
    var nextHealth = _health;
    var nextPosition = _configuration.lastPosition?.value ?? 0;
    for (final event in events) {
      nextPosition++;
      final provisional = LocalJournalEntry(
        position: LocalJournalPosition(nextPosition),
        event: event,
      );
      nextConfiguration = nextConfiguration.apply(provisional);
      nextExpenses = nextExpenses.apply(provisional);
      nextReserves = nextReserves.apply(provisional);
      nextHealth = nextHealth.apply(provisional);
    }

    final appended = await _journal.appendAll(events);
    if (appended.length != events.length) {
      throw StateError('The local journal returned an incomplete append.');
    }
    var committedConfiguration = _configuration;
    var committedExpenses = _expenses;
    var committedReserves = _reserves;
    var committedHealth = _health;
    for (final entry in appended) {
      committedConfiguration = committedConfiguration.apply(entry);
      committedExpenses = committedExpenses.apply(entry);
      committedReserves = committedReserves.apply(entry);
      committedHealth = committedHealth.apply(entry);
    }
    _configuration = committedConfiguration;
    _expenses = committedExpenses;
    _reserves = committedReserves;
    _health = committedHealth;
  }

  Future<T> _runExclusive<T>(Future<T> Function() action) {
    final result = Completer<T>();
    _commandTail = _commandTail.then((_) async {
      try {
        result.complete(await action());
      } on Object catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  void _requireOpen() {
    if (_closed) {
      throw StateError('The local REBOOT service is closed.');
    }
  }
}
