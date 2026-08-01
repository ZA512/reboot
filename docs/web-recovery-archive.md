# Archive de récupération portable — prototype RBP1

- Statut : cœur cryptographique testé, interface fichier non branchée
- Date : 2026-08-01

`RBP1` sépare volontairement la sauvegarde de la clé locale non extractible.
Chaque export génère 256 bits aléatoires, affiche leur représentation sous
forme de code à conserver séparément, puis chiffre en AES-256-GCM une liste
ordonnée des événements canoniques complets.

L’enveloppe JSON publique contient uniquement la version, l’algorithme, le type
de document, un nonce aléatoire de 96 bits et le ciphertext base64url. Ces trois
premiers champs sont authentifiés comme données associées. La limite d’entrée
est fixée à 64 Mio et le nombre d’événements à un million.

La restauration suit cet ordre :

1. contrôler strictement l’enveloppe et le code `RBP1` ;
2. authentifier et déchiffrer l’archive entière ;
3. décoder chaque `EventRecord` canonique et refuser tout UUID dupliqué ;
4. rejouer toutes les projections REBOOT dans un journal éphémère en lecture
   seule ;
5. importer le lot complet uniquement dans un profil encore vide.

Une erreur ne transporte ni donnée financière ni clé. Les copies temporaires
de la clé et du plaintext sont écrasées au mieux dans les limites du runtime
JavaScript ; le code affiché reste naturellement un secret persistant.

Le format est conçu pour devenir commun à Android et à la PWA, mais Android
utilise encore son archive SQLite chiffrée `RB1`. La compatibilité croisée, le
téléchargement, le sélecteur de fichier, l’ergonomie de conservation du code et
les essais Safari iPhone restent à réaliser avant activation.
