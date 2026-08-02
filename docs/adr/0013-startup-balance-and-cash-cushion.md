# ADR-0013 — Objectif de solde et financement du coussin de démarrage

- Statut : Accepted
- Date : 2026-08-02
- Décideurs : porteur du produit et responsable de l’implémentation REBOOT

## Contexte

Le complément de PRD sur la phase de démarrage distingue le budget durable de
la trésorerie nécessaire pour supporter le calendrier réel des flux. Sa formule
initiale mélange toutefois le solde déjà disponible, le niveau de compte désiré
et le coussin technique. Dans certains cas, la trésorerie présente est alors
comptée deux fois.

Le produit doit pouvoir expliquer simplement un cas courant : un foyer vit
habituellement autour de -1 500 €, souhaite revenir à 0 €, mais doit encore
absorber des variations normales entre revenus et charges une fois cet objectif
atteint.

## Décision

REBOOT sépare trois informations.

### Objectif de solde

L’`objectif de solde` est le niveau bancaire que l’utilisateur veut retrouver
après redressement. Il vaut souvent 0 €, mais reste un choix explicite. Il ne
sert pas à mesurer l’amplitude des variations de calendrier.

### Besoin de coussin

La projection quotidienne commence avec une variation cumulée nulle, puis
applique les revenus, charges, dépenses connues et engagements hebdomadaires
datés. Le besoin technique est l’amplitude nécessaire pour absorber son plus
grand creux :

```text
variation_cumulée_minimale = minimum des variations cumulées quotidiennes

coussin_technique = max(0, -variation_cumulée_minimale)

coussin_cible = coussin_technique + marge_incertitude_lancement
```

Ce calcul est indépendant du solde actuel et de l’objectif de solde. Il répond
uniquement à la question : « quelle amplitude faut-il pouvoir absorber ? »

### Financement du coussin

Le coussin cible est financé par une combinaison exacte de :

- trésorerie propre laissée sur le compte ;
- découvert autorisé explicitement affecté au coussin.

```text
coussin_propre + coussin_financé_par_découvert = coussin_cible

niveau_de_fonctionnement = objectif_de_solde + coussin_propre

point_bas_autorisé = objectif_de_solde - coussin_financé_par_découvert
```

Exemples pour un objectif de solde de 0 € et un coussin cible de 400 € :

- 400 € propres : le compte atteint 400 € avant le fonctionnement normal et ne
  doit normalement pas passer sous 0 € ;
- 400 € de découvert : le compte atteint 0 €, mais peut descendre jusqu’à
  -400 € à cause du calendrier ;
- financement mixte 250 € / 150 € : niveau de fonctionnement à 250 € et point
  bas autorisé à -150 €.

Le financement par découvert est plafonné par le découvert autorisé réellement
disponible. Il est présenté comme une trésorerie financée par la banque, avec
risque de frais et de réduction unilatérale de l’autorisation. Il n’est jamais
préselectionné ni qualifié de solution la plus sûre.

### Phase de redressement

Le besoin total de progression vers le fonctionnement normal est calculé sans
confondre les deux objectifs :

```text
progression_requise =
    max(0, niveau_de_fonctionnement - trésorerie_réellement_disponible)
```

Chaque plan de lancement est ensuite simulé quotidiennement. Par défaut, un
foyer déjà à découvert ne reçoit aucune proposition qui aggrave son point bas
actuel. Une dérogation reste possible conformément à la liberté laissée à
l’utilisateur, mais elle exige une acceptation explicite et n’est jamais
étiquetée sûre ou recommandée.

## Conséquences

### Positives

- l’objectif personnel et la contrainte technique sont compréhensibles
  séparément ;
- aucun euro présent n’est déduit deux fois ;
- le même moteur couvre coussin propre, découvert et financement mixte ;
- REBOOT peut expliquer pourquoi « revenir à zéro » et « ne plus passer sous
  zéro » ne demandent pas toujours le même effort.

### Négatives

- le wizard doit demander comment le coussin est financé ;
- un utilisateur choisissant le découvert conserve un risque bancaire réel ;
- le solde bancaire visible peut être supérieur à l’objectif lorsque le coussin
  est entièrement financé avec de la trésorerie propre.

## Liens

- PRD complémentaire : `docs/PRD_REBOOT_Complement_Phase_Demarrage_v1.1.md`
- ADR liés : ADR-0002, ADR-0003 et ADR-0006.
