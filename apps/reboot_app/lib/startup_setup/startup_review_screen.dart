import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

import '../financial_setup/euro_amount_parser.dart';
import '../formatting/exact_money_formatter.dart';
import '../infrastructure/device_context_providers.dart';
import '../l10n/app_localizations.dart';
import 'startup_review_controller.dart';

/// Fresh account check required before increasing to the durable budget.
final class StartupReviewScreen extends ConsumerStatefulWidget {
  const StartupReviewScreen({
    required this.service,
    required this.today,
    super.key,
  });

  final LocalRebootService service;
  final LocalDate today;

  @override
  ConsumerState<StartupReviewScreen> createState() =>
      _StartupReviewScreenState();
}

final class _StartupReviewScreenState
    extends ConsumerState<StartupReviewScreen> {
  final _booked = TextEditingController();
  final _pendingCard = TextEditingController(text: '0');
  final _deferredCard = TextEditingController(text: '0');
  final _cheques = TextEditingController(text: '0');
  final _transfers = TextEditingController(text: '0');
  final _protected = TextEditingController(text: '0');
  var _checkedToday = true;
  var _allPendingKnown = true;
  var _noUnfundedLargeExpense = true;
  StartupViabilityAnswer? _viability;
  String? _validationError;

  @override
  void dispose() {
    for (final controller in [
      _booked,
      _pendingCard,
      _deferredCard,
      _cheques,
      _transfers,
      _protected,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(startupReviewControllerProvider);
    final review = state.value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.launchReviewTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Text(
              l10n.launchReviewIntro,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            _ReviewSummary(service: widget.service),
            const SizedBox(height: 16),
            _AmountField(
              key: const ValueKey('launch-review-booked'),
              controller: _booked,
              label: l10n.bookedBalanceLabel,
              signed: true,
            ),
            _AmountField(
              controller: _pendingCard,
              label: l10n.pendingCardLabel,
            ),
            _AmountField(
              controller: _deferredCard,
              label: l10n.deferredCardLabel,
            ),
            _AmountField(
              controller: _cheques,
              label: l10n.outstandingChequesLabel,
            ),
            _AmountField(
              controller: _transfers,
              label: l10n.committedTransfersLabel,
            ),
            _AmountField(
              controller: _protected,
              label: l10n.protectedAllocationsLabel,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _checkedToday,
              onChanged: (value) =>
                  setState(() => _checkedToday = value ?? false),
              title: Text(l10n.accountCheckedToday),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _allPendingKnown,
              onChanged: (value) =>
                  setState(() => _allPendingKnown = value ?? false),
              title: Text(l10n.allPendingKnown),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _noUnfundedLargeExpense,
              onChanged: (value) =>
                  setState(() => _noUnfundedLargeExpense = value ?? false),
              title: Text(l10n.noUnfundedLargeExpense),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.launchReviewViability,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            RadioGroup<StartupViabilityAnswer>(
              key: const ValueKey('launch-review-viability-group'),
              groupValue: _viability,
              onChanged: (value) => setState(() => _viability = value),
              child: Column(
                children: [
                  RadioListTile<StartupViabilityAnswer>(
                    key: const ValueKey('launch-review-comfortable'),
                    value: StartupViabilityAnswer.comfortable,
                    title: Text(l10n.viabilityComfortable),
                  ),
                  RadioListTile<StartupViabilityAnswer>(
                    value: StartupViabilityAnswer.tight,
                    title: Text(l10n.viabilityTight),
                  ),
                  RadioListTile<StartupViabilityAnswer>(
                    value: StartupViabilityAnswer.rejected,
                    title: Text(l10n.viabilityNo),
                  ),
                ],
              ),
            ),
            if (_validationError != null || state.hasError) ...[
              const SizedBox(height: 12),
              _Notice(
                error: true,
                text: state.hasError
                    ? l10n.launchReviewSaveError
                    : _validationError!,
              ),
            ],
            if (review != null) ...[
              const SizedBox(height: 12),
              _Notice(
                error: !review.completed,
                text: review.completed
                    ? l10n.launchReviewCompleted
                    : _outcomeMessage(l10n, review.review.outcome),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.launchReviewProjection(
                  _money(context, review.review.projectedLowPoint),
                  _money(context, review.review.cashDivergence),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('launch-review-submit'),
              onPressed: state.isLoading ? null : _submit,
              icon: state.isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(l10n.launchReviewAction),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _validationError = null);
    final booked = parseSignedEuroAmount(_booked.text);
    final pending = [
      parseNonNegativeEuroAmount(_pendingCard.text),
      parseNonNegativeEuroAmount(_deferredCard.text),
      parseNonNegativeEuroAmount(_cheques.text),
      parseNonNegativeEuroAmount(_transfers.text),
      parseNonNegativeEuroAmount(_protected.text),
    ];
    if (booked == null || pending.any((amount) => amount == null)) {
      setState(() => _validationError = l10n.startupInvalidAmountError);
      return;
    }
    if (_viability == null) {
      setState(() => _validationError = l10n.startupViabilityRequiredError);
      return;
    }
    final result = await ref
        .read(startupReviewControllerProvider.notifier)
        .submit(
          ReviewStartupLaunchCommand(
            liquidity: LiquiditySnapshot(
              capturedAtUtc: ref.read(currentInstantProvider),
              bookedBalance: booked,
              pendingCardAmount: pending[0],
              deferredCardAmount: pending[1],
              outstandingCheques: pending[2],
              committedTransfers: pending[3],
              protectedVirtualAllocations: pending[4],
              source: LiquiditySnapshotSource.manual,
              confidence: _checkedToday
                  ? StartupDataConfidence.high
                  : StartupDataConfidence.medium,
            ),
            allPendingOperationsKnown: _allPendingKnown,
            noUnfundedLargeExpense: _noUnfundedLargeExpense,
            viabilityAnswer: _viability!,
            businessDate: widget.today,
          ),
        );
    if (result?.completed ?? false) {
      if (mounted) Navigator.of(context).pop();
    }
  }
}

final class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({required this.service});

  final LocalRebootService service;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accepted = service.startup.acceptedPlan!;
    final cushion = service.startup.cushionPolicy!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.launchReviewCurrentPlan(
                _money(context, accepted.launchWeeklyBudget),
                _money(context, accepted.sustainableWeeklyBudget),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.launchReviewTargetCushion(
                _money(context, cushion.targetCashCushion),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.label,
    this.signed = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool signed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: signed,
      ),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        suffixText: 'EUR',
      ),
    ),
  );
}

final class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.error});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) => Card(
    color: error
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.primaryContainer,
    child: Padding(padding: const EdgeInsets.all(16), child: Text(text)),
  );
}

String _outcomeMessage(
  AppLocalizations l10n,
  LaunchReviewOutcome outcome,
) => switch (outcome) {
  LaunchReviewOutcome.pendingOperationsUnknown =>
    l10n.launchReviewPendingUnknown,
  LaunchReviewOutcome.upcomingExpenseUnfunded =>
    l10n.launchReviewExpenseUnfunded,
  LaunchReviewOutcome.dataNotFresh => l10n.launchReviewDataNotFresh,
  LaunchReviewOutcome.cushionNotReached => l10n.launchReviewCushionNotReached,
  LaunchReviewOutcome.projectedFloorBreached => l10n.launchReviewFloorBreached,
  LaunchReviewOutcome.structurallyTooTight =>
    l10n.launchReviewStructurallyTight,
  LaunchReviewOutcome.humanViabilityNotConfirmed =>
    l10n.launchReviewHumanNotConfirmed,
  LaunchReviewOutcome.safeToComplete => l10n.launchReviewCompleted,
};

String _money(BuildContext context, Money amount) => formatMoneyExact(
  amount,
  locale: Localizations.localeOf(context).toLanguageTag(),
);
