# Prototype de stockage Web chiffré

- Statut : en cours
- Début : 2026-08-01
- Portée : preuve technique uniquement, aucune donnée financière réelle

## Étape 0 — Composition et précision numérique

Le shell Flutter Web est présent et la composition native est isolée derrière
un import conditionnel. Android continue d’ouvrir exclusivement le journal
SQLite chiffré et sa clé protégée par Android Keystore.

Le shell Web ne propose aucune saisie et n’ouvre aucun stockage de repli. Il
explique que la persistance chiffrée, la garde des clés et la récupération sont
encore en validation.

Le premier build JavaScript a révélé un prérequis de domaine : `int` est signé
64 bits sur la VM Dart, mais ne conserve que 53 bits de précision entière dans
la représentation JavaScript. REBOOT ne réduit pas silencieusement sa plage
monétaire et ne réserve pas son exactitude au seul WebAssembly : Flutter doit
conserver une sortie JavaScript pour Safari iPhone.

Ce prérequis est maintenant levé dans le cœur métier. `Money` et
`LocalJournalPosition` conservent leur valeur exacte dans un `BigInt`, avec les
mêmes bornes signées 64 bits sur Android et sur le Web. Les montants des
événements sont écrits sous forme de chaînes décimales canoniques ; le lecteur
accepte aussi les anciens nombres JSON dans leur intervalle exact commun. Un
ancien nombre hors de l’intervalle sûr JavaScript est refusé et doit être migré
nativement, sans arrondi. Un exécutable de contrôle est compilé en JavaScript
puis exécuté en CI au-delà de la limite de précision de `Number` et aux bornes
signées 64 bits.

## Hypothèses à éprouver ensuite

Deux couches restent séparées :

1. un journal append-only dont chaque enveloppe d’événement est chiffrée et
   authentifiée avant persistance ;
2. une garde de clé Web indépendante du stockage des enveloppes.

Le prototype comparera :

- IndexedDB direct, avec une enveloppe AES-256-GCM par événement ;
- Drift/SQLite WebAssembly, uniquement s’il apporte un gain mesurable sans
  laisser le fichier ou les pages SQLite en clair.

Une clé non extractible Web Crypto conservée dans IndexedDB peut protéger la
clé de données locale contre une simple lecture du stockage. Elle ne protège
pas d’un JavaScript hostile exécuté sur la même origine : CSP, dépendances,
déploiements atomiques et absence de scripts tiers restent des contrôles
obligatoires.

La récupération devra utiliser une enveloppe distincte de la clé de données.
Le stockage navigateur peut être effacé à tout moment et ne sera jamais
présenté comme l’unique sauvegarde fiable.

## Critères avant activation des saisies Web

- build JavaScript compatible Safari iPhone et build WebAssembly compatibles ;
- exactitude des centimes et positions aux deux bornes signées 64 bits ;
- aucun payload, libellé ou montant en clair dans IndexedDB, OPFS ou caches ;
- corruption, duplication, ordre et reprise transactionnelle testés ;
- perte de clé et effacement du stockage détectés sans réinitialisation
  silencieuse ;
- scénario de récupération documenté et testé ;
- comportement du stockage détecté et annoncé, sans repli mémoire silencieux ;
- benchmark sur 300 000 événements ;
- validation Safari sur un iPhone réel.

## Sources techniques

- [Représentation des nombres Dart](https://dart.dev/resources/language/number-representation)
- [Flutter WebAssembly et repli JavaScript](https://docs.flutter.dev/platform-integration/web/wasm)
- [Drift sur le Web](https://drift.simonbinder.eu/platforms/web/)
- [Web Cryptography Level 2](https://www.w3.org/TR/webcrypto-2/)
