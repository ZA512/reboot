# ADR-0001 — Journal local dès le MVP

- Statut : Proposed
- Date : 2026-07-29
- Décideurs : à compléter

## Contexte

Le PRD place le produit local en Phase 1 et le journal d’événements en Phase 2. Il exige néanmoins que les agrégats soient reconstruisibles depuis le journal et que le passage du mode solo au partage transforme les données locales en événements.

Construire d’abord un modèle CRUD puis ajouter l’event sourcing provoquerait une migration structurelle après la création des principales fonctions métier.

## Décision proposée

Créer un journal d’événements append-only local dès la première mutation métier.

- L’interface lit exclusivement des projections SQLite.
- Une commande validée produit un ou plusieurs événements immuables.
- L’ajout des événements et la mise à jour des projections s’effectuent dans une transaction locale atomique.
- Chaque événement possède dès le départ un UUID, un type, une version de schéma, une date métier, une entité cible et une charge utile.
- Les champs liés au partage, à l’appareil et à la signature peuvent être absents ou locaux tant que la synchronisation n’est pas activée.
- Le rejeu complet doit reconstruire les projections.
- La Phase 2 devient une phase de durcissement : snapshots, migrations, rejeu, métadonnées multi-appareils et préparation de la synchronisation.

## Options étudiées

### Option A — CRUD puis conversion ultérieure

Plus simple pour une démonstration rapide, mais impose une migration de toutes les mutations et rend difficile la preuve qu’aucune information n’a été perdue.

### Option B — Journal local dès le départ

Ajoute une discipline initiale, mais aligne immédiatement le stockage, l’audit, les corrections et la future synchronisation.

### Option C — Double écriture indépendante

Écartée : une écriture CRUD et une écriture événementielle non atomiques créent deux sources de vérité susceptibles de diverger.

## Conséquences

### Positives

- pas de bascule architecturale avant le partage ;
- audit et corrections explicites dès le MVP ;
- projections reconstruisibles et testables ;
- idempotence préparée tôt.

### Négatives

- davantage de code d’infrastructure au démarrage ;
- versionnement des événements nécessaire dès le premier MVP ;
- règles strictes de transaction et de migration.

## Conditions d’acceptation

- rejouer le journal produit le même état observable ;
- réappliquer un événement ne modifie pas deux fois la projection ;
- une transaction interrompue ne laisse pas un événement sans projection durable ni une projection sans événement ;
- aucune logique de synchronisation Drive n’est requise pour le MVP local.

## Liens

- PRD : sections 18.4, 21.2, 30, 32.2, 34.2 et 36.
- Analyse : `docs/foundation-analysis.md`, FND-01.
