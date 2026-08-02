import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';
import 'package:test/test.dart';

void main() {
  group('LaunchPlanSearchEngine', () {
    test('finds a recovery plan without ever worsening -1500 EUR', () {
      final cycles = _cycles();
      final result = LaunchPlanSearchEngine.search(
        cycles: cycles,
        initialUsableCash: _eur(-150000),
        movements: _weeklyIncome(cycles, 10000),
        sustainableWeeklyBudget: _eur(10000),
        minimumViableWeeklyBudget: _eur(5000),
        uncertaintyMargin: _eur(50000),
        funding: CashCushionFunding(
          targetBalance: _eur(0),
          ownedCash: _eur(50000),
          authorizedOverdraft: _eur(150000),
          overdraftFundedCash: _eur(0),
        ),
      );

      expect(result.isFeasible, isTrue);
      expect(result.gentlest!.durationCycles, 52);
      expect(result.gentlest!.launchWeeklyBudget, _eur(6000));
      expect(result.gentlest!.completionBalance, _eur(58000));
      expect(
        result.gentlest!.projection.points
            .map((point) => point.closingBalance)
            .reduce((left, right) => left.compareTo(right) < 0 ? left : right),
        _eur(-146000),
      );
      expect(result.recommended, isNull);
      expect(result.primarySuggestions, hasLength(1));
    });

    test('does not hide an early cash crisis behind a yearly division', () {
      final cycles = _cycles();
      final result = LaunchPlanSearchEngine.search(
        cycles: cycles,
        initialUsableCash: _eur(-150000),
        movements: [
          StartupCashMovement(
            date: LocalDate(2026, 8, 30),
            amount: _eur(520000),
            kind: StartupCashMovementKind.guaranteedIncome,
          ),
        ],
        sustainableWeeklyBudget: _eur(10000),
        minimumViableWeeklyBudget: _eur(5000),
        uncertaintyMargin: _eur(0),
        funding: CashCushionFunding(
          targetBalance: _eur(0),
          ownedCash: _eur(50000),
          authorizedOverdraft: _eur(200000),
          overdraftFundedCash: _eur(0),
        ),
      );

      expect(result.isFeasible, isFalse);
      expect(result.primarySuggestions, isEmpty);
    });

    test(
      'rejects a nearby unfunded expense when every viable budget fails',
      () {
        final cycles = _cycles();
        final result = LaunchPlanSearchEngine.search(
          cycles: cycles,
          initialUsableCash: _eur(0),
          movements: [
            ..._weeklyIncome(cycles, 10000),
            StartupCashMovement(
              date: cycles[1].start.addDays(2),
              amount: _eur(100000),
              kind: StartupCashMovementKind.irregularExpense,
            ),
          ],
          sustainableWeeklyBudget: _eur(10000),
          minimumViableWeeklyBudget: _eur(5000),
          uncertaintyMargin: _eur(0),
          funding: CashCushionFunding(
            targetBalance: _eur(0),
            ownedCash: _eur(100000),
            authorizedOverdraft: _eur(0),
            overdraftFundedCash: _eur(0),
          ),
        );

        expect(result.isFeasible, isFalse);
      },
    );

    test('offers a non-severe recommendation when one exists', () {
      final cycles = _cycles();
      final result = LaunchPlanSearchEngine.search(
        cycles: cycles,
        initialUsableCash: _eur(0),
        movements: _weeklyIncome(cycles, 10000),
        sustainableWeeklyBudget: _eur(10000),
        minimumViableWeeklyBudget: _eur(7000),
        uncertaintyMargin: _eur(20000),
        funding: CashCushionFunding(
          targetBalance: _eur(0),
          ownedCash: _eur(20000),
          authorizedOverdraft: _eur(0),
          overdraftFundedCash: _eur(0),
        ),
      );

      expect(result.recommended, isNotNull);
      expect(result.recommended!.durationCycles, 8);
      expect(result.recommended!.launchWeeklyBudget, _eur(7500));
      expect(result.recommended!.compressionBasisPoints, 2500);
      expect(result.primarySuggestions.length, lessThanOrEqualTo(3));
    });

    test('refuses a weekly amount below the declared human minimum', () {
      final cycles = _cycles();
      final result = LaunchPlanSearchEngine.search(
        cycles: cycles,
        initialUsableCash: _eur(0),
        movements: _weeklyIncome(cycles, 10000),
        sustainableWeeklyBudget: _eur(8000),
        minimumViableWeeklyBudget: _eur(9000),
        uncertaintyMargin: _eur(0),
        funding: CashCushionFunding(
          targetBalance: _eur(0),
          ownedCash: _eur(0),
          authorizedOverdraft: _eur(0),
          overdraftFundedCash: _eur(0),
        ),
      );

      expect(result.isFeasible, isFalse);
    });
  });
}

List<StartupCashMovement> _weeklyIncome(List<WeeklyCycle> cycles, int amount) =>
    [
      for (final cycle in cycles)
        StartupCashMovement(
          date: cycle.start,
          amount: _eur(amount),
          kind: StartupCashMovementKind.guaranteedIncome,
        ),
    ];

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
