import 'package:reboot_domain/reboot_domain.dart';

import 'expense_ledger.dart';

/// Financial state projected for one materialized cycle.
final class ProjectedCycleFinances {
  const ProjectedCycleFinances({
    required this.cycle,
    required this.budget,
    required this.allocatedExpenses,
    required this.refundCredits,
    required this.remaining,
  });

  /// Auditable civil cycle.
  final WeeklyCycle cycle;

  /// User-selected budget applicable to this cycle.
  final Money budget;

  /// Sum of active virtual expense allocations targeting this cycle.
  final Money allocatedExpenses;

  /// Refunds received inside their original purchase cycle.
  final Money refundCredits;

  /// Signed budget minus allocations; may be negative.
  final Money remaining;

  /// Whether allocations exceed the selected budget.
  bool get isOverBudget => remaining.isNegative;
}

/// Immutable financial projection over exactly 52 consecutive cycles.
final class Rolling52Projection {
  Rolling52Projection._(List<ProjectedCycleFinances> cycles)
    : cycles = List<ProjectedCycleFinances>.unmodifiable(cycles);

  /// Builds the projection without carrying surplus or deficit between cycles.
  factory Rolling52Projection.build({
    required List<WeeklyCycle> cycles,
    required Map<LocalDate, Money> budgetsByCycleStart,
    required ExpenseLedger expenseLedger,
  }) {
    if (cycles.length != 52) {
      throw ArgumentError.value(
        cycles.length,
        'cycles',
        'A rolling REBOOT horizon must contain exactly 52 cycles.',
      );
    }
    for (var index = 1; index < cycles.length; index++) {
      if (cycles[index - 1].endExclusive != cycles[index].start) {
        throw ArgumentError.value(
          cycles,
          'cycles',
          'The rolling horizon contains a gap or overlap.',
        );
      }
    }

    final cycleStarts = {for (final cycle in cycles) cycle.start};
    final horizonStart = cycles.first.start;
    final horizonEnd = cycles.last.endExclusive;
    final allocationsByCycleStart = <LocalDate, Money>{};
    final refundsByCycleStart = <LocalDate, Money>{};
    for (final expense in expenseLedger.activeExpenses) {
      final allocations = expense.allocations;
      if (allocations == null) {
        throw UnallocatedExpenseException(expense.id);
      }
      for (final allocation in allocations) {
        if (!cycleStarts.contains(allocation.cycleStart)) {
          final fallsInsideHorizon =
              !allocation.cycleStart.isBefore(horizonStart) &&
              allocation.cycleStart.isBefore(horizonEnd);
          if (fallsInsideHorizon) {
            throw InvalidAllocationCycleException(
              expenseId: expense.id,
              cycleStart: allocation.cycleStart,
            );
          }
          continue;
        }
        allocationsByCycleStart.update(
          allocation.cycleStart,
          (existing) => existing + allocation.amount,
          ifAbsent: () => allocation.amount,
        );
      }
      for (final refund in expense.activeRefunds) {
        final restoresOriginalCycle =
            refund.receiptCycleStart == expense.cycleAssignment.cycleStart;
        if (!restoresOriginalCycle ||
            !cycleStarts.contains(refund.receiptCycleStart)) {
          continue;
        }
        refundsByCycleStart.update(
          refund.receiptCycleStart,
          (existing) => existing + refund.amount,
          ifAbsent: () => refund.amount,
        );
      }
    }

    return Rolling52Projection._([
      for (final cycle in cycles)
        _projectCycle(
          cycle: cycle,
          budget: _requiredBudget(cycle, budgetsByCycleStart),
          allocatedExpenses:
              allocationsByCycleStart[cycle.start] ?? Money.zero(Currency.eur),
          refundCredits:
              refundsByCycleStart[cycle.start] ?? Money.zero(Currency.eur),
        ),
    ]);
  }

  /// Ordered 52-cycle financial states.
  final List<ProjectedCycleFinances> cycles;

  /// Returns the projected state identified by [cycleStart].
  ProjectedCycleFinances cycleStarting(LocalDate cycleStart) {
    return cycles.firstWhere(
      (cycle) => cycle.cycle.start == cycleStart,
      orElse: () =>
          throw StateError('Cycle $cycleStart is outside the rolling horizon.'),
    );
  }

  static Money _requiredBudget(
    WeeklyCycle cycle,
    Map<LocalDate, Money> budgetsByCycleStart,
  ) {
    final budget = budgetsByCycleStart[cycle.start];
    if (budget == null) {
      throw MissingCycleBudgetException(cycle.start);
    }
    if (budget.isNegative || budget.currency != Currency.eur) {
      throw ArgumentError.value(
        budget,
        'budgetsByCycleStart',
        'A selected weekly budget must be a non-negative EUR value.',
      );
    }
    return budget;
  }

  static ProjectedCycleFinances _projectCycle({
    required WeeklyCycle cycle,
    required Money budget,
    required Money allocatedExpenses,
    required Money refundCredits,
  }) {
    return ProjectedCycleFinances(
      cycle: cycle,
      budget: budget,
      allocatedExpenses: allocatedExpenses,
      refundCredits: refundCredits,
      remaining: budget - allocatedExpenses + refundCredits,
    );
  }
}

/// Indicates that an active expense lacks its mandatory allocation event.
final class UnallocatedExpenseException implements Exception {
  /// Creates an incomplete-journal error for [expenseId].
  const UnallocatedExpenseException(this.expenseId);

  /// Expense missing its plan.
  final EntityId expenseId;

  @override
  String toString() => 'UnallocatedExpenseException: $expenseId';
}

/// Indicates that one materialized cycle has no selected budget.
final class MissingCycleBudgetException implements Exception {
  /// Creates a missing-budget error for [cycleStart].
  const MissingCycleBudgetException(this.cycleStart);

  /// Cycle without a budget.
  final LocalDate cycleStart;

  @override
  String toString() => 'MissingCycleBudgetException: $cycleStart';
}

/// Indicates an allocation date that is not a materialized cycle identifier.
final class InvalidAllocationCycleException implements Exception {
  /// Creates an invalid target error.
  const InvalidAllocationCycleException({
    required this.expenseId,
    required this.cycleStart,
  });

  /// Expense carrying the invalid allocation.
  final EntityId expenseId;

  /// In-horizon date that does not identify a cycle start.
  final LocalDate cycleStart;

  @override
  String toString() {
    return 'InvalidAllocationCycleException: expense $expenseId targets '
        '$cycleStart';
  }
}
