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
