# Modèle de menaces initial

- Version : 3
- Date : 2026-08-01
- Portée : application Android locale, future PWA et futur partage chiffré

## Objectif

Ce document définit les menaces que l’architecture de REBOOT doit traiter. Il
ne remplace pas les tests, les revues de code ni les ADR cryptographiques.

## Actifs à protéger

- événements financiers et leurs libellés ;
- revenus, charges, réserves, budgets et projections ;
- clés de base locale et clés d’époque du foyer ;
- identités et clés privées des appareils ;
- kit et données de récupération ;
- jetons OAuth et autorisations du fournisseur de synchronisation ;
- intégrité, ordre et provenance des événements ;
- disponibilité d’une copie récupérable des données.

## Frontières de confiance

- **Domaine pur** : traite des données déjà validées, sans accès direct au
  stockage, au réseau ou aux secrets.
- **Stockage local Android** : fichier chiffré dans l’espace privé de
  l’application, ouvert uniquement après récupération de la clé locale.
- **Stockage sécurisé Android** : Android Keystore protège les petits secrets
  propres à l’installation.
- **Origine Web/PWA** : code, service worker, caches, stockage persistant et
  primitives cryptographiques du navigateur forment une frontière distincte.
  Elle n’est pas assimilée à Android Keystore et doit être validée avant
  utilisation de données financières réelles.
- **Fournisseur distant** : considéré comme non fiable pour la confidentialité
  et l’intégrité des objets ; il fournit seulement stockage et transport.
- **Autre appareil du foyer** : autorisé tant que son certificat est actif,
  mais susceptible d’être perdu, volé, révoqué ou compromis.
- **Interface et journaux** : ne doivent jamais devenir un canal de fuite des
  données financières ou cryptographiques.
- **Widget Android** : reçoit uniquement le restant déjà calculé et sa date de
  validité. Son cache privé est chiffré avec une clé AES-GCM non exportable de
  l’Android Keystore ; aucun événement, libellé ou budget global n’y entre.

## Adversaires considérés

- personne obtenant une copie du fichier SQLite, de son WAL ou d’une sauvegarde
  système ;
- attaquant réseau observant ou modifiant la synchronisation ;
- fournisseur Drive ou compte cloud lisant, supprimant, rejouant ou altérant
  les objets ;
- appareil perdu ou volé après révocation ;
- application malveillante sans compromission du système d’exploitation ;
- dépendance ou mise à jour introduisant un comportement vulnérable ;
- utilisateur distant envoyant un objet malformé, surdimensionné ou signé avec
  une identité non autorisée ;
- erreur de migration, corruption locale ou suppression distante.
- injection XSS lisant des données déchiffrées dans la PWA ;
- service worker, ressource statique ou dépendance Web compromis ;
- effacement, éviction ou repli silencieux vers un stockage Web non persistant ;
- ancienne version PWA continuant à écrire un format devenu incompatible.

## Propriétés exigées

- aucune donnée métier en clair hors de la mémoire de l’application ;
- une copie de la base ne suffit pas pour lire les données ;
- les objets distants sont chiffrés de bout en bout et authentifiés ;
- chaque événement partagé est attribuable à un appareil autorisé ;
- une modification de l’enveloppe ou du contenu est détectée avant traitement ;
- un objet rejoué n’est pas appliqué deux fois ;
- une révocation ferme l’époque courante et exclut l’appareil des nouvelles
  clés ;
- un appareil révoqué ne peut pas injecter indéfiniment des événements sous une
  ancienne époque ;
- la perte d’un appareil n’oblige pas à faire confiance à l’éditeur ;
- une erreur de stockage sécurisé ne provoque ni effacement silencieux ni
  recréation d’une base vide ;
- aucune clé, donnée financière ou jeton OAuth n’apparaît dans les journaux.
- le widget masque le restant par défaut, refuse de révéler un montant périmé
  et remasque automatiquement une révélation temporaire ;
- aucune donnée métier, clé ou jeton OAuth n’est placé en clair dans un cache
  Web ou confié au service worker ;
- une perte du stockage PWA est détectée et conduit à une récupération
  explicite, jamais à un faux profil vide présenté comme le profil existant ;
- une politique de sécurité de contenu restrictive limite les sources de code.

## Limites assumées

REBOOT ne peut pas garantir :

- la confidentialité sur un appareil déverrouillé dont le système
  d’exploitation est compromis ;
- l’effacement d’informations qu’un appareil autorisé a déjà déchiffrées ;
- la récupération d’un profil solo non synchronisé si l’appareil, sa clé et
  toute exportation ont tous été perdus ;
- la disponibilité du fournisseur distant face à une suppression ou une panne ;
- la protection contre une personne autorisée qui photographie ou exporte les
  informations affichées ;
- la révocation sûre d’un kit de récupération volé sans création d’une nouvelle
  racine de confiance et migration du foyer.
- la conservation illimitée du stockage local d’un navigateur ;
- la confidentialité d’une PWA lorsqu’un script exécuté dans son origine est
  compromis et accède aux données déjà déchiffrées.

Ces limites doivent être expliquées sans présenter le chiffrement comme une
garantie absolue.

## Scénarios prioritaires

| Scénario | Contrôle principal |
|---|---|
| Copie du fichier SQLite | chiffrement SQLite et clé locale non sauvegardée avec le fichier |
| Mauvaise bibliothèque SQLite chargée | contrôle cryptographique obligatoire et échec fermé |
| Objet Drive lu par un tiers | chiffrement XChaCha20-Poly1305 par clé d’époque |
| Objet Drive modifié | AEAD, signature d’appareil et en-tête authentifié |
| Rejeu d’un événement | UUID, séquence d’appareil et idempotence |
| Appareil révoqué encore connecté à Drive | nouvelle époque de clé et point de coupure signé |
| Injection tardive par l’appareil révoqué | rejet après le point de coupure |
| Perte du dernier appareil | kit de récupération et paquet distant chiffré |
| Perte du stockage sécurisé local | échec fermé puis restauration d’une archive locale chiffrée, si elle existe |
| Fuite par diagnostic | redaction stricte et télémétrie sans données métier |
| Lecture du cache du widget | cache AES-GCM, clé Android Keystore et sauvegarde Android désactivée |
| Regard indiscret sur l’écran d’accueil | montant masqué par défaut et révélation limitée à deux secondes |
| Dépendance compromise | versions verrouillées, revue des mises à jour et inventaire |
| Migration interrompue | transaction, schémas versionnés et tests de reprise |
| XSS dans la PWA | CSP restrictive, aucun HTML dynamique non assaini, revue des dépendances |
| Cache applicatif compromis | HTTPS, ressources versionnées, service worker minimal et mise à jour contrôlée |
| Stockage PWA supprimé | détection, avertissement, export et récupération distante chiffrée |
| Repli vers stockage non persistant | test au démarrage et échec fermé pour les données réelles |

## Validation continue

Le modèle doit être revu :

- avant l’ajout de la synchronisation ;
- avant chaque nouveau fournisseur distant ;
- avant les imports bancaires ;
- après toute modification du format d’enveloppe ou de la hiérarchie de clés ;
- après un incident, une vulnérabilité de dépendance ou un changement majeur
  Android ou Web ;
- avant une publication Android ou PWA.

Les constats entraînent un ADR, un test ou une limitation documentée. Ils ne
restent pas uniquement dans une discussion.
