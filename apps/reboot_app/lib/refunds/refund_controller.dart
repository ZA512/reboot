import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';

import '../infrastructure/profile_providers.dart';

/// Mutation revision shared by refunds and the weekly dashboard.
final refundControllerProvider = AsyncNotifierProvider<RefundController, int>(
  RefundController.new,
);

final class RefundController extends AsyncNotifier<int> {
  @override
  FutureOr<int> build() => 0;

  Future<ExpenseRefundResult?> record(
    RecordExpenseRefundCommand command,
  ) async {
    if (state.isLoading) return null;
    final revision = state.value ?? 0;
    ExpenseRefundResult? result;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(localRebootServiceProvider.future);
      result = await service.recordExpenseRefund(command);
      return revision + 1;
    });
    return state.hasError ? null : result;
  }

  Future<bool> reverse(ReverseExpenseRefundCommand command) async {
    if (state.isLoading) return false;
    final revision = state.value ?? 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(localRebootServiceProvider.future);
      await service.reverseExpenseRefund(command);
      return revision + 1;
    });
    return !state.hasError;
  }
}
