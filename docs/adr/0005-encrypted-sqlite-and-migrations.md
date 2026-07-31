# ADR-0005 — SQLite chiffrée, Drift et migrations

> Note : depuis l’ADR-0008, cette pile de stockage native s’applique à Android.
> Le stockage Web/PWA requiert un adaptateur et une décision de sécurité dédiés.

- Statut : Accepted
- Date : 2026-07-31
- Accepté le : 2026-07-31
- Décideur : responsable de l’implémentation REBOOT

## Contexte

REBOOT stocke localement des données financières sensibles. Le PRD exige :

- une base locale chiffrée ;
- un journal d’événements append-only ;
- des projections SQLite entièrement reconstruisibles ;
- l’écriture atomique d’un événement et de ses projections ;
- une utilisation hors ligne ;
- aucun partage direct d’un fichier SQLite entre appareils ;
- des migrations sans perte des données de l’utilisateur.

La bibliothèque choisie doit aussi conserver le domaine et le moteur de
projection indépendants de Flutter, exécuter les accès bloquants hors de
l’isolate de l’interface et rendre les requêtes et migrations vérifiables.

Au moment de cette décision, les versions stables examinées sont notamment
Drift 2.34.3, `sqlite3` 3.5.0 et `drift_dev` 2.34.5. Les numéros exacts installés
seront ceux des dernières versions stables mutuellement compatibles au moment
du bootstrap, puis seront verrouillés par le lockfile racine.

## Décision

### Pile de persistance

Utiliser :

- Drift pour le schéma, les requêtes typées, les transactions et les
  migrations ;
- `sqlite3` version 3 ou ultérieure pour l’accès natif à SQLite par FFI et les
  hooks de compilation Dart ;
- SQLite3MultipleCiphers, sélectionné par le hook `sqlite3` avec
  `source: sqlite3mc`, comme moteur SQLite chiffré ;
- le schéma de chiffrement `chacha20` de SQLite3MultipleCiphers, fondé sur
  ChaCha20 avec authentification Poly1305, sélectionné explicitement avant
  l’application de la clé.

Ne pas utiliser :

- `sqlite3_flutter_libs`, devenu obsolète avec `sqlite3` 3.x ;
- `sqlcipher_flutter_libs`, qui n’est plus nécessaire avec les hooks natifs ;
- `sqflite_sqlcipher`, qui couple le stockage à Flutter et impose un fork natif
  supplémentaire ;
- le SQLite fourni par Android ou iOS, dont la version et les options de
  compilation ne sont pas homogènes.

Le binaire SQLite3MultipleCiphers est fourni par le mécanisme de hooks de
`sqlite3`. Les artefacts publiés sont associés à des empreintes SHA-256
vérifiées par le package.

### Frontière de package

Créer `packages/reboot_storage` lorsque débute l’implémentation du journal.

Ce package :

- est un package Dart, sans import Flutter ;
- implémente les ports de persistance définis par `reboot_application` ;
- dépend de `reboot_application`, `reboot_domain`, Drift et `sqlite3` ;
- reçoit le chemin de la base et la clé par injection ;
- ne lit pas directement le Keychain, le Keystore ou les préférences de
  l’application ;
- n’expose aucun type Drift ou SQLite au domaine et à la couche application.

`reboot_app` reste la racine de composition et fournit les adaptateurs de chemin
et de clé. Le choix de l’implémentation du stockage sécurisé de cette clé relève
de l’ADR de sécurité suivant.

### Fichier et modèle d’écriture

- Utiliser un fichier SQLite chiffré par profil local.
- Conserver le journal d’événements et les projections dans ce même fichier.
- Utiliser une seule connexion d’écriture, exécutée dans un isolate de fond.
- Enregistrer les événements et mettre à jour leurs projections dans une seule
  transaction Drift.
- Valider la transaction uniquement si toutes les contraintes et projections
  ont réussi.
- Conserver une contrainte d’unicité sur l’UUID de chaque événement et sur sa
  position locale monotone.
- Protéger la table du journal contre `UPDATE` et `DELETE` par des triggers
  SQLite qui échouent explicitement.
- Versionner séparément le schéma SQLite et la charge utile de chaque type
  d’événement.

Les corrections métier produisent de nouveaux événements ; elles ne modifient
jamais les événements existants.

### Ouverture chiffrée et échec fermé

L’ouverture respecte cet ordre :

1. obtenir une clé aléatoire de 256 bits depuis le fournisseur de clé ;
2. vérifier à l’exécution que le moteur expose les primitives
   SQLite3MultipleCiphers ;
3. sélectionner explicitement `PRAGMA cipher = 'chacha20'` ;
4. appliquer la clé binaire au moyen de la syntaxe de clé brute prévue par le
   moteur ;
5. exécuter une lecture de `sqlite_master` pour prouver que la clé ouvre
   réellement le fichier ;
6. appliquer les réglages SQLite ;
7. exécuter les éventuelles migrations ;
8. rendre la connexion disponible à l’application.

Ces vérifications sont actives en version de production et ne reposent pas sur
un `assert`. Si le moteur chiffré manque, si la clé est absente ou incorrecte,
ou si l’intégrité ne peut pas être établie, l’ouverture échoue. REBOOT ne crée
jamais silencieusement une nouvelle base et n’essaie jamais une ouverture sans
clé à la même adresse.

La clé :

- n’est jamais codée en dur ;
- n’est jamais stockée dans SQLite ;
- n’est jamais écrite dans les journaux, traces, rapports d’erreur ou noms de
  fichier ;
- est fournie sous forme binaire et sa représentation temporaire est conservée
  le moins longtemps possible ;
- ne peut pas être remplacée par le code appelant sans une opération explicite
  de rotation ou de récupération.

### Réglages SQLite

Appliquer et vérifier au minimum :

- `PRAGMA foreign_keys = ON` ;
- `PRAGMA journal_mode = WAL` ;
- `PRAGMA synchronous = FULL` ;
- `PRAGMA temp_store = MEMORY` ;
- un délai d’attente borné pour les verrous concurrents ;
- les contrôles de cohérence appropriés après une migration.

Le mode WAL est autorisé car SQLite3MultipleCiphers chiffre également les pages
du journal. Aucun fichier `-wal`, `-shm`, copie de migration ou sauvegarde
temporaire ne doit sortir du répertoire privé de l’application.

Les requêtes SQL détaillées et leurs paramètres restent désactivés dans les
journaux de production. Les erreurs remontent des codes et un contexte
technique expurgé des montants, libellés, événements et clés.

### Migrations

- La première version publiée commence au schéma SQLite 1.
- Chaque changement de schéma incrémente exactement cette version.
- Utiliser les migrations guidées et pas-à-pas de `drift_dev`.
- Versionner tous les instantanés de schéma générés dans `drift_schemas/`.
- Versionner le code de migration et ses tests.
- Interdire les migrations destructrices implicites et la remise à zéro de la
  base en production.
- Refuser proprement l’ouverture d’une base créée par une version applicative
  plus récente ; les rétrogradations ne sont pas prises en charge.
- Réserver les copies temporaires de base aux migrations qui ne peuvent pas
  être exécutées atomiquement en place. Ces copies sont elles aussi chiffrées
  et supprimées après validation.

Pour chaque nouvelle version, les tests couvrent :

- la création d’une base vide au dernier schéma ;
- la migration depuis chacune des versions précédemment publiées ;
- la conservation de données représentatives et des centimes exacts ;
- les clés étrangères, index, triggers et contraintes ;
- le rejet des modifications du journal ;
- le rejeu complet du journal et l’égalité des projections reconstruites ;
- l’interruption d’une migration sans état partiellement validé ;
- l’échec avec une mauvaise clé et l’impossibilité d’ouvrir sans chiffrement.

Une migration n’est intégrée que si ces tests et un contrôle de cohérence
SQLite réussissent.

### Sauvegardes, export et synchronisation

- Ne jamais synchroniser ni partager le fichier SQLite.
- Ne pas considérer la sauvegarde système Android ou iOS comme une stratégie de
  récupération.
- Exclure la base et ses fichiers annexes des sauvegardes système tant que la
  stratégie de restauration des clés n’est pas définie et testée.
- Produire les futurs exports par une fonction dédiée, avec un format et un
  chiffrement décidés séparément.
- Synchroniser ultérieurement les événements chiffrés, jamais les pages SQLite
  ni les projections locales.

### Maintenance des dépendances

- Conserver le lockfile racine dans Git.
- Examiner les nouvelles versions stables et avis de sécurité de façon
  régulière.
- Mettre à jour ensemble Drift, `drift_dev` et `sqlite3` lorsqu’ils sont
  interdépendants.
- Ne jamais mettre à jour automatiquement une dépendance native en production
  sans construction Android/iOS et tests d’ouverture d’une base existante.
- Vérifier à chaque mise à niveau la présence effective du moteur chiffré, le
  schéma de chiffrement, l’ouverture d’un fichier antérieur et le rejet d’une
  mauvaise clé.
- Conserver un inventaire des dépendances et de leurs licences avant toute
  distribution.

## Options étudiées

### Option A — `sqflite` ou `sqflite_sqlcipher`

L’API est familière dans Flutter, mais elle couple la persistance au framework,
offre moins de contrôle typé sur le schéma et les migrations, et ajoute dans le
cas chiffré un fork natif spécifique. Cette option est écartée.

### Option B — `sqlite3` brut

Cette option réduit le nombre de couches, mais impose d’écrire manuellement les
adaptateurs, validations de requêtes, conversions, migrations et outils de
test. Le risque de perte de données et de divergence du schéma est supérieur.

### Option C — Drift, `sqlite3` 3.x et SQLCipher

SQLCipher est éprouvé et fournit un chiffrement AES-256 avec authentification.
Le build fourni par `sqlite3` peut toutefois embarquer un SQLite plus ancien
que les autres variantes et ajoute OpenSSL sur plusieurs plateformes. Cette
option reste une solution de repli si un audit ou une contrainte
d’interopérabilité invalide SQLite3MultipleCiphers.

### Option D — Drift, `sqlite3` 3.x et SQLite3MultipleCiphers

Cette option s’intègre directement aux hooks actuels de Dart, reste indépendante
de Flutter, chiffre la base et les journaux, utilise un schéma moderne
authentifié et suit rapidement les versions SQLite. Elle est retenue.

### Option E — Base objet ou clé-valeur

Un stockage objet simplifierait certains écrans, mais serait moins adapté à
l’append-only, aux contraintes relationnelles, aux migrations vérifiables et
aux projections requêtables. Cette option est écartée.

## Conséquences

### Positives

- stockage local chiffré sur Android et iOS avec une pile commune ;
- requêtes, tables et migrations vérifiées avant l’exécution ;
- transaction atomique entre événements et projections ;
- accès disque déplacé hors de l’isolate de l’interface ;
- schémas historiques et migrations testables ;
- absence de dépendance Flutter dans le package de stockage ;
- mécanisme de chiffrement vérifié en production et non seulement en debug.

### Négatives

- génération de code Drift à maintenir ;
- dépendance à un binaire natif et à ses hooks de compilation ;
- temps de construction plus important ;
- gestion de clé obligatoire avant toute ouverture ;
- impossibilité de revenir à une ancienne version de l’application après une
  migration de schéma ;
- migrations et mises à niveau du moteur à tester sur les deux plateformes ;
- nécessité d’examiner la sécurité et la maintenance de SQLite3MultipleCiphers
  dans la durée.

## Conditions d’acceptation

- une base créée par REBOOT est illisible avec SQLite standard ;
- la base, le WAL et les fichiers temporaires ne contiennent pas de données
  financières en clair ;
- une mauvaise clé et l’absence du moteur chiffré provoquent un échec fermé ;
- un événement et ses projections sont validés ou annulés ensemble ;
- les triggers empêchent la modification et la suppression du journal ;
- le rejeu reconstruit des projections identiques ;
- toutes les migrations publiées restent testées jusqu’au schéma courant ;
- aucune donnée de production n’est effacée pour résoudre une erreur de
  migration ;
- la couche métier ne dépend d’aucun type Drift, SQLite ou Flutter.

## Hors périmètre

Cet ADR ne choisit pas :

- l’API concrète Android Keystore ou iOS Keychain ;
- les règles de verrouillage biométrique ;
- la récupération et le transfert des clés entre appareils ;
- les époques de clé du foyer et la révocation ;
- le format d’export ;
- la licence open source de REBOOT.

## Liens

- PRD REBOOT 2.0 : sections 17, 19, 21, 22 et 23.
- ADR liés : ADR-0001 et ADR-0004.
- Drift :
  [documentation du package](https://pub.dev/packages/drift),
  [transactions](https://drift.simonbinder.eu/dart_api/transactions/) et
  [migrations](https://drift.simonbinder.eu/migrations/).
- Drift :
  [tests de migration](https://drift.simonbinder.eu/migrations/tests/).
- `sqlite3` :
  [package](https://pub.dev/packages/sqlite3) et
  [options des hooks](https://pub.dev/documentation/sqlite3/latest/topics/hook-topic.html).
- Drift :
  [bases chiffrées](https://drift.simonbinder.eu/platforms/encryption/).
- SQLite3MultipleCiphers :
  [présentation et choix des chiffrements](https://utelle.github.io/SQLite3MultipleCiphers/).
- SQLite :
  [PRAGMA](https://sqlite.org/pragma.html) et
  [mode WAL](https://sqlite.org/wal.html).
