import 'package:reboot_domain/reboot_domain.dart';
import 'package:test/test.dart';

void main() {
  test('cash events separate a wallet transfer from an expense', () {
    const method = CashHandlingMethodSetPayload(
      method: CashWithdrawalMethod.cashWallet,
    );
    final transfer = CashWalletTransferRecordedPayload(
      amount: Money.fromMinorUnits(5000, Currency.eur),
      label: 'Retrait espèces',
    );

    expect(method.targetKind, EntityKind.cashHandling);
    expect(transfer.targetKind, EntityKind.cashHandling);
    expect(transfer.eventType, 'cash-wallet.transfer-recorded');
    expect(
      () => CashWalletTransferRecordedPayload(
        amount: Money.zero(Currency.eur),
        label: 'Retrait',
      ),
      throwsArgumentError,
    );
  });
}
