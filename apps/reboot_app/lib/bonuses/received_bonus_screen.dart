import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

import '../financial_setup/euro_amount_parser.dart';
import '../formatting/exact_money_formatter.dart';
import '../l10n/app_localizations.dart';
import 'received_bonus_controller.dart';

/// Manages only bonus money that has already been received and still exists.
final class ReceivedBonusScreen extends ConsumerWidget {
  const ReceivedBonusScreen({
    required this.service,
    required this.today,
    super.key,
  });

  final LocalRebootService service;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mutation = ref.watch(receivedBonusControllerProvider);
    final household = service.configuration.household!;
    final currentCycle = today.isBefore(household.firstCycleStart)
        ? household.firstCycleStart
        : household.cycleContaining(today).start;
    final effectiveCycle = service.nextConfigurationCycleStart(today);
    final bonuses =
        service.configuration.receivedBonuses.values.where((item) {
          return item.revisionForCycleStarting(currentCycle)?.pool != null ||
              item.revisionForCycleStarting(effectiveCycle)?.pool != null;
        }).toList()..sort((left, right) {
          final leftPool = _displayPool(left, currentCycle, effectiveCycle);
          final rightPool = _displayPool(right, currentCycle, effectiveCycle);
          return leftPool.title.toLowerCase().compareTo(
            rightPool.title.toLowerCase(),
          );
        });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.receivedBonusesTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text(l10n.receivedBonusesIntro),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.receivedBonusRule(_formatDate(context, effectiveCycle)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (bonuses.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    l10n.noReceivedBonus,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              for (final bonus in bonuses)
                _BonusCard(
                  bonus: bonus,
                  currentCycle: currentCycle,
                  effectiveCycle: effectiveCycle,
                  today: today,
                  busy: mutation.isLoading,
                  onEdit: () => _edit(context, ref, bonus, effectiveCycle),
                  onDelete: () => _delete(context, ref, bonus),
                ),
            if (mutation.hasError) ...[
              const SizedBox(height: 12),
              Text(
                l10n.receivedBonusMutationError,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('create-received-bonus'),
        onPressed: mutation.isLoading
            ? null
            : () => _create(context, ref, effectiveCycle),
        icon: const Icon(Icons.add),
        label: Text(l10n.addReceivedBonus),
      ),
    );
  }

  Future<void> _create(
    BuildContext context,
    WidgetRef ref,
    LocalDate effectiveCycle,
  ) async {
    final pool = await showDialog<ReceivedBonusPool>(
      context: context,
      builder: (_) => _ReceivedBonusDialog(effectiveCycle: effectiveCycle),
    );
    if (pool == null || !context.mounted) return;
    await ref
        .read(receivedBonusControllerProvider.notifier)
        .create(pool: pool, businessDate: today);
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ProjectedReceivedBonus bonus,
    LocalDate effectiveCycle,
  ) async {
    final currentCycle =
        today.isBefore(service.configuration.household!.firstCycleStart)
        ? service.configuration.household!.firstCycleStart
        : service.configuration.household!.cycleContaining(today).start;
    final initial = _displayPool(bonus, currentCycle, effectiveCycle);
    final pool = await showDialog<ReceivedBonusPool>(
      context: context,
      builder: (_) => _ReceivedBonusDialog(
        effectiveCycle: effectiveCycle,
        initial: initial,
      ),
    );
    if (pool == null || !context.mounted) return;
    await ref
        .read(receivedBonusControllerProvider.notifier)
        .replace(receivedBonusId: bonus.id, pool: pool, businessDate: today);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ProjectedReceivedBonus bonus,
  ) async {
    final l10n = AppLocalizations.of(context);
    final effective = service.nextConfigurationCycleStart(today);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteReceivedBonusTitle),
        content: Text(
          l10n.deleteReceivedBonusBody(_formatDate(context, effective)),
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
        .read(receivedBonusControllerProvider.notifier)
        .delete(receivedBonusId: bonus.id, businessDate: today);
  }
}

final class _BonusCard extends StatelessWidget {
  const _BonusCard({
    required this.bonus,
    required this.currentCycle,
    required this.effectiveCycle,
    required this.today,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectedReceivedBonus bonus;
  final LocalDate currentCycle;
  final LocalDate effectiveCycle;
  final LocalDate today;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = bonus.revisionForCycleStarting(currentCycle);
    final future = bonus.revisionForCycleStarting(effectiveCycle);
    final pool = future?.pool ?? current!.pool!;
    final pendingChange = current?.eventId != future?.eventId;
    final due = !pool.nextPaymentDate.isAfter(today);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(due ? Icons.warning_amber_rounded : Icons.card_giftcard),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pool.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  _formatMoney(context, pool.remainingForDailyLife),
                  key: ValueKey('received-bonus-${bonus.id.value}'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              due
                  ? l10n.receivedBonusConfirmationRequired
                  : l10n.receivedBonusUntil(
                      _formatDate(context, pool.nextPaymentDate),
                    ),
            ),
            if (pendingChange) ...[
              const SizedBox(height: 6),
              Text(
                future?.pool == null
                    ? l10n.receivedBonusEndsOn(
                        _formatDate(context, effectiveCycle),
                      )
                    : l10n.receivedBonusChangesOn(
                        _formatDate(context, effectiveCycle),
                      ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onDelete,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: Text(l10n.stopReceivedBonus),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onEdit,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      due
                          ? l10n.confirmReceivedBonus
                          : l10n.adjustReceivedBonus,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _ReceivedBonusDialog extends StatefulWidget {
  const _ReceivedBonusDialog({required this.effectiveCycle, this.initial});

  final LocalDate effectiveCycle;
  final ReceivedBonusPool? initial;

  @override
  State<_ReceivedBonusDialog> createState() => _ReceivedBonusDialogState();
}

final class _ReceivedBonusDialogState extends State<_ReceivedBonusDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late LocalDate _nextPaymentDate;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial?.title ?? '');
    _amount = TextEditingController(
      text: widget.initial == null
          ? ''
          : formatMoneyInputExact(
              widget.initial!.remainingForDailyLife,
              alwaysShowFraction: true,
            ),
    );
    _nextPaymentDate =
        widget.initial?.nextPaymentDate ?? widget.effectiveCycle.addDays(364);
    if (!_nextPaymentDate.isAfter(widget.effectiveCycle)) {
      _nextPaymentDate = widget.effectiveCycle.addDays(364);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        widget.initial == null
            ? l10n.addReceivedBonus
            : l10n.confirmReceivedBonusTitle,
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.receivedBonusDialogHelp),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('received-bonus-title'),
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: l10n.receivedBonusName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.requiredField
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('received-bonus-amount'),
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.receivedBonusRemainingAmount,
                    suffixText: 'EUR',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      parsePositiveEuroAmount(value ?? '') == null
                      ? l10n.invalidPositiveAmount
                      : null,
                ),
                const SizedBox(height: 12),
                ListTile(
                  key: const ValueKey('received-bonus-date'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(l10n.receivedBonusNextPayment),
                  subtitle: Text(_formatDate(context, _nextPaymentDate)),
                  onTap: _pickDate,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('save-received-bonus'),
          onPressed: _submit,
          child: Text(l10n.saveReceivedBonus),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final first = widget.effectiveCycle.addDays(1);
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(
        _nextPaymentDate.year,
        _nextPaymentDate.month,
        _nextPaymentDate.day,
      ),
      firstDate: DateTime(first.year, first.month, first.day),
      lastDate: DateTime(first.year + 10, first.month, first.day),
    );
    if (selected != null) {
      setState(() => _nextPaymentDate = LocalDate.fromDateTime(selected));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ReceivedBonusPool(
        title: _title.text,
        remainingForDailyLife: parsePositiveEuroAmount(_amount.text)!,
        nextPaymentDate: _nextPaymentDate,
      ),
    );
  }
}

ReceivedBonusPool _displayPool(
  ProjectedReceivedBonus bonus,
  LocalDate currentCycle,
  LocalDate effectiveCycle,
) {
  return bonus.revisionForCycleStarting(effectiveCycle)?.pool ??
      bonus.revisionForCycleStarting(currentCycle)!.pool!;
}

String _formatMoney(BuildContext context, Money amount) {
  return formatMoneyExact(
    amount,
    locale: Localizations.localeOf(context).toLanguageTag(),
  );
}

String _formatDate(BuildContext context, LocalDate date) {
  return MaterialLocalizations.of(
    context,
  ).formatFullDate(DateTime(date.year, date.month, date.day));
}
