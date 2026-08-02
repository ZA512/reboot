import 'package:reboot_domain/reboot_domain.dart';

import 'startup_projection.dart';

/// One fully simulated temporary weekly budget.
final class LaunchPlanCandidate {
  const LaunchPlanCandidate._({
    required this.launchWeeklyBudget,
    required this.sustainableWeeklyBudget,
    required this.durationCycles,
    required this.completionDate,
    required this.completionBalance,
    required this.projection,
  });

  final Money launchWeeklyBudget;
  final Money sustainableWeeklyBudget;
  final int durationCycles;
  final LocalDate completionDate;
  final Money completionBalance;
  final StartupCashProjection projection;

  int get compressionBasisPoints {
    if (sustainableWeeklyBudget.isZero) return 0;
    final difference = sustainableWeeklyBudget - launchWeeklyBudget;
    return (difference.exactMinorUnits *
            BigInt.from(10000) ~/
            sustainableWeeklyBudget.exactMinorUnits)
        .toInt();
  }

  bool get hasSevereCompression => compressionBasisPoints > 3000;
}

/// Valid launch plans and up to three distinct user-facing suggestions.
final class LaunchPlanSearchResult {
  const LaunchPlanSearchResult._(this.validPlans);

  final List<LaunchPlanCandidate> validPlans;

  bool get isFeasible => validPlans.isNotEmpty;

  /// Highest temporary budget, using the shortest duration as a tie-breaker.
  LaunchPlanCandidate? get gentlest {
    if (validPlans.isEmpty) return null;
    return _sorted(
      validPlans,
      (left, right) =>
          right.launchWeeklyBudget.compareTo(left.launchWeeklyBudget) != 0
          ? right.launchWeeklyBudget.compareTo(left.launchWeeklyBudget)
          : left.durationCycles.compareTo(right.durationCycles),
    ).first;
  }

  /// Shortest valid duration, using the highest budget as a tie-breaker.
  LaunchPlanCandidate? get fastest {
    if (validPlans.isEmpty) return null;
    return _sorted(
      validPlans,
      (left, right) => left.durationCycles != right.durationCycles
          ? left.durationCycles.compareTo(right.durationCycles)
          : right.launchWeeklyBudget.compareTo(left.launchWeeklyBudget),
    ).first;
  }

  /// Shortest plan that does not impose severe compression.
  ///
  /// No plan above the 30% threshold is silently called recommended.
  LaunchPlanCandidate? get recommended {
    final acceptable = validPlans
        .where((plan) => !plan.hasSevereCompression)
        .toList(growable: false);
    if (acceptable.isEmpty) return null;
    return _sorted(
      acceptable,
      (left, right) => left.durationCycles != right.durationCycles
          ? left.durationCycles.compareTo(right.durationCycles)
          : right.launchWeeklyBudget.compareTo(left.launchWeeklyBudget),
    ).first;
  }

  /// Recommended, gentle, and fast without duplicate cards.
  List<LaunchPlanCandidate> get primarySuggestions {
    final result = <LaunchPlanCandidate>[];
    for (final candidate in [recommended, gentlest, fastest]) {
      if (candidate != null && !result.contains(candidate)) {
        result.add(candidate);
      }
    }
    return List<LaunchPlanCandidate>.unmodifiable(result);
  }
}

/// Exhaustive bounded search; every returned plan was simulated for 52 weeks.
abstract final class LaunchPlanSearchEngine {
  static const List<int> defaultDurations = [4, 8, 13, 26, 52];

  static LaunchPlanSearchResult search({
    required List<WeeklyCycle> cycles,
    required Money initialUsableCash,
    required Iterable<StartupCashMovement> movements,
    required Money sustainableWeeklyBudget,
    required Money minimumViableWeeklyBudget,
    required Money uncertaintyMargin,
    required CashCushionFunding funding,
    Iterable<int> durations = defaultDurations,
    int decrementMinorUnits = 500,
    Money? launchFloor,
  }) {
    _requireNonNegativeEur(
      initialUsableCash,
      'initialUsableCash',
      signed: true,
    );
    _requireNonNegativeEur(sustainableWeeklyBudget, 'sustainableWeeklyBudget');
    _requireNonNegativeEur(
      minimumViableWeeklyBudget,
      'minimumViableWeeklyBudget',
    );
    _requireNonNegativeEur(uncertaintyMargin, 'uncertaintyMargin');
    if (minimumViableWeeklyBudget.compareTo(sustainableWeeklyBudget) > 0) {
      return const LaunchPlanSearchResult._([]);
    }
    if (decrementMinorUnits <= 0) {
      throw RangeError.range(
        decrementMinorUnits,
        1,
        null,
        'decrementMinorUnits',
      );
    }
    final testedDurations = durations.toSet().toList()..sort();
    if (testedDurations.isEmpty ||
        testedDurations.any((duration) => duration < 1 || duration > 52)) {
      throw ArgumentError.value(
        durations,
        'durations',
        'Every launch duration must contain 1 to 52 cycles.',
      );
    }
    final immutableMovements = List<StartupCashMovement>.unmodifiable(
      movements,
    );
    final sustainableProjection = StartupCashProjectionEngine.project(
      cycles: cycles,
      initialUsableCash: initialUsableCash,
      movements: immutableMovements,
      weeklyBudgetsByCycleStart: {
        for (final cycle in cycles) cycle.start: sustainableWeeklyBudget,
      },
    );
    StartupLiquidityAssessment(
      projection: sustainableProjection,
      uncertaintyMargin: uncertaintyMargin,
      funding: funding,
    );

    final ordinaryFloor = funding.lowestAllowedBalance;
    final defaultLaunchFloor = initialUsableCash.compareTo(ordinaryFloor) < 0
        ? initialUsableCash
        : ordinaryFloor;
    final effectiveLaunchFloor = launchFloor ?? defaultLaunchFloor;
    if (effectiveLaunchFloor.currency != Currency.eur) {
      throw ArgumentError.value(
        effectiveLaunchFloor,
        'launchFloor',
        'The launch floor must use EUR.',
      );
    }

    final budgets = _candidateBudgets(
      sustainableWeeklyBudget,
      minimumViableWeeklyBudget,
      decrementMinorUnits,
    );
    final valid = <LaunchPlanCandidate>[];
    for (final duration in testedDurations) {
      final completionDate = cycles[duration - 1].endExclusive;
      final completionPointIndex = duration * 7 - 1;
      for (final budget in budgets) {
        final projection = StartupCashProjectionEngine.project(
          cycles: cycles,
          initialUsableCash: initialUsableCash,
          movements: immutableMovements,
          weeklyBudgetsByCycleStart: {
            for (var index = 0; index < cycles.length; index++)
              cycles[index].start: index < duration
                  ? budget
                  : sustainableWeeklyBudget,
          },
        );
        final duringLaunch = projection.points.take(duration * 7);
        if (duringLaunch.any(
          (point) => point.closingBalance.compareTo(effectiveLaunchFloor) < 0,
        )) {
          continue;
        }
        final completionBalance =
            projection.points[completionPointIndex].closingBalance;
        if (completionBalance.compareTo(funding.operatingBalance) < 0) {
          continue;
        }
        final afterLaunch = projection.points.skip(duration * 7);
        if (afterLaunch.any(
          (point) => point.closingBalance.compareTo(ordinaryFloor) < 0,
        )) {
          continue;
        }
        valid.add(
          LaunchPlanCandidate._(
            launchWeeklyBudget: budget,
            sustainableWeeklyBudget: sustainableWeeklyBudget,
            durationCycles: duration,
            completionDate: completionDate,
            completionBalance: completionBalance,
            projection: projection,
          ),
        );
      }
    }
    return LaunchPlanSearchResult._(
      List<LaunchPlanCandidate>.unmodifiable(valid),
    );
  }

  static List<Money> _candidateBudgets(
    Money sustainable,
    Money minimum,
    int decrementMinorUnits,
  ) {
    final result = <Money>[];
    final decrement = BigInt.from(decrementMinorUnits);
    var current = sustainable.exactMinorUnits;
    while (current >= minimum.exactMinorUnits) {
      result.add(Money.fromMinorUnitsBigInt(current, Currency.eur));
      current -= decrement;
    }
    if (result.isEmpty || result.last != minimum) result.add(minimum);
    return result;
  }
}

List<T> _sorted<T>(List<T> source, int Function(T, T) compare) {
  return List<T>.of(source)..sort(compare);
}

void _requireNonNegativeEur(Money amount, String name, {bool signed = false}) {
  if (amount.currency != Currency.eur || (!signed && amount.isNegative)) {
    throw ArgumentError.value(
      amount,
      name,
      signed
          ? 'The amount must use EUR.'
          : 'The amount must be non-negative EUR.',
    );
  }
}
