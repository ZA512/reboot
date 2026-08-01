import 'package:reboot_domain/reboot_domain.dart';

import 'expense_ledger.dart';

/// One frequent or recent label proposed as a quick-entry shortcut.
final class ExpenseLabelSuggestion {
  const ExpenseLabelSuggestion({
    required this.label,
    required this.nature,
    required this.useCount,
    required this.lastUsedAtUtc,
  });

  /// Most recently used visible spelling.
  final String label;

  /// Qualification from the most recent matching expense, if any.
  final ExpenseNature? nature;

  /// Number of active expenses sharing the normalized label.
  final int useCount;

  /// Recency tie-breaker after frequency.
  final DateTime lastUsedAtUtc;
}

/// One qualified or unqualified share of weekly allocations.
final class ExpenseNatureShare {
  const ExpenseNatureShare({
    required this.nature,
    required this.amount,
    required this.basisPoints,
  });

  /// Null represents expenses the user chose not to qualify.
  final ExpenseNature? nature;

  /// Exact allocation total in the selected cycles.
  final Money amount;

  /// Exact share rounded down to two percentage decimal places.
  final int basisPoints;
}

/// Optional behavioral breakdown that never affects the weekly budget.
final class ExpenseNatureBreakdown {
  ExpenseNatureBreakdown._({
    required Map<ExpenseNature, Money> amounts,
    required this.unqualified,
    required this.total,
  }) : amounts = Map<ExpenseNature, Money>.unmodifiable(amounts);

  /// Exact allocation totals for each selected nature.
  final Map<ExpenseNature, Money> amounts;

  /// Allocations without an optional qualification.
  final Money unqualified;

  /// All selected allocations, qualified or not.
  final Money total;

  /// Non-zero shares in stable method order, with unqualified last.
  List<ExpenseNatureShare> get shares => List.unmodifiable([
    for (final nature in ExpenseNature.values)
      if ((amounts[nature] ?? Money.zero(Currency.eur)).isPositive)
        _share(nature, amounts[nature]!),
    if (unqualified.isPositive) _share(null, unqualified),
  ]);

  ExpenseNatureShare _share(ExpenseNature? nature, Money amount) {
    final basisPoints = total.isZero
        ? 0
        : ((amount.exactMinorUnits * BigInt.from(10000)) ~/
                  total.exactMinorUnits)
              .toInt();
    return ExpenseNatureShare(
      nature: nature,
      amount: amount,
      basisPoints: basisPoints,
    );
  }
}

/// Pure insights derived from the existing expense journal projection.
abstract final class ExpenseInsights {
  /// Ranks active labels by frequency, then recency, without storing profiles.
  static List<ExpenseLabelSuggestion> suggestions(
    ExpenseLedger ledger, {
    int limit = 5,
  }) {
    if (limit < 0) throw RangeError.range(limit, 0, null, 'limit');
    final aggregates = <String, _SuggestionAggregate>{};
    for (final expense in ledger.activeExpenses) {
      final key = expense.label
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ')
          .toLowerCase();
      final previous = aggregates[key];
      if (previous == null) {
        aggregates[key] = _SuggestionAggregate(
          label: expense.label,
          nature: expense.nature,
          useCount: 1,
          lastUsedAtUtc: expense.recordedAtUtc,
        );
      } else {
        previous.useCount++;
        // Map insertion order follows journal replay; equality therefore means
        // this expense is the later fact even when clock precision collides.
        if (!expense.recordedAtUtc.isBefore(previous.lastUsedAtUtc)) {
          previous
            ..label = expense.label
            ..nature = expense.nature
            ..lastUsedAtUtc = expense.recordedAtUtc;
        }
      }
    }
    final ranked =
        [
          for (final item in aggregates.values)
            ExpenseLabelSuggestion(
              label: item.label,
              nature: item.nature,
              useCount: item.useCount,
              lastUsedAtUtc: item.lastUsedAtUtc,
            ),
        ]..sort((left, right) {
          final byCount = right.useCount.compareTo(left.useCount);
          if (byCount != 0) return byCount;
          final byRecency = right.lastUsedAtUtc.compareTo(left.lastUsedAtUtc);
          if (byRecency != 0) return byRecency;
          return left.label.compareTo(right.label);
        });
    return List.unmodifiable(ranked.take(limit));
  }

  /// Aggregates only virtual weekly allocations targeting [cycleStarts].
  static ExpenseNatureBreakdown natureBreakdown(
    ExpenseLedger ledger,
    Iterable<LocalDate> cycleStarts,
  ) {
    final selected = cycleStarts.toSet();
    final amounts = <ExpenseNature, Money>{};
    var unqualified = Money.zero(Currency.eur);
    for (final expense in ledger.activeExpenses) {
      for (final allocation
          in expense.allocations ?? const <ExpenseAllocation>[]) {
        if (!selected.contains(allocation.cycleStart)) continue;
        final nature = expense.nature;
        if (nature == null) {
          unqualified = unqualified + allocation.amount;
        } else {
          amounts.update(
            nature,
            (current) => current + allocation.amount,
            ifAbsent: () => allocation.amount,
          );
        }
      }
    }
    final total =
        amounts.values.fold(
          Money.zero(Currency.eur),
          (sum, amount) => sum + amount,
        ) +
        unqualified;
    return ExpenseNatureBreakdown._(
      amounts: amounts,
      unqualified: unqualified,
      total: total,
    );
  }
}

final class _SuggestionAggregate {
  _SuggestionAggregate({
    required this.label,
    required this.nature,
    required this.useCount,
    required this.lastUsedAtUtc,
  });

  String label;
  ExpenseNature? nature;
  int useCount;
  DateTime lastUsedAtUtc;
}
