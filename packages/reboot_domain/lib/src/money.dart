/// An ISO 4217 currency explicitly supported by the domain.
///
/// REBOOT's first product version accepts only [eur] for household data.
/// Other entries exist so currency mismatches cannot silently enter generic
/// monetary calculations. Expanding this list requires reviewed ISO metadata.
enum Currency {
  /// Euro.
  eur('EUR', 100),

  /// United States dollar.
  usd('USD', 100),

  /// Japanese yen.
  jpy('JPY', 1);

  const Currency(this.code, this.minorUnitsPerMajorUnit);

  /// The three-letter ISO 4217 code.
  final String code;

  /// The number of minor units in one major unit.
  final int minorUnitsPerMajorUnit;

  /// Parses an exact, uppercase, supported ISO 4217 [code].
  static Currency parse(String code) {
    for (final currency in values) {
      if (currency.code == code) {
        return currency;
      }
    }

    throw FormatException('Unsupported ISO 4217 currency code: $code');
  }
}

/// An exact signed monetary value stored in ISO 4217 minor units.
///
/// Formatting and exchange-rate conversion deliberately do not belong here.
/// All arithmetic is checked against the signed 64-bit storage range.
final class Money implements Comparable<Money> {
  Money._(this.exactMinorUnits, this.currency);

  /// Smallest value supported by the persisted signed 64-bit representation.
  static final BigInt minMinorUnits = BigInt.parse('-9223372036854775808');

  /// Largest value supported by the persisted signed 64-bit representation.
  static final BigInt maxMinorUnits = BigInt.parse('9223372036854775807');

  /// Creates an exact value from [minorUnits].
  factory Money.fromMinorUnits(int minorUnits, Currency currency) {
    return Money._checked(BigInt.from(minorUnits), currency);
  }

  /// Creates an exact value from a platform-independent integer.
  factory Money.fromMinorUnitsBigInt(BigInt minorUnits, Currency currency) {
    return Money._checked(minorUnits, currency);
  }

  /// Parses the canonical decimal representation used by portable journals.
  factory Money.fromMinorUnitsDecimal(String minorUnits, Currency currency) {
    final parsed = BigInt.tryParse(minorUnits);
    if (parsed == null || parsed.toString() != minorUnits) {
      throw FormatException(
        'Minor units must use a canonical decimal integer representation.',
      );
    }
    return Money._checked(parsed, currency);
  }

  /// Creates a zero value in [currency].
  factory Money.zero(Currency currency) => Money._(BigInt.zero, currency);

  /// The exact signed amount in the currency's minor unit on every platform.
  final BigInt exactMinorUnits;

  /// Compatibility view for native storage and ordinary UI values.
  ///
  /// JavaScript cannot represent every signed 64-bit integer as an [int]. Code
  /// that persists, authenticates, or performs domain arithmetic must use
  /// [exactMinorUnits]. This getter fails instead of returning a rounded value.
  int get minorUnits {
    if (!exactMinorUnits.isValidInt) {
      throw StateError(
        'This exact monetary value cannot be represented as a platform int.',
      );
    }
    return exactMinorUnits.toInt();
  }

  /// The currency that labels this value.
  final Currency currency;

  /// Whether this amount is below zero.
  bool get isNegative => exactMinorUnits.isNegative;

  /// Whether this amount equals zero.
  bool get isZero => exactMinorUnits == BigInt.zero;

  /// Whether this amount is above zero.
  bool get isPositive => exactMinorUnits > BigInt.zero;

  /// Adds two values bearing the same currency.
  Money operator +(Money other) {
    _requireSameCurrency(other);
    return Money._checked(exactMinorUnits + other.exactMinorUnits, currency);
  }

  /// Subtracts two values bearing the same currency.
  Money operator -(Money other) {
    _requireSameCurrency(other);
    return Money._checked(exactMinorUnits - other.exactMinorUnits, currency);
  }

  /// Returns the additive inverse of this value.
  Money operator -() {
    return Money._checked(-exactMinorUnits, currency);
  }

  /// Multiplies this value by an integer [factor].
  Money operator *(int factor) {
    return Money._checked(exactMinorUnits * BigInt.from(factor), currency);
  }

  /// Splits a non-negative amount into [partCount] exact installments.
  ///
  /// The first `partCount - 1` installments receive the integer quotient. The
  /// last installment absorbs the remainder, so the returned sum always equals
  /// this amount.
  List<Money> splitEvenly(int partCount) {
    if (partCount <= 0) {
      throw RangeError.range(partCount, 1, null, 'partCount');
    }
    if (isNegative) {
      throw StateError('A negative amount cannot be split into installments.');
    }

    final quotient = exactMinorUnits ~/ BigInt.from(partCount);
    final lastPart = exactMinorUnits - (quotient * BigInt.from(partCount - 1));

    return List<Money>.unmodifiable(
      List<Money>.generate(
        partCount,
        (index) => index == partCount - 1
            ? Money._checked(lastPart, currency)
            : Money.fromMinorUnitsBigInt(quotient, currency),
      ),
    );
  }

  /// Rounds a non-negative recommendation down to a whole major unit.
  ///
  /// Negative capacities must remain explicit deficits and are therefore
  /// rejected instead of being silently rounded.
  Money roundDownToMajorUnit() {
    if (isNegative) {
      throw StateError('A negative capacity must not be rounded as a budget.');
    }

    final scale = BigInt.from(currency.minorUnitsPerMajorUnit);
    return Money.fromMinorUnitsBigInt(
      (exactMinorUnits ~/ scale) * scale,
      currency,
    );
  }

  @override
  int compareTo(Money other) {
    _requireSameCurrency(other);
    return exactMinorUnits.compareTo(other.exactMinorUnits);
  }

  void _requireSameCurrency(Money other) {
    if (currency != other.currency) {
      throw CurrencyMismatchException(currency, other.currency);
    }
  }

  factory Money._checked(BigInt minorUnits, Currency currency) {
    if (minorUnits < minMinorUnits || minorUnits > maxMinorUnits) {
      throw MoneyOverflowException(minorUnits);
    }

    return Money._(minorUnits, currency);
  }

  @override
  bool operator ==(Object other) {
    return other is Money &&
        exactMinorUnits == other.exactMinorUnits &&
        currency == other.currency;
  }

  @override
  int get hashCode => Object.hash(exactMinorUnits, currency);

  @override
  String toString() => 'Money($exactMinorUnits ${currency.code} minor units)';
}

/// Indicates that an operation mixed monetary values in different currencies.
final class CurrencyMismatchException implements Exception {
  /// Creates a mismatch between [left] and [right].
  const CurrencyMismatchException(this.left, this.right);

  /// Currency of the left-hand value.
  final Currency left;

  /// Currency of the right-hand value.
  final Currency right;

  @override
  String toString() {
    return 'CurrencyMismatchException: ${left.code} and ${right.code}';
  }
}

/// Indicates that a calculation exceeded signed 64-bit monetary storage.
final class MoneyOverflowException implements Exception {
  /// Creates an overflow carrying the rejected exact [value].
  const MoneyOverflowException(this.value);

  /// The exact out-of-range result.
  final BigInt value;

  @override
  String toString() => 'MoneyOverflowException: $value is outside int64';
}
