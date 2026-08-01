# Sécurité du projet

Le PRD constitue la référence normative. Ce dossier accueille le modèle de
menaces, les choix cryptographiques, les procédures de revue et les preuves de
tests de sécurité.

## Documents

- [Modèle de menaces initial](threat-model.md)
- [ADR-0005 — SQLite chiffrée, Drift et migrations](../adr/0005-encrypted-sqlite-and-migrations.md)
- [ADR-0006 — Cycle de vie des clés, révocation et récupération](../adr/0006-key-lifecycle-revocation-and-recovery.md)
- [ADR-0009 — Journal Web chiffré et garde locale de clé](../adr/0009-browser-encrypted-journal.md)
- [Benchmark du journal Web chiffré](../web-storage-benchmark.md)

## Invariants initiaux

- aucune donnée financière envoyée à l’éditeur ;
- aucune donnée financière en clair hors de l’appareil ;
- aucun secret, jeton OAuth, clé ou base locale dans Git ;
- montants stockés en centimes entiers signés 64 bits ;
- chiffrement local et synchronisation chiffrée de bout en bout ;
- télémétrie désactivée par défaut et dépourvue de données métier ;
- journaux nettoyés des montants, libellés, identifiants bancaires et secrets ;
- dépendances verrouillées et lockfiles versionnés.

## Avant toute implémentation sensible

Les choix de chiffrement, de stockage de clés, de révocation, de récupération et de synchronisation doivent être documentés dans des ADR puis couverts par des tests dédiés.
