import 'package:flutter/material.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

import '../formatting/exact_money_formatter.dart';
import '../l10n/app_localizations.dart';

/// Read-only view of expense allocations already committed to future cycles.
final class FutureCommitmentsScreen extends StatelessWidget {
  const FutureCommitmentsScreen({
    required this.service,
    required this.today,
    super.key,
  });

  final LocalRebootService service;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final projection = service.buildRollingBudget(today);
    final committedCycles = projection.cycles
        .where(
          (cycle) =>
              cycle.cycle.start.isAfter(today) &&
              cycle.allocatedExpenses.isPositive,
        )
        .toList(growable: false);
    final total = committedCycles.fold(
      Money.zero(Currency.eur),
      (sum, cycle) => sum + cycle.allocatedExpenses,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.futureCommitmentsTitle)),
      body: SafeArea(
        child: committedCycles.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.noFutureCommitments,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text(l10n.futureCommitmentsIntro),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.event_note_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.futureCommitmentsTotal),
                                Text(
                                  _formatMoney(context, total),
                                  key: const ValueKey(
                                    'future-commitments-total',
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  l10n.futureCommitmentsCycleCount(
                                    committedCycles.length,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final cycle in committedCycles) ...[
                    _CommittedCycleCard(
                      cycle: cycle,
                      allocations: _allocationsForCycle(
                        service.expenses,
                        cycle.cycle.start,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
      ),
    );
  }
}

final class _CommittedCycleCard extends StatelessWidget {
  const _CommittedCycleCard({required this.cycle, required this.allocations});

  final ProjectedCycleFinances cycle;
  final List<_FutureAllocation> allocations;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final heavilyCommitted =
        cycle.allocatedExpenses.exactMinorUnits * BigInt.two >
        cycle.budget.exactMinorUnits;
    return Card(
      key: ValueKey('future-cycle-${cycle.cycle.start}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.futureCommitmentPeriod(
                _formatDate(context, cycle.cycle.start),
                _formatDate(context, cycle.cycle.endExclusive.addDays(-1)),
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _AmountRow(
              label: l10n.futureCycleBudget,
              value: _formatMoney(context, cycle.budget),
            ),
            _AmountRow(
              label: l10n.futureCycleCommitted,
              value: '−${_formatMoney(context, cycle.allocatedExpenses)}',
            ),
            _AmountRow(
              label: l10n.futureCycleAvailable,
              value: _formatSignedMoney(context, cycle.remaining),
              valueColor: cycle.remaining.isNegative ? colors.error : null,
              emphasized: true,
            ),
            if (heavilyCommitted) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: colors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.futureCommitmentStrongWarning,
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            for (final item in allocations)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(item.expense.label),
                subtitle: Text(
                  l10n.futureCommitmentSource(
                    _formatMoney(context, item.expense.amount),
                    _formatDate(context, item.expense.purchaseDate),
                  ),
                ),
                trailing: Text(
                  _formatMoney(context, item.allocation.amount),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
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
    padding: const EdgeInsets.symmetric(vertical: 3),
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

final class _FutureAllocation {
  const _FutureAllocation({required this.expense, required this.allocation});

  final ProjectedExpense expense;
  final ExpenseAllocation allocation;
}

List<_FutureAllocation> _allocationsForCycle(
  ExpenseLedger expenses,
  LocalDate cycleStart,
) {
  final result = <_FutureAllocation>[];
  for (final expense in expenses.activeExpenses) {
    for (final allocation
        in expense.allocations ?? const <ExpenseAllocation>[]) {
      if (allocation.cycleStart == cycleStart) {
        result.add(_FutureAllocation(expense: expense, allocation: allocation));
      }
    }
  }
  result.sort(
    (left, right) =>
        right.expense.recordedAtUtc.compareTo(left.expense.recordedAtUtc),
  );
  return List<_FutureAllocation>.unmodifiable(result);
}

String _formatMoney(BuildContext context, Money money) => formatMoneyExact(
  money,
  locale: Localizations.localeOf(context).toLanguageTag(),
);

String _formatSignedMoney(BuildContext context, Money money) {
  final magnitude = money.isNegative ? -money : money;
  return '${money.isNegative ? '−' : ''}${_formatMoney(context, magnitude)}';
}

String _formatDate(BuildContext context, LocalDate date) =>
    MaterialLocalizations.of(
      context,
    ).formatShortDate(DateTime(date.year, date.month, date.day));
