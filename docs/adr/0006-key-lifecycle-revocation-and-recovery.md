# ADR-0006 — Cycle de vie des clés, révocation et récupération

- Statut : Accepted
- Date : 2026-07-31
- Accepté le : 2026-07-31
- Décideur : responsable de l’implémentation REBOOT

## Contexte

REBOOT doit chiffrer sa base locale et, plus tard, partager des événements et
snapshots sans serveur métier de l’éditeur. Un appareil autorisé peut être
perdu, volé ou révoqué tout en conservant :

- les anciennes clés qu’il a déjà reçues ;
- une copie de ses données locales ;
- un jeton OAuth encore utilisable ;
- un accès en lecture ou écriture au stockage distant ;
- des événements créés hors ligne mais pas encore synchronisés.

Retirer seulement l’appareil d’une liste ne protège donc pas les futurs objets.
Une révocation doit fermer l’époque cryptographique courante, distribuer une
nouvelle clé uniquement aux appareils actifs et définir quels événements de
l’ancienne époque restent admissibles.

La récupération doit rester possible sans que l’éditeur possède une clé, un
compte central ou une porte dérobée.

## Décision

### Bibliothèques et primitives

Utiliser la version stable courante de `sodium`, liaison Dart de libsodium, pour
les opérations cryptographiques applicatives. Au moment de cette décision, la
version stable examinée est `sodium` 4.0.3, fondée sur libsodium 1.0.21 et
distribuée par les hooks natifs Dart.

Utiliser uniquement les primitives de haut niveau suivantes :

- générateur aléatoire de libsodium ;
- XChaCha20-Poly1305-IETF pour chiffrer les objets et paquets ;
- Ed25519 pour signer les enveloppes et décisions d’autorité ;
- X25519 et les sealed boxes libsodium pour remettre une clé à un appareil ;
- BLAKE2b par l’API de hachage générique de libsodium ;
- KDF libsodium avec contextes de domaine distincts pour dériver des sous-clés.

Ne pas implémenter de primitive cryptographique dans REBOOT. Ne pas employer
RSA, AES-CBC sans authentification, chiffrement maison, nonce raccourci ou mot
de passe utilisateur comme clé directe.

Les primitives, tailles, contextes KDF et formats sont versionnés. Une migration
cryptographique crée une nouvelle version ou une nouvelle époque ; elle ne
change jamais silencieusement les paramètres d’un objet existant.

### Frontière d’implémentation

Créer `packages/reboot_crypto` lorsque les premières enveloppes chiffrées sont
implémentées.

Ce package :

- est un package Dart sans dépendance Flutter ;
- encapsule libsodium derrière des interfaces étroites ;
- fournit génération de clés, chiffrement authentifié, signature, vérification,
  enveloppement et effacement ;
- ne connaît ni Drive, ni SQLite, ni l’interface ;
- expose des erreurs typées sans contenu sensible ;
- contient les vecteurs de test et les versions de protocole.

L’adaptateur `flutter_secure_storage` reste du côté plateforme et implémente un
port de coffre de secrets. Le domaine ne dépend ni de libsodium ni du stockage
sécurisé.

### Hiérarchie des secrets

Séparer les secrets suivants :

| Secret | Portée | Usage |
|---|---|---|
| `K_db` | profil sur une installation | ouvrir la base SQLite locale |
| `D_sign` | appareil | signer les événements et enveloppes |
| `D_box` | appareil | recevoir des clés par X25519/sealed box |
| `H_epoch[n]` | foyer et époque | chiffrer les objets partagés de l’époque |
| `R_root` | kit de récupération | autorité ultime et chiffrement de récupération |

Tous sont générés aléatoirement. Une clé ne sert jamais à deux usages.

`K_db`, les parties privées de `D_sign` et `D_box`, et les clés d’époque reçues
sont propres à l’installation. Le kit `R_root` n’est pas conservé durablement
dans le stockage normal de l’application.

La perte de `K_db` ne change pas les clés partagées : une nouvelle base locale
peut être créée puis reconstruite depuis les objets distants après une
récupération autorisée. En mode solo non synchronisé, la récupération nécessite
une exportation chiffrée existante.

### Stockage local des secrets

Utiliser la dernière version stable compatible de `flutter_secure_storage`
comme adaptateur initial vers :

- Android Keystore avec RSA-OAEP-SHA-256 pour envelopper une clé AES-GCM ;
- iOS Keychain avec l’accessibilité
  `WhenUnlockedThisDeviceOnly` et sans synchronisation iCloud.

Configuration obligatoire :

- espace de noms dédié à REBOOT ;
- algorithmes sélectionnés explicitement ;
- `resetOnError: false` sur Android ;
- aucune migration automatique d’algorithme sans migration REBOOT testée ;
- aucun stockage de secours dans des préférences ordinaires ;
- aucune synchronisation Keychain ;
- sauvegardes Android, transferts automatiques et copies iOS exclus pour les
  secrets, la base et ses fichiers annexes.

Une erreur du Keystore ou du Keychain ne supprime pas un secret et ne déclenche
pas la création d’un nouveau profil. L’application se verrouille et propose les
voies de récupération disponibles.

Le verrouillage biométrique est une protection d’interface optionnelle. Il ne
constitue ni une clé de chiffrement ni une méthode de récupération. Son absence,
son changement ou l’échec d’un capteur ne doit pas détruire les données.

Les secrets chargés en mémoire utilisent autant que possible les types de clés
protégées et les fonctions d’effacement de libsodium. Leur durée de vie et leurs
copies sont minimisées.

### Identité et autorité

Chaque appareil possède :

- un UUID aléatoire ;
- une paire Ed25519 `D_sign` ;
- une paire X25519 `D_box` ;
- un certificat indiquant son foyer, son rôle, ses clés publiques et son état.

Chaque événement partagé est :

1. chiffré avec la clé de son époque par XChaCha20-Poly1305 ;
2. lié à un en-tête authentifié contenant au minimum version, foyer, époque,
   objet, type, schéma, auteur et séquence d’appareil ;
3. signé par `D_sign` sur les octets exacts de l’en-tête et du texte chiffré.

Le chiffrement protège le contenu ; la signature identifie l’appareil auteur.
Une signature valide ne suffit pas : le certificat doit aussi être actif pour
l’époque et la séquence concernées.

Le premier appareil devient l’autorité courante du foyer pour les opérations de
membre et d’appareil. Les autres appareils peuvent saisir et synchroniser les
dépenses, mais l’ajout, la révocation et le transfert d’autorité nécessitent la
signature de l’autorité courante.

Cette centralisation limitée ne concerne pas les décisions financières. Elle
évite deux listes d’appareils concurrentes impossibles à départager sans
serveur. L’autorité peut être transférée explicitement à un autre appareil.

`R_root` établit une racine de récupération hors ligne qui peut remplacer une
autorité perdue. La clé privée de cette racine n’est pas conservée sur
l’appareil après la création ou l’utilisation du kit.

### Invitation d’un appareil

L’invitation de première version se fait à proximité :

1. le nouvel appareil génère son UUID et ses deux paires de clés ;
2. il affiche un QR code contenant uniquement ses clés publiques, un défi
   aléatoire, une version de protocole et une expiration courte ;
3. l’appareil d’autorité scanne le QR code ;
4. les deux appareils affichent un code de vérification dérivé de la
   transcription complète ;
5. l’utilisateur confirme que les codes correspondent ;
6. l’autorité signe le certificat du nouvel appareil ;
7. elle chiffre les clés d’époque nécessaires pour `D_box` du nouvel appareil ;
8. le nouvel appareil vérifie, déchiffre et stocke les secrets localement.

Une invitation expirée, réutilisée ou non confirmée est rejetée. Aucune clé
privée, clé d’époque, donnée financière ou jeton OAuth ne passe dans le QR code.

Une invitation distante pourra être ajoutée plus tard, mais devra fournir une
vérification hors bande équivalente. Un simple lien reçu dans le même canal que
les données n’est pas suffisant.

### Époques de clé

Le foyer possède une époque entière monotone commençant à 1. Chaque époque a une
clé `H_epoch[n]` aléatoire indépendante.

- Chaque objet indique son époque.
- Les nonces XChaCha20 sont aléatoires sur 192 bits et ne sont jamais réutilisés
  intentionnellement avec une même clé.
- L’en-tête complet est passé comme donnée associée de l’AEAD.
- Les appareils actifs conservent les anciennes clés nécessaires à l’historique.
- Un nouvel appareil reçoit uniquement les époques autorisées par la politique
  du foyer.
- Les clés d’époque ne sont jamais stockées en clair chez le fournisseur
  distant ; elles sont enveloppées séparément pour chaque appareil actif.

Une rotation planifiée peut créer une nouvelle époque sans révocation. Une
révocation crée toujours une nouvelle époque.

### Révocation

La révocation suit une procédure indivisible au niveau logique :

1. l’autorité synchronise les manifestes disponibles ;
2. elle crée un point de coupure signé pour l’ancienne époque ;
3. ce point identifie l’appareil révoqué, la liste active et les derniers objets
   acceptés de l’appareil révoqué ;
4. elle génère `H_epoch[n+1]` ;
5. elle enveloppe cette clé uniquement pour les appareils encore actifs ;
6. elle publie le manifeste de transition signé ;
7. elle retire, lorsque le fournisseur le permet, l’accès distant et révoque le
   jeton OAuth de l’appareil ;
8. chaque appareil actif cesse d’émettre sous l’ancienne époque après avoir
   vérifié la transition.

Après le point de coupure :

- un objet tardif signé par l’appareil révoqué est rejeté ou placé en
  quarantaine sans effet métier ;
- un objet de la nouvelle époque provenant de cet appareil est impossible à
  produire sans compromission d’une nouvelle clé ;
- un objet ancien déjà accepté reste lisible et auditable ;
- les événements hors ligne d’un appareil toujours actif peuvent être adoptés
  selon les règles du futur ADR de synchronisation.

La révocation ne prétend pas effacer l’histoire déjà déchiffrée par l’appareil.
Elle garantit la confidentialité et l’autorisation futures à partir du point de
coupure.

Si l’appareil révoqué était l’autorité, la récupération avec `R_root` désigne
d’abord une nouvelle autorité, puis effectue la rotation. Si le kit de
récupération lui-même est soupçonné compromis, le foyer doit créer une nouvelle
racine et migrer vers un nouveau coffre ; aucune rotation ordinaire ne peut
annuler sûrement un secret racine copié.

### Récupération

Lors de la création d’un foyer partagé, REBOOT génère un kit de récupération
contenant :

- un secret aléatoire de 256 bits encodé pour QR et saisie manuelle avec somme
  de contrôle ;
- l’identifiant opaque permettant de localiser le paquet de récupération ;
- la version du format ;
- des avertissements clairs sur la conservation hors ligne.

Le kit peut être imprimé ou enregistré dans un emplacement choisi explicitement
par l’utilisateur. REBOOT :

- ne l’envoie pas à l’éditeur ;
- ne le place pas dans les sauvegardes automatiques ;
- ne le photographie pas et ne le conserve pas dans la galerie ;
- ne peut pas le réinitialiser.

Un paquet de récupération distant, chiffré par une sous-clé dérivée de
`R_root`, contient la racine d’autorité et les clés nécessaires pour restaurer
le foyer. Il est remplacé à chaque changement d’époque ou d’autorité. Sa
confidentialité et son intégrité sont protégées par XChaCha20-Poly1305 avec un
en-tête authentifié.

Ordre de récupération :

1. utiliser un autre appareil actif lorsqu’il en existe un ;
2. sinon authentifier l’accès au fournisseur distant ;
3. scanner ou saisir le kit ;
4. vérifier et déchiffrer le paquet de récupération ;
5. créer une nouvelle identité d’appareil et une nouvelle clé de base locale ;
6. désigner cette identité comme autorité par une opération de récupération ;
7. révoquer les appareils perdus et ouvrir une nouvelle époque ;
8. reconstruire la base depuis les objets authentifiés.

Une récupération ne réutilise jamais `K_db` ni les clés privées d’un ancien
appareil.

### Format, validation et limites

- Toutes les enveloppes ont une version et une longueur maximale.
- Les champs authentifiés ont un encodage binaire déterministe ; les octets
  signés sont conservés et ne sont pas reconstruits à partir d’un objet JSON.
- Les identifiants, tailles, époques et séquences sont validés avant allocation
  importante ou déchiffrement.
- Le texte clair n’est traité qu’après validation de l’AEAD, de la signature,
  du certificat et de l’autorisation.
- Les UUID et séquences empêchent la double application.
- Les erreurs cryptographiques sont indistinctes pour l’interface et expurgées
  des secrets.
- Les clés et données déchiffrées ne sont jamais transmises à la télémétrie.

Le format exact des segments, manifestes, snapshots et conflits sera défini par
l’ADR de synchronisation en respectant ces invariants.

### Maintenance

- Verrouiller `sodium`, `flutter_secure_storage` et leurs dépendances.
- Installer la dernière version stable compatible, jamais une préversion par
  défaut.
- Examiner les avis de sécurité, changelogs et changements de binaire natif
  avant mise à jour.
- Tester les anciennes enveloppes, bases, clés et paquets de récupération après
  chaque mise à niveau.
- Maintenir des vecteurs de test indépendants du code de production.
- Refuser toute mise à jour qui modifie implicitement algorithme, paramètres,
  format de clé ou comportement de migration.

## Options étudiées

### Option A — Une clé unique pour la base et la synchronisation

Écartée : la perte d’un appareil exposerait tous les usages et empêcherait une
rotation limitée. Elle couplerait aussi le format local au protocole partagé.

### Option B — Clés dérivées d’un mot de passe utilisateur

Écartée comme mécanisme principal : les mots de passe mémorisables ont une
entropie insuffisante et imposeraient un système de compte ou de réinitialisation.
Un secret de récupération aléatoire est utilisé à la place.

### Option C — Chiffrement symétrique sans signatures d’appareil

Écartée : tout détenteur de la clé du foyer pourrait se faire passer pour
n’importe quel appareil, ce qui rendrait la révocation et l’audit fragiles.

### Option D — Clé de foyer permanente

Écartée : un appareil révoqué continuerait à déchiffrer les nouveaux objets.

### Option E — Rotation d’époque, identités par appareil et racine de récupération

Retenue : elle sépare les compromissions, permet l’attribution des événements,
ferme l’accès futur après révocation et conserve une récupération sans serveur
de l’éditeur.

### Option F — Clés uniquement dans Secure Enclave et StrongBox

Écartée comme exigence universelle : leur disponibilité et leurs primitives
diffèrent selon les appareils, et les clés d’époque doivent être transférables
entre appareils autorisés. Le Keystore et le Keychain protègent les secrets
locaux ; les mécanismes matériels pourront renforcer les clés d’enveloppe sans
modifier le protocole.

## Conséquences

### Positives

- séparation nette entre perte locale, partage et récupération ;
- confidentialité future après révocation ;
- provenance vérifiable de chaque événement ;
- absence de clé ou compte détenu par l’éditeur ;
- primitives modernes avec implémentation libsodium ;
- récupération possible après perte du dernier appareil si le kit existe ;
- format versionné et évolutif.

### Négatives

- gestion de plusieurs clés et certificats ;
- nécessité d’un appareil d’autorité pour les changements courants ;
- révocation plus coûteuse qu’une suppression de ligne ;
- anciens contenus impossibles à faire oublier à un appareil qui les a lus ;
- perte définitive possible sans appareil actif, kit ou export ;
- kit de récupération à conserver avec le même sérieux qu’un mot de passe
  maître ;
- tests multi-appareils et de concurrence indispensables.

## Conditions d’acceptation

- les clés locales ne migrent pas automatiquement vers un autre appareil ;
- le chargement d’un secret manquant ou corrompu échoue sans effacement ;
- un objet altéré, mal signé ou attribué à un appareil inactif est rejeté ;
- deux objets identiques ne sont appliqués qu’une fois ;
- une révocation produit obligatoirement une nouvelle époque ;
- l’appareil révoqué ne peut pas déchiffrer ni produire d’objet accepté dans la
  nouvelle époque ;
- ses objets tardifs postérieurs au point de coupure n’affectent pas le métier ;
- un appareil actif peut être remplacé par invitation ;
- le kit restaure un foyer sur une installation neuve sans intervention de
  l’éditeur ;
- les journaux et rapports ne contiennent aucun secret ou contenu financier ;
- des vecteurs de test couvrent chiffrement, signature, invitation, rotation,
  révocation, récupération, corruption et rejeu.

## Hors périmètre

Cet ADR ne choisit pas :

- le fournisseur Drive et ses scopes OAuth ;
- le format final des segments et snapshots ;
- l’algorithme de résolution de tous les conflits métier ;
- l’interface détaillée d’impression ou de conservation du kit ;
- les rôles financiers entre membres d’un foyer ;
- le format d’export portable.

## Liens

- PRD REBOOT 2.0 : sections 17, 18, 19, 21, 22 et 23.
- Modèle de menaces : `docs/security/threat-model.md`.
- ADR liés : ADR-0001, ADR-0004 et ADR-0005.
- Android :
  [Android Keystore](https://developer.android.com/privacy-and-security/keystore)
  et [Auto Backup](https://developer.android.com/identity/data/autobackup).
- Apple :
  [Keychain Services](https://developer.apple.com/documentation/security/keychain-services)
  et
  [`WhenUnlockedThisDeviceOnly`](https://developer.apple.com/documentation/security/ksecattraccessiblewhenunlockedthisdeviceonly).
- Packages :
  [`sodium`](https://pub.dev/packages/sodium) et
  [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage).
- libsodium :
  [XChaCha20-Poly1305](https://doc.libsodium.org/secret-key_cryptography/aead/chacha20-poly1305/xchacha20-poly1305_construction),
  [sealed boxes](https://doc.libsodium.org/public-key_cryptography/sealed_boxes)
  et
  [signatures](https://doc.libsodium.org/public-key_cryptography/public-key_signatures).
