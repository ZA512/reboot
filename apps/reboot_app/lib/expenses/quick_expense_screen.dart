import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../financial_setup/euro_amount_parser.dart';
import '../l10n/app_localizations.dart';
import 'quick_expense_controller.dart';

/// Minimal real-time expense entry for the weekly budget.
final class QuickExpenseScreen extends ConsumerStatefulWidget {
  /// Creates the form with the device-local date selected.
  const QuickExpenseScreen({
    required this.service,
    required this.today,
    super.key,
  });

  final LocalRebootService service;
  final LocalDate today;

  @override
  ConsumerState<QuickExpenseScreen> createState() => _QuickExpenseScreenState();
}

final class _QuickExpenseScreenState extends ConsumerState<QuickExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _labelController = TextEditingController();
  late LocalDate _purchaseDate;
  int _cycleCount = 1;

  @override
  void initState() {
    super.initState();
    _purchaseDate = widget.today;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mutation = ref.watch(quickExpenseControllerProvider);
    final amount = parsePositiveEuroAmount(_amountController.text);
    final warning = amount == null
        ? false
        : _exceedsHalfBudget(amount, _cycleCount);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.quickExpenseTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            children: [
              Text(l10n.quickExpenseIntro),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('expense-amount'),
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.expenseAmountLabel,
                  suffixText: '€',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    parsePositiveEuroAmount(value ?? '') == null
                    ? l10n.invalidPositiveAmount
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('expense-label'),
                controller: _labelController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.expenseLabel,
                  hintText: l10n.expenseLabelHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.requiredField
                    : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(l10n.expenseDate),
                subtitle: Text(_formatDate(context, _purchaseDate)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: mutation.isLoading ? null : _chooseDate,
              ),
              const Divider(),
              Text(
                l10n.expenseAllocationTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(l10n.expenseAllocationHelp),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: const ValueKey('expense-cycle-count'),
                initialValue: _cycleCount,
                decoration: InputDecoration(
                  labelText: l10n.expenseCycleCount,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (var count = 1; count <= 12; count++)
                    DropdownMenuItem(
                      value: count,
                      child: Text(l10n.cycleCount(count)),
                    ),
                ],
                onChanged: mutation.isLoading
                    ? null
                    : (value) => setState(() => _cycleCount = value ?? 1),
              ),
              if (amount != null && _cycleCount > 1) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.expenseAllocationPreview(
                        _formatMoney(
                          context,
                          _regularPart(amount, _cycleCount),
                        ),
                        _cycleCount - 1,
                        _formatMoney(context, _lastPart(amount, _cycleCount)),
                      ),
                    ),
                  ),
                ),
              ],
              if (warning) ...[
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l10n.expenseCommitmentWarning)),
                      ],
                    ),
                  ),
                ),
              ],
              if (mutation.hasError) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.quickExpenseError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const ValueKey('save-expense'),
                onPressed: mutation.isLoading ? null : _submit,
                icon: mutation.isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  mutation.isLoading
                      ? l10n.quickExpenseSaving
                      : l10n.saveExpense,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseDate() async {
    final household = widget.service.configuration.household!;
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(
        _purchaseDate.year,
        _purchaseDate.month,
        _purchaseDate.day,
      ),
      firstDate: DateTime(
        household.firstCycleStart.year,
        household.firstCycleStart.month,
        household.firstCycleStart.day,
      ),
      lastDate: DateTime(
        widget.today.year,
        widget.today.month,
        widget.today.day,
      ),
    );
    if (selected != null) {
      setState(() => _purchaseDate = LocalDate.fromDateTime(selected));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final accepted = await ref
        .read(quickExpenseControllerProvider.notifier)
        .record(
          RecordExpenseCommand(
            amount: parsePositiveEuroAmount(_amountController.text)!,
            label: _labelController.text,
            purchaseDate: _purchaseDate,
            allocationCycleCount: _cycleCount,
          ),
        );
    if (accepted && mounted) Navigator.of(context).pop();
  }

  bool _exceedsHalfBudget(Money amount, int count) {
    final projection = widget.service.buildRollingBudget(_purchaseDate);
    final regular = _regularPart(amount, count);
    final last = _lastPart(amount, count);
    for (var index = 0; index < count; index++) {
      final cycle = projection.cycles[index];
      final proposed = index == count - 1 ? last : regular;
      final committedMinorUnits =
          cycle.allocatedExpenses.minorUnits + proposed.minorUnits;
      if (committedMinorUnits * 2 > cycle.budget.minorUnits) {
        return true;
      }
    }
    return false;
  }
}

Money _regularPart(Money amount, int count) =>
    Money.fromMinorUnits(amount.minorUnits ~/ count, amount.currency);

Money _lastPart(Money amount, int count) {
  final regular = amount.minorUnits ~/ count;
  return Money.fromMinorUnits(
    amount.minorUnits - regular * (count - 1),
    amount.currency,
  );
}

String _formatMoney(BuildContext context, Money money) =>
    NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      name: money.currency.code,
      decimalDigits: 2,
    ).format(money.minorUnits / money.currency.minorUnitsPerMajorUnit);

String _formatDate(BuildContext context, LocalDate date) =>
    MaterialLocalizations.of(
      context,
    ).formatFullDate(DateTime(date.year, date.month, date.day));
