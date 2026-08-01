import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dashboard/weekly_dashboard_screen.dart';
import '../financial_setup/financial_setup_controller.dart';
import '../financial_setup/financial_setup_screen.dart';
import '../infrastructure/profile_providers.dart';
import '../l10n/app_localizations.dart';
import '../onboarding/onboarding_controller.dart';
import '../onboarding/onboarding_screen.dart';
import '../settings/local_backup_controller.dart';
import '../trajectory_setup/trajectory_setup_controller.dart';
import '../trajectory_setup/trajectory_setup_screen.dart';

/// Root material application after platform bindings and providers exist.
final class RebootApp extends StatelessWidget {
  /// Creates the root application.
  const RebootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff315c4b)),
        useMaterial3: true,
      ),
      home: const ProfileStartupGate(),
    );
  }
}

/// Distinguishes startup, locked profile, onboarding, and ready states.
final class ProfileStartupGate extends ConsumerWidget {
  /// Creates the startup gate.
  const ProfileStartupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(localRebootServiceProvider);
    return profile.when(
      loading: () => const _LoadingScreen(),
      error: (error, stackTrace) => _LockedProfileScreen(
        onRetry: () => ref.invalidate(localRebootServiceProvider),
      ),
      data: (service) {
        if (service.configuration.household == null) {
          ref.watch(onboardingControllerProvider);
          ref.watch(localBackupControllerProvider);
          return const OnboardingScreen();
        }
        if (service.configuration.cashFlows.isEmpty) {
          ref.watch(financialSetupControllerProvider);
          return const FinancialSetupScreen();
        }
        if (service.configuration.annualCommitments.isEmpty) {
          ref.watch(trajectorySetupControllerProvider);
          return TrajectorySetupScreen(
            firstCycleStart: service.configuration.household!.firstCycleStart,
          );
        }
        return WeeklyDashboardScreen(service: service);
      },
    );
  }
}

final class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Semantics(
          label: l10n.profileOpening,
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

final class _LockedProfileScreen extends StatelessWidget {
  const _LockedProfileScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  l10n.profileLockedTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(l10n.profileLockedBody, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.tryAgain),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
