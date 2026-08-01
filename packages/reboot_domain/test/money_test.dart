import 'package:reboot_domain/reboot_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Currency', () {
    test('parses supported exact ISO 4217 codes', () {
      expect(Currency.parse('EUR'), Currency.eur);
      expect(Currency.parse('JPY'), Currency.jpy);
    });

    test('rejects unknown or non-normalized codes', () {
      expect(() => Currency.parse('eur'), throwsFormatException);
      expect(() => Currency.parse('ZZZ'), throwsFormatException);
    });
  });

  group('Money arithmetic', () {
    test('adds, subtracts, and compares exact values', () {
      final first = Money.fromMinorUnits(1250, Currency.eur);
      final second = Money.fromMinorUnits(250, Currency.eur);

      expect(first + second, Money.fromMinorUnits(1500, Currency.eur));
      expect(first - second, Money.fromMinorUnits(1000, Currency.eur));
      expect(second * 3, Money.fromMinorUnits(750, Currency.eur));
      expect(-second, Money.fromMinorUnits(-250, Currency.eur));
      expect(first.compareTo(second), greaterThan(0));
    });

    test(
      'supports partial and total refunds without treating them as income',
      () {
        final expense = Money.fromMinorUnits(10000, Currency.eur);
        final partialRefund = Money.fromMinorUnits(3500, Currency.eur);
        final totalRefund = Money.fromMinorUnits(10000, Currency.eur);

        expect(
          expense - partialRefund,
          Money.fromMinorUnits(6500, Currency.eur),
        );
        expect(expense - totalRefund, Money.zero(Currency.eur));
      },
    );

    test('refuses arithmetic and comparison across currencies', () {
      final euros = Money.fromMinorUnits(100, Currency.eur);
      final dollars = Money.fromMinorUnits(100, Currency.usd);

      expect(() => euros + dollars, throwsA(isA<CurrencyMismatchException>()));
      expect(() => euros - dollars, throwsA(isA<CurrencyMismatchException>()));
      expect(
        () => euros.compareTo(dollars),
        throwsA(isA<CurrencyMismatchException>()),
      );
    });

    test('preserves value equality and currency identity', () {
      final value = Money.fromMinorUnits(42, Currency.eur);

      expect(value, Money.fromMinorUnits(42, Currency.eur));
      expect(value.hashCode, Money.fromMinorUnits(42, Currency.eur).hashCode);
      expect(value, isNot(Money.fromMinorUnits(42, Currency.usd)));
    });
  });

  group('Money int64 boundaries', () {
    test('accepts both signed 64-bit boundaries', () {
      expect(
        Money.fromMinorUnitsBigInt(
          Money.minMinorUnits,
          Currency.eur,
        ).exactMinorUnits,
        Money.minMinorUnits,
      );
      expect(
        Money.fromMinorUnitsBigInt(
          Money.maxMinorUnits,
          Currency.eur,
        ).exactMinorUnits,
        Money.maxMinorUnits,
      );
    });

    test('round-trips canonical portable decimal values', () {
      final value = Money.fromMinorUnitsDecimal(
        '9007199254740993',
        Currency.eur,
      );

      expect(value.exactMinorUnits.toString(), '9007199254740993');
      expect(
        () => Money.fromMinorUnitsDecimal('09007199254740993', Currency.eur),
        throwsFormatException,
      );
      expect(
        () => Money.fromMinorUnitsDecimal('+1', Currency.eur),
        throwsFormatException,
      );
    });

    test('detects addition and subtraction overflow', () {
      final maximum = Money.fromMinorUnitsBigInt(
        Money.maxMinorUnits,
        Currency.eur,
      );
      final minimum = Money.fromMinorUnitsBigInt(
        Money.minMinorUnits,
        Currency.eur,
      );
      final one = Money.fromMinorUnits(1, Currency.eur);

      expect(() => maximum + one, throwsA(isA<MoneyOverflowException>()));
      expect(() => minimum - one, throwsA(isA<MoneyOverflowException>()));
    });

    test('detects multiplication and negation overflow', () {
      final maximum = Money.fromMinorUnitsBigInt(
        Money.maxMinorUnits,
        Currency.eur,
      );
      final minimum = Money.fromMinorUnitsBigInt(
        Money.minMinorUnits,
        Currency.eur,
      );

      expect(() => maximum * 2, throwsA(isA<MoneyOverflowException>()));
      expect(() => -minimum, throwsA(isA<MoneyOverflowException>()));
    });
  });

  group('Money allocation', () {
    test('splits 90 EUR exactly across 26 cycles', () {
      final source = Money.fromMinorUnits(9000, Currency.eur);
      final parts = source.splitEvenly(26);

      expect(parts, hasLength(26));
      expect(
        parts.take(25),
        everyElement(Money.fromMinorUnits(346, Currency.eur)),
      );
      expect(parts.last, Money.fromMinorUnits(350, Currency.eur));
      expect(_sum(parts, Currency.eur), source);
    });

    test('splits 28 EUR into 9.33, 9.33, and 9.34 EUR', () {
      final parts = Money.fromMinorUnits(2800, Currency.eur).splitEvenly(3);

      expect(parts, [
        Money.fromMinorUnits(933, Currency.eur),
        Money.fromMinorUnits(933, Currency.eur),
        Money.fromMinorUnits(934, Currency.eur),
      ]);
    });

    test('preserves every source cent across representative allocations', () {
      for (var minorUnits = 0; minorUnits <= 1000; minorUnits++) {
        final source = Money.fromMinorUnits(minorUnits, Currency.eur);
        for (var partCount = 1; partCount <= 52; partCount++) {
          expect(_sum(source.splitEvenly(partCount), Currency.eur), source);
        }
      }
    });

    test('rejects invalid installment requests', () {
      expect(
        () => Money.fromMinorUnits(100, Currency.eur).splitEvenly(0),
        throwsRangeError,
      );
      expect(
        () => Money.fromMinorUnits(-100, Currency.eur).splitEvenly(3),
        throwsStateError,
      );
    });
  });

  group('Money recommendation rounding', () {
    test('rounds 233.82 EUR down to 233 EUR', () {
      expect(
        Money.fromMinorUnits(23382, Currency.eur).roundDownToMajorUnit(),
        Money.fromMinorUnits(23300, Currency.eur),
      );
    });

    test('uses the currency minor-unit scale instead of assuming cents', () {
      expect(
        Money.fromMinorUnits(233, Currency.jpy).roundDownToMajorUnit(),
        Money.fromMinorUnits(233, Currency.jpy),
      );
    });

    test('keeps zero and refuses to hide a negative deficit', () {
      expect(
        Money.zero(Currency.eur).roundDownToMajorUnit(),
        Money.zero(Currency.eur),
      );
      expect(
        () => Money.fromMinorUnits(-1, Currency.eur).roundDownToMajorUnit(),
        throwsStateError,
      );
    });
  });
}

Money _sum(Iterable<Money> values, Currency currency) {
  return values.fold(Money.zero(currency), (sum, value) => sum + value);
}
