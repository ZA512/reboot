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

  @override
  String get financialSetupTitle =>
      'Listez toutes les entrées et sorties d’argent';

  @override
  String get financialSetupIntro =>
      'REBOOT annualise ces hypothèses avant de calculer votre budget semaine. La fréquence mensuelle est sélectionnée par défaut, mais la fréquence et le caractère fixe ou variable sont indépendants.';

  @override
  String get financialSetupTip =>
      'Vous pouvez saisir un seul total pour tous les revenus ou toutes les charges. Les détailler demande plus de temps maintenant, mais facilitera la détection des changements futurs.';

  @override
  String get incomeSectionTitle => 'Entrées d’argent';

  @override
  String get incomeSectionBody =>
      'Salaires, allocations, pensions et toutes les autres entrées prévisibles.';

  @override
  String get outflowSectionTitle => 'Charges et dépenses lissées';

  @override
  String get outflowSectionBody =>
      'Incluez les charges mensuelles, annuelles ou non mensuelles, ainsi que les dépenses variables incontournables que vous préférez lisser.';

  @override
  String get suggestionsLabel =>
      'Ajoutez une ligne suggérée ou personnalisée :';

  @override
  String get deleteDraft => 'Supprimer cette ligne en brouillon';

  @override
  String get confirmFinancialSetup => 'Confirmer les revenus et charges';

  @override
  String get financialSetupSaving => 'Enregistrement des hypothèses…';

  @override
  String get financialSetupMinimum =>
      'Ajoutez au moins un revenu et une charge pour continuer.';

  @override
  String get financialSetupError =>
      'Les revenus et charges n’ont pas pu être enregistrés. Rien n’a été sauvegardé partiellement. Réessayez.';

  @override
  String get addIncomeTitle => 'Ajouter une entrée d’argent';

  @override
  String get addOutflowTitle => 'Ajouter une charge';

  @override
  String get cashFlowTitleLabel => 'Nom';

  @override
  String get requiredField => 'Ce champ est obligatoire.';

  @override
  String get amountBehaviorLabel => 'Le montant est-il fixe ou variable ?';

  @override
  String get fixedAmount => 'Fixe';

  @override
  String get variableAmount => 'Variable';

  @override
  String get amountPerOccurrenceLabel => 'Montant à chaque versement';

  @override
  String get fixedAmountHelp => 'Saisissez le montant attendu à chaque fois.';

  @override
  String get averageAmountLabel => 'Moyenne observée à chaque versement';

  @override
  String get averageAmountHelp =>
      'Utilisez l’historique disponible ; REBOOT applique ensuite la stratégie ci-dessous.';

  @override
  String get invalidPositiveAmount =>
      'Saisissez un montant supérieur à zéro, avec deux décimales au maximum.';

  @override
  String get estimateStrategyLabel => 'Stratégie d’estimation';

  @override
  String get strategyPrudent => 'Prudente';

  @override
  String get strategyBalanced => 'Équilibrée';

  @override
  String get strategyCustom => 'Personnalisée';

  @override
  String get prudentIncomeHelp => 'REBOOT retient 90 % de la moyenne observée.';

  @override
  String get prudentOutflowHelp =>
      'REBOOT prévoit 110 % de la moyenne observée.';

  @override
  String get balancedHelp => 'REBOOT utilise 100 % de la moyenne observée.';

  @override
  String get customStrategyHelp =>
      'Choisissez le montant que REBOOT doit utiliser à chaque occurrence.';

  @override
  String get customAmountLabel => 'Montant utilisé par REBOOT';

  @override
  String get frequencyLabel => 'Fréquence';

  @override
  String get frequencyWeekly => 'Hebdomadaire';

  @override
  String get frequencyEveryFourWeeks => 'Toutes les quatre semaines';

  @override
  String get frequencyMonthly => 'Mensuelle';

  @override
  String get frequencyQuarterly => 'Trimestrielle';

  @override
  String get frequencySemiAnnual => 'Semestrielle';

  @override
  String get frequencyAnnual => 'Annuelle';

  @override
  String get referenceDateLabel => 'Date d’occurrence de référence';

  @override
  String get referenceDateHelp =>
      'Choisissez une date passée ou à venir où ce versement a lieu. REBOOT conserve son jour de semaine ou son jour prévu dans le mois.';

  @override
  String get irregularFrequencyTip =>
      'Pour un rythme inhabituel, calculez le total attendu sur un an et saisissez-le comme un seul montant annuel.';

  @override
  String get addThisCashFlow => 'Ajouter cette ligne';

  @override
  String cashFlowSummary(String amount, String frequency, String behavior) {
    return '$amount · $frequency · $behavior';
  }

  @override
  String get suggestionSalary1 => 'Salaire 1';

  @override
  String get suggestionSalary2 => 'Salaire 2';

  @override
  String get suggestionBenefit1 => 'Prestation ou allocation 1';

  @override
  String get suggestionBenefit2 => 'Prestation ou allocation 2';

  @override
  String get suggestionPension => 'Pension';

  @override
  String get suggestionOtherIncome => 'Autre revenu';

  @override
  String get suggestionHousing => 'Logement';

  @override
  String get suggestionElectricity => 'Électricité';

  @override
  String get suggestionHeating => 'Gaz ou chauffage';

  @override
  String get suggestionWater => 'Eau';

  @override
  String get suggestionInsurance => 'Assurances';

  @override
  String get suggestionTelecom => 'Télécommunications';

  @override
  String get suggestionLoans => 'Crédits';

  @override
  String get suggestionTransport => 'Transport';

  @override
  String get suggestionChildcare => 'Garde d’enfants ou scolarité';

  @override
  String get suggestionTaxes => 'Impôts et taxes';

  @override
  String get suggestionOtherOutflow => 'Autre charge';
}
