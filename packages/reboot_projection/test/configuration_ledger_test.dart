import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigurationLedger replay', () {
    test('reconstructs onboarding and its annual recommendation', () {
      final ledger = ConfigurationLedger.replay([
        _householdEntry(1),
        _commitmentsEntry(2),
        _cashFlowCreatedEntry(3, _salary(300000), _salaryId),
        _cashFlowCreatedEntry(4, _rent(100000), _rentId),
      ]);
      final projection = ledger.buildAnnualBudget(_cycles());

      expect(ledger.household!.householdKind, HouseholdKind.sharedMainAccount);
      expect(ledger.household!.firstCycleStart, _firstCycleStart);
      expect(ledger.cashFlows, hasLength(2));
      expect(projection.totalIncome.minorUnits, 3600000);
      expect(projection.totalOutflows.minorUnits, 1200000);
      expect(projection.deductions.total.minorUnits, 204000);
      expect(projection.steerableCapacity.minorUnits, 2196000);
      expect(projection.recommendedWeeklyBudget.minorUnits, 42200);
      expect(projection.unallocatedAnnualMargin.minorUnits, 1600);
    });

    test('keeps the current amount until a replacement becomes effective', () {
      final replacementStart = _firstCycleStart.addDays(7);
      final ledger = ConfigurationLedger.replay([
        _householdEntry(1),
        _cashFlowCreatedEntry(2, _salary(300000), _salaryId),
        _entry(
          position: 3,
          eventIdentity: 3,
          businessDate: LocalDate(2026, 4, 8),
          target: _reference(EntityKind.cashFlow, _salaryId),
          payload: CashFlowReplacedPayload(
            definition: _salary(320000),
            effectiveFromCycleStart: replacementStart,
          ),
        ),
      ]);

      expect(
        ledger
            .cashFlowsForCycleStarting(_firstCycleStart)
            .single
            .referenceAmountPerOccurrence
            .minorUnits,
        300000,
      );
      expect(
        ledger
            .cashFlowsForCycleStarting(replacementStart)
            .single
            .referenceAmountPerOccurrence
            .minorUnits,
        320000,
      );
      expect(ledger.cashFlows[_salaryId]!.revisions, hasLength(2));
    });

    test('applies a tombstone only from its future cycle', () {
      final deletionStart = _firstCycleStart.addDays(14);
      final ledger = ConfigurationLedger.replay([
        _householdEntry(1),
        _cashFlowCreatedEntry(2, _salary(300000), _salaryId),
        _entry(
          position: 3,
          eventIdentity: 3,
          businessDate: LocalDate(2026, 4, 15),
          target: _reference(EntityKind.cashFlow, _salaryId),
          payload: CashFlowDeletedPayload(
            effectiveFromCycleStart: deletionStart,
          ),
        ),
      ]);

      expect(
        ledger.cashFlowsForCycleStarting(deletionStart.addDays(-7)),
        hasLength(1),
      );
      expect(ledger.cashFlowsForCycleStarting(deletionStart), isEmpty);
      expect(ledger.cashFlows[_salaryId]!.latestRevision.isDeletion, isTrue);
    });

    test('retains a versioned future cycle-policy change', () {
      final nextPolicy = CyclePolicy(
        version: 2,
        effectiveFrom: LocalDate(2026, 4, 8),
        anchorWeekday: Weekday.monday,
        timeZone: IanaTimeZoneId('Europe/Paris'),
      );
      final ledger = ConfigurationLedger.replay([
        _householdEntry(1),
        _entry(
          position: 2,
          eventIdentity: 2,
          businessDate: LocalDate(2026, 4, 8),
          target: _reference(EntityKind.household, _householdId),
          payload: HouseholdCyclePolicyChangedPayload(nextPolicy: nextPolicy),
        ),
      ]);

      expect(ledger.household!.cyclePolicies, hasLength(2));
      expect(
        ledger.household!.policyForCycleStarting(LocalDate(2026, 4, 11)),
        _initialPolicy,
      );
      expect(
        ledger.household!.policyForCycleStarting(LocalDate(2026, 4, 13)),
        nextPolicy,
      );

      final cycles = ledger.household!.cyclesFromDate(
        LocalDate(2026, 4, 12),
        count: 3,
      );
      expect(cycles.map((cycle) => cycle.start), [
        LocalDate(2026, 4, 4),
        LocalDate(2026, 4, 13),
        LocalDate(2026, 4, 20),
      ]);
      expect(cycles.map((cycle) => cycle.dateCount), [9, 7, 7]);
      expect(cycles.first.kind, WeeklyCycleKind.transition);
      expect(cycles[1].policy, nextPolicy);
    });

    test('changes time zone on a normal boundary without a transition', () {
      final nextPolicy = CyclePolicy(
        version: 2,
        effectiveFrom: LocalDate(2026, 4, 15),
        anchorWeekday: Weekday.saturday,
        timeZone: IanaTimeZoneId('America/Montreal'),
      );
      final ledger = ConfigurationLedger.replay([
        _householdEntry(1),
        _entry(
          position: 2,
          eventIdentity: 2,
          businessDate: LocalDate(2026, 4, 15),
          target: _reference(EntityKind.household, _householdId),
          payload: HouseholdCyclePolicyChangedPayload(nextPolicy: nextPolicy),
        ),
      ]);

      final before = ledger.household!.cycleContaining(LocalDate(2026, 4, 17));
      final after = ledger.household!.cycleContaining(LocalDate(2026, 4, 18));

      expect(before.start, LocalDate(2026, 4, 11));
      expect(before.policy, _initialPolicy);
      expect(after.start, LocalDate(2026, 4, 18));
      expect(after.kind, WeeklyCycleKind.normal);
      expect(after.policy, nextPolicy);
    });

    test('is idempotent by event UUID', () {
      final entry = _householdEntry(1);
      final once = ConfigurationLedger.empty().apply(entry);
      final twice = once.apply(entry);

      expect(twice, same(once));
    });

    test('ignores expense facts while preserving global journal order', () {
      final expense = _expenseEntry(2);
      final ledger = ConfigurationLedger.replay([
        _householdEntry(1),
        expense,
        _cashFlowCreatedEntry(3, _salary(300000), _salaryId),
      ]);
      final expenseLedger = ExpenseLedger.replay([
        _householdEntry(1),
        expense,
        _cashFlowCreatedEntry(3, _salary(300000), _salaryId),
      ]);

      expect(ledger.cashFlows, hasLength(1));
      expect(ledger.lastPosition, LocalJournalPosition(3));
      expect(expenseLedger.expenses, hasLength(1));
      expect(expenseLedger.lastPosition, LocalJournalPosition(3));
    });
  });

  group('ConfigurationLedger invariant failures', () {
    test('requires household creation before dependent configuration', () {
      expect(
        () => ConfigurationLedger.empty().apply(
          _cashFlowCreatedEntry(1, _salary(300000), _salaryId),
        ),
        throwsA(isA<ProjectionConflictException>()),
      );
      expect(
        () => ConfigurationLedger.empty().apply(_commitmentsEntry(1)),
        throwsA(isA<ProjectionConflictException>()),
      );
    });

    test('rejects replacements before creation and after deletion', () {
      final replacement = _entry(
        position: 2,
        eventIdentity: 2,
        businessDate: LocalDate(2026, 4, 8),
        target: _reference(EntityKind.cashFlow, _salaryId),
        payload: CashFlowReplacedPayload(
          definition: _salary(320000),
          effectiveFromCycleStart: _firstCycleStart.addDays(7),
        ),
      );
      expect(
        () => ConfigurationLedger.replay([_householdEntry(1), replacement]),
        throwsA(isA<ProjectionConflictException>()),
      );

      final deleted = ConfigurationLedger.replay([
        _householdEntry(1),
        _cashFlowCreatedEntry(2, _salary(300000), _salaryId),
        _entry(
          position: 3,
          eventIdentity: 3,
          businessDate: LocalDate(2026, 4, 8),
          target: _reference(EntityKind.cashFlow, _salaryId),
          payload: CashFlowDeletedPayload(
            effectiveFromCycleStart: _firstCycleStart.addDays(7),
          ),
        ),
      ]);
      expect(
        () => deleted.apply(
          _entry(
            position: 4,
            eventIdentity: 4,
            businessDate: LocalDate(2026, 4, 9),
            target: _reference(EntityKind.cashFlow, _salaryId),
            payload: CashFlowReplacedPayload(
              definition: _salary(320000),
              effectiveFromCycleStart: _firstCycleStart.addDays(14),
            ),
          ),
        ),
        throwsA(isA<ProjectionConflictException>()),
      );
    });

    test('rejects retroactive or backwards changes', () {
      final configured = ConfigurationLedger.replay([
        _householdEntry(1),
        _cashFlowCreatedEntry(2, _salary(300000), _salaryId),
      ]);
      expect(
        () => configured.apply(
          _entry(
            position: 3,
            eventIdentity: 3,
            businessDate: LocalDate(2026, 4, 8),
            target: _reference(EntityKind.cashFlow, _salaryId),
            payload: CashFlowReplacedPayload(
              definition: _salary(320000),
              effectiveFromCycleStart: _firstCycleStart,
            ),
          ),
        ),
        throwsA(isA<ProjectionConflictException>()),
      );
    });

    test('requires configured cycle starts and the household currency', () {
      final household = ConfigurationLedger.empty().apply(_householdEntry(1));
      expect(
        () => household.apply(
          _entry(
            position: 2,
            eventIdentity: 2,
            businessDate: LocalDate(2026, 4, 1),
            target: _reference(EntityKind.cashFlow, _salaryId),
            payload: CashFlowCreatedPayload(
              definition: _salary(300000),
              effectiveFromCycleStart: LocalDate(2026, 4, 5),
            ),
          ),
        ),
        throwsA(isA<ProjectionConflictException>()),
      );
      expect(
        () => household.apply(
          _entry(
            position: 2,
            eventIdentity: 3,
            businessDate: LocalDate(2026, 4, 1),
            target: _reference(EntityKind.cashFlow, _salaryId),
            payload: CashFlowCreatedPayload(
              definition: CashFlowDefinition.fixed(
                title: 'USD income',
                direction: CashFlowDirection.income,
                schedule: CustomDateSchedule([LocalDate(2026, 4, 30)]),
                amountPerOccurrence: Money.fromMinorUnits(10000, Currency.usd),
              ),
              effectiveFromCycleStart: _firstCycleStart,
            ),
          ),
        ),
        throwsA(isA<CurrencyMismatchException>()),
      );
    });

    test('rejects multiple household or annual-plan identities', () {
      final configured = ConfigurationLedger.replay([
        _householdEntry(1),
        _commitmentsEntry(2),
      ]);
      expect(
        () => configured.apply(
          _entry(
            position: 3,
            eventIdentity: 3,
            businessDate: LocalDate(2026, 4, 1),
            target: _reference(EntityKind.household, _entityId(99)),
            payload: HouseholdCreatedPayload(
              householdKind: HouseholdKind.solo,
              currency: Currency.eur,
              initialCyclePolicy: _initialPolicy,
            ),
          ),
        ),
        throwsA(isA<ProjectionConflictException>()),
      );
      expect(
        () => configured.apply(
          _entry(
            position: 3,
            eventIdentity: 4,
            businessDate: LocalDate(2026, 4, 8),
            target: _reference(EntityKind.annualBudgetPlan, _entityId(98)),
            payload: AnnualCommitmentsSetPayload(
              effectiveFromCycleStart: _firstCycleStart.addDays(7),
              reserveContributions: _eur(0),
              projectContributions: _eur(0),
              safetyMargin: _eur(0),
            ),
          ),
        ),
        throwsA(isA<ProjectionConflictException>()),
      );
    });

    test('requires monotone global positions and a configured household', () {
      final configured = ConfigurationLedger.empty().apply(_householdEntry(2));
      expect(
        () => configured.apply(
          _cashFlowCreatedEntry(1, _salary(300000), _salaryId),
        ),
        throwsA(isA<LocalJournalOrderException>()),
      );
      expect(
        () => ConfigurationLedger.empty().buildAnnualBudget(_cycles()),
        throwsA(isA<IncompleteConfigurationException>()),
      );
    });
  });
}

final LocalDate _firstCycleStart = LocalDate(2026, 4, 4);
final CyclePolicy _initialPolicy = CyclePolicy(
  version: 1,
  effectiveFrom: _firstCycleStart,
  anchorWeekday: Weekday.saturday,
  timeZone: IanaTimeZoneId('Europe/Paris'),
);
final EntityId _householdId = _entityId(1);
final EntityId _planId = _entityId(2);
final EntityId _salaryId = _entityId(3);
final EntityId _rentId = _entityId(4);
final EntityId _expenseId = _entityId(5);

LocalJournalEntry _householdEntry(int position) {
  return _entry(
    position: position,
    eventIdentity: position,
    businessDate: LocalDate(2026, 4, 1),
    target: _reference(EntityKind.household, _householdId),
    payload: HouseholdCreatedPayload(
      householdKind: HouseholdKind.sharedMainAccount,
      currency: Currency.eur,
      initialCyclePolicy: _initialPolicy,
    ),
  );
}

LocalJournalEntry _commitmentsEntry(int position) {
  return _entry(
    position: position,
    eventIdentity: position,
    businessDate: LocalDate(2026, 4, 1),
    target: _reference(EntityKind.annualBudgetPlan, _planId),
    payload: AnnualCommitmentsSetPayload(
      effectiveFromCycleStart: _firstCycleStart,
      reserveContributions: _eur(120000),
      projectContributions: _eur(60000),
      safetyMargin: _eur(24000),
    ),
  );
}

LocalJournalEntry _cashFlowCreatedEntry(
  int position,
  CashFlowDefinition definition,
  EntityId id,
) {
  return _entry(
    position: position,
    eventIdentity: position,
    businessDate: LocalDate(2026, 4, 1),
    target: _reference(EntityKind.cashFlow, id),
    payload: CashFlowCreatedPayload(
      definition: definition,
      effectiveFromCycleStart: _firstCycleStart,
    ),
  );
}

LocalJournalEntry _expenseEntry(int position) {
  return _entry(
    position: position,
    eventIdentity: position,
    businessDate: LocalDate(2026, 4, 6),
    target: _reference(EntityKind.expense, _expenseId),
    payload: ExpenseRecordedPayload(
      amount: _eur(4250),
      label: 'Courses',
      cycleAssignment: ExpenseCycleAssignment(
        cycleStart: _firstCycleStart,
        policyVersion: 1,
        timeZone: IanaTimeZoneId('Europe/Paris'),
      ),
    ),
  );
}

LocalJournalEntry _entry({
  required int position,
  required int eventIdentity,
  required LocalDate businessDate,
  required EntityReference target,
  required EventPayload payload,
}) {
  return LocalJournalEntry(
    position: LocalJournalPosition(position),
    event: EventRecord(
      id: _eventId(eventIdentity),
      recordedAtUtc: DateTime.utc(2026, 4, 1, 10, 0, eventIdentity),
      businessDate: businessDate,
      target: target,
      payload: payload,
    ),
  );
}

EntityReference _reference(EntityKind kind, EntityId id) {
  return EntityReference(kind: kind, id: id);
}

List<WeeklyCycle> _cycles() {
  return CycleCalendar.normalCycles(
    firstStart: _firstCycleStart,
    count: 52,
    policy: _initialPolicy,
  );
}

CashFlowDefinition _salary(int minorUnits) {
  return _monthlyFlow(
    title: 'Salaire 1',
    direction: CashFlowDirection.income,
    amount: minorUnits,
  );
}

CashFlowDefinition _rent(int minorUnits) {
  return _monthlyFlow(
    title: 'Logement',
    direction: CashFlowDirection.outflow,
    amount: minorUnits,
  );
}

CashFlowDefinition _monthlyFlow({
  required String title,
  required CashFlowDirection direction,
  required int amount,
}) {
  return CashFlowDefinition.fixed(
    title: title,
    direction: direction,
    schedule: RecurringSchedule(
      firstOccurrence: LocalDate(2026, 4, 30),
      frequency: RecurrenceFrequency.monthly,
    ),
    amountPerOccurrence: _eur(amount),
    lastConfirmedOn: LocalDate(2026, 4, 1),
  );
}

Money _eur(int minorUnits) => Money.fromMinorUnits(minorUnits, Currency.eur);

EventId _eventId(int value) => EventId(
  '0193${value.toString().padLeft(4, '0')}-3333-7333-8333-333333333333',
);

EntityId _entityId(int value) => EntityId(
  '0194${value.toString().padLeft(4, '0')}-4444-7444-8444-444444444444',
);
