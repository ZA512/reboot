import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../infrastructure/profile_providers.dart';

/// Mutation revision shared by the post-onboarding assumptions screen.
final cashFlowManagementControllerProvider =
    AsyncNotifierProvider.autoDispose<CashFlowManagementController, int>(
      CashFlowManagementController.new,
    );

/// Applies durable assumption changes only from the next REBOOT boundary.
final class CashFlowManagementController extends AsyncNotifier<int> {
  @override
  FutureOr<int> build() => 0;

  Future<bool> create({
    required CashFlowDefinition definition,
    required LocalDate businessDate,
  }) => _mutate((service) async {
    await service.createCashFlow(
      CreateCashFlowCommand(
        definition: definition,
        effectiveFromCycleStart: service.nextConfigurationCycleStart(
          businessDate,
        ),
        businessDate: businessDate,
      ),
    );
  });

  Future<bool> replace({
    required EntityId cashFlowId,
    required CashFlowDefinition definition,
    required LocalDate businessDate,
  }) => _mutate((service) async {
    await service.replaceCashFlow(
      ReplaceCashFlowCommand(
        cashFlowId: cashFlowId,
        definition: definition,
        effectiveFromCycleStart: service.nextConfigurationCycleStart(
          businessDate,
        ),
        businessDate: businessDate,
      ),
    );
  });

  Future<bool> delete({
    required EntityId cashFlowId,
    required LocalDate businessDate,
  }) => _mutate((service) async {
    await service.deleteCashFlow(
      DeleteCashFlowCommand(
        cashFlowId: cashFlowId,
        effectiveFromCycleStart: service.nextConfigurationCycleStart(
          businessDate,
        ),
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
