import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_storage/src/event_codec.dart';
import 'package:test/test.dart';

void main() {
  group('EventPayloadJsonCodec', () {
    test('round-trips every version 1 payload canonically', () {
      final codec = EventPayloadJsonCodec();

      for (final payload in _allPayloads()) {
        final encoded = codec.encode(payload);
        final decoded = codec.decode(
          eventType: payload.eventType,
          schemaVersion: payload.schemaVersion,
          json: encoded,
        );

        expect(decoded.eventType, payload.eventType);
        expect(decoded.schemaVersion, payload.schemaVersion);
        expect(decoded.targetKind, payload.targetKind);
        expect(codec.encode(decoded), encoded, reason: payload.eventType);
      }
    });

    test('rejects unknown event types and future schema versions', () {
      final codec = EventPayloadJsonCodec();

      expect(
        () => codec.decode(
          eventType: 'future.event',
          schemaVersion: 1,
          json: '{}',
        ),
        throwsA(isA<UnsupportedStoredEventException>()),
      );
      expect(
        () => codec.decode(
          eventType: 'expense.deleted',
          schemaVersion: 2,
          json: '{}',
        ),
        throwsA(isA<UnsupportedStoredEventException>()),
      );
    });
  });
}

List<EventPayload> _allPayloads() {
  final policy = CyclePolicy(
    version: 1,
    effectiveFrom: LocalDate(2026, 4, 4),
    anchorWeekday: Weekday.saturday,
    timeZone: IanaTimeZoneId('Europe/Paris'),
  );
  final fixed = CashFlowDefinition.fixed(
    title: 'Salaire 1',
    direction: CashFlowDirection.income,
    schedule: RecurringSchedule(
      firstOccurrence: LocalDate(2026, 4, 30),
      frequency: RecurrenceFrequency.monthly,
      lastOccurrence: LocalDate(2027, 3, 31),
    ),
    amountPerOccurrence: _eur(300000),
    lastConfirmedOn: LocalDate(2026, 4, 1),
  );
  final variable = CashFlowDefinition.variable(
    title: 'Essence',
    direction: CashFlowDirection.outflow,
    schedule: CustomDateSchedule([
      LocalDate(2026, 4, 15),
      LocalDate(2026, 5, 15),
    ]),
    historicalAveragePerOccurrence: _eur(8000),
    strategy: VariableEstimateStrategy.custom,
    customAmountPerOccurrence: _eur(9000),
    lastConfirmedOn: LocalDate(2026, 4, 1),
  );
  return [
    HouseholdCreatedPayload(
      householdKind: HouseholdKind.sharedMainAccount,
      currency: Currency.eur,
      initialCyclePolicy: policy,
    ),
    HouseholdCyclePolicyChangedPayload(
      nextPolicy: CyclePolicy(
        version: 2,
        effectiveFrom: LocalDate(2026, 5, 1),
        anchorWeekday: Weekday.monday,
        timeZone: IanaTimeZoneId('Europe/Paris'),
      ),
    ),
    CashFlowCreatedPayload(
      definition: fixed,
      effectiveFromCycleStart: LocalDate(2026, 4, 4),
    ),
    CashFlowReplacedPayload(
      definition: variable,
      effectiveFromCycleStart: LocalDate(2026, 4, 11),
    ),
    CashFlowDeletedPayload(effectiveFromCycleStart: LocalDate(2026, 4, 18)),
    AnnualCommitmentsSetPayload(
      effectiveFromCycleStart: LocalDate(2026, 4, 4),
      reserveContributions: _eur(120000),
      projectContributions: _eur(60000),
      safetyMargin: _eur(24000),
    ),
    ExpenseRecordedPayload(
      amount: _eur(4250),
      label: 'Courses',
      cycleAssignment: ExpenseCycleAssignment(
        cycleStart: LocalDate(2026, 4, 4),
        policyVersion: 1,
        timeZone: IanaTimeZoneId('Europe/Paris'),
      ),
    ),
    ExpenseAllocationsPlannedPayload.evenly(
      expenseAmount: _eur(4250),
      cycleStarts: [LocalDate(2026, 4, 4), LocalDate(2026, 4, 11)],
    ),
    const ExpenseDeletedPayload(),
  ];
}

Money _eur(int minorUnits) => Money.fromMinorUnits(minorUnits, Currency.eur);
