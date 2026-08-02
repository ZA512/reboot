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
journal PWA initial. Ne pas persister un fichier SQLite ni une projection en
clair. Une projection éventuellement conservée est un cache chiffré jetable ;
elle reste reconstructible depuis le journal déchiffré.

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

Utiliser cinq object stores : clés, métadonnées, enveloppes, index UUID et
snapshots de projection.
L’ajout d’un ou plusieurs événements vérifie la dernière position et tous les
UUID dans une transaction IndexedDB `readwrite`, puis ajoute les enveloppes,
les index UUID et la nouvelle position dans la même transaction. Le lot entier
est validé ou annulé. Un conflit optimiste provoque un nouveau chiffrement avec
une nouvelle position et un nouveau nonce. Un UUID identique avec le même
contenu est idempotent ; avec un contenu différent, il est refusé.

### Snapshot de projection dérivé

Le schéma IndexedDB v2 ajoute un snapshot AES-256-GCM remplaçable. Il contient
uniquement un état dérivé versionné, jamais une nouvelle source de vérité. Son
enveloppe authentifie son type, sa position de journal et l’empreinte SHA-256 de
l’enveloppe située à cette position. Le démarrage déchiffre ce snapshot puis lit
et vérifie uniquement le suffixe postérieur.

Une structure, une authentification ou un ancrage invalide provoque la
suppression du snapshot et la reconstruction depuis le journal. Aucun échec de
cache ne supprime ou ne réécrit un événement. La migration v1 vers v2 ajoute
l’object store sans remplacer la clé non extractible ni les événements existants.

### Activation

Le journal dispose désormais d’un adaptateur `LocalEventJournal` couvert avec
de vrais `EventRecord`, mais cet adaptateur reste déconnecté de la composition
du shell Web, qui demeure sans saisie. Le codec complet des événements est
partagé dans un package Dart pur avec le stockage Android. Le benchmark de
300 000 événements sur Chrome desktop valide le débit
d’une saisie et mesure 69 ms pour restaurer un snapshot synthétique puis rejouer
100 événements, contre 34,0 secondes pour un rejeu intégral lors du même passage.

Un premier codec de projection réel couvre maintenant l’état complet des
dépenses. Il est canonique, borné, portable entre JavaScript et les plateformes
natives, restaure les invariants du domaine et sa reprise avec le suffixe
chiffré est vérifiée dans Chrome. Passer cet ADR à `Accepted` et activer les
données réelles exigera donc encore au minimum : les quatre autres projections
et leur conteneur agrégé, récupération chiffrée exposée dans l’interface,
validation Safari iPhone réelle, politique de persistance navigateur et tests
de concurrence multi-onglets. La CSP et le contrat d’hébergement sont désormais
fixés par l’ADR-0012.

Le cœur d’une récupération chiffrée est désormais prototypé : une archive
AES-256-GCM indépendante de la clé locale, accompagnée d’un code séparé `RBP1`,
est authentifiée et intégralement rejouée avant tout import atomique dans un
profil vide. Son format est partagé avec Android. Le branchement
au téléchargement et au sélecteur de fichier PWA est maintenant testé dans
Chrome. Android produit désormais le même format `RBP1`, vérifié par un vecteur
AES-GCM commun, et restaure encore les anciennes archives `RB1`. L’exposition
dans le shell et la validation Safari restent requises. La copie Web du code
ne peut pas demander au système de masquer les aperçus du presse-papiers.

## Preuves obtenues

Les tests Chrome exécutent réellement Web Crypto et IndexedDB et vérifient :

- refus d’export de la clé non extractible ;
- absence des payloads synthétiques dans les enveloppes persistées ;
- réouverture et déchiffrement ordonné ;
- UUID idempotent et conflit immuable ;
- lots atomiques, doublons internes et absence d’écriture partielle en cas de
  conflit ;
- aller-retour canonique de vrais événements métier via `LocalEventJournal` ;
- positions uniques avec deux connexions concurrentes à la même base ;
- rollback intégral lorsqu’une requête d’une transaction échoue ;
- rejet d’un ciphertext et d’un en-tête authentifié modifiés ;
- perte de clé et suppression isolée de la base sans régénération silencieuse ;
- cohérence transactionnelle entre la position finale, les enveloppes et
  l’index UUID complet ;
- algorithme, taille, non-extractibilité et usages exacts de la clé rechargée ;
- détection explicite du mode persistant ou `best effort` et cohérence du quota
  annoncé par le navigateur ;
- benchmark reproductible de 300 000 enveloppes sur Chrome desktop, incluant
  écriture, fermeture, réouverture et rejeu authentifié complet ;
- snapshot opaque, suffixe authentifié, corruption supprimable et migration de
  schéma v1 vers v2 sans perte de clé ni d’événement ;
- codec canonique de la projection des dépenses, bornes int64 exactes,
  invariants invalides refusés et reprise du suffixe identique au rejeu complet ;
- archive de récupération opaque, mauvais code et corruption refusés avant
  toute écriture, projections métier intégralement validées avant restauration ;
- téléchargement Blob, sélection bornée, annulation et workflow complet de
  restauration couverts dans Chrome.

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
- récupération implémentée mais non exposée dans le shell Web ; partage encore
  non implémenté.

## Liens

- ADR liés : ADR-0001, ADR-0003, ADR-0006, ADR-0008 et ADR-0012.
- Prototype : `docs/web-storage-prototype.md`.
- Benchmark : `docs/web-storage-benchmark.md`.
- [Web Cryptography Level 2](https://www.w3.org/TR/WebCryptoAPI/)
- [Package Dart `web`](https://pub.dev/packages/web)
