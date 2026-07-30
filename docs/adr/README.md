# Architecture Decision Records

Ce dossier contient les décisions d’architecture de REBOOT.

Le PRD est normatif. Un ADR documente un choix technique nécessaire à son implémentation ; il ne doit pas modifier silencieusement une règle métier. Toute contradiction ou formule manquante doit être rendue explicite avant développement.

## Convention

Nom de fichier : `NNNN-titre-court.md`

Statuts autorisés :

- Proposed
- Accepted
- Superseded
- Rejected

## Modèle

```markdown
# ADR-NNNN — Titre

- Statut : Proposed
- Date : YYYY-MM-DD
- Décideurs :

## Contexte

## Décision

## Options étudiées

## Conséquences

## Liens

- PRD :
- ADR liés :
```

## ADR proposés

- [ADR-0004 — Workspace Flutter/Dart et outillage monorepo](0004-flutter-dart-workspace.md)

Cette proposition doit être acceptée, amendée ou rejetée explicitement avant la
création du workspace.

## Prochaines décisions à traiter

1. bibliothèque SQLite chiffrée et stratégie de migration ;
2. gestion d’état et injection de dépendances ;
3. primitives cryptographiques, stockage des clés et révocation ;
4. modèle de synchronisation et résolution des conflits.

## ADR acceptés

- [ADR-0001 — Journal local dès le MVP](0001-local-event-journal.md)
- [ADR-0002 — Cycles hebdomadaires en dates civiles locales](0002-civil-weekly-cycles.md)
- [ADR-0003 — Représentation monétaire et arrondis](0003-money-and-rounding.md)

Ces trois ADR ont été acceptés explicitement le 2026-07-30.
