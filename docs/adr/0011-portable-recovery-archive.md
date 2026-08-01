# ADR-0011 — Archive de récupération portable Android et Web

- Statut : Accepted
- Date : 2026-08-02
- Accepté le : 2026-08-02
- Décideur : responsable de l’implémentation REBOOT
- Remplace : ADR-0010 pour les nouveaux exports

## Contexte

L’ADR-0010 a livré une première sauvegarde Android sûre sous la forme d’une
base SQLite chiffrée et d’un code `RB1`. Le prototype Web a ensuite dû définir
une archive AES-GCM indépendante d’IndexedDB et de sa clé non extractible.
Conserver deux formats empêcherait une restauration Android vers PWA ou PWA
vers Android et doublerait les migrations et audits futurs.

## Décision

Les nouveaux exports Android et Web utilisent le même format versionné `RBP1`.
Le package Dart pur `reboot_serialization` possède l’unique contrat de format :

- liste ordonnée d’`EventRecord` encodés canoniquement et sans perte numérique ;
- enveloppe JSON bornée portant version, algorithme, type de document, nonce et
  ciphertext en base64url canonique ;
- AES-256-GCM, nonce aléatoire de 96 bits et tag de 128 bits ;
- version, algorithme et type de document authentifiés comme données associées ;
- nouvelle clé aléatoire de 256 bits pour chaque export, représentée dans un
  code séparé préfixé `RBP1` ;
- limite de 64 Mio et d’un million d’événements.

Le format ne réalise aucune cryptographie. Android chiffre avec
`cryptography` 2.9.0 et sa source aléatoire système ; le navigateur conserve
Web Crypto. Un vecteur déterministe partagé vérifie que les deux moteurs
produisent exactement les mêmes octets pour une même clé, un même nonce et un
même journal.

Avant import, chaque plateforme authentifie l’archive entière, refuse les UUID
dupliqués, décode tous les événements puis rejoue toutes les projections dans
un journal éphémère en lecture seule. Le lot n’est importé qu’après cette
validation et seulement dans un profil vide.

Android continue de reconnaître les codes `RB1` et de restaurer les anciennes
bases SQLite de l’ADR-0010. Il ne produit plus de nouvel export `RB1`. Cette
compatibilité est testée et ne doit être retirée qu’avec une politique de fin
de support explicite.

## Options étudiées

### Conserver deux formats

Écarté : cela rendrait les sauvegardes dépendantes de la plateforme et
multiplierait les chemins de validation.

### Réutiliser SQLite dans le navigateur

Écarté : SQLite WebAssembly ne fournirait pas le chiffrement applicatif requis
et ajouterait une seconde couche de stockage et de migration.

### Abandonner immédiatement `RB1`

Écarté : une mise à jour ne doit pas rendre inutilisables les sauvegardes
Android déjà remises aux utilisateurs.

## Conséquences

### Positives

- une sauvegarde REBOOT n’est plus liée à Android ou au Web ;
- un seul codec strict et un seul vecteur cryptographique servent de contrat ;
- les événements restent la source de vérité et sont entièrement rejoués ;
- les archives Android existantes restent restaurables.

### Négatives

- Android conserve temporairement deux chemins de lecture ;
- le code aléatoire doit toujours être conservé séparément du fichier ;
- l’archive reste un format de récupération opaque, pas un export lisible ;
- l’interface de récupération PWA et la validation Safari restent à livrer.

## Conditions d’acceptation

- aucun payload financier n’est lisible dans l’archive ;
- Android et Web satisfont le même vecteur AES-GCM `RBP1` ;
- mauvais code, corruption, doublon ou projection invalide échouent fermés ;
- aucune restauration partielle ou fusion implicite n’est possible ;
- un fichier `RB1` Android historique reste restaurable.

## Liens

- Remplace partiellement l’ADR-0010 pour les nouveaux exports.
- ADR-0001 — Journal local dès le MVP.
- ADR-0006 — Cycle de vie des clés, révocation et récupération.
- ADR-0009 — Journal Web chiffré et garde locale de clé.
- Format : `docs/web-recovery-archive.md`.
- [`cryptography` 2.9.0](https://pub.dev/packages/cryptography/versions/2.9.0).
