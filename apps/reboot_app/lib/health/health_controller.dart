import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';

import '../infrastructure/profile_providers.dart';

/// Mutation revision shared by health tracking and the dashboard.
final healthControllerProvider = AsyncNotifierProvider<HealthController, int>(
  HealthController.new,
);

final class HealthController extends AsyncNotifier<int> {
  @override
  FutureOr<int> build() => 0;

  Future<bool> configure(ConfigureHealthTrackingCommand command) =>
      _mutate((service) => service.configureHealthTracking(command));

  Future<bool> record(RecordHealthEntryCommand command) =>
      _mutate((service) => service.recordHealthEntry(command));

  Future<bool> reverse(ReverseHealthEntryCommand command) =>
      _mutate((service) => service.reverseHealthEntry(command));

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
