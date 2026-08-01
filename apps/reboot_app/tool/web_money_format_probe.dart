import 'package:reboot_app/formatting/exact_money_formatter.dart';
import 'package:reboot_domain/reboot_domain.dart';

void main() {
  final value = Money.fromMinorUnitsDecimal('9007199254740993', Currency.eur);
  final formatted = formatMoneyInputExact(value);
  if (formatted != '90071992547409.93') {
    throw StateError('Exact Web money formatting failed: $formatted');
  }
}
