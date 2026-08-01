import 'package:flutter_test/flutter_test.dart';
import 'package:reboot_app/formatting/exact_money_formatter.dart';
import 'package:reboot_domain/reboot_domain.dart';

void main() {
  final beyondSafeInteger = Money.fromMinorUnitsDecimal(
    '9007199254740993',
    Currency.eur,
  );

  test('formats exact EUR cents in French and English', () {
    expect(
      formatMoneyExact(beyondSafeInteger, locale: 'fr_FR'),
      '90\u202f071\u202f992\u202f547\u202f409,93\u00a0€',
    );
    expect(
      formatMoneyExact(beyondSafeInteger, locale: 'en_US'),
      '€90,071,992,547,409.93',
    );
  });

  test('formats localized widget numbers and exact editable values', () {
    expect(
      formatMoneyNumberExact(beyondSafeInteger, locale: 'fr_FR'),
      '90\u202f071\u202f992\u202f547\u202f409,93',
    );
    expect(formatMoneyInputExact(beyondSafeInteger), '90071992547409.93');
    expect(
      formatMoneyInputExact(
        Money.fromMinorUnits(1200, Currency.eur),
        alwaysShowFraction: true,
      ),
      '12.00',
    );
  });

  test('preserves signs and zero-decimal currencies', () {
    expect(
      formatMoneyExact(
        Money.fromMinorUnits(-1234, Currency.eur),
        locale: 'fr_FR',
      ),
      '-12,34\u00a0€',
    );
    expect(
      formatMoneyInputExact(Money.fromMinorUnits(233, Currency.jpy)),
      '233',
    );
  });
}
