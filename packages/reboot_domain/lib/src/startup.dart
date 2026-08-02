import 'money.dart';

/// How fresh and reliable one manually or automatically captured value is.
enum StartupDataConfidence { high, medium, low }

/// Origin of a liquidity snapshot used by the startup assessment.
enum LiquiditySnapshotSource { manual, imported, synchronized }

/// Current account facts after money already committed has been identified.
final class LiquiditySnapshot {
  /// Creates one immutable view of the account at a UTC instant.
  LiquiditySnapshot({
    required this.capturedAtUtc,
    required this.bookedBalance,
    required this.source,
    required this.confidence,
    Money? pendingCardAmount,
    Money? deferredCardAmount,
    Money? outstandingCheques,
    Money? committedTransfers,
    Money? protectedVirtualAllocations,
  }) : pendingCardAmount =
           pendingCardAmount ?? Money.zero(bookedBalance.currency),
       deferredCardAmount =
           deferredCardAmount ?? Money.zero(bookedBalance.currency),
       outstandingCheques =
           outstandingCheques ?? Money.zero(bookedBalance.currency),
       committedTransfers =
           committedTransfers ?? Money.zero(bookedBalance.currency),
       protectedVirtualAllocations =
           protectedVirtualAllocations ?? Money.zero(bookedBalance.currency) {
    if (!capturedAtUtc.isUtc) {
      throw ArgumentError.value(
        capturedAtUtc,
        'capturedAtUtc',
        'A liquidity snapshot timestamp must be UTC.',
      );
    }
    for (final entry in <(String, Money)>[
      ('pendingCardAmount', this.pendingCardAmount),
      ('deferredCardAmount', this.deferredCardAmount),
      ('outstandingCheques', this.outstandingCheques),
      ('committedTransfers', this.committedTransfers),
      ('protectedVirtualAllocations', this.protectedVirtualAllocations),
    ]) {
      _requireNonNegativeCurrency(entry.$2, bookedBalance.currency, entry.$1);
    }
  }

  final DateTime capturedAtUtc;
  final Money bookedBalance;
  final Money pendingCardAmount;
  final Money deferredCardAmount;
  final Money outstandingCheques;
  final Money committedTransfers;
  final Money protectedVirtualAllocations;
  final LiquiditySnapshotSource source;
  final StartupDataConfidence confidence;

  /// Money genuinely available now, before future uncommitted dated flows.
  ///
  /// Amounts removed here must not be removed a second time by the daily
  /// projection when their bank debit eventually appears.
  Money get usableCash =>
      bookedBalance -
      pendingCardAmount -
      deferredCardAmount -
      outstandingCheques -
      committedTransfers -
      protectedVirtualAllocations;
}

/// Broad categories that may belong to the steerable weekly amount.
enum WeeklyBudgetCategory {
  groceries,
  fuel,
  hygiene,
  clothing,
  children,
  healthOutOfPocket,
  leisure,
  everydayPurchases,
  other,
}

/// Age band used by the modified OECD equivalence scale.
enum HouseholdNeedAgeBand { age14OrOlder, under14 }

/// One additional person whose costs are present only part of the time.
final class PartialHouseholdPresence {
  /// [presencePermille] is an explicit approximation between 0.1% and 99.9%.
  PartialHouseholdPresence({
    required this.ageBand,
    required this.presencePermille,
  }) {
    if (presencePermille < 1 || presencePermille > 999) {
      throw RangeError.range(presencePermille, 1, 999, 'presencePermille');
    }
  }

  final HouseholdNeedAgeBand ageBand;
  final int presencePermille;
}

/// Economic household covered by the weekly budget, not application accounts.
final class HouseholdNeedsProfile {
  /// Creates a complete profile with one full-time primary adult.
  HouseholdNeedsProfile({
    required this.fullTimePersons14OrOlder,
    required this.fullTimeChildrenUnder14,
    required Set<WeeklyBudgetCategory> weeklyBudgetScope,
    required this.minimumViableWeeklyBudget,
    Iterable<PartialHouseholdPresence> partialPresences = const [],
  }) : weeklyBudgetScope = Set<WeeklyBudgetCategory>.unmodifiable(
         weeklyBudgetScope,
       ),
       partialPresences = List<PartialHouseholdPresence>.unmodifiable(
         partialPresences,
       ) {
    if (fullTimePersons14OrOlder < 1) {
      throw RangeError.range(
        fullTimePersons14OrOlder,
        1,
        null,
        'fullTimePersons14OrOlder',
      );
    }
    if (fullTimeChildrenUnder14 < 0) {
      throw RangeError.range(
        fullTimeChildrenUnder14,
        0,
        null,
        'fullTimeChildrenUnder14',
      );
    }
    if (this.weeklyBudgetScope.isEmpty) {
      throw ArgumentError.value(
        weeklyBudgetScope,
        'weeklyBudgetScope',
        'A complete profile requires at least one weekly category.',
      );
    }
    if (!minimumViableWeeklyBudget.isPositive ||
        minimumViableWeeklyBudget.currency != Currency.eur) {
      throw ArgumentError.value(
        minimumViableWeeklyBudget,
        'minimumViableWeeklyBudget',
        'The declared minimum must be a positive EUR amount.',
      );
    }
  }

  final int fullTimePersons14OrOlder;
  final int fullTimeChildrenUnder14;
  final List<PartialHouseholdPresence> partialPresences;
  final Set<WeeklyBudgetCategory> weeklyBudgetScope;
  final Money minimumViableWeeklyBudget;

  /// Physical people covered, including people with partial presence.
  int get personCount =>
      fullTimePersons14OrOlder +
      fullTimeChildrenUnder14 +
      partialPresences.length;

  /// Modified OECD consumption units in exact thousandths of one unit.
  int get consumptionUnitMilliUnits {
    var result = 1000;
    result += (fullTimePersons14OrOlder - 1) * 500;
    result += fullTimeChildrenUnder14 * 300;
    for (final presence in partialPresences) {
      final fullWeight = switch (presence.ageBand) {
        HouseholdNeedAgeBand.age14OrOlder => 500,
        HouseholdNeedAgeBand.under14 => 300,
      };
      result += fullWeight * presence.presencePermille ~/ 1000;
    }
    return result;
  }
}

/// Outcome categories required by the startup supplement.
enum LaunchDecisionState {
  dataIncomplete,
  householdProfileIncomplete,
  weeklyScopeIncomplete,
  pendingOperationsUnknown,
  upcomingExpenseUnfunded,
  structuralDeficit,
  structurallyTooTight,
  readyWithSustainableBudget,
  readyWithExistingCushion,
  readyWithReserveTransfer,
  readyWithLaunchBudget,
  readyAtLaterDate,
  readyWithOverdraftRecovery,
  launchExcessiveCompression,
  launchNotFeasible,
  userDeferredDecision,
}

void _requireNonNegativeCurrency(Money amount, Currency currency, String name) {
  if (amount.currency != currency || amount.isNegative) {
    throw ArgumentError.value(
      amount,
      name,
      'The amount must be non-negative and use ${currency.code}.',
    );
  }
}
