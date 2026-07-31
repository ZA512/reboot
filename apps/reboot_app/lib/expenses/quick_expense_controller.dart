import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../infrastructure/profile_providers.dart';

/// Mutation state shared by quick entry and the live dashboard.
final quickExpenseControllerProvider =
    AsyncNotifierProvider<QuickExpenseController, int>(
      QuickExpenseController.new,
    );

/// Records and deletes complete expenses through the application boundary.
final class QuickExpenseController extends AsyncNotifier<int> {
  @override
  FutureOr<int> build() => 0;

  /// Persists the real expense and every virtual installment atomically.
  Future<bool> record(RecordExpenseCommand command) async {
    if (state.isLoading) return false;
    final revision = state.value ?? 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(localRebootServiceProvider.future);
      await service.recordExpense(command);
      return revision + 1;
    });
    return !state.hasError;
  }

  /// Tombstones an erroneous expense, including all its installments.
  Future<bool> delete({
    required EntityId expenseId,
    required LocalDate deletionDate,
  }) async {
    if (state.isLoading) return false;
    final revision = state.value ?? 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(localRebootServiceProvider.future);
      await service.deleteExpense(
        expenseId: expenseId,
        deletionDate: deletionDate,
      );
      return revision + 1;
    });
    return !state.hasError;
  }
}
