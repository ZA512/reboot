import 'package:reboot_domain/reboot_domain.dart';

/// Parses a user-entered positive EUR amount without binary floating point.
Money? parsePositiveEuroAmount(String source) {
  final normalized = source
      .trim()
      .replaceAll(RegExp(r'[\s\u00a0\u202f]'), '')
      .replaceAll(',', '.');
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(normalized);
  if (match == null) {
    return null;
  }
  final whole = BigInt.parse(match.group(1)!);
  final fractionSource = match.group(2) ?? '';
  final fraction = switch (fractionSource.length) {
    0 => BigInt.zero,
    1 => BigInt.parse(fractionSource) * BigInt.from(10),
    _ => BigInt.parse(fractionSource),
  };
  final minorUnits = whole * BigInt.from(100) + fraction;
  if (minorUnits <= BigInt.zero ||
      minorUnits > BigInt.from(Money.maxMinorUnits)) {
    return null;
  }
  return Money.fromMinorUnits(minorUnits.toInt(), Currency.eur);
}
