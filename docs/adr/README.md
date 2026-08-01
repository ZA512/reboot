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

## Prochaines décisions à traiter

1. codec de projection, récupération et validation Safari requis avant
   acceptation du stockage Web proposé par l’ADR-0009 ;
2. modèle de synchronisation et résolution des conflits ;
3. hébergement PWA, en-têtes de sécurité et chaîne de déploiement ;
4. format lisible d’export et portabilité au-delà de l’archive de récupération.

## ADR acceptés

- [ADR-0001 — Journal local dès le MVP](0001-local-event-journal.md)
- [ADR-0002 — Cycles hebdomadaires en dates civiles locales](0002-civil-weekly-cycles.md)
- [ADR-0003 — Représentation monétaire et arrondis](0003-money-and-rounding.md)
- [ADR-0004 — Workspace Flutter/Dart et outillage monorepo](0004-flutter-dart-workspace.md)
- [ADR-0005 — SQLite chiffrée, Drift et migrations](0005-encrypted-sqlite-and-migrations.md)
- [ADR-0006 — Cycle de vie des clés, révocation et récupération](0006-key-lifecycle-revocation-and-recovery.md)
- [ADR-0007 — État Flutter et racine de composition](0007-riverpod-state-and-composition.md)
- [ADR-0008 — Distribution Android et Web/PWA](0008-android-and-web-pwa-distribution.md)
- [ADR-0011 — Archive de récupération portable Android et Web](0011-portable-recovery-archive.md)

Les trois premiers ADR ont été acceptés explicitement le 2026-07-30.
L’ADR-0004 a été accepté le 2026-07-31 dans le cadre de la délégation des
décisions techniques au responsable de l’implémentation.
L’ADR-0005 a été décidé par le responsable de l’implémentation le 2026-07-31.
L’ADR-0006 a été décidé par le responsable de l’implémentation le 2026-07-31.
L’ADR-0007 a été décidé par le responsable de l’implémentation le 2026-07-31.
L’ADR-0008 a été accepté le 2026-08-01 à la demande du porteur du projet ; ses
choix techniques ont été précisés par le responsable de l’implémentation.
L’ADR-0011 a été décidé par le responsable de l’implémentation le 2026-08-02
dans le cadre de la délégation des décisions techniques et de sécurité.

## ADR remplacés

- [ADR-0010 — Export local chiffré et restauration](0010-encrypted-local-recovery-export.md),
  remplacé par l’ADR-0011 pour les nouveaux exports. Les archives historiques
  `RB1` restent prises en charge.

## ADR proposés

- [ADR-0009 — Journal Web chiffré et garde locale de clé](0009-browser-encrypted-journal.md)
