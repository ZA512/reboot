import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../financial_setup/euro_amount_parser.dart';
import '../infrastructure/device_context_providers.dart';
import '../l10n/app_localizations.dart';
import 'trajectory_setup_controller.dart';

/// Collects the final explicit choices before calculating a weekly budget.
final class TrajectorySetupScreen extends ConsumerStatefulWidget {
  /// Creates the trajectory step for the household's first 52-cycle horizon.
  const TrajectorySetupScreen({required this.firstCycleStart, super.key});

  /// Start of the first configured REBOOT cycle.
  final LocalDate firstCycleStart;

  @override
  ConsumerState<TrajectorySetupScreen> createState() =>
      _TrajectorySetupScreenState();
}

final class _TrajectorySetupScreenState
    extends ConsumerState<TrajectorySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cushionController = TextEditingController(text: '0');
  final _projectsController = TextEditingController(text: '0');
  final _safetyController = TextEditingController(text: '0');
  final _overdraftController = TextEditingController(text: '0');
  final _targetCushionController = TextEditingController(text: '0');
  TrajectoryStrategy _strategy = TrajectoryStrategy.balance;
  LocalDate? _targetDate;

  @override
  void dispose() {
    _cushionController.dispose();
    _projectsController.dispose();
    _safetyController.dispose();
    _overdraftController.dispose();
    _targetCushionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deviceContext = ref.watch(onboardingDeviceContextProvider);
    final submission = ref.watch(trajectorySetupControllerProvider);
    final businessDate = switch (deviceContext) {
      AsyncData(:final value) => value.localDate,
      _ => null,
    };
    if (_targetDate == null && businessDate != null) {
      final proposed = businessDate.addDays(182);
      final horizonEnd = widget.firstCycleStart.addDays(364);
      _targetDate = proposed.isAfter(horizonEnd) ? horizonEnd : proposed;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            children: [
              Text(
                l10n.trajectorySetupTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(l10n.trajectorySetupIntro),
              const SizedBox(height: 24),
              _StrategyCard(
                selected: _strategy == TrajectoryStrategy.balance,
                icon: Icons.balance,
                title: l10n.strategyBalanceTitle,
                body: l10n.strategyBalanceBody,
                onTap: () => _selectStrategy(TrajectoryStrategy.balance),
              ),
              const SizedBox(height: 8),
              _StrategyCard(
                selected: _strategy == TrajectoryStrategy.cushion,
                icon: Icons.savings_outlined,
                title: l10n.strategyCushionTitle,
                body: l10n.strategyCushionBody,
                onTap: () => _selectStrategy(TrajectoryStrategy.cushion),
              ),
              const SizedBox(height: 8),
              _StrategyCard(
                selected: _strategy == TrajectoryStrategy.overdraftExit,
                icon: Icons.trending_up,
                title: l10n.strategyOverdraftTitle,
                body: l10n.strategyOverdraftBody,
                onTap: () => _selectStrategy(TrajectoryStrategy.overdraftExit),
              ),
              if (_strategy == TrajectoryStrategy.cushion) ...[
                const SizedBox(height: 20),
                _MoneyField(
                  controller: _cushionController,
                  label: l10n.annualCushionLabel,
                  help: l10n.annualCushionHelp,
                  validator: (value) {
                    final amount = parsePositiveEuroAmount(value ?? '');
                    return amount == null ? l10n.invalidPositiveAmount : null;
                  },
                ),
              ],
              if (_strategy == TrajectoryStrategy.overdraftExit) ...[
                const SizedBox(height: 20),
                _MoneyField(
                  controller: _overdraftController,
                  label: l10n.currentOverdraftLabel,
                  help: l10n.currentOverdraftHelp,
                  validator: _validateNonNegative,
                ),
                const SizedBox(height: 16),
                _MoneyField(
                  controller: _targetCushionController,
                  label: l10n.targetCushionLabel,
                  help: l10n.targetCushionHelp,
                  validator: _validateNonNegative,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  leading: const Icon(Icons.event_available),
                  title: Text(l10n.overdraftTargetDateLabel),
                  subtitle: Text(
                    _targetDate == null
                        ? l10n.dateUnavailable
                        : _formatDate(context, _targetDate!),
                  ),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: businessDate == null
                      ? null
                      : () => _pickTargetDate(businessDate),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.overdraftConfirmationHelp,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 28),
              Text(
                l10n.otherAnnualGoalsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(l10n.otherAnnualGoalsBody),
              const SizedBox(height: 16),
              _MoneyField(
                controller: _projectsController,
                label: l10n.annualProjectsLabel,
                help: l10n.annualProjectsHelp,
                validator: _validateNonNegative,
              ),
              const SizedBox(height: 16),
              _MoneyField(
                controller: _safetyController,
                label: l10n.annualSafetyLabel,
                help: l10n.annualSafetyHelp,
                validator: _validateNonNegative,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.noAutomaticMargin,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (deviceContext.hasError || submission.hasError) ...[
                const SizedBox(height: 20),
                _ErrorNotice(
                  message: deviceContext.hasError
                      ? l10n.timeZoneError
                      : l10n.trajectorySetupError,
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: businessDate == null || submission.isLoading
                    ? null
                    : () => _submit(businessDate),
                child: submission.isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(l10n.trajectorySaving),
                        ],
                      )
                    : Text(l10n.calculateWeeklyBudget),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectStrategy(TrajectoryStrategy strategy) {
    setState(() => _strategy = strategy);
  }

  String? _validateNonNegative(String? value) {
    return parseNonNegativeEuroAmount(value ?? '') == null
        ? AppLocalizations.of(context).invalidNonNegativeAmount
        : null;
  }

  Future<void> _pickTargetDate(LocalDate businessDate) async {
    final target = _targetDate!;
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(target.year, target.month, target.day),
      firstDate: DateTime(
        businessDate.addDays(1).year,
        businessDate.addDays(1).month,
        businessDate.addDays(1).day,
      ),
      lastDate: DateTime(
        widget.firstCycleStart.addDays(364).year,
        widget.firstCycleStart.addDays(364).month,
        widget.firstCycleStart.addDays(364).day,
      ),
    );
    if (selected != null) {
      setState(() => _targetDate = LocalDate.fromDateTime(selected));
    }
  }

  void _submit(LocalDate businessDate) {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final reserve = _strategy == TrajectoryStrategy.cushion
        ? parsePositiveEuroAmount(_cushionController.text)!
        : Money.zero(Currency.eur);
    final project = parseNonNegativeEuroAmount(_projectsController.text)!;
    final safety = parseNonNegativeEuroAmount(_safetyController.text)!;
    OverdraftExitGoal? goal;
    if (_strategy == TrajectoryStrategy.overdraftExit) {
      final overdraft = parseNonNegativeEuroAmount(_overdraftController.text)!;
      final target = parseNonNegativeEuroAmount(_targetCushionController.text)!;
      if ((overdraft + target).isZero) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).emptyRecoveryGoal),
          ),
        );
        return;
      }
      goal = OverdraftExitGoal(
        currentOverdraftDepth: overdraft,
        targetCushion: target,
        targetDate: _targetDate!,
      );
    }
    ref
        .read(trajectorySetupControllerProvider.notifier)
        .submit(
          strategy: _strategy,
          reserveContributions: reserve,
          projectContributions: project,
          safetyMargin: safety,
          businessDate: businessDate,
          overdraftExitGoal: goal,
        );
  }
}

final class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.controller,
    required this.label,
    required this.help,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String help;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'EUR',
        helperText: help,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}

final class _StrategyCard extends StatelessWidget {
  const _StrategyCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: selected ? colors.secondaryContainer : colors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(body),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(selected ? Icons.check_circle : Icons.circle_outlined),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
      ),
    );
  }
}

String _formatDate(BuildContext context, LocalDate date) {
  return MaterialLocalizations.of(
    context,
  ).formatFullDate(DateTime(date.year, date.month, date.day));
}
