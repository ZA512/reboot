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
}
