# Méthode REBOOT

- Version : 0.1
- Date : 2026-07-30
- Statut : fondation produit validée, détails d’implémentation à compléter

## Promesse

**REBOOT — Regain Expenses, Back On Our Track**

REBOOT transforme une trajectoire financière annuelle en un montant hebdomadaire simple à piloter. L’utilisateur prépare soigneusement ses revenus, charges, dépenses lissées, réserves et objectifs, puis se concentre au quotidien sur une seule question :

> Combien pouvons-nous encore dépenser jusqu’au prochain jour REBOOT ?

REBOOT n’est ni une comptabilité générale, ni un outil de surveillance permanente du solde bancaire, ni un arbitre de l’équité financière dans le couple.

Si les hypothèses saisies restent exactes et que le budget choisi est respecté, la méthode construit une trajectoire mathématiquement neutre ou positive. Les imprévus, les changements de revenus et les erreurs de saisie empêchent d’en faire une garantie absolue de gain.

## Les six étapes

### Français

1. **Recenser** les revenus et les dépenses.
2. **Estimer** les montants variables sur l’année.
3. **Bloquer** les charges, réserves et objectifs.
4. **Organiser** son cycle hebdomadaire.
5. **Observer** sa trajectoire.
6. **Trancher** soi-même les ajustements.

### Anglais

1. **Record** income and expenses.
2. **Estimate** variable amounts over a year.
3. **Block** commitments, reserves and goals.
4. **Organize** the weekly cycle.
5. **Observe** the trajectory.
6. **Tune** future choices.

## Périmètre du premier MVP

Le premier MVP cible :

- un foyer solo ou un foyer utilisant un compte courant principal partagé ;
- un budget hebdomadaire commun au foyer ;
- plusieurs comptes de réserve facultatifs, réels ou virtuels ;
- la France et l’euro ;
- des interfaces en français et en anglais.

Le MVP ne propose pas :

- de budget individuel par membre ;
- d’analyse de l’équité entre partenaires ;
- de prévision de découvert par compte ;
- de fusion de comptes personnels séparés.

Une version ultérieure pourra relier deux espaces solo. Chaque personne conserverait son propre budget et pourrait partager uniquement son restant hebdomadaire avec son partenaire. Les budgets ne seraient ni additionnés ni rééquilibrés automatiquement.

## Onboarding

L’onboarding propose deux niveaux de précision dans le même parcours, sans créer deux modèles incompatibles.

### Entrées d’argent

L’écran présente une liste de lignes facultatives, par exemple :

- salaire 1 ;
- salaire 2 ;
- prestation ou allocation 1 ;
- prestation ou allocation 2 ;
- pension ;
- autre revenu récurrent ;
- autre entrée personnalisée.

Chaque ligne accepte un titre, un montant et une fréquence. L’utilisateur peut ajouter, renommer ou supprimer des lignes.

La fréquence mensuelle est sélectionnée par défaut. REBOOT propose les rythmes courants :

- hebdomadaire ;
- toutes les quatre semaines ;
- mensuel ;
- trimestriel ;
- semestriel ;
- annuel ;
- dates personnalisées.

Pour un rythme trop particulier, l’utilisateur peut calculer lui-même le total attendu sur l’année et utiliser la fréquence annuelle.

Une astuce explique :

> Vous pouvez calculer tous vos revenus de votre côté et saisir uniquement un total. Les détailler permettra toutefois à REBOOT de mieux détecter les changements futurs.

### Sorties d’argent

Le même principe s’applique aux charges et dépenses lissées. Les propositions utilisent des noms génériques et non des marques ou organismes propres à un pays :

- logement ;
- électricité ;
- gaz ou chauffage ;
- eau ;
- assurances ;
- télécommunications ;
- crédits ;
- transport ;
- garde d’enfants ou scolarité ;
- impôts et taxes ;
- autre charge personnalisée.

L’utilisateur peut saisir un total global ou détailler progressivement les éléments. Lorsqu’un total est décomposé, les nouveaux éléments remplacent une partie de ce total afin d’éviter tout double comptage.

Le parcours demande ensuite :

- le jour REBOOT ;
- la stratégie : équilibre, coussin ou sortie de découvert ;
- les réserves et principaux imprévus à préparer.

## Construction du budget

```text
total de toutes les entrées prévues sur 52 cycles
  - total de toutes les sorties prévues sur 52 cycles
  - provisions et réserves choisies
  - projets et objectifs
  - marge de sécurité
= capacité annuelle pilotable
```

```text
capacité annuelle pilotable / 52
= budget REBOOT hebdomadaire
```

L’horizon est toujours glissant : REBOOT projette les 52 cycles à venir à partir du cycle actif. Il ne se termine ni à la fin de l’année civile ni à la date anniversaire de l’onboarding.

Toutes les entrées prévisibles sont prises en compte :

- salaires ;
- prestations familiales et sociales, dont CAF et allocations ;
- pensions ;
- revenus récurrents fixes ou variables ;
- primes et autres entrées planifiées.

Une entrée ponctuelle non prévue ne modifie pas le budget hebdomadaire. REBOOT propose de :

- la placer dans une réserve ;
- l’affecter à un projet ou à un objet à acheter ;
- financer une dépense exceptionnelle ;
- la conserver sans affectation.

Si une prime ou une autre entrée est raisonnablement attendue tous les ans, elle possède une récurrence annuelle. Elle ne contribue toutefois au quotidien qu’à travers les montants déjà reçus et explicitement affectés selon la règle suivante.

### Prime à durée de vie

Une prime versée en une seule fois ne peut soutenir le quotidien que si l’argent correspondant existe encore et si l’utilisateur décide explicitement de l’y affecter.

À la création du profil, l’utilisateur indique :

- le montant encore disponible et destiné au quotidien, et non le montant brut initial de la prime ;
- la prochaine date anniversaire ou date de versement attendue.

Le montant disponible est réparti uniquement sur les cycles restant avant cette date.

À la date anniversaire, REBOOT demande de confirmer :

- que la nouvelle prime a réellement été reçue ;
- le montant reçu cette année ;
- la part que l’utilisateur veut injecter dans son quotidien.

Seule cette part confirmée est répartie jusqu’à la prochaine date anniversaire. Une prime future, même habituelle, n’est jamais utilisée avant confirmation de sa réception.

Une prime semestrielle possède deux dates de versement. À chaque occurrence, le montant réellement reçu et affecté au quotidien est confirmé puis réparti jusqu’à l’occurrence suivante.

Une prime mensuelle est traitée comme un revenu variable récurrent et estimée à partir d’une moyenne, plutôt que comme une succession de primes à durée de vie.

La part non affectée au quotidien peut financer un projet, une réserve ou une dépense exceptionnelle. Elle ne modifie pas le budget hebdomadaire.

Toutes les sorties prévisibles sont également prises en compte :

- charges mensuelles ;
- charges annuelles, comme le ramonage ou une assurance ;
- charges périodiques non mensuelles ;
- dépenses variables lissées ;
- dépenses irrégulières estimées.

Chaque élément possède une fréquence, des dates prévues ou une estimation annuelle. Exemples d’annualisation :

```text
montant mensuel × 12
montant hebdomadaire × 52
montant toutes les 4 semaines × 13
montant annuel × 1
```

Lorsque des dates exactes sont connues, le moteur compte les occurrences réelles présentes dans les 52 cycles au lieu d’appliquer aveuglément un multiplicateur.

Pour un revenu variable, REBOOT propose :

- **prudent** : 90 % de la moyenne annuelle disponible ;
- **équilibré** : 100 % de cette moyenne ;
- **personnalisé** : montant libre, avec avertissement s’il dépasse l’historique connu.

Pour une charge variable lissée, REBOOT propose :

- **prudent** : 110 % de la moyenne annuelle disponible ;
- **équilibré** : 100 % de cette moyenne ;
- **personnalisé** : montant libre.

Les revenus, charges et objectifs sont ainsi annualisés avant d’être transposés sur les semaines. Le mois civil n’est jamais l’unité principale : sa durée varie et il peut contenir quatre ou cinq occurrences du jour REBOOT.

Le budget brut conserve les centimes. La recommandation du MVP est arrondie à l’euro inférieur :

```text
budget brut :       233,82 €
budget recommandé : 233 €
marge conservée :     0,82 € par cycle
```

Cette marge reste dans la trajectoire annuelle. Aucun arrondi automatique à 5 € n’est appliqué.

## Contrôle des hypothèses

L’import ou la synchronisation ne modifie jamais automatiquement un montant de référence.

Ils servent à comparer les opérations observées aux hypothèses confirmées par l’utilisateur :

- salaire moyen ;
- prestations et autres revenus ;
- charges fixes ;
- dépenses variables lissées, comme l’essence ;
- charges annuelles ou irrégulières.

Lorsque les montants observés dérivent durablement de l’hypothèse, REBOOT émet une alerte et propose une nouvelle valeur. L’utilisateur doit confirmer toute modification du budget futur.

Même lorsque toutes les opérations sont importées automatiquement, REBOOT demande périodiquement de confirmer que les montants moyens et leur traitement correspondent toujours à la réalité du foyer.

Le budget hebdomadaire reste stable tant qu’aucune donnée structurelle ne change. Un surplus ou un dépassement sur une semaine ne modifie jamais automatiquement le budget de la semaine suivante.

L’utilisateur choisit lui-même de conserver un surplus, de le placer dans une réserve ou de faire un effort ultérieur. Une modification durable d’un revenu, d’une charge ou d’un objectif peut produire une nouvelle recommandation, qui doit être acceptée explicitement.

## Cycle hebdomadaire

Le jour REBOOT est choisi pendant l’onboarding en fonction du rythme réel du foyer. Il correspond idéalement au jour de la principale dépense alimentaire, afin que cette dépense nécessaire arrive au début du cycle et que le restant soit ensuite réellement arbitrable.

L’écran principal affiche en priorité :

```text
Il vous reste 147 jusqu’à samedi
```

Il peut également afficher :

```text
147 / 230
Repère moyen : 36,75 par jour
```

Le repère journalier est informatif et ne constitue pas un sous-budget quotidien.

Un changement de jour REBOOT crée un cycle exceptionnel de transition conformément à l’ADR-0002.

À chaque nouveau jour REBOOT :

- le cycle précédent devient une période historique utilisable dans les tendances ;
- un nouveau cycle hebdomadaire commence ;
- l’horizon de projection glisse pour conserver 52 cycles à venir.

Il n’existe aucune clôture mensuelle ou annuelle obligatoire.

## Saisie rapide

La saisie en temps réel est le comportement recommandé, particulièrement pour un foyer où plusieurs personnes utilisent le même budget.

Une dépense demande au minimum :

- un montant ;
- un libellé libre ou un raccourci.

Une dépense payée en une seule fois peut avoir deux traitements dans la méthode :

- être entièrement affectée au cycle courant ;
- être étalée sur plusieurs cycles.

Exemple pour une dépense réelle de 150 € étalée sur trois semaines :

```text
dépense réelle :             150 €
affectation au cycle actuel : 50 €
engagement cycle suivant :    50 €
engagement cycle +2 :         50 €
```

La transaction réelle de 150 € est conservée pour l’audit et le rapprochement. Les trois affectations virtuelles réduisent les restants hebdomadaires correspondants sans créer trois nouvelles dépenses.

Pour un montant non divisible exactement :

1. REBOOT arrondit les `N - 1` premières échéances au centime inférieur ;
2. la dernière échéance est calculée comme le montant total moins toutes les échéances précédentes.

Exemple :

```text
28 € sur trois semaines
= 9,33 € + 9,33 € + 9,34 €
```

Toutes les affectations sont créées dès la confirmation, avec leurs dates futures.

Plusieurs étalements peuvent se chevaucher. Par exemple, deux dépenses successives de 150 € étalées chacune sur trois semaines produisent :

```text
première dépense : 50 € + 50 € + 50 €
seconde dépense :         50 € + 50 € + 50 €
engagement total : 50 € + 100 € + 100 € + 50 €
```

REBOOT additionne donc tous les engagements déjà prévus pour chaque cycle futur.

La date proposée est la date de saisie. Pour une dépense oubliée, REBOOT recommande d’indiquer la date d’achat réelle, ce qui peut corriger rétroactivement un ancien cycle et ses tendances.

L’utilisateur peut néanmoins choisir de l’affecter au cycle courant. La dépense réduit alors le restant actuel et n’est toujours comptée qu’une seule fois.

Un raccourci peut mémoriser :

- le libellé ;
- le mode de financement ;
- une catégorie ;
- une nature facultative.

Les natures proposées restent peu nombreuses :

- nécessaire ;
- plaisir ;
- reportable ;
- imprévu.

Une dépense non qualifiée reste valide. Les statistiques seront simplement moins détaillées.

REBOOT ne peut piloter que les opérations qui lui sont déclarées. Une dépense oubliée augmente artificiellement le restant affiché ; un remboursement oublié dégrade artificiellement l’estimation correspondante. L’application explique cette conséquence sans bloquer l’utilisateur ni prétendre contrôler son compte bancaire.

## Modes de financement

L’**annualisation** d’une charge récurrente lors de la configuration et l’**étalement** d’une dépense déjà réalisée sont deux mécanismes distincts.

### Budget hebdomadaire

La dépense réduit immédiatement le restant de la semaine.

### Charge fixe ou lissée

La charge a déjà été retirée lors du calcul annuel. Elle ne réduit pas le restant hebdomadaire.

L’utilisateur n’a pas besoin de la saisir manuellement. Il peut néanmoins le faire pour faciliter un futur rapprochement.

Une même enseigne pouvant correspondre à plusieurs usages, le libellé seul ne permet jamais de décider automatiquement du financement. Par exemple, une opération `Super U` peut être une course hebdomadaire ou un achat d’essence déjà lissé.

### Réserve

La dépense réduit la réserve sélectionnée et non le budget hebdomadaire.

Une réserve est déclarée comme :

- **réelle**, lorsqu’elle correspond à un compte bancaire distinct ;
- **virtuelle**, lorsqu’elle représente une allocation interne dans le même compte.

Pour une réserve réelle, REBOOT rappelle le montant du virement à effectuer vers le compte courant lors de son utilisation. Pour une réserve virtuelle, aucune opération bancaire réelle n’est demandée.

REBOOT ne vérifie pas le solde bancaire de la réserve. La cohérence dépend des opérations déclarées par l’utilisateur.

### Transfert

Un virement entre deux comptes ou enveloppes du foyer n’est ni un revenu ni une dépense.

## Tendances

Le cycle courant affiche son restant en direct. Les tendances historiques utilisent les cycles terminés.

Chaque cycle conserve :

- le budget applicable à cette date ;
- les dépenses hebdomadaires réelles ;
- l’écart positif ou négatif.

```text
tendance sur N cycles =
  somme des budgets applicables
  - somme des dépenses hebdomadaires réelles
```

Les fenêtres proposées sont 4, 8, 16, 32 et 52 cycles. L’analyse ne dépasse pas une année.

Un ancien cycle n’est jamais recalculé avec le budget actuel. Un cycle exceptionnel de transition reste visible dans l’historique, mais il est exclu par défaut des tendances hebdomadaires normales.

### Balance observée et alertes

La balance principale utilise tous les cycles terminés disponibles, dans la limite des 52 derniers :

```text
balance observée =
  somme des budgets applicables
  - somme des dépenses hebdomadaires affectées
```

REBOOT distingue deux pourcentages :

```text
dépassement du dernier cycle / budget du dernier cycle
```

```text
balance négative cumulée / somme des budgets observés
```

Seuils du MVP :

- moins de 5 % : aucune alerte ;
- de 5 % inclus à 15 % exclus : vigilance ;
- 15 % ou plus : alerte forte dans l’application.

La sévérité affichée correspond au signal le plus important, mais le détail distingue toujours l’écart récent de la trajectoire générale.

Exemple : un dépassement unique de 23 € sur un budget de 80 € produit une alerte forte pour la dernière semaine. Si les semaines précédentes étaient positives, le détail indique néanmoins que la méthode reste globalement bien suivie.

Le cycle suivant conserve son budget normal :

```text
Budget de la semaine : 200 €  /!\
```

L’icône ou la zone tactile explique :

- le dépassement du dernier cycle ;
- la balance cumulée ;
- le nombre de cycles observés, jusqu’à 52 ;
- si la trajectoire globale reste saine ou dérive.

La couleur renforce le message, mais n’est jamais le seul moyen de transmettre l’alerte.

Le MVP affiche les valeurs réelles observées. Il n’extrapole pas encore automatiquement la dérive sur une année complète.

Au passage au cycle suivant, un résumé court peut indiquer :

```text
Semaine terminée : +18 €
Tendance sur 8 semaines : +74 €
```

Ce résumé sert à montrer si le foyer reste sur sa trajectoire ou creuse progressivement un écart. Il ne déclenche aucune compensation automatique.

Des statistiques par année civile pourront être proposées comme lecture secondaire, sans intervenir dans le calcul du budget.

## Remboursement d’un achat

Un remboursement de produit corrige la dépense d’origine.

- s’il arrive pendant le même cycle, il peut restaurer le restant de ce cycle ;
- s’il arrive après la clôture, il améliore la trajectoire annuelle sans augmenter automatiquement le budget de la semaine actuelle ;
- l’utilisateur décide de conserver, réserver ou redépenser l’argent reçu.

Dans le MVP, un remboursement ne reconfigure pas un étalement déjà confirmé. Les affectations prévues restent en place et le remboursement améliore la trajectoire annuelle. Utiliser ce surplus pour compenser ou financer autre chose reste une décision de l’utilisateur.

Message proposé :

> Remboursement reçu : votre trajectoire annuelle s’améliore de 80 €. Votre budget de la semaine reste inchangé.

## Santé sans rapprochement individuel

REBOOT ne demande pas à l’utilisateur de consulter séparément chaque décompte d’assurance maladie ou de mutuelle.

Le suivi Santé est facultatif. Lorsqu’il est activé, son estimation n’a de sens que si l’utilisateur déclare les deux flux :

- les dépenses de santé ;
- les remboursements reçus.

Ces flux peuvent être saisis opération par opération ou sous forme de montants agrégés. L’utilisateur peut par exemple saisir une fois par mois le total des remboursements observés sur son compte, sans les rattacher à chaque consultation.

L’application utilise une estimation agrégée :

```text
reste_santé_estimé =
  dépenses_santé_plus_anciennes_que_le_délai
  - remboursements_santé_reçus
  - montants_déjà_régularisés
```

Le calcul commence à la date de début du suivi ou au début d’un historique importé jugé suffisamment complet.

Paramètres par défaut :

- délai avant prise en compte : 4 semaines ;
- seuil d’alerte : 50 €.

L’utilisateur peut augmenter le délai s’il sait que ses remboursements prennent habituellement plus de temps. Le seuil est également modifiable.

Cette valeur est une estimation de pilotage et non un rapprochement comptable exact. Un résultat négatif ne crée jamais de budget hebdomadaire supplémentaire.

Si l’utilisateur désactive le suivi Santé et ne constitue aucune provision dédiée, REBOOT indique que les dépenses non suivies peuvent dégrader la trajectoire. Il propose alors d’augmenter la marge de sécurité ou de réduire le budget hebdomadaire, sans appliquer automatiquement cette modification.

Lorsque le reste estimé dépasse le seuil, l’utilisateur peut :

- utiliser une réserve ;
- l’affecter à la semaine en cours ;
- le répartir sur plusieurs semaines ;
- ne rien faire pour l’instant.

## Rattrapage d’une dépense importante

La même mécanique s’applique à la santé, au vétérinaire, à une réparation automobile ou à une autre facture importante.

Elle s’applique également à une charge annuelle connue mais insuffisamment préparée. Par exemple, une facture de 600 € arrivant bientôt sans réserve suffisante peut être répartie sur la durée choisie par l’utilisateur.

Choix proposés :

- utiliser une réserve ;
- affecter tout le montant à la semaine actuelle ;
- répartir le montant de 1 à 12 semaines.

Pour une dépense quotidienne ordinaire, l’affectation complète au cycle courant est sélectionnée par défaut. Pour une dépense importante ou une régularisation, REBOOT peut proposer 3 semaines. L’utilisateur reste libre de choisir une durée de 1 à 12 semaines.

REBOOT affiche toujours la réduction de chaque semaine avant validation.

Une fois confirmé, l’étalement et sa source de financement ne sont pas reconfigurables dans le premier MVP.

Si la somme de tous les engagements affectés à un cycle dépasse 50 % du budget REBOOT applicable à ce cycle, l’application affiche un avertissement fort. Elle indique que les dépenses engagées ne sont pas absorbables confortablement par le budget courant et invite à :

- utiliser une réserve disponible ;
- reporter ou réduire la dépense lorsque cela est possible ;
- examiner séparément une solution de financement et en déclarer ensuite les véritables échéances.

REBOOT ne recommande, ne fournit et ne souscrit aucun crédit.

L’utilisateur peut confirmer même si les engagements dépassent 50 % du budget ou rendent un futur disponible négatif. REBOOT rappelle alors explicitement que cette décision éloigne la trajectoire de l’équilibre recherché. Il ne bloque pas l’utilisateur et ne présente jamais ce choix comme recommandé.

Avant validation, un aperçu peut présenter les engagements futurs :

```text
Budget habituel la semaine prochaine : 230 €
Dépenses déjà engagées :              -120 €
Disponible prévisionnel :              110 €
```

### Suppression et erreur de saisie

Le MVP ne modifie pas un étalement existant.

Une transaction erronée peut être supprimée, qu’elle appartienne au cycle actuel ou à un cycle passé. Si elle possède un étalement :

- la transaction réelle fait l’objet d’une suppression métier par événement tombstone ;
- toutes ses affectations passées et futures sont annulées ensemble ;
- les cycles et tendances concernés sont recalculés ;
- aucune échéance individuelle ne peut être conservée, déplacée ou modifiée.

Pour remplacer la transaction, l’utilisateur en crée ensuite une nouvelle avec les bonnes informations. Cette règle privilégie un audit simple et évite les plans partiellement incohérents.

L’utilisateur peut choisir une durée allant jusqu’à 12 semaines, même si elle dépasse la date de paiement. REBOOT distingue alors :

- la préparation constituée avant l’échéance ;
- le rattrapage virtuel poursuivi après le paiement.

Exemple :

```text
Montant à régulariser :    90 €
Durée choisie :             3 semaines
Réduction par semaine :    30 €
```

Le budget REBOOT de référence reste inchangé. Le rattrapage est un effort temporaire explicitement accepté :

```text
Budget REBOOT habituel :  230 €
Rattrapage santé :        -30 €
Disponible cette semaine : 200 €
```

Le montant réel de la facture est conservé pour le rapprochement. Les allocations virtuelles de rattrapage ne créent pas de nouvelles dépenses et ne provoquent aucun double comptage.

## Espèces

L’utilisateur choisit une méthode :

### Retrait dépensé

Le retrait réduit immédiatement le budget. Les achats effectués avec ces espèces ne sont pas saisis une seconde fois.

### Portefeuille espèces

Le retrait est un transfert vers un portefeuille virtuel. Chaque achat en espèces réduit ensuite le budget au moment de sa saisie.

Un changement de méthode possède une date d’effet et ne réinterprète pas les opérations passées.

## Invariants de simplicité

- un seul montant hebdomadaire principal ;
- aucune compensation automatique entre semaines ;
- aucun budget individuel dans un foyer partagé du MVP ;
- aucune classification obligatoire à la saisie ;
- aucune mutation automatique d’une hypothèse annuelle ;
- aucune dépense comptée deux fois ;
- aucune hausse automatique du budget après un remboursement ou un revenu supérieur aux prévisions ;
- toute correction ou tout rattrapage important reste un choix explicite de l’utilisateur.
- la fiabilité du restant et des tendances dépend de la complétude des dépenses, remboursements et transferts déclarés ;
- REBOOT explique les conséquences d’un oubli ou d’une saisie volontairement décalée, mais laisse l’utilisateur responsable de ses choix.

## Affectation d’un surplus hebdomadaire

Un surplus de prime déjà lissée n’est pas compté une seconde fois. En revanche, les sous-dépenses réelles s’accumulent dans la tendance.

Exemple :

```text
budget hebdomadaire : 200 €
dépenses réelles :    150 €
surplus par semaine :  50 €
sur 10 semaines :     500 €
```

Après huit cycles terminés, REBOOT peut proposer d’affecter tout ou partie du surplus cumulé à une réserve ou à un projet :

- réaffectation interne pour une réserve virtuelle ;
- rappel de virement et confirmation de l’utilisateur pour un compte de réserve réel.

Cette proposition ne déclenche jamais automatiquement le transfert ni une hausse du budget hebdomadaire.

La fenêtre de huit cycles évite de traiter comme une économie durable une courte période atypique : séjour chez des proches, maladie, impossibilité temporaire d’acheter ou dépense simplement reportée à la semaine suivante.
