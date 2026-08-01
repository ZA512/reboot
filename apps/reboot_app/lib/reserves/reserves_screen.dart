import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

import '../expenses/quick_expense_screen.dart';
import '../financial_setup/euro_amount_parser.dart';
import '../formatting/exact_money_formatter.dart';
import '../l10n/app_localizations.dart';
import 'reserve_controller.dart';

/// Lists and manages the household's real and virtual reserves.
final class ReservesScreen extends ConsumerWidget {
  const ReservesScreen({required this.service, required this.today, super.key});

  final LocalRebootService service;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mutation = ref.watch(reserveControllerProvider);
    final reserves = service.reserves.reserves.values.toList()
      ..sort((left, right) => left.name.compareTo(right.name));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reservesTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text(l10n.reservesIntro),
            const SizedBox(height: 16),
            if (reserves.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(l10n.noReserveYet, textAlign: TextAlign.center),
                ),
              )
            else ...[
              Text(
                l10n.totalReserves(
                  _formatMoney(context, service.reserves.totalBalance),
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final reserve in reserves)
                _ReserveCard(
                  reserve: reserve,
                  busy: mutation.isLoading,
                  onFund: () => _fund(context, ref, reserve),
                  onUse: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => QuickExpenseScreen(
                        service: service,
                        today: today,
                        initialReserveId: reserve.id,
                      ),
                    ),
                  ),
                  onReverse: (movement) =>
                      _reverse(context, ref, reserve, movement),
                ),
            ],
            if (mutation.hasError) ...[
              const SizedBox(height: 12),
              Text(
                l10n.reserveMutationError,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('create-reserve'),
        onPressed: mutation.isLoading ? null : () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.createReserve),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final draft = await showDialog<_ReserveDraft>(
      context: context,
      builder: (_) => const _CreateReserveDialog(),
    );
    if (draft == null || !context.mounted) return;
    await ref
        .read(reserveControllerProvider.notifier)
        .create(
          CreateReserveCommand(
            name: draft.name,
            kind: draft.kind,
            openingBalance: draft.amount,
            businessDate: today,
          ),
        );
  }

  Future<void> _fund(
    BuildContext context,
    WidgetRef ref,
    ProjectedReserve reserve,
  ) async {
    final draft = await showDialog<_MovementDraft>(
      context: context,
      builder: (_) => const _MovementDialog(),
    );
    if (draft == null || !context.mounted) return;
    if (reserve.kind == ReserveKind.real) {
      final l10n = AppLocalizations.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.realReserveTransferTitle),
          content: Text(
            l10n.realReserveFundingTransferBody(
              _formatMoney(context, draft.amount),
              reserve.name,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const ValueKey('confirm-real-reserve-funding'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.confirmRealReserveFunding),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    await ref
        .read(reserveControllerProvider.notifier)
        .addFunds(
          AddReserveFundsCommand(
            reserveId: reserve.id,
            amount: draft.amount,
            label: draft.label,
            businessDate: today,
          ),
        );
  }

  Future<void> _reverse(
    BuildContext context,
    WidgetRef ref,
    ProjectedReserve reserve,
    ProjectedReserveMovement movement,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.reverseReserveMovementTitle),
        content: Text(l10n.reverseReserveMovementBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.reverseReserveMovement),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(reserveControllerProvider.notifier)
        .reverse(
          ReverseReserveMovementCommand(
            reserveId: reserve.id,
            movementEventId: movement.eventId,
            businessDate: today,
          ),
        );
  }
}

final class _ReserveCard extends StatelessWidget {
  const _ReserveCard({
    required this.reserve,
    required this.busy,
    required this.onFund,
    required this.onUse,
    required this.onReverse,
  });

  final ProjectedReserve reserve;
  final bool busy;
  final VoidCallback onFund;
  final VoidCallback onUse;
  final ValueChanged<ProjectedReserveMovement> onReverse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  reserve.kind == ReserveKind.real
                      ? Icons.account_balance_outlined
                      : Icons.savings_outlined,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reserve.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        reserve.kind == ReserveKind.real
                            ? l10n.realReserve
                            : l10n.virtualReserve,
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatMoney(context, reserve.balance),
                  key: ValueKey('reserve-balance-${reserve.id.value}'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onFund,
                    icon: const Icon(Icons.add_card_outlined),
                    label: Text(l10n.addReserveFunds),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy || reserve.balance.isZero ? null : onUse,
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Text(l10n.useReserve),
                  ),
                ),
              ],
            ),
            if (reserve.movements.isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                l10n.reserveHistory,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final movement in reserve.movements.reversed.take(5))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    movement.label,
                    style: movement.isReversed
                        ? const TextStyle(
                            decoration: TextDecoration.lineThrough,
                          )
                        : null,
                  ),
                  subtitle: Text(
                    movement.isReversed
                        ? l10n.reversedReserveMovement
                        : _formatDate(context, movement.businessDate),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${movement.kind == ReserveMovementKind.funding ? '+' : '−'}'
                        '${_formatMoney(context, movement.amount)}',
                      ),
                      if (!movement.isReversed)
                        IconButton(
                          tooltip: l10n.reverseReserveMovement,
                          onPressed: busy ? null : () => onReverse(movement),
                          icon: const Icon(Icons.undo),
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
}

final class _CreateReserveDialog extends StatefulWidget {
  const _CreateReserveDialog();

  @override
  State<_CreateReserveDialog> createState() => _CreateReserveDialogState();
}

final class _CreateReserveDialogState extends State<_CreateReserveDialog> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController(text: '0');
  ReserveKind _kind = ReserveKind.virtual;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.createReserve),
      content: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('reserve-name'),
                controller: _name,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.reserveName),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.requiredField
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ReserveKind>(
                initialValue: _kind,
                decoration: InputDecoration(labelText: l10n.reserveKind),
                items: [
                  DropdownMenuItem(
                    value: ReserveKind.virtual,
                    child: Text(l10n.virtualReserve),
                  ),
                  DropdownMenuItem(
                    value: ReserveKind.real,
                    child: Text(l10n.realReserve),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _kind = value ?? ReserveKind.virtual),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('reserve-opening-balance'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.reserveOpeningBalance,
                  suffixText: '€',
                ),
                validator: (value) =>
                    parseNonNegativeEuroAmount(value ?? '') == null
                    ? l10n.invalidNonNegativeAmount
                    : null,
              ),
              const SizedBox(height: 8),
              Text(l10n.reserveOpeningBalanceHelp),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('confirm-create-reserve'),
          onPressed: () {
            if (!_key.currentState!.validate()) return;
            Navigator.pop(
              context,
              _ReserveDraft(
                name: _name.text,
                kind: _kind,
                amount: parseNonNegativeEuroAmount(_amount.text)!,
              ),
            );
          },
          child: Text(l10n.createReserve),
        ),
      ],
    );
  }
}

final class _MovementDialog extends StatefulWidget {
  const _MovementDialog();

  @override
  State<_MovementDialog> createState() => _MovementDialogState();
}

final class _MovementDialogState extends State<_MovementDialog> {
  final _key = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _label = TextEditingController();

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
      title: Text(l10n.addReserveFunds),
      content: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('reserve-funding-amount'),
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.reserveFundingAmount,
                suffixText: '€',
              ),
              validator: (value) => parsePositiveEuroAmount(value ?? '') == null
                  ? l10n.invalidPositiveAmount
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('reserve-funding-label'),
              controller: _label,
              decoration: InputDecoration(
                labelText: l10n.reserveFundingLabel,
                hintText: l10n.reserveFundingHint,
              ),
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
          key: const ValueKey('confirm-reserve-funding'),
          onPressed: () {
            if (!_key.currentState!.validate()) return;
            Navigator.pop(
              context,
              _MovementDraft(
                amount: parsePositiveEuroAmount(_amount.text)!,
                label: _label.text,
              ),
            );
          },
          child: Text(l10n.confirmReserveFunding),
        ),
      ],
    );
  }
}

final class _ReserveDraft {
  const _ReserveDraft({
    required this.name,
    required this.kind,
    required this.amount,
  });

  final String name;
  final ReserveKind kind;
  final Money amount;
}

final class _MovementDraft {
  const _MovementDraft({required this.amount, required this.label});

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
    ).formatShortDate(DateTime(date.year, date.month, date.day));
