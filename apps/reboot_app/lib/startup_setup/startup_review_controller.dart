import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';

import '../infrastructure/profile_providers.dart';

final startupReviewControllerProvider =
    AsyncNotifierProvider.autoDispose<
      StartupReviewController,
      StartupLaunchReviewResult?
    >(StartupReviewController.new);

final class StartupReviewController
    extends AsyncNotifier<StartupLaunchReviewResult?> {
  @override
  FutureOr<StartupLaunchReviewResult?> build() => null;

  Future<StartupLaunchReviewResult?> submit(
    ReviewStartupLaunchCommand command,
  ) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(localRebootServiceProvider.future);
      return service.reviewStartupLaunch(command);
    });
    return state.value;
  }
}
