import 'package:reboot_domain/reboot_domain.dart';
import 'package:test/test.dart';

void main() {
  group('RecurringSchedule', () {
    test('preserves an intended month-end day after a shorter month', () {
      final schedule = RecurringSchedule(
        firstOccurrence: LocalDate(2026, 1, 31),
        frequency: RecurrenceFrequency.monthly,
      );

      expect(
        schedule.occurrencesBetween(
          startInclusive: LocalDate(2026, 1, 1),
          endExclusive: LocalDate(2026, 4, 1),
        ),
        [
          LocalDate(2026, 1, 31),
          LocalDate(2026, 2, 28),
          LocalDate(2026, 3, 31),
        ],
      );
    });

    test('uses February 29 in leap years', () {
      final schedule = RecurringSchedule(
        firstOccurrence: LocalDate(2024, 1, 31),
        frequency: RecurrenceFrequency.monthly,
      );

      expect(
        schedule.occurrencesBetween(
          startInclusive: LocalDate(2024, 2, 1),
          endExclusive: LocalDate(2024, 3, 1),
        ),
        [LocalDate(2024, 2, 29)],
      );
    });

    test('counts weekly and four-week cadences as civil dates', () {
      final start = LocalDate(2026, 1, 3);
      final end = start.addDays(364);

      expect(
        RecurringSchedule(
          firstOccurrence: start,
          frequency: RecurrenceFrequency.weekly,
        ).occurrencesBetween(startInclusive: start, endExclusive: end),
        hasLength(52),
      );
      expect(
        RecurringSchedule(
          firstOccurrence: start,
          frequency: RecurrenceFrequency.everyFourWeeks,
        ).occurrencesBetween(startInclusive: start, endExclusive: end),
        hasLength(13),
      );
    });

    test('respects an inclusive final occurrence', () {
      final schedule = RecurringSchedule(
        firstOccurrence: LocalDate(2026, 1, 15),
        frequency: RecurrenceFrequency.monthly,
        lastOccurrence: LocalDate(2026, 3, 15),
      );

      expect(
        schedule.occurrencesBetween(
          startInclusive: LocalDate(2026, 1, 1),
          endExclusive: LocalDate(2026, 6, 1),
        ),
        [
          LocalDate(2026, 1, 15),
          LocalDate(2026, 2, 15),
          LocalDate(2026, 3, 15),
        ],
      );
    });
  });

  group('CustomDateSchedule', () {
    test('sorts, deduplicates, and filters explicit dates', () {
      final schedule = CustomDateSchedule([
        LocalDate(2026, 12, 1),
        LocalDate(2026, 3, 1),
        LocalDate(2026, 3, 1),
      ]);

      expect(
        schedule.occurrencesBetween(
          startInclusive: LocalDate(2026, 2, 1),
          endExclusive: LocalDate(2026, 6, 1),
        ),
        [LocalDate(2026, 3, 1)],
      );
    });
  });

  group('CashFlowDefinition', () {
    final schedule = CustomDateSchedule([LocalDate(2026, 1, 3)]);

    test('requires custom amount only for a custom variable estimate', () {
      expect(
        () => CashFlowDefinition.variable(
          title: 'Allocation',
          direction: CashFlowDirection.income,
          schedule: schedule,
          historicalAveragePerOccurrence: _eur(10000),
          strategy: VariableEstimateStrategy.custom,
        ),
        throwsArgumentError,
      );
      expect(
        () => CashFlowDefinition.variable(
          title: 'Allocation',
          direction: CashFlowDirection.income,
          schedule: schedule,
          historicalAveragePerOccurrence: _eur(10000),
          strategy: VariableEstimateStrategy.balanced,
          customAmountPerOccurrence: _eur(9000),
        ),
        throwsArgumentError,
      );
    });

    test('keeps fixed and variable behavior explicit', () {
      final fixed = CashFlowDefinition.fixed(
        title: ' Électricité ',
        direction: CashFlowDirection.outflow,
        schedule: schedule,
        amountPerOccurrence: _eur(12000),
      );
      final variable = CashFlowDefinition.variable(
        title: 'Essence',
        direction: CashFlowDirection.outflow,
        schedule: schedule,
        historicalAveragePerOccurrence: _eur(20000),
        strategy: VariableEstimateStrategy.prudent,
      );

      expect(fixed.title, 'Électricité');
      expect(fixed.behavior, AmountBehavior.fixed);
      expect(variable.behavior, AmountBehavior.variable);
    });
  });

  group('ReceivedBonusPool', () {
    test('contains only money already received and assigned to daily life', () {
      final pool = ReceivedBonusPool(
        title: 'Prime annuelle restante',
        remainingForDailyLife: _eur(500000),
        nextPaymentDate: LocalDate(2027, 1, 15),
      );

      expect(pool.remainingForDailyLife.minorUnits, 500000);
      expect(pool.nextPaymentDate, LocalDate(2027, 1, 15));
    });

    test('rejects negative remaining money', () {
      expect(
        () => ReceivedBonusPool(
          title: 'Prime',
          remainingForDailyLife: _eur(-1),
          nextPaymentDate: LocalDate(2027, 1, 15),
        ),
        throwsArgumentError,
      );
    });
  });
}

Money _eur(int minorUnits) => Money.fromMinorUnits(minorUnits, Currency.eur);
