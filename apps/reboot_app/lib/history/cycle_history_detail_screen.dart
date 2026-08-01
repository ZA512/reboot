import 'package:flutter/material.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

import '../formatting/exact_money_formatter.dart';
import '../l10n/app_localizations.dart';

/// Auditable breakdown of one completed REBOOT cycle.
final class CycleHistoryDetailScreen extends StatelessWidget {
  const CycleHistoryDetailScreen({
    required this.service,
    required this.observation,
    super.key,
  });

  final LocalRebootService service;
  final TrendCycleObservation observation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allocations = _allocationsForCycle(
      service.expenses,
      observation.cycle.start,
    );
    final refunds = _refundsForCycle(service.expenses, observation.cycle.start);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cycleHistoryDetailTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              l10n.cycleHistoryPeriod(
                _formatDate(context, observation.cycle.start),
                _formatDate(
                  context,
                  observation.cycle.endExclusive.addDays(-1),
                ),
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (!observation.cycle.includedInNormalTrends) ...[
              const SizedBox(height: 8),
              Text(
                l10n.cycleHistoryTransitionHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _AmountRow(
                      label: l10n.cycleHistoryBudget,
                      value: _formatMoney(context, observation.budget),
                    ),
                    _AmountRow(
                      label: l10n.cycleHistoryAllocated,
                      value:
                          '−${_formatMoney(context, observation.allocatedExpenses)}',
                    ),
                    if (observation.trajectoryCredits.isPositive)
                      _AmountRow(
                        label: l10n.cycleHistoryRefunds,
                        value:
                            '+${_formatMoney(context, observation.trajectoryCredits)}',
                      ),
                    const Divider(height: 20),
                    _AmountRow(
                      label: l10n.cycleHistoryBalance,
                      value: _formatSignedMoney(context, observation.balance),
                      valueColor: observation.balance.isNegative
                          ? colors.error
                          : colors.primary,
                      emphasized: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.cycleHistoryExpensesTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (allocations.isEmpty)
              Text(l10n.cycleHistoryNoExpense)
            else
              for (final item in allocations)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(item.expense.label),
                    subtitle: Text(
                      item.installmentCount == 1
                          ? l10n.cycleHistoryExpenseSource(
                              _formatMoney(context, item.expense.amount),
                              _formatDate(context, item.expense.purchaseDate),
                            )
                          : l10n.cycleHistoryInstallmentSource(
                              item.installmentIndex,
                              item.installmentCount,
                              _formatMoney(context, item.expense.amount),
                              _formatDate(context, item.expense.purchaseDate),
                            ),
                    ),
                    trailing: Text(
                      _formatMoney(context, item.allocation.amount),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
            if (refunds.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                l10n.cycleHistoryRefundsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              for (final item in refunds)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.replay_circle_filled),
                    title: Text(item.expense.label),
                    subtitle: Text(
                      l10n.cycleHistoryRefundSource(
                        _formatDate(context, item.refund.receivedDate),
                        _formatDate(context, item.expense.purchaseDate),
                      ),
                    ),
                    trailing: Text(
                      '+${_formatMoney(context, item.refund.amount)}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: colors.primary),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: emphasized
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                )
              : TextStyle(color: valueColor),
        ),
      ],
    ),
  );
}

final class _HistoricalAllocation {
  const _HistoricalAllocation({
    required this.expense,
    required this.allocation,
    required this.installmentIndex,
    required this.installmentCount,
  });

  final ProjectedExpense expense;
  final ExpenseAllocation allocation;
  final int installmentIndex;
  final int installmentCount;
}

final class _HistoricalRefund {
  const _HistoricalRefund({required this.expense, required this.refund});

  final ProjectedExpense expense;
  final ProjectedExpenseRefund refund;
}

List<_HistoricalAllocation> _allocationsForCycle(
  ExpenseLedger expenses,
  LocalDate cycleStart,
) {
  final result = <_HistoricalAllocation>[];
  for (final expense in expenses.activeExpenses) {
    final plan = expense.allocations ?? const <ExpenseAllocation>[];
    for (var index = 0; index < plan.length; index++) {
      if (plan[index].cycleStart == cycleStart) {
        result.add(
          _HistoricalAllocation(
            expense: expense,
            allocation: plan[index],
            installmentIndex: index + 1,
            installmentCount: plan.length,
          ),
        );
      }
    }
  }
  result.sort(
    (left, right) =>
        right.expense.recordedAtUtc.compareTo(left.expense.recordedAtUtc),
  );
  return List<_HistoricalAllocation>.unmodifiable(result);
}

List<_HistoricalRefund> _refundsForCycle(
  ExpenseLedger expenses,
  LocalDate cycleStart,
) {
  final result = <_HistoricalRefund>[];
  for (final expense in expenses.activeExpenses) {
    for (final refund in expense.activeRefunds) {
      if (refund.receiptCycleStart == cycleStart) {
        result.add(_HistoricalRefund(expense: expense, refund: refund));
      }
    }
  }
  result.sort(
    (left, right) =>
        right.refund.recordedAtUtc.compareTo(left.refund.recordedAtUtc),
  );
  return List<_HistoricalRefund>.unmodifiable(result);
}

String _formatMoney(BuildContext context, Money money) => formatMoneyExact(
  money,
  locale: Localizations.localeOf(context).toLanguageTag(),
);

String _formatSignedMoney(BuildContext context, Money money) {
  final magnitude = money.isNegative ? -money : money;
  return '${money.isNegative ? '−' : '+'}${_formatMoney(context, magnitude)}';
}

String _formatDate(BuildContext context, LocalDate date) =>
    MaterialLocalizations.of(
      context,
    ).formatShortDate(DateTime(date.year, date.month, date.day));
