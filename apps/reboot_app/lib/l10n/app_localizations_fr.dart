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

  @override
  String get cycleHistoryDetailTitle => 'Détail de la semaine';

  @override
  String cycleHistoryPeriod(String start, String end) {
    return 'Semaine du $start au $end';
  }

  @override
  String get cycleHistoryTransitionHelp =>
      'Cette transition exceptionnelle reste consultable mais est exclue des moyennes de tendance normales.';

  @override
  String get cycleHistoryBudget => 'Budget semaine applicable';

  @override
  String get cycleHistoryAllocated => 'Dépenses affectées';

  @override
  String get cycleHistoryRefunds => 'Remboursements reçus';

  @override
  String get cycleHistoryBalance => 'Balance de la semaine';

  @override
  String get cycleHistoryExpensesTitle => 'Dépenses affectées à cette semaine';

  @override
  String get cycleHistoryNoExpense =>
      'Aucune dépense active n’est affectée à cette semaine.';

  @override
  String cycleHistoryExpenseSource(String amount, String date) {
    return 'Dépense réelle : $amount, payée le $date';
  }

  @override
  String cycleHistoryInstallmentSource(
    int index,
    int count,
    String amount,
    String date,
  ) {
    return 'Part $index sur $count · dépense réelle : $amount, payée le $date';
  }

  @override
  String get cycleHistoryRefundsTitle =>
      'Remboursements reçus pendant cette semaine';

  @override
  String cycleHistoryRefundSource(String receivedDate, String purchaseDate) {
    return 'Reçu le $receivedDate · achat d’origine du $purchaseDate';
  }

  @override
  String get reservesTitle => 'Réserves';

  @override
  String get reservesIntro =>
      'Une réserve protège une dépense exceptionnelle sans réduire le budget semaine. REBOOT suit ce que vous déclarez ; il ne lit pas le solde bancaire.';

  @override
  String get noReserveYet =>
      'Créez une réserve pour les imprévus, la santé, un véhicule ou un autre objectif que vous souhaitez protéger.';

  @override
  String get createReserve => 'Créer une réserve';

  @override
  String get createFirstReserve => 'Créer votre première réserve';

  @override
  String reservesSummary(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réserves · $amount',
      one: '1 réserve · $amount',
    );
    return '$_temp0';
  }

  @override
  String get reservesSummaryHelp =>
      'Les comptes réels et allocations virtuelles restent distincts des dépenses de la semaine.';

  @override
  String totalReserves(String amount) {
    return 'Total déclaré des réserves : $amount';
  }

  @override
  String get reserveName => 'Nom de la réserve';

  @override
  String get reserveKind => 'Type de réserve';

  @override
  String get realReserve => 'Compte de réserve réel';

  @override
  String get virtualReserve => 'Réserve virtuelle';

  @override
  String get reserveOpeningBalance => 'Montant disponible actuellement';

  @override
  String get reserveOpeningBalanceHelp =>
      'Saisissez uniquement ce qui existe aujourd’hui. Cela ne crée aucun revenu et ne change pas votre budget semaine.';

  @override
  String get addReserveFunds => 'Ajouter des fonds';

  @override
  String get useReserve => 'Utiliser';

  @override
  String get reserveFundingAmount => 'Montant affecté';

  @override
  String get reserveFundingLabel => 'Motif';

  @override
  String get reserveFundingHint =>
      'Surplus hebdomadaire, cadeau, virement manuel…';

  @override
  String get confirmReserveFunding => 'Enregistrer les fonds';

  @override
  String realReserveFundingTransferBody(String amount, String reserveName) {
    return 'Cette saisie ajoutera $amount à $reserveName. Pensez à virer $amount du compte principal vers ce compte de réserve. REBOOT n’effectuera ni ne vérifiera le virement.';
  }

  @override
  String get confirmRealReserveFunding => 'J’ai compris, ajouter les fonds';

  @override
  String get reserveHistory => 'Mouvements récents';

  @override
  String get reversedReserveMovement => 'Saisie erronée annulée';

  @override
  String get reverseReserveMovement => 'Annuler la saisie';

  @override
  String get reverseReserveMovementTitle => 'Annuler cette saisie erronée ?';

  @override
  String get reverseReserveMovementBody =>
      'Son effet sur la réserve sera neutralisé, mais les deux événements resteront dans l’historique d’audit.';

  @override
  String get reserveMutationError =>
      'La réserve n’a pas pu être mise à jour. Aucun changement partiel n’a été enregistré.';

  @override
  String get expenseFundingTitle => 'Comment cette dépense est-elle financée ?';

  @override
  String get weeklyBudgetFunding => 'Budget semaine';

  @override
  String get reserveFunding => 'Une réserve';

  @override
  String get createReserveBeforeUse =>
      'Créez d’abord une réserve depuis le tableau de bord pour utiliser ce financement.';

  @override
  String get selectReserve => 'Réserve à utiliser';

  @override
  String get reserveExpenseNoWeeklyImpact =>
      'Cette dépense réduit uniquement la réserve sélectionnée. Elle ne change ni cette semaine ni la suivante.';

  @override
  String insufficientReserveBalance(String amount) {
    return 'La réserve déclarée contient seulement $amount. Choisissez une autre réserve ou utilisez l’étalement hebdomadaire.';
  }

  @override
  String get realReserveTransferTitle => 'Rappel de virement';

  @override
  String realReserveTransferBody(String amount, String reserveName) {
    return 'Cette dépense réduira $reserveName de $amount. Pensez à virer $amount de ce compte de réserve vers le compte principal si le paiement y a été effectué. REBOOT n’effectuera ni ne vérifiera le virement.';
  }

  @override
  String get confirmReserveExpense => 'J’ai compris, enregistrer';

  @override
  String get refundsTitle => 'Remboursements';

  @override
  String get refundsIntro =>
      'Rattachez chaque remboursement à son achat d’origine. L’étalement n’est jamais réécrit et un remboursement tardif améliore la trajectoire sans augmenter le budget de la semaine en cours.';

  @override
  String get noRefundableExpense =>
      'Aucun achat actif ne peut encore être remboursé.';

  @override
  String get refundMutationError =>
      'Le remboursement n’a pas pu être enregistré. Aucun changement partiel n’a été sauvegardé.';

  @override
  String refundRestoredOriginalCycle(String amount) {
    return '$amount a été restauré sur la semaine de l’achat.';
  }

  @override
  String refundImprovesTrajectory(String amount) {
    return 'Votre trajectoire s’améliore de $amount. Le budget de cette semaine reste inchangé.';
  }

  @override
  String get reverseRefundTitle => 'Annuler ce remboursement erroné ?';

  @override
  String get reverseRefundBody =>
      'Son effet sera neutralisé, mais les deux saisies resteront dans l’historique d’audit local.';

  @override
  String get reverseRefund => 'Annuler le remboursement';

  @override
  String refundExpenseSummary(String amount, String date) {
    return '$amount payé le $date';
  }

  @override
  String get fullyRefunded => 'Remboursé en totalité';

  @override
  String get recordRefund => 'Saisir un remboursement';

  @override
  String refundableRemaining(String amount) {
    return 'Encore remboursable : $amount';
  }

  @override
  String refundHistoryLine(String amount, String date) {
    return '$amount reçu le $date';
  }

  @override
  String get reversedRefund => 'Saisie erronée annulée';

  @override
  String recordRefundFor(String label) {
    return 'Remboursement de $label';
  }

  @override
  String get refundAmount => 'Montant reçu';

  @override
  String invalidRefundAmount(String maximum) {
    return 'Saisissez un montant supérieur à zéro et inférieur ou égal à $maximum.';
  }

  @override
  String get refundDate => 'Date de réception';

  @override
  String refundsRestoredThisCycle(String amount) {
    return 'Remboursements restaurés cette semaine : $amount';
  }

  @override
  String get refundsRestoredThisCycleHelp =>
      'Seuls les remboursements d’achats affectés à cette même semaine restaurent son restant.';

  @override
  String get refundsDashboardHelp =>
      'Rattachez le remboursement d’un produit à son achat d’origine.';

  @override
  String expenseRefunded(String amount) {
    return 'Remboursé : $amount';
  }

  @override
  String get trendRefundCredits => 'Remboursements';

  @override
  String get healthTitle => 'Suivi Santé';

  @override
  String get healthSettings => 'Réglages Santé';

  @override
  String get healthMutationError =>
      'Le suivi Santé n’a pas pu être mis à jour. Aucun changement partiel n’a été enregistré.';

  @override
  String get healthTrackingDisabled => 'Le suivi Santé est en pause';

  @override
  String get healthTrackingOptional => 'Suivi Santé facultatif';

  @override
  String get healthIntro =>
      'Saisissez les dépenses de santé et les remboursements, un par un ou sous forme de totaux occasionnels. Aucun rapprochement dossier par dossier n’est imposé.';

  @override
  String get healthDisabledWarning =>
      'Sans ce suivi, les frais de santé peuvent dériver sans alerte. Vous pouvez à la place réduire prudemment votre budget semaine.';

  @override
  String get enableHealthTracking => 'Activer le suivi Santé';

  @override
  String get healthEstimatedRest => 'Reste Santé estimé à couvrir';

  @override
  String healthEstimateSettings(int weeks, String threshold) {
    return 'Dépenses de plus de $weeks semaines · alerte au-dessus de $threshold';
  }

  @override
  String get healthAttentionTitle => 'Cette estimation mérite votre attention';

  @override
  String get healthAttentionBody =>
      'Vous pouvez la couvrir avec une réserve, la semaine en cours ou un étalement jusqu’à 12 semaines — ou attendre. REBOOT ne modifie jamais votre budget automatiquement.';

  @override
  String get addHealthExpense => 'Dépense de santé';

  @override
  String get addHealthReimbursement => 'Remboursement reçu';

  @override
  String get addHealthRegularization => 'Montant déjà compensé';

  @override
  String get healthRegularizationHelp =>
      'N’indiquez un montant déjà compensé qu’après l’avoir réellement couvert par une réserve ou une réduction des dépenses. Une estimation négative n’augmente jamais le budget semaine.';

  @override
  String get healthHistory => 'Historique Santé';

  @override
  String get noHealthEntry => 'Aucune saisie Santé depuis le début du suivi.';

  @override
  String get reversedHealthEntry => 'Saisie erronée annulée';

  @override
  String get reverseHealthEntryTitle => 'Annuler cette saisie erronée ?';

  @override
  String get reverseHealthEntryBody =>
      'Son effet sera neutralisé, mais les deux saisies resteront dans l’historique d’audit local.';

  @override
  String get reverseHealthEntry => 'Annuler la saisie';

  @override
  String get healthDelayWeeks => 'Délai de remboursement en semaines';

  @override
  String get invalidHealthDelay => 'Choisissez entre 1 et 52 semaines.';

  @override
  String get healthAlertThreshold => 'Seuil d’alerte';

  @override
  String get saveHealthSettings => 'Enregistrer les réglages';

  @override
  String get healthEntryAmount => 'Montant';

  @override
  String get healthEntryLabel => 'Description ou période du total';

  @override
  String get healthEntryDate => 'Date';

  @override
  String get saveHealthEntry => 'Enregistrer la saisie';

  @override
  String healthDashboardEstimate(String amount) {
    return 'Estimation Santé : $amount';
  }

  @override
  String get healthDashboardOnTrack =>
      'Aucune alerte selon le délai et le seuil actuels.';

  @override
  String get expenseSuggestionsTitle => 'Raccourcis récents et fréquents';

  @override
  String get expenseNatureTitle => 'Nature facultative de la dépense';

  @override
  String get expenseNatureHelp =>
      'Ce choix ne change jamais le montant de la semaine. Il sert uniquement à mieux comprendre vos tendances.';

  @override
  String get expenseNatureNecessary => 'Nécessaire';

  @override
  String get expenseNaturePleasure => 'Plaisir';

  @override
  String get expenseNatureDeferrable => 'Aurait pu attendre';

  @override
  String get expenseNatureUnexpected => 'Imprévu';

  @override
  String get expenseNatureSkipped =>
      'Vous pouvez ne rien choisir : la dépense reste valide.';

  @override
  String expenseNatureSelected(String nature) {
    return 'Choisi : $nature';
  }

  @override
  String get expenseNatureUnqualified => 'Non qualifié';

  @override
  String expenseNatureDisplay(String nature) {
    return 'Nature : $nature';
  }

  @override
  String get trendNatureBreakdownTitle => 'À quoi le budget semaine a servi';

  @override
  String get trendNatureBreakdownHelp =>
      'Qualifications facultatives sur les semaines terminées sélectionnées. Les dépenses non qualifiées restent visibles.';

  @override
  String get editCashFlowTitle => 'Modifier cette hypothèse';

  @override
  String get saveCashFlowChange => 'Planifier cette modification';

  @override
  String get assumptionsTitle => 'Revenus et charges';

  @override
  String get assumptionsIntro =>
      'Maintenez à jour chaque revenu durable et chaque charge incontournable. REBOOT conserve le passé et recalcule uniquement les futurs budgets semaine.';

  @override
  String assumptionsEffectiveDate(String date) {
    return 'Les modifications s’appliquent à partir du $date';
  }

  @override
  String get assumptionsCurrentWeekUnchanged =>
      'La semaine déjà commencée ne change jamais. Un surplus ou un dépassement n’est pas reporté automatiquement.';

  @override
  String get currentWeeklyBudget => 'Semaine actuelle';

  @override
  String get futureWeeklyBudget => 'Dès le prochain REBOOT';

  @override
  String assumptionsDeficitWarning(String amount) {
    return 'Ces hypothèses créent un manque de $amount sur les 52 prochaines semaines. Le budget semaine recommandé devient nul.';
  }

  @override
  String get assumptionsMutationError =>
      'La modification n’a pas pu être planifiée. Aucun changement partiel n’a été enregistré.';

  @override
  String get addAssumption => 'Ajouter';

  @override
  String get editAssumption => 'Modifier';

  @override
  String assumptionChangesOn(String date) {
    return 'Nouvelle valeur à partir du $date';
  }

  @override
  String assumptionEndsOn(String date) {
    return 'Prend fin le $date';
  }

  @override
  String assumptionStartsOn(String date) {
    return 'Commence le $date';
  }

  @override
  String assumptionSource(String source) {
    return 'Source : $source';
  }

  @override
  String get assumptionSourceLabel => 'Source';

  @override
  String get assumptionSourceManual => 'Saisie manuelle';

  @override
  String assumptionMethod(String method) {
    return 'Méthode : $method';
  }

  @override
  String get assumptionMethodFixed => 'Montant fixe déclaré';

  @override
  String assumptionMethodVariable(String strategy) {
    return 'Estimation variable · $strategy';
  }

  @override
  String assumptionLastConfirmed(String date) {
    return 'Dernière confirmation : $date';
  }

  @override
  String get assumptionLastConfirmedLabel => 'Dernière confirmation';

  @override
  String get assumptionConfirmationMissing =>
      'Dernière confirmation : à confirmer';

  @override
  String get assumptionConfirmationMissingShort => 'À confirmer';

  @override
  String get deleteAssumptionTitle => 'Mettre fin à cette hypothèse ?';

  @override
  String deleteAssumptionBody(String date) {
    return 'Elle cessera d’affecter le budget à partir du $date. Les semaines précédentes et l’historique d’audit local restent inchangés.';
  }

  @override
  String get frequencyCustomDates => 'Dates précises';

  @override
  String get assumptionsDashboardTitle => 'Revenus et charges';

  @override
  String get assumptionsDashboardHelp =>
      'Déclarez un changement durable ; la semaine en cours reste inchangée.';

  @override
  String get editTrajectoryTitle => 'Modifier la trajectoire';

  @override
  String editTrajectoryIntro(String date) {
    return 'Choisissez les montants que REBOOT doit protéger du quotidien à partir du $date. La semaine déjà commencée reste inchangée.';
  }

  @override
  String get saveTrajectoryChange => 'Planifier cette trajectoire';

  @override
  String get trajectoryManagementTitle => 'Trajectoire REBOOT';

  @override
  String get trajectoryManagementIntro =>
      'Votre trajectoire protège de l’argent avant de calculer les dépenses du quotidien. Vous choisissez l’objectif ; REBOOT ne réaffecte jamais automatiquement un surplus.';

  @override
  String trajectoryChangeScheduled(String date) {
    return 'Une nouvelle trajectoire est planifiée pour le $date';
  }

  @override
  String trajectoryChangeEffective(String date) {
    return 'Une modification s’appliquerait à partir du $date';
  }

  @override
  String get currentTrajectoryTitle => 'Trajectoire de la semaine actuelle';

  @override
  String get acceptedTrajectoryTitle => 'Trajectoire acceptée';

  @override
  String get futureTrajectoryTitle => 'Prochaine trajectoire';

  @override
  String get changeTrajectory => 'Modifier la trajectoire';

  @override
  String get changeScheduledTrajectory => 'Modifier la trajectoire planifiée';

  @override
  String overdraftTargetSummary(String date) {
    return 'Date cible : $date';
  }

  @override
  String get noAnnualDeductions =>
      'Aucun coussin, projet ou marge de sécurité supplémentaire n’est actuellement retiré.';

  @override
  String get trajectoryDashboardTitle => 'Trajectoire et objectifs';

  @override
  String get trajectoryDashboardHelp =>
      'Consultez les montants protégés avant le calcul du budget semaine.';

  @override
  String get cycleSettingsDashboardTitle => 'Jour REBOOT';

  @override
  String get cycleSettingsDashboardHelp =>
      'Changez le jour de départ sans réécrire les semaines passées.';

  @override
  String get cycleSettingsTitle => 'Rythme hebdomadaire';

  @override
  String get cycleSettingsIntro =>
      'Votre jour REBOOT devrait normalement correspondre au jour des courses principales. Un changement affecte uniquement les semaines futures.';

  @override
  String get currentRebootDay => 'Jour REBOOT actuel';

  @override
  String get newRebootDay => 'Nouveau jour REBOOT';

  @override
  String get rebootDayChangeHelp =>
      'La semaine déjà commencée conserve son budget accepté. REBOOT crée une période de transition exceptionnelle visible, puis débute des semaines complètes au nouveau jour.';

  @override
  String rebootDayChangePreview(String weekday, String date) {
    return 'Les semaines complètes du $weekday débutent le $date';
  }

  @override
  String rebootTransitionPreview(String start, String end, int dayCount) {
    return 'Transition du $start au $end : $dayCount jours.';
  }

  @override
  String get rebootTransitionTrendHelp =>
      'Cette période exceptionnelle reste dans l’historique mais est exclue des moyennes de tendance normales.';

  @override
  String get scheduleRebootDayChange => 'Planifier ce changement';

  @override
  String get rebootDayChangeError =>
      'Le nouveau jour REBOOT n’a pas pu être planifié. Aucun changement partiel n’a été enregistré.';

  @override
  String rebootDayAlreadyScheduled(String weekday, String date) {
    return 'Le $weekday est déjà planifié à partir du $date';
  }

  @override
  String get rebootDayScheduledLocked =>
      'Par sécurité dans cette première version, laissez ce changement prendre effet avant d’en planifier un autre.';

  @override
  String get receivedBonusesDashboardTitle => 'Primes déjà reçues';

  @override
  String get receivedBonusesDashboardEmpty =>
      'Ajoutez uniquement l’argent qui existe encore et qui est destiné au quotidien.';

  @override
  String receivedBonusesDashboardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count primes reçues sont en cours de lissage',
      one: '1 prime reçue est en cours de lissage',
    );
    return '$_temp0';
  }

  @override
  String receivedBonusesDashboardDue(int count, int due) {
    String _temp0 = intl.Intl.pluralLogic(
      due,
      locale: localeName,
      other: '$due primes sur $count doivent être confirmées',
      one: '1 prime sur $count doit être confirmée',
    );
    return '$_temp0';
  }

  @override
  String get receivedBonusesTitle => 'Primes déjà reçues';

  @override
  String get receivedBonusesIntro =>
      'Une prime ne compte jamais parce qu’elle est simplement attendue. Saisissez uniquement la part déjà reçue, encore disponible et volontairement destinée au quotidien.';

  @override
  String receivedBonusRule(String date) {
    return 'Un nouveau montant s’applique à partir du $date. REBOOT le répartit exactement jusqu’au prochain versement, puis attend votre confirmation.';
  }

  @override
  String get noReceivedBonus =>
      'Aucune prime reçue ne soutient actuellement votre budget semaine.';

  @override
  String get receivedBonusMutationError =>
      'La prime n’a pas pu être enregistrée. Aucun changement partiel n’a été sauvegardé.';

  @override
  String get addReceivedBonus => 'Ajouter une prime reçue';

  @override
  String get receivedBonusConfirmationRequired =>
      'La date de versement attendue est arrivée. Confirmez ce qui a réellement été reçu et la part destinée au quotidien.';

  @override
  String receivedBonusUntil(String date) {
    return 'Répartie jusqu’au versement attendu le $date';
  }

  @override
  String receivedBonusChangesOn(String date) {
    return 'Un nouveau montant confirmé s’applique à partir du $date';
  }

  @override
  String receivedBonusEndsOn(String date) {
    return 'Cette prime cesse d’affecter le budget à partir du $date';
  }

  @override
  String get stopReceivedBonus => 'Arrêter';

  @override
  String get confirmReceivedBonus => 'Confirmer';

  @override
  String get adjustReceivedBonus => 'Ajuster';

  @override
  String get deleteReceivedBonusTitle => 'Arrêter d’utiliser cette prime ?';

  @override
  String deleteReceivedBonusBody(String date) {
    return 'Elle cessera d’augmenter le budget semaine à partir du $date. Les semaines précédentes restent inchangées.';
  }

  @override
  String get confirmReceivedBonusTitle => 'Confirmer le montant disponible';

  @override
  String get receivedBonusDialogHelp =>
      'Ne saisissez ni la prime brute d’origine ni une estimation future. Indiquez uniquement le montant qui existe aujourd’hui et que vous choisissez d’injecter dans le quotidien.';

  @override
  String get receivedBonusName => 'Nom';

  @override
  String get receivedBonusRemainingAmount =>
      'Montant encore disponible pour le quotidien';

  @override
  String get receivedBonusNextPayment => 'Date du prochain versement attendu';

  @override
  String get saveReceivedBonus => 'Enregistrer ce montant';

  @override
  String get weeklyWidgetTitle => 'Widget semaine confidentiel';

  @override
  String get weeklyWidgetHelp =>
      'Affiche uniquement le restant, masqué jusqu’à ce que vous le touchiez.';

  @override
  String get weeklyWidgetRequestSent =>
      'Confirmez l’ajout du widget sur votre écran d’accueil.';

  @override
  String get weeklyWidgetManualInstall =>
      'Ouvrez le menu des widgets de l’écran d’accueil et ajoutez le widget REBOOT.';

  @override
  String get budgetExplanationDashboardTitle => 'Comprendre mon budget';

  @override
  String get budgetExplanationDashboardHelp =>
      'Consultez chaque hypothèse, protection et arrondi derrière le montant semaine.';

  @override
  String get budgetExplanationTitle => 'Comment ce budget est calculé';

  @override
  String get budgetExplanationIntro =>
      'REBOOT reconstruit ce montant à partir des entrées et dépenses validées pour les 52 prochains cycles. Aucune compensation d’une semaine passée n’est cachée dans le calcul.';

  @override
  String calculationHorizon(String start, String end) {
    return 'Calcul du $start au $end inclus';
  }

  @override
  String get baseWeeklyBudget => 'Budget semaine de base';

  @override
  String get receivedBonusWeeklyAddition =>
      'Prime reçue disponible cette semaine';

  @override
  String get weeklyBudgetComposition => 'Composition hebdomadaire';

  @override
  String get exactWeeklyCapacity => 'Capacité exacte avant arrondi';

  @override
  String get unallocatedAnnualMarginLabel =>
      'Capacité annuelle laissée hors budget semaine';

  @override
  String get unallocatedAnnualMarginHelp =>
      'Cette marge provient de l’arrondi à l’euro inférieur et, si elle est configurée, de la part réservée à la sortie de découvert. Elle reste sur le compte : REBOOT ne la dépense pas en douce.';

  @override
  String cashFlowOccurrences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count occurrences',
      one: '1 occurrence',
      zero: 'Aucune occurrence',
    );
    return '$_temp0';
  }

  @override
  String get cashFlowReferenceAmount => 'Montant par occurrence';

  @override
  String get cashFlowEstimation => 'Estimation du montant variable';

  @override
  String get rebootMethodTitle => 'La méthode REBOOT';

  @override
  String get rebootMethodIntro =>
      'Le paramétrage fait le travail difficile une fois ; le quotidien reste volontairement simple :';

  @override
  String get methodStepRecord =>
      'Recenser toutes les entrées régulières et les dépenses incontournables.';

  @override
  String get methodStepEstimate =>
      'Estimer prudemment les montants variables sur une année entière.';

  @override
  String get methodStepBlock =>
      'Bloquer les réserves, projets et une marge de sécurité avant le quotidien.';

  @override
  String get methodStepOrganize =>
      'Organiser la capacité restante en budgets semaine identiques.';

  @override
  String get methodStepObserve =>
      'Observer le restant avant de dépenser, pas le solde bancaire.';

  @override
  String get methodStepTune =>
      'Réajuster les hypothèses uniquement quand les revenus, dépenses ou habitudes changent.';

  @override
  String get futureCommitmentsDashboardTitle => 'Engagements futurs';

  @override
  String get futureCommitmentsDashboardEmpty =>
      'Aucune dépense ne réduit un futur budget semaine.';

  @override
  String futureCommitmentsDashboardSummary(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count futures semaines',
      one: '1 future semaine',
    );
    return '$amount déjà répartis sur $_temp0';
  }

  @override
  String get futureCommitmentsTitle => 'Engagements futurs';

  @override
  String get futureCommitmentsIntro =>
      'Ces montants proviennent de dépenses déjà payées et réparties sur plusieurs semaines REBOOT. Ils réduisent le disponible prévisionnel sans créer une nouvelle opération bancaire.';

  @override
  String get futureCommitmentsTotal => 'Total restant engagé';

  @override
  String futureCommitmentsCycleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semaines sont concernées',
      one: '1 semaine est concernée',
    );
    return '$_temp0';
  }

  @override
  String get noFutureCommitments =>
      'Aucune dépense n’est actuellement engagée sur un futur budget semaine.';

  @override
  String futureCommitmentPeriod(String start, String end) {
    return 'Semaine du $start au $end';
  }

  @override
  String get futureCycleBudget => 'Budget semaine habituel';

  @override
  String get futureCycleCommitted => 'Déjà engagé';

  @override
  String get futureCycleAvailable => 'Disponible prévisionnel';

  @override
  String get futureCommitmentStrongWarning =>
      'Plus de la moitié de ce budget semaine est déjà engagée. Vérifiez le restant avant d’accepter un nouvel étalement.';

  @override
  String futureCommitmentSource(String amount, String date) {
    return 'Dépense réelle : $amount, payée le $date';
  }

  @override
  String get webPrototypeTitle =>
      'Le stockage Web sécurisé est en cours de validation';

  @override
  String get webPrototypeBody =>
      'L’interface REBOOT fonctionne désormais dans un navigateur, mais la persistance chiffrée et la récupération ne sont pas encore prêtes pour de vraies données financières.';

  @override
  String get webPrototypeSafety =>
      'Aucune saisie n’est enregistrée dans un stockage non chiffré ou temporaire. Utilisez l’application Android pendant cette preuve de sécurité.';

  @override
  String get dataPrivacyTitle => 'Données et confidentialité';

  @override
  String get encryptedLocalProfileTitle => 'Profil local chiffré';

  @override
  String get encryptedLocalProfileBody =>
      'Votre journal financier est conservé dans une base chiffrée, dans l’espace privé de l’application. Son secret est protégé par le stockage sécurisé d’Android.';

  @override
  String get currentProtectionTitle => 'Protection sur cet appareil';

  @override
  String get localOnlyDataTitle => 'Les données restent sur cet appareil';

  @override
  String get localOnlyDataBody =>
      'Cette version n’utilise ni connexion bancaire ni synchronisation distante des données.';

  @override
  String get androidBackupDisabledTitle =>
      'Sauvegarde système Android désactivée';

  @override
  String get androidBackupDisabledBody =>
      'La base chiffrée et sa clé sont exclues des sauvegardes Android afin d’éviter une copie inutilisable ou insuffisamment protégée.';

  @override
  String get noTelemetryTitle => 'Aucune télémétrie';

  @override
  String get noTelemetryBody =>
      'Cette version n’envoie ni mesure d’usage, ni montant financier, ni libellé d’opération.';

  @override
  String get syncRecoveryTitle => 'Synchronisation et récupération';

  @override
  String get syncUnavailableTitle => 'Synchronisation pas encore activée';

  @override
  String get syncUnavailableBody =>
      'REBOOT fonctionne actuellement hors ligne, uniquement sur cet appareil Android. Le partage et la synchronisation chiffrés ne seront ajoutés qu’après validation de leur modèle de sécurité.';

  @override
  String get recoveryUnavailableTitle =>
      'Aucune récupération disponible pour le moment';

  @override
  String get recoveryUnavailableBody =>
      'Si l’application est désinstallée, si ses données sont effacées ou si cet appareil et sa clé sont perdus, ce profil local ne peut pas encore être restauré. L’export et la récupération chiffrés restent à développer.';

  @override
  String get financialAssumptionsStatusTitle => 'Hypothèses financières';

  @override
  String financialAssumptionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hypothèses actives',
      one: '1 hypothèse active',
      zero: 'Aucune hypothèse active',
    );
    return '$_temp0';
  }

  @override
  String financialAssumptionsKinds(int fixedCount, int variableCount) {
    return '$fixedCount fixes · $variableCount variables';
  }

  @override
  String oldestAssumptionConfirmation(String date) {
    return 'Confirmation la plus ancienne : $date';
  }

  @override
  String get assumptionsNeverChangedAutomatically =>
      'REBOOT ne modifie jamais automatiquement un montant de référence. Un import ou une future synchronisation pourra proposer une correction, mais vous déciderez toujours.';

  @override
  String get manageFinancialAssumptions => 'Vérifier les revenus et charges';
}
