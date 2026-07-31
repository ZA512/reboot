# ADR-0008 — Distribution Android et Web/PWA

- Statut : Accepted
- Date : 2026-08-01
- Accepté le : 2026-08-01
- Décideurs : porteur du projet et responsable de l’implémentation REBOOT

## Contexte

REBOOT doit valider sa méthode sur iPhone sans imposer immédiatement un Mac,
le programme développeur Apple, TestFlight ou l’App Store. Le produit local
Android est déjà en cours d’implémentation avec une base SQLite chiffrée.

Flutter permet de réutiliser l’interface et les packages métier sur le Web,
mais le navigateur ne fournit ni Android Keystore ni le même moteur SQLite
natif. Flutter ne génère par ailleurs plus de service worker applicatif par
défaut. Présenter un simple build Web comme une PWA locale, hors ligne et sûre
serait donc incorrect.

## Décision

### Plateformes

Le périmètre initial devient :

- application Flutter native Android, plateforme de développement prioritaire ;
- application Flutter Web pour ordinateur et mobile ;
- PWA installable sur iPhone, utilisable aussi dans Safari sans installation ;
- PWA installable sur Android lorsque l’utilisateur le souhaite.

La version iOS native, TestFlight et l’App Store sortent du périmètre initial.
Le squelette iOS existant peut être conservé pour une réévaluation future,
mais il ne constitue pas une cible livrée ou testée.

### Frontière de persistance

Le port commun est le `LocalEventJournal` déjà défini par
`reboot_application`. Le domaine et les projections ne connaissent aucune
technologie de stockage.

```text
LocalEventJournal
├── journal SQLite chiffré       Android
└── journal Web chiffré          Web/PWA
```

L’adaptateur Web fera l’objet d’un prototype avant choix définitif. L’option
préférée à évaluer est Drift avec SQLite WebAssembly, OPFS lorsque disponible
et IndexedDB comme solution de repli, afin de réutiliser le schéma et les
migrations. Un adaptateur IndexedDB direct reste possible si le prototype
montre que la pile SQLite Web ne satisfait pas la compatibilité, le chiffrement
ou les performances.

L’ADR-0005 reste la décision applicable au stockage Android. Il ne s’applique
pas implicitement au navigateur.

### Sécurité du navigateur

Aucune donnée financière réelle ne sera confiée à la PWA avant validation de :

- son chiffrement local avant persistance ;
- la création, la conservation et la récupération de ses clés ;
- sa politique face à l’effacement du stockage par le navigateur ;
- l’isolation contre XSS, dépendances compromises et cache empoisonné ;
- ses en-têtes de sécurité et sa politique de contenu ;
- l’absence de données, secrets et jetons OAuth dans les caches et journaux.

Le stockage du navigateur n’est jamais présenté comme une sauvegarde fiable.
Le mode partagé PWA exigera une copie distante chiffrée et récupérable avant
d’être considéré prêt à livrer. L’ADR-0006 reste applicable au protocole de
partage, mais la garde locale des clés Web nécessite une décision dédiée.

### Hors ligne et mises à jour

La PWA dispose d’un service worker maintenu par REBOOT ou par un outil standard
explicitement configuré. Il met en cache uniquement le shell versionné de
l’application, permet son démarrage hors ligne et propose une mise à jour sans
interrompre une saisie.

Une dépense est toujours écrite localement et réduit immédiatement le restant.
La future synchronisation conserve explicitement les états `local en attente`,
`synchronisé` et `échec de synchronisation`. La synchronisation en arrière-plan
sur iPhone n’est jamais supposée fiable ; lancement, retour au premier plan,
écriture et actualisation manuelle sont les déclencheurs garantis par le
produit.

### Distribution et compatibilité

La PWA est servie en HTTPS comme application statique. L’hébergeur ne reçoit et
ne conserve aucune donnée métier. Le fournisseur sera choisi après validation
des en-têtes de sécurité, des déploiements atomiques, des retours arrière et de
la politique de cache.

Le manifeste possède au minimum un identifiant stable, un nom, des icônes, les
couleurs, une URL de démarrage, une portée et le mode `standalone`. Une aide
explique l’ajout à l’écran d’accueil sur iPhone sans présenter la PWA comme une
application native.

Les versions minimales de Safari iPhone, Chrome Android, Chrome/Edge desktop et
Firefox desktop seront fixées après le prototype. Les essais automatiques Web
ne remplacent pas une validation manuelle sur un iPhone réel.

## Ordre d’implémentation

1. poursuivre le produit local Android et ses règles métier ;
2. rendre la racine de composition indépendante de `dart:io` et des plugins
   uniquement natifs ;
3. prototyper stockage Web, chiffrement, garde des clés et effacement ;
4. ajouter le manifeste et le service worker contrôlé ;
5. valider installation, redémarrage et usage hors ligne sur iPhone réel ;
6. ajouter le partage chiffré après l’ADR de synchronisation.

## Options étudiées

### Application iOS native dès le MVP

Écartée pour la phase initiale : coût et chaîne de publication avant validation
de la méthode. Elle reste compatible avec l’architecture commune.

### Simple site Web connecté

Écarté : il contredirait les propriétés local-first, hors ligne et sans serveur
métier de REBOOT.

### PWA utilisant le stockage Web sans chiffrement validé

Écartée : la simplicité de publication ne justifie pas une protection plus
faible de données financières.

### Android natif et PWA local-first

Retenue : elle maximise la réutilisation du domaine tout en gardant des
adaptateurs et des garanties explicites par plateforme.

## Conséquences

### Positives

- accès initial à l’iPhone sans publication App Store ;
- une base Flutter et un domaine communs ;
- validation plus rapide de la méthode REBOOT ;
- version Web disponible aussi sur ordinateur ;
- aucune dépendance à un serveur métier de l’éditeur.

### Négatives

- deux modèles locaux de stockage et de garde des clés à maintenir ;
- service worker, caches et sécurité Web à concevoir explicitement ;
- synchronisation de fond et stockage moins prévisibles sur iPhone ;
- certaines capacités natives resteront Android seulement ;
- validation WebKit sur appareil réel indispensable.

## Conditions d’acceptation

- Android conserve sa base chiffrée et son fonctionnement actuel ;
- le même journal métier peut être rejoué sur Android et Web ;
- aucune dépendance Web ne remonte dans les packages métier purs ;
- la PWA s’installe et démarre hors ligne après un premier chargement ;
- une dépense hors ligne réduit immédiatement le restant ;
- une mise à jour n’interrompt pas une saisie ;
- l’effacement du stockage et la récupération sont testés et expliqués ;
- aucune donnée métier, clé ou jeton n’est mis en cache en clair ;
- les objectifs de performance sont validés sur 300 000 enregistrements ;
- le mode partagé n’est livré qu’avec sauvegarde distante chiffrée.

## Liens

- PRD REBOOT 2.1 : sections 17 à 25.
- ADR liés : ADR-0001, ADR-0004, ADR-0005 et ADR-0006.
- Flutter : [FAQ Web](https://docs.flutter.dev/platform-integration/web/faq).
- Drift : [Web](https://drift.simonbinder.eu/platforms/web/).
- WebKit : [Web Push for Web Apps on iOS and iPadOS](https://webkit.org/blog/13878/web-push-for-web-apps-on-ios-and-ipados/).
