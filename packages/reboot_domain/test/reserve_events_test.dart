import 'package:reboot_domain/reboot_domain.dart';
import 'package:test/test.dart';

void main() {
  test('reserve payloads keep credits and expenses distinct from income', () {
    final created = ReserveCreatedPayload(
      name: 'Imprévus',
      kind: ReserveKind.real,
      openingBalance: _eur(50000),
    );
    final funded = ReserveFundsAddedPayload(
      amount: _eur(12000),
      label: 'Surplus affecté',
    );
    final spent = ReserveExpenseRecordedPayload(
      amount: _eur(8000),
      label: 'Vétérinaire',
    );

    expect(created.targetKind, EntityKind.reserve);
    expect(funded.eventType, 'reserve.funds-added');
    expect(spent.eventType, 'reserve.expense-recorded');
  });

  test('reserve payloads reject invalid names and amounts', () {
    expect(
      () => ReserveCreatedPayload(
        name: ' ',
        kind: ReserveKind.virtual,
        openingBalance: _eur(0),
      ),
      throwsArgumentError,
    );
    expect(
      () => ReserveFundsAddedPayload(amount: _eur(0), label: 'Apport'),
      throwsArgumentError,
    );
    expect(
      () => ReserveExpenseRecordedPayload(amount: _eur(100), label: ' '),
      throwsArgumentError,
    );
  });
}

Money _eur(int minorUnits) => Money.fromMinorUnits(minorUnits, Currency.eur);
