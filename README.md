# REBOOT

**Regain Expenses, Back On Our Track**

REBOOT est une application mobile de pilotage du reste à vivre hebdomadaire. Elle est conçue pour fonctionner en local, hors ligne, avec un calcul soutenable sur 52 semaines et une synchronisation chiffrée facultative.

Le projet est actuellement en **Phase 0 — Fondation**.

## Documentation

- [PRD REBOOT 2.0](docs/PRD.md)
- [Méthode REBOOT](docs/reboot-method.md)
- [Décisions d’architecture](docs/adr/README.md)
- [Principes de sécurité](docs/security/README.md)
- [Documents historiques](docs/archive/README.md)

## Architecture cible

Le client sera développé en Flutter/Dart pour Android et iOS. La logique financière restera indépendante de l’interface et manipulera exclusivement des montants entiers en centimes.

L’organisation détaillée du dépôt et l’ordre d’implémentation sont définis dans le PRD. Les packages applicatifs seront créés après validation des premières décisions d’architecture.

## Nom du projet

**REBOOT** est le nom officiel du projet et du produit.

Le nom de travail **Budget52** est conservé uniquement dans le PRD historique archivé.

## État du chantier

- [x] Dépôt public initialisé
- [x] PRD Budget52 original archivé sans modification
- [x] PRD REBOOT 2.0 publié comme source de vérité
- [x] Garde-fous Git et sécurité posés
- [x] Analyse initiale des contradictions et questions ouvertes
- [x] Trois ADR de fondation acceptés
- [x] Méthode REBOOT formalisée
- [ ] Création du workspace Flutter/Dart
- [ ] Premiers types métier et tests de référence

## Licence

Aucune licence open source n’est encore définie. La visibilité publique du dépôt n’accorde pas, à elle seule, de droit de réutilisation.
