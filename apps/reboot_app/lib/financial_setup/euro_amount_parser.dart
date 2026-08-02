import 'package:reboot_domain/reboot_domain.dart';

/// Parses a user-entered positive EUR amount without binary floating point.
Money? parsePositiveEuroAmount(String source) {
  final amount = parseNonNegativeEuroAmount(source);
  return amount == null || amount.isZero ? null : amount;
}

/// Parses an exact non-negative EUR amount, including zero.
Money? parseNonNegativeEuroAmount(String source) {
  final amount = parseSignedEuroAmount(source);
  return amount == null || amount.isNegative ? null : amount;
}

/// Parses an exact signed EUR amount, including a leading minus sign.
Money? parseSignedEuroAmount(String source) {
  final normalized = source
      .trim()
      .replaceAll(RegExp(r'[\s\u00a0\u202f]'), '')
      .replaceAll(',', '.');
  final match = RegExp(r'^(-?)(\d+)(?:\.(\d{1,2}))?$').firstMatch(normalized);
  if (match == null) {
    return null;
  }
  final negative = match.group(1) == '-';
  final whole = BigInt.parse(match.group(2)!);
  final fractionSource = match.group(3) ?? '';
  final fraction = switch (fractionSource.length) {
    0 => BigInt.zero,
    1 => BigInt.parse(fractionSource) * BigInt.from(10),
    _ => BigInt.parse(fractionSource),
  };
  final absoluteMinorUnits = whole * BigInt.from(100) + fraction;
  final minorUnits = negative ? -absoluteMinorUnits : absoluteMinorUnits;
  if (minorUnits < Money.minMinorUnits || minorUnits > Money.maxMinorUnits) {
    return null;
  }
  return Money.fromMinorUnitsBigInt(minorUnits, Currency.eur);
}
