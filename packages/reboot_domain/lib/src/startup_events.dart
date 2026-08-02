import 'events.dart';
import 'local_date.dart';
import 'money.dart';
import 'startup.dart';

/// Records the account facts confirmed for one startup assessment.
final class LiquiditySnapshotCreatedPayload implements EventPayload {
  const LiquiditySnapshotCreatedPayload({required this.snapshot});

  @override
  String get eventType => 'startup.liquidity-snapshot.created';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.startupPlan;

  final LiquiditySnapshot snapshot;
}

/// Records who and what the steerable weekly budget must cover.
final class HouseholdNeedsProfileCreatedPayload implements EventPayload {
  const HouseholdNeedsProfileCreatedPayload({required this.profile});

  @override
  String get eventType => 'startup.household-needs.created';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.startupPlan;

  final HouseholdNeedsProfile profile;
}

/// Exact split between the desired balance and the timing cushion.
final class CashCushionPolicyCreatedPayload implements EventPayload {
  CashCushionPolicyCreatedPayload({
    required this.targetBalance,
    required this.technicalCushion,
    required this.uncertaintyMargin,
    required this.ownedCash,
    required this.authorizedOverdraft,
    required this.overdraftFundedCash,
  }) {
    _requireEur(targetBalance, 'targetBalance', signed: true);
    for (final entry in <(String, Money)>[
      ('technicalCushion', technicalCushion),
      ('uncertaintyMargin', uncertaintyMargin),
      ('ownedCash', ownedCash),
      ('authorizedOverdraft', authorizedOverdraft),
      ('overdraftFundedCash', overdraftFundedCash),
    ]) {
      _requireEur(entry.$2, entry.$1);
    }
    if (ownedCash + overdraftFundedCash != targetCashCushion) {
      throw ArgumentError(
        'The funding split must exactly equal the target cash cushion.',
      );
    }
    if ((targetBalance - overdraftFundedCash).compareTo(-authorizedOverdraft) <
        0) {
      throw ArgumentError(
        'The selected bank cushion exceeds the authorized overdraft.',
      );
    }
  }

  @override
  String get eventType => 'startup.cash-cushion-policy.created';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.startupPlan;

  final Money targetBalance;
  final Money technicalCushion;
  final Money uncertaintyMargin;
  final Money ownedCash;
  final Money authorizedOverdraft;
  final Money overdraftFundedCash;

  Money get targetCashCushion => technicalCushion + uncertaintyMargin;
}

/// Durable result of one complete 52-week assessment.
final class LaunchAssessmentCreatedPayload implements EventPayload {
  LaunchAssessmentCreatedPayload({
    required this.sustainableWeeklyBudget,
    required this.minimumViableWeeklyBudget,
    required this.projectedLowPoint,
    required this.projectedLowPointDate,
    required this.decisionState,
    required this.confidence,
  }) {
    _requireEur(sustainableWeeklyBudget, 'sustainableWeeklyBudget');
    _requireEur(minimumViableWeeklyBudget, 'minimumViableWeeklyBudget');
    _requireEur(projectedLowPoint, 'projectedLowPoint', signed: true);
  }

  @override
  String get eventType => 'startup.launch-assessment.created';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.startupPlan;

  final Money sustainableWeeklyBudget;
  final Money minimumViableWeeklyBudget;
  final Money projectedLowPoint;
  final LocalDate projectedLowPointDate;
  final LaunchDecisionState decisionState;
  final StartupDataConfidence confidence;
}

enum StartupViabilityAnswer { comfortable, tight, rejected, uncertain }

/// User acceptance of the exact temporary or immediate weekly plan.
final class LaunchPlanAcceptedPayload implements EventPayload {
  LaunchPlanAcceptedPayload({
    required this.startDate,
    required this.launchWeeklyBudget,
    required this.sustainableWeeklyBudget,
    required this.durationCycles,
    required this.estimatedCompletionDate,
    required this.expectedLowPoint,
    required this.decisionState,
    required this.viabilityAnswer,
    required this.acceptedBankFundingRisk,
  }) {
    _requireEur(launchWeeklyBudget, 'launchWeeklyBudget');
    _requireEur(sustainableWeeklyBudget, 'sustainableWeeklyBudget');
    _requireEur(expectedLowPoint, 'expectedLowPoint', signed: true);
    if (durationCycles < 0 || durationCycles > 52) {
      throw RangeError.range(durationCycles, 0, 52, 'durationCycles');
    }
    if (launchWeeklyBudget.compareTo(sustainableWeeklyBudget) > 0) {
      throw ArgumentError(
        'A launch budget cannot exceed the sustainable weekly budget.',
      );
    }
    if (estimatedCompletionDate.isBefore(startDate)) {
      throw ArgumentError('Launch completion cannot precede its start.');
    }
  }

  @override
  String get eventType => 'startup.launch-plan.accepted';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.startupPlan;

  final LocalDate startDate;
  final Money launchWeeklyBudget;
  final Money sustainableWeeklyBudget;
  final int durationCycles;
  final LocalDate estimatedCompletionDate;
  final Money expectedLowPoint;
  final LaunchDecisionState decisionState;
  final StartupViabilityAnswer viabilityAnswer;
  final bool acceptedBankFundingRisk;
}

void _requireEur(Money amount, String name, {bool signed = false}) {
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
