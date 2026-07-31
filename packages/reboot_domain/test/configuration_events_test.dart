import 'package:reboot_domain/reboot_domain.dart';
import 'package:test/test.dart';

void main() {
  group('household configuration events', () {
    test('establishes a EUR shared household and its initial policy', () {
      final payload = HouseholdCreatedPayload(
        householdKind: HouseholdKind.sharedMainAccount,
        currency: Currency.eur,
        initialCyclePolicy: _policy(),
      );

      expect(payload.eventType, 'household.created');
      expect(payload.schemaVersion, 1);
      expect(payload.targetKind, EntityKind.household);
      expect(payload.initialCyclePolicy.firstNormalCycleStart, _cycleStart);
    });

    test('rejects non-EUR and non-initial policy versions', () {
      expect(
        () => HouseholdCreatedPayload(
          householdKind: HouseholdKind.solo,
          currency: Currency.usd,
          initialCyclePolicy: _policy(),
        ),
        throwsArgumentError,
      );
      expect(
        () => HouseholdCreatedPayload(
          householdKind: HouseholdKind.solo,
          currency: Currency.eur,
          initialCyclePolicy: _policy(version: 2),
        ),
        throwsArgumentError,
      );
    });
  });

  group('cash-flow configuration events', () {
    test('uses complete replacement events and a future tombstone', () {
      final definition = _salary(300000);
      final created = CashFlowCreatedPayload(
        definition: definition,
        effectiveFromCycleStart: _cycleStart,
      );
      final replaced = CashFlowReplacedPayload(
        definition: _salary(310000),
        effectiveFromCycleStart: _cycleStart.addDays(7),
      );
      final deleted = CashFlowDeletedPayload(
        effectiveFromCycleStart: _cycleStart.addDays(14),
      );

      expect(created.eventType, 'cash-flow.created');
      expect(replaced.eventType, 'cash-flow.replaced');
      expect(deleted.eventType, 'cash-flow.deleted');
      expect(created.targetKind, EntityKind.cashFlow);
      expect(created.definition, same(definition));
    });

    test('cannot be attached to a different entity family', () {
      expect(
        () => EventRecord(
          id: _eventId(1),
          recordedAtUtc: DateTime.utc(2026, 4, 1),
          businessDate: LocalDate(2026, 4, 1),
          target: EntityReference(kind: EntityKind.expense, id: _entityId(1)),
          payload: CashFlowCreatedPayload(
            definition: _salary(300000),
            effectiveFromCycleStart: _cycleStart,
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  group('received-bonus configuration events', () {
    test('stores only money already received and its renewal date', () {
      final pool = ReceivedBonusPool(
        title: 'Prime annuelle',
        remainingForDailyLife: _eur(500000),
        nextPaymentDate: LocalDate(2027, 1, 15),
      );
      final created = ReceivedBonusCreatedPayload(
        pool: pool,
        effectiveFromCycleStart: _cycleStart,
      );
      final replaced = ReceivedBonusReplacedPayload(
        pool: pool,
        effectiveFromCycleStart: _cycleStart.addDays(7),
      );
      final deleted = ReceivedBonusDeletedPayload(
        effectiveFromCycleStart: _cycleStart.addDays(14),
      );

      expect(created.eventType, 'received-bonus.created');
      expect(replaced.eventType, 'received-bonus.replaced');
      expect(deleted.eventType, 'received-bonus.deleted');
      expect(created.targetKind, EntityKind.receivedBonus);
      expect(created.pool, same(pool));
    });
  });

  group('AnnualCommitmentsSetPayload', () {
    test('keeps reserves, projects, and safety separate', () {
      final payload = AnnualCommitmentsSetPayload(
        effectiveFromCycleStart: _cycleStart,
        reserveContributions: _eur(120000),
        projectContributions: _eur(60000),
        safetyMargin: _eur(24000),
      );

      expect(payload.eventType, 'annual-commitments.set');
      expect(payload.targetKind, EntityKind.annualBudgetPlan);
      expect(payload.reserveContributions.minorUnits, 120000);
      expect(payload.projectContributions.minorUnits, 60000);
      expect(payload.safetyMargin.minorUnits, 24000);
    });

    test('rejects negative amounts and other currencies', () {
      expect(
        () => AnnualCommitmentsSetPayload(
          effectiveFromCycleStart: _cycleStart,
          reserveContributions: _eur(-1),
          projectContributions: _eur(0),
          safetyMargin: _eur(0),
        ),
        throwsArgumentError,
      );
      expect(
        () => AnnualCommitmentsSetPayload(
          effectiveFromCycleStart: _cycleStart,
          reserveContributions: Money.zero(Currency.usd),
          projectContributions: _eur(0),
          safetyMargin: _eur(0),
        ),
        throwsArgumentError,
      );
    });
  });

  group('TrajectoryPlanSetPayload', () {
    test('keeps the overdraft recovery goal explicit', () {
      final payload = TrajectoryPlanSetPayload(
        effectiveFromCycleStart: _cycleStart,
        strategy: TrajectoryStrategy.overdraftExit,
        reserveContributions: _eur(120000),
        projectContributions: _eur(60000),
        safetyMargin: _eur(24000),
        overdraftExitGoal: OverdraftExitGoal(
          currentOverdraftDepth: _eur(100000),
          targetCushion: _eur(50000),
          targetDate: LocalDate(2026, 10, 1),
        ),
      );

      expect(payload.eventType, 'trajectory-plan.set');
      expect(payload.strategy, TrajectoryStrategy.overdraftExit);
      expect(payload.overdraftExitGoal!.totalToRecover, _eur(150000));
    });

    test('requires a goal only for overdraft exit', () {
      expect(
        () => TrajectoryPlanSetPayload(
          effectiveFromCycleStart: _cycleStart,
          strategy: TrajectoryStrategy.overdraftExit,
          reserveContributions: _eur(0),
          projectContributions: _eur(0),
          safetyMargin: _eur(0),
        ),
        throwsArgumentError,
      );
      expect(
        () => TrajectoryPlanSetPayload(
          effectiveFromCycleStart: _cycleStart,
          strategy: TrajectoryStrategy.balance,
          reserveContributions: _eur(0),
          projectContributions: _eur(0),
          safetyMargin: _eur(0),
          overdraftExitGoal: OverdraftExitGoal(
            currentOverdraftDepth: _eur(100),
            targetCushion: _eur(0),
            targetDate: LocalDate(2026, 10, 1),
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}

final LocalDate _cycleStart = LocalDate(2026, 4, 4);

CyclePolicy _policy({int version = 1}) {
  return CyclePolicy(
    version: version,
    effectiveFrom: _cycleStart,
    anchorWeekday: Weekday.saturday,
    timeZone: IanaTimeZoneId('Europe/Paris'),
  );
}

CashFlowDefinition _salary(int minorUnits) {
  return CashFlowDefinition.fixed(
    title: 'Salaire 1',
    direction: CashFlowDirection.income,
    schedule: RecurringSchedule(
      firstOccurrence: LocalDate(2026, 4, 30),
      frequency: RecurrenceFrequency.monthly,
    ),
    amountPerOccurrence: _eur(minorUnits),
    lastConfirmedOn: LocalDate(2026, 4, 1),
  );
}

Money _eur(int minorUnits) => Money.fromMinorUnits(minorUnits, Currency.eur);

EventId _eventId(int value) => EventId(
  '0191${value.toString().padLeft(4, '0')}-1111-7111-8111-111111111111',
);

EntityId _entityId(int value) => EntityId(
  '0192${value.toString().padLeft(4, '0')}-2222-7222-8222-222222222222',
);
