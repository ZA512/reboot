# REBOOT

**Regain Expenses, Back On Our Track**

REBOOT est une application mobile de pilotage du reste à vivre hebdomadaire. Elle est conçue pour fonctionner en local, hors ligne, avec un calcul soutenable sur 52 semaines et une synchronisation chiffrée facultative.

Le projet est actuellement en **Phase 0 — Fondation**.

## Documentation

- [PRD REBOOT 2.0](docs/PRD.md)
- [Méthode REBOOT](docs/reboot-method.md)
- [Décisions d’architecture](docs/adr/README.md)
- [Principes de sécurité](docs/security/README.md)
- [Environnement de développement](docs/development.md)
- [Documents historiques](docs/archive/README.md)

## Architecture cible

Le client sera développé en Flutter/Dart pour Android et iOS. La logique financière restera indépendante de l’interface et manipulera exclusivement des montants entiers en centimes.

L’organisation détaillée du dépôt et l’ordre d’implémentation sont définis dans
le PRD. Le workspace sépare le domaine, les projections, l’orchestration
applicative et le client mobile afin que les calculs métier restent testables
sans Flutter.

## Nom du projet

**REBOOT** est le nom officiel du projet et du produit.

Le nom de travail **Budget52** est conservé uniquement dans le PRD historique archivé.

## État du chantier

- [x] Dépôt public initialisé
- [x] PRD Budget52 original archivé sans modification
- [x] PRD REBOOT 2.0 publié comme source de vérité
- [x] Garde-fous Git et sécurité posés
- [x] Analyse initiale des contradictions et questions ouvertes
- [x] Six ADR de fondation acceptés
- [x] Méthode REBOOT formalisée
- [x] Création du workspace Flutter/Dart
- [x] Type monétaire et tests de référence
- [x] Moteur de cycles civils et tests de changements d’heure
- [x] Premiers événements métier locaux et rejeu pur
- [x] Allocations et projection hebdomadaire glissante sur 52 cycles
- [x] Annualisation des revenus, charges, réserves et objectifs
- [x] Événements et projection de configuration du foyer
- [ ] Journal local SQLite chiffré et orchestration applicative

## Licence

Aucune licence open source n’est encore définie. La visibilité publique du dépôt n’accorde pas, à elle seule, de droit de réutilisation.
