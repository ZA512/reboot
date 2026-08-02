# ADR-0012 — Hébergement et contrat de sécurité PWA

- Statut : Accepted
- Date : 2026-08-02
- Décidé le : 2026-08-02
- Décideur : responsable de l’implémentation REBOOT

## Contexte

La clé Web Crypto non extractible protège une copie brute du stockage, mais
elle reste utilisable par tout JavaScript exécuté sur la même origine. La PWA
doit aussi mettre à jour son shell sans conserver indéfiniment un document de
démarrage ou un service worker périmé.

Un hébergement statique HTTPS ne suffit donc pas. La politique de contenu, les
en-têtes d’isolation, le cache et l’absence de code tiers font partie de la
frontière de sécurité de REBOOT et doivent être vérifiés au même titre que le
code Dart.

## Décision

### Artefact unique

La seule sortie publiable est produite depuis `apps/reboot_app` par :

```shell
dart run tool/build_web_release.dart
```

Cette commande construit Flutter sans CDN, vérifie le contrat d’hébergement,
retire le service worker Flutter éventuel et génère le service worker REBOOT à
partir d’une liste exacte et empreintée des ressources du shell.

Le fichier `_headers` est livré avec `build/web`, mais n’est jamais ajouté au
cache du service worker. Une configuration manquante ou affaiblie fait échouer
la préparation du build et les tests.

### Origine et fournisseur

La cible de référence est Cloudflare Pages, qui sait appliquer le fichier
statique `_headers`, publier un déploiement immuable et revenir à un
déploiement antérieur. Un autre hébergeur reste possible uniquement s’il
reproduit exactement ce contrat sur toutes les réponses.

L’origine de production est réservée à REBOOT. Aucun autre site, script
marketing, gestionnaire de balises ou outil d’administration ne partage cette
origine. Les données financières restent exclusivement dans le navigateur ;
l’hébergement ne reçoit que des requêtes de ressources statiques.

### Politique de contenu

La CSP de production :

- limite par défaut toutes les ressources à la même origine ;
- interdit objets, cadres, formulaires et intégration de REBOOT dans une page
  tierce ;
- interdit les scripts inline et `unsafe-eval` ;
- autorise seulement `wasm-unsafe-eval`, nécessaire à WebAssembly sans ouvrir
  l’évaluation arbitraire de JavaScript ;
- autorise le service worker de même origine et les workers Blob nécessaires à
  l’exécution Flutter ;
- ne prévoit aucune origine de CDN, d’analyse ou de publicité.

L’URL de repli des polices Flutter est redirigée vers le shell local. Les
sous-ensembles Roboto et Noto Sans Symbols effectivement requis sont embarqués,
empreintés et accompagnés de leur licence ; le navigateur ne contacte donc pas
Google Fonts.

`style-src 'unsafe-inline'` est conservé parce que le moteur Flutter crée des
styles à l’exécution. Cette exception ne s’étend pas aux scripts.

`Cross-Origin-Opener-Policy: same-origin` et
`Cross-Origin-Embedder-Policy: require-corp` isolent le contexte et préparent
le fonctionnement WebAssembly multithread. Toutes les ressources applicatives
sont servies par la même origine.

### Cache et mises à jour

La racine, `index.html` et le service worker sont servis avec `no-store` et
doivent être revalidés. Le bootstrap et le manifeste sont également revalidés.
Les ressources du shell hors ligne sont gérées par le cache versionné REBOOT,
qui ne répond qu’aux navigations et aux URL statiques de son manifeste exact.

Une publication est atomique : on publie le dossier construit complet, jamais
des fichiers remplacés un à un. Une vérification après déploiement contrôle au
minimum la CSP, les en-têtes d’isolation, le service worker, le démarrage en
ligne et le redémarrage hors ligne. Un échec empêche la promotion ou déclenche
le retour au déploiement précédent.

## Options étudiées

### GitHub Pages direct

Écarté pour la PWA financière : il ne permet pas au dépôt de définir ce contrat
d’en-têtes sur les réponses. Il reste adapté à une future page publique de
présentation, sur une origine distincte et sans données.

### CDN ou scripts tiers

Écartés. Le gain de poids ou de mesure d’audience ne compense pas l’ajout d’un
acteur capable d’exécuter du code dans l’origine qui utilise la clé locale.

### CSP par balise HTML uniquement

Écartée : elle ne couvre pas toutes les directives nécessaires, notamment la
protection contre l’intégration dans une frame et les en-têtes d’isolation.

## Conséquences

### Positives

- politique de production versionnée et testée avec le code ;
- aucune dépendance d’exécution à un tiers ;
- déploiement reproductible et retour arrière complet ;
- compatibilité avec le shell hors ligne JavaScript et l’évolution Wasm.

### Négatives

- toute future intégration OAuth ou ressource externe exigera une décision et
  une modification explicite de la CSP ;
- la validation réelle de Safari iPhone et du fournisseur reste nécessaire
  avant activation des données Web ;
- une compromission de la chaîne de build ou du compte d’hébergement reste
  capable de remplacer l’application et doit être traitée séparément.

## Liens

- ADR liés : ADR-0006, ADR-0008, ADR-0009 et ADR-0011.
- [En-têtes Cloudflare Pages](https://developers.cloudflare.com/pages/configuration/headers/)
- [Flutter WebAssembly](https://docs.flutter.dev/platform-integration/web/wasm)
- [CSP `script-src`](https://developer.mozilla.org/docs/Web/HTTP/Reference/Headers/Content-Security-Policy/script-src)
- [CSP `worker-src`](https://developer.mozilla.org/docs/Web/HTTP/Reference/Headers/Content-Security-Policy/worker-src)
