import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Application title.
  ///
  /// In en, this message translates to:
  /// **'REBOOT'**
  String get appTitle;

  /// Accessible label while the encrypted profile opens.
  ///
  /// In en, this message translates to:
  /// **'Opening your REBOOT profile'**
  String get profileOpening;

  /// Generic, non-sensitive profile opening error.
  ///
  /// In en, this message translates to:
  /// **'The local profile cannot be opened.'**
  String get profileLockedTitle;

  /// Fail-closed profile opening explanation.
  ///
  /// In en, this message translates to:
  /// **'No data was deleted or recreated. Unlock your device, then try again.'**
  String get profileLockedBody;

  /// Generic retry action.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// REBOOT onboarding headline.
  ///
  /// In en, this message translates to:
  /// **'Take back control of your spending, one week at a time.'**
  String get welcomeHeadline;

  /// Short explanation of the REBOOT method.
  ///
  /// In en, this message translates to:
  /// **'REBOOT turns your income, expenses and goals into one simple weekly amount to follow.'**
  String get welcomeBody;

  /// Confirms that local encrypted storage opened.
  ///
  /// In en, this message translates to:
  /// **'Your encrypted local profile is ready.'**
  String get encryptedProfileReady;

  /// Starts household onboarding.
  ///
  /// In en, this message translates to:
  /// **'Set up my REBOOT'**
  String get startSetup;

  /// Title of the initial household configuration screen.
  ///
  /// In en, this message translates to:
  /// **'Set up your weekly rhythm'**
  String get setupTitle;

  /// Explains why the REBOOT weekday matters.
  ///
  /// In en, this message translates to:
  /// **'Choose the day when your weekly budget starts. We recommend the day of your main grocery shop, so essential food spending comes first.'**
  String get setupIntro;

  /// Household mode section title.
  ///
  /// In en, this message translates to:
  /// **'Who uses this weekly budget?'**
  String get householdQuestion;

  /// Shared household mode label.
  ///
  /// In en, this message translates to:
  /// **'A shared main account'**
  String get sharedHouseholdTitle;

  /// Shared household mode explanation.
  ///
  /// In en, this message translates to:
  /// **'Everyone spends from the same weekly budget, even with several cards.'**
  String get sharedHouseholdBody;

  /// Solo household mode label.
  ///
  /// In en, this message translates to:
  /// **'Just me'**
  String get soloHouseholdTitle;

  /// Solo household mode explanation.
  ///
  /// In en, this message translates to:
  /// **'I manage one personal weekly budget.'**
  String get soloHouseholdBody;

  /// Weekly anchor weekday section title.
  ///
  /// In en, this message translates to:
  /// **'What is your REBOOT day?'**
  String get rebootDayQuestion;

  /// Explains future anchor changes without rewriting history.
  ///
  /// In en, this message translates to:
  /// **'You can change it later. Your history will keep the day that applied at the time.'**
  String get rebootDayHelp;

  /// Full weekday name.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMonday;

  /// Full weekday name.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTuesday;

  /// Full weekday name.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWednesday;

  /// Full weekday name.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayThursday;

  /// Full weekday name.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFriday;

  /// Full weekday name.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySaturday;

  /// Full weekday name.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySunday;

  /// First cycle choice section title.
  ///
  /// In en, this message translates to:
  /// **'When should the first week start?'**
  String get startQuestion;

  /// Start at the next weekly anchor.
  ///
  /// In en, this message translates to:
  /// **'Start on {date}'**
  String startNextTitle(String date);

  /// Recommended next-anchor choice explanation.
  ///
  /// In en, this message translates to:
  /// **'The simplest option. You will begin with a complete new week.'**
  String get startNextBody;

  /// Catch up from the previous weekly anchor.
  ///
  /// In en, this message translates to:
  /// **'Start from {date}'**
  String startPreviousTitle(String date);

  /// Previous-anchor catch-up requirement.
  ///
  /// In en, this message translates to:
  /// **'Enter every weekly-budget expense made since that date so the balance is accurate.'**
  String get startPreviousBody;

  /// Shown when onboarding occurs on the selected anchor day.
  ///
  /// In en, this message translates to:
  /// **'Your first REBOOT week starts today.'**
  String get startsToday;

  /// Time-zone section title.
  ///
  /// In en, this message translates to:
  /// **'Local time zone'**
  String get timeZoneTitle;

  /// Detected IANA time-zone identifier.
  ///
  /// In en, this message translates to:
  /// **'Detected: {zone}'**
  String timeZoneDetected(String zone);

  /// Time-zone detection progress.
  ///
  /// In en, this message translates to:
  /// **'Detecting the device time zone…'**
  String get timeZoneLoading;

  /// Generic time-zone detection error.
  ///
  /// In en, this message translates to:
  /// **'The device time zone could not be verified.'**
  String get timeZoneError;

  /// Retries device time-zone detection.
  ///
  /// In en, this message translates to:
  /// **'Detect again'**
  String get detectAgain;

  /// Persists the initial household configuration.
  ///
  /// In en, this message translates to:
  /// **'Create my REBOOT profile'**
  String get confirmSetup;

  /// Household creation progress.
  ///
  /// In en, this message translates to:
  /// **'Creating the encrypted profile…'**
  String get creatingProfile;

  /// Generic household initialization error.
  ///
  /// In en, this message translates to:
  /// **'The profile could not be created. Nothing was partially saved. Try again.'**
  String get setupError;

  /// Ready message for a solo household.
  ///
  /// In en, this message translates to:
  /// **'Your personal REBOOT profile is ready.'**
  String get readySolo;

  /// Ready message for a shared household.
  ///
  /// In en, this message translates to:
  /// **'Your shared REBOOT profile is ready.'**
  String get readyShared;

  /// Initial financial assumptions screen title.
  ///
  /// In en, this message translates to:
  /// **'List all money coming in and going out'**
  String get financialSetupTitle;

  /// Explains the initial cash-flow setup.
  ///
  /// In en, this message translates to:
  /// **'REBOOT annualizes these assumptions before calculating your weekly budget. Monthly is selected by default, but frequency and fixed or variable behavior are independent.'**
  String get financialSetupIntro;

  /// Progressive-detail onboarding advice.
  ///
  /// In en, this message translates to:
  /// **'You may enter one total for all income or charges. Adding detail takes longer now, but will make future changes easier to detect.'**
  String get financialSetupTip;

  /// Income assumptions section.
  ///
  /// In en, this message translates to:
  /// **'Money coming in'**
  String get incomeSectionTitle;

  /// Income assumptions explanation.
  ///
  /// In en, this message translates to:
  /// **'Salaries, benefits, pensions and every other predictable receipt.'**
  String get incomeSectionBody;

  /// Outflow assumptions section.
  ///
  /// In en, this message translates to:
  /// **'Charges and smoothed expenses'**
  String get outflowSectionTitle;

  /// Outflow assumptions explanation.
  ///
  /// In en, this message translates to:
  /// **'Include monthly, annual and non-monthly charges, plus unavoidable variable spending you prefer to smooth.'**
  String get outflowSectionBody;

  /// Label above cash-flow suggestion chips.
  ///
  /// In en, this message translates to:
  /// **'Add a suggested line or a custom one:'**
  String get suggestionsLabel;

  /// Deletes one unsaved onboarding cash flow.
  ///
  /// In en, this message translates to:
  /// **'Delete this draft line'**
  String get deleteDraft;

  /// Atomically saves initial cash flows.
  ///
  /// In en, this message translates to:
  /// **'Confirm income and charges'**
  String get confirmFinancialSetup;

  /// Initial cash-flow save progress.
  ///
  /// In en, this message translates to:
  /// **'Saving assumptions…'**
  String get financialSetupSaving;

  /// Minimum initial setup requirement.
  ///
  /// In en, this message translates to:
  /// **'Add at least one income and one charge before continuing.'**
  String get financialSetupMinimum;

  /// Generic initial cash-flow save error.
  ///
  /// In en, this message translates to:
  /// **'Income and charges could not be saved. Nothing was partially recorded. Try again.'**
  String get financialSetupError;

  /// Income editor title.
  ///
  /// In en, this message translates to:
  /// **'Add money coming in'**
  String get addIncomeTitle;

  /// Outflow editor title.
  ///
  /// In en, this message translates to:
  /// **'Add a charge'**
  String get addOutflowTitle;

  /// Editable cash-flow title field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get cashFlowTitleLabel;

  /// Required form field error.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// Amount behavior selector label.
  ///
  /// In en, this message translates to:
  /// **'Is the amount fixed or variable?'**
  String get amountBehaviorLabel;

  /// Known cash-flow amount behavior.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get fixedAmount;

  /// Estimated cash-flow amount behavior.
  ///
  /// In en, this message translates to:
  /// **'Variable'**
  String get variableAmount;

  /// Fixed amount per occurrence input.
  ///
  /// In en, this message translates to:
  /// **'Amount at each payment'**
  String get amountPerOccurrenceLabel;

  /// Fixed amount input help.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount expected each time.'**
  String get fixedAmountHelp;

  /// Variable historical average input.
  ///
  /// In en, this message translates to:
  /// **'Observed average at each payment'**
  String get averageAmountLabel;

  /// Variable historical average input help.
  ///
  /// In en, this message translates to:
  /// **'Use your available history; REBOOT applies the strategy below.'**
  String get averageAmountHelp;

  /// Exact positive EUR parsing error.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero, with no more than two decimals.'**
  String get invalidPositiveAmount;

  /// Variable estimate strategy field.
  ///
  /// In en, this message translates to:
  /// **'Estimation strategy'**
  String get estimateStrategyLabel;

  /// Conservative estimate strategy.
  ///
  /// In en, this message translates to:
  /// **'Prudent'**
  String get strategyPrudent;

  /// Historical-average estimate strategy.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get strategyBalanced;

  /// User-selected estimate strategy.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get strategyCustom;

  /// Prudent income calculation.
  ///
  /// In en, this message translates to:
  /// **'REBOOT keeps 90% of the observed average.'**
  String get prudentIncomeHelp;

  /// Prudent outflow calculation.
  ///
  /// In en, this message translates to:
  /// **'REBOOT budgets 110% of the observed average.'**
  String get prudentOutflowHelp;

  /// Balanced calculation.
  ///
  /// In en, this message translates to:
  /// **'REBOOT uses 100% of the observed average.'**
  String get balancedHelp;

  /// Custom calculation explanation.
  ///
  /// In en, this message translates to:
  /// **'Choose the amount REBOOT should use at each occurrence.'**
  String get customStrategyHelp;

  /// Custom variable amount input.
  ///
  /// In en, this message translates to:
  /// **'Amount used by REBOOT'**
  String get customAmountLabel;

  /// Cash-flow recurrence selector.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequencyLabel;

  /// Weekly recurrence.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// Four-week recurrence.
  ///
  /// In en, this message translates to:
  /// **'Every four weeks'**
  String get frequencyEveryFourWeeks;

  /// Monthly recurrence.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get frequencyMonthly;

  /// Quarterly recurrence.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get frequencyQuarterly;

  /// Semiannual recurrence.
  ///
  /// In en, this message translates to:
  /// **'Every six months'**
  String get frequencySemiAnnual;

  /// Annual recurrence.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get frequencyAnnual;

  /// Anchor date for a recurrence schedule.
  ///
  /// In en, this message translates to:
  /// **'Reference occurrence date'**
  String get referenceDateLabel;

  /// Recurrence anchor explanation.
  ///
  /// In en, this message translates to:
  /// **'Choose a past or upcoming date when this payment occurs. REBOOT preserves its weekday or intended day of month.'**
  String get referenceDateHelp;

  /// Annual workaround for irregular schedules.
  ///
  /// In en, this message translates to:
  /// **'For an unusual rhythm, calculate the total you expect over one year and enter it as one annual amount.'**
  String get irregularFrequencyTip;

  /// Returns a completed cash-flow draft to setup.
  ///
  /// In en, this message translates to:
  /// **'Add this line'**
  String get addThisCashFlow;

  /// Compact cash-flow draft summary.
  ///
  /// In en, this message translates to:
  /// **'{amount} · {frequency} · {behavior}'**
  String cashFlowSummary(String amount, String frequency, String behavior);

  /// Suggested income title.
  ///
  /// In en, this message translates to:
  /// **'Salary 1'**
  String get suggestionSalary1;

  /// Suggested income title.
  ///
  /// In en, this message translates to:
  /// **'Salary 2'**
  String get suggestionSalary2;

  /// Suggested income title.
  ///
  /// In en, this message translates to:
  /// **'Benefit or allowance 1'**
  String get suggestionBenefit1;

  /// Suggested income title.
  ///
  /// In en, this message translates to:
  /// **'Benefit or allowance 2'**
  String get suggestionBenefit2;

  /// Suggested income title.
  ///
  /// In en, this message translates to:
  /// **'Pension'**
  String get suggestionPension;

  /// Suggested custom income title.
  ///
  /// In en, this message translates to:
  /// **'Other income'**
  String get suggestionOtherIncome;

  /// Suggested outflow title.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get suggestionHousing;

  /// Suggested outflow title.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get suggestionElectricity;

  /// Suggested outflow title.
  ///
  /// In en, this message translates to:
  /// **'Gas or heating'**
  String get suggestionHeating;

  /// Suggested outflow title.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get suggestionWater;

  /// Suggested outflow title.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get suggestionInsurance;

  /// Suggested outflow title.
  ///
  /// In en, this message translates to:
  /// **'Telecommunications'**
  String get suggestionTelecom;

  /// Suggested outflow title.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get suggestionLoans;

  /// Suggested outflow title.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get suggestionTransport;

  /// Suggested outflow title.
  ///
  /// In en, this message translates to:
  /// **'Childcare or school'**
  String get suggestionChildcare;

  /// Suggested outflow title.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get suggestionTaxes;

  /// Suggested custom outflow title.
  ///
  /// In en, this message translates to:
  /// **'Other charge'**
  String get suggestionOtherOutflow;

  /// Initial trajectory strategy screen title.
  ///
  /// In en, this message translates to:
  /// **'Choose the result you want REBOOT to create'**
  String get trajectorySetupTitle;

  /// Trajectory setup explanation.
  ///
  /// In en, this message translates to:
  /// **'Your income and charges define the available capacity. The choices below decide how much stays outside everyday weekly spending.'**
  String get trajectorySetupIntro;

  /// Neutral trajectory strategy.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get strategyBalanceTitle;

  /// Balance strategy explanation.
  ///
  /// In en, this message translates to:
  /// **'Use the available capacity without saving an extra cushion in the background. Explicit projects and safety amounts still remain possible.'**
  String get strategyBalanceBody;

  /// Annual reserve-building strategy.
  ///
  /// In en, this message translates to:
  /// **'Build a cushion'**
  String get strategyCushionTitle;

  /// Cushion strategy explanation.
  ///
  /// In en, this message translates to:
  /// **'Choose how much you want to add to your reserve over the next 52 REBOOT cycles.'**
  String get strategyCushionBody;

  /// Time-bound overdraft recovery strategy.
  ///
  /// In en, this message translates to:
  /// **'Exit an overdraft'**
  String get strategyOverdraftTitle;

  /// Overdraft strategy explanation.
  ///
  /// In en, this message translates to:
  /// **'Set the current overdraft, the positive cushion you want, and the date when you want to reach it.'**
  String get strategyOverdraftBody;

  /// Annual cushion contribution input.
  ///
  /// In en, this message translates to:
  /// **'Amount added to the reserve over 52 cycles'**
  String get annualCushionLabel;

  /// Annual cushion input help.
  ///
  /// In en, this message translates to:
  /// **'This amount is divided across the rolling REBOOT year.'**
  String get annualCushionHelp;

  /// Positive depth below zero.
  ///
  /// In en, this message translates to:
  /// **'Current overdraft depth'**
  String get currentOverdraftLabel;

  /// Overdraft sign convention help.
  ///
  /// In en, this message translates to:
  /// **'Enter 1,000 if the account is currently at −1,000.'**
  String get currentOverdraftHelp;

  /// Positive target balance after recovery.
  ///
  /// In en, this message translates to:
  /// **'Desired positive cushion'**
  String get targetCushionLabel;

  /// Target cushion help.
  ///
  /// In en, this message translates to:
  /// **'Enter zero if your only objective is to return to balance.'**
  String get targetCushionHelp;

  /// Overdraft recovery deadline.
  ///
  /// In en, this message translates to:
  /// **'Target date'**
  String get overdraftTargetDateLabel;

  /// Fallback while device date is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Date unavailable'**
  String get dateUnavailable;

  /// No silent post-recovery change explanation.
  ///
  /// In en, this message translates to:
  /// **'At this date, REBOOT asks you to confirm the real result. It will not increase your weekly budget automatically.'**
  String get overdraftConfirmationHelp;

  /// Other annual deductions section.
  ///
  /// In en, this message translates to:
  /// **'Projects and safety'**
  String get otherAnnualGoalsTitle;

  /// Other annual deductions explanation.
  ///
  /// In en, this message translates to:
  /// **'These optional annual amounts are separate from charges and from the selected strategy.'**
  String get otherAnnualGoalsBody;

  /// Annual project contribution input.
  ///
  /// In en, this message translates to:
  /// **'Projects and planned purchases over 52 cycles'**
  String get annualProjectsLabel;

  /// Annual project contribution help.
  ///
  /// In en, this message translates to:
  /// **'For example, an object, a trip, or planned replacement.'**
  String get annualProjectsHelp;

  /// Explicit annual safety input.
  ///
  /// In en, this message translates to:
  /// **'Additional safety margin over 52 cycles'**
  String get annualSafetyLabel;

  /// Annual safety input help.
  ///
  /// In en, this message translates to:
  /// **'Keep zero if you do not want an additional conservative margin.'**
  String get annualSafetyHelp;

  /// Explicit margin confirmation rule.
  ///
  /// In en, this message translates to:
  /// **'REBOOT never adds or changes this margin without your confirmation.'**
  String get noAutomaticMargin;

  /// Exact non-negative EUR parsing error.
  ///
  /// In en, this message translates to:
  /// **'Enter zero or a positive amount, with no more than two decimals.'**
  String get invalidNonNegativeAmount;

  /// Empty overdraft goal validation.
  ///
  /// In en, this message translates to:
  /// **'The overdraft and target cushion cannot both be zero.'**
  String get emptyRecoveryGoal;

  /// Saves trajectory and opens first recommendation.
  ///
  /// In en, this message translates to:
  /// **'Calculate my weekly budget'**
  String get calculateWeeklyBudget;

  /// Trajectory save progress.
  ///
  /// In en, this message translates to:
  /// **'Calculating the trajectory…'**
  String get trajectorySaving;

  /// Generic trajectory setup failure.
  ///
  /// In en, this message translates to:
  /// **'The trajectory could not be saved. Nothing was partially recorded. Check the target date and try again.'**
  String get trajectorySetupError;

  /// First recommendation screen title.
  ///
  /// In en, this message translates to:
  /// **'Your first REBOOT budget'**
  String get firstWeeklyBudgetTitle;

  /// First effective weekly budget date.
  ///
  /// In en, this message translates to:
  /// **'For each week from {date}'**
  String weeklyBudgetFrom(String date);

  /// Primary weekly recommendation label.
  ///
  /// In en, this message translates to:
  /// **'Recommended weekly spending budget'**
  String get recommendedWeeklyBudget;

  /// Whole-euro recommendation explanation.
  ///
  /// In en, this message translates to:
  /// **'Exact capacity: {amount} per cycle, rounded down to a whole euro.'**
  String weeklyRoundingHelp(String amount);

  /// Negative annual capacity warning.
  ///
  /// In en, this message translates to:
  /// **'The current assumptions leave an annual deficit of {amount}. No spending budget can be recommended yet.'**
  String annualDeficit(String amount);

  /// Feasible overdraft recovery explanation.
  ///
  /// In en, this message translates to:
  /// **'Keep {amount} per cycle for {cycleCount} cycles to target {date}. REBOOT will ask you to confirm the result then.'**
  String overdraftRecoverySummary(String amount, int cycleCount, String date);

  /// Infeasible overdraft recovery warning.
  ///
  /// In en, this message translates to:
  /// **'The selected date requires {amount} more per cycle than the available capacity. Choose a later date or revise the assumptions.'**
  String overdraftRecoveryImpossible(String amount);

  /// Annual calculation breakdown title.
  ///
  /// In en, this message translates to:
  /// **'Rolling 52-cycle calculation'**
  String get annualCalculationTitle;

  /// Annual income total.
  ///
  /// In en, this message translates to:
  /// **'Expected income'**
  String get annualIncome;

  /// Annual outflow total.
  ///
  /// In en, this message translates to:
  /// **'Expected charges'**
  String get annualOutflows;

  /// Annual reserve deduction.
  ///
  /// In en, this message translates to:
  /// **'Reserve contribution'**
  String get annualReserves;

  /// Annual project deduction.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get annualProjects;

  /// Annual safety deduction.
  ///
  /// In en, this message translates to:
  /// **'Safety margin'**
  String get annualSafety;

  /// Annual capacity after deductions.
  ///
  /// In en, this message translates to:
  /// **'Steerable annual capacity'**
  String get annualSteerableCapacity;

  /// Selected strategy summary.
  ///
  /// In en, this message translates to:
  /// **'Selected trajectory: {strategy}'**
  String selectedTrajectory(String strategy);

  /// Temporary roadmap note on first dashboard.
  ///
  /// In en, this message translates to:
  /// **'The next product step will turn this recommendation into the live remaining amount and quick expense entry.'**
  String get quickExpenseNext;

  /// Refreshes the device date and dashboard.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshDashboard;

  /// Headline above the live remaining amount.
  ///
  /// In en, this message translates to:
  /// **'You can still spend'**
  String get remainingThisWeek;

  /// Headline before the first cycle starts.
  ///
  /// In en, this message translates to:
  /// **'Your upcoming weekly budget'**
  String get upcomingWeeklyBudget;

  /// Explains a pending first cycle.
  ///
  /// In en, this message translates to:
  /// **'Your first REBOOT week starts on {date}. Expense entry will open then.'**
  String firstCyclePending(String date);

  /// Date when an upcoming budget opens.
  ///
  /// In en, this message translates to:
  /// **'Available from {date}'**
  String availableFrom(String date);

  /// End boundary for the live amount.
  ///
  /// In en, this message translates to:
  /// **'until your next REBOOT on {date}'**
  String untilNextReboot(String date);

  /// Optional daily spending guide.
  ///
  /// In en, this message translates to:
  /// **'{dayCount, plural, =1{About {amount} for the remaining day} other{About {amount} per day for the {dayCount} remaining days}}'**
  String dailyGuide(String amount, int dayCount);

  /// Live negative weekly balance explanation.
  ///
  /// In en, this message translates to:
  /// **'This week is over budget. The next weekly budget will not change automatically.'**
  String get weeklyOverBudget;

  /// Weekly budget metric label.
  ///
  /// In en, this message translates to:
  /// **'Weekly budget'**
  String get weeklyBudgetMetric;

  /// Weekly allocations metric label.
  ///
  /// In en, this message translates to:
  /// **'Allocated'**
  String get weeklySpentMetric;

  /// Current cycle expense list title.
  ///
  /// In en, this message translates to:
  /// **'This week\'s expenses'**
  String get thisWeekExpenses;

  /// Expense empty state before first cycle.
  ///
  /// In en, this message translates to:
  /// **'You will be able to record expenses once the first REBOOT week starts.'**
  String get expensesAvailableAfterStart;

  /// Current cycle expense empty state.
  ///
  /// In en, this message translates to:
  /// **'No expense has reduced this week yet.'**
  String get noExpenseYet;

  /// Core no-carryover method reminder.
  ///
  /// In en, this message translates to:
  /// **'Spending less or more never changes the next weekly budget automatically. You remain in control of any compensation or transfer to a reserve.'**
  String get noCarryoverReminder;

  /// Opens quick expense entry.
  ///
  /// In en, this message translates to:
  /// **'Add an expense'**
  String get addExpense;

  /// Safe dashboard device-date error.
  ///
  /// In en, this message translates to:
  /// **'The current local date could not be verified. Your financial data remains unchanged.'**
  String get dashboardDateError;

  /// Quick expense screen title.
  ///
  /// In en, this message translates to:
  /// **'Quick expense'**
  String get quickExpenseTitle;

  /// Real-time entry rationale.
  ///
  /// In en, this message translates to:
  /// **'Record it now so everyone using the weekly budget sees the correct remaining amount.'**
  String get quickExpenseIntro;

  /// Real expense amount field.
  ///
  /// In en, this message translates to:
  /// **'Amount paid'**
  String get expenseAmountLabel;

  /// Free expense label field.
  ///
  /// In en, this message translates to:
  /// **'What or where?'**
  String get expenseLabel;

  /// Examples for an expense label.
  ///
  /// In en, this message translates to:
  /// **'Groceries, cinema, Vinted…'**
  String get expenseLabelHint;

  /// Real purchase date label.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get expenseDate;

  /// Virtual allocation section title.
  ///
  /// In en, this message translates to:
  /// **'Impact on the weekly budget'**
  String get expenseAllocationTitle;

  /// Explains real payment versus virtual allocation.
  ///
  /// In en, this message translates to:
  /// **'Use one week normally. A large exceptional expense can be spread virtually over up to 12 weeks; the payment itself remains a single real transaction.'**
  String get expenseAllocationHelp;

  /// Allocation cycle count field label.
  ///
  /// In en, this message translates to:
  /// **'Spread over'**
  String get expenseCycleCount;

  /// Localized number of allocation weeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String cycleCount(int count);

  /// Exact installment and rounding preview.
  ///
  /// In en, this message translates to:
  /// **'{regularCount, plural, =1{{regularAmount} on the first week} other{{regularAmount} on each of the first {regularCount} weeks}}, then {lastAmount} on the final week to absorb rounding.'**
  String expenseAllocationPreview(
    String regularAmount,
    int regularCount,
    String lastAmount,
  );

  /// Non-blocking high commitment warning.
  ///
  /// In en, this message translates to:
  /// **'At least one affected week would have more than 50% of its budget already committed. REBOOT does not block you, but the method recommends using a reserve or a longer plan.'**
  String get expenseCommitmentWarning;

  /// Quick expense submit button.
  ///
  /// In en, this message translates to:
  /// **'Record the expense'**
  String get saveExpense;

  /// Quick expense progress label.
  ///
  /// In en, this message translates to:
  /// **'Recording…'**
  String get quickExpenseSaving;

  /// Generic atomic expense failure.
  ///
  /// In en, this message translates to:
  /// **'The expense could not be recorded. Nothing was saved partially; try again.'**
  String get quickExpenseError;

  /// Current list detail for a split expense.
  ///
  /// In en, this message translates to:
  /// **'{amount} paid · spread over {count} weeks · {date}'**
  String splitExpenseDetail(String amount, int count, String date);

  /// Expense deletion confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Delete this erroneous entry?'**
  String get deleteExpenseTitle;

  /// Single expense deletion consequence.
  ///
  /// In en, this message translates to:
  /// **'The expense will no longer count in the weekly balance. Its audit history remains in the local journal.'**
  String get deleteExpenseBody;

  /// Split expense deletion consequence.
  ///
  /// In en, this message translates to:
  /// **'All {count} weekly installments will be removed together. Its audit history remains in the local journal.'**
  String deleteSplitExpenseBody(int count);

  /// Expense deletion action.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteExpense;

  /// Cancels a destructive confirmation.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic expense deletion failure.
  ///
  /// In en, this message translates to:
  /// **'The expense could not be deleted. Try again.'**
  String get deleteExpenseError;

  /// Completed REBOOT cycle trend screen title.
  ///
  /// In en, this message translates to:
  /// **'Weekly trends'**
  String get trendsTitle;

  /// Trend empty state before one cycle is complete.
  ///
  /// In en, this message translates to:
  /// **'Your trends will appear after your first REBOOT week is complete.'**
  String get trendNoCompletedCycle;

  /// Dashboard trend empty-state link.
  ///
  /// In en, this message translates to:
  /// **'Trends available after the first completed week'**
  String get trendAvailableAfterCycle;

  /// Main completed-cycle balance label.
  ///
  /// In en, this message translates to:
  /// **'Observed balance'**
  String get trendObservedBalance;

  /// Count of completed normal cycles in the main balance.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Over 1 completed week} other{Over {count} completed weeks}}'**
  String trendCycleCount(int count);

  /// No-alert trend status.
  ///
  /// In en, this message translates to:
  /// **'The method is on track'**
  String get trendStatusNone;

  /// Five-to-fifteen-percent trend status.
  ///
  /// In en, this message translates to:
  /// **'Keep an eye on the trend'**
  String get trendStatusVigilance;

  /// At-least-fifteen-percent trend status.
  ///
  /// In en, this message translates to:
  /// **'A correction deserves consideration'**
  String get trendStatusStrong;

  /// Compact dashboard trend summary.
  ///
  /// In en, this message translates to:
  /// **'{balance} over {count, plural, =1{1 completed week} other{{count} completed weeks}}'**
  String trendSummary(String balance, int count);

  /// Latest completed cycle has no overspend.
  ///
  /// In en, this message translates to:
  /// **'Latest week: within budget.'**
  String get trendLatestOnTrack;

  /// Latest-cycle overspend signal.
  ///
  /// In en, this message translates to:
  /// **'Latest week: {amount} over budget ({percent} of that week\'s budget).'**
  String trendLatestOverspend(String amount, String percent);

  /// Positive or neutral global trend detail.
  ///
  /// In en, this message translates to:
  /// **'Overall trajectory: {amount} across the observed weeks.'**
  String trendGlobalPositive(String amount);

  /// Negative global trend detail.
  ///
  /// In en, this message translates to:
  /// **'Overall trajectory: {amount} ({percent} of observed budgets).'**
  String trendGlobalNegative(String amount, String percent);

  /// No automatic trend compensation reminder.
  ///
  /// In en, this message translates to:
  /// **'The next weekly budget remains unchanged. You decide whether and when to compensate.'**
  String get trendBudgetUnchanged;

  /// Trend window selector title.
  ///
  /// In en, this message translates to:
  /// **'Choose the perspective'**
  String get trendWindowTitle;

  /// Trend window choice.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks'**
  String trendWindowLabel(int count);

  /// Selected trend window balance label.
  ///
  /// In en, this message translates to:
  /// **'Balance over the last {count} weeks'**
  String trendWindowBalance(int count);

  /// Available history inside the selected window.
  ///
  /// In en, this message translates to:
  /// **'{observed} of the requested {requested} completed weeks are available'**
  String trendObservedCount(int observed, int requested);

  /// Historical budget total label.
  ///
  /// In en, this message translates to:
  /// **'Applicable budgets'**
  String get trendHistoricalBudget;

  /// Historical allocation total label.
  ///
  /// In en, this message translates to:
  /// **'Allocated expenses'**
  String get trendAllocated;

  /// Historical trend list title.
  ///
  /// In en, this message translates to:
  /// **'Week-by-week history'**
  String get trendCycleHistory;

  /// One historical cycle date range.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String trendCyclePeriod(String start, String end);

  /// Anchor-change cycles excluded from trends.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exceptional transition week is visible in history but excluded from normal trends.} other{{count} exceptional transition weeks are visible in history but excluded from normal trends.}}'**
  String trendExcludedTransitions(int count);

  /// Historical list of excluded anchor-change cycles.
  ///
  /// In en, this message translates to:
  /// **'Exceptional transitions'**
  String get trendTransitionHistory;

  /// Suggestion after eight positive completed cycles.
  ///
  /// In en, this message translates to:
  /// **'You have a {amount} observed surplus. You could move it to a reserve or a project; the choice remains yours.'**
  String trendSurplusSuggestion(String amount);

  /// Reserve management screen title.
  ///
  /// In en, this message translates to:
  /// **'Reserves'**
  String get reservesTitle;

  /// Reserve behavior and trust boundary.
  ///
  /// In en, this message translates to:
  /// **'A reserve protects an exceptional expense without reducing the weekly budget. REBOOT tracks what you declare; it does not read the bank balance.'**
  String get reservesIntro;

  /// Empty reserve list explanation.
  ///
  /// In en, this message translates to:
  /// **'Create a reserve for emergencies, health, a vehicle, or another goal you want to protect.'**
  String get noReserveYet;

  /// Reserve creation action.
  ///
  /// In en, this message translates to:
  /// **'Create a reserve'**
  String get createReserve;

  /// Dashboard reserve empty-state link.
  ///
  /// In en, this message translates to:
  /// **'Create your first reserve'**
  String get createFirstReserve;

  /// Dashboard reserve count and total.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reserve · {amount}} other{{count} reserves · {amount}}}'**
  String reservesSummary(String amount, int count);

  /// Dashboard reserve behavior reminder.
  ///
  /// In en, this message translates to:
  /// **'Real accounts and virtual allocations remain distinct from weekly spending.'**
  String get reservesSummaryHelp;

  /// Combined reserve balance.
  ///
  /// In en, this message translates to:
  /// **'Total declared reserves: {amount}'**
  String totalReserves(String amount);

  /// Reserve name field.
  ///
  /// In en, this message translates to:
  /// **'Reserve name'**
  String get reserveName;

  /// Reserve kind field.
  ///
  /// In en, this message translates to:
  /// **'Reserve type'**
  String get reserveKind;

  /// A reserve backed by a separate bank account.
  ///
  /// In en, this message translates to:
  /// **'Real reserve account'**
  String get realReserve;

  /// An internal allocation in the main account.
  ///
  /// In en, this message translates to:
  /// **'Virtual reserve'**
  String get virtualReserve;

  /// Declared reserve opening balance field.
  ///
  /// In en, this message translates to:
  /// **'Current available amount'**
  String get reserveOpeningBalance;

  /// Opening balance accounting explanation.
  ///
  /// In en, this message translates to:
  /// **'Enter only what is available now. This does not create income or change your weekly budget.'**
  String get reserveOpeningBalanceHelp;

  /// Records an explicit reserve credit.
  ///
  /// In en, this message translates to:
  /// **'Add funds'**
  String get addReserveFunds;

  /// Starts a reserve-funded expense.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get useReserve;

  /// Reserve credit amount field.
  ///
  /// In en, this message translates to:
  /// **'Amount assigned'**
  String get reserveFundingAmount;

  /// Reserve credit label field.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reserveFundingLabel;

  /// Reserve credit label examples.
  ///
  /// In en, this message translates to:
  /// **'Weekly surplus, gift, manual transfer…'**
  String get reserveFundingHint;

  /// Confirms a reserve credit.
  ///
  /// In en, this message translates to:
  /// **'Record the funds'**
  String get confirmReserveFunding;

  /// Reserve movement history title.
  ///
  /// In en, this message translates to:
  /// **'Recent movements'**
  String get reserveHistory;

  /// Audit label for a corrected reserve movement.
  ///
  /// In en, this message translates to:
  /// **'Erroneous entry reversed'**
  String get reversedReserveMovement;

  /// Reserve movement correction action.
  ///
  /// In en, this message translates to:
  /// **'Reverse the entry'**
  String get reverseReserveMovement;

  /// Reserve movement correction confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Reverse this erroneous entry?'**
  String get reverseReserveMovementTitle;

  /// Reserve movement correction consequence.
  ///
  /// In en, this message translates to:
  /// **'Its effect on the reserve will be neutralized, while both events remain in the audit history.'**
  String get reverseReserveMovementBody;

  /// Generic atomic reserve mutation failure.
  ///
  /// In en, this message translates to:
  /// **'The reserve could not be updated. No partial change was saved.'**
  String get reserveMutationError;

  /// Expense funding source section title.
  ///
  /// In en, this message translates to:
  /// **'How is this expense funded?'**
  String get expenseFundingTitle;

  /// Weekly allocation funding choice.
  ///
  /// In en, this message translates to:
  /// **'Weekly budget'**
  String get weeklyBudgetFunding;

  /// Reserve funding choice.
  ///
  /// In en, this message translates to:
  /// **'A reserve'**
  String get reserveFunding;

  /// No-reserve explanation in quick expense entry.
  ///
  /// In en, this message translates to:
  /// **'Create a reserve from the dashboard before using this funding choice.'**
  String get createReserveBeforeUse;

  /// Reserve selection field.
  ///
  /// In en, this message translates to:
  /// **'Reserve to use'**
  String get selectReserve;

  /// No-weekly-impact reserve expense explanation.
  ///
  /// In en, this message translates to:
  /// **'This expense reduces only the selected reserve. It does not change this week or the next one.'**
  String get reserveExpenseNoWeeklyImpact;

  /// Reserve balance validation.
  ///
  /// In en, this message translates to:
  /// **'The declared reserve contains only {amount}. Choose another reserve or use the weekly spread.'**
  String insufficientReserveBalance(String amount);

  /// Real reserve expense reminder title.
  ///
  /// In en, this message translates to:
  /// **'Transfer reminder'**
  String get realReserveTransferTitle;

  /// Real reserve bank transfer reminder.
  ///
  /// In en, this message translates to:
  /// **'This expense will reduce {reserveName} by {amount}. Remember to transfer {amount} from that reserve account to the main account if the payment was made there. REBOOT will not perform or verify the transfer.'**
  String realReserveTransferBody(String amount, String reserveName);

  /// Confirms a real-reserve expense after reminder.
  ///
  /// In en, this message translates to:
  /// **'I understand, record it'**
  String get confirmReserveExpense;

  /// Refund management title.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get refundsTitle;

  /// Refund method explanation.
  ///
  /// In en, this message translates to:
  /// **'Attach each refund to its original purchase. The installment plan is never rewritten, and a later refund improves the trajectory without increasing the current weekly budget.'**
  String get refundsIntro;

  /// Empty refund list.
  ///
  /// In en, this message translates to:
  /// **'There is no active purchase to refund yet.'**
  String get noRefundableExpense;

  /// Refund mutation error.
  ///
  /// In en, this message translates to:
  /// **'The refund could not be saved. No partial change was recorded.'**
  String get refundMutationError;

  /// Same-cycle refund result.
  ///
  /// In en, this message translates to:
  /// **'{amount} was restored to the original purchase week.'**
  String refundRestoredOriginalCycle(String amount);

  /// Later refund result.
  ///
  /// In en, this message translates to:
  /// **'Your trajectory improves by {amount}. This week\'s budget stays unchanged.'**
  String refundImprovesTrajectory(String amount);

  /// Refund reversal confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Reverse this incorrect refund?'**
  String get reverseRefundTitle;

  /// Refund reversal confirmation body.
  ///
  /// In en, this message translates to:
  /// **'Its effect will be neutralized, while both entries remain in the local audit history.'**
  String get reverseRefundBody;

  /// Refund reversal action.
  ///
  /// In en, this message translates to:
  /// **'Reverse refund'**
  String get reverseRefund;

  /// Original purchase summary.
  ///
  /// In en, this message translates to:
  /// **'{amount} paid on {date}'**
  String refundExpenseSummary(String amount, String date);

  /// Fully refunded purchase state.
  ///
  /// In en, this message translates to:
  /// **'Fully refunded'**
  String get fullyRefunded;

  /// Record refund action.
  ///
  /// In en, this message translates to:
  /// **'Record refund'**
  String get recordRefund;

  /// Remaining refundable amount.
  ///
  /// In en, this message translates to:
  /// **'Still refundable: {amount}'**
  String refundableRemaining(String amount);

  /// Refund history line.
  ///
  /// In en, this message translates to:
  /// **'{amount} received on {date}'**
  String refundHistoryLine(String amount, String date);

  /// Reversed refund state.
  ///
  /// In en, this message translates to:
  /// **'Incorrect entry reversed'**
  String get reversedRefund;

  /// Refund dialog title.
  ///
  /// In en, this message translates to:
  /// **'Refund for {label}'**
  String recordRefundFor(String label);

  /// Refund amount field.
  ///
  /// In en, this message translates to:
  /// **'Amount received'**
  String get refundAmount;

  /// Refund amount validation.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above zero and no greater than {maximum}.'**
  String invalidRefundAmount(String maximum);

  /// Refund receipt date.
  ///
  /// In en, this message translates to:
  /// **'Date received'**
  String get refundDate;

  /// Same-cycle restored refund amount.
  ///
  /// In en, this message translates to:
  /// **'Refunds restored this week: {amount}'**
  String refundsRestoredThisCycle(String amount);

  /// Same-cycle refund explanation.
  ///
  /// In en, this message translates to:
  /// **'Only refunds from purchases assigned to this same week restore its remaining amount.'**
  String get refundsRestoredThisCycleHelp;

  /// Refund dashboard navigation help.
  ///
  /// In en, this message translates to:
  /// **'Record a product refund against its original purchase.'**
  String get refundsDashboardHelp;

  /// Expense refunded amount.
  ///
  /// In en, this message translates to:
  /// **'Refunded: {amount}'**
  String expenseRefunded(String amount);

  /// Refund trajectory credit metric.
  ///
  /// In en, this message translates to:
  /// **'Refund credits'**
  String get trendRefundCredits;

  /// Health tracking screen title.
  ///
  /// In en, this message translates to:
  /// **'Health tracking'**
  String get healthTitle;

  /// Health tracking settings title.
  ///
  /// In en, this message translates to:
  /// **'Health settings'**
  String get healthSettings;

  /// Health mutation error.
  ///
  /// In en, this message translates to:
  /// **'Health tracking could not be updated. No partial change was recorded.'**
  String get healthMutationError;

  /// Disabled configured health state.
  ///
  /// In en, this message translates to:
  /// **'Health tracking is paused'**
  String get healthTrackingDisabled;

  /// Optional health feature title.
  ///
  /// In en, this message translates to:
  /// **'Optional health tracking'**
  String get healthTrackingOptional;

  /// Health tracking explanation.
  ///
  /// In en, this message translates to:
  /// **'Enter both health expenses and reimbursements, individually or as occasional totals. No per-claim matching is required.'**
  String get healthIntro;

  /// Health disabled method warning.
  ///
  /// In en, this message translates to:
  /// **'Without this tracking, health costs may drift unnoticed. You can instead reduce your weekly budget by a cautious amount.'**
  String get healthDisabledWarning;

  /// Enable health tracking action.
  ///
  /// In en, this message translates to:
  /// **'Enable health tracking'**
  String get enableHealthTracking;

  /// Health estimate label.
  ///
  /// In en, this message translates to:
  /// **'Estimated health amount still to cover'**
  String get healthEstimatedRest;

  /// Health estimate configuration summary.
  ///
  /// In en, this message translates to:
  /// **'Expenses older than {weeks} weeks · alert above {threshold}'**
  String healthEstimateSettings(int weeks, String threshold);

  /// Health estimate alert title.
  ///
  /// In en, this message translates to:
  /// **'This estimate deserves attention'**
  String get healthAttentionTitle;

  /// Health estimate method choices.
  ///
  /// In en, this message translates to:
  /// **'You may cover it from a reserve, the current week, or a spread of up to 12 weeks—or wait. REBOOT never changes your budget automatically.'**
  String get healthAttentionBody;

  /// Add health expense action.
  ///
  /// In en, this message translates to:
  /// **'Health expense'**
  String get addHealthExpense;

  /// Add health reimbursement action.
  ///
  /// In en, this message translates to:
  /// **'Reimbursement received'**
  String get addHealthReimbursement;

  /// Add health regularization action.
  ///
  /// In en, this message translates to:
  /// **'Already covered amount'**
  String get addHealthRegularization;

  /// Health regularization safety explanation.
  ///
  /// In en, this message translates to:
  /// **'Record an already covered amount only after you actually compensated it from a reserve or reduced spending. A negative estimate never increases the weekly budget.'**
  String get healthRegularizationHelp;

  /// Health entry history heading.
  ///
  /// In en, this message translates to:
  /// **'Health history'**
  String get healthHistory;

  /// Empty health history.
  ///
  /// In en, this message translates to:
  /// **'No health entry has been recorded since tracking began.'**
  String get noHealthEntry;

  /// Reversed health entry state.
  ///
  /// In en, this message translates to:
  /// **'Incorrect entry reversed'**
  String get reversedHealthEntry;

  /// Health reversal confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Reverse this incorrect entry?'**
  String get reverseHealthEntryTitle;

  /// Health reversal confirmation body.
  ///
  /// In en, this message translates to:
  /// **'Its effect will be neutralized, while both entries remain in the local audit history.'**
  String get reverseHealthEntryBody;

  /// Health reversal action.
  ///
  /// In en, this message translates to:
  /// **'Reverse entry'**
  String get reverseHealthEntry;

  /// Health delay setting.
  ///
  /// In en, this message translates to:
  /// **'Reimbursement delay in weeks'**
  String get healthDelayWeeks;

  /// Health delay validation.
  ///
  /// In en, this message translates to:
  /// **'Choose between 1 and 52 weeks.'**
  String get invalidHealthDelay;

  /// Health alert threshold setting.
  ///
  /// In en, this message translates to:
  /// **'Alert threshold'**
  String get healthAlertThreshold;

  /// Save health settings action.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get saveHealthSettings;

  /// Health entry amount field.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get healthEntryAmount;

  /// Health entry label field.
  ///
  /// In en, this message translates to:
  /// **'Description or total period'**
  String get healthEntryLabel;

  /// Health entry business date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get healthEntryDate;

  /// Save health entry action.
  ///
  /// In en, this message translates to:
  /// **'Record entry'**
  String get saveHealthEntry;

  /// Dashboard health estimate.
  ///
  /// In en, this message translates to:
  /// **'Health estimate: {amount}'**
  String healthDashboardEstimate(String amount);

  /// Dashboard healthy tracking state.
  ///
  /// In en, this message translates to:
  /// **'No alert under the current delay and threshold.'**
  String get healthDashboardOnTrack;

  /// Derived quick expense suggestions heading.
  ///
  /// In en, this message translates to:
  /// **'Recent and frequent shortcuts'**
  String get expenseSuggestionsTitle;

  /// Optional expense qualification heading.
  ///
  /// In en, this message translates to:
  /// **'Optional spending nature'**
  String get expenseNatureTitle;

  /// Expense nature optionality explanation.
  ///
  /// In en, this message translates to:
  /// **'This never changes the weekly amount. It only makes your trends easier to understand.'**
  String get expenseNatureHelp;

  /// Necessary expense nature.
  ///
  /// In en, this message translates to:
  /// **'Necessary'**
  String get expenseNatureNecessary;

  /// Pleasure expense nature.
  ///
  /// In en, this message translates to:
  /// **'Pleasure'**
  String get expenseNaturePleasure;

  /// Deferrable expense nature.
  ///
  /// In en, this message translates to:
  /// **'Could wait'**
  String get expenseNatureDeferrable;

  /// Unexpected expense nature.
  ///
  /// In en, this message translates to:
  /// **'Unexpected'**
  String get expenseNatureUnexpected;

  /// Unqualified expense reassurance.
  ///
  /// In en, this message translates to:
  /// **'You can leave this blank; the expense remains valid.'**
  String get expenseNatureSkipped;

  /// Selected expense nature.
  ///
  /// In en, this message translates to:
  /// **'Selected: {nature}'**
  String expenseNatureSelected(String nature);

  /// Unqualified expense insight label.
  ///
  /// In en, this message translates to:
  /// **'Not qualified'**
  String get expenseNatureUnqualified;

  /// Expense nature display line.
  ///
  /// In en, this message translates to:
  /// **'Nature: {nature}'**
  String expenseNatureDisplay(String nature);

  /// Expense nature breakdown heading.
  ///
  /// In en, this message translates to:
  /// **'How weekly spending was used'**
  String get trendNatureBreakdownTitle;

  /// Expense nature breakdown explanation.
  ///
  /// In en, this message translates to:
  /// **'Optional qualifications across the selected completed weeks. Unqualified spending is kept visible.'**
  String get trendNatureBreakdownHelp;

  /// Existing cash-flow editor title.
  ///
  /// In en, this message translates to:
  /// **'Change this assumption'**
  String get editCashFlowTitle;

  /// Confirms a future-effective cash-flow replacement.
  ///
  /// In en, this message translates to:
  /// **'Schedule this change'**
  String get saveCashFlowChange;

  /// Post-onboarding financial assumptions screen title.
  ///
  /// In en, this message translates to:
  /// **'Income and charges'**
  String get assumptionsTitle;

  /// Financial assumptions management explanation.
  ///
  /// In en, this message translates to:
  /// **'Keep every durable income and unavoidable charge accurate. REBOOT preserves the past and recalculates only future weekly budgets.'**
  String get assumptionsIntro;

  /// Next effective weekly boundary.
  ///
  /// In en, this message translates to:
  /// **'Changes apply from {date}'**
  String assumptionsEffectiveDate(String date);

  /// Immutable current weekly budget reminder.
  ///
  /// In en, this message translates to:
  /// **'The week already started never changes. A surplus or overspend is not carried over automatically.'**
  String get assumptionsCurrentWeekUnchanged;

  /// Current accepted weekly budget label.
  ///
  /// In en, this message translates to:
  /// **'Current week'**
  String get currentWeeklyBudget;

  /// Future recalculated weekly budget label.
  ///
  /// In en, this message translates to:
  /// **'From next REBOOT'**
  String get futureWeeklyBudget;

  /// Negative annual capacity warning.
  ///
  /// In en, this message translates to:
  /// **'These assumptions are short by {amount} over the next 52 weeks. The recommended weekly spending budget becomes zero.'**
  String assumptionsDeficitWarning(String amount);

  /// Sanitized assumption mutation failure.
  ///
  /// In en, this message translates to:
  /// **'The change could not be scheduled. No partial update was recorded.'**
  String get assumptionsMutationError;

  /// Adds a recurring financial assumption.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addAssumption;

  /// Edits a recurring financial assumption.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get editAssumption;

  /// Pending cash-flow change status.
  ///
  /// In en, this message translates to:
  /// **'New value from {date}'**
  String assumptionChangesOn(String date);

  /// Pending cash-flow deletion status.
  ///
  /// In en, this message translates to:
  /// **'Ends on {date}'**
  String assumptionEndsOn(String date);

  /// Future cash-flow creation status.
  ///
  /// In en, this message translates to:
  /// **'Starts on {date}'**
  String assumptionStartsOn(String date);

  /// Future cash-flow deletion confirmation title.
  ///
  /// In en, this message translates to:
  /// **'End this assumption?'**
  String get deleteAssumptionTitle;

  /// Future cash-flow deletion confirmation body.
  ///
  /// In en, this message translates to:
  /// **'It will stop affecting the budget from {date}. Earlier weeks and the local audit history remain unchanged.'**
  String deleteAssumptionBody(String date);

  /// Custom-date recurrence display label.
  ///
  /// In en, this message translates to:
  /// **'Specific dates'**
  String get frequencyCustomDates;

  /// Dashboard navigation title for financial assumptions.
  ///
  /// In en, this message translates to:
  /// **'Income and charges'**
  String get assumptionsDashboardTitle;

  /// Dashboard navigation help for financial assumptions.
  ///
  /// In en, this message translates to:
  /// **'Update a lasting change; the current week remains unchanged.'**
  String get assumptionsDashboardHelp;

  /// Post-onboarding trajectory editor title.
  ///
  /// In en, this message translates to:
  /// **'Change the trajectory'**
  String get editTrajectoryTitle;

  /// Future trajectory editor explanation.
  ///
  /// In en, this message translates to:
  /// **'Choose the amounts REBOOT should keep outside everyday spending from {date}. The week already started remains unchanged.'**
  String editTrajectoryIntro(String date);

  /// Confirms a future trajectory revision.
  ///
  /// In en, this message translates to:
  /// **'Schedule this trajectory'**
  String get saveTrajectoryChange;

  /// Trajectory review screen title.
  ///
  /// In en, this message translates to:
  /// **'REBOOT trajectory'**
  String get trajectoryManagementTitle;

  /// Trajectory review explanation.
  ///
  /// In en, this message translates to:
  /// **'Your trajectory protects money before calculating everyday weekly spending. You decide the goal; REBOOT never reallocates a surplus automatically.'**
  String get trajectoryManagementIntro;

  /// Pending trajectory status.
  ///
  /// In en, this message translates to:
  /// **'A new trajectory is scheduled for {date}'**
  String trajectoryChangeScheduled(String date);

  /// Next possible trajectory change date.
  ///
  /// In en, this message translates to:
  /// **'A change would apply from {date}'**
  String trajectoryChangeEffective(String date);

  /// Current trajectory card heading when a revision is pending.
  ///
  /// In en, this message translates to:
  /// **'Current week’s trajectory'**
  String get currentTrajectoryTitle;

  /// Current trajectory card heading.
  ///
  /// In en, this message translates to:
  /// **'Accepted trajectory'**
  String get acceptedTrajectoryTitle;

  /// Pending trajectory card heading.
  ///
  /// In en, this message translates to:
  /// **'Next trajectory'**
  String get futureTrajectoryTitle;

  /// Starts a future trajectory revision.
  ///
  /// In en, this message translates to:
  /// **'Change the trajectory'**
  String get changeTrajectory;

  /// Replaces an already pending trajectory revision.
  ///
  /// In en, this message translates to:
  /// **'Change the scheduled trajectory'**
  String get changeScheduledTrajectory;

  /// Overdraft exit target summary.
  ///
  /// In en, this message translates to:
  /// **'Target date: {date}'**
  String overdraftTargetSummary(String date);

  /// Empty annual trajectory deductions state.
  ///
  /// In en, this message translates to:
  /// **'No cushion, project or additional safety margin is currently deducted.'**
  String get noAnnualDeductions;

  /// Dashboard navigation title for trajectory management.
  ///
  /// In en, this message translates to:
  /// **'Trajectory and goals'**
  String get trajectoryDashboardTitle;

  /// Dashboard navigation help for trajectory management.
  ///
  /// In en, this message translates to:
  /// **'Review the amounts protected before the weekly budget is calculated.'**
  String get trajectoryDashboardHelp;

  /// Dashboard navigation title for weekly cycle settings.
  ///
  /// In en, this message translates to:
  /// **'REBOOT day'**
  String get cycleSettingsDashboardTitle;

  /// Dashboard navigation help for weekly cycle settings.
  ///
  /// In en, this message translates to:
  /// **'Change the start day without rewriting previous weeks.'**
  String get cycleSettingsDashboardHelp;

  /// Weekly cycle settings screen title.
  ///
  /// In en, this message translates to:
  /// **'Weekly rhythm'**
  String get cycleSettingsTitle;

  /// Explains how to choose and change the REBOOT day.
  ///
  /// In en, this message translates to:
  /// **'Your REBOOT day should normally match the day of your main grocery shop. A change affects future weeks only.'**
  String get cycleSettingsIntro;

  /// Label for the latest accepted weekly anchor.
  ///
  /// In en, this message translates to:
  /// **'Current REBOOT day'**
  String get currentRebootDay;

  /// Label for the new weekly anchor selector.
  ///
  /// In en, this message translates to:
  /// **'New REBOOT day'**
  String get newRebootDay;

  /// Explains non-retroactive weekly anchor changes.
  ///
  /// In en, this message translates to:
  /// **'The week already in progress keeps its accepted budget. REBOOT creates one visible exceptional transition, then starts complete weeks on the new day.'**
  String get rebootDayChangeHelp;

  /// Preview of the first normal week using the new anchor.
  ///
  /// In en, this message translates to:
  /// **'Complete {weekday} weeks start on {date}'**
  String rebootDayChangePreview(String weekday, String date);

  /// Exact exceptional cycle created by an anchor change.
  ///
  /// In en, this message translates to:
  /// **'Transition from {start} to {end}: {dayCount} days.'**
  String rebootTransitionPreview(String start, String end, int dayCount);

  /// Explains how transition cycles affect trends.
  ///
  /// In en, this message translates to:
  /// **'This exceptional period remains in history but is excluded from normal trend averages.'**
  String get rebootTransitionTrendHelp;

  /// Confirms a future weekly anchor change.
  ///
  /// In en, this message translates to:
  /// **'Schedule this change'**
  String get scheduleRebootDayChange;

  /// Generic weekly anchor mutation failure.
  ///
  /// In en, this message translates to:
  /// **'The new REBOOT day could not be scheduled. No partial change was saved.'**
  String get rebootDayChangeError;

  /// Pending weekly anchor summary.
  ///
  /// In en, this message translates to:
  /// **'{weekday} is already scheduled from {date}'**
  String rebootDayAlreadyScheduled(String weekday, String date);

  /// Explains why a second pending anchor change is disabled.
  ///
  /// In en, this message translates to:
  /// **'For safety in this first version, let this change take effect before scheduling another one.'**
  String get rebootDayScheduledLocked;

  /// Dashboard navigation title for received bonus pools.
  ///
  /// In en, this message translates to:
  /// **'Bonuses already received'**
  String get receivedBonusesDashboardTitle;

  /// Empty received bonus dashboard summary.
  ///
  /// In en, this message translates to:
  /// **'Add only money that still exists and is assigned to everyday spending.'**
  String get receivedBonusesDashboardEmpty;

  /// Active received bonus count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 received bonus is being spread} other{{count} received bonuses are being spread}}'**
  String receivedBonusesDashboardCount(int count);

  /// Received bonuses requiring confirmation.
  ///
  /// In en, this message translates to:
  /// **'{due, plural, =1{1 of {count} bonuses needs confirmation} other{{due} of {count} bonuses need confirmation}}'**
  String receivedBonusesDashboardDue(int count, int due);

  /// Received bonus management screen title.
  ///
  /// In en, this message translates to:
  /// **'Bonuses already received'**
  String get receivedBonusesTitle;

  /// Core already-received bonus rule.
  ///
  /// In en, this message translates to:
  /// **'A bonus never counts merely because it is expected. Enter only the part already received, still available, and deliberately assigned to everyday spending.'**
  String get receivedBonusesIntro;

  /// Bonus effective date and confirmation rule.
  ///
  /// In en, this message translates to:
  /// **'A new amount applies from {date}. REBOOT spreads it exactly until the next payment date, then waits for your confirmation.'**
  String receivedBonusRule(String date);

  /// Empty received bonus list.
  ///
  /// In en, this message translates to:
  /// **'No received bonus currently supports your weekly budget.'**
  String get noReceivedBonus;

  /// Generic received bonus mutation failure.
  ///
  /// In en, this message translates to:
  /// **'The bonus could not be saved. No partial change was recorded.'**
  String get receivedBonusMutationError;

  /// Creates a received bonus pool.
  ///
  /// In en, this message translates to:
  /// **'Add a received bonus'**
  String get addReceivedBonus;

  /// Mandatory received bonus renewal warning.
  ///
  /// In en, this message translates to:
  /// **'The expected payment date has arrived. Confirm what was actually received and what part will support everyday spending.'**
  String get receivedBonusConfirmationRequired;

  /// Received bonus allocation end.
  ///
  /// In en, this message translates to:
  /// **'Spread until the expected payment on {date}'**
  String receivedBonusUntil(String date);

  /// Pending bonus replacement status.
  ///
  /// In en, this message translates to:
  /// **'A newly confirmed amount applies from {date}'**
  String receivedBonusChangesOn(String date);

  /// Pending bonus deletion status.
  ///
  /// In en, this message translates to:
  /// **'This bonus stops affecting the budget from {date}'**
  String receivedBonusEndsOn(String date);

  /// Stops a received bonus allocation.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopReceivedBonus;

  /// Confirms a newly received bonus amount.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmReceivedBonus;

  /// Adjusts an existing received bonus amount.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get adjustReceivedBonus;

  /// Received bonus deletion confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Stop using this bonus?'**
  String get deleteReceivedBonusTitle;

  /// Received bonus deletion confirmation body.
  ///
  /// In en, this message translates to:
  /// **'It will stop increasing the weekly budget from {date}. Previous weeks remain unchanged.'**
  String deleteReceivedBonusBody(String date);

  /// Received bonus renewal dialog title.
  ///
  /// In en, this message translates to:
  /// **'Confirm the available amount'**
  String get confirmReceivedBonusTitle;

  /// Warning shown in the received bonus form.
  ///
  /// In en, this message translates to:
  /// **'Do not enter the original gross bonus or a future estimate. Enter only the amount that exists now and that you choose to inject into everyday spending.'**
  String get receivedBonusDialogHelp;

  /// Received bonus source name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get receivedBonusName;

  /// Existing received bonus amount field.
  ///
  /// In en, this message translates to:
  /// **'Amount still available for everyday spending'**
  String get receivedBonusRemainingAmount;

  /// Mandatory received bonus renewal date.
  ///
  /// In en, this message translates to:
  /// **'Next expected payment date'**
  String get receivedBonusNextPayment;

  /// Persists a received bonus snapshot.
  ///
  /// In en, this message translates to:
  /// **'Save this amount'**
  String get saveReceivedBonus;

  /// Dashboard action for the private Android home-screen widget.
  ///
  /// In en, this message translates to:
  /// **'Private weekly widget'**
  String get weeklyWidgetTitle;

  /// Privacy behavior of the Android weekly widget.
  ///
  /// In en, this message translates to:
  /// **'Shows only the remaining amount, masked until you tap it.'**
  String get weeklyWidgetHelp;

  /// Android launcher accepted the pin-widget request.
  ///
  /// In en, this message translates to:
  /// **'Confirm the widget placement on your home screen.'**
  String get weeklyWidgetRequestSent;

  /// Fallback instructions when widget pinning is unavailable.
  ///
  /// In en, this message translates to:
  /// **'Open your home-screen widget menu and add the REBOOT widget.'**
  String get weeklyWidgetManualInstall;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
