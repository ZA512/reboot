# ADR-0002 — Cycles hebdomadaires en dates civiles locales

- Statut : Accepted
- Date : 2026-07-29
- Accepté le : 2026-07-30
- Décideur : porteur du projet REBOOT

## Contexte

Le PRD définit un cycle comme sept dates civiles locales afin que les changements d’heure ne créent pas de cycle de six ou huit jours. Il prévoit également une heure de début configurable. Un cycle commençant à une autre heure que minuit ne correspond plus exactement à sept dates civiles.

Les changements de fuseau et la correction tardive d’une dépense ne doivent pas déplacer silencieusement une opération historique vers un autre cycle.

## Décision

Pour le MVP :

- un cycle normal est identifié par une `LocalDate` de début et contient exactement sept dates locales consécutives ;
- le jour d’ancrage est choisi pendant l’onboarding en fonction du rythme réel du foyer, idéalement le jour de sa principale dépense alimentaire ;
- l’heure d’ancrage est fixée à 00:00 locale et n’est pas modifiable ;
- aucun calcul métier ne repose sur une durée de 168 heures ;
- une dépense est affectée selon sa date d’achat dans le fuseau du foyer applicable au moment de sa création ;
- l’affectation historique ne change pas après un changement de fuseau ou de jour d’ancrage, sauf correction explicite de la dépense ;
- chaque cycle matérialisé conserve les informations de politique nécessaires à son audit : fuseau IANA, jour d’ancrage et version de politique ;
- un changement de politique possède une date d’effet et ne réécrit pas les cycles clos.

Le jour d’ancrage peut être modifié si les habitudes du foyer changent. Cette modification crée un cycle exceptionnel de transition, plus court ou plus long que sept dates :

- le cycle de transition est identifié explicitement et conserve ses dates réelles ;
- il conserve le budget hebdomadaire applicable, sans compensation automatique avec le cycle suivant ;
- l’interface signale que sa durée est atypique ;
- il reste visible dans l’historique, mais il est exclu par défaut des tendances comparant des cycles hebdomadaires normaux ;
- tous les cycles suivants recommencent au nouveau jour d’ancrage et contiennent sept dates.

L’horizon de soutenabilité comprend 52 cycles identifiés par leurs dates. La recommandation recalculée n’écrase jamais le budget déjà choisi pour le cycle actif.

## Options étudiées

### Option A — Intervalles de 168 heures

Écartée : elle contredit la règle des dates civiles et dérive lors des changements d’heure.

### Option B — Jour et heure configurables sans cycle de transition

Écartée pour le MVP : elle exige des intervalles locaux semi-ouverts, ne résout pas proprement le changement de jour et complique l’expérience sans besoin établi pour une heure différente de minuit.

### Option C — Sept dates civiles à partir de minuit

Recommandée pour le MVP : comportement compréhensible, déterministe et testable.

## Conséquences

### Positives

- stabilité lors des passages heure d’été/heure d’hiver ;
- explication simple pour l’utilisateur ;
- tests indépendants de la durée réelle d’une journée ;
- historique auditable après changement de configuration.

### Négatives

- `cycle_anchor_time` reste réservé à 00:00 dans le MVP ;
- le modèle `WeeklyCycle` doit conserver davantage de contexte que prévu initialement.
- le modèle doit accepter un cycle de transition exceptionnel et les tableaux de bord doivent le distinguer des cycles normaux.

## Cas de test minimaux

- cycle traversant chaque changement d’heure européen ;
- année bissextile ;
- achat juste avant et juste après minuit ;
- changement de fuseau avec cycles historiques ;
- changement du jour d’ancrage avec date d’effet ;
- cycle de transition plus court et plus long que sept dates ;
- exclusion par défaut du cycle de transition dans les tendances hebdomadaires ;
- suite de cycles normaux et de transition sans trou ni chevauchement ;
- 52 cycles normaux consécutifs sans changement de politique.

## Liens

- PRD REBOOT 2.0 : sections 2.1, 8, 9 et 22.
- Méthode REBOOT : sections « Démarrage du premier cycle » et « Cycle hebdomadaire ».
- PRD Budget52 archivé : sections 2.1, 7.1, 8.1, 13.4, 29.1, 29.12 et 33.
- Analyse : `docs/foundation-analysis.md`, FND-02.
