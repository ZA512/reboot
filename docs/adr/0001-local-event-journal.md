# ADR-0001 — Journal local dès le MVP

- Statut : Accepted
- Date : 2026-07-29
- Accepté le : 2026-07-30
- Décideur : porteur du projet REBOOT

## Contexte

Le PRD place le produit local en Phase 1 et le journal d’événements en Phase 2. Il exige néanmoins que les agrégats soient reconstruisibles depuis le journal et que le passage du mode solo au partage transforme les données locales en événements.

Construire d’abord un modèle CRUD puis ajouter l’event sourcing provoquerait une migration structurelle après la création des principales fonctions métier.

## Décision

Créer un journal d’événements append-only local dès la première mutation métier.

- L’interface lit exclusivement des projections SQLite.
- Une commande validée produit un ou plusieurs événements immuables.
- L’ajout des événements et la mise à jour des projections s’effectuent dans une transaction locale atomique.
- Chaque événement possède dès le départ un UUID, un type, une version de schéma, une date d’enregistrement, une date métier, une entité cible et une charge utile.
- Le journal attribue une position locale monotone à chaque événement. Cette position ordonne le rejeu local, sans prétendre définir à elle seule un ordre global entre appareils.
- Les futures métadonnées de transport, de foyer, d’appareil, de membre, de chiffrement et de signature sont portées par une enveloppe distincte du contenu métier immuable.
- L’activation ultérieure de la synchronisation peut envelopper un événement local existant sans réécrire son identité ni sa charge utile métier.
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
- distinction à maintenir entre événement métier, position du journal local et enveloppe de synchronisation.

## Conditions d’acceptation

- rejouer le journal produit le même état observable ;
- réappliquer un événement ne modifie pas deux fois la projection ;
- une transaction interrompue ne laisse pas un événement sans projection durable ni une projection sans événement ;
- aucune logique de synchronisation Drive n’est requise pour le MVP local.

## Liens

- PRD REBOOT 2.0 : sections 17, 19, 21 et 22.
- PRD Budget52 archivé : sections 18.4, 21.2, 30, 32.2, 34.2 et 36.
- Analyse : `docs/foundation-analysis.md`, FND-01.
