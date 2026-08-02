import 'package:reboot_domain/reboot_domain.dart';

import 'annualization.dart';

/// A dated cash movement not already removed from current usable cash.
enum StartupCashMovementKind {
  guaranteedIncome,
  guaranteedRefund,
  fixedCharge,
  irregularExpense,
  futurePendingOperation,
}

/// One positive, dated input of the 52-week startup simulation.
final class StartupCashMovement {
  StartupCashMovement({
    required this.date,
    required this.amount,
    required this.kind,
  }) {
    if (!amount.isPositive || amount.currency != Currency.eur) {
      throw ArgumentError.value(
        amount,
        'amount',
        'A startup cash movement must be a positive EUR amount.',
      );
    }
  }

  final LocalDate date;
  final Money amount;
  final StartupCashMovementKind kind;

  bool get isIncoming => switch (kind) {
    StartupCashMovementKind.guaranteedIncome ||
    StartupCashMovementKind.guaranteedRefund => true,
    _ => false,
  };
}

/// Auditable opening, movements, and closing balance for one civil date.
final class StartupCashProjectionPoint {
  const StartupCashProjectionPoint({
    required this.date,
    required this.openingBalance,
    required this.income,
    required this.guaranteedRefunds,
    required this.fixedCharges,
    required this.irregularExpenses,
    required this.pendingOperations,
    required this.weeklyBudgetCommitment,
    required this.closingBalance,
    required this.cumulativeVariation,
  });

  final LocalDate date;
  final Money openingBalance;
  final Money income;
  final Money guaranteedRefunds;
  final Money fixedCharges;
  final Money irregularExpenses;
  final Money pendingOperations;
  final Money weeklyBudgetCommitment;
  final Money closingBalance;

  /// Net movement since the opening of the whole projection.
  final Money cumulativeVariation;
}

/// Complete daily simulation and its timing-only cash requirement.
final class StartupCashProjection {
  const StartupCashProjection._({
    required this.points,
    required this.initialUsableCash,
    required this.minimumCumulativeVariation,
    required this.projectedLowPoint,
    required this.projectedLowPointDate,
    required this.technicalCashCushion,
  });

  final List<StartupCashProjectionPoint> points;
  final Money initialUsableCash;

  /// Lowest net movement, calculated independently of the current balance.
  final Money minimumCumulativeVariation;

  /// Lowest actual balance when starting from [initialUsableCash].
  final Money projectedLowPoint;
  final LocalDate projectedLowPointDate;

  /// Own cash or overdraft capacity needed to absorb known timing variation.
  final Money technicalCashCushion;
}

/// Pure daily projection for exactly 52 complete seven-date cycles.
abstract final class StartupCashProjectionEngine {
  static const int cycleCount = 52;

  /// Expands annualized assumptions back onto their exact occurrence dates.
  ///
  /// Remainder cents are distributed deterministically and the total remains
  /// exactly equal to the annual calculation used for the weekly budget.
  static List<StartupCashMovement> movementsFromAnnualBudget(
    AnnualBudgetProjection annualBudget,
  ) {
    final result = <StartupCashMovement>[];
    for (final line in annualBudget.cashFlows) {
      if (line.occurrences.isEmpty) continue;
      final amounts = line.total.splitEvenly(line.occurrences.length);
      for (var index = 0; index < line.occurrences.length; index++) {
        final amount = amounts[index];
        if (amount.isZero) continue;
        result.add(
          StartupCashMovement(
            date: line.occurrences[index],
            amount: amount,
            kind: line.definition.direction == CashFlowDirection.income
                ? StartupCashMovementKind.guaranteedIncome
                : StartupCashMovementKind.fixedCharge,
          ),
        );
      }
    }
    result.sort((left, right) => left.date.compareTo(right.date));
    return List<StartupCashMovement>.unmodifiable(result);
  }

  static StartupCashProjection project({
    required List<WeeklyCycle> cycles,
    required Money initialUsableCash,
    required Iterable<StartupCashMovement> movements,
    required Map<LocalDate, Money> weeklyBudgetsByCycleStart,
  }) {
    _validateCycles(cycles);
    if (initialUsableCash.currency != Currency.eur) {
      throw ArgumentError.value(
        initialUsableCash,
        'initialUsableCash',
        'Startup projection currently requires EUR.',
      );
    }
    if (weeklyBudgetsByCycleStart.length != cycles.length) {
      throw ArgumentError(
        'Every startup cycle requires one explicit weekly budget.',
      );
    }
    for (final cycle in cycles) {
      final budget = weeklyBudgetsByCycleStart[cycle.start];
      if (budget == null ||
          budget.currency != Currency.eur ||
          budget.isNegative) {
        throw ArgumentError.value(
          weeklyBudgetsByCycleStart,
          'weeklyBudgetsByCycleStart',
          'Every cycle budget must be a non-negative EUR amount.',
        );
      }
    }

    final start = cycles.first.start;
    final endExclusive = cycles.last.endExclusive;
    final movementsByDate = <LocalDate, List<StartupCashMovement>>{};
    for (final movement in movements) {
      if (movement.date.isBefore(start) ||
          !movement.date.isBefore(endExclusive)) {
        throw ArgumentError.value(
          movement.date,
          'movements',
          'Every movement must fall inside the 52-week horizon.',
        );
      }
      movementsByDate.putIfAbsent(movement.date, () => []).add(movement);
    }

    final zero = Money.zero(Currency.eur);
    final points = <StartupCashProjectionPoint>[];
    var balance = initialUsableCash;
    var minimumVariation = zero;
    var lowPoint = initialUsableCash;
    var lowPointDate = start;
    final dayCount = start.daysUntil(endExclusive);
    for (var dayOffset = 0; dayOffset < dayCount; dayOffset++) {
      final date = start.addDays(dayOffset);
      final opening = balance;
      var income = zero;
      var refunds = zero;
      var fixedCharges = zero;
      var irregular = zero;
      var pending = zero;
      for (final movement
          in movementsByDate[date] ?? const <StartupCashMovement>[]) {
        switch (movement.kind) {
          case StartupCashMovementKind.guaranteedIncome:
            income += movement.amount;
          case StartupCashMovementKind.guaranteedRefund:
            refunds += movement.amount;
          case StartupCashMovementKind.fixedCharge:
            fixedCharges += movement.amount;
          case StartupCashMovementKind.irregularExpense:
            irregular += movement.amount;
          case StartupCashMovementKind.futurePendingOperation:
            pending += movement.amount;
        }
      }
      final weeklyBudget = weeklyBudgetsByCycleStart[date] ?? zero;
      balance =
          opening +
          income +
          refunds -
          fixedCharges -
          irregular -
          pending -
          weeklyBudget;
      final variation = balance - initialUsableCash;
      if (variation.compareTo(minimumVariation) < 0) {
        minimumVariation = variation;
      }
      if (balance.compareTo(lowPoint) < 0) {
        lowPoint = balance;
        lowPointDate = date;
      }
      points.add(
        StartupCashProjectionPoint(
          date: date,
          openingBalance: opening,
          income: income,
          guaranteedRefunds: refunds,
          fixedCharges: fixedCharges,
          irregularExpenses: irregular,
          pendingOperations: pending,
          weeklyBudgetCommitment: weeklyBudget,
          closingBalance: balance,
          cumulativeVariation: variation,
        ),
      );
    }
    return StartupCashProjection._(
      points: List<StartupCashProjectionPoint>.unmodifiable(points),
      initialUsableCash: initialUsableCash,
      minimumCumulativeVariation: minimumVariation,
      projectedLowPoint: lowPoint,
      projectedLowPointDate: lowPointDate,
      technicalCashCushion: minimumVariation.isNegative
          ? -minimumVariation
          : zero,
    );
  }

  static void _validateCycles(List<WeeklyCycle> cycles) {
    if (cycles.length != cycleCount) {
      throw ArgumentError.value(
        cycles.length,
        'cycles',
        'Startup projection requires exactly 52 complete cycles.',
      );
    }
    for (var index = 0; index < cycles.length; index++) {
      final cycle = cycles[index];
      if (cycle.kind != WeeklyCycleKind.normal || cycle.dateCount != 7) {
        throw ArgumentError('Startup projection requires normal cycles only.');
      }
      if (index > 0 && cycles[index - 1].endExclusive != cycle.start) {
        throw ArgumentError('Startup cycles must be contiguous.');
      }
    }
  }
}

/// User choice describing who finances the timing cushion.
final class CashCushionFunding {
  CashCushionFunding({
    required this.targetBalance,
    required this.ownedCash,
    required this.authorizedOverdraft,
    required this.overdraftFundedCash,
  }) {
    _requireEur(targetBalance, 'targetBalance');
    for (final entry in <(String, Money)>[
      ('ownedCash', ownedCash),
      ('authorizedOverdraft', authorizedOverdraft),
      ('overdraftFundedCash', overdraftFundedCash),
    ]) {
      _requireNonNegativeEur(entry.$2, entry.$1);
    }
    if (lowestAllowedBalance.compareTo(-authorizedOverdraft) < 0) {
      throw ArgumentError(
        'The bank-financed cushion exceeds the authorized overdraft floor.',
      );
    }
  }

  /// Desired ordinary account level, usually zero.
  final Money targetBalance;

  /// Cushion kept as the household's own money on the operating account.
  final Money ownedCash;

  /// Positive depth of the bank's complete authorized overdraft.
  final Money authorizedOverdraft;

  /// Portion of the cushion deliberately financed by that authorization.
  final Money overdraftFundedCash;

  Money get totalFundedCushion => ownedCash + overdraftFundedCash;

  /// Actual account level required before ordinary weekly operation.
  Money get operatingBalance => targetBalance + ownedCash;

  /// Lowest ordinary variation explicitly accepted by the funding choice.
  Money get lowestAllowedBalance => targetBalance - overdraftFundedCash;

  bool get usesBankFunding => overdraftFundedCash.isPositive;
}

/// Separation of desired balance, timing need, and current recovery effort.
final class StartupLiquidityAssessment {
  StartupLiquidityAssessment({
    required this.projection,
    required this.uncertaintyMargin,
    required this.funding,
  }) {
    _requireNonNegativeEur(uncertaintyMargin, 'uncertaintyMargin');
    if (funding.totalFundedCushion != targetCashCushion) {
      throw ArgumentError(
        'Owned cash and overdraft funding must exactly cover the target cushion.',
      );
    }
  }

  final StartupCashProjection projection;
  final Money uncertaintyMargin;
  final CashCushionFunding funding;

  Money get targetCashCushion =>
      projection.technicalCashCushion + uncertaintyMargin;

  /// Improvement still needed before the selected ordinary operating level.
  Money get requiredProgress {
    final difference = funding.operatingBalance - projection.initialUsableCash;
    return difference.isPositive ? difference : Money.zero(Currency.eur);
  }

  /// Expected low point after starting at the selected operating balance.
  Money get protectedProjectedLowPoint =>
      funding.operatingBalance + projection.minimumCumulativeVariation;

  bool get marginIsProtected =>
      protectedProjectedLowPoint.compareTo(funding.lowestAllowedBalance) >= 0;

  bool get canStartDirectly =>
      projection.initialUsableCash.compareTo(funding.operatingBalance) >= 0 &&
      marginIsProtected;
}

/// Human viability indicators that never alter the sustainable budget.
final class HouseholdBudgetFeasibility {
  HouseholdBudgetFeasibility({
    required this.profile,
    required this.testedWeeklyBudget,
    required this.sustainableWeeklyBudget,
  }) {
    _requireNonNegativeEur(testedWeeklyBudget, 'testedWeeklyBudget');
    _requireNonNegativeEur(sustainableWeeklyBudget, 'sustainableWeeklyBudget');
  }

  final HouseholdNeedsProfile profile;
  final Money testedWeeklyBudget;
  final Money sustainableWeeklyBudget;

  Money get budgetPerPerson => Money.fromMinorUnitsBigInt(
    testedWeeklyBudget.exactMinorUnits ~/ BigInt.from(profile.personCount),
    Currency.eur,
  );

  Money get budgetPerConsumptionUnit => Money.fromMinorUnitsBigInt(
    testedWeeklyBudget.exactMinorUnits *
        BigInt.from(1000) ~/
        BigInt.from(profile.consumptionUnitMilliUnits),
    Currency.eur,
  );

  int get viabilityBasisPoints =>
      _basisPoints(testedWeeklyBudget, profile.minimumViableWeeklyBudget);

  int get launchCompressionBasisPoints {
    if (sustainableWeeklyBudget.isZero) return 0;
    final compression = sustainableWeeklyBudget - testedWeeklyBudget;
    return compression.isPositive
        ? _basisPoints(compression, sustainableWeeklyBudget)
        : 0;
  }

  bool get isBelowDeclaredMinimum =>
      testedWeeklyBudget.compareTo(profile.minimumViableWeeklyBudget) < 0;

  bool get hasSevereCompression => launchCompressionBasisPoints > 3000;
}

int _basisPoints(Money numerator, Money denominator) {
  if (numerator.isNegative || !denominator.isPositive) {
    throw ArgumentError('A ratio requires non-negative / positive amounts.');
  }
  return (numerator.exactMinorUnits *
          BigInt.from(10000) ~/
          denominator.exactMinorUnits)
      .toInt();
}

void _requireEur(Money amount, String name) {
  if (amount.currency != Currency.eur) {
    throw ArgumentError.value(amount, name, 'The amount must use EUR.');
  }
}

void _requireNonNegativeEur(Money amount, String name) {
  if (amount.currency != Currency.eur || amount.isNegative) {
    throw ArgumentError.value(
      amount,
      name,
      'The amount must be non-negative EUR.',
    );
  }
}
