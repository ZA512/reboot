import 'package:flutter_test/flutter_test.dart';
import 'package:reboot_app/financial_setup/euro_amount_parser.dart';

void main() {
  test('parses French and English EUR input exactly in cents', () {
    expect(parsePositiveEuroAmount('9,3')!.minorUnits, 930);
    expect(parsePositiveEuroAmount('9.33')!.minorUnits, 933);
    expect(parsePositiveEuroAmount('1 234,56')!.minorUnits, 123456);
    expect(parsePositiveEuroAmount('1\u202f234,56')!.minorUnits, 123456);
  });

  test('rejects zero, signs, extra decimals, and non-numeric input', () {
    expect(parsePositiveEuroAmount('0'), isNull);
    expect(parsePositiveEuroAmount('-1'), isNull);
    expect(parsePositiveEuroAmount('+1'), isNull);
    expect(parsePositiveEuroAmount('9,333'), isNull);
    expect(parsePositiveEuroAmount('1,2.3'), isNull);
    expect(parsePositiveEuroAmount('EUR 10'), isNull);
  });

  test('rejects values outside signed 64-bit minor units', () {
    expect(parsePositiveEuroAmount('92233720368547758,08'), isNull);
  });
}
