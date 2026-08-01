# Environnement de développement

## Outils de référence

REBOOT utilise :

- Flutter 3.44.8, canal `stable` ;
- Dart 3.12.2 fourni par ce SDK Flutter ;
- révision Flutter `058e0af2c2b57e369d905a03ac9748b0ebf543c6`.

Les archives et empreintes SHA-256 officielles sont enregistrées dans
[`tool/flutter-version.json`](../tool/flutter-version.json).

La version est volontairement précise. Ne pas exécuter `flutter upgrade` dans
ce projet sans modification dédiée du fichier de version, régénération
contrôlée des fichiers plateforme et exécution de tous les tests.

## Installation

1. Installer Git.
2. Télécharger l’archive correspondant au système depuis
   [l’archive officielle Flutter](https://docs.flutter.dev/install/archive).
3. Vérifier son SHA-256 avec la valeur du fichier de version.
4. Extraire le SDK dans un chemin local accessible en écriture, sans espace ni
   caractère spécial.
5. Ajouter le dossier `flutter/bin` au `PATH`.
6. Exécuter `flutter doctor -v`.

Exemples de chemins :

- Windows : `C:\Users\<utilisateur>\develop\flutter` ;
- macOS et Linux : `~/develop/flutter`.

## Plateformes produit

### Android

Installer Android Studio, le SDK Android courant demandé par Flutter, les
command-line tools et accepter les licences avec :

```shell
flutter doctor --android-licenses
```

Android est la cible d’implémentation prioritaire. Le poste Windows sert au
développement Dart, Flutter, Android et Web.

### Web/PWA et iPhone

L’accès iPhone initial passe par une PWA. Ne pas activer la cible Web en
important directement les adaptateurs Android : la racine de composition, le
stockage local chiffré et la garde des clés doivent d’abord disposer
d’implémentations Web validées conformément à l’ADR-0008.

Le shell Web actuel est volontairement bloqué avant toute saisie. Il permet de
valider la chaîne de compilation, le responsive, l’installation et le
redémarrage hors ligne sans utiliser un stockage en clair, temporaire ou non
récupérable. Dans Safari iPhone, l’aide reprend le flux système actuel :
`Partager` ou `Plus`, `Sur l’écran d’accueil`, `Ouvrir comme app web`, puis
`Ajouter`. Les constats du prototype sont suivis dans
[`docs/web-storage-prototype.md`](web-storage-prototype.md).

Le prototype utilise Chrome pour le développement local, puis Safari sur un
iPhone réel pour valider installation, redémarrage, mise à jour et hors-ligne.
Une inspection WebKit approfondie pourra nécessiter ponctuellement un Mac, mais
ni la construction ni la publication de la PWA ne dépendent du programme
développeur Apple.

La version iOS native est hors du périmètre initial. Le squelette généré reste
dans le dépôt afin de ne pas rendre une future reprise destructive.

## Commandes du dépôt

Depuis la racine :

```shell
flutter pub get
dart run tool/check.dart
```

La commande de contrôle vérifie le formatage, l’analyse statique et les tests de
tous les membres du workspace. Les packages métier restent testables sans
import Flutter.

Le code Drift et l’instantané du schéma chiffré sont maintenus depuis le
package de stockage :

```shell
cd packages/reboot_storage
dart run build_runner build
dart run drift_dev make-migrations
```

Après une modification de Drift, de `sqlite3` ou de la configuration des hooks,
construire aussi l’application Android afin de vérifier l’intégration du moteur
natif SQLite3MultipleCiphers :

```shell
cd apps/reboot_app
flutter build apk --debug
```

La sortie JavaScript compatible Safari iPhone doit également continuer à
compiler, même si le shell interdit encore les saisies. La commande dédiée
construit les ressources sans CDN, calcule la version du shell hors ligne et
génère le service worker REBOOT :

```shell
cd apps/reboot_app
dart run tool/build_web_release.dart
```

Ne pas publier directement la sortie d'un simple `flutter build web` : elle ne
contient pas le manifeste exact et atomique du shell hors ligne. Le cache PWA
ne contient que les ressources statiques listées par cette commande, jamais le
journal, les clés ou les données financières locales.

## Politique de dépendances

- utiliser la dernière version stable compatible au moment de l’ajout ;
- versionner le lockfile racine ;
- ne pas utiliser de préversion sans justification documentée ;
- examiner le changelog, la maintenance, la licence et les avis de sécurité ;
- tester Android après toute mise à niveau native et le Web après toute mise à
  niveau affectant Flutter Web, Wasm ou le service worker ;
- ne jamais fusionner automatiquement une mise à niveau majeure.

Les versions mentionnées dans un ADR décrivent l’état étudié au moment de la
décision. Le lockfile décrit exactement ce qui est construit.
