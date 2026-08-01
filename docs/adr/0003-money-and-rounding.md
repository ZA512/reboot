# ADR-0003 — Représentation monétaire et arrondis

- Statut : Accepted
- Date : 2026-07-29
- Accepté le : 2026-07-30
- Amendements : 2026-07-30, 2026-07-31, 2026-08-01
- Décideur : porteur du projet REBOOT

## Contexte

Le PRD interdit les flottants binaires et impose des centimes signés 64 bits. Il ne définit pas complètement les conventions de signe, les opérations entre devises, les restes de division ni l’affichage d’une capacité discrétionnaire négative.

Une simple division arrondie à chaque cycle peut perdre des centimes. Exemple : 90 € répartis sur 26 cycles ne peuvent pas être représentés par 26 contributions identiques au centime tout en conservant exactement 90 €.

## Décision

### Type monétaire

Le domaine utilise un type valeur `Money` composé de :

- `exactMinorUnits` : entier exact borné à l’intervalle signé 64 bits ;
- `currency` : code ISO 4217 validé.

La valeur exacte repose sur `BigInt` afin de conserver les 64 bits sur la VM
Dart, en JavaScript et en WebAssembly. Dans le journal portable, les unités
mineures sont sérialisées sous forme de chaînes décimales canoniques. Le
lecteur accepte aussi les anciens nombres JSON, uniquement pour préserver les
journaux créés avant cet amendement lorsque leur valeur appartient à
l’intervalle exact commun à JSON/JavaScript (`±(2^53 - 1)`). Un ancien nombre
hors de cet intervalle est refusé et doit être migré nativement vers une chaîne,
jamais arrondi. Aucun calcul métier, stockage ou affichage ne convertit une
valeur monétaire en `double`.

Les opérations arithmétiques entre devises différentes échouent explicitement. Le type ne suppose pas que toutes les devises possèdent deux décimales : leur nombre d’unités mineures dépend de la devise.

Le premier MVP cible la France et l’euro :

- un foyer et toutes ses entités financières utilisent `EUR` ;
- aucun compte, revenu, charge, réserve ou projet dans une autre devise n’entre dans les calculs ;
- modifier la devise d’un foyer contenant des données exige une migration explicite et n’est pas proposé dans le MVP ;
- aucune conversion implicite n’est autorisée.

L’interface est disponible en anglais et en français. La langue d’affichage, le format des nombres et le format des dates ne modifient jamais la devise ni les unités stockées.

### Conventions de signe

- les montants saisis dans les entités métier sont non négatifs ;
- la nature de l’opération est portée par un type explicite : revenu, dépense, remboursement, transfert, contribution ;
- les moteurs de projection peuvent utiliser des deltas signés en interne ;
- un remboursement reste lié à la dépense qu’il réduit et ne devient pas un revenu.

### Division et répartition

Toute répartition utilise quotient et reste :

1. calculer le quotient entier ;
2. affecter ce quotient aux `N - 1` premières échéances ;
3. calculer la dernière échéance comme le montant d’origine moins la somme des échéances précédentes ;
4. garantir que la somme des allocations est strictement égale au montant d’origine.

La dernière échéance absorbe ainsi tous les centimes résiduels. Aucun centime ne disparaît.

### Recommandation hebdomadaire

- une capacité positive est divisée en centimes puis arrondie vers le bas à l’euro entier pour le MVP ;
- pour `EUR`, le pas d’arrondi du MVP est fixé à 100 unités mineures ;
- les centimes écartés de la recommandation restent dans la trajectoire annuelle et constituent une petite marge ;
- une capacité négative reste un déficit explicite ;
- l’interface ne propose jamais un budget de dépense négatif : elle affiche zéro disponible et l’effort minimal ou le déficit séparément ;
- un budget choisi par l’utilisateur est toujours supérieur ou égal à zéro.

### Robustesse

- toute addition, soustraction ou multiplication vérifie les dépassements ;
- le formatage est séparé du calcul ;
- le formatage localisé travaille directement depuis l’entier exact ;
- les comparaisons exigent la même devise.

## Options étudiées

### Option A — `double`

Écartée explicitement par le PRD et impropre aux égalités comptables.

### Option B — bibliothèque décimale générale

Utile pour des taux, mais insuffisante seule pour imposer devise, signes et répartition exacte.

### Option C — entier en unités mineures avec type valeur

Recommandée : modèle simple, exact et facile à tester par propriétés.

## Conséquences

### Positives

- calculs déterministes ;
- absence de centimes perdus ;
- erreurs de devise visibles ;
- règles de remboursement et transfert explicites.

### Négatives

- nécessité de gérer le reste pour chaque répartition ;
- absence de multi-devise réelle dans le MVP ;
- besoin d’un type distinct pour les taux ou pourcentages.
- besoin futur de métadonnées ISO 4217 fiables avant l’ouverture à d’autres devises.

## Tests minimaux

- répartition exacte de 90 € sur 26 cycles ;
- répartition de 28 € sur trois échéances : 9,33 €, 9,33 € et 9,34 € ;
- recommandation brute de 233,82 € arrondie à 233 € ;
- capacité négative ;
- zéro ;
- limites de l’entier 64 bits ;
- compilation et exécution JavaScript au-delà de `2^53` ;
- sérialisation décimale canonique et lecture de l’ancien format JSON entier ;
- addition de devises différentes refusée ;
- données non libellées en EUR refusées dans un foyer MVP ;
- remboursement partiel et total ;
- propriété : somme des parts égale au montant source.

## Liens

- PRD REBOOT 2.0 : sections 5, 6, 12, 14, 16 et 22.
- Méthode REBOOT : sections « Construction du budget », « Saisie rapide » et « Rattrapage d’une dépense importante ».
- PRD Budget52 archivé : sections 8, 9.1, 11.2, 12.4, 14.5, 32.1 et 34.
- Analyse : `docs/foundation-analysis.md`, FND-03.
