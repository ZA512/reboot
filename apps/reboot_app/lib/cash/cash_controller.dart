import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../infrastructure/profile_providers.dart';

/// Serializes cash-method, withdrawal, and correction commands.
final cashControllerProvider = AsyncNotifierProvider<CashController, int>(
  CashController.new,
);

final class CashController extends AsyncNotifier<int> {
  @override
  FutureOr<int> build() => 0;

  Future<bool> configure({
    required CashWithdrawalMethod method,
    required LocalDate businessDate,
  }) => _mutate((service) async {
    await service.configureCashHandling(
      ConfigureCashHandlingCommand(method: method, businessDate: businessDate),
    );
  });

  Future<bool> recordWithdrawal({
    required Money amount,
    required String label,
    required LocalDate businessDate,
  }) => _mutate((service) async {
    switch (service.cash.methodOn(businessDate)) {
      case CashWithdrawalMethod.withdrawalAsExpense:
        await service.recordExpense(
          RecordExpenseCommand(
            amount: amount,
            label: label,
            purchaseDate: businessDate,
          ),
        );
      case CashWithdrawalMethod.cashWallet:
        await service.recordCashWalletTransfer(
          RecordCashWalletTransferCommand(
            amount: amount,
            label: label,
            businessDate: businessDate,
          ),
        );
      case null:
        throw StateError('Cash handling must be selected first.');
    }
  });

  Future<bool> reverseTransfer({
    required EventId transferEventId,
    required LocalDate businessDate,
  }) => _mutate((service) async {
    await service.reverseCashWalletTransfer(
      ReverseCashWalletTransferCommand(
        transferEventId: transferEventId,
        businessDate: businessDate,
      ),
    );
  });

  Future<bool> _mutate(
    Future<void> Function(LocalRebootService service) operation,
  ) async {
    if (state.isLoading) return false;
    final revision = state.value ?? 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(localRebootServiceProvider.future);
      await operation(service);
      return revision + 1;
    });
    return !state.hasError;
  }
}
