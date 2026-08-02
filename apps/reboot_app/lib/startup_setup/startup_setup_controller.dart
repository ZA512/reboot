import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';

import '../infrastructure/profile_providers.dart';

final startupSetupControllerProvider =
    AsyncNotifierProvider.autoDispose<StartupSetupController, bool>(
      StartupSetupController.new,
    );

final class StartupSetupController extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() => false;

  Future<bool> submit(AcceptStartupPlanCommand command) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(localRebootServiceProvider.future);
      await service.acceptStartupPlan(command);
      return true;
    });
    return !state.hasError;
  }
}
