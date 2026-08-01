import 'package:reboot_domain/reboot_domain.dart';

void main() {
  final beyondJavaScriptSafeInteger = Money.fromMinorUnitsDecimal(
    '9007199254740993',
    Currency.eur,
  );
  final maximum = Money.fromMinorUnitsBigInt(Money.maxMinorUnits, Currency.eur);
  final position = LocalJournalPosition.fromBigInt(
    LocalJournalPosition.maxValue,
  );

  _require(
    beyondJavaScriptSafeInteger.exactMinorUnits.toString() ==
        '9007199254740993',
    'Money lost precision above the JavaScript safe-integer range.',
  );
  _require(
    (maximum - beyondJavaScriptSafeInteger).exactMinorUnits ==
        Money.maxMinorUnits - beyondJavaScriptSafeInteger.exactMinorUnits,
    'Money arithmetic lost signed-64-bit precision.',
  );
  _require(
    position.exactValue.toString() == '9223372036854775807',
    'Journal position lost signed-64-bit precision.',
  );

  try {
    maximum + Money.fromMinorUnits(1, Currency.eur);
  } on MoneyOverflowException {
    print('REBOOT Web signed-64-bit exactness probe passed.');
    return;
  }
  throw StateError('Signed-64-bit monetary overflow was not rejected.');
}

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}
