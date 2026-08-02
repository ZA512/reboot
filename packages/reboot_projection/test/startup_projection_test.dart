import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';
import 'package:test/test.dart';

void main() {
  group('StartupCashProjectionEngine', () {
    test('finds timing amplitude independently from a -1500 EUR balance', () {
      final projection = _delayedAnnualIncomeProjection(_eur(-150000));

      expect(projection.minimumCumulativeVariation, _eur(-50000));
      expect(projection.technicalCashCushion, _eur(50000));
      expect(projection.projectedLowPoint, _eur(-200000));
      expect(projection.projectedLowPointDate, LocalDate(2026, 8, 29));
      expect(projection.points, hasLength(364));
      expect(projection.points.last.closingBalance, _eur(-150000));
    });

    test('can produce a zero technical cushion', () {
      final cycles = _cycles();
      final movements = [
        for (final cycle in cycles)
          StartupCashMovement(
            date: cycle.start,
            amount: _eur(10000),
            kind: StartupCashMovementKind.guaranteedIncome,
          ),
      ];

      final projection = StartupCashProjectionEngine.project(
        cycles: cycles,
        initialUsableCash: _eur(0),
        movements: movements,
        weeklyBudgetsByCycleStart: {
          for (final cycle in cycles) cycle.start: _eur(10000),
        },
      );

      expect(projection.technicalCashCushion, _eur(0));
      expect(projection.projectedLowPoint, _eur(0));
    });

    test('commits the complete weekly amount on the first cycle date', () {
      final projection = _delayedAnnualIncomeProjection(_eur(0));

      expect(projection.points.first.weeklyBudgetCommitment, _eur(10000));
      expect(projection.points.first.closingBalance, _eur(-10000));
      expect(projection.points[1].weeklyBudgetCommitment, _eur(0));
    });
  });

  group('cash cushion funding', () {
    test('own cash reaches zero without using the bank', () {
      final projection = _delayedAnnualIncomeProjection(_eur(-150000));
      final assessment = StartupLiquidityAssessment(
        projection: projection,
        uncertaintyMargin: _eur(0),
        funding: CashCushionFunding(
          targetBalance: _eur(0),
          ownedCash: _eur(50000),
          authorizedOverdraft: _eur(150000),
          overdraftFundedCash: _eur(0),
        ),
      );

      expect(assessment.funding.operatingBalance, _eur(50000));
      expect(assessment.funding.lowestAllowedBalance, _eur(0));
      expect(assessment.requiredProgress, _eur(200000));
      expect(assessment.protectedProjectedLowPoint, _eur(0));
      expect(assessment.marginIsProtected, isTrue);
    });

    test('bank funding keeps the objective at zero but permits a dip', () {
      final projection = _delayedAnnualIncomeProjection(_eur(-150000));
      final assessment = StartupLiquidityAssessment(
        projection: projection,
        uncertaintyMargin: _eur(0),
        funding: CashCushionFunding(
          targetBalance: _eur(0),
          ownedCash: _eur(0),
          authorizedOverdraft: _eur(150000),
          overdraftFundedCash: _eur(50000),
        ),
      );

      expect(assessment.funding.operatingBalance, _eur(0));
      expect(assessment.funding.lowestAllowedBalance, _eur(-50000));
      expect(assessment.requiredProgress, _eur(150000));
      expect(assessment.protectedProjectedLowPoint, _eur(-50000));
      expect(assessment.funding.usesBankFunding, isTrue);
    });

    test('mixed funding keeps the uncertainty margin above its floor', () {
      final projection = _delayedAnnualIncomeProjection(_eur(-150000));
      final assessment = StartupLiquidityAssessment(
        projection: projection,
        uncertaintyMargin: _eur(10000),
        funding: CashCushionFunding(
          targetBalance: _eur(0),
          ownedCash: _eur(25000),
          authorizedOverdraft: _eur(150000),
          overdraftFundedCash: _eur(35000),
        ),
      );

      expect(assessment.targetCashCushion, _eur(60000));
      expect(assessment.funding.operatingBalance, _eur(25000));
      expect(assessment.funding.lowestAllowedBalance, _eur(-35000));
      expect(assessment.protectedProjectedLowPoint, _eur(-25000));
      expect(assessment.marginIsProtected, isTrue);
    });

    test('refuses to pretend the bank authorizes a lower floor', () {
      expect(
        () => CashCushionFunding(
          targetBalance: _eur(0),
          ownedCash: _eur(0),
          authorizedOverdraft: _eur(30000),
          overdraftFundedCash: _eur(40000),
        ),
        throwsArgumentError,
      );
    });
  });

  group('HouseholdBudgetFeasibility', () {
    test('contextualizes without modifying the sustainable amount', () {
      final profile = HouseholdNeedsProfile(
        fullTimePersons14OrOlder: 1,
        fullTimeChildrenUnder14: 2,
        weeklyBudgetScope: const {
          WeeklyBudgetCategory.groceries,
          WeeklyBudgetCategory.hygiene,
        },
        minimumViableWeeklyBudget: _eur(4000),
      );
      final feasibility = HouseholdBudgetFeasibility(
        profile: profile,
        testedWeeklyBudget: _eur(5000),
        sustainableWeeklyBudget: _eur(10000),
      );

      expect(feasibility.budgetPerPerson, _eur(1666));
      expect(feasibility.budgetPerConsumptionUnit, _eur(3125));
      expect(feasibility.viabilityBasisPoints, 12500);
      expect(feasibility.launchCompressionBasisPoints, 5000);
      expect(feasibility.isBelowDeclaredMinimum, isFalse);
      expect(feasibility.hasSevereCompression, isTrue);
    });
  });
}

StartupCashProjection _delayedAnnualIncomeProjection(Money initialCash) {
  final cycles = _cycles();
  return StartupCashProjectionEngine.project(
    cycles: cycles,
    initialUsableCash: initialCash,
    movements: [
      StartupCashMovement(
        date: LocalDate(2026, 8, 30),
        amount: _eur(520000),
        kind: StartupCashMovementKind.guaranteedIncome,
      ),
    ],
    weeklyBudgetsByCycleStart: {
      for (final cycle in cycles) cycle.start: _eur(10000),
    },
  );
}

List<WeeklyCycle> _cycles() {
  final policy = CyclePolicy(
    version: 1,
    effectiveFrom: LocalDate(2026, 8, 1),
    anchorWeekday: Weekday.saturday,
    timeZone: IanaTimeZoneId('Europe/Paris'),
  );
  return CycleCalendar.normalCycles(
    policy: policy,
    firstStart: policy.effectiveFrom,
    count: 52,
  );
}

Money _eur(int minorUnits) => Money.fromMinorUnits(minorUnits, Currency.eur);
