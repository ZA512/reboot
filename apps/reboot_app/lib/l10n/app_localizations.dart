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
