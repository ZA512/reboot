import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../infrastructure/profile_providers.dart';

/// Complete user choice required by the initial household command.
final class OnboardingDraft {
  /// Creates an immutable onboarding submission.
  const OnboardingDraft({
    required this.householdKind,
    required this.onboardingDate,
    required this.anchorWeekday,
    required this.timeZone,
    required this.firstCycleChoice,
  });

  /// Solo or shared-main-account mode.
  final HouseholdKind householdKind;

  /// Local civil confirmation date.
  final LocalDate onboardingDate;

  /// User-selected start of every normal REBOOT week.
  final Weekday anchorWeekday;

  /// Verified IANA zone detected from the device.
  final IanaTimeZoneId timeZone;

  /// Next complete anchor or explicit expense catch-up.
  final FirstCycleStartChoice firstCycleChoice;
}

/// Presentation controller coordinating one atomic household initialization.
final onboardingControllerProvider =
    AsyncNotifierProvider.autoDispose<
      OnboardingController,
      HouseholdInitializationResult?
    >(OnboardingController.new);

/// Keeps command execution and error state outside widgets.
final class OnboardingController
    extends AsyncNotifier<HouseholdInitializationResult?> {
  @override
  FutureOr<HouseholdInitializationResult?> build() => null;

  /// Persists the initial household exactly once through the application port.
  Future<void> submit(OnboardingDraft draft) async {
    if (state.isLoading) {
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(localRebootServiceProvider.future);
      return service.initializeHousehold(
        InitializeHouseholdCommand(
          householdKind: draft.householdKind,
          onboardingDate: draft.onboardingDate,
          anchorWeekday: draft.anchorWeekday,
          timeZone: draft.timeZone,
          firstCycleChoice: draft.firstCycleChoice,
        ),
      );
    });
  }
}
