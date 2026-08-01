import 'package:intl/intl.dart';
import 'package:reboot_domain/reboot_domain.dart';

/// Formats [money] without converting its exact integer value to `double`.
String formatMoneyExact(Money money, {required String locale}) {
  final formatter = NumberFormat.simpleCurrency(
    locale: locale,
    name: money.currency.code,
    decimalDigits: _fractionDigitCount(money.currency),
  );
  final unsigned = _formatUnsigned(money, formatter);
  return money.isNegative
      ? '${formatter.negativePrefix}$unsigned${formatter.negativeSuffix}'
      : '${formatter.positivePrefix}$unsigned${formatter.positiveSuffix}';
}

/// Formats only the localized numeric part, for the privacy-preserving widget.
String formatMoneyNumberExact(Money money, {required String locale}) {
  final formatter = NumberFormat.decimalPattern(locale);
  final unsigned = _formatUnsigned(money, formatter);
  return money.isNegative
      ? '${formatter.negativePrefix}$unsigned${formatter.negativeSuffix}'
      : '${formatter.positivePrefix}$unsigned${formatter.positiveSuffix}';
}

/// Produces an exact, ungrouped amount suitable for a decimal input field.
String formatMoneyInputExact(Money money, {bool alwaysShowFraction = false}) {
  final digits = _fractionDigitCount(money.currency);
  final scale = BigInt.from(money.currency.minorUnitsPerMajorUnit);
  final absolute = money.exactMinorUnits.abs();
  final whole = absolute ~/ scale;
  final fraction = (absolute % scale).toString().padLeft(digits, '0');
  final sign = money.isNegative ? '-' : '';
  if (digits == 0 || (!alwaysShowFraction && fraction == '0' * digits)) {
    return '$sign$whole';
  }
  return '$sign$whole.$fraction';
}

String _formatUnsigned(Money money, NumberFormat formatter) {
  final digits = _fractionDigitCount(money.currency);
  final scale = BigInt.from(money.currency.minorUnitsPerMajorUnit);
  final absolute = money.exactMinorUnits.abs();
  final whole = absolute ~/ scale;
  final groupedWhole = _groupAndLocalizeWhole(whole, formatter);
  if (digits == 0) return groupedWhole;

  final asciiFraction = (absolute % scale).toString().padLeft(digits, '0');
  final localizedFraction = _localizeDigits(asciiFraction, formatter);
  return '$groupedWhole${formatter.symbols.DECIMAL_SEP}$localizedFraction';
}

String _groupAndLocalizeWhole(BigInt whole, NumberFormat formatter) {
  // REBOOT V1 supports French and English, both of which group by three.
  // Keeping grouping textual avoids the lossy `BigInt -> double` path in intl.
  final digits = whole.toString();
  final firstGroupLength = digits.length % 3 == 0 ? 3 : digits.length % 3;
  final groups = <String>[digits.substring(0, firstGroupLength)];
  for (var offset = firstGroupLength; offset < digits.length; offset += 3) {
    groups.add(digits.substring(offset, offset + 3));
  }
  return _localizeDigits(groups.join(formatter.symbols.GROUP_SEP), formatter);
}

String _localizeDigits(String source, NumberFormat formatter) {
  return String.fromCharCodes(
    source.codeUnits.map(
      (codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39
          ? codeUnit + formatter.localeZero - 0x30
          : codeUnit,
    ),
  );
}

int _fractionDigitCount(Currency currency) {
  var scale = currency.minorUnitsPerMajorUnit;
  var digits = 0;
  while (scale > 1 && scale % 10 == 0) {
    scale ~/= 10;
    digits += 1;
  }
  if (scale != 1) {
    throw StateError('Currency scale must be a power of ten.');
  }
  return digits;
}
