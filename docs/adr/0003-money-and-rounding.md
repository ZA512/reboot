# ADR-0003 — Représentation monétaire et arrondis

- Statut : Proposed
- Date : 2026-07-29
- Décideurs : à compléter

## Contexte

Le PRD interdit les flottants binaires et impose des centimes signés 64 bits. Il ne définit pas complètement les conventions de signe, les opérations entre devises, les restes de division ni l’affichage d’une capacité discrétionnaire négative.

Une simple division arrondie à chaque cycle peut perdre des centimes. Exemple : 90 € répartis sur 26 cycles ne peuvent pas être représentés par 26 contributions identiques au centime tout en conservant exactement 90 €.

## Décision proposée

### Type monétaire

Le domaine utilise un type valeur `Money` composé de :

- `minorUnits` : entier signé 64 bits ;
- `currency` : code ISO 4217 validé.

Les opérations arithmétiques entre devises différentes échouent explicitement. Le MVP calcule uniquement dans la devise du foyer ; aucune conversion implicite n’est autorisée.

### Conventions de signe

- les montants saisis dans les entités métier sont non négatifs ;
- la nature de l’opération est portée par un type explicite : revenu, dépense, remboursement, transfert, contribution ;
- les moteurs de projection peuvent utiliser des deltas signés en interne ;
- un remboursement reste lié à la dépense qu’il réduit et ne devient pas un revenu.

### Division et répartition

Toute répartition utilise quotient et reste :

1. calculer le quotient entier ;
2. distribuer les unités mineures restantes de manière déterministe sur les premiers cycles ;
3. garantir que la somme des allocations est strictement égale au montant d’origine.

Aucun centime résiduel ne disparaît.

### Recommandation hebdomadaire

- une capacité positive est divisée en centimes puis arrondie vers le bas au multiple configuré ;
- une capacité négative reste un déficit explicite ;
- l’interface ne propose jamais un budget de dépense négatif : elle affiche zéro disponible et l’effort minimal ou le déficit séparément ;
- un budget choisi par l’utilisateur est toujours supérieur ou égal à zéro.

### Robustesse

- toute addition, soustraction ou multiplication vérifie les dépassements ;
- le formatage est séparé du calcul ;
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

## Tests minimaux

- répartition exacte de 90 € sur 26 cycles ;
- montant non divisible par 5 € ;
- capacité négative ;
- zéro ;
- limites de l’entier 64 bits ;
- addition de devises différentes refusée ;
- remboursement partiel et total ;
- propriété : somme des parts égale au montant source.

## Liens

- PRD : sections 8, 9.1, 11.2, 12.4, 14.5, 32.1 et 34.
- Analyse : `docs/foundation-analysis.md`, FND-03.
