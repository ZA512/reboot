import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_serialization/reboot_serialization.dart';
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

    test('stores exact money as a canonical decimal string', () {
      final codec = EventPayloadJsonCodec();
      final payload = ExpenseRecordedPayload(
        amount: Money.fromMinorUnitsDecimal('9007199254740993', Currency.eur),
        label: 'Test de précision',
        cycleAssignment: ExpenseCycleAssignment(
          cycleStart: LocalDate(2026, 4, 4),
          policyVersion: 1,
          timeZone: IanaTimeZoneId('Europe/Paris'),
        ),
      );

      final encoded = codec.encode(payload);
      expect(encoded, contains('"minorUnits":"9007199254740993"'));

      final decoded =
          codec.decode(
                eventType: payload.eventType,
                schemaVersion: payload.schemaVersion,
                json: encoded,
              )
              as ExpenseRecordedPayload;
      expect(decoded.amount, payload.amount);
    });

    test('continues to decode legacy numeric money fields', () {
      final codec = EventPayloadJsonCodec();
      final decoded =
          codec.decode(
                eventType: 'expense.recorded',
                schemaVersion: 1,
                json: '''
{"amount":{"minorUnits":4250,"currency":"EUR"},"label":"Courses","cycleAssignment":{"cycleStart":"2026-04-04","policyVersion":1,"timeZone":"Europe/Paris"}}
''',
              )
              as ExpenseRecordedPayload;

      expect(decoded.amount, Money.fromMinorUnits(4250, Currency.eur));
    });

    test('rejects unsafe legacy JSON numbers instead of rounding them', () {
      final codec = EventPayloadJsonCodec();

      expect(
        () => codec.decode(
          eventType: 'expense.recorded',
          schemaVersion: 1,
          json: '''
{"amount":{"minorUnits":9007199254740993,"currency":"EUR"},"label":"Courses","cycleAssignment":{"cycleStart":"2026-04-04","policyVersion":1,"timeZone":"Europe/Paris"}}
''',
        ),
        throwsFormatException,
      );
    });

    test('rejects non-canonical portable integer strings', () {
      final codec = EventPayloadJsonCodec();

      expect(
        () => codec.decode(
          eventType: 'expense.recorded',
          schemaVersion: 1,
          json: '''
{"amount":{"minorUnits":"004250","currency":"EUR"},"label":"Courses","cycleAssignment":{"cycleStart":"2026-04-04","policyVersion":1,"timeZone":"Europe/Paris"}}
''',
        ),
        throwsFormatException,
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
    ReceivedBonusCreatedPayload(
      pool: ReceivedBonusPool(
        title: 'Prime annuelle',
        remainingForDailyLife: _eur(500000),
        nextPaymentDate: LocalDate(2027, 1, 15),
      ),
      effectiveFromCycleStart: LocalDate(2026, 4, 4),
    ),
    ReceivedBonusReplacedPayload(
      pool: ReceivedBonusPool(
        title: 'Prime annuelle',
        remainingForDailyLife: _eur(450000),
        nextPaymentDate: LocalDate(2027, 7, 15),
      ),
      effectiveFromCycleStart: LocalDate(2027, 1, 16),
    ),
    ReceivedBonusDeletedPayload(
      effectiveFromCycleStart: LocalDate(2027, 7, 17),
    ),
    AnnualCommitmentsSetPayload(
      effectiveFromCycleStart: LocalDate(2026, 4, 4),
      reserveContributions: _eur(120000),
      projectContributions: _eur(60000),
      safetyMargin: _eur(24000),
    ),
    TrajectoryPlanSetPayload(
      effectiveFromCycleStart: LocalDate(2026, 4, 4),
      strategy: TrajectoryStrategy.overdraftExit,
      reserveContributions: _eur(120000),
      projectContributions: _eur(60000),
      safetyMargin: _eur(24000),
      overdraftExitGoal: OverdraftExitGoal(
        currentOverdraftDepth: _eur(100000),
        targetCushion: _eur(50000),
        targetDate: LocalDate(2026, 10, 1),
      ),
    ),
    LiquiditySnapshotCreatedPayload(
      snapshot: LiquiditySnapshot(
        capturedAtUtc: DateTime.utc(2026, 4, 1, 8, 30),
        bookedBalance: _eur(-150000),
        pendingCardAmount: _eur(12000),
        deferredCardAmount: _eur(8000),
        outstandingCheques: _eur(5000),
        committedTransfers: _eur(3000),
        protectedVirtualAllocations: _eur(20000),
        source: LiquiditySnapshotSource.manual,
        confidence: StartupDataConfidence.high,
      ),
    ),
    HouseholdNeedsProfileCreatedPayload(
      profile: HouseholdNeedsProfile(
        fullTimePersons14OrOlder: 2,
        fullTimeChildrenUnder14: 2,
        partialPresences: [
          PartialHouseholdPresence(
            ageBand: HouseholdNeedAgeBand.under14,
            presencePermille: 500,
          ),
        ],
        weeklyBudgetScope: const {
          WeeklyBudgetCategory.groceries,
          WeeklyBudgetCategory.hygiene,
        },
        minimumViableWeeklyBudget: _eur(9000),
      ),
    ),
    CashCushionPolicyCreatedPayload(
      targetBalance: _eur(0),
      technicalCushion: _eur(40000),
      uncertaintyMargin: _eur(10000),
      ownedCash: _eur(30000),
      authorizedOverdraft: _eur(150000),
      overdraftFundedCash: _eur(20000),
    ),
    LaunchAssessmentCreatedPayload(
      sustainableWeeklyBudget: _eur(12000),
      minimumViableWeeklyBudget: _eur(9000),
      projectedLowPoint: _eur(-190000),
      projectedLowPointDate: LocalDate(2026, 5, 2),
      decisionState: LaunchDecisionState.readyWithLaunchBudget,
      confidence: StartupDataConfidence.high,
    ),
    LaunchPlanAcceptedPayload(
      startDate: LocalDate(2026, 4, 4),
      launchWeeklyBudget: _eur(9000),
      sustainableWeeklyBudget: _eur(12000),
      durationCycles: 26,
      estimatedCompletionDate: LocalDate(2026, 10, 3),
      expectedLowPoint: _eur(-150000),
      decisionState: LaunchDecisionState.readyWithLaunchBudget,
      viabilityAnswer: StartupViabilityAnswer.tight,
      acceptedBankFundingRisk: true,
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
    const ExpenseNatureSetPayload(nature: ExpenseNature.necessary),
    const ExpenseDeletedPayload(),
    ExpenseRefundedPayload(
      amount: _eur(2000),
      receiptCycleStart: LocalDate(2026, 4, 11),
    ),
    ExpenseRefundReversedPayload(
      refundEventId: EventId('018f2b8a-7d3c-7a1b-8c4d-1234567890ab'),
    ),
    ReserveCreatedPayload(
      name: 'Imprévus',
      kind: ReserveKind.real,
      openingBalance: _eur(50000),
    ),
    ReserveFundsAddedPayload(amount: _eur(12000), label: 'Surplus'),
    ReserveExpenseRecordedPayload(amount: _eur(8000), label: 'Vétérinaire'),
    ReserveMovementReversedPayload(
      movementEventId: EventId('018f2b8a-7d3c-7a1b-8c4d-1234567890ab'),
    ),
    HealthTrackingConfiguredPayload(
      enabled: true,
      delayWeeks: 4,
      alertThreshold: _eur(5000),
    ),
    HealthExpenseRecordedPayload(amount: _eur(9000), label: 'Médecin'),
    HealthReimbursementRecordedPayload(
      amount: _eur(6000),
      label: 'Remboursements',
    ),
    HealthRegularizationRecordedPayload(amount: _eur(3000), label: 'Compensé'),
    HealthEntryReversedPayload(
      entryEventId: EventId('018f2b8a-7d3c-7a1b-8c4d-1234567890ab'),
    ),
    const CashHandlingMethodSetPayload(method: CashWithdrawalMethod.cashWallet),
    CashWalletTransferRecordedPayload(
      amount: _eur(5000),
      label: 'Retrait espèces',
    ),
    CashWalletTransferReversedPayload(
      transferEventId: EventId('018f2b8a-7d3c-7a1b-8c4d-1234567890ab'),
    ),
  ];
}

Money _eur(int minorUnits) => Money.fromMinorUnits(minorUnits, Currency.eur);
