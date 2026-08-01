import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

import '../l10n/app_localizations.dart';

/// Makes every accepted assumption behind the current weekly budget visible.
final class BudgetExplanationScreen extends StatelessWidget {
  const BudgetExplanationScreen({
    required this.service,
    required this.today,
    super.key,
  });

  final LocalRebootService service;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final household = service.configuration.household!;
    final cycleStart = today.isBefore(household.firstCycleStart)
        ? household.firstCycleStart
        : household.cycleContaining(today).start;
    final projection = service.buildAnnualBudget(cycleStart);
    final weeklyBudget = service.weeklyBudgetForCycleStarting(cycleStart);
    final bonusAddition = weeklyBudget - projection.recommendedWeeklyBudget;
    final incomes = projection.cashFlows
        .where((line) => line.definition.direction == CashFlowDirection.income)
        .toList(growable: false);
    final outflows = projection.cashFlows
        .where((line) => line.definition.direction == CashFlowDirection.outflow)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetExplanationTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Text(l10n.budgetExplanationIntro),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      l10n.currentWeeklyBudget,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatMoney(context, weeklyBudget),
                      key: const ValueKey('explained-weekly-budget'),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.calculationHorizon(
                        _formatDate(context, projection.start),
                        _formatDate(
                          context,
                          projection.endExclusive.addDays(-1),
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    _FormulaLine(
                      label: l10n.baseWeeklyBudget,
                      amount: projection.recommendedWeeklyBudget,
                    ),
                    if (bonusAddition.isPositive)
                      _FormulaLine(
                        label: l10n.receivedBonusWeeklyAddition,
                        amount: bonusAddition,
                        sign: '+',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.annualCalculationTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _AnnualFormulaCard(projection: projection),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weeklyBudgetComposition,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    _FormulaLine(
                      label: l10n.exactWeeklyCapacity,
                      amount: projection.grossWeeklyCapacity,
                    ),
                    _FormulaLine(
                      label: l10n.baseWeeklyBudget,
                      amount: projection.recommendedWeeklyBudget,
                    ),
                    _FormulaLine(
                      label: l10n.unallocatedAnnualMarginLabel,
                      amount: projection.unallocatedAnnualMargin,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.unallocatedAnnualMarginHelp,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            if (projection.overdraftRecovery case final recovery?) ...[
              const SizedBox(height: 12),
              Card(
                color: recovery.isFeasible
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    recovery.isFeasible
                        ? l10n.overdraftRecoverySummary(
                            _formatMoney(context, recovery.requiredPerCycle),
                            recovery.cycleCount,
                            _formatDate(context, recovery.goal.targetDate),
                          )
                        : l10n.overdraftRecoveryImpossible(
                            _formatMoney(context, recovery.shortfallPerCycle),
                          ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _CashFlowSection(
              title: l10n.incomeSectionTitle,
              total: projection.totalIncome,
              lines: incomes,
              totalKey: const ValueKey('budget-explanation-income-total'),
            ),
            const SizedBox(height: 16),
            _CashFlowSection(
              title: l10n.outflowSectionTitle,
              total: projection.totalOutflows,
              lines: outflows,
              totalKey: const ValueKey('budget-explanation-outflow-total'),
            ),
            const SizedBox(height: 24),
            const _MethodCard(),
          ],
        ),
      ),
    );
  }
}

final class _AnnualFormulaCard extends StatelessWidget {
  const _AnnualFormulaCard({required this.projection});

  final AnnualBudgetProjection projection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deductions = projection.deductions;
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _FormulaLine(
              label: l10n.annualIncome,
              amount: projection.totalIncome,
            ),
            _FormulaLine(
              label: l10n.annualOutflows,
              amount: projection.totalOutflows,
              sign: '−',
            ),
            _FormulaLine(
              label: l10n.annualReserves,
              amount: deductions.reserveContributions,
              sign: '−',
            ),
            _FormulaLine(
              label: l10n.annualProjects,
              amount: deductions.projectContributions,
              sign: '−',
            ),
            _FormulaLine(
              label: l10n.annualSafety,
              amount: deductions.safetyMargin,
              sign: '−',
            ),
            const Divider(height: 24),
            _FormulaLine(
              key: const ValueKey('budget-explanation-capacity'),
              label: l10n.annualSteerableCapacity,
              amount: projection.steerableCapacity,
              emphasized: true,
            ),
            if (projection.deficit.isPositive) ...[
              const SizedBox(height: 8),
              Text(
                l10n.annualDeficit(_formatMoney(context, projection.deficit)),
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _FormulaLine extends StatelessWidget {
  const _FormulaLine({
    required this.label,
    required this.amount,
    this.sign,
    this.emphasized = false,
    super.key,
  });

  final String label;
  final Money amount;
  final String? sign;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (sign != null) ...[
            SizedBox(width: 20, child: Text(sign!, style: style)),
            const SizedBox(width: 4),
          ],
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(
            _formatMoney(context, amount),
            style: style?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

final class _CashFlowSection extends StatelessWidget {
  const _CashFlowSection({
    required this.title,
    required this.total,
    required this.lines,
    required this.totalKey,
  });

  final String title;
  final Money total;
  final List<CashFlowAnnualization> lines;
  final Key totalKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            Text(
              _formatMoney(context, total),
              key: totalKey,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < lines.length; index += 1) ...[
                _CashFlowTile(line: lines[index]),
                if (index != lines.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

final class _CashFlowTile extends StatelessWidget {
  const _CashFlowTile({required this.line});

  final CashFlowAnnualization line;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final definition = line.definition;
    final sourceAmount =
        definition.variableStrategy == VariableEstimateStrategy.custom
        ? definition.customAmountPerOccurrence!
        : definition.referenceAmountPerOccurrence;
    return ExpansionTile(
      key: ValueKey('explained-cash-flow-${definition.title}'),
      title: Text(definition.title),
      subtitle: Text(l10n.cashFlowOccurrences(line.occurrences.length)),
      trailing: Text(
        _formatMoney(context, line.total),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailLine(
          label: l10n.cashFlowReferenceAmount,
          value: _formatMoney(context, sourceAmount),
        ),
        _DetailLine(
          label: l10n.amountBehaviorLabel,
          value: definition.behavior == AmountBehavior.fixed
              ? l10n.fixedAmount
              : l10n.variableAmount,
        ),
        if (definition.behavior == AmountBehavior.variable)
          _DetailLine(
            label: l10n.cashFlowEstimation,
            value: _strategyLabel(l10n, definition.variableStrategy!),
          ),
      ],
    );
  }
}

final class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

final class _MethodCard extends StatelessWidget {
  const _MethodCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      l10n.methodStepRecord,
      l10n.methodStepEstimate,
      l10n.methodStepBlock,
      l10n.methodStepOrganize,
      l10n.methodStepObserve,
      l10n.methodStepTune,
    ];
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.rebootMethodTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(l10n.rebootMethodIntro),
            const SizedBox(height: 10),
            for (var index = 0; index < steps.length; index += 1)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${index + 1}. ${steps[index]}'),
              ),
            const SizedBox(height: 10),
            Text(
              l10n.noCarryoverReminder,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

String _strategyLabel(
  AppLocalizations l10n,
  VariableEstimateStrategy strategy,
) => switch (strategy) {
  VariableEstimateStrategy.prudent => l10n.strategyPrudent,
  VariableEstimateStrategy.balanced => l10n.strategyBalanced,
  VariableEstimateStrategy.custom => l10n.strategyCustom,
};

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
