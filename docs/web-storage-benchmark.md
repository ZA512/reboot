# Benchmark du journal Web chiffré

- Date : 2026-08-01
- Statut : mesure de prototype, hors CI quotidienne
- Volume : 300 000 événements chiffrés et authentifiés

## Environnement de référence

- Windows 11 Entreprise ;
- Intel Core i7-1365U, 10 cœurs et 12 processeurs logiques ;
- 31,7 Gio de mémoire physique ;
- Chrome 150.0.7871.182 en mode headless ;
- Flutter 3.44.8 et Dart 3.12.2 ;
- stockage temporaire Chrome classé `best effort`.

Chaque événement possède un UUID distinct et un payload JSON synthétique de
157 octets. Le chemin mesuré inclut la génération du nonce, AES-256-GCM,
WebCrypto, les contrôles d’idempotence, la transaction IndexedDB atomique,
la fermeture et la réouverture de la base, puis l’authentification et le
déchiffrement de tout le journal.

## Résultat retenu

| Mesure | Résultat |
| --- | ---: |
| Écriture totale de 300 000 événements | 994 970 ms (16 min 35,0 s) |
| Débit moyen d’écriture | 301,5 événements/s |
| Écriture p50 | 2,8 ms |
| Écriture p95 | 5,9 ms |
| Écriture p99 | 8,8 ms |
| Écriture maximale observée | 313,3 ms |
| Écriture du snapshot chiffré de 262 228 octets | 57,1 ms |
| Réouverture de la base et de la clé | 4 ms |
| Snapshot puis rejeu authentifié de 100 événements | 69 ms |
| Rejeu du suffixe seul | 32 ms |
| Rejeu complet authentifié | 34 025 ms |
| Débit moyen de rejeu complet | 8 817,0 événements/s |
| Occupation estimée de l’origine | 149 925 938 octets |

La variation du quota et de l’occupation estimés dépend du profil temporaire et
du navigateur. Ces valeurs ne sont pas des tailles de fichier contractuelles.
Les passages précédents ont mesuré de 19,5 à 34,0 secondes pour le rejeu
complet : ces résultats locaux sont des ordres de grandeur, pas des garanties
matérielles.

## Expérience rejetée

Un second passage a déchiffré par lots bornés de 128 opérations WebCrypto. Il a
porté le rejeu à 29 017 ms, soit une dégradation de 48,8 %. Cette optimisation
a été retirée. WebCrypto et IndexedDB ne doivent pas être supposés plus rapides
par simple parallélisation.

## Conclusion d’architecture

Le journal direct satisfait largement la cible de retour visuel de 100 ms pour
une saisie courante : son p95 de persistance est de 5,9 ms sur cette machine.
Le test prouve aussi que 300 000 enveloppes restent stockables, ordonnées,
authentifiables et déchiffrables.

En revanche, 19,5 à 34,0 secondes interdisent de reconstruire systématiquement
toutes les projections avant d’afficher le tableau de bord. Le prototype v2
ajoute donc un snapshot chiffré, versionné et supprimable, lié à une position
exacte du journal. Avec un snapshot synthétique de 262 228 octets à la position
299 900, sa restauration et le rejeu des 100 événements suivants prennent 69 ms.
Cette preuve satisfait la cible de 300 ms sur la machine de référence.

Le journal reste l’unique source de vérité. Une corruption du snapshot provoque
sa suppression, jamais la perte ou la réécriture du journal. Le mécanisme est
validé, mais le JSON synthétique doit encore être remplacé par un codec versionné
des vraies projections REBOOT avant activation de la PWA.

Cette mesure sur ordinateur ne remplace pas le benchmark Safari sur un iPhone
réel. Les performances d’import en masse devront aussi être mesurées avec une
future primitive atomique par lot.

## Reproduction

Depuis la racine du dépôt :

```powershell
dart test -p chrome -r expanded apps/reboot_app/benchmark/browser_encrypted_journal_benchmark_test.dart
```

Le test supprime automatiquement la base et son marqueur après la mesure.
