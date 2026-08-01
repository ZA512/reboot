import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

import '../financial_setup/euro_amount_parser.dart';
import '../formatting/exact_money_formatter.dart';
import '../l10n/app_localizations.dart';
import 'cash_controller.dart';

/// Configures the dated cash rule and records withdrawals accordingly.
final class CashScreen extends ConsumerWidget {
  const CashScreen({required this.service, required this.today, super.key});

  final LocalRebootService service;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mutation = ref.watch(cashControllerProvider);
    final method = service.cash.methodOn(today);
    final effectiveRevision = _methodRevisionOn(today);
    final transfers = service.cash.walletTransfers.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cashTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text(l10n.cashIntro),
            const SizedBox(height: 16),
            Text(
              l10n.cashMethodTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _MethodCard(
              key: const ValueKey('cash-method-withdrawal-expense'),
              selected: method == CashWithdrawalMethod.withdrawalAsExpense,
              icon: Icons.money_off_csred_outlined,
              title: l10n.cashMethodWithdrawalExpense,
              body: l10n.cashMethodWithdrawalExpenseHelp,
              enabled: !mutation.isLoading,
              onSelect: () => _changeMethod(
                context,
                ref,
                CashWithdrawalMethod.withdrawalAsExpense,
                method,
              ),
            ),
            _MethodCard(
              key: const ValueKey('cash-method-wallet'),
              selected: method == CashWithdrawalMethod.cashWallet,
              icon: Icons.account_balance_wallet_outlined,
              title: l10n.cashMethodWallet,
              body: l10n.cashMethodWalletHelp,
              enabled: !mutation.isLoading,
              onSelect: () => _changeMethod(
                context,
                ref,
                CashWithdrawalMethod.cashWallet,
                method,
              ),
            ),
            if (effectiveRevision != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.cashMethodEffectiveSince(
                  _formatDate(context, effectiveRevision.effectiveFrom),
                ),
              ),
            ],
            if (method != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const ValueKey('record-cash-withdrawal'),
                onPressed: mutation.isLoading
                    ? null
                    : () => _recordWithdrawal(context, ref, method),
                icon: const Icon(Icons.local_atm_outlined),
                label: Text(l10n.recordCashWithdrawal),
              ),
            ],
            if (mutation.hasError) ...[
              const SizedBox(height: 12),
              Text(
                l10n.cashMutationError,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (transfers.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                l10n.cashWalletTransferHistory,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(l10n.cashWalletNoBalanceHelp),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (final transfer in transfers)
                      ListTile(
                        title: Text(
                          transfer.label,
                          style: transfer.isReversed
                              ? const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                )
                              : null,
                        ),
                        subtitle: Text(
                          transfer.isReversed
                              ? l10n.reversedCashTransfer
                              : _formatDate(context, transfer.businessDate),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_formatMoney(context, transfer.amount)),
                            if (!transfer.isReversed)
                              IconButton(
                                tooltip: l10n.reverseCashTransfer,
                                onPressed: mutation.isLoading
                                    ? null
                                    : () => _reverseTransfer(
                                        context,
                                        ref,
                                        transfer,
                                      ),
                                icon: const Icon(Icons.undo),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  CashMethodRevision? _methodRevisionOn(LocalDate date) {
    CashMethodRevision? effective;
    for (final revision in service.cash.methodRevisions) {
      if (!revision.effectiveFrom.isAfter(date)) effective = revision;
    }
    return effective;
  }

  Future<void> _changeMethod(
    BuildContext context,
    WidgetRef ref,
    CashWithdrawalMethod next,
    CashWithdrawalMethod? current,
  ) async {
    if (next == current) return;
    if (current != null) {
      final l10n = AppLocalizations.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.changeCashMethodTitle),
          content: Text(l10n.changeCashMethodBody(_formatDate(context, today))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.changeCashMethod),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    await ref
        .read(cashControllerProvider.notifier)
        .configure(method: next, businessDate: today);
  }

  Future<void> _recordWithdrawal(
    BuildContext context,
    WidgetRef ref,
    CashWithdrawalMethod method,
  ) async {
    final draft = await showDialog<_WithdrawalDraft>(
      context: context,
      builder: (_) => const _WithdrawalDialog(),
    );
    if (draft == null || !context.mounted) return;
    final accepted = await ref
        .read(cashControllerProvider.notifier)
        .recordWithdrawal(
          amount: draft.amount,
          label: draft.label,
          businessDate: today,
        );
    if (!accepted || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          method == CashWithdrawalMethod.withdrawalAsExpense
              ? l10n.cashWithdrawalReducedWeek(
                  _formatMoney(context, draft.amount),
                )
              : l10n.cashWithdrawalRecordedAsTransfer(
                  _formatMoney(context, draft.amount),
                ),
        ),
      ),
    );
  }

  Future<void> _reverseTransfer(
    BuildContext context,
    WidgetRef ref,
    ProjectedCashWalletTransfer transfer,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.reverseCashTransferTitle),
        content: Text(l10n.reverseCashTransferBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.reverseCashTransfer),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(cashControllerProvider.notifier)
        .reverseTransfer(
          transferEventId: transfer.eventId,
          businessDate: today,
        );
  }
}

final class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.body,
    required this.enabled,
    required this.onSelect,
    super.key,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String body;
  final bool enabled;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => Card(
    color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(body),
      trailing: Icon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
      ),
      onTap: enabled ? onSelect : null,
    ),
  );
}

final class _WithdrawalDialog extends StatefulWidget {
  const _WithdrawalDialog();

  @override
  State<_WithdrawalDialog> createState() => _WithdrawalDialogState();
}

final class _WithdrawalDialogState extends State<_WithdrawalDialog> {
  final _key = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _label = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_label.text.isEmpty) {
      _label.text = AppLocalizations.of(context).defaultCashWithdrawalLabel;
    }
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
    return AlertDialog(
      title: Text(l10n.recordCashWithdrawal),
      content: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('cash-withdrawal-amount'),
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.cashWithdrawalAmount,
                suffixText: '€',
              ),
              validator: (value) => parsePositiveEuroAmount(value ?? '') == null
                  ? l10n.invalidPositiveAmount
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('cash-withdrawal-label'),
              controller: _label,
              decoration: InputDecoration(labelText: l10n.cashWithdrawalLabel),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.requiredField
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
          key: const ValueKey('confirm-cash-withdrawal'),
          onPressed: () {
            if (!_key.currentState!.validate()) return;
            Navigator.pop(
              context,
              _WithdrawalDraft(
                amount: parsePositiveEuroAmount(_amount.text)!,
                label: _label.text.trim(),
              ),
            );
          },
          child: Text(l10n.recordCashWithdrawal),
        ),
      ],
    );
  }
}

final class _WithdrawalDraft {
  const _WithdrawalDraft({required this.amount, required this.label});

  final Money amount;
  final String label;
}

String _formatMoney(BuildContext context, Money money) => formatMoneyExact(
  money,
  locale: Localizations.localeOf(context).toLanguageTag(),
);

String _formatDate(BuildContext context, LocalDate date) =>
    MaterialLocalizations.of(
      context,
    ).formatFullDate(DateTime(date.year, date.month, date.day));
