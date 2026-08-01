import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

import '../financial_setup/euro_amount_parser.dart';
import '../formatting/exact_money_formatter.dart';
import '../l10n/app_localizations.dart';
import 'refund_controller.dart';

/// Records refunds against their original purchase without rewriting history.
final class RefundsScreen extends ConsumerWidget {
  const RefundsScreen({required this.service, required this.today, super.key});

  final LocalRebootService service;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mutation = ref.watch(refundControllerProvider);
    final expenses = service.expenses.activeExpenses.toList()
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.refundsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(l10n.refundsIntro),
            const SizedBox(height: 16),
            if (expenses.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(l10n.noRefundableExpense),
                ),
              )
            else
              for (final expense in expenses)
                _ExpenseRefundCard(
                  expense: expense,
                  busy: mutation.isLoading,
                  onRecord: expense.refundableAmount.isPositive
                      ? () => _record(context, ref, expense)
                      : null,
                  onReverse: (refund) =>
                      _reverse(context, ref, expense, refund),
                ),
            if (mutation.hasError) ...[
              const SizedBox(height: 8),
              Text(
                l10n.refundMutationError,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _record(
    BuildContext context,
    WidgetRef ref,
    ProjectedExpense expense,
  ) async {
    final draft = await showDialog<_RefundDraft>(
      context: context,
      builder: (_) => _RefundDialog(expense: expense, today: today),
    );
    if (draft == null || !context.mounted) return;
    final result = await ref
        .read(refundControllerProvider.notifier)
        .record(
          RecordExpenseRefundCommand(
            expenseId: expense.id,
            amount: draft.amount,
            receivedDate: draft.date,
          ),
        );
    if (result == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.restoresOriginalCycle
              ? l10n.refundRestoredOriginalCycle(
                  _formatMoney(context, result.refund.amount),
                )
              : l10n.refundImprovesTrajectory(
                  _formatMoney(context, result.refund.amount),
                ),
        ),
      ),
    );
  }

  Future<void> _reverse(
    BuildContext context,
    WidgetRef ref,
    ProjectedExpense expense,
    ProjectedExpenseRefund refund,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.reverseRefundTitle),
        content: Text(l10n.reverseRefundBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.reverseRefund),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(refundControllerProvider.notifier)
        .reverse(
          ReverseExpenseRefundCommand(
            expenseId: expense.id,
            refundEventId: refund.eventId,
            businessDate: today,
          ),
        );
  }
}

final class _ExpenseRefundCard extends StatelessWidget {
  const _ExpenseRefundCard({
    required this.expense,
    required this.busy,
    required this.onRecord,
    required this.onReverse,
  });

  final ProjectedExpense expense;
  final bool busy;
  final VoidCallback? onRecord;
  final ValueChanged<ProjectedExpenseRefund> onReverse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        l10n.refundExpenseSummary(
                          _formatMoney(context, expense.amount),
                          _formatDate(context, expense.purchaseDate),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: busy ? null : onRecord,
                  child: Text(
                    onRecord == null ? l10n.fullyRefunded : l10n.recordRefund,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.refundableRemaining(
                _formatMoney(context, expense.refundableAmount),
              ),
            ),
            for (final refund in expense.refunds.reversed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  refund.isReversed ? Icons.undo : Icons.replay_circle_filled,
                ),
                title: Text(
                  l10n.refundHistoryLine(
                    _formatMoney(context, refund.amount),
                    _formatDate(context, refund.receivedDate),
                  ),
                ),
                subtitle: refund.isReversed ? Text(l10n.reversedRefund) : null,
                trailing: refund.isReversed
                    ? null
                    : IconButton(
                        tooltip: l10n.reverseRefund,
                        onPressed: busy ? null : () => onReverse(refund),
                        icon: const Icon(Icons.undo),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _RefundDraft {
  const _RefundDraft(this.amount, this.date);

  final Money amount;
  final LocalDate date;
}

final class _RefundDialog extends StatefulWidget {
  const _RefundDialog({required this.expense, required this.today});

  final ProjectedExpense expense;
  final LocalDate today;

  @override
  State<_RefundDialog> createState() => _RefundDialogState();
}

final class _RefundDialogState extends State<_RefundDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late LocalDate _date;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: formatMoneyInputExact(
        widget.expense.refundableAmount,
        alwaysShowFraction: true,
      ),
    );
    _date = widget.today;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.recordRefundFor(widget.expense.label)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l10n.refundAmount),
              validator: (value) {
                final parsed = parsePositiveEuroAmount(value ?? '');
                if (parsed == null ||
                    parsed.compareTo(widget.expense.refundableAmount) > 0) {
                  return l10n.invalidRefundAmount(
                    _formatMoney(context, widget.expense.refundableAmount),
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.refundDate),
              subtitle: Text(_formatDate(context, _date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _chooseDate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _RefundDraft(parsePositiveEuroAmount(_amount.text)!, _date),
            );
          },
          child: Text(l10n.recordRefund),
        ),
      ],
    );
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(_date.year, _date.month, _date.day),
      firstDate: DateTime(
        widget.expense.purchaseDate.year,
        widget.expense.purchaseDate.month,
        widget.expense.purchaseDate.day,
      ),
      lastDate: DateTime(
        widget.today.year,
        widget.today.month,
        widget.today.day,
      ),
    );
    if (selected != null) {
      setState(() => _date = LocalDate.fromDateTime(selected));
    }
  }
}

String _formatMoney(BuildContext context, Money money) => formatMoneyExact(
  money,
  locale: Localizations.localeOf(context).toLanguageTag(),
);

String _formatDate(BuildContext context, LocalDate date) =>
    MaterialLocalizations.of(
      context,
    ).formatShortDate(DateTime(date.year, date.month, date.day));
