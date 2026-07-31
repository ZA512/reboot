import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../infrastructure/profile_providers.dart';

/// Mutation revision shared by received-bonus screens and the dashboard.
final receivedBonusControllerProvider =
    AsyncNotifierProvider<ReceivedBonusController, int>(
      ReceivedBonusController.new,
    );

/// Applies bonus confirmations through the serialized application boundary.
final class ReceivedBonusController extends AsyncNotifier<int> {
  @override
  FutureOr<int> build() => 0;

  Future<bool> create({
    required ReceivedBonusPool pool,
    required LocalDate businessDate,
  }) => _mutate((service) {
    return service.createReceivedBonus(
      CreateReceivedBonusCommand(
        pool: pool,
        effectiveFromCycleStart: service.nextConfigurationCycleStart(
          businessDate,
        ),
        businessDate: businessDate,
      ),
    );
  });

  Future<bool> replace({
    required EntityId receivedBonusId,
    required ReceivedBonusPool pool,
    required LocalDate businessDate,
  }) => _mutate((service) {
    return service.replaceReceivedBonus(
      ReplaceReceivedBonusCommand(
        receivedBonusId: receivedBonusId,
        pool: pool,
        effectiveFromCycleStart: service.nextConfigurationCycleStart(
          businessDate,
        ),
        businessDate: businessDate,
      ),
    );
  });

  Future<bool> delete({
    required EntityId receivedBonusId,
    required LocalDate businessDate,
  }) => _mutate((service) {
    return service.deleteReceivedBonus(
      DeleteReceivedBonusCommand(
        receivedBonusId: receivedBonusId,
        effectiveFromCycleStart: service.nextConfigurationCycleStart(
          businessDate,
        ),
        businessDate: businessDate,
      ),
    );
  });

  Future<bool> _mutate(
    Future<Object?> Function(LocalRebootService service) operation,
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
