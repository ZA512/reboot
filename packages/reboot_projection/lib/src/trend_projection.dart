import 'package:reboot_domain/reboot_domain.dart';

/// User-visible alert level produced by an exact ratio comparison.
enum TrendAlertSeverity {
  /// Below 5%.
  none,

  /// At least 5% and below 15%.
  vigilance,

  /// At least 15%.
  strong,
}

/// Exact non-negative ratio between two amounts of the same currency.
final class TrendRatio {
  /// Creates a ratio with a strictly positive denominator.
  TrendRatio({required this.numerator, required this.denominator}) {
    if (numerator.isNegative || !denominator.isPositive) {
      throw ArgumentError('A trend ratio requires non-negative / positive.');
    }
    if (numerator.currency != denominator.currency) {
      throw CurrencyMismatchException(numerator.currency, denominator.currency);
    }
  }

  /// Non-negative observed difference.
  final Money numerator;

  /// Positive applicable budget base.
  final Money denominator;

  /// Percentage rounded down to two decimal places, expressed in basis points.
  int get basisPoints {
    return ((numerator.exactMinorUnits * BigInt.from(10000)) ~/
            denominator.exactMinorUnits)
        .toInt();
  }

  /// Exact severity without floating-point or display rounding.
  TrendAlertSeverity get severity {
    final scaled = numerator.exactMinorUnits * BigInt.from(100);
    final base = denominator.exactMinorUnits;
    if (scaled >= base * BigInt.from(15)) {
      return TrendAlertSeverity.strong;
    }
    if (scaled >= base * BigInt.from(5)) {
      return TrendAlertSeverity.vigilance;
    }
    return TrendAlertSeverity.none;
  }
}

/// Historical budget and allocations retained for one completed cycle.
final class TrendCycleObservation {
  /// Creates one exact historical observation.
  TrendCycleObservation({
    required this.cycle,
    required this.budget,
    required this.allocatedExpenses,
    Money? trajectoryCredits,
  }) : trajectoryCredits = trajectoryCredits ?? Money.zero(Currency.eur) {
    if (budget.isNegative ||
        allocatedExpenses.isNegative ||
        this.trajectoryCredits.isNegative) {
      throw ArgumentError('Trend budgets and expenses must be non-negative.');
    }
    if (budget.currency != allocatedExpenses.currency ||
        budget.currency != this.trajectoryCredits.currency) {
      throw CurrencyMismatchException(
        budget.currency,
        allocatedExpenses.currency,
      );
    }
  }

  /// Completed civil cycle, normal or exceptional transition.
  final WeeklyCycle cycle;

  /// Recommendation that applied when this cycle began.
  final Money budget;

  /// Active virtual allocations assigned to this cycle.
  final Money allocatedExpenses;

  /// Refunds improving the trajectory without carrying into another week.
  final Money trajectoryCredits;

  /// Weekly discipline signal before trajectory-only credits.
  Money get weeklyBalance => budget - allocatedExpenses;

  /// Signed historical difference, with no carryover.
  Money get balance => weeklyBalance + trajectoryCredits;
}

/// Aggregation over one user-selected normal-cycle window.
final class TrendWindowProjection {
  const TrendWindowProjection._({
    required this.requestedCycleCount,
    required this.observedCycles,
    required this.totalBudget,
    required this.totalAllocatedExpenses,
    required this.totalTrajectoryCredits,
    required this.balance,
  });

  /// Selected window: 4, 8, 16, 32, or 52.
  final int requestedCycleCount;

  /// Available completed normal cycles, capped by the selected window.
  final List<TrendCycleObservation> observedCycles;

  /// Sum of the historical budgets that actually applied.
  final Money totalBudget;

  /// Sum of allocations assigned to the selected cycles.
  final Money totalAllocatedExpenses;

  /// Refund credits received in the selected window.
  final Money totalTrajectoryCredits;

  /// Signed budget minus allocations.
  final Money balance;
}

/// Exact trend and alert read model over at most 52 completed normal cycles.
final class TrendProjection {
  TrendProjection._({
    required this.observedCycles,
    required this.excludedTransitionCycles,
    required this.totalBudget,
    required this.totalAllocatedExpenses,
    required this.totalTrajectoryCredits,
    required this.balance,
    required this.latestOverspend,
    required this.latestOverspendRatio,
    required this.cumulativeNegativeRatio,
  });

  /// Supported user-selectable analysis windows.
  static const supportedWindows = <int>[4, 8, 16, 32, 52];

  /// Builds trends from chronologically ordered completed cycles.
  factory TrendProjection.build(
    Iterable<TrendCycleObservation> completedCycles,
  ) {
    final source = List<TrendCycleObservation>.of(completedCycles);
    for (var index = 1; index < source.length; index++) {
      if (!source[index - 1].cycle.start.isBefore(source[index].cycle.start)) {
        throw ArgumentError('Completed trend cycles must be chronological.');
      }
    }
    final transitions = List<TrendCycleObservation>.unmodifiable(
      source.where((item) => !item.cycle.includedInNormalTrends),
    );
    final normal = source
        .where((item) => item.cycle.includedInNormalTrends)
        .toList();
    final observed = List<TrendCycleObservation>.unmodifiable(
      normal.length <= 52 ? normal : normal.sublist(normal.length - 52),
    );
    final totals = _totals(observed);
    final latest = observed.lastOrNull;
    final latestOverspend = latest == null || !latest.weeklyBalance.isNegative
        ? Money.zero(Currency.eur)
        : -latest.weeklyBalance;
    final latestRatio =
        latest != null && latestOverspend.isPositive && latest.budget.isPositive
        ? TrendRatio(numerator: latestOverspend, denominator: latest.budget)
        : null;
    final cumulativeRatio =
        totals.balance.isNegative && totals.budget.isPositive
        ? TrendRatio(numerator: -totals.balance, denominator: totals.budget)
        : null;
    return TrendProjection._(
      observedCycles: observed,
      excludedTransitionCycles: transitions,
      totalBudget: totals.budget,
      totalAllocatedExpenses: totals.allocated,
      totalTrajectoryCredits: totals.credits,
      balance: totals.balance,
      latestOverspend: latestOverspend,
      latestOverspendRatio: latestRatio,
      cumulativeNegativeRatio: cumulativeRatio,
    );
  }

  /// Chronological normal cycles, capped at the latest 52.
  final List<TrendCycleObservation> observedCycles;

  /// Exceptional anchor-change cycles retained for history but not compared.
  final List<TrendCycleObservation> excludedTransitionCycles;

  /// Number of exceptional cycles omitted from normal comparisons.
  int get excludedTransitionCount => excludedTransitionCycles.length;

  /// Sum of all applicable historical budgets observed.
  final Money totalBudget;

  /// Sum of all active allocations in the observed cycles.
  final Money totalAllocatedExpenses;

  /// Refund credits improving the observed trajectory.
  final Money totalTrajectoryCredits;

  /// Main observed balance over every available cycle, up to 52.
  final Money balance;

  /// Positive overspend of the latest completed cycle, or zero.
  final Money latestOverspend;

  /// Latest-cycle overspend divided by that cycle's budget, if meaningful.
  final TrendRatio? latestOverspendRatio;

  /// Cumulative negative balance divided by all observed budgets, if negative.
  final TrendRatio? cumulativeNegativeRatio;

  /// Most important of the recent and cumulative signals.
  TrendAlertSeverity get severity => _strongest(
    latestOverspendRatio?.severity ?? TrendAlertSeverity.none,
    cumulativeNegativeRatio?.severity ?? TrendAlertSeverity.none,
  );

  /// Aggregates the most recent cycles inside a supported window.
  TrendWindowProjection window(int requestedCycleCount) {
    if (!supportedWindows.contains(requestedCycleCount)) {
      throw ArgumentError.value(
        requestedCycleCount,
        'requestedCycleCount',
        'Supported trend windows are 4, 8, 16, 32, and 52.',
      );
    }
    final start = observedCycles.length > requestedCycleCount
        ? observedCycles.length - requestedCycleCount
        : 0;
    final selected = List<TrendCycleObservation>.unmodifiable(
      observedCycles.sublist(start),
    );
    final totals = _totals(selected);
    return TrendWindowProjection._(
      requestedCycleCount: requestedCycleCount,
      observedCycles: selected,
      totalBudget: totals.budget,
      totalAllocatedExpenses: totals.allocated,
      totalTrajectoryCredits: totals.credits,
      balance: totals.balance,
    );
  }
}

({Money budget, Money allocated, Money credits, Money balance}) _totals(
  Iterable<TrendCycleObservation> observations,
) {
  var budget = Money.zero(Currency.eur);
  var allocated = Money.zero(Currency.eur);
  var credits = Money.zero(Currency.eur);
  for (final item in observations) {
    budget = budget + item.budget;
    allocated = allocated + item.allocatedExpenses;
    credits = credits + item.trajectoryCredits;
  }
  return (
    budget: budget,
    allocated: allocated,
    credits: credits,
    balance: budget - allocated + credits,
  );
}

TrendAlertSeverity _strongest(
  TrendAlertSeverity left,
  TrendAlertSeverity right,
) => left.index >= right.index ? left : right;
