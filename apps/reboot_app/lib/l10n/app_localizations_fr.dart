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

  @override
  String get trajectorySetupTitle =>
      'Choisissez le résultat que REBOOT doit créer';

  @override
  String get trajectorySetupIntro =>
      'Vos revenus et charges définissent la capacité disponible. Les choix ci-dessous déterminent ce qui reste en dehors des dépenses du budget semaine.';

  @override
  String get strategyBalanceTitle => 'Équilibre';

  @override
  String get strategyBalanceBody =>
      'Utilisez la capacité disponible sans constituer un coussin supplémentaire en douce. Les projets et marges explicitement saisis restent possibles.';

  @override
  String get strategyCushionTitle => 'Construire un coussin';

  @override
  String get strategyCushionBody =>
      'Choisissez la somme à ajouter à votre réserve pendant les 52 prochains cycles REBOOT.';

  @override
  String get strategyOverdraftTitle => 'Sortir du découvert';

  @override
  String get strategyOverdraftBody =>
      'Indiquez le découvert actuel, le coussin positif souhaité et la date à laquelle vous voulez l’atteindre.';

  @override
  String get annualCushionLabel => 'Somme ajoutée à la réserve sur 52 cycles';

  @override
  String get annualCushionHelp =>
      'Cette somme est répartie sur l’année REBOOT glissante.';

  @override
  String get currentOverdraftLabel => 'Profondeur actuelle du découvert';

  @override
  String get currentOverdraftHelp =>
      'Saisissez 1 000 si le compte est actuellement à −1 000.';

  @override
  String get targetCushionLabel => 'Coussin positif souhaité';

  @override
  String get targetCushionHelp =>
      'Saisissez zéro si votre seul objectif est de revenir à l’équilibre.';

  @override
  String get overdraftTargetDateLabel => 'Date cible';

  @override
  String get dateUnavailable => 'Date indisponible';

  @override
  String get overdraftConfirmationHelp =>
      'À cette date, REBOOT vous demandera de confirmer le résultat réel. Le budget semaine n’augmentera pas automatiquement.';

  @override
  String get otherAnnualGoalsTitle => 'Projets et sécurité';

  @override
  String get otherAnnualGoalsBody =>
      'Ces montants annuels facultatifs restent distincts des charges et de la stratégie choisie.';

  @override
  String get annualProjectsLabel => 'Projets et achats prévus sur 52 cycles';

  @override
  String get annualProjectsHelp =>
      'Par exemple un objet, un voyage ou un remplacement anticipé.';

  @override
  String get annualSafetyLabel =>
      'Marge de sécurité supplémentaire sur 52 cycles';

  @override
  String get annualSafetyHelp =>
      'Laissez zéro si vous ne souhaitez pas de marge prudente supplémentaire.';

  @override
  String get noAutomaticMargin =>
      'REBOOT n’ajoute et ne modifie jamais cette marge sans votre confirmation.';

  @override
  String get invalidNonNegativeAmount =>
      'Saisissez zéro ou un montant positif, avec deux décimales au maximum.';

  @override
  String get emptyRecoveryGoal =>
      'Le découvert et le coussin cible ne peuvent pas être tous les deux à zéro.';

  @override
  String get calculateWeeklyBudget => 'Calculer mon budget semaine';

  @override
  String get trajectorySaving => 'Calcul de la trajectoire…';

  @override
  String get trajectorySetupError =>
      'La trajectoire n’a pas pu être enregistrée. Rien n’a été sauvegardé partiellement. Vérifiez la date cible et réessayez.';

  @override
  String get firstWeeklyBudgetTitle => 'Votre premier budget REBOOT';

  @override
  String weeklyBudgetFrom(String date) {
    return 'Pour chaque semaine à partir du $date';
  }

  @override
  String get recommendedWeeklyBudget =>
      'Budget de dépense hebdomadaire recommandé';

  @override
  String weeklyRoundingHelp(String amount) {
    return 'Capacité exacte : $amount par cycle, arrondie à l’euro inférieur.';
  }

  @override
  String annualDeficit(String amount) {
    return 'Les hypothèses actuelles produisent un déficit annuel de $amount. Aucun budget de dépense ne peut encore être recommandé.';
  }

  @override
  String overdraftRecoverySummary(String amount, int cycleCount, String date) {
    return 'Conservez $amount par cycle pendant $cycleCount cycles pour viser le $date. REBOOT vous demandera alors de confirmer le résultat.';
  }

  @override
  String overdraftRecoveryImpossible(String amount) {
    return 'La date choisie exige $amount de plus par cycle que la capacité disponible. Choisissez une date plus tardive ou révisez les hypothèses.';
  }

  @override
  String get annualCalculationTitle => 'Calcul glissant sur 52 cycles';

  @override
  String get annualIncome => 'Entrées prévues';

  @override
  String get annualOutflows => 'Charges prévues';

  @override
  String get annualReserves => 'Contribution à la réserve';

  @override
  String get annualProjects => 'Projets';

  @override
  String get annualSafety => 'Marge de sécurité';

  @override
  String get annualSteerableCapacity => 'Capacité annuelle pilotable';

  @override
  String selectedTrajectory(String strategy) {
    return 'Trajectoire choisie : $strategy';
  }

  @override
  String get quickExpenseNext =>
      'La prochaine étape du produit transformera cette recommandation en restant disponible et en saisie rapide des dépenses.';

  @override
  String get refreshDashboard => 'Actualiser';

  @override
  String get remainingThisWeek => 'Vous pouvez encore dépenser';

  @override
  String get upcomingWeeklyBudget => 'Votre prochain budget semaine';

  @override
  String firstCyclePending(String date) {
    return 'Votre première semaine REBOOT commence le $date. La saisie des dépenses sera alors disponible.';
  }

  @override
  String availableFrom(String date) {
    return 'Disponible à partir du $date';
  }

  @override
  String untilNextReboot(String date) {
    return 'jusqu’à votre prochain REBOOT le $date';
  }

  @override
  String dailyGuide(String amount, int dayCount) {
    String _temp0 = intl.Intl.pluralLogic(
      dayCount,
      locale: localeName,
      other: 'Environ $amount par jour pendant les $dayCount jours restants',
      one: 'Environ $amount pour le dernier jour',
    );
    return '$_temp0';
  }

  @override
  String get weeklyOverBudget =>
      'Cette semaine dépasse le budget. Le budget de la semaine suivante ne changera pas automatiquement.';

  @override
  String get weeklyBudgetMetric => 'Budget semaine';

  @override
  String get weeklySpentMetric => 'Affecté';

  @override
  String get thisWeekExpenses => 'Dépenses de cette semaine';

  @override
  String get expensesAvailableAfterStart =>
      'Vous pourrez saisir les dépenses dès le début de la première semaine REBOOT.';

  @override
  String get noExpenseYet => 'Aucune dépense n’a encore réduit cette semaine.';

  @override
  String get noCarryoverReminder =>
      'Dépenser moins ou plus ne modifie jamais automatiquement le budget de la semaine suivante. Vous gardez le choix d’une compensation ou d’un virement vers une réserve.';

  @override
  String get addExpense => 'Ajouter une dépense';

  @override
  String get dashboardDateError =>
      'La date locale actuelle n’a pas pu être vérifiée. Vos données financières restent inchangées.';

  @override
  String get quickExpenseTitle => 'Dépense rapide';

  @override
  String get quickExpenseIntro =>
      'Saisissez-la maintenant pour que toutes les personnes utilisant le budget semaine voient le bon montant restant.';

  @override
  String get expenseAmountLabel => 'Montant payé';

  @override
  String get expenseLabel => 'Quoi ou où ?';

  @override
  String get expenseLabelHint => 'Courses, cinéma, Vinted…';

  @override
  String get expenseDate => 'Date de l’achat';

  @override
  String get expenseAllocationTitle => 'Impact sur le budget semaine';

  @override
  String get expenseAllocationHelp =>
      'Utilisez normalement une semaine. Une grosse dépense exceptionnelle peut être étalée virtuellement sur 12 semaines au maximum ; le paiement reste une seule transaction réelle.';

  @override
  String get expenseCycleCount => 'Étaler sur';

  @override
  String cycleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semaines',
      one: '1 semaine',
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
      other: '$regularAmount sur chacune des $regularCount premières semaines',
      one: '$regularAmount sur la première semaine',
    );
    return '$_temp0, puis $lastAmount sur la dernière pour absorber l’arrondi.';
  }

  @override
  String get expenseCommitmentWarning =>
      'Au moins une semaine concernée aurait déjà plus de 50 % de son budget engagé. REBOOT ne vous bloque pas, mais la méthode recommande d’utiliser une réserve ou un étalement plus long.';

  @override
  String get saveExpense => 'Enregistrer la dépense';

  @override
  String get quickExpenseSaving => 'Enregistrement…';

  @override
  String get quickExpenseError =>
      'La dépense n’a pas pu être enregistrée. Rien n’a été sauvegardé partiellement ; réessayez.';

  @override
  String splitExpenseDetail(String amount, int count, String date) {
    return '$amount payé · étalé sur $count semaines · $date';
  }

  @override
  String get deleteExpenseTitle => 'Supprimer cette saisie erronée ?';

  @override
  String get deleteExpenseBody =>
      'La dépense ne comptera plus dans le solde semaine. Son historique d’audit restera dans le journal local.';

  @override
  String deleteSplitExpenseBody(int count) {
    return 'Les $count parts hebdomadaires seront toutes retirées ensemble. Leur historique d’audit restera dans le journal local.';
  }

  @override
  String get deleteExpense => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get deleteExpenseError =>
      'La dépense n’a pas pu être supprimée. Réessayez.';

  @override
  String get trendsTitle => 'Tendances hebdomadaires';

  @override
  String get trendNoCompletedCycle =>
      'Vos tendances apparaîtront après la fin de votre première semaine REBOOT.';

  @override
  String get trendAvailableAfterCycle =>
      'Tendances disponibles après la première semaine terminée';

  @override
  String get trendObservedBalance => 'Balance observée';

  @override
  String trendCycleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sur $count semaines terminées',
      one: 'Sur 1 semaine terminée',
    );
    return '$_temp0';
  }

  @override
  String get trendStatusNone => 'La méthode est bien suivie';

  @override
  String get trendStatusVigilance => 'Gardez un œil sur la tendance';

  @override
  String get trendStatusStrong => 'Une correction mérite d’être envisagée';

  @override
  String trendSummary(String balance, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semaines terminées',
      one: '1 semaine terminée',
    );
    return '$balance sur $_temp0';
  }

  @override
  String get trendLatestOnTrack => 'Dernière semaine : budget respecté.';

  @override
  String trendLatestOverspend(String amount, String percent) {
    return 'Dernière semaine : dépassement de $amount ($percent du budget de cette semaine).';
  }

  @override
  String trendGlobalPositive(String amount) {
    return 'Trajectoire globale : $amount sur les semaines observées.';
  }

  @override
  String trendGlobalNegative(String amount, String percent) {
    return 'Trajectoire globale : $amount ($percent des budgets observés).';
  }

  @override
  String get trendBudgetUnchanged =>
      'Le budget de la semaine suivante reste inchangé. Vous choisissez si et quand vous compensez.';

  @override
  String get trendWindowTitle => 'Choisissez la perspective';

  @override
  String trendWindowLabel(int count) {
    return '$count semaines';
  }

  @override
  String trendWindowBalance(int count) {
    return 'Balance sur les $count dernières semaines';
  }

  @override
  String trendObservedCount(int observed, int requested) {
    return '$observed semaines terminées disponibles sur les $requested demandées';
  }

  @override
  String get trendHistoricalBudget => 'Budgets applicables';

  @override
  String get trendAllocated => 'Dépenses affectées';

  @override
  String get trendCycleHistory => 'Historique semaine par semaine';

  @override
  String trendCyclePeriod(String start, String end) {
    return 'Du $start au $end';
  }

  @override
  String trendExcludedTransitions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count semaines de transition exceptionnelles restent visibles dans l’historique mais sont exclues des tendances normales.',
      one:
          '1 semaine de transition exceptionnelle reste visible dans l’historique mais est exclue des tendances normales.',
    );
    return '$_temp0';
  }

  @override
  String get trendTransitionHistory => 'Transitions exceptionnelles';

  @override
  String trendSurplusSuggestion(String amount) {
    return 'Vous avez un surplus observé de $amount. Vous pouvez le virer vers une réserve ou un projet ; le choix reste le vôtre.';
  }
}
