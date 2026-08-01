import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

import '../financial_setup/euro_amount_parser.dart';
import '../formatting/exact_money_formatter.dart';
import '../l10n/app_localizations.dart';
import 'health_controller.dart';

/// Optional aggregate health-expense and reimbursement monitor.
final class HealthScreen extends ConsumerWidget {
  const HealthScreen({required this.service, required this.today, super.key});

  final LocalRebootService service;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mutation = ref.watch(healthControllerProvider);
    final tracking = service.health.tracking;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.healthTitle),
        actions: [
          if (tracking != null)
            IconButton(
              tooltip: l10n.healthSettings,
              onPressed: mutation.isLoading
                  ? null
                  : () => _configure(context, ref, tracking),
              icon: const Icon(Icons.tune),
            ),
        ],
      ),
      body: SafeArea(
        child: tracking == null || !tracking.enabled
            ? _DisabledHealth(
                wasConfigured: tracking != null,
                busy: mutation.isLoading,
                onEnable: () => _configure(context, ref, tracking),
              )
            : _EnabledHealth(
                tracking: tracking,
                today: today,
                busy: mutation.isLoading,
                onRecord: (kind) => _record(context, ref, tracking, kind),
                onReverse: (entry) => _reverse(context, ref, entry),
              ),
      ),
      bottomNavigationBar: mutation.hasError
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  l10n.healthMutationError,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _configure(
    BuildContext context,
    WidgetRef ref,
    ProjectedHealthTracking? current,
  ) async {
    final draft = await showDialog<_HealthConfigDraft>(
      context: context,
      builder: (_) => _HealthConfigDialog(current: current),
    );
    if (draft == null || !context.mounted) return;
    await ref
        .read(healthControllerProvider.notifier)
        .configure(
          ConfigureHealthTrackingCommand(
            enabled: draft.enabled,
            delayWeeks: draft.delayWeeks,
            alertThreshold: draft.threshold,
            businessDate: today,
          ),
        );
  }

  Future<void> _record(
    BuildContext context,
    WidgetRef ref,
    ProjectedHealthTracking tracking,
    HealthEntryKind kind,
  ) async {
    final draft = await showDialog<_HealthEntryDraft>(
      context: context,
      builder: (_) => _HealthEntryDialog(
        kind: kind,
        firstDate: tracking.trackingStartDate!,
        today: today,
      ),
    );
    if (draft == null || !context.mounted) return;
    await ref
        .read(healthControllerProvider.notifier)
        .record(
          RecordHealthEntryCommand(
            kind: kind,
            amount: draft.amount,
            label: draft.label,
            businessDate: draft.date,
          ),
        );
  }

  Future<void> _reverse(
    BuildContext context,
    WidgetRef ref,
    ProjectedHealthEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.reverseHealthEntryTitle),
        content: Text(l10n.reverseHealthEntryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.reverseHealthEntry),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(healthControllerProvider.notifier)
        .reverse(
          ReverseHealthEntryCommand(
            entryEventId: entry.eventId,
            businessDate: today,
          ),
        );
  }
}

final class _DisabledHealth extends StatelessWidget {
  const _DisabledHealth({
    required this.wasConfigured,
    required this.busy,
    required this.onEnable,
  });

  final bool wasConfigured;
  final bool busy;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.health_and_safety_outlined, size: 48),
        const SizedBox(height: 16),
        Text(
          wasConfigured
              ? l10n.healthTrackingDisabled
              : l10n.healthTrackingOptional,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(l10n.healthIntro, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.healthDisabledWarning),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: busy ? null : onEnable,
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.enableHealthTracking),
        ),
      ],
    );
  }
}

final class _EnabledHealth extends StatelessWidget {
  const _EnabledHealth({
    required this.tracking,
    required this.today,
    required this.busy,
    required this.onRecord,
    required this.onReverse,
  });

  final ProjectedHealthTracking tracking;
  final LocalDate today;
  final bool busy;
  final ValueChanged<HealthEntryKind> onRecord;
  final ValueChanged<ProjectedHealthEntry> onReverse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final estimate = tracking.estimatedRest(today);
    final alert = tracking.requiresAttention(today);
    final colors = Theme.of(context).colorScheme;
    final entries = tracking.entries.reversed.toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Card(
          color: alert ? colors.errorContainer : colors.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(l10n.healthEstimatedRest),
                const SizedBox(height: 6),
                Text(
                  _formatSignedMoney(context, estimate),
                  key: const ValueKey('health-estimate'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.healthEstimateSettings(
                    tracking.delayWeeks,
                    _formatMoney(context, tracking.alertThreshold),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        if (alert) ...[
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.warning_amber_rounded, color: colors.error),
              title: Text(l10n.healthAttentionTitle),
              subtitle: Text(l10n.healthAttentionBody),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: busy ? null : () => onRecord(HealthEntryKind.expense),
              icon: const Icon(Icons.medical_services_outlined),
              label: Text(l10n.addHealthExpense),
            ),
            FilledButton.tonalIcon(
              onPressed: busy
                  ? null
                  : () => onRecord(HealthEntryKind.reimbursement),
              icon: const Icon(Icons.payments_outlined),
              label: Text(l10n.addHealthReimbursement),
            ),
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () => onRecord(HealthEntryKind.regularization),
              icon: const Icon(Icons.done_all),
              label: Text(l10n.addHealthRegularization),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(l10n.healthRegularizationHelp),
        const SizedBox(height: 24),
        Text(l10n.healthHistory, style: Theme.of(context).textTheme.titleLarge),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.noHealthEntry),
          )
        else
          for (final entry in entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_entryIcon(entry.kind)),
              title: Text(entry.label),
              subtitle: Text(
                entry.isReversed
                    ? l10n.reversedHealthEntry
                    : _formatDate(context, entry.businessDate),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _entryAmount(context, entry),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (!entry.isReversed)
                    IconButton(
                      tooltip: l10n.reverseHealthEntry,
                      onPressed: busy ? null : () => onReverse(entry),
                      icon: const Icon(Icons.undo),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

final class _HealthConfigDraft {
  const _HealthConfigDraft(this.enabled, this.delayWeeks, this.threshold);

  final bool enabled;
  final int delayWeeks;
  final Money threshold;
}

final class _HealthConfigDialog extends StatefulWidget {
  const _HealthConfigDialog({required this.current});

  final ProjectedHealthTracking? current;

  @override
  State<_HealthConfigDialog> createState() => _HealthConfigDialogState();
}

final class _HealthConfigDialogState extends State<_HealthConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late bool _enabled;
  late final TextEditingController _delay;
  late final TextEditingController _threshold;

  @override
  void initState() {
    super.initState();
    _enabled = widget.current?.enabled ?? true;
    _delay = TextEditingController(
      text: (widget.current?.delayWeeks ?? 4).toString(),
    );
    _threshold = TextEditingController(
      text: formatMoneyInputExact(
        widget.current?.alertThreshold ??
            Money.fromMinorUnits(5000, Currency.eur),
        alwaysShowFraction: true,
      ),
    );
  }

  @override
  void dispose() {
    _delay.dispose();
    _threshold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.healthSettings),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _enabled,
              title: Text(l10n.enableHealthTracking),
              onChanged: (value) => setState(() => _enabled = value),
            ),
            TextFormField(
              controller: _delay,
              enabled: _enabled,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.healthDelayWeeks),
              validator: (value) {
                final parsed = int.tryParse(value ?? '');
                return parsed == null || parsed < 1 || parsed > 52
                    ? l10n.invalidHealthDelay
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _threshold,
              enabled: _enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l10n.healthAlertThreshold),
              validator: (value) =>
                  parseNonNegativeEuroAmount(value ?? '') == null
                  ? l10n.invalidNonNegativeAmount
                  : null,
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
            if (_enabled && !_formKey.currentState!.validate()) return;
            final delay =
                int.tryParse(_delay.text) ?? widget.current?.delayWeeks ?? 4;
            final threshold =
                parseNonNegativeEuroAmount(_threshold.text) ??
                widget.current?.alertThreshold ??
                Money.fromMinorUnits(5000, Currency.eur);
            Navigator.pop(
              context,
              _HealthConfigDraft(_enabled, delay, threshold),
            );
          },
          child: Text(l10n.saveHealthSettings),
        ),
      ],
    );
  }
}

final class _HealthEntryDraft {
  const _HealthEntryDraft(this.amount, this.label, this.date);

  final Money amount;
  final String label;
  final LocalDate date;
}

final class _HealthEntryDialog extends StatefulWidget {
  const _HealthEntryDialog({
    required this.kind,
    required this.firstDate,
    required this.today,
  });

  final HealthEntryKind kind;
  final LocalDate firstDate;
  final LocalDate today;

  @override
  State<_HealthEntryDialog> createState() => _HealthEntryDialogState();
}

final class _HealthEntryDialogState extends State<_HealthEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _label = TextEditingController();
  late LocalDate _date;

  @override
  void initState() {
    super.initState();
    _date = widget.today;
  }

  @override
  void dispose() {
    _amount.dispose();
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = switch (widget.kind) {
      HealthEntryKind.expense => l10n.addHealthExpense,
      HealthEntryKind.reimbursement => l10n.addHealthReimbursement,
      HealthEntryKind.regularization => l10n.addHealthRegularization,
    };
    return AlertDialog(
      title: Text(title),
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
              decoration: InputDecoration(labelText: l10n.healthEntryAmount),
              validator: (value) => parsePositiveEuroAmount(value ?? '') == null
                  ? l10n.invalidPositiveAmount
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _label,
              decoration: InputDecoration(labelText: l10n.healthEntryLabel),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? l10n.requiredField : null,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.healthEntryDate),
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
              _HealthEntryDraft(
                parsePositiveEuroAmount(_amount.text)!,
                _label.text.trim(),
                _date,
              ),
            );
          },
          child: Text(l10n.saveHealthEntry),
        ),
      ],
    );
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(_date.year, _date.month, _date.day),
      firstDate: DateTime(
        widget.firstDate.year,
        widget.firstDate.month,
        widget.firstDate.day,
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

IconData _entryIcon(HealthEntryKind kind) => switch (kind) {
  HealthEntryKind.expense => Icons.medical_services_outlined,
  HealthEntryKind.reimbursement => Icons.payments_outlined,
  HealthEntryKind.regularization => Icons.done_all,
};

String _entryAmount(BuildContext context, ProjectedHealthEntry entry) {
  final sign = entry.kind == HealthEntryKind.expense ? '+' : '−';
  return '$sign${_formatMoney(context, entry.amount)}';
}

String _formatMoney(BuildContext context, Money money) => formatMoneyExact(
  money,
  locale: Localizations.localeOf(context).toLanguageTag(),
);

String _formatSignedMoney(BuildContext context, Money money) {
  final formatted = _formatMoney(context, money.isNegative ? -money : money);
  return money.isNegative ? '−$formatted' : formatted;
}

String _formatDate(BuildContext context, LocalDate date) =>
    MaterialLocalizations.of(
      context,
    ).formatShortDate(DateTime(date.year, date.month, date.day));
