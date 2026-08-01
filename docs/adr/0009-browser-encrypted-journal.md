# ADR-0009 — Journal Web chiffré et garde locale de clé

- Statut : Proposed
- Date : 2026-08-01
- Décideur proposé : responsable de l’implémentation REBOOT

## Contexte

La PWA ne dispose ni d’Android Keystore ni du moteur SQLite chiffré retenu pour
Android. Elle doit pourtant écrire chaque événement hors ligne avant toute
synchronisation, sans persister de montant, libellé ou payload en clair.

Une copie brute d’IndexedDB ne doit pas suffire à lire les événements. Une
suppression ou une corruption de la clé ne doit jamais provoquer la création
silencieuse d’un nouveau profil. Un JavaScript hostile exécuté sur la même
origine reste toutefois capable d’utiliser une clé Web Crypto chargée par
l’application : la garde locale ne remplace donc pas la sécurité de la chaîne
de déploiement et la CSP.

## Décision proposée

### Stockage du journal

Utiliser IndexedDB directement par le package officiel `web` 1.1.1 pour le
journal PWA initial. Ne pas persister un fichier SQLite ou des projections :
les projections sont reconstruites en mémoire depuis le journal déchiffré.

Chaque événement est chiffré avant l’appel à IndexedDB dans une enveloppe
versionnée :

- AES-256-GCM par l’API Web Crypto native ;
- clé locale `CryptoKey` non extractible, limitée à `encrypt` et `decrypt` ;
- nonce aléatoire de 96 bits par enveloppe ;
- tag d’authentification de 128 bits ;
- position, UUID, version de format, algorithme et identifiant de clé comme
  données associées authentifiées ;
- ciphertext et nonce encodés en base64url canonique sans remplissage ;
- positions exactes signées 64 bits stockées en chaînes décimales et clés
  IndexedDB complétées à 19 chiffres pour préserver l’ordre lexical.

Le type métier, la version de payload et le JSON métier restent à l’intérieur
du ciphertext. L’UUID aléatoire et la position restent visibles pour assurer
ordre et idempotence sans déchiffrement ; ils révèlent seulement l’existence et
le volume approximatif d’activité locale.

### Garde locale

Générer la clé dans Web Crypto avec `extractable = false`, puis conserver le
`CryptoKey` lui-même dans un object store IndexedDB grâce au clonage structuré.
Ne jamais exporter la clé brute pour sa persistance.

Un marqueur non sensible distinct dans `localStorage` aide à détecter une
éviction isolée d’IndexedDB. Les cas suivants échouent fermés :

- marqueur présent mais base recréée vide ;
- profil initialisé mais clé absente ;
- clé extractible ou structure de métadonnées incohérente ;
- enveloppe, ordre, encodage ou authentification invalide.

L’effacement simultané de tout le stockage de l’origine ne peut pas être
distingué localement d’une première installation. La livraison avec données
réelles exige donc une preuve externe récupérable : export chiffré ou copie
distante chiffrée liée au profil.

### Atomicité et concurrence

Utiliser quatre object stores : clés, métadonnées, enveloppes et index UUID.
L’ajout vérifie la dernière position et l’UUID dans une transaction IndexedDB
`readwrite`, puis ajoute l’enveloppe, l’index UUID et la nouvelle position dans
la même transaction. Un conflit optimiste provoque un nouveau chiffrement avec
une nouvelle position et un nouveau nonce. Un UUID identique avec le même
contenu est idempotent ; avec un contenu différent, il est refusé.

### Activation

Le prototype reste déconnecté de `LocalEventJournal` et le shell Web reste sans
saisie. Passer cet ADR à `Accepted` et activer les données réelles exigera au
minimum : récupération chiffrée, benchmark de 300 000 événements, validation
Safari iPhone réelle, politique de persistance navigateur, CSP et hébergement
durci, tests de concurrence multi-onglets et stratégie de migration.

## Preuves obtenues

Les tests Chrome exécutent réellement Web Crypto et IndexedDB et vérifient :

- refus d’export de la clé non extractible ;
- absence des payloads synthétiques dans les enveloppes persistées ;
- réouverture et déchiffrement ordonné ;
- UUID idempotent et conflit immuable ;
- positions uniques avec deux connexions concurrentes à la même base ;
- rollback intégral lorsqu’une requête d’une transaction échoue ;
- rejet d’un ciphertext et d’un en-tête authentifié modifiés ;
- perte de clé et suppression isolée de la base sans régénération silencieuse ;
- cohérence transactionnelle entre la position finale, les enveloppes et
  l’index UUID complet ;
- algorithme, taille, non-extractibilité et usages exacts de la clé rechargée ;
- détection explicite du mode persistant ou `best effort` et cohérence du quota
  annoncé par le navigateur.

## Options étudiées

### Drift/SQLite WebAssembly

Différé. Sans chiffrement applicatif des événements, les pages SQLite ou les
fichiers OPFS/IndexedDB resteraient lisibles. Ajouter une couche SQLite ne
réduit pas le besoin d’enveloppes chiffrées et augmente la surface de migration
pour le journal initial.

### Bibliothèque cryptographique Dart supplémentaire

Écartée pour ce prototype. Web Crypto fournit AES-GCM et la clé non extractible
dans Safari, Chrome, Edge et Firefox. Une dépendance supplémentaire ne
protégerait pas mieux la clé contre un script hostile de même origine.

### Clé brute encodée dans IndexedDB

Écartée : une simple lecture du stockage exposerait immédiatement la clé et les
événements.

## Conséquences

### Positives

- aucune donnée métier claire confiée au stockage du prototype ;
- primitives fournies par le navigateur et API Dart officielle minimale ;
- journal simple, append-only, testable et compatible JavaScript/Wasm ;
- suppression ou corruption détectée sans remise à zéro silencieuse.

### Négatives

- clé utilisable par tout script compromis de la même origine ;
- perte simultanée de la base et du marqueur indétectable sans preuve externe ;
- projections reconstruites au démarrage tant qu’aucun cache chiffré n’existe ;
- compatibilité et quota dépendants du navigateur ;
- récupération et partage encore non implémentés.

## Liens

- ADR liés : ADR-0001, ADR-0003, ADR-0006 et ADR-0008.
- Prototype : `docs/web-storage-prototype.md`.
- [Web Cryptography Level 2](https://www.w3.org/TR/WebCryptoAPI/)
- [Package Dart `web`](https://pub.dev/packages/web)
