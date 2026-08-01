import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

import '../formatting/exact_money_formatter.dart';
import '../l10n/app_localizations.dart';
import 'trajectory_setup_controller.dart';
import 'trajectory_setup_screen.dart';

/// Explains the accepted and next trajectory without rewriting past weeks.
final class TrajectoryManagementScreen extends ConsumerWidget {
  const TrajectoryManagementScreen({
    required this.service,
    required this.today,
    super.key,
  });

  final LocalRebootService service;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.watch(trajectorySetupControllerProvider);
    final household = service.configuration.household!;
    final currentCycle = today.isBefore(household.firstCycleStart)
        ? household.firstCycleStart
        : household.cycleContaining(today).start;
    final effectiveCycle = service.nextConfigurationCycleStart(today);
    final current = service.configuration.commitmentsForCycleStarting(
      currentCycle,
    )!;
    final future = service.configuration.commitmentsForCycleStarting(
      effectiveCycle,
    )!;
    final futureBudget = service.buildAnnualBudget(effectiveCycle);
    final hasPendingChange = current.eventId != future.eventId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trajectoryManagementTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Text(l10n.trajectoryManagementIntro),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPendingChange
                          ? l10n.trajectoryChangeScheduled(
                              _formatDate(context, effectiveCycle),
                            )
                          : l10n.trajectoryChangeEffective(
                              _formatDate(context, effectiveCycle),
                            ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(l10n.assumptionsCurrentWeekUnchanged),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _BudgetValue(
                            label: l10n.currentWeeklyBudget,
                            amount: service.weeklyBudgetForCycleStarting(
                              currentCycle,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward),
                        Expanded(
                          child: _BudgetValue(
                            key: const ValueKey('future-trajectory-budget'),
                            label: l10n.futureWeeklyBudget,
                            amount: service.weeklyBudgetForCycleStarting(
                              effectiveCycle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (futureBudget.deficit.isPositive) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.assumptionsDeficitWarning(
                          _formatMoney(context, futureBudget.deficit),
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _TrajectoryCard(
              title: hasPendingChange
                  ? l10n.currentTrajectoryTitle
                  : l10n.acceptedTrajectoryTitle,
              revision: current,
            ),
            if (hasPendingChange) ...[
              const SizedBox(height: 12),
              _TrajectoryCard(
                key: const ValueKey('future-trajectory'),
                title: l10n.futureTrajectoryTitle,
                revision: future,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('edit-trajectory'),
              onPressed: () => Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => TrajectorySetupScreen(
                    firstCycleStart: household.firstCycleStart,
                    initialRevision: future,
                    effectiveFromCycleStart: effectiveCycle,
                  ),
                ),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: Text(
                hasPendingChange
                    ? l10n.changeScheduledTrajectory
                    : l10n.changeTrajectory,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TrajectoryCard extends StatelessWidget {
  const _TrajectoryCard({
    required this.title,
    required this.revision,
    super.key,
  });

  final String title;
  final AnnualCommitmentsRevision revision;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final goal = revision.overdraftExitGoal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_strategyIcon(revision.strategy)),
              title: Text(_strategyLabel(l10n, revision.strategy)),
              subtitle: Text(_strategyDescription(l10n, revision.strategy)),
            ),
            if (revision.reserveContributions.isPositive)
              _AmountLine(
                label: l10n.annualCushionLabel,
                amount: revision.reserveContributions,
              ),
            if (revision.projectContributions.isPositive)
              _AmountLine(
                label: l10n.annualProjectsLabel,
                amount: revision.projectContributions,
              ),
            if (revision.safetyMargin.isPositive)
              _AmountLine(
                label: l10n.annualSafetyLabel,
                amount: revision.safetyMargin,
              ),
            if (goal != null) ...[
              _AmountLine(
                label: l10n.currentOverdraftLabel,
                amount: goal.currentOverdraftDepth,
              ),
              _AmountLine(
                label: l10n.targetCushionLabel,
                amount: goal.targetCushion,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.overdraftTargetSummary(
                  _formatDate(context, goal.targetDate),
                ),
              ),
            ],
            if (!revision.reserveContributions.isPositive &&
                !revision.projectContributions.isPositive &&
                !revision.safetyMargin.isPositive &&
                goal == null)
              Text(l10n.noAnnualDeductions),
          ],
        ),
      ),
    );
  }
}

final class _AmountLine extends StatelessWidget {
  const _AmountLine({required this.label, required this.amount});

  final String label;
  final Money amount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          _formatMoney(context, amount),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

final class _BudgetValue extends StatelessWidget {
  const _BudgetValue({required this.label, required this.amount, super.key});

  final String label;
  final Money amount;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Text(
        _formatMoney(context, amount),
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
    ],
  );
}

IconData _strategyIcon(TrajectoryStrategy strategy) => switch (strategy) {
  TrajectoryStrategy.balance => Icons.balance,
  TrajectoryStrategy.cushion => Icons.savings_outlined,
  TrajectoryStrategy.overdraftExit => Icons.trending_up,
};

String _strategyLabel(AppLocalizations l10n, TrajectoryStrategy strategy) =>
    switch (strategy) {
      TrajectoryStrategy.balance => l10n.strategyBalanceTitle,
      TrajectoryStrategy.cushion => l10n.strategyCushionTitle,
      TrajectoryStrategy.overdraftExit => l10n.strategyOverdraftTitle,
    };

String _strategyDescription(
  AppLocalizations l10n,
  TrajectoryStrategy strategy,
) => switch (strategy) {
  TrajectoryStrategy.balance => l10n.strategyBalanceBody,
  TrajectoryStrategy.cushion => l10n.strategyCushionBody,
  TrajectoryStrategy.overdraftExit => l10n.strategyOverdraftBody,
};

String _formatMoney(BuildContext context, Money money) => formatMoneyExact(
  money,
  locale: Localizations.localeOf(context).toLanguageTag(),
);

String _formatDate(BuildContext context, LocalDate date) =>
    MaterialLocalizations.of(
      context,
    ).formatFullDate(DateTime(date.year, date.month, date.day));
