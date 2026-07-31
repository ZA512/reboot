import 'package:reboot_domain/reboot_domain.dart';

/// Annual amounts deliberately kept outside the everyday weekly budget.
final class AnnualBudgetDeductions {
  /// Creates annual deductions in one explicit [currency].
  AnnualBudgetDeductions({
    required this.currency,
    Money? reserveContributions,
    Money? projectContributions,
    Money? safetyMargin,
  }) : reserveContributions = reserveContributions ?? Money.zero(currency),
       projectContributions = projectContributions ?? Money.zero(currency),
       safetyMargin = safetyMargin ?? Money.zero(currency) {
    _requireAmount(this.reserveContributions, 'reserveContributions');
    _requireAmount(this.projectContributions, 'projectContributions');
    _requireAmount(this.safetyMargin, 'safetyMargin');
  }

  /// Household currency for this projection.
  final Currency currency;

  /// Amount intentionally directed to reserves during the horizon.
  final Money reserveContributions;

  /// Amount intentionally directed to projects or purchase goals.
  final Money projectContributions;

  /// Additional conservative margin selected by the user.
  final Money safetyMargin;

  /// Exact total removed before computing the steerable capacity.
  Money get total => reserveContributions + projectContributions + safetyMargin;

  void _requireAmount(Money amount, String name) {
    if (amount.currency != currency) {
      throw CurrencyMismatchException(currency, amount.currency);
    }
    if (amount.isNegative) {
      throw ArgumentError.value(
        amount,
        name,
        'A deduction cannot be negative.',
      );
    }
  }
}

/// The result of annualizing one cash-flow definition on exact civil dates.
final class CashFlowAnnualization {
  const CashFlowAnnualization({
    required this.definition,
    required this.occurrences,
    required this.total,
  });

  /// Source definition retained for explanation and audit.
  final CashFlowDefinition definition;

  /// Actual expected occurrence dates inside the horizon.
  final List<LocalDate> occurrences;

  /// Exact amount expected over those occurrences after estimation rules.
  final Money total;
}

/// Exact weekly allocation of one already received bonus pool.
final class ReceivedBonusAllocation {
  const ReceivedBonusAllocation._({
    required this.pool,
    required this.cycles,
    required this.amounts,
  });

  /// Already available source money; never a forecast future receipt.
  final ReceivedBonusPool pool;

  /// Cycles that receive the pool before its renewal date.
  final List<WeeklyCycle> cycles;

  /// Exact additions aligned by index with [cycles].
  final List<Money> amounts;

  /// Returns the exact addition for [cycleStart], or zero outside this pool.
  Money amountFor(LocalDate cycleStart) {
    for (var index = 0; index < cycles.length; index += 1) {
      if (cycles[index].start == cycleStart) {
        return amounts[index];
      }
    }
    return Money.zero(pool.remainingForDailyLife.currency);
  }
}

/// Distributes money that already exists until its mandatory renewal date.
abstract final class ReceivedBonusAllocator {
  /// Splits [pool] over every supplied cycle that starts before its next
  /// payment date. [cyclesCoveringPaymentDate] must be contiguous and extend
  /// through that date, including a possible 53rd cycle beyond a 52-cycle
  /// projection. This prevents premature exhaustion near an anniversary.
  static ReceivedBonusAllocation allocate({
    required ReceivedBonusPool pool,
    required List<WeeklyCycle> cyclesCoveringPaymentDate,
  }) {
    if (cyclesCoveringPaymentDate.isEmpty) {
      throw ArgumentError.value(
        cyclesCoveringPaymentDate,
        'cyclesCoveringPaymentDate',
        'At least one cycle is required.',
      );
    }
    for (var index = 1; index < cyclesCoveringPaymentDate.length; index += 1) {
      if (cyclesCoveringPaymentDate[index - 1].endExclusive !=
          cyclesCoveringPaymentDate[index].start) {
        throw ArgumentError.value(
          cyclesCoveringPaymentDate,
          'cyclesCoveringPaymentDate',
          'Bonus allocation cycles must be contiguous.',
        );
      }
    }

    final first = cyclesCoveringPaymentDate.first;
    final last = cyclesCoveringPaymentDate.last;
    if (!first.start.isBefore(pool.nextPaymentDate)) {
      throw StateError(
        'The bonus must be confirmed again before this projection starts.',
      );
    }
    if (last.endExclusive.isBefore(pool.nextPaymentDate)) {
      throw ArgumentError.value(
        cyclesCoveringPaymentDate,
        'cyclesCoveringPaymentDate',
        'Cycles must cover the next bonus payment date.',
      );
    }

    final eligible = cyclesCoveringPaymentDate
        .where((cycle) => cycle.start.isBefore(pool.nextPaymentDate))
        .toList(growable: false);
    final amounts = pool.remainingForDailyLife.splitEvenly(eligible.length);
    return ReceivedBonusAllocation._(
      pool: pool,
      cycles: List<WeeklyCycle>.unmodifiable(eligible),
      amounts: amounts,
    );
  }
}

/// A complete deterministic 52-cycle budget recommendation.
final class AnnualBudgetProjection {
  const AnnualBudgetProjection({
    required this.cycles,
    required this.cashFlows,
    required this.deductions,
    required this.totalIncome,
    required this.totalOutflows,
    required this.steerableCapacity,
    required this.grossWeeklyCapacity,
    required this.recommendedWeeklyBudget,
    required this.unallocatedAnnualMargin,
    required this.deficit,
    required this.overdraftRecovery,
  });

  /// The exact 52-cycle rolling horizon.
  final List<WeeklyCycle> cycles;

  /// Annualized line-by-line explanation.
  final List<CashFlowAnnualization> cashFlows;

  /// Reserve, project, and safety amounts removed from everyday spending.
  final AnnualBudgetDeductions deductions;

  /// Exact income expected in the horizon.
  final Money totalIncome;

  /// Exact charges expected in the horizon.
  final Money totalOutflows;

  /// Income minus outflows and explicit deductions; may be negative.
  final Money steerableCapacity;

  /// Positive capacity divided by 52, preserving cents and dropping remainder.
  final Money grossWeeklyCapacity;

  /// MVP recommendation rounded down to a whole major currency unit.
  final Money recommendedWeeklyBudget;

  /// Capacity intentionally not distributed because of conservative rounding.
  final Money unallocatedAnnualMargin;

  /// Positive amount missing when capacity is negative, otherwise zero.
  final Money deficit;

  /// Time-bound weekly recovery requirement, when selected by the user.
  final OverdraftRecoveryProjection? overdraftRecovery;

  /// Start of the first included cycle.
  LocalDate get start => cycles.first.start;

  /// End of the final included cycle, excluded from the horizon.
  LocalDate get endExclusive => cycles.last.endExclusive;
}

/// Explainable weekly effort required by an overdraft-exit target.
final class OverdraftRecoveryProjection {
  const OverdraftRecoveryProjection({
    required this.goal,
    required this.cycleCount,
    required this.requiredPerCycle,
    required this.shortfallPerCycle,
  });

  /// User-confirmed balance improvement target.
  final OverdraftExitGoal goal;

  /// REBOOT cycles available before the confirmation date.
  final int cycleCount;

  /// Exact cent-rounded-up amount kept each cycle until the target.
  final Money requiredPerCycle;

  /// Amount by which the goal exceeds current weekly capacity.
  final Money shortfallPerCycle;

  /// Whether the current assumptions can support the requested date.
  bool get isFeasible => shortfallPerCycle.isZero;
}

/// Pure annualization rules for REBOOT's rolling 52-cycle trajectory.
abstract final class AnnualizationEngine {
  static const int _cycleCount = 52;

  /// Builds the recommendation for exactly 52 contiguous cycles.
  static AnnualBudgetProjection project({
    required List<WeeklyCycle> cycles,
    required Iterable<CashFlowDefinition> cashFlows,
    required AnnualBudgetDeductions deductions,
    OverdraftExitGoal? overdraftExitGoal,
  }) {
    _validateCycles(cycles);
    final horizon = List<WeeklyCycle>.unmodifiable(cycles);
    final annualized = cashFlows
        .map(
          (definition) => _annualize(
            definition,
            startInclusive: horizon.first.start,
            endExclusive: horizon.last.endExclusive,
            currency: deductions.currency,
          ),
        )
        .toList(growable: false);

    var income = Money.zero(deductions.currency);
    var outflows = Money.zero(deductions.currency);
    for (final line in annualized) {
      switch (line.definition.direction) {
        case CashFlowDirection.income:
          income += line.total;
        case CashFlowDirection.outflow:
          outflows += line.total;
      }
    }

    final capacity = income - outflows - deductions.total;
    final zero = Money.zero(deductions.currency);
    if (capacity.isNegative) {
      final recovery = overdraftExitGoal == null
          ? null
          : _projectRecovery(
              cycles: horizon,
              goal: overdraftExitGoal,
              availablePerCycle: zero,
            );
      return AnnualBudgetProjection(
        cycles: horizon,
        cashFlows: List.unmodifiable(annualized),
        deductions: deductions,
        totalIncome: income,
        totalOutflows: outflows,
        steerableCapacity: capacity,
        grossWeeklyCapacity: zero,
        recommendedWeeklyBudget: zero,
        unallocatedAnnualMargin: zero,
        deficit: -capacity,
        overdraftRecovery: recovery,
      );
    }

    final baseGross = Money.fromMinorUnits(
      capacity.minorUnits ~/ _cycleCount,
      capacity.currency,
    );
    final recovery = overdraftExitGoal == null
        ? null
        : _projectRecovery(
            cycles: horizon,
            goal: overdraftExitGoal,
            availablePerCycle: baseGross,
          );
    final recoveryWithinCapacity = recovery == null
        ? zero
        : recovery.requiredPerCycle.compareTo(baseGross) > 0
        ? baseGross
        : recovery.requiredPerCycle;
    final gross = baseGross - recoveryWithinCapacity;
    final recommendation = gross.roundDownToMajorUnit();
    final margin = capacity - recommendation * _cycleCount;
    return AnnualBudgetProjection(
      cycles: horizon,
      cashFlows: List.unmodifiable(annualized),
      deductions: deductions,
      totalIncome: income,
      totalOutflows: outflows,
      steerableCapacity: capacity,
      grossWeeklyCapacity: gross,
      recommendedWeeklyBudget: recommendation,
      unallocatedAnnualMargin: margin,
      deficit: zero,
      overdraftRecovery: recovery,
    );
  }

  static OverdraftRecoveryProjection _projectRecovery({
    required List<WeeklyCycle> cycles,
    required OverdraftExitGoal goal,
    required Money availablePerCycle,
  }) {
    if (!goal.targetDate.isAfter(cycles.first.start) ||
        goal.targetDate.isAfter(cycles.last.endExclusive)) {
      throw ArgumentError.value(
        goal.targetDate,
        'targetDate',
        'The overdraft target must fall inside the 52-cycle horizon.',
      );
    }
    final cycleCount = cycles
        .where((cycle) => cycle.start.isBefore(goal.targetDate))
        .length;
    final total = BigInt.from(goal.totalToRecover.minorUnits);
    final divisor = BigInt.from(cycleCount);
    final requiredMinorUnits = (total + divisor - BigInt.one) ~/ divisor;
    final required = Money.fromMinorUnits(
      requiredMinorUnits.toInt(),
      goal.totalToRecover.currency,
    );
    final shortfall = required.compareTo(availablePerCycle) > 0
        ? required - availablePerCycle
        : Money.zero(required.currency);
    return OverdraftRecoveryProjection(
      goal: goal,
      cycleCount: cycleCount,
      requiredPerCycle: required,
      shortfallPerCycle: shortfall,
    );
  }

  static CashFlowAnnualization _annualize(
    CashFlowDefinition definition, {
    required LocalDate startInclusive,
    required LocalDate endExclusive,
    required Currency currency,
  }) {
    if (definition.referenceAmountPerOccurrence.currency != currency) {
      throw CurrencyMismatchException(
        currency,
        definition.referenceAmountPerOccurrence.currency,
      );
    }

    final occurrences = definition.schedule.occurrencesBetween(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
    final reference = switch (definition.variableStrategy) {
      VariableEstimateStrategy.custom => definition.customAmountPerOccurrence!,
      _ => definition.referenceAmountPerOccurrence,
    };
    var exactMinorUnits =
        BigInt.from(reference.minorUnits) * BigInt.from(occurrences.length);

    if (definition.variableStrategy == VariableEstimateStrategy.prudent) {
      exactMinorUnits = switch (definition.direction) {
        CashFlowDirection.income =>
          exactMinorUnits * BigInt.from(90) ~/ BigInt.from(100),
        CashFlowDirection.outflow => _divideRoundingUp(
          exactMinorUnits * BigInt.from(110),
          100,
        ),
      };
    }

    return CashFlowAnnualization(
      definition: definition,
      occurrences: occurrences,
      total: Money.fromMinorUnits(exactMinorUnits.toInt(), currency),
    );
  }

  static BigInt _divideRoundingUp(BigInt value, int divisor) {
    if (value == BigInt.zero) {
      return BigInt.zero;
    }
    final denominator = BigInt.from(divisor);
    return (value + denominator - BigInt.one) ~/ denominator;
  }

  static void _validateCycles(List<WeeklyCycle> cycles) {
    if (cycles.length != _cycleCount) {
      throw ArgumentError.value(
        cycles.length,
        'cycles',
        'An annual projection requires exactly 52 cycles.',
      );
    }
    for (var index = 1; index < cycles.length; index += 1) {
      if (cycles[index - 1].endExclusive != cycles[index].start) {
        throw ArgumentError.value(
          cycles,
          'cycles',
          'The 52-cycle horizon must be contiguous.',
        );
      }
    }
  }
}
