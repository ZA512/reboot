# Archive de récupération portable — prototype RBP1

- Statut : format commun Android/Web et portail navigateur testés, interface
  Web non activée
- Date : 2026-08-02

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

Le format est désormais commun à Android et à la PWA. Un même vecteur
déterministe est chiffré par AES-GCM natif côté Android et par Web Crypto dans
Chrome ; les deux archives ont exactement la même empreinte SHA-256. Android
continue aussi de restaurer les anciennes archives SQLite chiffrées `RB1`, mais
n’en produit plus.

Le téléchargement et le sélecteur de fichier sont implémentés et testés dans
Chrome, avec une limite de 64 Mio et une seule opération à la fois. Ils ne sont
pas encore exposés dans le shell Flutter. La préparation et le téléchargement
sont volontairement deux étapes : le clic final reste ainsi un geste
utilisateur direct, condition importante sur les navigateurs mobiles stricts.

L’API Clipboard Web exige un contexte sécurisé mais ne sait pas demander au
système de masquer les aperçus, contrairement à l’intégration Android. Le futur
écran devra l’expliquer et laisser le code affiché pour une copie manuelle.
L’ergonomie Web finale et les essais Safari iPhone restent à réaliser avant
activation.
