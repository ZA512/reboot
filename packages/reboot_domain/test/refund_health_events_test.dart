import 'package:reboot_domain/reboot_domain.dart';
import 'package:test/test.dart';

void main() {
  test('refund payload keeps amount and receipt cycle explicit', () {
    final payload = ExpenseRefundedPayload(
      amount: _eur(8000),
      receiptCycleStart: LocalDate(2026, 4, 11),
    );

    expect(payload.eventType, 'expense.refunded');
    expect(payload.targetKind, EntityKind.expense);
  });

  test('health configuration validates delay and threshold', () {
    final payload = HealthTrackingConfiguredPayload(
      enabled: true,
      delayWeeks: 4,
      alertThreshold: _eur(5000),
    );

    expect(payload.targetKind, EntityKind.healthTracking);
    expect(payload.delayWeeks, 4);
    expect(
      () => HealthTrackingConfiguredPayload(
        enabled: true,
        delayWeeks: 0,
        alertThreshold: _eur(5000),
      ),
      throwsRangeError,
    );
  });

  test('health entries require a positive amount and label', () {
    expect(
      () => HealthExpenseRecordedPayload(amount: _eur(0), label: 'Médecin'),
      throwsArgumentError,
    );
    expect(
      () => HealthReimbursementRecordedPayload(amount: _eur(1000), label: ' '),
      throwsArgumentError,
    );
  });
}

Money _eur(int minorUnits) => Money.fromMinorUnits(minorUnits, Currency.eur);
