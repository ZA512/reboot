# PRD — REBOOT

## Regain Expenses, Back On Our Track

- Version : 2.0
- Date : 2026-07-31
- Statut : spécification produit de référence
- Cibles initiales : Android et iOS
- Langues initiales : anglais et français
- Devise du premier MVP : EUR

## 0. Sources et gouvernance

Ce document définit la vision, le périmètre, les exigences et l’ordre de livraison de REBOOT.

Les règles détaillées de la méthode sont définies dans la [Méthode REBOOT](reboot-method.md). Les décisions techniques acceptées sont définies dans les [ADR](adr/README.md).

Le [PRD Budget52 original](archive/PRD-Budget52-v1.0.md) est conservé sans modification pour la traçabilité historique. Il n’est plus la source normative du produit courant.

En cas de contradiction :

1. la contradiction doit être documentée ;
2. aucune formule ou propriété de sécurité ne doit être modifiée silencieusement ;
3. le PRD, la méthode et les ADR concernés doivent être remis en cohérence avant implémentation.

## 1. Vision

REBOOT transforme l’ensemble des entrées, charges, dépenses lissées, réserves et objectifs d’un foyer en un montant hebdomadaire simple à piloter.

Après un paramétrage initial sérieux, l’utilisateur doit pouvoir répondre immédiatement à une question :

> Combien pouvons-nous encore dépenser jusqu’au prochain jour REBOOT ?

Le produit s’adresse notamment aux personnes et foyers qui peinent à voir une dérive financière au quotidien malgré des revenus suffisants et des charges prévisibles.

REBOOT n’est pas :

- une comptabilité générale ;
- un gestionnaire de patrimoine ;
- un outil de surveillance permanente du solde bancaire ;
- un arbitre de l’équité financière dans le couple ;
- un fournisseur de crédit ;
- une application exigeant une connexion bancaire.

## 2. Principes fondateurs

### 2.1. Piloter à la semaine et prévoir sur un an

Le mois civil n’est jamais l’unité principale. Sa durée varie et il peut contenir quatre ou cinq occurrences du jour choisi par le foyer.

Le budget est piloté par cycles hebdomadaires civils. La projection porte toujours sur les 52 cycles à venir.

### 2.2. Préparer en détail, vivre simplement

Les revenus, charges, dépenses irrégulières, réserves et objectifs sont étudiés lors du paramétrage. Une fois cette préparation terminée, l’usage quotidien se concentre sur un restant hebdomadaire et une saisie rapide.

### 2.3. Ne jamais compenser automatiquement

Un surplus ou un dépassement ne modifie pas automatiquement le budget de la semaine suivante. Toute nouvelle recommandation, marge, réserve ou correction doit être comprise et acceptée par l’utilisateur.

### 2.4. Proposer sans contraindre

REBOOT alerte, explique et conseille. L’utilisateur peut confirmer un choix défavorable ou ignorer une recommandation. L’application rappelle alors que la trajectoire recherchée peut ne pas être atteinte.

### 2.5. Rester explicable

Aucun montant conseillé ne doit apparaître comme un nombre magique. Les hypothèses, calculs, arrondis, engagements et conséquences restent consultables.

### 2.6. Local-first

La saisie et la lecture du budget fonctionnent hors ligne. Les données financières restent chiffrées localement et lors d’une synchronisation facultative.

## 3. La méthode

### Français

1. **Recenser** les revenus et les dépenses.
2. **Estimer** les montants variables sur l’année.
3. **Bloquer** les charges, réserves et objectifs.
4. **Organiser** le cycle hebdomadaire.
5. **Observer** la trajectoire.
6. **Trancher** soi-même les ajustements.

### Anglais

1. **Record** income and expenses.
2. **Estimate** variable amounts over a year.
3. **Block** commitments, reserves and goals.
4. **Organize** the weekly cycle.
5. **Observe** the trajectory.
6. **Tune** future choices.

## 4. Utilisateurs et périmètre

### 4.1. Premier périmètre

REBOOT prend en charge :

- un utilisateur solo ;
- un foyer utilisant un compte courant principal partagé ;
- un budget hebdomadaire commun ;
- plusieurs réserves réelles ou virtuelles ;
- plusieurs appareils partageant ultérieurement le même budget chiffré.

Le produit ne crée aucun sous-budget individuel dans un foyer partagé.

### 4.2. Hors périmètre initial

- fusion de comptes personnels séparés ;
- analyse de l’équité entre partenaires ;
- prévision de découvert par compte ;
- initiation de virements ;
- recommandations ou souscription de crédit ;
- multi-devise dans un même foyer ;
- catégorisation comptable exhaustive ;
- modification automatique d’une hypothèse financière.

Une version ultérieure pourra relier deux espaces solo et partager uniquement leurs restants respectifs, sans fusionner leurs budgets.

## 5. Calcul du budget

```text
total des entrées prévues sur 52 cycles
  - total des sorties prévues sur 52 cycles
  - provisions et réserves choisies
  - projets et objectifs
  - marge de sécurité
= capacité annuelle pilotable
```

```text
capacité annuelle pilotable / 52
= budget REBOOT hebdomadaire brut
```

Le moteur :

- utilise des entiers signés 64 bits en unités mineures ;
- conserve tous les centimes ;
- arrondit la recommandation EUR à l’euro inférieur ;
- refuse les calculs entre devises différentes ;
- ne propose jamais un budget de dépense négatif.

Les règles exactes sont fixées par l’[ADR-0003](adr/0003-money-and-rounding.md).

## 6. Entrées et sorties

Chaque revenu ou charge possède :

- un titre ;
- un montant ;
- une fréquence ;
- un comportement `Fixe` ou `Variable` ;
- une date de début ;
- une date de fin facultative ;
- une méthode d’estimation lorsque le montant est variable ;
- une date de dernière confirmation.

La fréquence mensuelle est proposée par défaut. Les rythmes courants sont hebdomadaire, toutes les quatre semaines, mensuel, trimestriel, semestriel, annuel et dates personnalisées.

Un rythme atypique peut être saisi sous forme d’un total annuel.

Pour un revenu variable :

- prudent : 90 % de la moyenne annuelle ;
- équilibré : 100 % ;
- personnalisé : montant libre.

Pour une sortie variable lissée :

- prudent : 110 % de la moyenne annuelle ;
- équilibré : 100 % ;
- personnalisé : montant libre.

## 7. Prime à durée de vie

Une prime reçue en une seule fois ne soutient le quotidien que si le montant existe encore et lui est explicitement affecté.

Au démarrage, l’utilisateur saisit :

- le montant encore disponible pour le quotidien ;
- la prochaine date de versement attendue.

Le montant est réparti jusqu’à cette date. À chaque nouvelle occurrence, REBOOT exige la confirmation du montant réellement reçu et de la part destinée au quotidien.

Une prime future n’est jamais comptée avant sa réception. Une prime mensuelle est traitée comme un revenu variable récurrent.

## 8. Onboarding

L’onboarding propose des listes génériques et personnalisables.

Entrées suggérées :

- salaire 1 et salaire 2 ;
- prestations ou allocations ;
- pensions ;
- revenus récurrents personnalisés.

Sorties suggérées :

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
- autres charges.

L’utilisateur peut détailler chaque élément ou saisir un total. Le détail est recommandé car il améliore les futures alertes. Une décomposition ultérieure remplace une partie du total existant sans double comptage.

Le parcours demande également :

- le jour REBOOT ;
- la stratégie : équilibre, coussin ou sortie de découvert ;
- les réserves principales ;
- les dépenses annuelles et irrégulières connues.

Le premier cycle commence par défaut au prochain jour REBOOT. L’utilisateur peut reprendre depuis l’occurrence précédente s’il saisit toutes les dépenses déjà réalisées.

## 9. Cycles hebdomadaires

Un cycle normal :

- commence à 00:00 locale le jour choisi ;
- contient sept dates civiles ;
- ne repose jamais sur une durée de 168 heures ;
- conserve la politique et le fuseau applicables.

Le jour est idéalement choisi en fonction de la dépense alimentaire principale du foyer.

Un changement de jour crée un cycle exceptionnel de transition, visible dans l’historique et exclu par défaut des tendances normales.

Les détails sont fixés par l’[ADR-0002](adr/0002-civil-weekly-cycles.md).

## 10. Écran principal et saisie

L’écran principal affiche en priorité :

```text
Il vous reste 147 jusqu’à samedi
147 / 230
Repère moyen : 36,75 par jour
```

Le repère journalier est informatif.

La saisie rapide demande au minimum :

- un montant ;
- un libellé ou raccourci.

Un raccourci peut mémoriser catégorie, mode de financement et nature facultative :

- nécessaire ;
- plaisir ;
- reportable ;
- imprévu.

Une qualification absente ne bloque jamais la saisie.

## 11. Affectation des dépenses

Une dépense peut :

- réduire le budget hebdomadaire ;
- être déjà annualisée comme charge fixe ou variable lissée ;
- utiliser une réserve réelle ou virtuelle ;
- être un transfert sans effet sur le budget ;
- relever du suivi Santé ;
- être étalée sur plusieurs cycles.

Le libellé seul ne décide jamais automatiquement de l’affectation. Une même enseigne peut correspondre à des usages différents.

## 12. Étalement

Une dépense réelle peut être affectée au cycle courant ou étalée sur 1 à 12 cycles.

Pour `N` échéances :

- les `N - 1` premières utilisent le quotient arrondi au centime inférieur ;
- la dernière absorbe le reliquat exact ;
- toutes les affectations futures sont créées dès la confirmation.

Les engagements qui se chevauchent sont additionnés par cycle.

Si leur somme dépasse 50 % du budget applicable ou rend un futur disponible négatif, REBOOT affiche un avertissement fort sans bloquer la confirmation.

Un étalement n’est pas modifiable dans le premier MVP. Une erreur se corrige par suppression complète de la transaction et de toutes ses affectations, puis nouvelle saisie.

## 13. Tendances et alertes

```text
balance observée =
  somme des budgets applicables
  - somme des dépenses hebdomadaires affectées
```

Les fenêtres sont 4, 8, 16, 32 et 52 cycles. L’indicateur principal utilise tous les cycles terminés disponibles, dans la limite de 52.

REBOOT distingue :

- le dépassement du dernier cycle rapporté à son budget ;
- la balance négative cumulée rapportée à la somme des budgets observés.

Seuils du premier MVP :

- moins de 5 % : aucune alerte ;
- de 5 % inclus à 15 % exclus : vigilance ;
- 15 % ou plus : alerte forte.

Le budget suivant reste inchangé. Le MVP affiche les observations réelles sans extrapoler automatiquement la dérive annuelle.

Après huit cycles terminés, un surplus cumulé peut être proposé à l’affectation vers une réserve ou un projet.

## 14. Remboursements, Santé et grosses dépenses

Un remboursement de produit corrige l’achat d’origine sans augmenter automatiquement le budget courant.

Le suivi Santé est facultatif et agrégé :

```text
reste_santé_estimé =
  dépenses_santé_plus_anciennes_que_le_délai
  - remboursements_santé_reçus
  - montants_déjà_régularisés
```

Valeurs par défaut :

- délai : 4 semaines ;
- seuil : 50 €.

L’utilisateur peut saisir des totaux de remboursement sans rapprochement individuel.

Une dépense Santé, vétérinaire, automobile ou autre grosse facture peut être :

- financée par une réserve ;
- affectée au cycle courant ;
- répartie sur 1 à 12 cycles, avec 3 proposés par défaut.

## 15. Espèces

L’utilisateur choisit :

- retrait immédiatement compté comme dépense, sans ressaisie des achats ;
- ou retrait traité comme transfert vers un portefeuille espèces, puis saisie de chaque achat.

Un changement de méthode possède une date d’effet et ne réinterprète pas le passé.

## 16. État des données

Chaque hypothèse indique sa provenance, sa méthode et sa dernière confirmation.

États globaux :

- **Configuration à compléter** : marge conseillée 10 % ;
- **Données à confirmer** : marge conseillée 5 % ;
- **Données à jour** : marge conseillée 2 %.

La marge est visible, modifiable et jamais appliquée automatiquement.

L’import et la synchronisation peuvent détecter une dérive et proposer une nouvelle valeur. Toute modification reste soumise à confirmation.

## 17. Partage et synchronisation

Chaque dépense est écrite localement immédiatement, puis synchronisée dès que possible.

L’application et le widget indiquent la fraîcheur du restant et proposent une actualisation manuelle. Un montant ancien reste visible avec avertissement.

Deux appareils hors ligne peuvent dépenser simultanément. Toutes les dépenses indépendantes sont conservées après synchronisation, même si le restant devient négatif.

Le budget suivant ne change pas automatiquement. L’utilisateur décide d’un éventuel effort ultérieur.

La synchronisation distante :

- stocke uniquement des objets chiffrés ;
- ne partage jamais un fichier SQLite unique ;
- conserve des événements et snapshots ;
- doit résoudre explicitement la révocation, les époques de clé et les conflits.

## 18. Confidentialité, accessibilité et localisation

- aucune donnée financière en clair hors de l’appareil ;
- aucune donnée métier envoyée à l’éditeur ;
- télémétrie désactivée par défaut ;
- journaux sans montants, libellés bancaires ni secrets ;
- widget limité au restant et à sa fraîcheur ;
- couleur jamais utilisée comme unique signal ;
- formats monétaires et calendaires localisés ;
- textes sources en anglais et traduction française ;
- lecteurs d’écran et tailles de texte agrandies pris en charge.

## 19. Contraintes d’architecture

- Flutter et Dart pour Android et iOS ;
- domaine indépendant de Flutter ;
- moteur de projection pur ;
- aucune formule financière dans les widgets ;
- journal local append-only dès la première mutation ;
- projections SQLite reconstruisibles ;
- base locale chiffrée ;
- dépendances verrouillées et lockfiles versionnés ;
- aucun flottant binaire pour l’argent ;
- aucun serveur métier administré par l’éditeur requis.

Les décisions acceptées sont :

- [ADR-0001 — Journal local dès le MVP](adr/0001-local-event-journal.md) ;
- [ADR-0002 — Cycles hebdomadaires en dates civiles locales](adr/0002-civil-weekly-cycles.md) ;
- [ADR-0003 — Représentation monétaire et arrondis](adr/0003-money-and-rounding.md) ;
- [ADR-0004 — Workspace Flutter/Dart et outillage monorepo](adr/0004-flutter-dart-workspace.md) ;
- [ADR-0005 — SQLite chiffrée, Drift et migrations](adr/0005-encrypted-sqlite-and-migrations.md) ;
- [ADR-0006 — Cycle de vie des clés, révocation et récupération](adr/0006-key-lifecycle-revocation-and-recovery.md).

## 20. Écrans du premier produit

- onboarding ;
- accueil et restant courant ;
- ajout rapide d’une dépense ;
- historique du cycle ;
- revenus et charges ;
- réserves, projets et grosses dépenses ;
- engagements futurs ;
- tendances ;
- méthode et hypothèses ;
- paramètres de cycle, confidentialité et synchronisation.

## 21. Jalons de livraison

### Fondation

1. accepter les décisions de domaine ;
2. décider le workspace Flutter/Dart ;
3. décider le stockage SQLite chiffré ;
4. définir la sécurité des clés et de la révocation ;
5. créer les packages minimaux.

### Moteurs locaux

1. type monétaire et tests ;
2. cycles civils et tests de changements d’heure ;
3. événements locaux et rejeu ;
4. projection sur 52 cycles ;
5. étalements, réserves et tendances.

### Application locale

1. onboarding ;
2. écran principal ;
3. saisie rapide ;
4. hypothèses et alertes ;
5. réserves et rattrapages ;
6. export local.

### Partage chiffré

1. fournisseur de synchronisation abstrait ;
2. Google Drive ;
3. invitation d’un appareil ;
4. segments et snapshots ;
5. fraîcheur et actualisation ;
6. conflits, révocation et récupération.

### Import

1. CSV ;
2. OFX ;
3. QIF ;
4. déduplication ;
5. rapprochement ;
6. propositions de révision des hypothèses.

## 22. Critères d’acceptation

Le premier produit doit permettre de :

- construire un budget à partir de toutes les entrées et sorties prévisibles ;
- expliquer chaque hypothèse et chaque calcul ;
- choisir un jour REBOOT ;
- afficher le restant courant en moins d’une seconde à chaud ;
- saisir une dépense rapidement et hors ligne ;
- ne compter aucune dépense deux fois ;
- conserver exactement les centimes ;
- traverser les changements d’heure sans déplacer les cycles ;
- étaler une dépense avec une somme exacte ;
- rejouer le journal pour reconstruire les projections ;
- conserver le budget suivant après un surplus ou dépassement ;
- distinguer un montant frais d’un montant partagé potentiellement ancien ;
- utiliser le produit sans import ni connexion bancaire.

## 23. Décisions encore ouvertes

Les décisions suivantes doivent être prises avant le code concerné :

- gestion d’état et injection de dépendances ;
- fournisseur Drive, OAuth et permissions ;
- modèle de conflits multi-appareils ;
- formats d’export et de portabilité.

## 24. Définition de réussite

REBOOT réussit si un foyer peut :

1. préparer sa trajectoire sans connexion bancaire ;
2. comprendre son budget hebdomadaire sans raisonner par mois ;
3. savoir immédiatement s’il peut encore dépenser ;
4. saisir une dépense sans effort ;
5. voir une dérive sans correction automatique punitive ;
6. protéger charges, réserves et grosses dépenses ;
7. utiliser le produit à plusieurs sans serveur métier de l’éditeur ;
8. comprendre pourquoi chaque recommandation existe ;
9. restaurer et auditer ses données ;
10. conserver la maîtrise de ses choix et de ses clés.
