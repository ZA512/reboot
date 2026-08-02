# Composants tiers embarqués

## Noto Sans Symbols

REBOOT embarque le sous-ensemble Web `Noto Sans Symbols` demandé par le moteur
Flutter 3.44.8 afin que la PWA ne contacte pas Google Fonts à l’exécution.

- fichier :
  `apps/reboot_app/web/font-fallback/notosanssymbols/v43/rP2up3q65FkAtHfwd-eIS2brbDN6gxP34F9jRRCe4W3gfQ8gb_VFRkzrbQ.woff2` ;
- source : `https://fonts.gstatic.com/s/notosanssymbols/v43/` ;
- SHA-256 :
  `08202e258ea583254c036cff46a7077bb5af4f82c41a6c0a6775f6e44d99f1aa` ;
- licence : SIL Open Font License 1.1, reproduite dans
  [`noto-sans-symbols-OFL.txt`](noto-sans-symbols-OFL.txt) ;
- dépôt amont :
  [google/fonts — Noto Sans Symbols](https://github.com/google/fonts/tree/main/ofl/notosanssymbols).

La version de chemin correspond aux données de repli du SDK Flutter épinglé.
Lors d’une mise à niveau du SDK, reconstruire la PWA sous CSP, relever tout
nouveau repli demandé et vérifier sa source, sa licence et son empreinte avant
de modifier cet inventaire.

## Roboto

REBOOT embarque également le sous-ensemble Web Roboto demandé au démarrage par
CanvasKit :

- fichier :
  `apps/reboot_app/web/font-fallback/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2` ;
- source : `https://fonts.gstatic.com/s/roboto/v32/` ;
- SHA-256 :
  `35b02ca266b79eb4996590f15817425a1ce9ebf48f84471843233ff614656bf2` ;
- licence : SIL Open Font License 1.1, reproduite dans
  [`roboto-OFL.txt`](roboto-OFL.txt) ;
- dépôt amont :
  [google/fonts — Roboto](https://github.com/google/fonts/tree/main/ofl/roboto).
