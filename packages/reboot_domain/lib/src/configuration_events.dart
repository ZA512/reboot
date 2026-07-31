import 'cash_flows.dart';
import 'cycles.dart';
import 'events.dart';
import 'local_date.dart';
import 'money.dart';

/// Household shape supported by the first REBOOT product.
enum HouseholdKind {
  /// One person pilots one weekly budget.
  solo,

  /// Several people share one principal account and one weekly budget.
  sharedMainAccount,
}

/// Version 1 payload that establishes the local household profile.
final class HouseholdCreatedPayload implements EventPayload {
  /// Creates the one initial household configuration.
  HouseholdCreatedPayload({
    required this.householdKind,
    required this.currency,
    required this.initialCyclePolicy,
  }) {
    if (currency != Currency.eur) {
      throw ArgumentError.value(
        currency,
        'currency',
        'The first REBOOT household schema supports EUR only.',
      );
    }
    if (initialCyclePolicy.version != 1) {
      throw ArgumentError.value(
        initialCyclePolicy.version,
        'initialCyclePolicy',
        'The initial cycle policy must use version 1.',
      );
    }
  }

  @override
  String get eventType => 'household.created';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.household;

  /// Solo or shared-principal-account mode.
  final HouseholdKind householdKind;

  /// One explicit household currency.
  final Currency currency;

  /// Initial anchor weekday, time zone, and first effective date.
  final CyclePolicy initialCyclePolicy;
}

/// Version 1 payload accepting a new cycle policy for future cycles.
final class HouseholdCyclePolicyChangedPayload implements EventPayload {
  /// Creates a complete replacement policy snapshot.
  const HouseholdCyclePolicyChangedPayload({required this.nextPolicy});

  @override
  String get eventType => 'household.cycle-policy.changed';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.household;

  /// New versioned policy. Projection validates it against prior history.
  final CyclePolicy nextPolicy;
}

/// Version 1 payload that creates one recurring income or outflow assumption.
final class CashFlowCreatedPayload implements EventPayload {
  /// Creates a cash-flow definition effective from a materialized cycle start.
  const CashFlowCreatedPayload({
    required this.definition,
    required this.effectiveFromCycleStart,
  });

  @override
  String get eventType => 'cash-flow.created';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.cashFlow;

  /// Complete immutable definition accepted by the user.
  final CashFlowDefinition definition;

  /// First weekly cycle whose recommendation may use this definition.
  final LocalDate effectiveFromCycleStart;
}

/// Version 1 payload that completely replaces a cash-flow assumption.
final class CashFlowReplacedPayload implements EventPayload {
  /// Creates a replacement effective from a materialized cycle start.
  const CashFlowReplacedPayload({
    required this.definition,
    required this.effectiveFromCycleStart,
  });

  @override
  String get eventType => 'cash-flow.replaced';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.cashFlow;

  /// Complete new definition; prior versions remain in the journal.
  final CashFlowDefinition definition;

  /// First weekly cycle whose recommendation may use the replacement.
  final LocalDate effectiveFromCycleStart;
}

/// Version 1 tombstone that removes a cash flow from future recommendations.
final class CashFlowDeletedPayload implements EventPayload {
  /// Creates a future-effective cash-flow tombstone.
  const CashFlowDeletedPayload({required this.effectiveFromCycleStart});

  @override
  String get eventType => 'cash-flow.deleted';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.cashFlow;

  /// First weekly cycle from which the definition is absent.
  final LocalDate effectiveFromCycleStart;
}

/// Version 1 payload accepting annual amounts protected from daily spending.
final class AnnualCommitmentsSetPayload implements EventPayload {
  /// Creates a complete annual commitment snapshot.
  AnnualCommitmentsSetPayload({
    required this.effectiveFromCycleStart,
    required this.reserveContributions,
    required this.projectContributions,
    required this.safetyMargin,
  }) {
    _requireNonNegativeEur(reserveContributions, 'reserveContributions');
    _requireNonNegativeEur(projectContributions, 'projectContributions');
    _requireNonNegativeEur(safetyMargin, 'safetyMargin');
  }

  @override
  String get eventType => 'annual-commitments.set';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.annualBudgetPlan;

  /// First weekly cycle whose trajectory uses this complete snapshot.
  final LocalDate effectiveFromCycleStart;

  /// Total amount intentionally directed to reserves over 52 cycles.
  final Money reserveContributions;

  /// Total amount intentionally directed to projects over 52 cycles.
  final Money projectContributions;

  /// Additional visible conservative margin over 52 cycles.
  final Money safetyMargin;
}

void _requireNonNegativeEur(Money amount, String name) {
  if (amount.isNegative || amount.currency != Currency.eur) {
    throw ArgumentError.value(
      amount,
      name,
      'An annual commitment must be a non-negative EUR amount.',
    );
  }
}
