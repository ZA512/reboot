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

## Étape 1 — Enveloppes chiffrées et IndexedDB direct

Deux couches restent séparées :

1. un journal append-only dont chaque enveloppe d’événement est chiffrée et
   authentifiée avant persistance ;
2. une garde de clé Web indépendante du stockage des enveloppes.

Le premier prototype retient provisoirement IndexedDB direct :

- clé AES-256-GCM générée par Web Crypto avec `extractable = false` ;
- `CryptoKey` cloné directement dans IndexedDB, jamais exporté en octets ;
- nonce aléatoire de 96 bits et tag de 128 bits par événement ;
- en-tête de routage authentifié comme données associées ;
- événement métier intégralement à l’intérieur du ciphertext ;
- transaction atomique entre enveloppe, UUID et position locale ;
- marqueur non sensible séparé pour détecter une suppression isolée de la
  base.

Les tests Chrome prouvent la réouverture, l’ordre, l’idempotence, le conflit
d’UUID, l’attribution de positions uniques entre deux connexions concurrentes,
le rollback intégral d’une transaction en échec, le refus d’export de clé, la
détection d’une altération du ciphertext ou de l’en-tête, la perte de clé et
l’effacement isolé d’IndexedDB. La lecture contrôle aussi, dans un même instantané
transactionnel, la cohérence entre la position finale, toutes les enveloppes et
l’index complet des UUID. La clé rechargée doit être une clé secrète AES-GCM de
256 bits, non extractible, dont les seuls usages sont le chiffrement et le
déchiffrement. Les valeurs de test sont exclusivement synthétiques. Le prototype
n’implémente pas encore le port applicatif et le shell Web reste bloqué.

La politique de durabilité n’est plus implicite : le prototype interroge le
quota de l’origine, vérifie sa cohérence et peut demander au navigateur le mode
persistant. Un refus reste un résultat valide mais classé `best effort`; il devra
être annoncé à l’utilisateur et interdit de présenter la copie locale comme une
sauvegarde. Une API absente ou incohérente échoue fermée.

Le [benchmark sur 300 000 événements](web-storage-benchmark.md) valide une
écriture p95 à 5,9 ms et la capacité du journal direct. Le rejeu authentifié
complet varie de 19,5 à 34,0 secondes sur la machine de référence. Le schéma v2
ajoute donc un snapshot de projection chiffré, versionné, remplaçable et ancré
sur l’empreinte d’une enveloppe exacte du journal. Sa corruption le supprime sans
toucher au journal. La migration v1 vers v2 conserve la clé et les événements.

Avec un snapshot synthétique de 262 228 octets à la position 299 900, la
restauration et le rejeu authentifié des 100 événements suivants prennent 69 ms.
Le mécanisme satisfait la cible desktop ; le vrai codec des projections REBOOT
et son intégration à `LocalEventJournal` restent à implémenter avant activation.

Drift/SQLite WebAssembly est différé : il ne supprimerait pas le besoin du
chiffrement applicatif et ajouterait des pages, caches et migrations à auditer.
Il pourra être réévalué seulement si le benchmark montre que le journal direct
ne satisfait pas les performances.

Une clé non extractible Web Crypto conservée dans IndexedDB peut protéger la
clé de données locale contre une simple lecture du stockage. Elle ne protège
pas d’un JavaScript hostile exécuté sur la même origine : CSP, dépendances,
déploiements atomiques et absence de scripts tiers restent des contrôles
obligatoires.

La récupération devra utiliser une enveloppe distincte de la clé de données.
Le stockage navigateur peut être effacé à tout moment et ne sera jamais
présenté comme l’unique sauvegarde fiable.

La proposition complète et ses limites sont consignées dans
[l’ADR-0009](adr/0009-browser-encrypted-journal.md), encore au statut
`Proposed`.

## Critères avant activation des saisies Web

- build JavaScript compatible Safari iPhone et build WebAssembly compatibles ;
- exactitude des centimes et positions aux deux bornes signées 64 bits ;
- aucun payload, libellé ou montant en clair dans IndexedDB, OPFS ou caches ;
- corruption, duplication, ordre et reprise transactionnelle testés ;
- perte de clé et effacement isolé du stockage détectés sans réinitialisation
  silencieuse ;
- scénario de récupération documenté et testé ;
- codec versionné des projections métier branché sur le snapshot chiffré ;
- comportement du stockage détecté et annoncé, sans repli mémoire silencieux ;
- benchmark sur 300 000 événements effectué sur ordinateur, puis confirmé sur
  Safari iPhone réel ;
- validation Safari sur un iPhone réel.

## Sources techniques

- [Représentation des nombres Dart](https://dart.dev/resources/language/number-representation)
- [Flutter WebAssembly et repli JavaScript](https://docs.flutter.dev/platform-integration/web/wasm)
- [Drift sur le Web](https://drift.simonbinder.eu/platforms/web/)
- [Web Cryptography Level 2](https://www.w3.org/TR/webcrypto-2/)
- [Package Dart `web`](https://pub.dev/packages/web)
