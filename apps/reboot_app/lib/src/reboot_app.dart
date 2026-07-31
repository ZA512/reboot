import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../financial_setup/financial_setup_controller.dart';
import '../financial_setup/financial_setup_screen.dart';
import '../infrastructure/profile_providers.dart';
import '../l10n/app_localizations.dart';
import '../onboarding/onboarding_controller.dart';
import '../onboarding/onboarding_screen.dart';
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
        return _ReadyScreen(service: service);
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

final class _ReadyScreen extends StatelessWidget {
  const _ReadyScreen({required this.service});

  final LocalRebootService service;

  @override
  Widget build(BuildContext context) {
    final household = service.configuration.household!;
    final l10n = AppLocalizations.of(context);
    final projection = service.buildAnnualBudget(household.firstCycleStart);
    final plan = service.configuration.annualCommitments.last;
    final recovery = projection.overdraftRecovery;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          children: [
            Text(switch (household.householdKind) {
              HouseholdKind.solo => l10n.readySolo,
              HouseholdKind.sharedMainAccount => l10n.readyShared,
            }, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            Text(
              l10n.firstWeeklyBudgetTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(l10n.weeklyBudgetFrom(_formatDate(context, projection.start))),
            const SizedBox(height: 20),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(l10n.recommendedWeeklyBudget),
                    const SizedBox(height: 8),
                    Text(
                      _formatMoney(
                        context,
                        projection.recommendedWeeklyBudget,
                        decimalDigits: 0,
                      ),
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.weeklyRoundingHelp(
                        _formatMoney(context, projection.grossWeeklyCapacity),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            if (!projection.deficit.isZero) ...[
              const SizedBox(height: 16),
              _DashboardNotice(
                strong: true,
                message: l10n.annualDeficit(
                  _formatMoney(context, projection.deficit),
                ),
              ),
            ],
            if (recovery != null) ...[
              const SizedBox(height: 16),
              _DashboardNotice(
                strong: !recovery.isFeasible,
                message: recovery.isFeasible
                    ? l10n.overdraftRecoverySummary(
                        _formatMoney(context, recovery.requiredPerCycle),
                        recovery.cycleCount,
                        _formatDate(context, recovery.goal.targetDate),
                      )
                    : l10n.overdraftRecoveryImpossible(
                        _formatMoney(context, recovery.shortfallPerCycle),
                      ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              l10n.annualCalculationTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _AmountRow(
              label: l10n.annualIncome,
              amount: _formatMoney(context, projection.totalIncome),
            ),
            _AmountRow(
              label: l10n.annualOutflows,
              amount: _formatMoney(context, projection.totalOutflows),
              negative: !projection.totalOutflows.isZero,
            ),
            _AmountRow(
              label: l10n.annualReserves,
              amount: _formatMoney(
                context,
                projection.deductions.reserveContributions,
              ),
              negative: !projection.deductions.reserveContributions.isZero,
            ),
            _AmountRow(
              label: l10n.annualProjects,
              amount: _formatMoney(
                context,
                projection.deductions.projectContributions,
              ),
              negative: !projection.deductions.projectContributions.isZero,
            ),
            _AmountRow(
              label: l10n.annualSafety,
              amount: _formatMoney(context, projection.deductions.safetyMargin),
              negative: !projection.deductions.safetyMargin.isZero,
            ),
            const Divider(height: 24),
            _AmountRow(
              label: l10n.annualSteerableCapacity,
              amount: _formatMoney(context, projection.steerableCapacity),
              emphasized: true,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.selectedTrajectory(switch (plan.strategy) {
                TrajectoryStrategy.balance => l10n.strategyBalanceTitle,
                TrajectoryStrategy.cushion => l10n.strategyCushionTitle,
                TrajectoryStrategy.overdraftExit => l10n.strategyOverdraftTitle,
              }),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.quickExpenseNext,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

final class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.negative = false,
    this.emphasized = false,
  });

  final String label;
  final String amount;
  final bool negative;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized ? Theme.of(context).textTheme.titleMedium : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('${negative ? '− ' : ''}$amount', style: style),
        ],
      ),
    );
  }
}

final class _DashboardNotice extends StatelessWidget {
  const _DashboardNotice({required this.message, required this.strong});

  final String message;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: strong ? colors.errorContainer : colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(strong ? Icons.warning_amber : Icons.trending_up),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

String _formatMoney(
  BuildContext context,
  Money money, {
  int decimalDigits = 2,
}) {
  return NumberFormat.simpleCurrency(
    locale: Localizations.localeOf(context).toLanguageTag(),
    name: money.currency.code,
    decimalDigits: decimalDigits,
  ).format(money.minorUnits / money.currency.minorUnitsPerMajorUnit);
}

String _formatDate(BuildContext context, LocalDate date) {
  return MaterialLocalizations.of(
    context,
  ).formatFullDate(DateTime(date.year, date.month, date.day));
}
