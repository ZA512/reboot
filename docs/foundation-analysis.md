# Analyse de fondation du PRD

- Date : 2026-07-29
- Document analysé : `docs/PRD.md`
- Portée : préparation de la Phase 0
- Statut : base de discussion, aucune décision implicite

## Conclusion

Le PRD est suffisamment précis pour commencer les fondations du domaine, mais pas encore pour générer tout le workspace ni choisir les bibliothèques structurantes. Trois décisions affectent directement le premier code : l’existence du journal d’événements dès le MVP local, la définition exacte d’un cycle civil et les règles monétaires.

Les trois ADR associés restent au statut `Proposed`.

## Points bloquants avant le premier code métier

| ID | Sections | Constat | Risque | Traitement proposé |
|---|---|---|---|---|
| FND-01 | 18.4, 21.2, 30, 36 | Les agrégats doivent être reconstruisibles depuis le journal et le passage au partage doit convertir les données, mais le journal n’arrive qu’en Phase 2, après le produit local. | Refonte du stockage et migration risquée après le MVP local. | ADR-0001 : journal local dès la première mutation, synchronisation ajoutée plus tard. |
| FND-02 | 2.1, 7.1, 29.1, 33 | Un cycle dure sept dates civiles, mais une heure d’ancrage configurable est aussi prévue. Avec une heure différente de minuit, ces deux définitions divergent. | Affectation différente d’une dépense selon l’heure, le fuseau ou un changement d’heure. | ADR-0002 : cycle fondé sur des dates locales et ancrage à 00:00 pour le MVP. |
| FND-03 | 8, 11, 12, 32.1 | Les centimes entiers sont imposés, mais les conventions de signe, la gestion des restes de division, les capacités négatives et le multi-devise ne sont pas définis. | Centimes perdus, arrondis incohérents et doubles interprétations. | ADR-0003 : type monétaire, signes, arrondis et répartition exacte. |
| FND-04 | 20.4 | La révocation doit empêcher l’accès futur, alors que la rotation de la clé du foyer est seulement optionnelle. Un appareil révoqué qui conserve l’accès Drive et l’ancienne clé peut lire les nouveaux objets. | Violation d’une propriété de sécurité explicite. | Rendre obligatoire une nouvelle époque de clé après révocation et retirer l’accès au stockage distant. ADR de sécurité dédié avant le partage. |
| FND-05 | 36 | La Phase 0 demande de créer les packages avant d’écrire les ADR, alors que le choix de l’outillage du workspace influence ces packages. | Structure créée puis immédiatement remaniée. | Passer les ADR de workspace, domaine et stockage avant la génération des packages. |

## Clarifications produit nécessaires

| ID | Sections | Point à clarifier | Recommandation |
|---|---|---|---|
| PRD-01 | en-tête, nom du fichier | Le fichier reçu porte `v1.1`, tandis que son contenu annonce la version 1.0. | Publier une version documentaire suivante avec un numéro unique. |
| PRD-02 | 39 | Le PRD conserve Budget52 comme nom de travail alors que le projet est désormais nommé REBOOT. | Employer REBOOT comme nom produit et décider séparément de l’identifiant technique avant création des applications. |
| PRD-03 | 6.3, 35, 36 | L’onboarding présente l’import dès le départ alors que l’import n’existe qu’au MVP 3 / Phase 4. | Masquer ce parcours derrière une capacité de version jusqu’à sa disponibilité réelle. |
| PRD-04 | 8.1 | L’horizon commence au cycle courant « ou suivant selon le contexte ». | Définir séparément la projection de soutenabilité et la recommandation applicable au prochain cycle. |
| PRD-05 | 8.4, 26 | Les marges 2 %, 5 % et 10 % utilisent « données complètes », « moyen » et « faible », tandis que le niveau de confiance comporte faible, moyen, bon et élevé. | Définir une table de correspondance exhaustive. |
| PRD-06 | 9.2 | Pour 6 à 11 mois, la ligne « confiance maximale : moyenne » ne correspond à aucune méthode proposée et répète la moyenne. | Corriger ou supprimer cette ligne dans le PRD. |
| PRD-07 | 11.2, 12.4 | Une échéance dans le cycle courant peut produire zéro cycle restant. | Définir un minimum d’un cycle ou un rattrapage immédiat hors division. |
| PRD-08 | 12.2 | La formule ajoute `autres_bénéficiaires` sans préciser s’il s’agit d’un nombre ou d’un montant. | Ajouter nombre, budget anniversaire et budget Noël, ou demander directement un montant global. |
| PRD-09 | 6.1 | La réduction d’une enveloppe synthétique suppose des montants de même période. | Normaliser chaque charge sur le même horizon avant de réduire le résiduel. |
| PRD-10 | 11, 12 | Vacances, entretien automobile, Noël et anniversaires peuvent être saisis comme dépense irrégulière ou réserve cyclique. | Définir une entité canonique ou une règle d’exclusivité contrôlée. |
| PRD-11 | 16 | Les états de tendance se chevauchent et ne couvrent pas tous les cas ; leur priorité n’est pas définie. | Construire une table de décision exclusive et définir « tendance positive/négative ». |
| PRD-12 | 7, 10, 29 | Plusieurs devises sont modélisées, mais aucun taux de change ni date de conversion n’est défini. | Limiter le MVP à la devise du foyer et refuser les calculs croisés. |
| PRD-13 | 21 | Le mode solo contient déjà un foyer dans le modèle, mais le passage au partage « crée un foyer chiffré ». | Distinguer foyer local et coffre partagé, sans recréer l’identité métier. |
| PRD-14 | 19.5 | Le scope Drive minimal dépend du mode : espace privé applicatif et dossier partagé n’offrent pas les mêmes propriétés. | Documenter les scopes et flux OAuth par mode dans l’ADR de synchronisation. |

## Backlog d’ADR

Ordre recommandé :

1. ADR-0001 — Journal local dès le MVP.
2. ADR-0002 — Cycles hebdomadaires en dates civiles locales.
3. ADR-0003 — Représentation monétaire et arrondis.
4. ADR-0004 — Workspace Flutter/Dart et outillage monorepo.
5. ADR-0005 — Gestion d’état et injection de dépendances.
6. ADR-0006 — SQLite chiffrée, migrations et sauvegarde locale.
7. ADR-0007 — Clés, époques, révocation et récupération.
8. ADR-0008 — Modèle de synchronisation et résolution des conflits.
9. ADR-0009 — Format d’export chiffré et portabilité.
10. ADR-0010 — Import, conventions de signe et déduplication.

## Ordre de travail révisé proposé

1. valider les trois ADR de domaine ;
2. choisir l’outillage du workspace dans ADR-0004 ;
3. générer les packages minimaux ;
4. implémenter `Money` et ses tests ;
5. implémenter le moteur de cycles et ses tests de changement d’heure ;
6. définir les événements locaux minimaux ;
7. implémenter le moteur de projection pur ;
8. seulement ensuite commencer l’application Flutter.
