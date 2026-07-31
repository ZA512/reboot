import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

import '../bonuses/received_bonus_controller.dart';
import '../bonuses/received_bonus_screen.dart';
import '../cycle_settings/cycle_settings_controller.dart';
import '../cycle_settings/cycle_settings_screen.dart';
import '../expenses/quick_expense_controller.dart';
import '../expenses/quick_expense_screen.dart';
import '../financial_setup/cash_flow_management_screen.dart';
import '../health/health_controller.dart';
import '../health/health_screen.dart';
import '../infrastructure/android_weekly_widget.dart';
import '../infrastructure/device_context_providers.dart';
import '../l10n/app_localizations.dart';
import '../refunds/refund_controller.dart';
import '../refunds/refunds_screen.dart';
import '../reserves/reserve_controller.dart';
import '../reserves/reserves_screen.dart';
import '../trajectory_setup/trajectory_management_screen.dart';
import '../trends/trends_screen.dart';

/// Live answer to the daily question: how much can the household still spend?
final class WeeklyDashboardScreen extends ConsumerStatefulWidget {
  const WeeklyDashboardScreen({required this.service, super.key});

  final LocalRebootService service;

  @override
  ConsumerState<WeeklyDashboardScreen> createState() =>
      _WeeklyDashboardScreenState();
}

final class _WeeklyDashboardScreenState
    extends ConsumerState<WeeklyDashboardScreen> {
  String? _lastPublishedWidgetState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deviceContext = ref.watch(onboardingDeviceContextProvider);
    final mutation = ref.watch(quickExpenseControllerProvider);
    ref.watch(reserveControllerProvider);
    ref.watch(refundControllerProvider);
    ref.watch(healthControllerProvider);
    ref.watch(cycleSettingsControllerProvider);
    ref.watch(receivedBonusControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.refreshDashboard,
            onPressed: () => ref.invalidate(onboardingDeviceContextProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: deviceContext.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _DashboardDateError(
          onRetry: () => ref.invalidate(onboardingDeviceContextProvider),
        ),
        data: _dashboardFor,
      ),
      floatingActionButton: switch (deviceContext) {
        AsyncData(:final value)
            when !value.localDate.isBefore(
              widget.service.configuration.household!.firstCycleStart,
            ) =>
          FloatingActionButton.extended(
            key: const ValueKey('add-expense'),
            onPressed: mutation.isLoading
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => QuickExpenseScreen(
                        service: widget.service,
                        today: value.localDate,
                      ),
                    ),
                  ),
            icon: const Icon(Icons.add),
            label: Text(l10n.addExpense),
          ),
        _ => null,
      },
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _dashboardFor(OnboardingDeviceContext device) {
    final current = widget.service
        .buildRollingBudget(device.localDate)
        .cycles
        .first;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final displayAmount = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    ).format(current.remaining.minorUnits / 100);
    final validBeforeDate = current.cycle.endExclusive.toString();
    final state = '$displayAmount|$validBeforeDate';
    if (_lastPublishedWidgetState != state) {
      _lastPublishedWidgetState = state;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AndroidWeeklyWidget.update(
          displayAmount: displayAmount,
          validBeforeDate: validBeforeDate,
        );
      });
    }
    return _DashboardBody(
      service: widget.service,
      today: device.localDate,
      deleting: ref.watch(quickExpenseControllerProvider).isLoading,
      onRequestWidget: _requestWidget,
    );
  }

  Future<void> _requestWidget() async {
    final l10n = AppLocalizations.of(context);
    final requested = await AndroidWeeklyWidget.requestPin();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          requested
              ? l10n.weeklyWidgetRequestSent
              : l10n.weeklyWidgetManualInstall,
        ),
      ),
    );
  }
}

final class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
    required this.service,
    required this.today,
    required this.deleting,
    required this.onRequestWidget,
  });

  final LocalRebootService service;
  final LocalDate today;
  final bool deleting;
  final VoidCallback onRequestWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final household = service.configuration.household!;
    final pending = today.isBefore(household.firstCycleStart);
    final projection = service.buildRollingBudget(today);
    final trends = service.buildTrends(today);
    final current = projection.cycles.first;
    final expenses =
        service.expenses.activeExpenses
            .where(
              (expense) =>
                  expense.allocations?.any(
                    (allocation) =>
                        allocation.cycleStart == current.cycle.start,
                  ) ??
                  false,
            )
            .toList()
          ..sort(
            (left, right) => right.recordedAtUtc.compareTo(left.recordedAtUtc),
          );
    final daysRemaining = math.max(
      1,
      today.daysUntil(current.cycle.endExclusive),
    );
    final daily = Money.fromMinorUnits(
      current.remaining.minorUnits ~/ daysRemaining,
      current.remaining.currency,
    );
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
        children: [
          if (pending) ...[
            Card(
              color: colors.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.firstCyclePending(
                          _formatDate(context, household.firstCycleStart),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            pending ? l10n.upcomingWeeklyBudget : l10n.remainingThisWeek,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Card(
            color: current.isOverBudget
                ? colors.errorContainer
                : colors.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                children: [
                  Text(
                    _formatMoney(context, current.remaining),
                    key: const ValueKey('weekly-remaining'),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: current.isOverBudget
                          ? colors.onErrorContainer
                          : colors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pending
                        ? l10n.availableFrom(
                            _formatDate(context, current.cycle.start),
                          )
                        : l10n.untilNextReboot(
                            _formatDate(context, current.cycle.endExclusive),
                          ),
                    textAlign: TextAlign.center,
                  ),
                  if (!pending && !current.isOverBudget) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.dailyGuide(
                        _formatMoney(context, daily),
                        daysRemaining,
                      ),
                    ),
                  ],
                  if (current.isOverBudget) ...[
                    const SizedBox(height: 6),
                    Text(l10n.weeklyOverBudget, textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: l10n.weeklyBudgetMetric,
                  amount: current.budget,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Metric(
                  label: l10n.weeklySpentMetric,
                  amount: current.allocatedExpenses,
                ),
              ),
            ],
          ),
          if (current.refundCredits.isPositive) ...[
            const SizedBox(height: 8),
            Card(
              color: colors.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.replay_circle_filled),
                title: Text(
                  l10n.refundsRestoredThisCycle(
                    _formatMoney(context, current.refundCredits),
                  ),
                ),
                subtitle: Text(l10n.refundsRestoredThisCycleHelp),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              key: const ValueKey('open-assumptions'),
              leading: const Icon(Icons.tune),
              title: Text(l10n.assumptionsDashboardTitle),
              subtitle: Text(l10n.assumptionsDashboardHelp),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      CashFlowManagementScreen(service: service, today: today),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              key: const ValueKey('open-trajectory'),
              leading: const Icon(Icons.route_outlined),
              title: Text(l10n.trajectoryDashboardTitle),
              subtitle: Text(l10n.trajectoryDashboardHelp),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TrajectoryManagementScreen(
                    service: service,
                    today: today,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              key: const ValueKey('open-received-bonuses'),
              leading: const Icon(Icons.card_giftcard),
              title: Text(l10n.receivedBonusesDashboardTitle),
              subtitle: Text(_receivedBonusSummary(l10n, service, today)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ReceivedBonusScreen(service: service, today: today),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              key: const ValueKey('open-cycle-settings'),
              leading: const Icon(Icons.event_repeat),
              title: Text(l10n.cycleSettingsDashboardTitle),
              subtitle: Text(l10n.cycleSettingsDashboardHelp),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      CycleSettingsScreen(service: service, today: today),
                ),
              ),
            ),
          ),
          if (AndroidWeeklyWidget.isSupported) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                key: const ValueKey('install-weekly-widget'),
                leading: const Icon(Icons.widgets_outlined),
                title: Text(l10n.weeklyWidgetTitle),
                subtitle: Text(l10n.weeklyWidgetHelp),
                trailing: const Icon(Icons.add_to_home_screen_outlined),
                onTap: onRequestWidget,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.replay_outlined),
              title: Text(l10n.refundsTitle),
              subtitle: Text(l10n.refundsDashboardHelp),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RefundsScreen(service: service, today: today),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _HealthSummaryCard(
            tracking: service.health.tracking,
            today: today,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HealthScreen(service: service, today: today),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.savings_outlined),
              title: Text(
                service.reserves.reserves.isEmpty
                    ? l10n.createFirstReserve
                    : l10n.reservesSummary(
                        _formatMoney(context, service.reserves.totalBalance),
                        service.reserves.reserves.length,
                      ),
              ),
              subtitle: Text(l10n.reservesSummaryHelp),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ReservesScreen(service: service, today: today),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _TrendSummaryCard(
            trends: trends,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TrendsScreen(service: service, today: today),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.thisWeekExpenses,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (expenses.isEmpty)
            Text(pending ? l10n.expensesAvailableAfterStart : l10n.noExpenseYet)
          else
            for (final expense in expenses)
              _ExpenseTile(
                expense: expense,
                cycleStart: current.cycle.start,
                deleting: deleting,
                onDelete: () => _confirmDelete(
                  context: context,
                  ref: ref,
                  expense: expense,
                ),
              ),
          const SizedBox(height: 24),
          Text(
            l10n.noCarryoverReminder,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete({
    required BuildContext context,
    required WidgetRef ref,
    required ProjectedExpense expense,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteExpenseTitle),
        content: Text(
          (expense.allocations?.length ?? 1) > 1
              ? l10n.deleteSplitExpenseBody(expense.allocations!.length)
              : l10n.deleteExpenseBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.deleteExpense),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final accepted = await ref
        .read(quickExpenseControllerProvider.notifier)
        .delete(expenseId: expense.id, deletionDate: today);
    if (!accepted && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.deleteExpenseError)));
    }
  }
}

String _receivedBonusSummary(
  AppLocalizations l10n,
  LocalRebootService service,
  LocalDate today,
) {
  final household = service.configuration.household!;
  final currentCycle = today.isBefore(household.firstCycleStart)
      ? household.firstCycleStart
      : household.cycleContaining(today).start;
  final nextCycle = service.nextConfigurationCycleStart(today);
  final active = service.configuration.receivedBonuses.values
      .where((bonus) {
        return bonus.revisionForCycleStarting(currentCycle)?.pool != null ||
            bonus.revisionForCycleStarting(nextCycle)?.pool != null;
      })
      .toList(growable: false);
  if (active.isEmpty) return l10n.receivedBonusesDashboardEmpty;
  final due = active.where((bonus) {
    final displayed =
        bonus.revisionForCycleStarting(nextCycle)?.pool ??
        bonus.revisionForCycleStarting(currentCycle)?.pool;
    return displayed != null && !displayed.nextPaymentDate.isAfter(today);
  }).length;
  return due == 0
      ? l10n.receivedBonusesDashboardCount(active.length)
      : l10n.receivedBonusesDashboardDue(active.length, due);
}

final class _TrendSummaryCard extends StatelessWidget {
  const _TrendSummaryCard({required this.trends, required this.onOpen});

  final TrendProjection trends;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    if (trends.observedCycles.isEmpty) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.insights_outlined),
          title: Text(l10n.trendAvailableAfterCycle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpen,
        ),
      );
    }
    final (icon, color, status) = switch (trends.severity) {
      TrendAlertSeverity.none => (
        Icons.check_circle_outline,
        colors.primary,
        l10n.trendStatusNone,
      ),
      TrendAlertSeverity.vigilance => (
        Icons.warning_amber_rounded,
        colors.tertiary,
        l10n.trendStatusVigilance,
      ),
      TrendAlertSeverity.strong => (
        Icons.error_outline,
        colors.error,
        l10n.trendStatusStrong,
      ),
    };
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(status),
        subtitle: Text(
          l10n.trendSummary(
            _formatSignedMoney(context, trends.balance),
            trends.observedCycles.length,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpen,
      ),
    );
  }
}

final class _HealthSummaryCard extends StatelessWidget {
  const _HealthSummaryCard({
    required this.tracking,
    required this.today,
    required this.onOpen,
  });

  final ProjectedHealthTracking? tracking;
  final LocalDate today;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled = tracking?.enabled ?? false;
    final alert = enabled && tracking!.requiresAttention(today);
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: alert ? colors.errorContainer : null,
      child: ListTile(
        leading: Icon(
          alert
              ? Icons.warning_amber_rounded
              : Icons.health_and_safety_outlined,
          color: alert ? colors.error : null,
        ),
        title: Text(
          enabled
              ? l10n.healthDashboardEstimate(
                  _formatSignedMoney(context, tracking!.estimatedRest(today)),
                )
              : l10n.healthTrackingOptional,
        ),
        subtitle: Text(
          enabled
              ? (alert
                    ? l10n.healthAttentionTitle
                    : l10n.healthDashboardOnTrack)
              : l10n.healthDisabledWarning,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpen,
      ),
    );
  }
}

final class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.amount});

  final String label;
  final Money amount;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text(label, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            _formatMoney(context, amount),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    ),
  );
}

final class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.cycleStart,
    required this.deleting,
    required this.onDelete,
  });

  final ProjectedExpense expense;
  final LocalDate cycleStart;
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allocation = expense.allocations!.firstWhere(
      (part) => part.cycleStart == cycleStart,
    );
    final splitCount = expense.allocations!.length;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
      title: Text(expense.label),
      subtitle: Text(
        '${splitCount > 1 ? l10n.splitExpenseDetail(_formatMoney(context, expense.amount), splitCount, _formatDate(context, expense.purchaseDate)) : _formatDate(context, expense.purchaseDate)}'
        '${expense.refundedAmount.isPositive ? '\n${l10n.expenseRefunded(_formatMoney(context, expense.refundedAmount))}' : ''}'
        '${expense.nature == null ? '' : '\n${l10n.expenseNatureDisplay(_expenseNatureLabel(l10n, expense.nature!))}'}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '−${_formatMoney(context, allocation.amount)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            tooltip: l10n.deleteExpense,
            onPressed: deleting ? null : onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

final class _DashboardDateError extends StatelessWidget {
  const _DashboardDateError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.dashboardDateError, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMoney(BuildContext context, Money money) =>
    NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      name: money.currency.code,
      decimalDigits: 2,
    ).format(money.minorUnits / money.currency.minorUnitsPerMajorUnit);

String _formatSignedMoney(BuildContext context, Money money) {
  final formatted = _formatMoney(context, money.isNegative ? -money : money);
  return money.isNegative ? '−$formatted' : '+$formatted';
}

String _formatDate(BuildContext context, LocalDate date) =>
    MaterialLocalizations.of(
      context,
    ).formatFullDate(DateTime(date.year, date.month, date.day));

String _expenseNatureLabel(AppLocalizations l10n, ExpenseNature nature) =>
    switch (nature) {
      ExpenseNature.necessary => l10n.expenseNatureNecessary,
      ExpenseNature.pleasure => l10n.expenseNaturePleasure,
      ExpenseNature.deferrable => l10n.expenseNatureDeferrable,
      ExpenseNature.unexpected => l10n.expenseNatureUnexpected,
    };
