import 'package:flutter/material.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../l10n/app_localizations.dart';
import 'euro_amount_parser.dart';

/// Full-screen editor for one exact recurring financial assumption.
final class CashFlowEditorScreen extends StatefulWidget {
  /// Creates an editor prefilled from a localized suggestion.
  const CashFlowEditorScreen({
    required this.direction,
    required this.initialTitle,
    required this.businessDate,
    super.key,
  });

  /// Money entering or leaving the household trajectory.
  final CashFlowDirection direction;

  /// Editable suggestion selected by the user.
  final String initialTitle;

  /// Device-local date used as the default reference and confirmation date.
  final LocalDate businessDate;

  @override
  State<CashFlowEditorScreen> createState() => _CashFlowEditorScreenState();
}

final class _CashFlowEditorScreenState extends State<CashFlowEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final _amountController = TextEditingController();
  final _customAmountController = TextEditingController();
  AmountBehavior _behavior = AmountBehavior.fixed;
  VariableEstimateStrategy _strategy = VariableEstimateStrategy.prudent;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  late LocalDate _referenceDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _referenceDate = widget.businessDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isVariable = _behavior == AmountBehavior.variable;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.direction == CashFlowDirection.income
              ? l10n.addIncomeTitle
              : l10n.addOutflowTitle,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            children: [
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.cashFlowTitleLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.requiredField
                    : null,
              ),
              const SizedBox(height: 20),
              Text(l10n.amountBehaviorLabel),
              const SizedBox(height: 8),
              SegmentedButton<AmountBehavior>(
                segments: [
                  ButtonSegment(
                    value: AmountBehavior.fixed,
                    label: Text(l10n.fixedAmount),
                  ),
                  ButtonSegment(
                    value: AmountBehavior.variable,
                    label: Text(l10n.variableAmount),
                  ),
                ],
                selected: {_behavior},
                onSelectionChanged: (selection) {
                  setState(() => _behavior = selection.single);
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: isVariable
                      ? l10n.averageAmountLabel
                      : l10n.amountPerOccurrenceLabel,
                  suffixText: 'EUR',
                  helperText: isVariable
                      ? l10n.averageAmountHelp
                      : l10n.fixedAmountHelp,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    parsePositiveEuroAmount(value ?? '') == null
                    ? l10n.invalidPositiveAmount
                    : null,
              ),
              if (isVariable) ...[
                const SizedBox(height: 20),
                DropdownButtonFormField<VariableEstimateStrategy>(
                  initialValue: _strategy,
                  decoration: InputDecoration(
                    labelText: l10n.estimateStrategyLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final strategy in VariableEstimateStrategy.values)
                      DropdownMenuItem(
                        value: strategy,
                        child: Text(_strategyLabel(l10n, strategy)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _strategy = value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _strategyHelp(l10n),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_strategy == VariableEstimateStrategy.custom) ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _customAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.customAmountLabel,
                      suffixText: 'EUR',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        parsePositiveEuroAmount(value ?? '') == null
                        ? l10n.invalidPositiveAmount
                        : null,
                  ),
                ],
              ],
              const SizedBox(height: 20),
              DropdownButtonFormField<RecurrenceFrequency>(
                initialValue: _frequency,
                decoration: InputDecoration(
                  labelText: l10n.frequencyLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final frequency in RecurrenceFrequency.values)
                    DropdownMenuItem(
                      value: frequency,
                      child: Text(_frequencyLabel(l10n, frequency)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _frequency = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                leading: const Icon(Icons.event),
                title: Text(l10n.referenceDateLabel),
                subtitle: Text(_formatDate(context, _referenceDate)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: _pickReferenceDate,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.referenceDateHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l10n.irregularFrequencyTip)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                child: Text(l10n.addThisCashFlow),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickReferenceDate() async {
    final initial = DateTime(
      _referenceDate.year,
      _referenceDate.month,
      _referenceDate.day,
    );
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(widget.businessDate.year - 10),
      lastDate: DateTime(widget.businessDate.year + 10, 12, 31),
    );
    if (selected != null) {
      setState(() => _referenceDate = LocalDate.fromDateTime(selected));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final referenceAmount = parsePositiveEuroAmount(_amountController.text)!;
    final schedule = RecurringSchedule(
      firstOccurrence: _referenceDate,
      frequency: _frequency,
    );
    final definition = switch (_behavior) {
      AmountBehavior.fixed => CashFlowDefinition.fixed(
        title: _titleController.text,
        direction: widget.direction,
        schedule: schedule,
        amountPerOccurrence: referenceAmount,
        lastConfirmedOn: widget.businessDate,
      ),
      AmountBehavior.variable => CashFlowDefinition.variable(
        title: _titleController.text,
        direction: widget.direction,
        schedule: schedule,
        historicalAveragePerOccurrence: referenceAmount,
        strategy: _strategy,
        customAmountPerOccurrence: _strategy == VariableEstimateStrategy.custom
            ? parsePositiveEuroAmount(_customAmountController.text)
            : null,
        lastConfirmedOn: widget.businessDate,
      ),
    };
    Navigator.of(context).pop(definition);
  }

  String _strategyHelp(AppLocalizations l10n) {
    return switch (_strategy) {
      VariableEstimateStrategy.prudent =>
        widget.direction == CashFlowDirection.income
            ? l10n.prudentIncomeHelp
            : l10n.prudentOutflowHelp,
      VariableEstimateStrategy.balanced => l10n.balancedHelp,
      VariableEstimateStrategy.custom => l10n.customStrategyHelp,
    };
  }
}

String _formatDate(BuildContext context, LocalDate date) {
  return MaterialLocalizations.of(
    context,
  ).formatFullDate(DateTime(date.year, date.month, date.day));
}

String _strategyLabel(
  AppLocalizations l10n,
  VariableEstimateStrategy strategy,
) {
  return switch (strategy) {
    VariableEstimateStrategy.prudent => l10n.strategyPrudent,
    VariableEstimateStrategy.balanced => l10n.strategyBalanced,
    VariableEstimateStrategy.custom => l10n.strategyCustom,
  };
}

String _frequencyLabel(AppLocalizations l10n, RecurrenceFrequency frequency) {
  return switch (frequency) {
    RecurrenceFrequency.weekly => l10n.frequencyWeekly,
    RecurrenceFrequency.everyFourWeeks => l10n.frequencyEveryFourWeeks,
    RecurrenceFrequency.monthly => l10n.frequencyMonthly,
    RecurrenceFrequency.quarterly => l10n.frequencyQuarterly,
    RecurrenceFrequency.semiAnnual => l10n.frequencySemiAnnual,
    RecurrenceFrequency.annual => l10n.frequencyAnnual,
  };
}
