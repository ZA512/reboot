// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'REBOOT';

  @override
  String get profileOpening => 'Ouverture de votre profil REBOOT';

  @override
  String get profileLockedTitle => 'Le profil local ne peut pas être ouvert.';

  @override
  String get profileLockedBody =>
      'Aucune donnée n’a été supprimée ni recréée. Déverrouillez l’appareil puis réessayez.';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get welcomeHeadline =>
      'Reprenez vos dépenses en main, une semaine à la fois.';

  @override
  String get welcomeBody =>
      'REBOOT transforme vos revenus, charges et objectifs en un montant hebdomadaire simple à suivre.';

  @override
  String get encryptedProfileReady => 'Votre profil local chiffré est prêt.';

  @override
  String get startSetup => 'Configurer mon REBOOT';

  @override
  String get setupTitle => 'Configurez votre rythme hebdomadaire';

  @override
  String get setupIntro =>
      'Choisissez le jour où votre budget semaine commence. Nous conseillons le jour des courses principales, afin que l’alimentation essentielle soit dépensée en premier.';

  @override
  String get householdQuestion => 'Qui utilise ce budget semaine ?';

  @override
  String get sharedHouseholdTitle => 'Un compte principal commun';

  @override
  String get sharedHouseholdBody =>
      'Tout le monde dépense sur le même budget semaine, même avec plusieurs cartes.';

  @override
  String get soloHouseholdTitle => 'Moi uniquement';

  @override
  String get soloHouseholdBody => 'Je gère un seul budget semaine personnel.';

  @override
  String get rebootDayQuestion => 'Quel est votre jour REBOOT ?';

  @override
  String get rebootDayHelp =>
      'Vous pourrez le changer plus tard. L’historique conservera le jour qui s’appliquait à l’époque.';

  @override
  String get weekdayMonday => 'Lundi';

  @override
  String get weekdayTuesday => 'Mardi';

  @override
  String get weekdayWednesday => 'Mercredi';

  @override
  String get weekdayThursday => 'Jeudi';

  @override
  String get weekdayFriday => 'Vendredi';

  @override
  String get weekdaySaturday => 'Samedi';

  @override
  String get weekdaySunday => 'Dimanche';

  @override
  String get startQuestion => 'Quand la première semaine doit-elle commencer ?';

  @override
  String startNextTitle(String date) {
    return 'Commencer le $date';
  }

  @override
  String get startNextBody =>
      'L’option la plus simple. Vous commencerez avec une nouvelle semaine complète.';

  @override
  String startPreviousTitle(String date) {
    return 'Commencer depuis le $date';
  }

  @override
  String get startPreviousBody =>
      'Saisissez toutes les dépenses du budget semaine effectuées depuis cette date pour obtenir un solde juste.';

  @override
  String get startsToday =>
      'Votre première semaine REBOOT commence aujourd’hui.';

  @override
  String get timeZoneTitle => 'Fuseau horaire local';

  @override
  String timeZoneDetected(String zone) {
    return 'Détecté : $zone';
  }

  @override
  String get timeZoneLoading => 'Détection du fuseau horaire de l’appareil…';

  @override
  String get timeZoneError =>
      'Le fuseau horaire de l’appareil n’a pas pu être vérifié.';

  @override
  String get detectAgain => 'Détecter à nouveau';

  @override
  String get confirmSetup => 'Créer mon profil REBOOT';

  @override
  String get creatingProfile => 'Création du profil chiffré…';

  @override
  String get setupError =>
      'Le profil n’a pas pu être créé. Rien n’a été enregistré partiellement. Réessayez.';

  @override
  String get readySolo => 'Votre profil REBOOT personnel est prêt.';

  @override
  String get readyShared => 'Votre profil REBOOT commun est prêt.';
}
