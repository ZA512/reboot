import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

import '../financial_setup/euro_amount_parser.dart';
import '../l10n/app_localizations.dart';
import '../reserves/reserve_controller.dart';
import 'quick_expense_controller.dart';

enum _ExpenseFunding { weeklyBudget, reserve }

/// Minimal real-time expense entry for the weekly budget.
final class QuickExpenseScreen extends ConsumerStatefulWidget {
  /// Creates the form with the device-local date selected.
  const QuickExpenseScreen({
    required this.service,
    required this.today,
    this.initialReserveId,
    super.key,
  });

  final LocalRebootService service;
  final LocalDate today;

  /// Opens directly on one reserve when launched from reserve management.
  final EntityId? initialReserveId;

  @override
  ConsumerState<QuickExpenseScreen> createState() => _QuickExpenseScreenState();
}

final class _QuickExpenseScreenState extends ConsumerState<QuickExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _labelController = TextEditingController();
  late LocalDate _purchaseDate;
  int _cycleCount = 1;
  ExpenseNature? _nature;
  late _ExpenseFunding _funding;
  EntityId? _reserveId;

  @override
  void initState() {
    super.initState();
    _purchaseDate = widget.today;
    _reserveId = widget.initialReserveId;
    _funding = _reserveId == null
        ? _ExpenseFunding.weeklyBudget
        : _ExpenseFunding.reserve;
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
    final reserveMutation = ref.watch(reserveControllerProvider);
    final reserves = widget.service.reserves.reserves.values.toList()
      ..sort((left, right) => left.name.compareTo(right.name));
    final suggestions = widget.service.expenseSuggestions();
    final selectedReserve = _selectedReserve(reserves);
    final amount = parsePositiveEuroAmount(_amountController.text);
    final warning = amount == null || _funding == _ExpenseFunding.reserve
        ? false
        : _exceedsHalfBudget(amount, _cycleCount);
    final insufficientReserve =
        _funding == _ExpenseFunding.reserve &&
        amount != null &&
        selectedReserve != null &&
        amount.minorUnits > selectedReserve.balance.minorUnits;
    final busy = mutation.isLoading || reserveMutation.isLoading;
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
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.expenseSuggestionsTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final suggestion in suggestions)
                      ActionChip(
                        avatar: const Icon(Icons.history, size: 18),
                        label: Text(suggestion.label.trim()),
                        onPressed: busy
                            ? null
                            : () => _selectSuggestion(suggestion),
                      ),
                  ],
                ),
              ],
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
                onTap: busy ? null : _chooseDate,
              ),
              const Divider(),
              Text(
                l10n.expenseFundingTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<_ExpenseFunding>(
                segments: [
                  ButtonSegment(
                    value: _ExpenseFunding.weeklyBudget,
                    icon: const Icon(Icons.calendar_view_week_outlined),
                    label: Text(l10n.weeklyBudgetFunding),
                  ),
                  ButtonSegment(
                    value: _ExpenseFunding.reserve,
                    icon: const Icon(Icons.savings_outlined),
                    label: Text(l10n.reserveFunding),
                  ),
                ],
                selected: {_funding},
                onSelectionChanged: busy || reserves.isEmpty
                    ? null
                    : (selection) => setState(() {
                        _funding = selection.single;
                        _reserveId ??= reserves.first.id;
                      }),
              ),
              if (reserves.isEmpty) ...[
                const SizedBox(height: 8),
                Text(l10n.createReserveBeforeUse),
              ],
              if (_funding == _ExpenseFunding.reserve) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<EntityId>(
                  key: const ValueKey('expense-reserve'),
                  initialValue: selectedReserve?.id,
                  decoration: InputDecoration(
                    labelText: l10n.selectReserve,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final reserve in reserves)
                      DropdownMenuItem(
                        value: reserve.id,
                        child: Text(
                          '${reserve.name} · '
                          '${_formatMoney(context, reserve.balance)}',
                        ),
                      ),
                  ],
                  validator: (value) =>
                      value == null ? l10n.requiredField : null,
                  onChanged: busy
                      ? null
                      : (value) => setState(() => _reserveId = value),
                ),
                const SizedBox(height: 8),
                Text(l10n.reserveExpenseNoWeeklyImpact),
                if (insufficientReserve) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.insufficientReserveBalance(
                      _formatMoney(context, selectedReserve.balance),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
              if (_funding == _ExpenseFunding.weeklyBudget) ...[
                const Divider(),
                Text(
                  l10n.expenseNatureTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(l10n.expenseNatureHelp),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final nature in ExpenseNature.values)
                      ChoiceChip(
                        key: ValueKey('expense-nature-${nature.name}'),
                        label: Text(_natureLabel(l10n, nature)),
                        selected: _nature == nature,
                        onSelected: busy
                            ? null
                            : (selected) => setState(
                                () => _nature = selected ? nature : null,
                              ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _nature == null
                      ? l10n.expenseNatureSkipped
                      : l10n.expenseNatureSelected(
                          _natureLabel(l10n, _nature!),
                        ),
                  style: Theme.of(context).textTheme.bodySmall,
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
                  onChanged: busy
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
              ],
              if (mutation.hasError || reserveMutation.hasError) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.quickExpenseError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const ValueKey('save-expense'),
                onPressed: busy || insufficientReserve ? null : _submit,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(busy ? l10n.quickExpenseSaving : l10n.saveExpense),
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
    final amount = parsePositiveEuroAmount(_amountController.text)!;
    if (_funding == _ExpenseFunding.reserve) {
      final reserve = widget.service.reserves.reserves[_reserveId];
      if (reserve == null || amount.minorUnits > reserve.balance.minorUnits) {
        return;
      }
      if (reserve.kind == ReserveKind.real &&
          !await _confirmRealReserveTransfer(reserve, amount)) {
        return;
      }
      final accepted = await ref
          .read(reserveControllerProvider.notifier)
          .use(
            UseReserveCommand(
              reserveId: reserve.id,
              amount: amount,
              label: _labelController.text,
              purchaseDate: _purchaseDate,
            ),
          );
      if (accepted && mounted) Navigator.of(context).pop();
      return;
    }
    final accepted = await ref
        .read(quickExpenseControllerProvider.notifier)
        .record(
          RecordExpenseCommand(
            amount: amount,
            label: _labelController.text,
            purchaseDate: _purchaseDate,
            allocationCycleCount: _cycleCount,
            nature: _nature,
          ),
        );
    if (accepted && mounted) Navigator.of(context).pop();
  }

  ProjectedReserve? _selectedReserve(List<ProjectedReserve> reserves) {
    if (reserves.isEmpty) return null;
    return reserves.firstWhere(
      (reserve) => reserve.id == _reserveId,
      orElse: () => reserves.first,
    );
  }

  void _selectSuggestion(ExpenseLabelSuggestion suggestion) {
    setState(() {
      _labelController.text = suggestion.label.trim();
      _labelController.selection = TextSelection.collapsed(
        offset: _labelController.text.length,
      );
      _nature = suggestion.nature;
    });
  }

  Future<bool> _confirmRealReserveTransfer(
    ProjectedReserve reserve,
    Money amount,
  ) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.realReserveTransferTitle),
            content: Text(
              l10n.realReserveTransferBody(
                _formatMoney(context, amount),
                reserve.name,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.confirmReserveExpense),
              ),
            ],
          ),
        ) ??
        false;
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

String _natureLabel(AppLocalizations l10n, ExpenseNature nature) =>
    switch (nature) {
      ExpenseNature.necessary => l10n.expenseNatureNecessary,
      ExpenseNature.pleasure => l10n.expenseNaturePleasure,
      ExpenseNature.deferrable => l10n.expenseNatureDeferrable,
      ExpenseNature.unexpected => l10n.expenseNatureUnexpected,
    };

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
