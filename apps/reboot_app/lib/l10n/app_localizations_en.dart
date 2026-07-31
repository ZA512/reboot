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
}
