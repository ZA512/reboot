# REBOOT dans Excel

Ce sous-projet permet d'appliquer la méthode REBOOT sans attendre l'application et sans macro. Le classeur reste volontairement centré sur la semaine et sur un horizon glissant de 52 semaines.

## Ordre d'utilisation

1. **Budget annuel** : activez les entrées et sorties qui vous concernent, indiquez leur rythme, leur caractère fixe ou variable et la méthode d'estimation. Les cellules bleues sont à remplir ; les cellules vertes reprennent un résultat d'un autre onglet.
2. **Bien démarrer** : saisissez la réalité du compte, les opérations encore en attente, le découvert autorisé, le solde souhaité et la marge d'incertitude. Testez la date du premier REBOOT. Le classeur distingue le solde visé du coussin technique nécessaire pour absorber le calendrier réel.
3. **Semaine en cours** : choisissez le plan validé et saisissez les dépenses au fil de la semaine. Le montant restant et le repère quotidien sont recalculés automatiquement.
4. **Historique** : en fin de semaine, recopiez le budget et les dépenses avant d'effacer les lignes de l'onglet précédent. Les balances sur 4, 8, 16, 32 et 52 semaines servent à voir la tendance sans modifier automatiquement la semaine suivante.

## Points importants

- Une charge déjà incluse dans le budget hebdomadaire doit être marquée comme telle pour éviter un double comptage.
- Une prime exceptionnelle n'entre dans le quotidien que pour la part déjà reçue et réellement affectée à cet usage.
- Le découvert éventuellement affecté au coussin reste un financement bancaire : le classeur le sépare de la trésorerie propre.
- Une date ou un plan affiché comme possible doit toujours être vérifié avec le solde réel et les opérations en attente.
- Le passage d'un budget temporaire au budget durable n'est jamais automatique.
- Un bonus ou un malus hebdomadaire ne change pas le budget de la semaine suivante : l'utilisateur décide lui-même quand agir.

Le fichier à utiliser est `REBOOT-methode.xlsx`.
