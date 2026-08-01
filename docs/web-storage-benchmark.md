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
| Écriture totale de 300 000 événements | 909 583 ms (15 min 9,6 s) |
| Débit moyen d’écriture | 329,8 événements/s |
| Écriture p50 | 2,8 ms |
| Écriture p95 | 4,4 ms |
| Écriture p99 | 6,7 ms |
| Écriture maximale observée | 324,3 ms |
| Réouverture de la base et de la clé | 2 ms |
| Rejeu complet authentifié | 19 495 ms |
| Débit moyen de rejeu | 15 388,6 événements/s |
| Occupation estimée de l’origine | 160 387 549 octets |

La variation du quota et de l’occupation estimés dépend du profil temporaire et
du navigateur. Ces valeurs ne sont pas des tailles de fichier contractuelles.

## Expérience rejetée

Un second passage a déchiffré par lots bornés de 128 opérations WebCrypto. Il a
porté le rejeu à 29 017 ms, soit une dégradation de 48,8 %. Cette optimisation
a été retirée. WebCrypto et IndexedDB ne doivent pas être supposés plus rapides
par simple parallélisation.

## Conclusion d’architecture

Le journal direct satisfait largement la cible de retour visuel de 100 ms pour
une saisie courante : son p95 de persistance est de 4,4 ms sur cette machine.
Le test prouve aussi que 300 000 enveloppes restent stockables, ordonnées,
authentifiables et déchiffrables.

En revanche, 19,5 secondes interdisent de reconstruire systématiquement toutes
les projections avant d’afficher le tableau de bord. L’activation de la PWA
exige donc un snapshot ou cache de projection chiffré, versionné et supprimable,
lié à une position exacte du journal. Le journal reste l’unique source de vérité
et le suffixe postérieur au snapshot doit toujours être rejoué. Une corruption
ou une version inconnue du cache provoque sa reconstruction, jamais la perte ou
la réécriture du journal.

Cette mesure sur ordinateur ne remplace pas le benchmark Safari sur un iPhone
réel. Les performances d’import en masse devront aussi être mesurées avec une
future primitive atomique par lot.

## Reproduction

Depuis la racine du dépôt :

```powershell
dart test -p chrome -r expanded apps/reboot_app/benchmark/browser_encrypted_journal_benchmark_test.dart
```

Le test supprime automatiquement la base et son marqueur après la mesure.
