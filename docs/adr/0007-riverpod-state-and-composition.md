# ADR-0007 — État Flutter et racine de composition

- Statut : Accepted
- Date : 2026-07-31
- Accepté le : 2026-07-31
- Décideur : responsable de l’implémentation REBOOT

## Contexte

Le domaine, les projections, les cas d’usage et le stockage chiffré sont des
packages Dart indépendants de Flutter. L’application mobile doit maintenant :

- ouvrir de façon asynchrone le coffre de secrets et la base locale ;
- exposer des états explicites de chargement, verrouillage, onboarding et
  fonctionnement normal ;
- injecter les adaptateurs plateforme sans créer de singleton global ;
- reconstruire l’interface après chaque commande acceptée ;
- rester testable sans Keystore, Keychain, SQLite ou horloge réels ;
- ne déplacer aucune règle financière dans les widgets ou les providers.

## Décision

### Bibliothèque

Utiliser `flutter_riverpod` 3.x, verrouillé par le lockfile. La version stable
examinée lors de la décision est 3.4.2.

Utiliser les API modernes `Provider`, `FutureProvider`, `Notifier` et
`AsyncNotifier`. Ne pas utiliser les API `legacy`, `StateNotifier`, un service
locator global ou des singletons mutables.

Ne pas introduire `riverpod_generator` au premier écran. Les providers manuels
sont peu nombreux, explicites et évitent une seconde chaîne de génération.
Cette décision pourra être réévaluée si le graphe devient suffisamment grand
pour que la génération réduise réellement le risque.

### Responsabilités

La racine `ProviderScope` ne contient que la composition technique. Les
providers peuvent :

- obtenir les répertoires privés de l’application ;
- accéder au coffre de secrets plateforme ;
- ouvrir puis fermer le journal chiffré ;
- construire `LocalRebootService` ;
- traduire ses résultats immuables en états de présentation ;
- coordonner chargement, nouvelle tentative et commandes utilisateur.

Ils ne peuvent pas :

- calculer un budget, un cycle, un arrondi ou une tendance ;
- fabriquer directement des événements métier ;
- exécuter du SQL ;
- persister un état Riverpod comme source de vérité ;
- transformer silencieusement une erreur de clé en nouveau profil.

Le journal reste la seule source de vérité. Un redémarrage reconstruit l’état
par rejeu via `LocalRebootService`.

### Cycle de vie

- L’ouverture du profil est représentée par un état asynchrone.
- Le service local n’est rendu aux contrôleurs qu’après ouverture complète du
  coffre, validation de la clé, ouverture chiffrée et rejeu.
- Le service possède exclusivement sa connexion et est fermé lors de la
  destruction du conteneur.
- Les commandes métier restent sérialisées par `LocalRebootService`.
- Une commande réussie publie un nouvel instantané immuable.
- Une erreur affiche un état expurgé et conserve la possibilité de réessayer.
- Une erreur Keystore, Keychain ou clé manquante avec base existante verrouille
  le profil ; elle ne supprime ni secret ni fichier.

### Navigation

Utiliser le `Navigator` Flutter standard pour les premiers écrans linéaires.
Ne pas ajouter de routeur tiers avant l’apparition d’un besoin concret de liens
profonds, navigation web ou graphes imbriqués.

### Tests

Les tests remplacent les providers de frontière par des doubles : coffre de
secrets, répertoire privé, journal, horloge et identités. Ils couvrent les
états de chargement, profil neuf, profil existant, profil verrouillé, commande
réussie, erreur et nouvelle tentative.

Les tests des widgets ne recréent aucune formule. Ils vérifient uniquement la
présentation d’un état déjà calculé et l’envoi de commandes typées.

## Options étudiées

### `setState` et `InheritedWidget` uniquement

Adapté à un prototype très court, mais la composition asynchrone et les
remplacements de frontières en test produiraient rapidement du code maison.

### Provider classique

Stable et simple, mais moins adapté aux états asynchrones structurés et aux
contrôleurs testables sans `BuildContext`.

### BLoC

Très explicite pour les flux d’événements, mais ajouterait beaucoup de classes
et de cérémonial autour d’un service applicatif qui sérialise déjà les
commandes et produit des projections immuables.

### Riverpod

Retenu pour la composition sans `BuildContext`, les overrides de test, le cycle
de vie, les états asynchrones et la sélection fine des données observées.

## Conséquences

### Positives

- démarrage et erreurs plateforme modélisés explicitement ;
- frontières remplaçables dans les tests ;
- widgets indépendants de SQLite et du coffre de secrets ;
- aucune duplication du moteur métier ;
- évolution possible vers plusieurs contrôleurs sans service locator.

### Négatives

- dépendance supplémentaire propre à Flutter ;
- apprentissage des cycles de vie Riverpod ;
- nécessité de surveiller les changements d’API majeurs ;
- discipline requise pour empêcher les providers de devenir une seconde
  couche métier.

## Conditions d’acceptation

- aucun package Dart métier ne dépend de Riverpod ou Flutter ;
- le profil local peut être ouvert avec des frontières réelles ou simulées ;
- une clé absente avec une base existante ne crée jamais un nouveau profil ;
- les providers sont remplaçables dans les tests ;
- la fermeture libère la connexion locale ;
- aucun calcul financier n’existe dans un widget ou provider ;
- chargement, erreur verrouillée, onboarding et état prêt sont distincts.

## Liens

- PRD REBOOT 2.0 : sections 2.5, 18, 19 et 20.
- ADR liés : ADR-0004, ADR-0005 et ADR-0006.
- Riverpod : [documentation](https://riverpod.dev/) et
  [package Flutter](https://pub.dev/packages/flutter_riverpod).
