import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../formatting/exact_money_formatter.dart';
import '../infrastructure/device_context_providers.dart';
import '../l10n/app_localizations.dart';
import 'cash_flow_editor_screen.dart';
import 'financial_setup_controller.dart';

/// Builds the initial income and outflow assumptions before weekly budgeting.
final class FinancialSetupScreen extends ConsumerStatefulWidget {
  /// Creates an empty, all-or-nothing financial setup draft.
  const FinancialSetupScreen({super.key});

  @override
  ConsumerState<FinancialSetupScreen> createState() =>
      _FinancialSetupScreenState();
}

final class _FinancialSetupScreenState
    extends ConsumerState<FinancialSetupScreen> {
  final List<CashFlowDefinition> _definitions = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deviceContext = ref.watch(onboardingDeviceContextProvider);
    final submission = ref.watch(financialSetupControllerProvider);
    final businessDate = switch (deviceContext) {
      AsyncData(:final value) => value.localDate,
      _ => null,
    };
    final incomes = _definitions
        .where((flow) => flow.direction == CashFlowDirection.income)
        .toList(growable: false);
    final outflows = _definitions
        .where((flow) => flow.direction == CashFlowDirection.outflow)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          children: [
            Text(
              l10n.financialSetupTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(l10n.financialSetupIntro),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.financialSetupTip)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _FlowSection(
              icon: Icons.south_west,
              title: l10n.incomeSectionTitle,
              description: l10n.incomeSectionBody,
              definitions: incomes,
              suggestions: _incomeSuggestions(l10n),
              enabled: businessDate != null && !submission.isLoading,
              onAdd: (title) => _openEditor(
                direction: CashFlowDirection.income,
                title: title,
                businessDate: businessDate!,
              ),
              onDelete: _deleteDefinition,
            ),
            const SizedBox(height: 28),
            _FlowSection(
              icon: Icons.north_east,
              title: l10n.outflowSectionTitle,
              description: l10n.outflowSectionBody,
              definitions: outflows,
              suggestions: _outflowSuggestions(l10n),
              enabled: businessDate != null && !submission.isLoading,
              onAdd: (title) => _openEditor(
                direction: CashFlowDirection.outflow,
                title: title,
                businessDate: businessDate!,
              ),
              onDelete: _deleteDefinition,
            ),
            if (deviceContext.hasError) ...[
              const SizedBox(height: 20),
              _ErrorNotice(message: l10n.timeZoneError),
            ],
            if (submission.hasError) ...[
              const SizedBox(height: 20),
              _ErrorNotice(message: l10n.financialSetupError),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed:
                  businessDate == null ||
                      incomes.isEmpty ||
                      outflows.isEmpty ||
                      submission.isLoading
                  ? null
                  : () => ref
                        .read(financialSetupControllerProvider.notifier)
                        .submit(
                          definitions: List.unmodifiable(_definitions),
                          businessDate: businessDate,
                        ),
              child: submission.isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(l10n.financialSetupSaving),
                      ],
                    )
                  : Text(l10n.confirmFinancialSetup),
            ),
            if (incomes.isEmpty || outflows.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.financialSetupMinimum,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor({
    required CashFlowDirection direction,
    required String title,
    required LocalDate businessDate,
  }) async {
    final definition = await Navigator.of(context).push<CashFlowDefinition>(
      MaterialPageRoute(
        builder: (context) => CashFlowEditorScreen(
          direction: direction,
          initialTitle: title,
          businessDate: businessDate,
        ),
      ),
    );
    if (definition != null && mounted) {
      setState(() => _definitions.add(definition));
    }
  }

  void _deleteDefinition(CashFlowDefinition definition) {
    setState(() => _definitions.remove(definition));
  }
}

final class _FlowSection extends StatelessWidget {
  const _FlowSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.definitions,
    required this.suggestions,
    required this.enabled,
    required this.onAdd,
    required this.onDelete,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<CashFlowDefinition> definitions;
  final List<String> suggestions;
  final bool enabled;
  final ValueChanged<String> onAdd;
  final ValueChanged<CashFlowDefinition> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(description),
        if (definitions.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final definition in definitions)
            Card(
              child: ListTile(
                title: Text(definition.title),
                subtitle: Text(_definitionSummary(context, definition)),
                trailing: IconButton(
                  tooltip: l10n.deleteDraft,
                  onPressed: enabled ? () => onDelete(definition) : null,
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
        ],
        const SizedBox(height: 12),
        Text(l10n.suggestionsLabel),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final suggestion in suggestions)
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: Text(suggestion),
                onPressed: enabled ? () => onAdd(suggestion) : null,
              ),
          ],
        ),
      ],
    );
  }
}

final class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            style: TextStyle(color: colors.onErrorContainer),
          ),
        ),
      ),
    );
  }
}

String _definitionSummary(BuildContext context, CashFlowDefinition definition) {
  final l10n = AppLocalizations.of(context);
  final amount = definition.variableStrategy == VariableEstimateStrategy.custom
      ? definition.customAmountPerOccurrence!
      : definition.referenceAmountPerOccurrence;
  final formatted = formatMoneyExact(
    amount,
    locale: Localizations.localeOf(context).toLanguageTag(),
  );
  final frequency =
      switch ((definition.schedule as RecurringSchedule).frequency) {
        RecurrenceFrequency.weekly => l10n.frequencyWeekly,
        RecurrenceFrequency.everyFourWeeks => l10n.frequencyEveryFourWeeks,
        RecurrenceFrequency.monthly => l10n.frequencyMonthly,
        RecurrenceFrequency.quarterly => l10n.frequencyQuarterly,
        RecurrenceFrequency.semiAnnual => l10n.frequencySemiAnnual,
        RecurrenceFrequency.annual => l10n.frequencyAnnual,
      };
  final behavior = definition.behavior == AmountBehavior.fixed
      ? l10n.fixedAmount
      : l10n.variableAmount;
  return l10n.cashFlowSummary(formatted, frequency, behavior);
}

List<String> _incomeSuggestions(AppLocalizations l10n) => [
  l10n.suggestionSalary1,
  l10n.suggestionSalary2,
  l10n.suggestionBenefit1,
  l10n.suggestionBenefit2,
  l10n.suggestionPension,
  l10n.suggestionOtherIncome,
];

List<String> _outflowSuggestions(AppLocalizations l10n) => [
  l10n.suggestionHousing,
  l10n.suggestionElectricity,
  l10n.suggestionHeating,
  l10n.suggestionWater,
  l10n.suggestionInsurance,
  l10n.suggestionTelecom,
  l10n.suggestionLoans,
  l10n.suggestionTransport,
  l10n.suggestionChildcare,
  l10n.suggestionTaxes,
  l10n.suggestionOtherOutflow,
];
