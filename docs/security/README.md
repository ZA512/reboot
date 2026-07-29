# Sécurité du projet

Le PRD constitue la référence normative. Ce dossier accueillera le modèle de menaces, les choix cryptographiques, les procédures de revue et les preuves de tests de sécurité.

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
