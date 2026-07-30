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

## Construction du budget

```text
revenus annuels de référence
  - charges fixes
  - dépenses essentielles lissées
  - provisions et réserves
  - projets et objectifs
  - marge de sécurité choisie
= capacité annuelle pilotable
```

```text
capacité annuelle pilotable / 52
= budget REBOOT hebdomadaire
```

L’horizon est toujours glissant : REBOOT projette les 52 cycles à venir à partir du cycle actif. Il ne se termine ni à la fin de l’année civile ni à la date anniversaire de l’onboarding.

Les revenus, charges et objectifs sont annualisés avant d’être transposés sur les semaines. Le mois civil n’est jamais l’unité principale : sa durée varie et il peut contenir quatre ou cinq occurrences du jour REBOOT.

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

Choix proposés :

- utiliser une réserve ;
- affecter tout le montant à la semaine actuelle ;
- répartir le montant de 1 à 12 semaines.

La durée proposée par défaut est de 3 semaines. REBOOT affiche toujours la réduction hebdomadaire avant validation.

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
