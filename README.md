# REBOOT

**Regain Expenses, Back On Our Track**

REBOOT est une application mobile de pilotage du reste à vivre hebdomadaire. Elle est conçue pour fonctionner en local, hors ligne, avec un calcul soutenable sur 52 semaines et une synchronisation chiffrée facultative.

Le projet est actuellement en **Phase 0 — Fondation**.

## Documentation

- [PRD de référence](docs/PRD.md)
- [Décisions d’architecture](docs/adr/README.md)
- [Principes de sécurité](docs/security/README.md)

## Architecture cible

Le client sera développé en Flutter/Dart pour Android et iOS. La logique financière restera indépendante de l’interface et manipulera exclusivement des montants entiers en centimes.

L’organisation détaillée du dépôt et l’ordre d’implémentation sont définis dans le PRD. Les packages applicatifs seront créés après validation des premières décisions d’architecture.

## Nom du projet

**REBOOT** est le nom du projet. Le PRD fourni utilise encore **Budget52** comme nom de travail interne ; cette divergence sera résolue explicitement lors de la prochaine révision documentaire.

## État du chantier

- [x] Dépôt public initialisé
- [x] PRD archivé comme source de vérité
- [x] Garde-fous Git et sécurité posés
- [x] Analyse initiale des contradictions et questions ouvertes
- [x] Trois ADR de fondation acceptés
- [ ] Création du workspace Flutter/Dart
- [ ] Premiers types métier et tests de référence

## Licence

Aucune licence open source n’est encore définie. La visibilité publique du dépôt n’accorde pas, à elle seule, de droit de réutilisation.
