import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../infrastructure/profile_providers.dart';

/// Coordinates the single atomic write that completes financial assumptions.
final financialSetupControllerProvider =
    AsyncNotifierProvider.autoDispose<
      FinancialSetupController,
      List<EntityId>?
    >(FinancialSetupController.new);

/// Keeps journal commands and sanitized failure state outside the screen.
final class FinancialSetupController extends AsyncNotifier<List<EntityId>?> {
  @override
  FutureOr<List<EntityId>?> build() => null;

  /// Persists all confirmed income and outflow definitions together.
  Future<void> submit({
    required List<CashFlowDefinition> definitions,
    required LocalDate businessDate,
  }) async {
    if (state.isLoading) {
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await ref.read(localRebootServiceProvider.future);
      final household = service.configuration.household;
      if (household == null) {
        throw StateError('The household must exist before financial setup.');
      }
      return service.createCashFlows(
        CreateCashFlowsCommand(
          definitions: definitions,
          effectiveFromCycleStart: household.firstCycleStart,
          businessDate: businessDate,
        ),
      );
    });
  }
}
