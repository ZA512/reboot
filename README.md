# REBOOT

**Regain Expenses, Back On Our Track**

REBOOT est une application mobile de pilotage du reste à vivre hebdomadaire. Elle est conçue pour fonctionner en local, hors ligne, avec un calcul soutenable sur 52 semaines et une synchronisation chiffrée facultative.

Le projet est actuellement en **Phase 1 — Application locale**.

## Documentation

- [PRD REBOOT 2.1](docs/PRD.md)
- [Méthode REBOOT](docs/reboot-method.md)
- [Décisions d’architecture](docs/adr/README.md)
- [Principes de sécurité](docs/security/README.md)
- [Environnement de développement](docs/development.md)
- [Documents historiques](docs/archive/README.md)

## Architecture cible

Le client est développé en Flutter/Dart pour Android natif et Web/PWA. L’accès
iPhone initial passe par une PWA installable depuis Safari ; une application
iOS native est hors du premier périmètre. La logique financière reste
indépendante de l’interface et manipule exclusivement des montants entiers en
centimes.

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
- [x] PRD REBOOT 2.1 publié comme source de vérité
- [x] Garde-fous Git et sécurité posés
- [x] Analyse initiale des contradictions et questions ouvertes
- [x] Huit ADR d’architecture acceptés
- [x] Méthode REBOOT formalisée
- [x] Création du workspace Flutter/Dart
- [x] Type monétaire et tests de référence
- [x] Moteur de cycles civils et tests de changements d’heure
- [x] Premiers événements métier locaux et rejeu pur
- [x] Allocations et projection hebdomadaire glissante sur 52 cycles
- [x] Annualisation des revenus, charges, réserves et objectifs
- [x] Événements et projection de configuration du foyer
- [x] Journal local SQLite chiffré, append-only et rejouable
- [x] Cas d’usage locaux initiaux et orchestration applicative
- [x] Onboarding Flutter : foyer, jour REBOOT et premier cycle
- [x] Configuration manuelle des revenus et charges
- [x] Choix de trajectoire et premier budget hebdomadaire
- [x] Tableau de bord du restant hebdomadaire en direct
- [x] Saisie rapide, étalement exact sur 1 à 12 semaines et suppression d’erreur
- [x] Tendances glissantes sur 4, 8, 16, 32 et 52 semaines et alertes graduées
- [x] Réserves réelles ou virtuelles et financement des grosses dépenses
- [x] Remboursements et suivi Santé facultatif
- [x] Raccourcis de saisie, qualification facultative et répartition des dépenses
- [x] Modification future des revenus et charges sans réécriture de la semaine en cours
- [x] Révision future de la trajectoire, des objectifs et du coussin annuel
- [x] Changement futur du jour REBOOT avec cycle de transition explicite
- [x] Primes déjà reçues lissées jusqu’à leur prochaine confirmation
- [x] Widget Android confidentiel du restant hebdomadaire
- [x] Stratégie de distribution Android et Web/PWA acceptée
- [ ] Prototype de stockage Web chiffré et garde des clés
- [ ] PWA installable et utilisable hors ligne sur iPhone

## Licence

Aucune licence open source n’est encore définie. La visibilité publique du dépôt n’accorde pas, à elle seule, de droit de réutilisation.
