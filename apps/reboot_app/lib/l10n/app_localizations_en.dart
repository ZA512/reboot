// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'REBOOT';

  @override
  String get profileOpening => 'Opening your REBOOT profile';

  @override
  String get profileLockedTitle => 'The local profile cannot be opened.';

  @override
  String get profileLockedBody =>
      'No data was deleted or recreated. Unlock your device, then try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get welcomeHeadline =>
      'Take back control of your spending, one week at a time.';

  @override
  String get welcomeBody =>
      'REBOOT turns your income, expenses and goals into one simple weekly amount to follow.';

  @override
  String get encryptedProfileReady => 'Your encrypted local profile is ready.';

  @override
  String get startSetup => 'Set up my REBOOT';

  @override
  String get setupTitle => 'Set up your weekly rhythm';

  @override
  String get setupIntro =>
      'Choose the day when your weekly budget starts. We recommend the day of your main grocery shop, so essential food spending comes first.';

  @override
  String get householdQuestion => 'Who uses this weekly budget?';

  @override
  String get sharedHouseholdTitle => 'A shared main account';

  @override
  String get sharedHouseholdBody =>
      'Everyone spends from the same weekly budget, even with several cards.';

  @override
  String get soloHouseholdTitle => 'Just me';

  @override
  String get soloHouseholdBody => 'I manage one personal weekly budget.';

  @override
  String get rebootDayQuestion => 'What is your REBOOT day?';

  @override
  String get rebootDayHelp =>
      'You can change it later. Your history will keep the day that applied at the time.';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get startQuestion => 'When should the first week start?';

  @override
  String startNextTitle(String date) {
    return 'Start on $date';
  }

  @override
  String get startNextBody =>
      'The simplest option. You will begin with a complete new week.';

  @override
  String startPreviousTitle(String date) {
    return 'Start from $date';
  }

  @override
  String get startPreviousBody =>
      'Enter every weekly-budget expense made since that date so the balance is accurate.';

  @override
  String get startsToday => 'Your first REBOOT week starts today.';

  @override
  String get timeZoneTitle => 'Local time zone';

  @override
  String timeZoneDetected(String zone) {
    return 'Detected: $zone';
  }

  @override
  String get timeZoneLoading => 'Detecting the device time zone…';

  @override
  String get timeZoneError => 'The device time zone could not be verified.';

  @override
  String get detectAgain => 'Detect again';

  @override
  String get confirmSetup => 'Create my REBOOT profile';

  @override
  String get creatingProfile => 'Creating the encrypted profile…';

  @override
  String get setupError =>
      'The profile could not be created. Nothing was partially saved. Try again.';

  @override
  String get readySolo => 'Your personal REBOOT profile is ready.';

  @override
  String get readyShared => 'Your shared REBOOT profile is ready.';

  @override
  String get financialSetupTitle => 'List all money coming in and going out';

  @override
  String get financialSetupIntro =>
      'REBOOT annualizes these assumptions before calculating your weekly budget. Monthly is selected by default, but frequency and fixed or variable behavior are independent.';

  @override
  String get financialSetupTip =>
      'You may enter one total for all income or charges. Adding detail takes longer now, but will make future changes easier to detect.';

  @override
  String get incomeSectionTitle => 'Money coming in';

  @override
  String get incomeSectionBody =>
      'Salaries, benefits, pensions and every other predictable receipt.';

  @override
  String get outflowSectionTitle => 'Charges and smoothed expenses';

  @override
  String get outflowSectionBody =>
      'Include monthly, annual and non-monthly charges, plus unavoidable variable spending you prefer to smooth.';

  @override
  String get suggestionsLabel => 'Add a suggested line or a custom one:';

  @override
  String get deleteDraft => 'Delete this draft line';

  @override
  String get confirmFinancialSetup => 'Confirm income and charges';

  @override
  String get financialSetupSaving => 'Saving assumptions…';

  @override
  String get financialSetupMinimum =>
      'Add at least one income and one charge before continuing.';

  @override
  String get financialSetupError =>
      'Income and charges could not be saved. Nothing was partially recorded. Try again.';

  @override
  String get addIncomeTitle => 'Add money coming in';

  @override
  String get addOutflowTitle => 'Add a charge';

  @override
  String get cashFlowTitleLabel => 'Name';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get amountBehaviorLabel => 'Is the amount fixed or variable?';

  @override
  String get fixedAmount => 'Fixed';

  @override
  String get variableAmount => 'Variable';

  @override
  String get amountPerOccurrenceLabel => 'Amount at each payment';

  @override
  String get fixedAmountHelp => 'Enter the amount expected each time.';

  @override
  String get averageAmountLabel => 'Observed average at each payment';

  @override
  String get averageAmountHelp =>
      'Use your available history; REBOOT applies the strategy below.';

  @override
  String get invalidPositiveAmount =>
      'Enter an amount greater than zero, with no more than two decimals.';

  @override
  String get estimateStrategyLabel => 'Estimation strategy';

  @override
  String get strategyPrudent => 'Prudent';

  @override
  String get strategyBalanced => 'Balanced';

  @override
  String get strategyCustom => 'Custom';

  @override
  String get prudentIncomeHelp => 'REBOOT keeps 90% of the observed average.';

  @override
  String get prudentOutflowHelp =>
      'REBOOT budgets 110% of the observed average.';

  @override
  String get balancedHelp => 'REBOOT uses 100% of the observed average.';

  @override
  String get customStrategyHelp =>
      'Choose the amount REBOOT should use at each occurrence.';

  @override
  String get customAmountLabel => 'Amount used by REBOOT';

  @override
  String get frequencyLabel => 'Frequency';

  @override
  String get frequencyWeekly => 'Weekly';

  @override
  String get frequencyEveryFourWeeks => 'Every four weeks';

  @override
  String get frequencyMonthly => 'Monthly';

  @override
  String get frequencyQuarterly => 'Quarterly';

  @override
  String get frequencySemiAnnual => 'Every six months';

  @override
  String get frequencyAnnual => 'Annual';

  @override
  String get referenceDateLabel => 'Reference occurrence date';

  @override
  String get referenceDateHelp =>
      'Choose a past or upcoming date when this payment occurs. REBOOT preserves its weekday or intended day of month.';

  @override
  String get irregularFrequencyTip =>
      'For an unusual rhythm, calculate the total you expect over one year and enter it as one annual amount.';

  @override
  String get addThisCashFlow => 'Add this line';

  @override
  String cashFlowSummary(String amount, String frequency, String behavior) {
    return '$amount · $frequency · $behavior';
  }

  @override
  String get suggestionSalary1 => 'Salary 1';

  @override
  String get suggestionSalary2 => 'Salary 2';

  @override
  String get suggestionBenefit1 => 'Benefit or allowance 1';

  @override
  String get suggestionBenefit2 => 'Benefit or allowance 2';

  @override
  String get suggestionPension => 'Pension';

  @override
  String get suggestionOtherIncome => 'Other income';

  @override
  String get suggestionHousing => 'Housing';

  @override
  String get suggestionElectricity => 'Electricity';

  @override
  String get suggestionHeating => 'Gas or heating';

  @override
  String get suggestionWater => 'Water';

  @override
  String get suggestionInsurance => 'Insurance';

  @override
  String get suggestionTelecom => 'Telecommunications';

  @override
  String get suggestionLoans => 'Loans';

  @override
  String get suggestionTransport => 'Transport';

  @override
  String get suggestionChildcare => 'Childcare or school';

  @override
  String get suggestionTaxes => 'Taxes';

  @override
  String get suggestionOtherOutflow => 'Other charge';

  @override
  String get trajectorySetupTitle =>
      'Choose the result you want REBOOT to create';

  @override
  String get trajectorySetupIntro =>
      'Your income and charges define the available capacity. The choices below decide how much stays outside everyday weekly spending.';

  @override
  String get strategyBalanceTitle => 'Balance';

  @override
  String get strategyBalanceBody =>
      'Use the available capacity without saving an extra cushion in the background. Explicit projects and safety amounts still remain possible.';

  @override
  String get strategyCushionTitle => 'Build a cushion';

  @override
  String get strategyCushionBody =>
      'Choose how much you want to add to your reserve over the next 52 REBOOT cycles.';

  @override
  String get strategyOverdraftTitle => 'Exit an overdraft';

  @override
  String get strategyOverdraftBody =>
      'Set the current overdraft, the positive cushion you want, and the date when you want to reach it.';

  @override
  String get annualCushionLabel => 'Amount added to the reserve over 52 cycles';

  @override
  String get annualCushionHelp =>
      'This amount is divided across the rolling REBOOT year.';

  @override
  String get currentOverdraftLabel => 'Current overdraft depth';

  @override
  String get currentOverdraftHelp =>
      'Enter 1,000 if the account is currently at −1,000.';

  @override
  String get targetCushionLabel => 'Desired positive cushion';

  @override
  String get targetCushionHelp =>
      'Enter zero if your only objective is to return to balance.';

  @override
  String get overdraftTargetDateLabel => 'Target date';

  @override
  String get dateUnavailable => 'Date unavailable';

  @override
  String get overdraftConfirmationHelp =>
      'At this date, REBOOT asks you to confirm the real result. It will not increase your weekly budget automatically.';

  @override
  String get otherAnnualGoalsTitle => 'Projects and safety';

  @override
  String get otherAnnualGoalsBody =>
      'These optional annual amounts are separate from charges and from the selected strategy.';

  @override
  String get annualProjectsLabel =>
      'Projects and planned purchases over 52 cycles';

  @override
  String get annualProjectsHelp =>
      'For example, an object, a trip, or planned replacement.';

  @override
  String get annualSafetyLabel => 'Additional safety margin over 52 cycles';

  @override
  String get annualSafetyHelp =>
      'Keep zero if you do not want an additional conservative margin.';

  @override
  String get noAutomaticMargin =>
      'REBOOT never adds or changes this margin without your confirmation.';

  @override
  String get invalidNonNegativeAmount =>
      'Enter zero or a positive amount, with no more than two decimals.';

  @override
  String get emptyRecoveryGoal =>
      'The overdraft and target cushion cannot both be zero.';

  @override
  String get calculateWeeklyBudget => 'Calculate my weekly budget';

  @override
  String get trajectorySaving => 'Calculating the trajectory…';

  @override
  String get trajectorySetupError =>
      'The trajectory could not be saved. Nothing was partially recorded. Check the target date and try again.';

  @override
  String get firstWeeklyBudgetTitle => 'Your first REBOOT budget';

  @override
  String weeklyBudgetFrom(String date) {
    return 'For each week from $date';
  }

  @override
  String get recommendedWeeklyBudget => 'Recommended weekly spending budget';

  @override
  String weeklyRoundingHelp(String amount) {
    return 'Exact capacity: $amount per cycle, rounded down to a whole euro.';
  }

  @override
  String annualDeficit(String amount) {
    return 'The current assumptions leave an annual deficit of $amount. No spending budget can be recommended yet.';
  }

  @override
  String overdraftRecoverySummary(String amount, int cycleCount, String date) {
    return 'Keep $amount per cycle for $cycleCount cycles to target $date. REBOOT will ask you to confirm the result then.';
  }

  @override
  String overdraftRecoveryImpossible(String amount) {
    return 'The selected date requires $amount more per cycle than the available capacity. Choose a later date or revise the assumptions.';
  }

  @override
  String get annualCalculationTitle => 'Rolling 52-cycle calculation';

  @override
  String get annualIncome => 'Expected income';

  @override
  String get annualOutflows => 'Expected charges';

  @override
  String get annualReserves => 'Reserve contribution';

  @override
  String get annualProjects => 'Projects';

  @override
  String get annualSafety => 'Safety margin';

  @override
  String get annualSteerableCapacity => 'Steerable annual capacity';

  @override
  String selectedTrajectory(String strategy) {
    return 'Selected trajectory: $strategy';
  }

  @override
  String get quickExpenseNext =>
      'The next product step will turn this recommendation into the live remaining amount and quick expense entry.';

  @override
  String get refreshDashboard => 'Refresh';

  @override
  String get remainingThisWeek => 'You can still spend';

  @override
  String get upcomingWeeklyBudget => 'Your upcoming weekly budget';

  @override
  String firstCyclePending(String date) {
    return 'Your first REBOOT week starts on $date. Expense entry will open then.';
  }

  @override
  String availableFrom(String date) {
    return 'Available from $date';
  }

  @override
  String untilNextReboot(String date) {
    return 'until your next REBOOT on $date';
  }

  @override
  String dailyGuide(String amount, int dayCount) {
    String _temp0 = intl.Intl.pluralLogic(
      dayCount,
      locale: localeName,
      other: 'About $amount per day for the $dayCount remaining days',
      one: 'About $amount for the remaining day',
    );
    return '$_temp0';
  }

  @override
  String get weeklyOverBudget =>
      'This week is over budget. The next weekly budget will not change automatically.';

  @override
  String get weeklyBudgetMetric => 'Weekly budget';

  @override
  String get weeklySpentMetric => 'Allocated';

  @override
  String get thisWeekExpenses => 'This week\'s expenses';

  @override
  String get expensesAvailableAfterStart =>
      'You will be able to record expenses once the first REBOOT week starts.';

  @override
  String get noExpenseYet => 'No expense has reduced this week yet.';

  @override
  String get noCarryoverReminder =>
      'Spending less or more never changes the next weekly budget automatically. You remain in control of any compensation or transfer to a reserve.';

  @override
  String get addExpense => 'Add an expense';

  @override
  String get dashboardDateError =>
      'The current local date could not be verified. Your financial data remains unchanged.';

  @override
  String get quickExpenseTitle => 'Quick expense';

  @override
  String get quickExpenseIntro =>
      'Record it now so everyone using the weekly budget sees the correct remaining amount.';

  @override
  String get expenseAmountLabel => 'Amount paid';

  @override
  String get expenseLabel => 'What or where?';

  @override
  String get expenseLabelHint => 'Groceries, cinema, Vinted…';

  @override
  String get expenseDate => 'Purchase date';

  @override
  String get expenseAllocationTitle => 'Impact on the weekly budget';

  @override
  String get expenseAllocationHelp =>
      'Use one week normally. A large exceptional expense can be spread virtually over up to 12 weeks; the payment itself remains a single real transaction.';

  @override
  String get expenseCycleCount => 'Spread over';

  @override
  String cycleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String expenseAllocationPreview(
    String regularAmount,
    int regularCount,
    String lastAmount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      regularCount,
      locale: localeName,
      other: '$regularAmount on each of the first $regularCount weeks',
      one: '$regularAmount on the first week',
    );
    return '$_temp0, then $lastAmount on the final week to absorb rounding.';
  }

  @override
  String get expenseCommitmentWarning =>
      'At least one affected week would have more than 50% of its budget already committed. REBOOT does not block you, but the method recommends using a reserve or a longer plan.';

  @override
  String get saveExpense => 'Record the expense';

  @override
  String get quickExpenseSaving => 'Recording…';

  @override
  String get quickExpenseError =>
      'The expense could not be recorded. Nothing was saved partially; try again.';

  @override
  String splitExpenseDetail(String amount, int count, String date) {
    return '$amount paid · spread over $count weeks · $date';
  }

  @override
  String get deleteExpenseTitle => 'Delete this erroneous entry?';

  @override
  String get deleteExpenseBody =>
      'The expense will no longer count in the weekly balance. Its audit history remains in the local journal.';

  @override
  String deleteSplitExpenseBody(int count) {
    return 'All $count weekly installments will be removed together. Its audit history remains in the local journal.';
  }

  @override
  String get deleteExpense => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteExpenseError =>
      'The expense could not be deleted. Try again.';

  @override
  String get trendsTitle => 'Weekly trends';

  @override
  String get trendNoCompletedCycle =>
      'Your trends will appear after your first REBOOT week is complete.';

  @override
  String get trendAvailableAfterCycle =>
      'Trends available after the first completed week';

  @override
  String get trendObservedBalance => 'Observed balance';

  @override
  String trendCycleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Over $count completed weeks',
      one: 'Over 1 completed week',
    );
    return '$_temp0';
  }

  @override
  String get trendStatusNone => 'The method is on track';

  @override
  String get trendStatusVigilance => 'Keep an eye on the trend';

  @override
  String get trendStatusStrong => 'A correction deserves consideration';

  @override
  String trendSummary(String balance, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed weeks',
      one: '1 completed week',
    );
    return '$balance over $_temp0';
  }

  @override
  String get trendLatestOnTrack => 'Latest week: within budget.';

  @override
  String trendLatestOverspend(String amount, String percent) {
    return 'Latest week: $amount over budget ($percent of that week\'s budget).';
  }

  @override
  String trendGlobalPositive(String amount) {
    return 'Overall trajectory: $amount across the observed weeks.';
  }

  @override
  String trendGlobalNegative(String amount, String percent) {
    return 'Overall trajectory: $amount ($percent of observed budgets).';
  }

  @override
  String get trendBudgetUnchanged =>
      'The next weekly budget remains unchanged. You decide whether and when to compensate.';

  @override
  String get trendWindowTitle => 'Choose the perspective';

  @override
  String trendWindowLabel(int count) {
    return '$count weeks';
  }

  @override
  String trendWindowBalance(int count) {
    return 'Balance over the last $count weeks';
  }

  @override
  String trendObservedCount(int observed, int requested) {
    return '$observed of the requested $requested completed weeks are available';
  }

  @override
  String get trendHistoricalBudget => 'Applicable budgets';

  @override
  String get trendAllocated => 'Allocated expenses';

  @override
  String get trendCycleHistory => 'Week-by-week history';

  @override
  String trendCyclePeriod(String start, String end) {
    return '$start to $end';
  }

  @override
  String trendExcludedTransitions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count exceptional transition weeks are visible in history but excluded from normal trends.',
      one:
          '1 exceptional transition week is visible in history but excluded from normal trends.',
    );
    return '$_temp0';
  }

  @override
  String get trendTransitionHistory => 'Exceptional transitions';

  @override
  String trendSurplusSuggestion(String amount) {
    return 'You have a $amount observed surplus. You could move it to a reserve or a project; the choice remains yours.';
  }

  @override
  String get reservesTitle => 'Reserves';

  @override
  String get reservesIntro =>
      'A reserve protects an exceptional expense without reducing the weekly budget. REBOOT tracks what you declare; it does not read the bank balance.';

  @override
  String get noReserveYet =>
      'Create a reserve for emergencies, health, a vehicle, or another goal you want to protect.';

  @override
  String get createReserve => 'Create a reserve';

  @override
  String get createFirstReserve => 'Create your first reserve';

  @override
  String reservesSummary(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reserves · $amount',
      one: '1 reserve · $amount',
    );
    return '$_temp0';
  }

  @override
  String get reservesSummaryHelp =>
      'Real accounts and virtual allocations remain distinct from weekly spending.';

  @override
  String totalReserves(String amount) {
    return 'Total declared reserves: $amount';
  }

  @override
  String get reserveName => 'Reserve name';

  @override
  String get reserveKind => 'Reserve type';

  @override
  String get realReserve => 'Real reserve account';

  @override
  String get virtualReserve => 'Virtual reserve';

  @override
  String get reserveOpeningBalance => 'Current available amount';

  @override
  String get reserveOpeningBalanceHelp =>
      'Enter only what is available now. This does not create income or change your weekly budget.';

  @override
  String get addReserveFunds => 'Add funds';

  @override
  String get useReserve => 'Use';

  @override
  String get reserveFundingAmount => 'Amount assigned';

  @override
  String get reserveFundingLabel => 'Reason';

  @override
  String get reserveFundingHint => 'Weekly surplus, gift, manual transfer…';

  @override
  String get confirmReserveFunding => 'Record the funds';

  @override
  String get reserveHistory => 'Recent movements';

  @override
  String get reversedReserveMovement => 'Erroneous entry reversed';

  @override
  String get reverseReserveMovement => 'Reverse the entry';

  @override
  String get reverseReserveMovementTitle => 'Reverse this erroneous entry?';

  @override
  String get reverseReserveMovementBody =>
      'Its effect on the reserve will be neutralized, while both events remain in the audit history.';

  @override
  String get reserveMutationError =>
      'The reserve could not be updated. No partial change was saved.';

  @override
  String get expenseFundingTitle => 'How is this expense funded?';

  @override
  String get weeklyBudgetFunding => 'Weekly budget';

  @override
  String get reserveFunding => 'A reserve';

  @override
  String get createReserveBeforeUse =>
      'Create a reserve from the dashboard before using this funding choice.';

  @override
  String get selectReserve => 'Reserve to use';

  @override
  String get reserveExpenseNoWeeklyImpact =>
      'This expense reduces only the selected reserve. It does not change this week or the next one.';

  @override
  String insufficientReserveBalance(String amount) {
    return 'The declared reserve contains only $amount. Choose another reserve or use the weekly spread.';
  }

  @override
  String get realReserveTransferTitle => 'Transfer reminder';

  @override
  String realReserveTransferBody(String amount, String reserveName) {
    return 'This expense will reduce $reserveName by $amount. Remember to transfer $amount from that reserve account to the main account if the payment was made there. REBOOT will not perform or verify the transfer.';
  }

  @override
  String get confirmReserveExpense => 'I understand, record it';

  @override
  String get refundsTitle => 'Refunds';

  @override
  String get refundsIntro =>
      'Attach each refund to its original purchase. The installment plan is never rewritten, and a later refund improves the trajectory without increasing the current weekly budget.';

  @override
  String get noRefundableExpense =>
      'There is no active purchase to refund yet.';

  @override
  String get refundMutationError =>
      'The refund could not be saved. No partial change was recorded.';

  @override
  String refundRestoredOriginalCycle(String amount) {
    return '$amount was restored to the original purchase week.';
  }

  @override
  String refundImprovesTrajectory(String amount) {
    return 'Your trajectory improves by $amount. This week\'s budget stays unchanged.';
  }

  @override
  String get reverseRefundTitle => 'Reverse this incorrect refund?';

  @override
  String get reverseRefundBody =>
      'Its effect will be neutralized, while both entries remain in the local audit history.';

  @override
  String get reverseRefund => 'Reverse refund';

  @override
  String refundExpenseSummary(String amount, String date) {
    return '$amount paid on $date';
  }

  @override
  String get fullyRefunded => 'Fully refunded';

  @override
  String get recordRefund => 'Record refund';

  @override
  String refundableRemaining(String amount) {
    return 'Still refundable: $amount';
  }

  @override
  String refundHistoryLine(String amount, String date) {
    return '$amount received on $date';
  }

  @override
  String get reversedRefund => 'Incorrect entry reversed';

  @override
  String recordRefundFor(String label) {
    return 'Refund for $label';
  }

  @override
  String get refundAmount => 'Amount received';

  @override
  String invalidRefundAmount(String maximum) {
    return 'Enter an amount above zero and no greater than $maximum.';
  }

  @override
  String get refundDate => 'Date received';

  @override
  String refundsRestoredThisCycle(String amount) {
    return 'Refunds restored this week: $amount';
  }

  @override
  String get refundsRestoredThisCycleHelp =>
      'Only refunds from purchases assigned to this same week restore its remaining amount.';

  @override
  String get refundsDashboardHelp =>
      'Record a product refund against its original purchase.';

  @override
  String expenseRefunded(String amount) {
    return 'Refunded: $amount';
  }

  @override
  String get trendRefundCredits => 'Refund credits';

  @override
  String get healthTitle => 'Health tracking';

  @override
  String get healthSettings => 'Health settings';

  @override
  String get healthMutationError =>
      'Health tracking could not be updated. No partial change was recorded.';

  @override
  String get healthTrackingDisabled => 'Health tracking is paused';

  @override
  String get healthTrackingOptional => 'Optional health tracking';

  @override
  String get healthIntro =>
      'Enter both health expenses and reimbursements, individually or as occasional totals. No per-claim matching is required.';

  @override
  String get healthDisabledWarning =>
      'Without this tracking, health costs may drift unnoticed. You can instead reduce your weekly budget by a cautious amount.';

  @override
  String get enableHealthTracking => 'Enable health tracking';

  @override
  String get healthEstimatedRest => 'Estimated health amount still to cover';

  @override
  String healthEstimateSettings(int weeks, String threshold) {
    return 'Expenses older than $weeks weeks · alert above $threshold';
  }

  @override
  String get healthAttentionTitle => 'This estimate deserves attention';

  @override
  String get healthAttentionBody =>
      'You may cover it from a reserve, the current week, or a spread of up to 12 weeks—or wait. REBOOT never changes your budget automatically.';

  @override
  String get addHealthExpense => 'Health expense';

  @override
  String get addHealthReimbursement => 'Reimbursement received';

  @override
  String get addHealthRegularization => 'Already covered amount';

  @override
  String get healthRegularizationHelp =>
      'Record an already covered amount only after you actually compensated it from a reserve or reduced spending. A negative estimate never increases the weekly budget.';

  @override
  String get healthHistory => 'Health history';

  @override
  String get noHealthEntry =>
      'No health entry has been recorded since tracking began.';

  @override
  String get reversedHealthEntry => 'Incorrect entry reversed';

  @override
  String get reverseHealthEntryTitle => 'Reverse this incorrect entry?';

  @override
  String get reverseHealthEntryBody =>
      'Its effect will be neutralized, while both entries remain in the local audit history.';

  @override
  String get reverseHealthEntry => 'Reverse entry';

  @override
  String get healthDelayWeeks => 'Reimbursement delay in weeks';

  @override
  String get invalidHealthDelay => 'Choose between 1 and 52 weeks.';

  @override
  String get healthAlertThreshold => 'Alert threshold';

  @override
  String get saveHealthSettings => 'Save settings';

  @override
  String get healthEntryAmount => 'Amount';

  @override
  String get healthEntryLabel => 'Description or total period';

  @override
  String get healthEntryDate => 'Date';

  @override
  String get saveHealthEntry => 'Record entry';

  @override
  String healthDashboardEstimate(String amount) {
    return 'Health estimate: $amount';
  }

  @override
  String get healthDashboardOnTrack =>
      'No alert under the current delay and threshold.';

  @override
  String get expenseSuggestionsTitle => 'Recent and frequent shortcuts';

  @override
  String get expenseNatureTitle => 'Optional spending nature';

  @override
  String get expenseNatureHelp =>
      'This never changes the weekly amount. It only makes your trends easier to understand.';

  @override
  String get expenseNatureNecessary => 'Necessary';

  @override
  String get expenseNaturePleasure => 'Pleasure';

  @override
  String get expenseNatureDeferrable => 'Could wait';

  @override
  String get expenseNatureUnexpected => 'Unexpected';

  @override
  String get expenseNatureSkipped =>
      'You can leave this blank; the expense remains valid.';

  @override
  String expenseNatureSelected(String nature) {
    return 'Selected: $nature';
  }

  @override
  String get expenseNatureUnqualified => 'Not qualified';

  @override
  String expenseNatureDisplay(String nature) {
    return 'Nature: $nature';
  }

  @override
  String get trendNatureBreakdownTitle => 'How weekly spending was used';

  @override
  String get trendNatureBreakdownHelp =>
      'Optional qualifications across the selected completed weeks. Unqualified spending is kept visible.';
}
