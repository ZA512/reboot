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

## Décisions à traiter en priorité

1. organisation du workspace Flutter/Dart et outillage monorepo ;
2. gestion d’état et injection de dépendances ;
3. bibliothèque SQLite chiffrée et stratégie de migration ;
4. implémentation du type monétaire ;
5. représentation des cycles en dates civiles locales ;
6. primitives cryptographiques et stockage des clés.
