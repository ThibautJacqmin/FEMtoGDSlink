# Références documentaires

Vérification du 23 octobre 2026, lors de l'analyse initiale du projet Python
indépendant. Les numéros ci-dessous sont
ceux imprimés dans les manuels, pas les indices de pages d'un lecteur PDF.

## Manuels COMSOL conservés localement

La copie fournie par l'utilisateur est la référence de départ. Elle documente
COMSOL **6.3**, tandis que l'installation Windows repérée et la configuration
du projet actuel désignent **6.4**. Les deux éditions doivent rester identifiées
séparément ; une propriété de la 6.4 ne doit pas être présumée présente en 6.3.

| Document | Copie locale | Version indiquée dans le PDF | Pages | Taille |
| --- | --- | --- | ---: | ---: |
| Programming Reference Manual fourni par l'utilisateur | [COMSOL_ProgrammingReferenceManual_user.pdf](references/manuals/COMSOL_ProgrammingReferenceManual_user.pdf) | 6.3 (2024) | 1234 | 14 004 767 octets |
| Programming Reference Manual officiel complémentaire | [COMSOL_ProgrammingReferenceManual_6.4.pdf](references/manuals/COMSOL_ProgrammingReferenceManual_6.4.pdf) | 6.4 (2025) | 1290 | 14 150 505 octets |
| LiveLink for MATLAB User's Guide officiel | [LiveLinkForMATLABUsersGuide_6.4.pdf](references/manuals/LiveLinkForMATLABUsersGuide_6.4.pdf) | 6.4 (2025) | 402 | 7 275 761 octets |

Provenance et identification :

- Copie utilisateur : `C:\Users\ThibautJacqmin\Downloads\COMSOL_ProgrammingReferenceManual.pdf` ; PDF modifié le 5 novembre 2024 ; SHA256 `b24bb4f9af926f0c538fdacf4a1e1bb796d58b86b1ed173dd20b04cbba5af904`.
- [Programming Reference Manual 6.4, source COMSOL](https://doc.comsol.com/6.4/doc/com.comsol.help.comsol/COMSOL_ProgrammingReferenceManual.pdf) : PDF modifié le 22 mai 2026 ; SHA256 `f1d63c6858efea4eaf9cf83fcb0c4b7f0a5e3d73ad6acc28b84665b9468baa39`.
- [LiveLink for MATLAB User's Guide 6.4, source COMSOL](https://doc.comsol.com/6.4/doc/com.comsol.help.llmatlab/LiveLinkForMATLABUsersGuide.pdf) : PDF modifié le 29 septembre 2025 ; SHA256 `735b3d4ac100666224d1ce48c374c32dc9f3fa9a1cdc2c7657e367d8738e80d0`.

Les métadonnées, tailles et empreintes portent sur les fichiers effectivement
lus. Les PDF officiels sont téléchargés comme compléments ; ils ne remplacent
pas le fichier utilisateur. L'installation locale repérée est
`C:\Program Files\COMSOL\COMSOL64\Multiphysics` ; aucune connexion au moteur
n'a été effectuée pendant cette analyse.

## Repères pour la géométrie

| Sujet du Programming Reference Manual | Édition utilisateur 6.3 | Édition officielle 6.4 |
| --- | ---: | ---: |
| Panorama des primitives, opérations, sélections et opérations virtuelles | 240–246 | 248–254 |
| Séquences, création, propriétés, construction et état des features | 247–253 | 255–261 |
| Unités, tolérances et reconstruction | 254–257 | 262–265 |
| Plans de travail | 258 | 266 |
| Sélections nommées et cumulatives | 259–260 | 267–268 |
| Informations géométriques et mesures | 263–270 | 271–278 |
| Début du catalogue détaillé « Geometry Commands » | 276 | 284 |
| `Array` | 279 | 287 |
| `Compose`, `Union`, `Intersection`, `Difference` | 295 | 304 |
| `Mirror` ; `Move`, `Copy` | 355 ; 357 | 365 ; 367 |
| `RigidTransform` ; `Rotate` ; `Scale` | 384 ; 385 ; 387 | 394 ; 396 ; 398 |
| `Offset` ; `Thicken2D` | 359 ; 401 | 369 ; 412 |
| `CrossSection` ; `Extrude` ; `Revolve` ; `Sweep` | 305 ; 324 ; 381 ; 395 | 315 ; 334 ; 392 ; 406 |
| Description détaillée de `WorkPlane` | 407 | 418 |

Le catalogue comprend les dimensions 1D, 2D et 3D. La liste des classes MATLAB
actuelles constitue un sous-ensemble de départ, pas une limite de couverture.
Les manuels renvoient également aux documentations des modules Design, CAD
Import, ECAD Import et LiveLink CAD pour leurs commandes supplémentaires.
Une couverture complète devra donc être recensée par version et par module.

Le guide LiveLink 6.4 fournit des exemples utiles aux pages **54–82**
(géométrie) et **166–167** (`set`, `setIndex`, valeurs, expressions et unités).
Il sert à comprendre la sémantique COMSOL ; ses fonctions auxiliaires MATLAB
ne deviennent pas des dépendances du futur projet.

Les signatures Java 6.4 sont vérifiables dans les pages officielles
[GeomSequence](https://doc.comsol.com/6.4/doc/com.comsol.help.comsol/api/com/comsol/model/GeomSequence.html)
et [GeomFeature](https://doc.comsol.com/6.4/doc/com.comsol.help.comsol/api/com/comsol/model/GeomFeature.html).
Elles permettent notamment de vérifier `create`, `feature`, `run`, `geom`,
`selection` et `objectNames`, au lieu d'inventer des alias.

## MPh : accès Python à COMSOL

Pour les fonctions ajoutées le 26 octobre, la page COMSOL 6.4
[Mathematical Functions](https://doc.comsol.com/6.4/doc/com.comsol.help.comsol/comsol_ref_definitions.21.037.html)
documente notamment `max`, `round`, `floor`, `abs` et `sign`. La règle des
demi-entiers n'y étant pas précisée, l'export de `round_nearest(x)` écrit
explicitement `sign(x)*(floor(abs(x))+(abs(x)-floor(abs(x))>=0.5))`.
Les tests sur le serveur vérifient l'accord avec le calcul Python pour les
demi-entiers positifs/négatifs, le flottant immédiatement inférieur à 0.5
et un grand entier exactement représentable. Les deux fonctions publiques
`maximum` et `round_nearest` exigent ici des arguments sans unité.

Pour les paramètres (vérifié le 25 octobre 2026),
[`model.param()`](https://doc.comsol.com/6.4/doc/com.comsol.help.comsol/comsol_api_general.47.50.html)
documente `set(name, expression, description)`, `get`, `evaluate` et
`evaluateUnit`. Les paramètres globaux et les propriétés des features gardent
leurs expressions. `GeomSequence.angularUnit(...)`, documenté dans l'API Java
citée plus haut, complète `lengthUnit(...)` pour fixer le contexte de la géométrie.

La documentation stable consultée affiche **MPh 1.4.0** ; cela ne mesure pas la
version installée sur le poste.

- [API Model](https://mph.readthedocs.io/en/stable/api/mph.Model.html) : `mph.Model.java` expose le modèle Java COMSOL complet. La création géométrique détaillée pourra utiliser les commandes du Programming Reference Manual via cet objet.
- [Installation](https://mph.readthedocs.io/en/stable/installation.html) : dépendances JPype et NumPy, Python Windows 64 bits, JVM livrée avec COMSOL. Le document annonce COMSOL 6.0 et suivants comme attendus, avec essais annoncés jusqu'à 6.3 ; la compatibilité du poste en 6.4 reste à valider.
- [Découverte des installations](https://mph.readthedocs.io/en/stable/api/mph.discovery.html) : MPh assure déjà la recherche de COMSOL, notamment par le registre Windows. Ce module est interne ; éviter d'en recopier la logique dans le projet.
- [Limitations](https://mph.readthedocs.io/en/stable/limitations.html) : un client/JVM par processus ; les sessions indépendantes parallèles nécessitent plusieurs processus. Les modes autonome et client–serveur ont des contraintes de plateforme différentes.

## KLayout : API principale et guides

Référence API principale fournie par l'utilisateur et vérifiée :
[index des classes KLayout, documentation Qt 5](https://www.klayout.de/doc-qt5/code/index.html).
Cet index distingue notamment les modules `db` (base de données géométrique)
et `lay` (interface graphique).

- [Module Python autonome](https://www.klayout.org/klayout-pypi/) : `klayout.db` permet de créer, manipuler et écrire les layouts GDS sans dépendre de l'interface graphique.
- [Utilisation de Python](https://www.klayout.de/doc-qt5/programming/python.html) : exemple de référence avec `import klayout.db as kdb` et différences de syntaxe entre les interfaces Ruby et Python. La page recommande les sous-modules `klayout` et indique que l'ancien module combiné `pya` est déprécié.
- [Geometry API](https://www.klayout.de/doc/programming/geometry_api.html) : polygones, régions, courbes polygonales, transformations et opérations booléennes ; à consulter pour les contours GDS et leur discrétisation.
- [Application API](https://www.klayout.de/doc/programming/application_api.html) : fenêtres, vues et sessions Desktop, utile pour une éventuelle prévisualisation. `Layout`, `Cell` et les couches du fichier restent accessibles dans `klayout.db`.

Les pages KLayout consultées sont évolutives. Elles ne prouvent pas la version
installée localement ; les propriétés retenues devront être confrontées à la
version choisie pour le futur environnement Python.
