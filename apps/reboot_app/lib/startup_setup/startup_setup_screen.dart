import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';

import '../financial_setup/euro_amount_parser.dart';
import '../formatting/exact_money_formatter.dart';
import '../infrastructure/device_context_providers.dart';
import '../l10n/app_localizations.dart';
import 'startup_setup_controller.dart';

/// Mandatory eight-step safety check before the first piloted cycle.
final class StartupSetupScreen extends ConsumerStatefulWidget {
  const StartupSetupScreen({required this.service, super.key});

  final LocalRebootService service;

  @override
  ConsumerState<StartupSetupScreen> createState() => _StartupSetupScreenState();
}

final class _StartupSetupScreenState extends ConsumerState<StartupSetupScreen> {
  final _booked = TextEditingController(text: '0');
  final _pendingCard = TextEditingController(text: '0');
  final _deferredCard = TextEditingController(text: '0');
  final _cheques = TextEditingController(text: '0');
  final _transfers = TextEditingController(text: '0');
  final _protected = TextEditingController(text: '0');
  final _authorizedOverdraft = TextEditingController(text: '0');
  final _targetBalance = TextEditingController(text: '0');
  final _upcomingExpense = TextEditingController(text: '0');
  final _persons14Plus = TextEditingController(text: '1');
  final _childrenUnder14 = TextEditingController(text: '0');
  final _minimumViable = TextEditingController();
  final _uncertaintyMargin = TextEditingController();
  final _ownedCushion = TextEditingController(text: '0');

  final _scope = <WeeklyBudgetCategory>{
    WeeklyBudgetCategory.groceries,
    WeeklyBudgetCategory.hygiene,
    WeeklyBudgetCategory.everydayPurchases,
  };
  var _step = 0;
  var _checkedToday = true;
  var _allPendingKnown = true;
  var _acceptedBankRisk = false;
  var _commitment = false;
  LocalDate? _upcomingExpenseDate;
  StartupViabilityAnswer? _viabilityAnswer;
  LiquiditySnapshot? _liquidity;
  HouseholdNeedsProfile? _needs;
  AnnualBudgetProjection? _annual;
  StartupCashProjection? _baseProjection;
  StartupLiquidityAssessment? _assessment;
  LaunchPlanSearchResult? _plans;
  LaunchPlanCandidate? _selectedPlan;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _booked,
      _pendingCard,
      _deferredCard,
      _cheques,
      _transfers,
      _protected,
      _authorizedOverdraft,
      _targetBalance,
      _upcomingExpense,
      _persons14Plus,
      _childrenUnder14,
      _minimumViable,
      _uncertaintyMargin,
      _ownedCushion,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final device = switch (ref.watch(onboardingDeviceContextProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final submission = ref.watch(startupSetupControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.startupSafetyTitle)),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_step + 1) / 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                children: [
                  Text(
                    l10n.startupStep(_step + 1),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildStep(context),
                  if (_error != null || submission.hasError) ...[
                    const SizedBox(height: 20),
                    _ErrorNotice(
                      message: submission.hasError
                          ? l10n.startupSaveError
                          : _error!,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: submission.isLoading ? null : _back,
                        child: Text(l10n.wizardBack),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('startup-continue'),
                      onPressed: device == null || submission.isLoading
                          ? null
                          : () => _continue(device),
                      child: submission.isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(child: Text(l10n.startupSaving)),
                              ],
                            )
                          : Text(
                              _step == 0
                                  ? l10n.startupCheckAction
                                  : _step == 7
                                  ? l10n.confirmStartupPlan
                                  : l10n.wizardNext,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) => switch (_step) {
    0 => _explanation(context),
    1 => _account(context),
    2 => _upcoming(context),
    3 => _household(context),
    4 => _simulation(context),
    5 => _funding(context),
    6 => _humanValidation(context),
    7 => _summary(context),
    _ => const SizedBox.shrink(),
  };

  Widget _heading(BuildContext context, IconData icon, String title) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 12),
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
    ],
  );

  Widget _explanation(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, Icons.shield_outlined, l10n.startupCushionTitle),
        Text(l10n.startupCushionBody),
        const SizedBox(height: 20),
        _ConceptCard(
          icon: Icons.flag_outlined,
          title: l10n.startupGoalConceptTitle,
          body: l10n.startupGoalConceptBody,
        ),
        _ConceptCard(
          icon: Icons.waves_outlined,
          title: l10n.startupCushionConceptTitle,
          body: l10n.startupCushionConceptBody,
        ),
        _ConceptCard(
          icon: Icons.account_balance_outlined,
          title: l10n.startupFundingConceptTitle,
          body: l10n.startupFundingConceptBody,
        ),
      ],
    );
  }

  Widget _account(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          context,
          Icons.account_balance_wallet_outlined,
          l10n.startupAccountTitle,
        ),
        Text(l10n.startupAccountBody),
        const SizedBox(height: 20),
        _MoneyInput(
          controller: _booked,
          label: l10n.bookedBalanceLabel,
          signed: true,
          fieldKey: const ValueKey('startup-booked-balance'),
        ),
        _MoneyInput(controller: _pendingCard, label: l10n.pendingCardLabel),
        _MoneyInput(controller: _deferredCard, label: l10n.deferredCardLabel),
        _MoneyInput(controller: _cheques, label: l10n.outstandingChequesLabel),
        _MoneyInput(
          controller: _transfers,
          label: l10n.committedTransfersLabel,
        ),
        _MoneyInput(
          controller: _protected,
          label: l10n.protectedAllocationsLabel,
        ),
        _MoneyInput(
          controller: _authorizedOverdraft,
          label: l10n.authorizedOverdraftLabel,
          fieldKey: const ValueKey('startup-authorized-overdraft'),
        ),
        _MoneyInput(
          controller: _targetBalance,
          label: l10n.targetBalanceLabel,
          signed: true,
          fieldKey: const ValueKey('startup-target-balance'),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _checkedToday,
          onChanged: (value) => setState(() => _checkedToday = value ?? false),
          title: Text(l10n.accountCheckedToday),
        ),
      ],
    );
  }

  Widget _upcoming(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, Icons.event_note_outlined, l10n.startupUpcomingTitle),
        Text(l10n.startupUpcomingBody),
        const SizedBox(height: 20),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _allPendingKnown,
          onChanged: (value) =>
              setState(() => _allPendingKnown = value ?? false),
          title: Text(l10n.allPendingKnown),
        ),
        _MoneyInput(
          controller: _upcomingExpense,
          label: l10n.upcomingExpenseAmountLabel,
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          leading: const Icon(Icons.edit_calendar_outlined),
          title: Text(l10n.upcomingExpenseDateLabel),
          subtitle: Text(
            _upcomingExpenseDate == null
                ? '—'
                : _formatDate(context, _upcomingExpenseDate!),
          ),
          onTap: _pickUpcomingDate,
        ),
      ],
    );
  }

  Widget _household(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = <(WeeklyBudgetCategory, String)>[
      (WeeklyBudgetCategory.groceries, l10n.scopeGroceries),
      (WeeklyBudgetCategory.fuel, l10n.scopeFuel),
      (WeeklyBudgetCategory.hygiene, l10n.scopeHygiene),
      (WeeklyBudgetCategory.children, l10n.scopeChildren),
      (WeeklyBudgetCategory.healthOutOfPocket, l10n.scopeHealth),
      (WeeklyBudgetCategory.everydayPurchases, l10n.scopeLeisure),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, Icons.groups_outlined, l10n.startupHouseholdTitle),
        _IntegerInput(
          controller: _persons14Plus,
          label: l10n.persons14PlusLabel,
        ),
        _IntegerInput(
          controller: _childrenUnder14,
          label: l10n.childrenUnder14Label,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.weeklyScopeTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final category in categories)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _scope.contains(category.$1),
            onChanged: (selected) => setState(() {
              if (selected ?? false) {
                _scope.add(category.$1);
              } else {
                _scope.remove(category.$1);
              }
            }),
            title: Text(category.$2),
          ),
        _MoneyInput(
          controller: _minimumViable,
          label: l10n.minimumViableBudgetLabel,
          positive: true,
          fieldKey: const ValueKey('startup-minimum-viable'),
        ),
      ],
    );
  }

  Widget _simulation(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final annual = _annual!;
    final projection = _baseProjection!;
    final feasibility = HouseholdBudgetFeasibility(
      profile: _needs!,
      testedWeeklyBudget: annual.recommendedWeeklyBudget,
      sustainableWeeklyBudget: annual.recommendedWeeklyBudget,
    );
    final margin =
        parseNonNegativeEuroAmount(_uncertaintyMargin.text) ??
        annual.recommendedWeeklyBudget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, Icons.timeline_outlined, l10n.startupSimulationTitle),
        _ResultLine(
          icon: Icons.calendar_view_week_outlined,
          text: l10n.sustainableBudgetResult(
            _money(context, annual.recommendedWeeklyBudget),
          ),
        ),
        _ResultLine(
          icon: Icons.account_balance_wallet_outlined,
          text: l10n.availableCashResult(
            _money(context, _liquidity!.usableCash),
          ),
        ),
        _ResultLine(
          icon: Icons.flag_outlined,
          text: l10n.balanceObjectiveResult(
            _money(context, _signed(_targetBalance)),
          ),
        ),
        _ResultLine(
          icon: Icons.south_east,
          text: l10n.projectedLowResult(
            _money(context, projection.projectedLowPoint),
            _formatDate(context, projection.projectedLowPointDate),
          ),
        ),
        _ResultLine(
          icon: Icons.waves_outlined,
          text: l10n.technicalCushionResult(
            _money(context, projection.technicalCashCushion),
          ),
        ),
        _MoneyInput(
          controller: _uncertaintyMargin,
          label: l10n.uncertaintyMarginLabel,
          fieldKey: const ValueKey('startup-uncertainty-margin'),
        ),
        _ResultLine(
          icon: Icons.shield_outlined,
          text: l10n.targetCushionResult(
            _money(context, projection.technicalCashCushion + margin),
          ),
        ),
        _ResultLine(
          icon: Icons.person_outline,
          text: l10n.budgetPerPersonResult(
            _money(context, feasibility.budgetPerPerson),
          ),
        ),
        _ResultLine(
          icon: Icons.groups_outlined,
          text: l10n.budgetPerConsumptionUnitResult(
            _money(context, feasibility.budgetPerConsumptionUnit),
          ),
        ),
        _ResultLine(
          icon: Icons.check_circle_outline,
          text: l10n.minimumCoverageResult(
            (feasibility.viabilityBasisPoints / 100).toStringAsFixed(0),
          ),
        ),
      ],
    );
  }

  Widget _funding(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final assessment = _assessment;
    final targetCushion = _baseProjection!.technicalCashCushion + _margin();
    final enteredOwned = parseNonNegativeEuroAmount(_ownedCushion.text);
    final bank =
        enteredOwned != null && enteredOwned.compareTo(targetCushion) <= 0
        ? targetCushion - enteredOwned
        : assessment?.funding.overdraftFundedCash ?? Money.zero(Currency.eur);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, Icons.savings_outlined, l10n.startupFundingTitle),
        Text(l10n.startupFundingBody),
        const SizedBox(height: 20),
        _MoneyInput(
          controller: _ownedCushion,
          label: l10n.ownedCushionLabel,
          fieldKey: const ValueKey('startup-owned-cushion'),
          onChanged: (_) {
            _acceptedBankRisk = false;
            _refreshFundingPreview();
          },
        ),
        const SizedBox(height: 8),
        _ResultLine(
          icon: Icons.account_balance_outlined,
          text: l10n.bankCushionResult(_money(context, bank)),
        ),
        if (assessment != null) ...[
          _ResultLine(
            icon: Icons.account_balance_wallet_outlined,
            text: l10n.operatingBalanceResult(
              _money(context, assessment.funding.operatingBalance),
            ),
          ),
          _ResultLine(
            icon: Icons.south_east,
            text: l10n.allowedLowResult(
              _money(context, assessment.funding.lowestAllowedBalance),
            ),
          ),
          _ResultLine(
            icon: Icons.trending_up,
            text: l10n.requiredProgressResult(
              _money(context, assessment.requiredProgress),
            ),
          ),
        ],
        if (bank.isPositive) ...[
          _WarningNotice(message: l10n.bankCushionWarning),
          CheckboxListTile(
            key: const ValueKey('startup-bank-risk'),
            contentPadding: EdgeInsets.zero,
            value: _acceptedBankRisk,
            onChanged: (value) =>
                setState(() => _acceptedBankRisk = value ?? false),
            title: Text(l10n.acceptBankCushionRisk),
          ),
        ],
        const SizedBox(height: 12),
        if (assessment?.canStartDirectly ?? false)
          RadioGroup<LaunchPlanCandidate?>(
            groupValue: _selectedPlan,
            onChanged: (_) => setState(() => _selectedPlan = null),
            child: RadioListTile<LaunchPlanCandidate?>(
              value: null,
              title: Text(
                l10n.directStartOption(
                  _money(context, _annual!.recommendedWeeklyBudget),
                ),
              ),
            ),
          )
        else if (_plans?.isFeasible ?? false)
          RadioGroup<LaunchPlanCandidate?>(
            groupValue: _selectedPlan,
            onChanged: (value) => setState(() => _selectedPlan = value),
            child: Column(
              children: [
                for (final plan in _plans!.primarySuggestions)
                  RadioListTile<LaunchPlanCandidate?>(
                    value: plan,
                    title: Text(
                      l10n.launchPlanOption(
                        _money(context, plan.launchWeeklyBudget),
                        plan.durationCycles,
                        _money(context, plan.sustainableWeeklyBudget),
                      ),
                    ),
                    subtitle: plan.hasSevereCompression
                        ? Text(
                            l10n.startupSevereEffort(
                              (plan.compressionBasisPoints / 100)
                                  .toStringAsFixed(0),
                            ),
                          )
                        : null,
                  ),
              ],
            ),
          )
        else
          _WarningNotice(message: l10n.startupNoSafePlan),
      ],
    );
  }

  Widget _humanValidation(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final budget =
        _selectedPlan?.launchWeeklyBudget ?? _annual!.recommendedWeeklyBudget;
    final weeks = _selectedPlan?.durationCycles ?? 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, Icons.favorite_outline, l10n.startupHumanTitle),
        Text(l10n.startupHumanQuestion(_money(context, budget), weeks)),
        const SizedBox(height: 12),
        RadioGroup<StartupViabilityAnswer>(
          groupValue: _viabilityAnswer,
          onChanged: (value) => setState(() => _viabilityAnswer = value),
          child: Column(
            children: [
              for (final option in <(StartupViabilityAnswer, String)>[
                (StartupViabilityAnswer.comfortable, l10n.viabilityComfortable),
                (StartupViabilityAnswer.tight, l10n.viabilityTight),
                (StartupViabilityAnswer.rejected, l10n.viabilityNo),
                (StartupViabilityAnswer.uncertain, l10n.viabilityUnknown),
              ])
                RadioListTile<StartupViabilityAnswer>(
                  key: option.$1 == StartupViabilityAnswer.comfortable
                      ? const ValueKey('startup-viability-comfortable')
                      : null,
                  value: option.$1,
                  title: Text(option.$2),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summary(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final funding = _assessment!.funding;
    final budget =
        _selectedPlan?.launchWeeklyBudget ?? _annual!.recommendedWeeklyBudget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, Icons.fact_check_outlined, l10n.startupSummaryTitle),
        _ResultLine(
          icon: Icons.flag_outlined,
          text: l10n.targetBalanceResult(
            _money(context, funding.targetBalance),
          ),
        ),
        _ResultLine(
          icon: Icons.account_balance_wallet_outlined,
          text: l10n.operatingBalanceResult(
            _money(context, funding.operatingBalance),
          ),
        ),
        _ResultLine(
          icon: Icons.south_east,
          text: l10n.allowedLowResult(
            _money(context, funding.lowestAllowedBalance),
          ),
        ),
        _ResultLine(
          icon: Icons.calendar_view_week_outlined,
          text: _selectedPlan == null
              ? l10n.directStartOption(_money(context, budget))
              : l10n.launchPlanOption(
                  _money(context, budget),
                  _selectedPlan!.durationCycles,
                  _money(context, _annual!.recommendedWeeklyBudget),
                ),
        ),
        CheckboxListTile(
          key: const ValueKey('startup-commitment'),
          contentPadding: EdgeInsets.zero,
          value: _commitment,
          onChanged: (value) => setState(() => _commitment = value ?? false),
          title: Text(l10n.startupCommitment),
        ),
      ],
    );
  }

  Future<void> _continue(OnboardingDeviceContext device) async {
    setState(() => _error = null);
    try {
      switch (_step) {
        case 0:
          _go(1);
        case 1:
          _liquidity = LiquiditySnapshot(
            capturedAtUtc: ref.read(currentInstantProvider),
            bookedBalance: _signed(_booked),
            pendingCardAmount: _nonNegative(_pendingCard),
            deferredCardAmount: _nonNegative(_deferredCard),
            outstandingCheques: _nonNegative(_cheques),
            committedTransfers: _nonNegative(_transfers),
            protectedVirtualAllocations: _nonNegative(_protected),
            source: LiquiditySnapshotSource.manual,
            confidence: _checkedToday
                ? StartupDataConfidence.high
                : StartupDataConfidence.medium,
          );
          _signed(_targetBalance);
          _nonNegative(_authorizedOverdraft);
          _go(2);
        case 2:
          if (!_allPendingKnown) {
            throw FormatException(
              AppLocalizations.of(context).startupPendingIncompleteError,
            );
          }
          final upcoming = _nonNegative(_upcomingExpense);
          if (upcoming.isPositive && _upcomingExpenseDate == null) {
            throw FormatException(
              AppLocalizations.of(context).startupExpenseDateRequiredError,
            );
          }
          _go(3);
        case 3:
          _calculateBase(device.localDate);
          _go(4);
        case 4:
          _calculateFundingAndPlans();
          _go(5);
        case 5:
          if (_assessment == null) _calculateFundingAndPlans();
          if (!(_assessment!.canStartDirectly ||
              (_plans?.isFeasible ?? false))) {
            throw FormatException(
              AppLocalizations.of(context).startupNoSafePlan,
            );
          }
          if (_assessment!.funding.usesBankFunding && !_acceptedBankRisk) {
            throw FormatException(
              AppLocalizations.of(context).startupBankRiskRequiredError,
            );
          }
          _go(6);
        case 6:
          if (_viabilityAnswer != StartupViabilityAnswer.comfortable &&
              _viabilityAnswer != StartupViabilityAnswer.tight) {
            throw FormatException(
              AppLocalizations.of(context).startupViabilityRequiredError,
            );
          }
          _go(7);
        case 7:
          if (!_commitment) {
            throw FormatException(
              AppLocalizations.of(context).startupCommitmentRequiredError,
            );
          }
          final initialIsNegative = _liquidity!.usableCash.isNegative;
          final state = _selectedPlan == null
              ? LaunchDecisionState.readyWithExistingCushion
              : initialIsNegative
              ? LaunchDecisionState.readyWithOverdraftRecovery
              : LaunchDecisionState.readyWithLaunchBudget;
          await ref
              .read(startupSetupControllerProvider.notifier)
              .submit(
                AcceptStartupPlanCommand(
                  liquidity: _liquidity!,
                  householdNeeds: _needs!,
                  assessment: _assessment!,
                  selectedLaunchPlan: _selectedPlan,
                  startDate: _annual!.start,
                  decisionState: state,
                  viabilityAnswer: _viabilityAnswer!,
                  businessDate: device.localDate,
                  acceptedBankFundingRisk: _acceptedBankRisk,
                ),
              );
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    }
  }

  void _calculateBase(LocalDate businessDate) {
    final adults = int.tryParse(_persons14Plus.text.trim());
    final children = int.tryParse(_childrenUnder14.text.trim());
    if (adults == null || adults < 1 || children == null || children < 0) {
      throw FormatException(
        AppLocalizations.of(context).startupHouseholdInvalidError,
      );
    }
    _needs = HouseholdNeedsProfile(
      fullTimePersons14OrOlder: adults,
      fullTimeChildrenUnder14: children,
      weeklyBudgetScope: _scope,
      minimumViableWeeklyBudget: _positive(_minimumViable),
    );
    final firstStart = widget.service.configuration.household!.firstCycleStart;
    _annual = widget.service.buildAnnualBudget(firstStart);
    if (!_annual!.recommendedWeeklyBudget.isPositive) {
      throw FormatException(
        AppLocalizations.of(context).startupNoPositiveBudgetError,
      );
    }
    if (_annual!.recommendedWeeklyBudget.compareTo(
          _needs!.minimumViableWeeklyBudget,
        ) <
        0) {
      throw FormatException(
        AppLocalizations.of(context).startupBelowMinimumError,
      );
    }
    final movements = List<StartupCashMovement>.of(
      StartupCashProjectionEngine.movementsFromAnnualBudget(_annual!),
    );
    final upcoming = _nonNegative(_upcomingExpense);
    if (upcoming.isPositive) {
      final date = _upcomingExpenseDate!;
      if (date.isBefore(firstStart) || date.isAfter(firstStart.addDays(83))) {
        throw FormatException(
          AppLocalizations.of(context).startupExpenseOutsideWindowError,
        );
      }
      movements.add(
        StartupCashMovement(
          date: date,
          amount: upcoming,
          kind: StartupCashMovementKind.irregularExpense,
        ),
      );
    }
    _baseProjection = StartupCashProjectionEngine.project(
      cycles: _annual!.cycles,
      initialUsableCash: _liquidity!.usableCash,
      movements: movements,
      weeklyBudgetsByCycleStart: {
        for (final cycle in _annual!.cycles)
          cycle.start: _annual!.recommendedWeeklyBudget,
      },
    );
    _uncertaintyMargin.text = _plainEuros(_annual!.recommendedWeeklyBudget);
    final targetCushion = _baseProjection!.technicalCashCushion + _margin();
    _ownedCushion.text = _plainEuros(targetCushion);
    _assessment = null;
    _plans = null;
    _selectedPlan = null;
  }

  void _calculateFundingAndPlans() {
    final targetCushion = _baseProjection!.technicalCashCushion + _margin();
    final owned = _nonNegative(_ownedCushion);
    if (owned.compareTo(targetCushion) > 0) {
      throw FormatException(
        AppLocalizations.of(context).startupOwnedCushionTooHighError,
      );
    }
    final funding = CashCushionFunding(
      targetBalance: _signed(_targetBalance),
      ownedCash: owned,
      authorizedOverdraft: _nonNegative(_authorizedOverdraft),
      overdraftFundedCash: targetCushion - owned,
    );
    _assessment = StartupLiquidityAssessment(
      projection: _baseProjection!,
      uncertaintyMargin: _margin(),
      funding: funding,
    );
    final movements = List<StartupCashMovement>.of(
      StartupCashProjectionEngine.movementsFromAnnualBudget(_annual!),
    );
    final upcoming = _nonNegative(_upcomingExpense);
    if (upcoming.isPositive) {
      movements.add(
        StartupCashMovement(
          date: _upcomingExpenseDate!,
          amount: upcoming,
          kind: StartupCashMovementKind.irregularExpense,
        ),
      );
    }
    _plans = _assessment!.canStartDirectly
        ? null
        : LaunchPlanSearchEngine.search(
            cycles: _annual!.cycles,
            initialUsableCash: _liquidity!.usableCash,
            movements: movements,
            sustainableWeeklyBudget: _annual!.recommendedWeeklyBudget,
            minimumViableWeeklyBudget: _needs!.minimumViableWeeklyBudget,
            uncertaintyMargin: _margin(),
            funding: funding,
          );
    _selectedPlan = _plans?.recommended ?? _plans?.gentlest;
  }

  void _refreshFundingPreview() {
    setState(() {
      try {
        _calculateFundingAndPlans();
        _error = null;
      } on Object catch (error) {
        _assessment = null;
        _plans = null;
        _selectedPlan = null;
        _error = _message(error);
      }
    });
  }

  Money _margin() => _nonNegative(_uncertaintyMargin);

  Future<void> _pickUpcomingDate() async {
    final first = widget.service.configuration.household!.firstCycleStart;
    final initial = _upcomingExpenseDate ?? first.addDays(14);
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(first.year, first.month, first.day),
      lastDate: DateTime(
        first.addDays(83).year,
        first.addDays(83).month,
        first.addDays(83).day,
      ),
    );
    if (selected != null) {
      setState(() => _upcomingExpenseDate = LocalDate.fromDateTime(selected));
    }
  }

  void _back() => setState(() {
    _error = null;
    _step--;
  });

  void _go(int step) => setState(() {
    _error = null;
    _step = step;
  });

  Money _signed(TextEditingController controller) =>
      parseSignedEuroAmount(controller.text) ??
      (throw FormatException(
        AppLocalizations.of(context).startupInvalidAmountError,
      ));

  Money _nonNegative(TextEditingController controller) =>
      parseNonNegativeEuroAmount(controller.text) ??
      (throw FormatException(
        AppLocalizations.of(context).startupNonNegativeAmountError,
      ));

  Money _positive(TextEditingController controller) =>
      parsePositiveEuroAmount(controller.text) ??
      (throw FormatException(
        AppLocalizations.of(context).startupPositiveAmountError,
      ));

  String _message(Object error) => switch (error) {
    FormatException(:final message) => message,
    ArgumentError() => AppLocalizations.of(context).startupInvalidDataError,
    _ => AppLocalizations.of(context).startupSaveError,
  };
}

final class _MoneyInput extends StatelessWidget {
  const _MoneyInput({
    required this.controller,
    required this.label,
    this.signed = false,
    this.positive = false,
    this.onChanged,
    this.fieldKey,
  });

  final TextEditingController controller;
  final String label;
  final bool signed;
  final bool positive;
  final ValueChanged<String>? onChanged;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      key: fieldKey,
      controller: controller,
      onChanged: onChanged,
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

final class _IntegerInput extends StatelessWidget {
  const _IntegerInput({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
      ),
    ),
  );
}

final class _ConceptCard extends StatelessWidget {
  const _ConceptCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(body),
    ),
  );
}

final class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(leading: Icon(icon), title: Text(text)),
  );
}

final class _WarningNotice extends StatelessWidget {
  const _WarningNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.tertiaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

final class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    ),
  );
}

String _money(BuildContext context, Money money) => formatMoneyExact(
  money,
  locale: Localizations.localeOf(context).toLanguageTag(),
);

String _formatDate(BuildContext context, LocalDate date) => DateFormat.yMMMd(
  Localizations.localeOf(context).toLanguageTag(),
).format(DateTime(date.year, date.month, date.day));

String _plainEuros(Money amount) {
  final whole = amount.exactMinorUnits ~/ BigInt.from(100);
  final cents = amount.exactMinorUnits.remainder(BigInt.from(100)).abs();
  return cents == BigInt.zero
      ? whole.toString()
      : '$whole.${cents.toString().padLeft(2, '0')}';
}
