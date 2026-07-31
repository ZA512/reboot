import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';

import '../infrastructure/profile_providers.dart';

/// Mutation revision shared by the reserve screens and dashboard.
final reserveControllerProvider = AsyncNotifierProvider<ReserveController, int>(
  ReserveController.new,
);

/// Serializes reserve commands through the application boundary.
final class ReserveController extends AsyncNotifier<int> {
  @override
  FutureOr<int> build() => 0;

  Future<bool> create(CreateReserveCommand command) =>
      _mutate((service) => service.createReserve(command));

  Future<bool> addFunds(AddReserveFundsCommand command) =>
      _mutate((service) => service.addReserveFunds(command));

  Future<bool> use(UseReserveCommand command) =>
      _mutate((service) => service.useReserve(command));

  Future<bool> reverse(ReverseReserveMovementCommand command) =>
      _mutate((service) => service.reverseReserveMovement(command));

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
