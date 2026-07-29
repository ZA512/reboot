# CONSIGNE DE LECTURE POUR CODEX

Ce document est la source de vérité du projet Budget52.

- Tout le contenu ci-dessous est destiné à Codex et aux agents de développement.
- Il ne contient pas de commentaires personnels adressés à l'utilisateur.
- Les formulations « doit », « ne doit pas », « obligatoire », « interdit » et « hors périmètre » sont normatives.
- Les exemples servent à préciser le comportement attendu et doivent être couverts par les tests lorsqu'ils décrivent un cas métier.
- Les éléments explicitement marqués « question ouverte » ne doivent pas être décidés implicitement par l'agent.
- Avant tout développement, Codex doit analyser le document, relever les contradictions éventuelles et proposer les ADR nécessaires.
- Codex ne doit pas tenter d'implémenter l'ensemble du produit en une seule passe. Il doit suivre l'ordre défini à la section 36.

---

# PRD — Budget52
## Pilote de reste à vivre hebdomadaire, local-first et chiffré

**Statut :** Spécification fonctionnelle et technique de référence  
**Audience principale :** Codex et agents de développement  
**Langue produit initiale :** français  
**Plateformes initiales :** Android et iOS  
**Nom de travail :** Budget52  
**Version du document :** 1.0  
**Date :** 29 juillet 2026

---

# 1. Objet du produit

Budget52 aide une personne, un couple ou un foyer à répondre en permanence à trois questions :

1. **Combien pouvons-nous encore dépenser pendant le cycle hebdomadaire en cours ?**
2. **Le budget hebdomadaire choisi est-il durable sur les 52 prochaines semaines ?**
3. **Notre situation financière réelle s’améliore-t-elle, se stabilise-t-elle ou se dégrade-t-elle ?**

Budget52 n’est pas une application de comptabilité générale.  
Budget52 n’a pas pour objectif principal de catégoriser chaque achat ni de produire des graphiques complexes sur le passé.

La promesse centrale est :

> **Calculer un budget hebdomadaire soutenable à partir des revenus, charges, provisions, réserves et objectifs du foyer, puis rendre ce budget utilisable au quotidien sans réflexion complexe.**

L’application doit privilégier la décision présente :

> **« Puis-je encore dépenser cette semaine ? »**

avant l’analyse historique :

> « Où est parti l’argent le mois dernier ? »

---

# 2. Principes fondateurs

## 2.1. Décorrélation entre mois et semaine

Le budget de consommation courante est géré par cycles fixes de sept jours.

L’utilisateur choisit le jour de début du cycle. L’onboarding doit lui conseiller de choisir le jour habituel des courses principales, car l’alimentation est une dépense vitale et doit être engagée au début du cycle, non conservée mentalement comme une contrainte de fin de semaine.

Exemple :

- début du cycle : samedi à 00:00 ;
- fin du cycle : vendredi à 23:59:59 ;
- nouveau budget disponible : chaque samedi.

La date de début est un **ancrage local**. Un cycle dure toujours sept dates civiles locales. Les changements d’heure ne doivent pas créer de cycle de six ou huit jours.

## 2.2. Une trajectoire annuelle, pas une obligation de clôture mensuelle positive

Le budget hebdomadaire soutenable est calculé sur les **52 prochaines semaines**.

Un mois civil peut contenir quatre ou cinq débuts de cycle. Un budget de 600 € par semaine produit donc :

- 2 400 € de budget sur un mois comportant quatre débuts de cycle ;
- 3 000 € sur un mois comportant cinq débuts de cycle ;
- 31 200 € sur 52 cycles ;
- environ 2 600 € par mois en moyenne annuelle.

Une fin de mois négative ne signifie pas automatiquement que la méthode échoue. Une fin de mois positive ne signifie pas automatiquement qu’elle réussit.

Le produit doit afficher séparément :

- **la soutenabilité sur 52 semaines** ;
- **la trésorerie bancaire à court terme** ;
- **l’adhérence au budget hebdomadaire**.

## 2.3. Les dépenses non consommées ne se reportent pas automatiquement

Par défaut, le reliquat d’un cycle n’augmente pas le budget du cycle suivant.

Exemple :

- budget du cycle : 600 € ;
- dépenses : 510 € ;
- reliquat : 90 € ;
- budget du cycle suivant : toujours 600 €, pas 690 €.

Le reliquat reste physiquement sur le compte bancaire. Il améliore la trajectoire, le découvert, la réserve de sécurité ou l’épargne réelle.

L’application peut proposer ultérieurement d’affecter un surplus confirmé à une réserve ou à un projet, mais uniquement après vérification de la trésorerie et sans modifier rétroactivement les cycles.

## 2.4. Séparer les concepts financiers

L’application doit distinguer strictement :

1. **Revenus**
2. **Charges programmées**
3. **Dépenses irrégulières provisionnées**
4. **Réserves permanentes**
5. **Projets temporaires**
6. **Dépenses du budget hebdomadaire**
7. **Transferts internes**
8. **Remboursements et annulations**
9. **Trésorerie bancaire**
10. **Objectifs de redressement ou d’épargne**

Cette séparation est obligatoire pour éviter le double comptage.

## 2.5. Local-first

La base locale est la source utilisée par l’interface.

L’application doit rester utilisable :

- sans compte ;
- sans connexion Internet ;
- sans synchronisation bancaire ;
- sans service serveur administré par l’éditeur.

La synchronisation distante est une option de sauvegarde et de partage. Elle ne doit pas être indispensable au fonctionnement local.

---

# 3. Doctrine UX/UI

Les règles suivantes sont normatives.

## 3.1. Simplification sans suppression d’information

Ne jamais confondre simplification et suppression d’information.

Une information métier, technique, juridique ou nécessaire à l’audit ne doit pas disparaître. Elle peut être déplacée vers un niveau secondaire, un écran de détail, un panneau extensible ou un journal.

## 3.2. Centre de gravité clair

Chaque page doit avoir un centre de gravité clair.

Il ne doit normalement y avoir qu’une seule action principale visuellement dominante à un instant donné.

Sur l’écran principal, cette action est :

> **Ajouter une dépense**

## 3.3. Le statut ne concurrence pas l’action

Les informations d’état servent à comprendre la situation. Elles ne doivent pas concurrencer l’action à effectuer.

Le montant restant cette semaine est dominant. Les détails du calcul, les charges et les historiques sont secondaires.

## 3.4. Éviter les répétitions

Une information ne doit pas être répétée sous plusieurs formes ou dans plusieurs cartes, sauf justification fonctionnelle explicite.

## 3.5. Diminution visuelle des éléments terminés

Les étapes terminées, charges rapprochées et opérations validées restent accessibles pour la traçabilité, mais perdent progressivement en importance visuelle.

## 3.6. Concevoir pour l’utilisateur régulier

L’aide d’apprentissage doit être disponible à la demande, mais ne doit pas encombrer durablement l’interface.

Après utilisation répétée :

- les explications longues sont repliées ;
- les tooltips sont facultatifs ;
- les raccourcis deviennent prioritaires ;
- les écrans quotidiens restent très concis.

## 3.7. Accessibilité

Ne jamais dépendre uniquement :

- de la couleur ;
- du survol ;
- d’un tooltip ;
- d’une animation ;
- d’une icône non libellée.

Exigences :

- compatibilité lecteur d’écran ;
- navigation clavier sur Web/desktop futur ;
- zones tactiles d’au moins 44 × 44 points logiques ;
- contraste WCAG AA ;
- texte redimensionnable sans perte fonctionnelle ;
- états exprimés par texte et icône en plus de la couleur ;
- animations réduites si le système demande une réduction des mouvements.

## 3.8. Densité contextuelle

Une vue opérationnelle doit être concise.

Une vue d’investigation, d’import, de rapprochement ou d’audit peut être dense.

Ne pas appliquer le minimalisme de manière mécanique. Toute suppression ou hiérarchisation doit être justifiée par la tâche utilisateur.

---

# 4. Périmètre produit

## 4.1. Inclus dans la cible fonctionnelle

- mode solo local ;
- mode multi-utilisateur ;
- cycles hebdomadaires personnalisés ;
- calcul du budget soutenable sur 52 semaines ;
- démarrage express, guidé ou par import/connexion ;
- revenus fixes et variables ;
- charges mensuelles, saisonnières, annuelles, pluriannuelles et temporaires ;
- réserves cycliques ;
- réserve de sécurité ;
- projets temporaires ;
- saisie manuelle immédiate ;
- rapprochement ultérieur avec transactions importées ;
- import CSV, OFX, QIF et formats extensibles ;
- synchronisation chiffrée sur Google Drive ;
- partage de foyer ;
- fonctionnement hors ligne ;
- alertes locales ;
- projection de trésorerie ;
- module Woob expérimental, local et désactivé par défaut ;
- export, sauvegarde, restauration et suppression.

## 4.2. Hors périmètre initial

- initiation de virements bancaires ;
- paiement depuis l’application ;
- conseil financier personnalisé réglementé ;
- notation morale des commerçants ou catégories ;
- comparaison entre membres du foyer ;
- publicité ;
- vente de données ;
- stockage serveur en clair ;
- OCR détaillé article par article ;
- comptabilité professionnelle ;
- gestion fiscale ;
- portefeuille d’investissement ;
- crédit scoring.

---

# 5. Profils utilisateurs

## 5.1. Utilisateur solo simple

- ne souhaite pas connecter sa banque ;
- veut connaître son budget de la semaine ;
- saisit ses dépenses manuellement ;
- peut utiliser une sauvegarde chiffrée facultative.

## 5.2. Couple ou foyer

- plusieurs personnes dépensent depuis un ou plusieurs comptes ;
- chaque membre doit saisir rapidement une dépense ;
- le budget disponible doit être partagé ;
- chaque opération doit conserver son auteur ;
- aucune comparaison culpabilisante entre membres.

## 5.3. Utilisateur accompagné

- connaît mal ses charges ;
- oublie les dépenses annuelles ;
- a besoin d’un assistant guidé ;
- veut une estimation explicable.

## 5.4. Utilisateur avancé

- possède un historique bancaire ;
- veut importer des fichiers ;
- veut détecter des récurrences ;
- peut activer Woob ou un compagnon local ;
- veut auditer les hypothèses du calcul.

---

# 6. Onboarding : choix du mode de démarrage

L’écran de choix initial doit présenter trois parcours.

Chaque carte doit afficher :

- le résultat obtenu ;
- le temps de configuration cible ;
- les avantages ;
- les limites ;
- les conséquences d’un changement ultérieur.

Aucun parcours ne doit être présenté comme « mauvais ».

## 6.1. Démarrage express

### Libellé utilisateur

> **J’ai déjà une estimation globale**

### Données demandées

- total des revenus récurrents ;
- total des charges récurrentes ;
- dépenses annuelles importantes ;
- réserves souhaitées ;
- objectif financier ;
- jour de début du cycle.

### Avantages affichés

- mise en route très rapide ;
- aucune donnée bancaire ;
- aucune catégorisation détaillée ;
- permet de tester immédiatement la méthode.

### Inconvénients affichés

- l’application ne peut pas détecter quelle charge augmente ou disparaît ;
- le niveau de confiance est plus faible ;
- le passage à un suivi détaillé demande de décomposer le total global ;
- une mauvaise estimation globale affecte directement le budget proposé.

### Modèle de données

Créer une `SyntheticChargeEnvelope` représentant le total des charges.

Exemple :

- libellé : « Charges fixes globales » ;
- montant : 3 200 € par mois ;
- fréquence : mensuelle ;
- source : saisie utilisateur ;
- statut : active.

### Migration vers un mode détaillé

Lorsqu’un utilisateur ajoute une charge détaillée, il doit choisir :

1. **Cette charge était déjà incluse dans mon total global**
2. **Cette charge s’ajoute à mon total global**
3. **Je ne sais pas**

Si elle était incluse, son montant réduit le résiduel de l’enveloppe synthétique.

Exemple :

- enveloppe synthétique : 3 200 € ;
- assurance identifiée : 120 € ;
- assurance déclarée incluse ;
- résiduel synthétique : 3 080 € ;
- charge totale retenue : 3 080 € + 120 € = 3 200 €.

L’application ne doit jamais compter l’enveloppe complète et les charges détaillées complètes simultanément.

Lorsque le résiduel atteint zéro, l’enveloppe est archivée.

## 6.2. Démarrage guidé

### Libellé utilisateur

> **Aidez-moi à construire mon budget**

### Données demandées

Assistant étape par étape :

1. foyer ;
2. revenus ;
3. logement ;
4. crédits ;
5. énergie et eau ;
6. assurances ;
7. télécommunications ;
8. transport ;
9. enfants et études ;
10. abonnements ;
11. dépenses annuelles ;
12. réserves ;
13. projets ;
14. trésorerie ;
15. objectif.

### Avantages affichés

- calcul explicable ;
- suivi des évolutions de chaque charge ;
- aucune connexion bancaire obligatoire ;
- migration simple vers l’import ;
- meilleure détection des oublis.

### Inconvénients affichés

- configuration plus longue ;
- dépend de l’exactitude des montants saisis ;
- nécessite de maintenir les charges en cas de changement ;
- certaines dépenses rares peuvent rester oubliées.

### Recommandation produit

Ce mode est le mode recommandé par défaut pour le grand public.

## 6.3. Démarrage par import ou connexion

### Libellé utilisateur

> **Analyser mes transactions**

### Sous-choix

- importer un fichier ;
- connecter une source expérimentale locale ;
- commencer par un import puis activer la synchronisation plus tard.

### Avantages affichés

- s’appuie sur des montants réels ;
- aide à retrouver les charges oubliées ;
- détecte les hausses, disparitions et nouvelles récurrences ;
- rattrape les dépenses manuelles oubliées après synchronisation.

### Inconvénients affichés

- configuration initiale plus longue ;
- l’utilisateur doit confirmer les charges et revenus détectés ;
- les libellés bancaires peuvent être ambigus ;
- les banques et formats peuvent changer ;
- les transactions passées ne décrivent pas toujours les 52 prochaines semaines ;
- la synchronisation directe peut être expérimentale.

### Règle de migration

Le passage depuis le mode express déclenche obligatoirement l’assistant de décomposition du total global.

Le passage depuis le mode guidé ne demande pas de ressaisir les charges. L’application tente de rattacher les transactions importées aux règles existantes.

## 6.4. Changement de parcours après onboarding

Le parcours initial n’est pas un verrou.

Le panneau **Méthode et données** permet :

- de passer de l’express au guidé ;
- d’ajouter un import ;
- d’activer ou désactiver une synchronisation ;
- de revenir à un usage manuel ;
- de conserver l’historique.

Toute migration doit afficher un aperçu avant validation :

- charges ajoutées ;
- charges fusionnées ;
- doublons potentiels ;
- impact estimé sur le budget hebdomadaire ;
- niveau de confiance avant et après.

---

# 7. Configuration du foyer

## 7.1. Données minimales

- nom du foyer ;
- devise : EUR par défaut pour la France ;
- fuseau horaire ;
- locale ;
- jour de début du cycle ;
- heure de début : 00:00 locale par défaut ;
- mode solo ou partagé ;
- seuil de découvert facultatif ;
- solde bancaire initial facultatif.

## 7.2. Membres

Chaque membre possède :

- identifiant UUID ;
- nom d’affichage ;
- rôle : propriétaire, administrateur, membre, lecture seule ;
- date d’ajout ;
- état actif/révoqué ;
- appareil(s) autorisé(s).

Les droits :

### Propriétaire

- supprimer le foyer ;
- gérer les clés ;
- ajouter ou révoquer un membre ;
- modifier la méthode ;
- exporter toutes les données.

### Administrateur

- modifier revenus, charges, réserves et budget ;
- ajouter des membres si autorisé par le propriétaire ;
- importer des données.

### Membre

- ajouter et corriger ses dépenses ;
- consulter le budget ;
- consulter les paramètres non sensibles ;
- proposer un rapprochement.

### Lecture seule

- consulter ;
- ne peut pas modifier.

---

# 8. Modèle financier

## 8.1. Horizon de projection

L’horizon principal est constitué de 52 cycles hebdomadaires consécutifs à partir du début du cycle courant ou suivant selon le contexte.

La projection doit être recalculée lors de :

- modification d’un revenu ;
- modification d’une charge ;
- ajout d’une dépense irrégulière ;
- ajout ou modification d’une réserve ;
- changement d’objectif ;
- fin détectée d’un crédit ;
- modification du calendrier ;
- import confirmé d’une nouvelle récurrence.

L’application peut recalculer silencieusement, mais ne doit pas modifier automatiquement le budget choisi sans validation de l’utilisateur.

## 8.2. Formule générale

Pour un horizon de `N` cycles, normalement `N = 52` :

```text
capacité_discrétionnaire =
    revenus_prévus
  - charges_programmées
  - provisions_irrégulières
  - contributions_aux_réserves
  - contributions_aux_projets
  - objectif_financier
  - marge_de_sécurité
```

```text
budget_hebdomadaire_brut =
    capacité_discrétionnaire / N
```

La recommandation affichée est arrondie vers le bas au multiple configurable de 5 € le plus proche.

Exemple :

- budget brut : 613,42 € ;
- recommandation : 610 €.

Le moteur interne conserve les centimes.

## 8.3. Stratégies proposées

### Stable

Objectif financier additionnel : 0 €.

Le résultat prévu sur 52 semaines est proche de zéro, hors marge de sécurité.

### Redressement

L’utilisateur indique :

- déficit ou découvert à résorber ;
- date cible ou nombre de semaines.

```text
effort_redressement_par_cycle =
    montant_à_résorber / nombre_de_cycles
```

Cet effort est retiré du budget hebdomadaire.

### Constitution de marge

L’utilisateur indique :

- un montant annuel ;
- un tampon bancaire cible ;
- ou un montant par cycle.

L’application calcule la contribution.

### Personnalisé

L’utilisateur saisit directement un budget hebdomadaire.

L’application affiche alors :

- écart par rapport au budget stable ;
- résultat prévu à 52 semaines ;
- date estimée de sortie du découvert ;
- impact sur les réserves.

## 8.4. Marge de sécurité

La marge de sécurité est explicite.

Valeur recommandée initiale :

- 2 % des revenus prévus si les données sont complètes ;
- 5 % si le niveau de confiance est moyen ;
- 10 % si le niveau de confiance est faible.

L’utilisateur peut la modifier, mais l’application explique l’impact.

---

# 9. Revenus

## 9.1. Types de revenus

### Revenu fixe garanti

Exemples :

- salaire fixe ;
- allocation stable ;
- pension régulière.

Intégré intégralement à la projection.

### Revenu récurrent variable

Exemples :

- salaire variable ;
- heures supplémentaires ;
- commissions ;
- activité indépendante ;
- revenus saisonniers.

L’utilisateur choisit une méthode :

- prudent ;
- équilibré ;
- optimiste ;
- montant manuel.

### Revenu exceptionnel

Exemples :

- vide-grenier ;
- Vinted ;
- cadeau ;
- prime exceptionnelle ;
- vente d’un véhicule.

Il ne doit jamais augmenter automatiquement le budget hebdomadaire durable.

### Remboursement

Un remboursement, retour marchand ou annulation n’est pas un revenu.

Il annule ou réduit une dépense passée.

## 9.2. Estimation d’un revenu variable

### Historique de 12 mois ou plus

Après exclusion des revenus marqués exceptionnels :

- prudent : moyenne des trois mois les plus faibles ;
- équilibré : médiane mensuelle ;
- optimiste : moyenne mensuelle.

### Historique de 6 à 11 mois

- prudent : moyenne des deux mois les plus faibles ;
- équilibré : médiane ;
- optimiste : moyenne ;
- confiance maximale : moyenne.

### Historique inférieur à 6 mois

- montant manuel obligatoire ou proposition indicative ;
- confiance faible ;
- avertissement visible.

### Revenu versé plusieurs fois dans le mois

Les versements appartenant à la même source sont agrégés par mois civil pour l’estimation historique.

La projection future utilise ensuite les dates réelles connues, par exemple :

- avance en fin de mois ;
- solde en début de mois.

## 9.3. Traitement d’un revenu exceptionnel

À la détection ou à la saisie, l’application propose :

1. réduire le découvert ;
2. alimenter la réserve de sécurité ;
3. alimenter un projet ;
4. rendre le montant disponible pour le cycle courant uniquement ;
5. ignorer dans la méthode.

Le choix est enregistré.

---

# 10. Charges programmées

## 10.1. Définition

Une charge programmée est une dépense attendue qui ne doit pas être financée par le budget hebdomadaire au moment où elle est prélevée.

Exemples :

- crédit ;
- loyer ou prêt immobilier ;
- assurance ;
- énergie ;
- téléphonie ;
- abonnement ;
- cantine ;
- école ;
- impôt ;
- pension ;
- frais bancaires récurrents.

## 10.2. Champs obligatoires

- UUID ;
- libellé ;
- montant estimé ;
- devise ;
- type de fréquence ;
- règle de fréquence ;
- prochaine date ;
- date de fin facultative ;
- nombre d’occurrences restantes facultatif ;
- mois actifs facultatifs ;
- fourchette de tolérance ;
- source : manuel, import, détection, Woob ;
- confiance ;
- compte concerné facultatif ;
- statut : proposé, actif, suspendu, terminé, archivé ;
- inclusion dans une enveloppe synthétique éventuelle.

## 10.3. Fréquences supportées

- hebdomadaire ;
- toutes les `n` semaines ;
- mensuelle ;
- tous les `n` mois ;
- annuelle ;
- tous les `n` ans ;
- dates explicites ;
- saisonnière ;
- nombre d’occurrences limité ;
- date de fin ;
- calendrier personnalisé.

Exemples :

- cantine : mensuelle de septembre à juin ;
- contrôle technique : tous les deux ans ;
- BNP : mensuel, 10 occurrences restantes ;
- assurance annuelle : une date par an.

## 10.4. Tolérance de montant

Une règle peut être :

- fixe ;
- montant proche ;
- variable dans une plage ;
- variable selon saison.

Exemple :

- Free Mobile : 9,99 € ± 0,50 € ;
- électricité : plage de 120 € à 240 € ;
- cantine : montant variable selon mois.

## 10.5. Détection des évolutions

Une alerte est proposée si :

- une charge dépasse la tolérance ;
- une charge apparaît plus tôt ou plus tard que la fenêtre attendue ;
- une charge manque sur deux occurrences attendues ;
- un nouveau prélèvement similaire apparaît trois fois ;
- une charge terminée réapparaît.

L’application ne modifie jamais silencieusement le montant de référence.

---

# 11. Dépenses annuelles, pluriannuelles et irrégulières

## 11.1. Types

### Périodique prévisible

- ramonage ;
- entretien de pompe à chaleur ;
- révision automobile ;
- contrôle technique ;
- assurance annuelle ;
- taxe foncière non mensualisée.

### Irrégulière mais probable

- réparation automobile ;
- électroménager ;
- soins non remboursés ;
- entretien du logement.

### Choisie et planifiée

- vacances ;
- travaux ;
- équipement ;
- voyage.

## 11.2. Provision initiale avec rattrapage

Si la prochaine échéance est connue :

```text
contribution_par_cycle =
    max(0, montant_cible - montant_déjà_provisionné)
    / nombre_de_cycles_avant_échéance
```

Exemple :

- contrôle technique : 90 € ;
- échéance dans 26 semaines ;
- provision existante : 0 € ;
- contribution : 3,46 € par semaine.

Après paiement, la prochaine occurrence est répartie sur l’intervalle complet.

## 11.3. Provision sans date connue

Si seule une fréquence est connue :

```text
contribution_par_cycle =
    montant_estimé / nombre_de_cycles_de_la_période
```

Exemples :

- annuel : montant / 52 ;
- tous les deux ans : montant / 104.

## 11.4. Assistant des dépenses oubliées

L’onboarding affiche une liste adaptative.

### Logement

- taxe foncière ;
- entretien chauffage ;
- ramonage ;
- entretien climatisation ou pompe à chaleur ;
- petits travaux ;
- assurance annuelle.

### Véhicule

- entretien ;
- pneus ;
- contrôle technique ;
- réparations ;
- carte grise ;
- franchise ;
- stationnement annuel.

### Enfants

- rentrée ;
- activités ;
- voyages scolaires ;
- permis ;
- études supérieures ;
- équipement informatique.

### Foyer

- Noël ;
- anniversaires ;
- vacances ;
- santé ;
- vétérinaire ;
- remplacement électroménager.

Pour chaque élément :

- « Je n’ai pas cette dépense »
- « Je connais le montant »
- « Je veux utiliser une estimation globale »
- « Je ne sais pas »

Les petites dépenses peuvent être regroupées dans une provision globale.

---

# 12. Réserves et projets

## 12.1. Réserve cyclique

Une réserve cyclique revient périodiquement.

Exemples :

- anniversaires ;
- Noël ;
- vacances annuelles ;
- rentrée ;
- entretien automobile.

Champs :

- nom ;
- cycle ;
- montant cible ;
- montant disponible ;
- prochaine période d’utilisation ;
- contribution recommandée ;
- compte bancaire réel facultatif ;
- allocation virtuelle.

## 12.2. Assistant anniversaires et Noël

Questions :

- nombre d’enfants ;
- nombre d’adultes ;
- nombre d’autres bénéficiaires facultatif ;
- budget anniversaire par enfant ;
- budget anniversaire par adulte ;
- budget Noël par enfant ;
- budget Noël par adulte ;
- dates d’anniversaire facultatives ;
- montant déjà disponible.

Calcul annuel simple :

```text
budget_annuel =
    enfants × (anniversaire_enfant + Noël_enfant)
  + adultes × (anniversaire_adulte + Noël_adulte)
  + autres_bénéficiaires
```

Si les dates sont connues, la contribution est ajustée pour couvrir les événements proches.

Sinon, le montant est lissé sur 12 mois ou 52 cycles.

## 12.3. Réserve de sécurité

Champs :

- objectif cible ;
- minimum à maintenir ;
- montant actuel ;
- contribution ;
- règle de reconstitution ;
- autorisation ou non d’utilisation pour dépenses courantes.

Une utilisation de la réserve de sécurité doit créer un événement explicite.

## 12.4. Projet temporaire

Exemples :

- voiture ;
- canapé ;
- réfrigérateur ;
- travaux.

Champs :

- montant cible ;
- montant actuel ;
- date cible facultative ;
- priorité ;
- contribution recommandée ;
- état : actif, financé, abandonné.

Avec date :

```text
contribution =
    montant_restant / cycles_restants
```

Sans date, l’application propose plusieurs vitesses compatibles avec la marge disponible.

## 12.5. Allocation virtuelle dans un compte partagé

Un compte bancaire réel peut contenir plusieurs allocations virtuelles.

Exemple :

- solde réel du compte de réserve : 1 265 € ;
- anniversaires/Noël : 460 € ;
- vacances : 500 € ;
- enfants : 305 €.

La somme des allocations ne doit pas dépasser le solde réel connu, sauf si le mode est purement déclaratif et que l’utilisateur accepte un avertissement.

## 12.6. Éviter le double comptage

Si une contribution à une réserve est déjà retirée du budget soutenable, la dépense payée depuis cette réserve ne doit pas réduire une deuxième fois le budget hebdomadaire.

---

# 13. Budget hebdomadaire quotidien

## 13.1. Écran principal

L’écran principal affiche dans cet ordre :

1. **Montant restant dans le cycle**
2. montant dépensé / budget ;
3. jours ou heures avant le prochain cycle ;
4. statut de synchronisation ;
5. tendance sur 8 ou 13 cycles ;
6. point bas de trésorerie si pertinent ;
7. action principale « Ajouter une dépense ».

Exemple :

```text
Il reste 252 €
jusqu’à samedi

348 € dépensés sur 600 €

Tendance : en progression
Dernière synchronisation : il y a 2 minutes
```

## 13.2. Saisie rapide

Objectif : une dépense simple doit être saisie en moins de cinq secondes par un utilisateur habitué.

Ordre :

1. montant ;
2. catégorie facultative ;
3. note facultative ;
4. validation.

Valeurs par défaut :

- date d’achat : maintenant ;
- auteur : membre courant ;
- budget : cycle actif ;
- compte : dernier compte utilisé ou inconnu ;
- statut : en attente si synchronisation bancaire active.

## 13.3. Catégories

Les catégories sont facultatives pour le fonctionnement du budget.

Elles servent uniquement à l’analyse.

Catégories par défaut :

- courses ;
- carburant ;
- enfants ;
- maison ;
- vêtements ;
- santé ;
- restaurants ;
- loisirs ;
- achats en ligne ;
- autre.

## 13.4. Date utilisée

### Budget hebdomadaire

Utiliser la date d’achat.

### Trésorerie

Utiliser la date comptable.

### Date de valeur

Conserver si importée, mais ne pas l’utiliser dans l’interface quotidienne.

## 13.5. Dépenses oubliées

En mode connecté ou importé, toute transaction non reconnue comme :

- transfert ;
- remboursement ;
- charge programmée ;
- dépense provisionnée ;
- paiement global déjà détaillé ;

devient par défaut une dépense du budget hebdomadaire.

---

# 14. Import et rapprochement

## 14.1. Formats

Architecture extensible.

Formats initiaux :

- CSV configurable ;
- OFX ;
- QIF ;
- CAMT ultérieur.

L’import doit proposer un assistant de mapping :

- date ;
- libellé ;
- montant ;
- débit/crédit ;
- compte ;
- solde ;
- identifiant de transaction.

## 14.2. Transaction manuelle en attente

Une dépense saisie avant apparition bancaire possède le statut `pending`.

Elle réduit immédiatement le budget.

Lorsqu’une transaction bancaire correspondante apparaît, l’application crée un lien de rapprochement.

Elle ne crée pas une nouvelle dépense budgétaire.

## 14.3. Critères de rapprochement

Le score de correspondance utilise :

- compte ;
- carte éventuelle ;
- montant ;
- tolérance ;
- date d’achat ;
- date comptable ;
- commerçant normalisé ;
- libellé ;
- auteur ;
- localisation facultative ;
- absence d’autre correspondance.

Ne jamais rapprocher automatiquement sur le seul montant.

Exemple à éviter :

- Free Mobile : 9,99 € ;
- boulangerie : 9,99 €.

## 14.4. Seuils

- confiance élevée : rapprochement automatique autorisé ;
- confiance moyenne : proposition utilisateur ;
- confiance faible : aucune proposition ou proposition secondaire.

Les seuils doivent être configurables dans le moteur, pas dispersés dans l’UI.

## 14.5. Ordre de classification

1. doublons d’import ;
2. transferts internes ;
3. remboursements ;
4. paiements globaux de carte à débit différé ;
5. charges programmées confirmées ;
6. dépenses provisionnées ;
7. rapprochement avec saisies manuelles ;
8. dépenses hebdomadaires.

## 14.6. Carte à débit différé

Les achats individuels réduisent le budget à leur date d’achat.

Le prélèvement global mensuel de la carte est classé comme règlement interne et ne réduit pas le budget une seconde fois.

---

# 15. Trésorerie

## 15.1. Objectif

La trésorerie répond à :

> « Le compte risque-t-il de dépasser son seuil avant les prochains revenus ? »

Elle est distincte de la soutenabilité annuelle.

## 15.2. Projection

Horizon initial :

- 60 jours par défaut ;
- option 90 jours.

Éléments :

- solde actuel ;
- revenus datés ;
- charges datées ;
- dépenses hebdomadaires estimées ;
- virements internes ;
- projets datés ;
- seuil de découvert.

## 15.3. Affichage

Afficher :

- point bas prévu ;
- date du point bas ;
- marge avant découvert ;
- niveau de confiance ;
- hypothèses principales.

Ne pas masquer le fait qu’un budget annuel stable peut produire un point bas négatif.

---

# 16. Tendance et score

## 16.1. Mesures

- budget cumulé sur 8 cycles ;
- dépenses cumulées ;
- écart ;
- trajectoire bancaire ;
- complétude des données ;
- rapprochements en attente.

## 16.2. États

### Hors trajectoire

Dépenses glissantes supérieures à 105 % du budget et tendance négative.

### Tendu

Dépenses comprises entre 95 % et 105 %, ou trésorerie proche du seuil.

### Stable

Dépenses respectant le budget et trajectoire proche de l’objectif.

### En progression

Dépenses inférieures à 95 % et trajectoire positive.

### Surperformance

Dépenses inférieures à 85 % pendant au moins 8 cycles, avec données complètes.

La surperformance ne doit pas inciter automatiquement à augmenter le budget.

## 16.3. Conditions de fiabilité

Ne pas afficher un score affirmatif si :

- plusieurs jours ne sont pas synchronisés ;
- plus de 10 % des transactions sont non rapprochées ;
- l’utilisateur est en mode manuel et indique que la saisie est incomplète ;
- le niveau de confiance est faible.

Afficher alors :

> « Tendance provisoire — données incomplètes »

---

# 17. Notifications

## 17.1. Notifications locales

- 75 % du budget consommé ;
- 90 % ;
- 100 % ;
- cycle terminé ;
- dépense en attente depuis plusieurs jours ;
- charge habituelle modifiée ;
- charge potentiellement terminée ;
- nouvelle récurrence détectée ;
- point bas sous le seuil ;
- réserve insuffisante avant échéance.

## 17.2. Règles

- pas de notification à chaque achat ;
- pas de message moralisateur ;
- pas de comparaison entre membres ;
- fréquence configurable ;
- heures silencieuses ;
- contenu financier masqué sur écran verrouillé si l’utilisateur le demande.

## 17.3. Sans serveur de push métier

Les alertes précises sont calculées localement.

La synchronisation Drive peut être tentée à l’ouverture et en arrière-plan selon les capacités du système.

L’interface affiche toujours la date de dernière synchronisation.

---

# 18. Stockage local

## 18.1. Base locale

Utiliser SQLite avec chiffrement au repos.

La base locale contient :

- projections matérialisées ;
- transactions ;
- événements appliqués ;
- index de recherche ;
- synthèses par cycle ;
- règles ;
- membres ;
- paramètres.

## 18.2. Performance cible

Jeu de test minimal :

- 10 ans ;
- 200 000 transactions ;
- 100 000 événements métier supplémentaires ;
- 10 000 charges ou modifications historiques ;
- 8 appareils historiques ;
- 6 membres.

Cibles :

- affichage du tableau de bord à chaud : moins de 150 ms ;
- affichage à froid après ouverture de base : moins de 1 seconde ;
- recherche sur 200 000 transactions : moins de 500 ms ;
- calcul de projection sur 52 semaines : moins de 300 ms ;
- saisie d’une dépense : confirmation visuelle immédiate, persistance locale sous 100 ms.

## 18.3. Index

Au minimum :

- date métier ;
- date comptable ;
- type ;
- compte ;
- statut ;
- commerçant normalisé ;
- charge associée ;
- cycle hebdomadaire ;
- UUID d’événement ;
- identifiant d’import.

## 18.4. Tables de synthèse

Maintenir des agrégats par :

- cycle hebdomadaire ;
- mois ;
- année ;
- charge ;
- réserve ;
- membre ;
- catégorie.

Les agrégats sont reconstruisibles depuis le journal.

---

# 19. Synchronisation Google Drive chiffrée

## 19.1. Principe

Google Drive stocke uniquement des objets chiffrés.

L’application chiffre avant envoi et déchiffre après téléchargement.

Google ne reçoit jamais la clé de déchiffrement.

## 19.2. Sélection du compte

Ne jamais utiliser silencieusement le compte Google présent sur Android.

Lors de l’activation :

> **Choisir le compte utilisé pour stocker ce budget**

Forcer un choix explicite.

Modes :

1. compte personnel d’un membre avec dossier partagé ;
2. compte Google commun dédié ;
3. sauvegarde solo.

## 19.3. Compte commun

Les deux appareils peuvent sélectionner le même compte Google dédié.

L’application doit avertir :

- les identifiants Google sont partagés hors de l’application ;
- l’authentification multifacteur doit être organisée ;
- le compte doit être réservé au stockage du budget si possible.

## 19.4. Comptes séparés

Le propriétaire crée un dossier Drive et le partage avec l’autre compte.

La clé de foyer est transmise séparément par QR code ou invitation chiffrée.

## 19.5. Scope OAuth

Utiliser l’accès le plus restreint permettant de gérer les fichiers créés ou explicitement sélectionnés par l’application.

Ne jamais demander l’accès global au Drive sans nécessité documentée.

## 19.6. Organisation distante

Ne pas créer un fichier par transaction.

Structure logique :

```text
vault/
  manifest chiffré
  descripteurs d’appareils chiffrés
  segments d’événements chiffrés
  snapshots chiffrés
  pièces jointes chiffrées facultatives
```

Les noms de fichiers sont opaques.

## 19.7. Segments

Fermer un segment dès que l’une des limites est atteinte :

- 500 événements ;
- 1 Mio avant chiffrement ;
- 24 heures depuis sa création.

Chaque appareil écrit dans son propre flux.

Aucun appareil ne modifie le segment fermé d’un autre appareil.

## 19.8. Instantanés

Créer un snapshot lorsque l’une des conditions est atteinte :

- 1 000 nouveaux événements ;
- un mois depuis le dernier snapshot ;
- migration de schéma ;
- ajout d’un nouvel appareil.

Conserver :

- les trois derniers snapshots mensuels ;
- un snapshot annuel par année ;
- le journal complet archivé.

## 19.9. Restauration

Un nouvel appareil :

1. télécharge le dernier snapshot compatible ;
2. vérifie l’intégrité ;
3. déchiffre ;
4. reconstruit SQLite ;
5. applique les segments plus récents ;
6. recalcule les agrégats.

Cible : restauration de 10 ans de données en moins de 60 secondes sur un smartphone moyen, hors temps réseau.

## 19.10. Conflits

Les événements sont immuables.

Une correction crée un nouvel événement.

Les conflits de modification simultanée sont résolus par :

- version logique ;
- auteur ;
- horodatage ;
- règle métier ;
- demande utilisateur si les valeurs sont incompatibles.

Les dépenses indépendantes ne doivent jamais se bloquer.

---

# 20. Chiffrement et gestion des clés

## 20.1. Primitives

Utiliser une bibliothèque maintenue fondée sur libsodium ou primitives équivalentes.

Exigences :

- clé maître aléatoire 256 bits par foyer ;
- chiffrement authentifié ;
- dérivation de clé par objet avec HKDF-SHA-256 ou équivalent ;
- nonce unique par objet ;
- échange de clé par mécanisme asymétrique moderne ;
- signature ou authentification de l’auteur ;
- comparaison en temps constant pour données sensibles.

## 20.2. Stockage local des clés

- Android Keystore ;
- iOS Keychain ;
- biométrie facultative ;
- aucune clé dans les logs ;
- aucune clé dans Drive en clair ;
- aucune clé dans les crash reports.

## 20.3. Invitation d’un appareil

1. nouvel appareil crée une paire de clés ;
2. appareil autorisé scanne ou reçoit la clé publique ;
3. clé du foyer chiffrée pour le nouvel appareil ;
4. paquet d’invitation signé ;
5. nouvel appareil confirme ;
6. événement `DEVICE_AUTHORIZED`.

## 20.4. Révocation

Révoquer un appareil empêche l’accès futur.

La révocation n’efface pas ce que l’appareil a déjà déchiffré.

Option de rotation de la clé du foyer après révocation.

## 20.5. Récupération

À la création :

- générer une phrase ou un code de récupération ;
- demander confirmation de sauvegarde ;
- proposer export imprimable ;
- expliquer l’irréversibilité.

Sans appareil autorisé ni code de récupération, les données sont perdues.

## 20.6. Verrouillage d’application

Options :

- aucun ;
- code local ;
- biométrie ;
- délai de verrouillage.

---

# 21. Mode solo

## 21.1. Fonctionnement

- aucun compte ;
- aucune connexion ;
- données locales chiffrées ;
- export manuel ;
- sauvegarde Drive facultative.

## 21.2. Passage au partage

Le passage au mode partagé :

1. crée un foyer chiffré ;
2. génère les clés ;
3. transfère les données locales dans le journal ;
4. choisit un compte Drive ;
5. crée le snapshot initial ;
6. invite un membre.

Aucune donnée ne doit être perdue.

---

# 22. Woob expérimental

## 22.1. Décision produit

Woob est proposé comme option expérimentale, désactivée par défaut.

L’éditeur ne reçoit :

- aucun identifiant bancaire ;
- aucune donnée bancaire ;
- aucune information sur les banques utilisées ;
- aucune information permettant de savoir si l’option est activée.

## 22.2. Message d’activation

Le message doit indiquer clairement :

- connecteurs non officiels ;
- possibilité de panne après modification d’un site bancaire ;
- traitement local ;
- identifiants conservés localement ;
- aucune certification revendiquée ;
- module expérimental ;
- lecture seule.

Le message ne doit pas prétendre qu’un disclaimer remplace une obligation légale.

## 22.3. Capacités autorisées

- lecture des comptes ;
- lecture des soldes ;
- lecture des opérations ;
- lecture des opérations à venir si disponible.

Interdit :

- virement ;
- ajout de bénéficiaire ;
- paiement ;
- modification de compte ;
- récupération de documents non nécessaires.

## 22.4. Architecture

Deux implémentations possibles :

### Compagnon local

- application desktop ou Docker ;
- Woob installé localement ;
- synchronisation vers le coffre chiffré ;
- aucune API publique exposée par défaut ;
- association avec le foyer par clé.

### Moteur embarqué

À étudier par plateforme.

Ne pas bloquer la version mobile si l’intégration iOS est trop complexe.

## 22.5. Journalisation

Les logs Woob doivent être expurgés :

- mots de passe ;
- OTP ;
- cookies ;
- numéros de compte complets ;
- soldes ;
- libellés ;
- réponses HTTP sensibles.

## 22.6. Statut réglementaire

Le produit doit conserver une note interne :

> « Qualification réglementaire à réévaluer avant diffusion à grande échelle ou monétisation. »

Cette note n’empêche pas le développement du module expérimental demandé.

---

# 23. Tickets de caisse

## 23.1. MVP

La photo de ticket n’est pas obligatoire pour la première version publique.

La saisie rapide prime.

## 23.2. Version ultérieure

Flux :

1. photo ;
2. extraction locale du total et de la date ;
3. validation ;
4. création de la dépense ;
5. suppression de l’image par défaut.

## 23.3. Conservation facultative

Si l’utilisateur choisit de conserver :

- compression ;
- chiffrement ;
- dossier séparé ;
- durée de conservation ;
- suppression automatique ;
- exclusion des snapshots principaux.

---

# 24. Panneau « Méthode et données »

Ce panneau est le centre de contrôle de la méthode.

Il doit permettre de modifier simplement :

- mode de démarrage ;
- jour du cycle ;
- budget choisi ;
- stratégie ;
- revenus ;
- charges ;
- dépenses annuelles ;
- réserves ;
- projets ;
- marge de sécurité ;
- synchronisation ;
- membres ;
- import ;
- Woob ;
- niveau de détail ;
- hypothèses ;
- confidentialité.

## 24.1. Affichage des conséquences

Toute modification financière affiche avant validation :

- ancien budget conseillé ;
- nouveau budget conseillé ;
- écart hebdomadaire ;
- impact annuel ;
- impact sur la trésorerie ;
- niveau de confiance.

---

# 25. Journal des hypothèses

Le budget proposé doit être explicable.

Écran exemple :

```text
Revenus retenus
- Salaire A : 3 936 €/mois
- Salaire B prudent : 1 450 €/mois
- Allocations : 690 €/mois

Charges retenues
- Logement et crédits : …
- Assurances : …
- Cantine : septembre à juin
- Crédit BNP : 10 échéances restantes

Provisions
- Noël et anniversaires : 115 €/mois
- Entretien automobile : 600 €/an

Objectif
- Sortie du découvert : 1 500 € en 10 mois

Budget conseillé
- 595 €/semaine
```

Aucune recommandation ne doit apparaître comme un nombre magique.

---

# 26. Niveau de confiance

## 26.1. Facteurs

- durée d’historique ;
- revenus confirmés ;
- charges confirmées ;
- dépenses annuelles renseignées ;
- rapprochements ;
- dernière synchronisation ;
- qualité des dates ;
- résiduel d’enveloppe synthétique ;
- revenus variables.

## 26.2. Niveaux

### Faible

- moins de 3 mois ;
- total global non détaillé ;
- dépenses annuelles non renseignées.

### Moyen

- 6 mois ou saisie guidée complète ;
- quelques hypothèses.

### Bon

- 12 mois ;
- charges confirmées ;
- dépenses annuelles ;
- réserves ;
- revenus variables traités.

### Élevé

- 24 mois ;
- rapprochement de qualité ;
- peu d’hypothèses manuelles ;
- cohérence historique/future validée.

Le niveau de confiance n’empêche pas l’utilisation. Il modifie la marge recommandée et le langage de l’interface.

---

# 27. Écrans obligatoires

## 27.1. Accueil

- restant ;
- consommé ;
- fin du cycle ;
- tendance ;
- synchronisation ;
- action principale.

## 27.2. Ajouter une dépense

- montant dominant ;
- catégorie facultative ;
- note facultative ;
- date ;
- auteur ;
- compte facultatif.

## 27.3. Historique du cycle

- dépenses ;
- statut pointé/non pointé ;
- auteur ;
- correction ;
- exclusion motivée.

## 27.4. Charges

- actives ;
- proposées ;
- modifiées ;
- terminées ;
- saisonnières ;
- synthétiques.

## 27.5. Revenus

- garantis ;
- variables ;
- exceptionnels ;
- hypothèse retenue.

## 27.6. Réserves et projets

- solde virtuel ;
- objectif ;
- contribution ;
- échéance ;
- compte réel.

## 27.7. Projection

- 52 semaines ;
- budget stable ;
- redressement ;
- marge ;
- hypothèses.

## 27.8. Trésorerie

- 60/90 jours ;
- point bas ;
- seuil ;
- dates.

## 27.9. Import et rapprochement

- import ;
- doublons ;
- propositions ;
- non classés ;
- règles.

## 27.10. Paramètres

- foyer ;
- membres ;
- sécurité ;
- Drive ;
- export ;
- Woob ;
- notifications ;
- méthode.

---

# 28. Architecture logicielle

## 28.1. Client

Flutter et Dart.

Cibles initiales :

- Android ;
- iOS.

Cibles futures possibles :

- Web ;
- Windows ;
- macOS ;
- Linux.

## 28.2. Organisation du dépôt

```text
/apps/mobile
/packages/domain
/packages/application
/packages/local_storage
/packages/sync_core
/packages/google_drive_sync
/packages/crypto
/packages/importers
/packages/reconciliation
/packages/forecast_engine
/packages/ui_components
/tools/woob_companion
/docs/adr
/docs/security
/tests/fixtures
```

## 28.3. Règles de dépendance

- `domain` ne dépend d’aucun framework ;
- `application` orchestre les cas d’usage ;
- `local_storage` implémente les dépôts ;
- `sync_core` définit l’interface fournisseur ;
- `google_drive_sync` implémente cette interface ;
- `forecast_engine` est pur et testable ;
- l’UI ne contient aucune formule financière ;
- aucun SDK Google dans le domaine ;
- aucun format CSV dans le domaine ;
- le chiffrement est isolé.

## 28.4. Gestion d’état

Utiliser une solution Flutter maintenue permettant :

- injection de dépendances ;
- états asynchrones ;
- test unitaire ;
- séparation UI/métier.

Le choix exact doit être documenté dans un ADR avant implémentation.

## 28.5. Versions

Au démarrage du projet :

- utiliser les versions stables courantes ;
- verrouiller toutes les dépendances ;
- commiter les lockfiles ;
- interdire les plages de versions non bornées ;
- documenter toute dépendance native.

---

# 29. Modèle de données principal

## 29.1. Household

- `id`
- `name`
- `currency`
- `locale`
- `timezone`
- `cycle_anchor_weekday`
- `cycle_anchor_time`
- `created_at`
- `updated_at`
- `security_policy`
- `sync_mode`

## 29.2. Member

- `id`
- `household_id`
- `display_name`
- `role`
- `status`
- `created_at`
- `revoked_at`

## 29.3. Device

- `id`
- `member_id`
- `public_key`
- `signing_key_id`
- `authorized_at`
- `revoked_at`
- `last_seen_at`

## 29.4. FinancialAccount

- `id`
- `name`
- `type`
- `institution`
- `currency`
- `current_balance`
- `balance_date`
- `is_reserve_account`
- `is_hidden`

## 29.5. IncomeRule

- `id`
- `name`
- `amount_model`
- `recurrence`
- `next_date`
- `end_date`
- `active_months`
- `source`
- `confidence`
- `exceptional_policy`

## 29.6. ChargeRule

- champs définis en section 10 ;
- `synthetic_envelope_id`
- `remaining_occurrences`
- `recognition_signature`

## 29.7. SyntheticChargeEnvelope

- `id`
- `name`
- `original_amount`
- `residual_amount`
- `period`
- `created_at`
- `decomposition_status`

## 29.8. IrregularExpenseRule

- `id`
- `name`
- `estimated_amount`
- `next_due_date`
- `interval`
- `funded_amount`
- `funding_mode`
- `confidence`

## 29.9. Reserve

- `id`
- `name`
- `type`
- `target_amount`
- `virtual_balance`
- `real_account_id`
- `cycle`
- `next_target_date`
- `contribution_policy`

## 29.10. Project

- `id`
- `name`
- `target_amount`
- `current_amount`
- `target_date`
- `priority`
- `status`

## 29.11. WeeklyBudgetPolicy

- `id`
- `strategy`
- `selected_amount`
- `recommended_amount`
- `rounding_step`
- `effective_from`
- `effective_to`
- `goal_id`
- `assumption_snapshot_id`

## 29.12. WeeklyCycle

- `id`
- `start_local_date`
- `end_local_date`
- `budget_amount`
- `spent_amount`
- `pending_amount`
- `status`
- `closed_at`

## 29.13. ManualExpense

- `id`
- `member_id`
- `purchase_date`
- `amount`
- `category`
- `note`
- `account_id`
- `cycle_id`
- `status`
- `matched_transaction_id`

## 29.14. ImportedTransaction

- `id`
- `source_id`
- `source_transaction_id`
- `account_id`
- `booking_date`
- `value_date`
- `amount`
- `raw_label`
- `normalized_counterparty`
- `classification`
- `import_batch_id`
- `duplicate_hash`

## 29.15. MatchLink

- `id`
- `manual_expense_id`
- `imported_transaction_id`
- `score`
- `method`
- `confirmed_by`
- `confirmed_at`

## 29.16. ForecastSnapshot

- `id`
- `created_at`
- `horizon_start`
- `horizon_end`
- `income_total`
- `charge_total`
- `provision_total`
- `reserve_total`
- `goal_total`
- `recommended_weekly_budget`
- `confidence`
- `assumptions_hash`

---

# 30. Journal d’événements

## 30.1. Structure

Chaque événement contient :

- UUID ;
- foyer ;
- appareil ;
- membre ;
- type ;
- version de schéma ;
- date de création ;
- date métier ;
- entité cible ;
- version attendue ;
- charge utile chiffrée ;
- signature/authentification.

## 30.2. Types minimaux

- `HOUSEHOLD_CREATED`
- `MEMBER_ADDED`
- `MEMBER_REVOKED`
- `DEVICE_AUTHORIZED`
- `DEVICE_REVOKED`
- `INCOME_CREATED`
- `INCOME_UPDATED`
- `CHARGE_CREATED`
- `CHARGE_UPDATED`
- `CHARGE_ENDED`
- `SYNTHETIC_ENVELOPE_CREATED`
- `SYNTHETIC_ENVELOPE_DECOMPOSED`
- `IRREGULAR_EXPENSE_CREATED`
- `RESERVE_CREATED`
- `RESERVE_CONTRIBUTION_RECORDED`
- `PROJECT_CREATED`
- `PROJECT_FUNDED`
- `BUDGET_POLICY_SELECTED`
- `EXPENSE_CREATED`
- `EXPENSE_CORRECTED`
- `EXPENSE_DELETED`
- `TRANSACTION_IMPORTED`
- `TRANSACTION_CLASSIFIED`
- `MATCH_PROPOSED`
- `MATCH_CONFIRMED`
- `MATCH_REJECTED`
- `TRANSFER_LINKED`
- `REFUND_LINKED`
- `CYCLE_CLOSED`
- `SYNC_PROVIDER_CHANGED`
- `RECOVERY_KEY_ROTATED`

## 30.3. Suppression

Une suppression métier crée un événement tombstone.

Ne jamais supprimer silencieusement un événement déjà synchronisé.

---

# 31. Sécurité et confidentialité

## 31.1. Minimisation

- aucune donnée financière envoyée à l’éditeur ;
- aucune télémétrie contenant montants ou libellés ;
- aucune publicité ;
- aucune vente de données ;
- aucune analyse distante du budget ;
- aucun identifiant bancaire dans les logs.

## 31.2. Télémétrie

Désactivée par défaut.

Si ajoutée :

- consentement explicite ;
- événements techniques uniquement ;
- aucune donnée métier ;
- possibilité de retrait ;
- documentation.

## 31.3. Crash reports

Nettoyer :

- routes contenant identifiants ;
- montants ;
- noms ;
- fichiers importés ;
- erreurs bancaires ;
- jetons OAuth ;
- clés.

## 31.4. Export

Formats :

- archive chiffrée complète ;
- export CSV lisible ;
- export des hypothèses ;
- export des règles.

## 31.5. Suppression

La suppression locale et distante doit être explicite.

Le propriétaire peut :

- supprimer un appareil ;
- supprimer le foyer ;
- effacer les fichiers Drive ;
- conserver un export.

---

# 32. Exigences de qualité

## 32.1. Exactitude

Les formules financières doivent être testées en centimes entiers, jamais en flottants binaires.

Utiliser un type monétaire entier :

- centimes signés 64 bits ;
- devise séparée.

## 32.2. Idempotence

Réimporter le même fichier ne doit pas dupliquer les transactions.

Réappliquer le même événement ne doit pas modifier deux fois la base.

## 32.3. Résilience

- perte réseau ;
- fermeture pendant sync ;
- Drive indisponible ;
- quota ;
- conflit ;
- fichier corrompu ;
- horloge appareil incorrecte ;
- changement de fuseau ;
- téléphone perdu.

## 32.4. Sauvegarde

Afficher régulièrement l’état :

- local uniquement ;
- sauvegardé ;
- synchronisation en retard ;
- récupération non configurée.

---

# 33. Cas limites obligatoires

- cycle traversant un changement d’heure ;
- année bissextile ;
- 52 ou 53 occurrences d’un jour dans une année civile ;
- achat le dernier jour du cycle, débit le cycle suivant ;
- remboursement partiel ;
- remboursement dans un cycle différent ;
- changement de montant d’une charge ;
- crédit avec 10 échéances restantes ;
- crédit terminé plus tôt ;
- revenu en deux versements ;
- prime exceptionnelle ;
- cinq cycles commençant dans un mois ;
- mois sans cantine ;
- dépense annuelle arrivant deux semaines après onboarding ;
- compte de réserve contenant plusieurs allocations ;
- virement vers réserve puis achat depuis réserve ;
- deux dépenses identiques le même jour ;
- charge et achat ayant le même montant ;
- import du même CSV deux fois ;
- deux membres hors ligne pendant plusieurs jours ;
- correction concurrente ;
- appareil révoqué ;
- perte du code de récupération ;
- changement de compte Google ;
- quota Drive atteint ;
- suppression d’un fichier distant ;
- historique de 10 ans.

---

# 34. Tests

## 34.1. Unitaires

- toutes les formules ;
- récurrences ;
- provisions ;
- arrondis ;
- revenus variables ;
- cycles ;
- scoring ;
- rapprochement ;
- double comptage ;
- import.

## 34.2. Propriétés

Exemples :

- une dépense ne peut réduire qu’une seule fois le budget ;
- un transfert interne ne change pas le patrimoine du foyer ;
- un remboursement lié annule exactement son montant ;
- la somme des allocations virtuelles respecte les règles ;
- une projection identique produit le même résultat ;
- rejouer le journal produit le même état.

## 34.3. Synchronisation

- deux appareils créent simultanément ;
- sync interrompue ;
- segment dupliqué ;
- segment corrompu ;
- ordre différent ;
- snapshot ancien ;
- migration.

## 34.4. Sécurité

- tests de chiffrement ;
- non-réutilisation de nonce ;
- clés absentes des logs ;
- export protégé ;
- révocation ;
- restauration ;
- fuzzing importeurs.

## 34.5. UX

- saisie d’une dépense en moins de cinq secondes ;
- compréhension du montant restant ;
- compréhension semaine/mois ;
- compréhension des trois démarrages ;
- migration express vers détaillé ;
- utilisation par lecteur d’écran.

---

# 35. Critères d’acceptation du MVP

## 35.1. MVP 1 — Manuel local

- création d’un foyer solo ;
- onboarding express et guidé ;
- cycle hebdomadaire ;
- calcul 52 semaines ;
- revenus ;
- charges ;
- dépenses annuelles ;
- réserves ;
- projets ;
- saisie rapide ;
- tableau de bord ;
- export local ;
- verrouillage.

## 35.2. MVP 2 — Partage Drive

- sélection explicite du compte ;
- compte commun ou dossier partagé ;
- chiffrement de bout en bout ;
- invitation QR ;
- deux appareils ;
- fonctionnement hors ligne ;
- synchronisation sans écrasement ;
- snapshots ;
- récupération.

## 35.3. MVP 3 — Import

- CSV ;
- OFX ;
- QIF ;
- mapping ;
- déduplication ;
- sélection des charges ;
- rapprochement manuel ;
- décomposition du total express.

## 35.4. Version expérimentale

- compagnon Woob ;
- lecture seule ;
- traitement local ;
- opt-in ;
- logs nettoyés ;
- aucune télémétrie.

## 35.5. Version ultérieure

- OCR tickets ;
- WebDAV/Nextcloud ;
- application desktop ;
- détection avancée ;
- notifications distantes génériques ;
- import CAMT.

---

# 36. Ordre d’implémentation recommandé pour Codex

## Phase 0 — Fondation

1. créer le dépôt ;
2. créer les packages ;
3. écrire les ADR ;
4. implémenter le type monétaire ;
5. implémenter le moteur de cycles ;
6. implémenter le moteur de projection ;
7. créer les tests de référence.

## Phase 1 — Produit local

1. modèle de données ;
2. SQLite chiffrée ;
3. onboarding express ;
4. onboarding guidé ;
5. revenus/charges ;
6. réserves/projets ;
7. budget hebdomadaire ;
8. saisie rapide ;
9. tendance ;
10. export.

## Phase 2 — Journal d’événements

1. événements immuables ;
2. projection vers SQLite ;
3. snapshots locaux ;
4. migration de schéma ;
5. tests de rejeu.

## Phase 3 — Google Drive

1. abstraction `SyncProvider` ;
2. OAuth explicite ;
3. Drive ;
4. segments ;
5. snapshots distants ;
6. compte commun ;
7. dossier partagé ;
8. invitation ;
9. récupération ;
10. conflits.

## Phase 4 — Import et rapprochement

1. CSV ;
2. OFX ;
3. QIF ;
4. déduplication ;
5. détection ;
6. rapprochement ;
7. cartes à débit différé ;
8. migration express.

## Phase 5 — Woob expérimental

1. spécification du compagnon ;
2. lecture seule ;
3. stockage sécurisé ;
4. association au foyer ;
5. synchronisation chiffrée ;
6. écran expérimental ;
7. documentation.

---

# 37. Règles impératives pour l’agent de développement

1. Ne jamais inventer une formule absente de ce PRD sans créer un ADR.
2. Ne jamais placer de logique financière dans les widgets UI.
3. Ne jamais utiliser de nombres flottants pour l’argent.
4. Ne jamais compter deux fois une opération rapprochée.
5. Ne jamais utiliser silencieusement un compte Google.
6. Ne jamais envoyer une donnée financière en clair hors de l’appareil.
7. Ne jamais modifier automatiquement le budget choisi.
8. Ne jamais présenter un revenu exceptionnel comme durable.
9. Ne jamais faire du mois civil l’unité principale du budget.
10. Ne jamais supprimer une information d’audit pour simplifier l’interface.
11. Ne jamais demander une connexion bancaire pour utiliser l’application.
12. Ne jamais exposer de capacité de virement dans Woob.
13. Ne jamais stocker une clé de foyer dans Drive en clair.
14. Ne jamais synchroniser un unique fichier SQLite partagé.
15. Ne jamais créer un fichier Drive par transaction.
16. Ne jamais fusionner automatiquement deux opérations sur le seul montant.
17. Ne jamais afficher un score fiable si les données sont incomplètes.
18. Ne jamais modifier une charge détectée sans validation.
19. Ne jamais masquer l’impact d’une migration de méthode.
20. Ne jamais rendre l’utilisateur dépendant d’un serveur administré par l’éditeur.

---

# 38. Définition de réussite produit

Le produit est réussi si un foyer peut :

1. comprendre en moins de deux minutes la différence entre budget mensuel et hebdomadaire ;
2. configurer une première estimation sans connexion bancaire ;
3. voir immédiatement combien il peut encore dépenser ;
4. saisir une dépense sans effort ;
5. rester utilisable à plusieurs sans serveur de l’éditeur ;
6. comprendre pourquoi le budget proposé a cette valeur ;
7. voir une tendance utile sans analyser des centaines de transactions ;
8. migrer d’un mode simple vers un mode détaillé sans double comptage ;
9. restaurer dix ans de données sans perte de réactivité ;
10. conserver la maîtrise cryptographique de ses données.

---

# 39. Question produit toujours ouverte

Une seule décision reste volontairement ouverte :

> **Nom commercial et identité visuelle définitive.**

Cette décision ne doit pas bloquer le développement. Utiliser `Budget52` comme nom de travail et identifiant interne jusqu’à décision contraire.
