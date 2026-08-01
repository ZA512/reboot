# ADR-0010 — Export local chiffré et restauration

- Statut : Superseded
- Date : 2026-08-01
- Accepté le : 2026-08-01
- Décideur : responsable de l’implémentation REBOOT
- Remplacé le : 2026-08-02 par l’ADR-0011 pour les nouveaux exports

> Les archives SQLite `RB1` décrites ici restent restaurables. REBOOT produit
> désormais les archives portables `RBP1` définies par l’ADR-0011.

## Contexte

La base Android et sa clé sont propres à l’installation et volontairement
exclues des sauvegardes système. Sans export explicite, la perte ou la
désinstallation de l’appareil entraîne donc une perte définitive du profil.

Le premier export doit permettre une restauration locale sans introduire de
compte éditeur, de mot de passe faible transformé en clé, de copie financière
en clair ou de dépendance au fournisseur de fichiers choisi par l’utilisateur.
Il ne constitue pas encore le format lisible de portabilité CSV ou JSON.

## Décision

### Archive de récupération v1

L’archive `.reboot-backup` est une nouvelle base SQLite3MultipleCiphers :

- elle contient une copie ordonnée du journal d’événements, pas la base active ;
- elle utilise le même schéma append-only et les mêmes événements versionnés ;
- elle est chiffrée par ChaCha20 et vérifiée par HMAC comme la base locale ;
- elle reçoit une clé aléatoire de 256 bits propre à cet export ;
- elle est fermée proprement avant d’être remise au sélecteur de documents.

La clé d’export n’est ni `K_db`, ni enregistrée dans le coffre de l’application.
Elle est affichée comme un code de récupération préfixé et versionné :
`RB1.` suivi de la clé en Base64URL sans remplissage, regroupée pour la lecture.
Une faute de saisie ou une mauvaise clé échoue de manière indistincte lors de
la vérification cryptographique de l’archive.

L’utilisateur doit conserver l’archive et son code dans deux emplacements
distincts. REBOOT explique qu’aucun des deux éléments ne suffit seul et qu’il
ne peut pas retrouver un code perdu.

### Restauration

La restauration est proposée uniquement tant que le journal local est vide.
Elle suit cet ordre :

1. sélectionner une archive par le sélecteur de documents du système ;
2. saisir ou coller le code de récupération ;
3. limiter la taille du fichier avant traitement ;
4. ouvrir et authentifier l’archive avec sa clé d’export ;
5. décoder et rejouer entièrement le journal avant toute mutation locale ;
6. recopier atomiquement les événements validés dans la base locale neuve ;
7. continuer avec la clé locale `K_db` créée par cette installation.

La clé d’export n’est donc jamais réutilisée comme clé locale. Une restauration
ne fusionne pas deux profils et ne remplace jamais un journal non vide.

### Frontière Android

Android utilise le Storage Access Framework : `ACTION_CREATE_DOCUMENT` pour
l’export et `ACTION_OPEN_DOCUMENT` pour la restauration. REBOOT ne demande
aucun accès général aux fichiers. Les URI sont copiées par flux et les fichiers
temporaires privés sont supprimés après l’opération.

La taille maximale initiale d’une archive est de 64 MiB. Les messages d’erreur
exposés ne contiennent ni chemin, ni code, ni libellé, ni montant.

## Options étudiées

### Copier la base active et sa clé

Écartée : le mode WAL rend la copie directe fragile et la réutilisation de
`K_db` étend inutilement la portée d’un secret propre à l’installation.

### Export JSON en clair

Écarté : un mauvais choix de destination exposerait immédiatement l’intégralité
des données financières et des libellés.

### Chiffrement par mot de passe utilisateur

Différé : il impose une dérivation Argon2id, des paramètres de coût versionnés
et une UX de phrase secrète. Le code aléatoire fournit dès maintenant 256 bits
d’entropie sans faire dépendre la sécurité de la qualité d’un mot de passe.

### Ajouter immédiatement libsodium

Différé pour cet export : SQLite3MultipleCiphers fournit déjà le chiffrement
authentifié nécessaire et évite une seconde représentation du journal. Le
package `sodium` reste la décision acceptée pour les enveloppes de partage, les
signatures, les époques et les kits distants.

## Conséquences

### Positives

- première récupération Android sans serveur et sans donnée en clair ;
- clé d’export distincte de la clé locale ;
- rejeu métier complet avant import ;
- choix libre du fournisseur de fichiers par l’utilisateur ;
- aucune permission de stockage étendue.

### Négatives

- perdre l’archive ou le code rend la restauration impossible ;
- le format v1 est un format de récupération REBOOT, pas un export lisible ;
- une nouvelle archive est nécessaire après les changements importants ;
- l’import ne fusionne pas des journaux existants.

## Conditions d’acceptation

- une archive ne contient aucun octet financier lisible ;
- une mauvaise clé, une archive altérée ou un journal invalide échoue fermé ;
- aucune restauration partielle n’est conservée ;
- un journal non vide ne peut pas être remplacé ;
- une restauration reconstruit les mêmes projections depuis les mêmes événements ;
- les secrets temporaires sont écrasés lorsque leur représentation le permet ;
- l’archive et son code ne sont jamais envoyés à REBOOT.

## Liens

- ADR-0001 — Journal local dès le MVP.
- ADR-0005 — SQLite chiffrée, Drift et migrations.
- ADR-0006 — Cycle de vie des clés, révocation et récupération.
- Android Storage Access Framework :
  <https://developer.android.com/training/data-storage/shared/documents-files>.
