import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';
import 'package:test/test.dart';

void main() {
  group('AnnualizationEngine', () {
    test('counts actual occurrences inside the rolling 52 cycles', () {
      final projection = _project([
        _fixed(
          title: 'Salaire',
          direction: CashFlowDirection.income,
          amount: 400000,
          first: LocalDate(2026, 1, 31),
          frequency: RecurrenceFrequency.monthly,
        ),
        _fixed(
          title: 'Ramonage',
          direction: CashFlowDirection.outflow,
          amount: 9000,
          first: LocalDate(2026, 12, 31),
          frequency: RecurrenceFrequency.annual,
        ),
      ]);

      expect(projection.cashFlows[0].occurrences, hasLength(12));
      expect(projection.cashFlows[0].total.minorUnits, 4800000);
      expect(projection.cashFlows[1].occurrences, [LocalDate(2026, 12, 31)]);
      expect(projection.cashFlows[1].total.minorUnits, 9000);
    });

    test('applies prudent income down and prudent outflow up', () {
      final monthly = RecurringSchedule(
        firstOccurrence: LocalDate(2026, 1, 31),
        frequency: RecurrenceFrequency.monthly,
      );
      final projection = _project([
        CashFlowDefinition.variable(
          title: 'Revenu variable',
          direction: CashFlowDirection.income,
          schedule: monthly,
          historicalAveragePerOccurrence: _eur(10001),
          strategy: VariableEstimateStrategy.prudent,
        ),
        CashFlowDefinition.variable(
          title: 'Essence',
          direction: CashFlowDirection.outflow,
          schedule: monthly,
          historicalAveragePerOccurrence: _eur(10001),
          strategy: VariableEstimateStrategy.prudent,
        ),
      ]);

      expect(projection.cashFlows[0].total.minorUnits, 108010);
      expect(projection.cashFlows[1].total.minorUnits, 132014);
    });

    test('uses the user amount for a custom variable estimate', () {
      final projection = _project([
        CashFlowDefinition.variable(
          title: 'Allocation',
          direction: CashFlowDirection.income,
          schedule: RecurringSchedule(
            firstOccurrence: LocalDate(2026, 1, 31),
            frequency: RecurrenceFrequency.monthly,
          ),
          historicalAveragePerOccurrence: _eur(10000),
          strategy: VariableEstimateStrategy.custom,
          customAmountPerOccurrence: _eur(9000),
        ),
      ]);

      expect(projection.totalIncome.minorUnits, 108000);
    });

    test('deducts reserves, projects, and safety before recommendation', () {
      final cycles = _cycles();
      final projection = AnnualizationEngine.project(
        cycles: cycles,
        cashFlows: [
          CashFlowDefinition.fixed(
            title: 'Capacité disponible',
            direction: CashFlowDirection.income,
            schedule: CustomDateSchedule([cycles.first.start]),
            amountPerOccurrence: _eur(1305864),
          ),
        ],
        deductions: AnnualBudgetDeductions(
          currency: Currency.eur,
          reserveContributions: _eur(50000),
          projectContributions: _eur(30000),
          safetyMargin: _eur(20000),
        ),
      );

      expect(projection.steerableCapacity.minorUnits, 1205864);
      expect(projection.grossWeeklyCapacity.minorUnits, 23189);
      expect(projection.recommendedWeeklyBudget.minorUnits, 23100);
      expect(projection.unallocatedAnnualMargin.minorUnits, 4664);
      expect(projection.deficit.isZero, isTrue);
    });

    test('reduces the current budget to meet an overdraft target', () {
      final cycles = _cycles();
      final projection = AnnualizationEngine.project(
        cycles: cycles,
        cashFlows: [
          CashFlowDefinition.fixed(
            title: 'Annual capacity',
            direction: CashFlowDirection.income,
            schedule: CustomDateSchedule([cycles.first.start]),
            amountPerOccurrence: _eur(1040000),
          ),
        ],
        deductions: AnnualBudgetDeductions(currency: Currency.eur),
        overdraftExitGoal: OverdraftExitGoal(
          currentOverdraftDepth: _eur(100000),
          targetCushion: _eur(50000),
          targetDate: LocalDate(2026, 7, 4),
        ),
      );

      expect(projection.overdraftRecovery!.cycleCount, 26);
      expect(projection.overdraftRecovery!.requiredPerCycle.minorUnits, 5770);
      expect(projection.overdraftRecovery!.isFeasible, isTrue);
      expect(projection.grossWeeklyCapacity.minorUnits, 14230);
      expect(projection.recommendedWeeklyBudget.minorUnits, 14200);
    });

    test(
      'exposes an impossible overdraft target without a negative budget',
      () {
        final cycles = _cycles();
        final projection = AnnualizationEngine.project(
          cycles: cycles,
          cashFlows: [
            CashFlowDefinition.fixed(
              title: 'Annual capacity',
              direction: CashFlowDirection.income,
              schedule: CustomDateSchedule([cycles.first.start]),
              amountPerOccurrence: _eur(260000),
            ),
          ],
          deductions: AnnualBudgetDeductions(currency: Currency.eur),
          overdraftExitGoal: OverdraftExitGoal(
            currentOverdraftDepth: _eur(100000),
            targetCushion: _eur(50000),
            targetDate: LocalDate(2026, 7, 4),
          ),
        );

        expect(projection.recommendedWeeklyBudget.isZero, isTrue);
        expect(projection.overdraftRecovery!.shortfallPerCycle.minorUnits, 770);
        expect(projection.overdraftRecovery!.isFeasible, isFalse);
      },
    );

    test('shows zero budget and an explicit deficit for negative capacity', () {
      final projection = _project([
        CashFlowDefinition.fixed(
          title: 'Revenu',
          direction: CashFlowDirection.income,
          schedule: CustomDateSchedule([LocalDate(2026, 1, 3)]),
          amountPerOccurrence: _eur(10000),
        ),
        CashFlowDefinition.fixed(
          title: 'Charge',
          direction: CashFlowDirection.outflow,
          schedule: CustomDateSchedule([LocalDate(2026, 1, 3)]),
          amountPerOccurrence: _eur(15000),
        ),
      ]);

      expect(projection.steerableCapacity.minorUnits, -5000);
      expect(projection.grossWeeklyCapacity.isZero, isTrue);
      expect(projection.recommendedWeeklyBudget.isZero, isTrue);
      expect(projection.deficit.minorUnits, 5000);
    });

    test('rejects a horizon other than 52 contiguous cycles', () {
      expect(
        () => AnnualizationEngine.project(
          cycles: _cycles().take(51).toList(),
          cashFlows: const [],
          deductions: AnnualBudgetDeductions(currency: Currency.eur),
        ),
        throwsArgumentError,
      );
    });

    test('rejects an implicit currency conversion', () {
      final usdFlow = CashFlowDefinition.fixed(
        title: 'USD',
        direction: CashFlowDirection.income,
        schedule: CustomDateSchedule([LocalDate(2026, 1, 3)]),
        amountPerOccurrence: Money.fromMinorUnits(10000, Currency.usd),
      );

      expect(
        () => _project([usdFlow]),
        throwsA(isA<CurrencyMismatchException>()),
      );
    });
  });

  group('ReceivedBonusAllocator', () {
    test('spreads only the existing pool until the next payment date', () {
      final cycles = _cycles(count: 53);
      final allocation = ReceivedBonusAllocator.allocate(
        pool: ReceivedBonusPool(
          title: 'Prime annuelle restante',
          remainingForDailyLife: _eur(1000000),
          nextPaymentDate: LocalDate(2027, 1, 3),
        ),
        cyclesCoveringPaymentDate: cycles,
      );

      expect(allocation.cycles, hasLength(53));
      expect(
        allocation.amounts.take(52).map((amount) => amount.minorUnits),
        everyElement(18867),
      );
      expect(allocation.amounts.last.minorUnits, 18916);
      expect(
        allocation.amounts.fold<int>(
          0,
          (sum, amount) => sum + amount.minorUnits,
        ),
        1000000,
      );
      expect(allocation.amountFor(LocalDate(2027, 1, 9)).isZero, isTrue);
    });

    test('requires enough cycles to avoid consuming a pool too early', () {
      expect(
        () => ReceivedBonusAllocator.allocate(
          pool: ReceivedBonusPool(
            title: 'Prime annuelle restante',
            remainingForDailyLife: _eur(1000000),
            nextPaymentDate: LocalDate(2027, 1, 3),
          ),
          cyclesCoveringPaymentDate: _cycles(),
        ),
        throwsArgumentError,
      );
    });

    test('requires confirmation when the renewal date has arrived', () {
      expect(
        () => ReceivedBonusAllocator.allocate(
          pool: ReceivedBonusPool(
            title: 'Prime',
            remainingForDailyLife: _eur(500000),
            nextPaymentDate: LocalDate(2026, 1, 3),
          ),
          cyclesCoveringPaymentDate: _cycles(),
        ),
        throwsStateError,
      );
    });
  });
}

AnnualBudgetProjection _project(List<CashFlowDefinition> cashFlows) {
  return AnnualizationEngine.project(
    cycles: _cycles(),
    cashFlows: cashFlows,
    deductions: AnnualBudgetDeductions(currency: Currency.eur),
  );
}

CashFlowDefinition _fixed({
  required String title,
  required CashFlowDirection direction,
  required int amount,
  required LocalDate first,
  required RecurrenceFrequency frequency,
}) {
  return CashFlowDefinition.fixed(
    title: title,
    direction: direction,
    schedule: RecurringSchedule(firstOccurrence: first, frequency: frequency),
    amountPerOccurrence: _eur(amount),
  );
}

List<WeeklyCycle> _cycles({int count = 52}) {
  final policy = CyclePolicy(
    version: 1,
    effectiveFrom: LocalDate(2026, 1, 3),
    anchorWeekday: Weekday.saturday,
    timeZone: IanaTimeZoneId('Europe/Paris'),
  );
  return CycleCalendar.normalCycles(
    firstStart: LocalDate(2026, 1, 3),
    count: count,
    policy: policy,
  );
}

Money _eur(int minorUnits) => Money.fromMinorUnits(minorUnits, Currency.eur);
