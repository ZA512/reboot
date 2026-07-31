import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

import '../l10n/app_localizations.dart';
import 'cash_flow_editor_screen.dart';
import 'cash_flow_management_controller.dart';

/// Reviews and changes the assumptions that determine future weekly budgets.
final class CashFlowManagementScreen extends ConsumerWidget {
  const CashFlowManagementScreen({
    required this.service,
    required this.today,
    super.key,
  });

  final LocalRebootService service;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mutation = ref.watch(cashFlowManagementControllerProvider);
    final household = service.configuration.household!;
    final effectiveCycle = service.nextConfigurationCycleStart(today);
    final currentCycle = today.isBefore(household.firstCycleStart)
        ? household.firstCycleStart
        : household.cycleContaining(today).start;
    final flows =
        service.configuration.cashFlows.values
            .where(
              (flow) =>
                  flow.definitionForCycleStarting(currentCycle) != null ||
                  flow.definitionForCycleStarting(effectiveCycle) != null,
            )
            .toList()
          ..sort((left, right) {
            final leftDefinition = _displayedDefinition(
              left,
              currentCycle,
              effectiveCycle,
            );
            final rightDefinition = _displayedDefinition(
              right,
              currentCycle,
              effectiveCycle,
            );
            final direction = leftDefinition.direction.index.compareTo(
              rightDefinition.direction.index,
            );
            return direction != 0
                ? direction
                : leftDefinition.title.toLowerCase().compareTo(
                    rightDefinition.title.toLowerCase(),
                  );
          });
    final incomes = flows
        .where(
          (flow) =>
              _displayedDefinition(
                flow,
                currentCycle,
                effectiveCycle,
              ).direction ==
              CashFlowDirection.income,
        )
        .toList(growable: false);
    final outflows = flows
        .where(
          (flow) =>
              _displayedDefinition(
                flow,
                currentCycle,
                effectiveCycle,
              ).direction ==
              CashFlowDirection.outflow,
        )
        .toList(growable: false);
    final currentBudget = service.weeklyBudgetForCycleStarting(currentCycle);
    final futureProjection = service.buildAnnualBudget(effectiveCycle);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.assumptionsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Text(l10n.assumptionsIntro),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.assumptionsEffectiveDate(
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
                            amount: currentBudget,
                          ),
                        ),
                        const Icon(Icons.arrow_forward),
                        Expanded(
                          child: _BudgetValue(
                            key: const ValueKey('future-weekly-budget'),
                            label: l10n.futureWeeklyBudget,
                            amount: service.weeklyBudgetForCycleStarting(
                              effectiveCycle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (futureProjection.deficit.isPositive) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.assumptionsDeficitWarning(
                          _formatMoney(context, futureProjection.deficit),
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
            if (mutation.hasError) ...[
              const SizedBox(height: 12),
              Text(
                l10n.assumptionsMutationError,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            _AssumptionSection(
              title: l10n.incomeSectionTitle,
              icon: Icons.south_west,
              flows: incomes,
              currentCycle: currentCycle,
              effectiveCycle: effectiveCycle,
              enabled: !mutation.isLoading,
              onAdd: () => _add(context, ref, CashFlowDirection.income),
              onEdit: (flow) => _edit(context, ref, flow),
              onDelete: (flow) => _delete(context, ref, flow, effectiveCycle),
            ),
            const SizedBox(height: 24),
            _AssumptionSection(
              title: l10n.outflowSectionTitle,
              icon: Icons.north_east,
              flows: outflows,
              currentCycle: currentCycle,
              effectiveCycle: effectiveCycle,
              enabled: !mutation.isLoading,
              onAdd: () => _add(context, ref, CashFlowDirection.outflow),
              onEdit: (flow) => _edit(context, ref, flow),
              onDelete: (flow) => _delete(context, ref, flow, effectiveCycle),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    CashFlowDirection direction,
  ) async {
    final definition = await Navigator.of(context).push<CashFlowDefinition>(
      MaterialPageRoute(
        builder: (_) => CashFlowEditorScreen(
          direction: direction,
          initialTitle: '',
          businessDate: today,
        ),
      ),
    );
    if (definition == null || !context.mounted) return;
    await ref
        .read(cashFlowManagementControllerProvider.notifier)
        .create(definition: definition, businessDate: today);
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ProjectedCashFlow flow,
  ) async {
    final effectiveCycle = service.nextConfigurationCycleStart(today);
    final currentCycle =
        today.isBefore(service.configuration.household!.firstCycleStart)
        ? service.configuration.household!.firstCycleStart
        : service.configuration.household!.cycleContaining(today).start;
    final initial = _displayedDefinition(flow, currentCycle, effectiveCycle);
    if (initial.schedule is! RecurringSchedule) return;
    final definition = await Navigator.of(context).push<CashFlowDefinition>(
      MaterialPageRoute(
        builder: (_) => CashFlowEditorScreen(
          direction: initial.direction,
          initialTitle: initial.title,
          businessDate: today,
          initialDefinition: initial,
        ),
      ),
    );
    if (definition == null || !context.mounted) return;
    await ref
        .read(cashFlowManagementControllerProvider.notifier)
        .replace(
          cashFlowId: flow.id,
          definition: definition,
          businessDate: today,
        );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ProjectedCashFlow flow,
    LocalDate effectiveCycle,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAssumptionTitle),
        content: Text(
          l10n.deleteAssumptionBody(_formatDate(context, effectiveCycle)),
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
    await ref
        .read(cashFlowManagementControllerProvider.notifier)
        .delete(cashFlowId: flow.id, businessDate: today);
  }
}

final class _AssumptionSection extends StatelessWidget {
  const _AssumptionSection({
    required this.title,
    required this.icon,
    required this.flows,
    required this.currentCycle,
    required this.effectiveCycle,
    required this.enabled,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final IconData icon;
  final List<ProjectedCashFlow> flows;
  final LocalDate currentCycle;
  final LocalDate effectiveCycle;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<ProjectedCashFlow> onEdit;
  final ValueChanged<ProjectedCashFlow> onDelete;

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
            TextButton.icon(
              onPressed: enabled ? onAdd : null,
              icon: const Icon(Icons.add),
              label: Text(l10n.addAssumption),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final flow in flows)
          _AssumptionTile(
            flow: flow,
            currentCycle: currentCycle,
            effectiveCycle: effectiveCycle,
            enabled: enabled,
            onEdit: () => onEdit(flow),
            onDelete: () => onDelete(flow),
          ),
      ],
    );
  }
}

final class _AssumptionTile extends StatelessWidget {
  const _AssumptionTile({
    required this.flow,
    required this.currentCycle,
    required this.effectiveCycle,
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectedCashFlow flow;
  final LocalDate currentCycle;
  final LocalDate effectiveCycle;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = flow.definitionForCycleStarting(currentCycle);
    final future = flow.definitionForCycleStarting(effectiveCycle);
    final displayed = future ?? current!;
    final latest = flow.latestRevision;
    final pending = latest.effectiveFromCycleStart == effectiveCycle;
    final pendingDeletion = pending && latest.isDeletion;
    final pendingCreation = pending && current == null && future != null;
    return Card(
      child: ListTile(
        title: Text(displayed.title),
        subtitle: Text(
          '${_definitionSummary(context, displayed)}'
          '${pendingDeletion
              ? '\n${l10n.assumptionEndsOn(_formatDate(context, effectiveCycle))}'
              : pendingCreation
              ? '\n${l10n.assumptionStartsOn(_formatDate(context, effectiveCycle))}'
              : pending
              ? '\n${l10n.assumptionChangesOn(_formatDate(context, effectiveCycle))}'
              : ''}',
        ),
        trailing: PopupMenuButton<_AssumptionAction>(
          enabled: enabled && !pendingDeletion,
          onSelected: (action) => switch (action) {
            _AssumptionAction.edit => onEdit(),
            _AssumptionAction.delete => onDelete(),
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: _AssumptionAction.edit,
              child: Text(l10n.editAssumption),
            ),
            PopupMenuItem(
              value: _AssumptionAction.delete,
              child: Text(l10n.deleteExpense),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AssumptionAction { edit, delete }

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

CashFlowDefinition _displayedDefinition(
  ProjectedCashFlow flow,
  LocalDate currentCycle,
  LocalDate effectiveCycle,
) =>
    flow.definitionForCycleStarting(effectiveCycle) ??
    flow.definitionForCycleStarting(currentCycle)!;

String _definitionSummary(BuildContext context, CashFlowDefinition definition) {
  final l10n = AppLocalizations.of(context);
  final amount = definition.variableStrategy == VariableEstimateStrategy.custom
      ? definition.customAmountPerOccurrence!
      : definition.referenceAmountPerOccurrence;
  final frequency = switch (definition.schedule) {
    RecurringSchedule(:final frequency) => switch (frequency) {
      RecurrenceFrequency.weekly => l10n.frequencyWeekly,
      RecurrenceFrequency.everyFourWeeks => l10n.frequencyEveryFourWeeks,
      RecurrenceFrequency.monthly => l10n.frequencyMonthly,
      RecurrenceFrequency.quarterly => l10n.frequencyQuarterly,
      RecurrenceFrequency.semiAnnual => l10n.frequencySemiAnnual,
      RecurrenceFrequency.annual => l10n.frequencyAnnual,
    },
    CustomDateSchedule() => l10n.frequencyCustomDates,
  };
  return l10n.cashFlowSummary(
    _formatMoney(context, amount),
    frequency,
    definition.behavior == AmountBehavior.fixed
        ? l10n.fixedAmount
        : l10n.variableAmount,
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
