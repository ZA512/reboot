import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

import '../formatting/exact_money_formatter.dart';
import '../history/cycle_history_detail_screen.dart';
import '../l10n/app_localizations.dart';

/// Completed-cycle history and rolling REBOOT trends.
final class TrendsScreen extends StatefulWidget {
  const TrendsScreen({required this.service, required this.today, super.key});

  final LocalRebootService service;
  final LocalDate today;

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

final class _TrendsScreenState extends State<TrendsScreen> {
  int _selectedWindow = 8;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trends = widget.service.buildTrends(widget.today);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.trendsTitle)),
      body: trends.observedCycles.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.trendNoCompletedCycle,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _TrendDetails(
              service: widget.service,
              trends: trends,
              selectedWindow: _selectedWindow,
              onWindowSelected: (value) =>
                  setState(() => _selectedWindow = value),
            ),
    );
  }
}

final class _TrendDetails extends StatelessWidget {
  const _TrendDetails({
    required this.service,
    required this.trends,
    required this.selectedWindow,
    required this.onWindowSelected,
  });

  final LocalRebootService service;
  final TrendProjection trends;
  final int selectedWindow;
  final ValueChanged<int> onWindowSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final window = trends.window(selectedWindow);
    final natureBreakdown = service.buildExpenseNatureBreakdown(
      window.observedCycles.map((item) => item.cycle.start),
    );
    final statusColor = switch (trends.severity) {
      TrendAlertSeverity.none => colors.primary,
      TrendAlertSeverity.vigilance => colors.tertiary,
      TrendAlertSeverity.strong => colors.error,
    };
    final statusContainer = switch (trends.severity) {
      TrendAlertSeverity.none => colors.primaryContainer,
      TrendAlertSeverity.vigilance => colors.tertiaryContainer,
      TrendAlertSeverity.strong => colors.errorContainer,
    };
    final statusText = switch (trends.severity) {
      TrendAlertSeverity.none => l10n.trendStatusNone,
      TrendAlertSeverity.vigilance => l10n.trendStatusVigilance,
      TrendAlertSeverity.strong => l10n.trendStatusStrong,
    };
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            l10n.trendObservedBalance,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _formatSignedMoney(context, trends.balance),
            key: const ValueKey('observed-trend-balance'),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: trends.balance.isNegative ? colors.error : colors.primary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            l10n.trendCycleCount(trends.observedCycles.length),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            color: statusContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_statusIcon(trends.severity), color: statusColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          statusText,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_latestCycleMessage(context, trends)),
                  const SizedBox(height: 6),
                  Text(_globalMessage(context, trends)),
                  const SizedBox(height: 10),
                  Text(
                    l10n.trendBudgetUnchanged,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          if (natureBreakdown.total.isPositive) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.trendNatureBreakdownTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.trendNatureBreakdownHelp),
                    const SizedBox(height: 8),
                    for (final share in natureBreakdown.shares)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(_natureIcon(share.nature)),
                        title: Text(_natureLabel(l10n, share.nature)),
                        trailing: Text(
                          '${_formatMoney(context, share.amount)} · '
                          '${_formatBasisPoints(context, share.basisPoints)}',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (trends.observedCycles.length >= 8 && trends.balance.isPositive)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.savings_outlined),
                  title: Text(
                    l10n.trendSurplusSuggestion(
                      _formatMoney(context, trends.balance),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            l10n.trendWindowTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final count in TrendProjection.supportedWindows)
                ChoiceChip(
                  label: Text(l10n.trendWindowLabel(count)),
                  selected: selectedWindow == count,
                  onSelected: (_) => onWindowSelected(count),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    l10n.trendWindowBalance(selectedWindow),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatSignedMoney(context, window.balance),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.trendObservedCount(
                      window.observedCycles.length,
                      selectedWindow,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _WindowMetric(
                          label: l10n.trendHistoricalBudget,
                          value: _formatMoney(context, window.totalBudget),
                        ),
                      ),
                      Expanded(
                        child: _WindowMetric(
                          label: l10n.trendAllocated,
                          value: _formatMoney(
                            context,
                            window.totalAllocatedExpenses,
                          ),
                        ),
                      ),
                      if (window.totalTrajectoryCredits.isPositive)
                        Expanded(
                          child: _WindowMetric(
                            label: l10n.trendRefundCredits,
                            value: _formatMoney(
                              context,
                              window.totalTrajectoryCredits,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (trends.excludedTransitionCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              l10n.trendExcludedTransitions(trends.excludedTransitionCount),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.trendTransitionHistory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final transition in trends.excludedTransitionCycles.reversed)
              _CycleTile(
                observation: transition,
                onTap: () => _openCycle(context, transition),
              ),
          ],
          const SizedBox(height: 24),
          Text(
            l10n.trendCycleHistory,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final observation in window.observedCycles.reversed)
            _CycleTile(
              observation: observation,
              onTap: () => _openCycle(context, observation),
            ),
        ],
      ),
    );
  }

  void _openCycle(BuildContext context, TrendCycleObservation observation) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CycleHistoryDetailScreen(
          service: service,
          observation: observation,
        ),
      ),
    );
  }
}

final class _WindowMetric extends StatelessWidget {
  const _WindowMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

final class _CycleTile extends StatelessWidget {
  const _CycleTile({required this.observation, required this.onTap});

  final TrendCycleObservation observation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final balance = observation.balance;
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      key: ValueKey('cycle-history-${observation.cycle.start}'),
      contentPadding: EdgeInsets.zero,
      title: Text(
        l10n.trendCyclePeriod(
          _formatDate(context, observation.cycle.start),
          _formatDate(context, observation.cycle.endExclusive.addDays(-1)),
        ),
      ),
      subtitle: Text(
        '${l10n.trendHistoricalBudget}: '
        '${_formatMoney(context, observation.budget)} · '
        '${l10n.trendAllocated}: '
        '${_formatMoney(context, observation.allocatedExpenses)}'
        '${observation.trajectoryCredits.isPositive ? ' · ${l10n.trendRefundCredits}: ${_formatMoney(context, observation.trajectoryCredits)}' : ''}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatSignedMoney(context, balance),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: balance.isNegative ? colors.error : colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}

IconData _statusIcon(TrendAlertSeverity severity) => switch (severity) {
  TrendAlertSeverity.none => Icons.check_circle_outline,
  TrendAlertSeverity.vigilance => Icons.warning_amber_rounded,
  TrendAlertSeverity.strong => Icons.error_outline,
};

IconData _natureIcon(ExpenseNature? nature) => switch (nature) {
  ExpenseNature.necessary => Icons.check_circle_outline,
  ExpenseNature.pleasure => Icons.celebration_outlined,
  ExpenseNature.deferrable => Icons.schedule_outlined,
  ExpenseNature.unexpected => Icons.bolt_outlined,
  null => Icons.help_outline,
};

String _natureLabel(AppLocalizations l10n, ExpenseNature? nature) =>
    switch (nature) {
      ExpenseNature.necessary => l10n.expenseNatureNecessary,
      ExpenseNature.pleasure => l10n.expenseNaturePleasure,
      ExpenseNature.deferrable => l10n.expenseNatureDeferrable,
      ExpenseNature.unexpected => l10n.expenseNatureUnexpected,
      null => l10n.expenseNatureUnqualified,
    };

String _latestCycleMessage(BuildContext context, TrendProjection trends) {
  final l10n = AppLocalizations.of(context);
  final ratio = trends.latestOverspendRatio;
  if (ratio == null) return l10n.trendLatestOnTrack;
  return l10n.trendLatestOverspend(
    _formatMoney(context, trends.latestOverspend),
    _formatRatio(context, ratio),
  );
}

String _globalMessage(BuildContext context, TrendProjection trends) {
  final l10n = AppLocalizations.of(context);
  final ratio = trends.cumulativeNegativeRatio;
  if (ratio == null) {
    return l10n.trendGlobalPositive(
      _formatSignedMoney(context, trends.balance),
    );
  }
  return l10n.trendGlobalNegative(
    _formatSignedMoney(context, trends.balance),
    _formatRatio(context, ratio),
  );
}

String _formatMoney(BuildContext context, Money money) => formatMoneyExact(
  money,
  locale: Localizations.localeOf(context).toLanguageTag(),
);

String _formatSignedMoney(BuildContext context, Money money) {
  final formatted = _formatMoney(context, money.isNegative ? -money : money);
  return money.isNegative ? '−$formatted' : '+$formatted';
}

String _formatRatio(BuildContext context, TrendRatio ratio) =>
    NumberFormat.decimalPercentPattern(
      locale: Localizations.localeOf(context).toLanguageTag(),
      decimalDigits: ratio.basisPoints % 100 == 0 ? 0 : 2,
    ).format(ratio.basisPoints / 10000);

String _formatBasisPoints(BuildContext context, int basisPoints) =>
    NumberFormat.decimalPercentPattern(
      locale: Localizations.localeOf(context).toLanguageTag(),
      decimalDigits: basisPoints % 100 == 0 ? 0 : 2,
    ).format(basisPoints / 10000);

String _formatDate(BuildContext context, LocalDate date) =>
    MaterialLocalizations.of(
      context,
    ).formatShortDate(DateTime(date.year, date.month, date.day));
