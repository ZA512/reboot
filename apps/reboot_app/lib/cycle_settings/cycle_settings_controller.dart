import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../infrastructure/profile_providers.dart';

/// Persists one future REBOOT-day change without rewriting previous cycles.
final cycleSettingsControllerProvider =
    AsyncNotifierProvider.autoDispose<CycleSettingsController, bool>(
      CycleSettingsController.new,
    );

/// Keeps the cycle-policy mutation and its failure state outside the widget.
final class CycleSettingsController extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() => false;

  /// Schedules [anchorWeekday] from the next untouched cycle boundary.
  Future<bool> submit({
    required Weekday anchorWeekday,
    required IanaTimeZoneId timeZone,
    required LocalDate effectiveFrom,
    required LocalDate businessDate,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(localRebootServiceProvider.future);
      await service.changeCyclePolicy(
        ChangeCyclePolicyCommand(
          anchorWeekday: anchorWeekday,
          timeZone: timeZone,
          effectiveFrom: effectiveFrom,
          businessDate: businessDate,
        ),
      );
      return true;
    });
    return !state.hasError;
  }
}
