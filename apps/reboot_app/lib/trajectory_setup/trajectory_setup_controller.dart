import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../infrastructure/profile_providers.dart';

/// Saves the complete initial trajectory plan through one application command.
final trajectorySetupControllerProvider =
    AsyncNotifierProvider.autoDispose<TrajectorySetupController, bool>(
      TrajectorySetupController.new,
    );

/// Keeps trajectory mutation and failure state outside presentation widgets.
final class TrajectorySetupController extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() => false;

  /// Persists the selected strategy from the household's first cycle.
  Future<void> submit({
    required TrajectoryStrategy strategy,
    required Money reserveContributions,
    required Money projectContributions,
    required Money safetyMargin,
    required LocalDate businessDate,
    OverdraftExitGoal? overdraftExitGoal,
  }) async {
    if (state.isLoading) {
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(localRebootServiceProvider.future);
      final household = service.configuration.household;
      if (household == null) {
        throw StateError('The household must exist before trajectory setup.');
      }
      await service.setTrajectoryPlan(
        SetTrajectoryPlanCommand(
          strategy: strategy,
          reserveContributions: reserveContributions,
          projectContributions: projectContributions,
          safetyMargin: safetyMargin,
          effectiveFromCycleStart: household.firstCycleStart,
          businessDate: businessDate,
          overdraftExitGoal: overdraftExitGoal,
        ),
      );
      return true;
    });
  }
}
