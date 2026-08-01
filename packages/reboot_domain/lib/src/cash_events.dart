import 'events.dart';
import 'money.dart';

/// How cash withdrawals affect the REBOOT weekly budget.
enum CashWithdrawalMethod {
  /// The withdrawal is the expense; later cash purchases are not entered.
  withdrawalAsExpense,

  /// The withdrawal is a transfer; every later cash purchase is entered.
  cashWallet,
}

/// Version 1 effective-dated choice for handling cash withdrawals.
final class CashHandlingMethodSetPayload implements EventPayload {
  const CashHandlingMethodSetPayload({required this.method});

  @override
  String get eventType => 'cash-handling.method-set';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.cashHandling;

  final CashWithdrawalMethod method;
}

/// Version 1 withdrawal transferred to a conceptual cash wallet.
final class CashWalletTransferRecordedPayload implements EventPayload {
  CashWalletTransferRecordedPayload({
    required this.amount,
    required this.label,
  }) {
    if (!amount.isPositive || amount.currency != Currency.eur) {
      throw ArgumentError.value(
        amount,
        'amount',
        'A cash transfer must be a strictly positive EUR amount.',
      );
    }
    if (label.trim().isEmpty) {
      throw ArgumentError.value(
        label,
        'label',
        'A transfer label is required.',
      );
    }
  }

  @override
  String get eventType => 'cash-wallet.transfer-recorded';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.cashHandling;

  final Money amount;
  final String label;
}

/// Version 1 correction neutralizing an erroneous cash-wallet transfer.
final class CashWalletTransferReversedPayload implements EventPayload {
  const CashWalletTransferReversedPayload({required this.transferEventId});

  @override
  String get eventType => 'cash-wallet.transfer-reversed';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.cashHandling;

  final EventId transferEventId;
}
