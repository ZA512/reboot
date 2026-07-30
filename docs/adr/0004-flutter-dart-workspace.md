# ADR-0004 — Workspace Flutter/Dart et outillage monorepo

- Statut : Proposed
- Date : 2026-07-31
- Décideur : porteur du projet REBOOT

## Contexte

REBOOT doit fournir une application Flutter pour Android et iOS tout en
conservant :

- un domaine indépendant de Flutter ;
- un moteur de projection pur et testable sans interface ;
- les formules financières hors des widgets ;
- une séparation nette entre le métier, le stockage local et les futurs
  transports de synchronisation.

Le dépôt ne contient encore aucun SDK, package ou code applicatif. Le
découpage initial doit donc rendre ces frontières visibles sans créer dès le
départ un package pour chaque écran, fonctionnalité ou technologie future.

Depuis Dart 3.6, `pub` prend nativement en charge les workspaces, leur
résolution de dépendances commune et un lockfile unique. Un orchestrateur
monorepo tiers n’est pas nécessaire pour obtenir ces propriétés.

## Décision proposée

### Workspace natif

Utiliser un workspace `pub` natif à la racine du dépôt.

- Le `pubspec.yaml` racine est privé avec `publish_to: none`.
- Il énumère explicitement chaque membre du workspace.
- Chaque membre déclare `resolution: workspace` et `publish_to: none`.
- Un unique `pubspec.lock`, situé à la racine, est versionné.
- Aucun lockfile propre à un membre n’est conservé.
- Melos n’est pas ajouté au démarrage.

Les chemins restent explicites plutôt que découverts par glob. L’ajout d’un
package constitue ainsi une modification volontaire et relisible.

### Topologie initiale

Créer uniquement les quatre membres suivants après acceptation de cet ADR :

```text
apps/
  reboot_app/                 application Flutter Android/iOS
packages/
  reboot_domain/              valeurs, règles et événements métier
  reboot_projection/          calculs et projections purs
  reboot_application/         commandes, cas d’usage et ports
```

Responsabilités :

- `reboot_domain` contient notamment les montants, cycles civils, identités,
  règles invariantes et événements métier. Il ne dépend d’aucun autre package
  REBOOT, de Flutter, du stockage, de l’horloge système ou du réseau.
- `reboot_projection` transforme des données et événements du domaine en
  projections déterministes. Il dépend uniquement de `reboot_domain` et de
  bibliothèques Dart sans effet de bord.
- `reboot_application` orchestre les commandes et cas d’usage autour de ports
  abstraits. Il dépend de `reboot_domain` et `reboot_projection`, mais pas de
  Flutter ni d’une implémentation SQLite, Drive ou bancaire.
- `reboot_app` contient l’interface Flutter, la navigation et la racine de
  composition. Il appelle la couche application et assemble les futures
  implémentations techniques.

La direction autorisée au départ est :

```text
reboot_app
    |
    v
reboot_application ---> reboot_projection
          |                      |
          +----------------------+
                     |
                     v
               reboot_domain
```

Une dépendance inverse ou cyclique est interdite. Le code d’un package n’importe
pas directement un fichier `lib/src` appartenant à un autre package.

### Packages différés

Les packages techniques comme `reboot_storage`, `reboot_sync` ou
`reboot_import` ne sont créés qu’après la décision d’architecture correspondante
et lorsqu’un premier code réel doit y vivre.

Un nouveau package doit matérialiser au moins une frontière parmi les suivantes :

- indépendance vis-à-vis de Flutter ;
- isolation d’un effet de bord ou d’une plateforme ;
- API réutilisée par plusieurs membres ;
- cycle de test ou de livraison réellement distinct.

Une catégorie métier, un écran ou un dossier interne ne justifie pas à lui seul
un package supplémentaire.

### SDK et reproductibilité

- Utiliser le canal Flutter `stable`.
- Au bootstrap, choisir une version stable précise compatible avec le workspace
  `pub`, puis enregistrer cette version dans la documentation de développement
  et dans la configuration d’intégration continue.
- Employer la même version localement et en intégration continue.
- Mettre à niveau Flutter/Dart par une modification dédiée, avec analyse et
  tests complets ; ne pas suivre implicitement la dernière version publiée.
- Garder des contraintes SDK cohérentes dans tous les membres.

Aucun gestionnaire de versions Flutter tiers n’est imposé initialement. Cette
décision pourra être revue si l’installation manuelle de la version convenue
devient une source répétée d’erreurs.

### Analyse, formatage et tests

- Utiliser les règles recommandées officiellement pour Dart et Flutter comme
  base, avec des exceptions documentées et limitées.
- Fournir une commande Dart multiplateforme au niveau du dépôt pour vérifier le
  formatage, lancer l’analyse statique et exécuter les tests de tous les
  membres.
- Exécuter la même commande en intégration continue.
- Tester `reboot_domain`, `reboot_projection` et `reboot_application` avec
  `dart test` sans démarrer Flutter.
- Réserver `flutter test` aux tests qui ont réellement besoin du framework.
- Refuser toute formule financière dans `reboot_app`.

La sélection de la solution d’intégration continue, de la gestion d’état et de
l’injection de dépendances ne fait pas partie de cet ADR.

## Options étudiées

### Option A — Une seule application Flutter

Le démarrage paraît plus court, mais les frontières métier reposent uniquement
sur des conventions de dossiers. Les calculs, l’interface et le stockage
peuvent alors se coupler sans signal visible dans le graphe de dépendances.

### Option B — Workspace `pub` natif et quatre membres initiaux

Cette option rend les trois frontières logiques principales vérifiables, utilise
la résolution officielle de Dart et conserve un outillage réduit.

### Option C — Workspace géré par Melos

Melos apporte des scripts, filtres et exécutions parallèles utiles aux grands
monorepos. Pour quatre membres privés, il ajoute toutefois une dépendance et une
configuration avant qu’un besoin concret ne les justifie. Il pourra être
réévalué si le nombre de packages ou les tâches transverses rendent le script
Dart du dépôt insuffisant.

### Option D — Un package par sous-système prévu dans le PRD

Créer immédiatement des packages pour le stockage, le chiffrement, la
synchronisation, les imports, les widgets et chaque moteur rendrait le dépôt
impressionnant mais figerait des frontières encore ouvertes. Cette option est
écartée.

## Conséquences

### Positives

- le domaine et les projections restent exécutables sans Flutter ;
- un seul graphe de versions et un seul lockfile évitent les résolutions
  divergentes ;
- les dépendances rendent l’architecture partiellement vérifiable ;
- le dépôt reste léger et repose d’abord sur l’outillage officiel ;
- les futurs adaptateurs techniques peuvent être ajoutés sans déplacer les
  règles métier.

### Négatives

- quatre `pubspec.yaml` membres doivent rester cohérents ;
- certaines commandes doivent être orchestrées pour tous les membres ;
- la résolution unique peut révéler plus tôt des incompatibilités entre
  dépendances ;
- l’absence initiale de Melos laisse au dépôt la responsabilité de sa commande
  de vérification ;
- les frontières de packages ne remplacent pas les revues de code pour empêcher
  toute fuite de logique vers l’interface.

## Conditions d’acceptation

Après création du workspace :

- `pub get` depuis la racine produit un seul lockfile versionné ;
- aucun membre ne possède son propre lockfile ou sa propre résolution ;
- les trois packages non visuels s’analysent et se testent sans import Flutter ;
- le graphe des dépendances respecte la direction décidée ;
- une commande documentée vérifie formatage, analyse et tests de tout le dépôt ;
- l’application Flutter cible uniquement Android et iOS au démarrage ;
- aucun package différé n’est créé vide ;
- la version exacte de Flutter utilisée est documentée et identique en
  intégration continue.

## Hors périmètre

Cet ADR ne choisit pas :

- la gestion d’état ou l’injection de dépendances ;
- la bibliothèque SQLite, son chiffrement ou ses migrations ;
- les primitives cryptographiques et le stockage des clés ;
- le fournisseur de synchronisation ;
- les bibliothèques d’import bancaire ;
- la licence open source du dépôt.

## Liens

- PRD REBOOT 2.0 : sections 19, 21, 22 et 23.
- ADR liés : ADR-0001, ADR-0002 et ADR-0003.
- Documentation Dart :
  [Pub workspaces](https://dart.dev/tools/pub/workspaces).
- Documentation Flutter :
  [Developing packages and plugins](https://docs.flutter.dev/packages-and-plugins/developing-packages).
- Documentation Dart :
  [Linter rules](https://dart.dev/tools/linter-rules).
- Documentation Flutter :
  [Flutter SDK archive](https://docs.flutter.dev/install/archive).
