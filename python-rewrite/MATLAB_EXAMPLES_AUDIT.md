# Comparaison des paramètres et coordonnées MATLAB/Python

Audit du 26 octobre 2026. Les six scripts MATLAB présents dans le projet
parent ont été relus, ainsi que leurs usages de `Parameter`, de formules
dépendantes et de `Vertices`. Deux lacunes ont été corrigées : les fonctions
paramétrées maximum/arrondi et l'enregistrement d'un paramètre global qui
n'est pas utilisé par la géométrie.

**Validation : 81 tests réussis, dont 9 tests natifs COMSOL, aucun ignoré.**
La session Python connectée a été conservée ouverte après les tests.

Cet audit vérifie les données et leurs compositions. Il ne signifie pas que
les six géométries MATLAB s'exécutent déjà en Python : seules les features
`Square` et `Rotate` sont actuellement implémentées. Les calculs destinés aux
autres features sont testés séparément, sans simuler leur implémentation.

## Comparaison par exemple

| Source MATLAB | Comportements examinés | Résultat et adaptation Python |
| --- | --- | --- |
| [example_1.m](../example_1.m), lignes 20–63 | Largeurs calculées dans une boucle, coordonnées multipliées à gauche/droite par un pitch, facteur sans unité, angles, nombre de points `max(8, round(3*x))`. | Calculs et références conservés. Ajout de `maximum` et de l'arrondi paramétré ; normalisation explicite du rayon par 1 µm. Test des six largeurs et positions, puis modification du rayon, de la largeur et du pitch. `Fillet`, booléens et autres transformations restent à porter. |
| [example_2.m](../example_2.m), lignes 20–82 | Positions avec préfacteur, nombres d'éléments sans unité, pas de réseaux, lecture de `.value` pour les lattices. | Compositions des pas et des nombres d'éléments vérifiées. Passer un paramètre garde sa référence ; `.value` fournit volontairement une valeur figée à cet instant. Les réseaux et lattices eux-mêmes ne sont pas implémentés. |
| [example_3.m](../example_3.m), lignes 19–78 | Épaisseur dérivée, tableaux de points, points de contrôle, angles, bornes 0/π/2π, noms globaux utilisés dans des chaînes `pc_rx*cos(s)`. | Tableaux et dépendances pris en charge ; ajouter une constante à une longueur exige son unité. `add_parameter` permet désormais d'enregistrer les paramètres non référencés par une feature. **Les courbes paramétriques et leurs expressions textuelles restent non prises en charge.** |
| [example_4.m](../example_4.m), lignes 19–52 | Deux épaisseurs dérivées, rapport nommé `dummy` sans usage géométrique, paramètre créé directement dans un préfacteur. | `DependentParameter` remplace la construction MATLAB par fonction anonyme ou renommage d'expression. `project.add_parameter(dummy)` exporte explicitement le rapport et ses dépendances. Test du rapport 0.7, puis 1 après modification. Chamfer, Offset et Tangent ne sont pas implémentés. |
| [example_5.m](../example_5.m), lignes 19–135 | Paramètres CPW, listes de largeurs et décalages signés, mélange avec zéro, marqueurs partageant un nom. | Listes Python de scalaires et calculs signés vérifiés. Les deux créations distinctes de `ex5_tip_E` aux lignes 99–100 doivent devenir **un même objet réutilisé** ; les collisions de noms sont rejetées. Ports, CPW, masques et routage ne sont pas encore portés. |
| [example_6.m](../example_6.m) | Géométrie numérique sans constructeur `Parameter`/`Vertices`, longueurs MATLAB en nm. | Attention au changement d'unité par défaut : Python utilise les µm. Conversion explicite testée avec `Vertices(..., unit="nm")` et un paramètre en nm ; le contrôle GDS utilise un carré, pas les booléens de cet exemple. |

`femtogds_config_example.m` ne contient pas de calcul de paramètre ou de tableau
de coordonnées à transposer.

## Traductions concrètes

Une formule dépendante se construit avec les objets Python. Aucune analyse
de lambda ni évaluation d'une chaîne n'est nécessaire :

```python
from femtogds import Parameter, DependentParameter, Vertices, maximum

um = Parameter(1, "unit_um", unit="um")
seed = Parameter(0.25, "line_thk_seed", unit="um")
thickness = DependentParameter(seed + 0.15 * um, "line_thk")

radius = Parameter(8, "fillet_r", unit="um")
count = DependentParameter(maximum(8, round(3 * radius / um)), "fillet_n")

pitch = Parameter(36, "pitch_y", unit="um")
points = Vertices([[0, 0], [0, 1], [0, 2]], pitch)
shifted = points + Vertices([-190, -10], um)
```

Les fonctions MATLAB qui ajoutaient `0.15` à la valeur numérique d'un
paramètre en µm se traduisent par `seed + 0.15 * um`. De même, `radius / um`
fournit explicitement le nombre de micromètres utilisé pour calculer `count`.
Les paramètres dimensionnés ne perdent pas silencieusement leur unité.

`maximum(a, b)` accepte deux expressions sans unité. Le `max()` Python
ordinaire ne construit pas une formule paramétrée. `round(expression)` et
`round_nearest(expression)` arrondissent à l'entier, avec les demi-entiers
éloignés de zéro, comme MATLAB : 2.5 donne 3 et -2.5 donne -3. Cette règle
concerne les objets paramétrés ; `round(2.5)` reste la fonction numérique
Python habituelle. L'arrondi à un nombre de décimales non nul n'est pas géré.

Les dépendances géométriques sont détectées automatiquement. Pour un paramètre
global destiné à un usage ultérieur dans la simulation :

```python
ratio = DependentParameter(thickness / radius, "ratio")
project.add_parameter(ratio)
project.build()
```

L'enregistrement conserve l'objet et ses dépendances, sans connecter ni
construire immédiatement, y compris en mode live. Une couche avec
`comsol=True` est nécessaire pour envoyer les définitions au serveur.
Un nouvel appel avec le même objet est sans effet supplémentaire ; un autre
objet portant un nom déjà utilisé est refusé avant modification du registre.

## Contrat commun et différences explicites

- Les opérations `+`, `-`, `*`, `/`, les signes unaires et les fonctions
  précédentes conservent les références. Une modification de `.value` se
  propage aux dépendants et coordonnées lors de leur prochaine évaluation.
  `build()` actualise les exports, même en mode live.
- Les unités compatibles se convertissent ; les dimensions incompatibles,
  cycles, divisions par zéro, valeurs non finies et noms en conflit sont
  rejetés. Le zéro littéral peut s'ajouter à une grandeur dimensionnée.
- `Vertices` accepte les points, tableaux N×2 et grilles N×M×2, les nombres,
  paramètres et expressions, les préfacteurs, translations avec un point,
  extractions, affectations, concaténations et centroïdes. Les tests existants
  couvrent aussi NumPy, tableaux vides, formes invalides et mutations atomiques.
- Les indices Python commencent à zéro ; les grilles suivent l'ordre Python,
  pas l'ordre linéaire MATLAB. Les nombres sont en µm par défaut. Les unités
  compatibles mélangées sont acceptées ; elles ne sont pas héritées d'un voisin.
- Les listes de scalaires (largeurs, décalages) sont des listes Python.
  `Vertices` désigne des coordonnées 2D, pas un tableau scalaire de forme arbitraire.
- COMSOL reçoit les formules et paramètres globaux. Le GDS est recalculé
  numériquement. Une modification faite uniquement dans COMSOL ne remonte pas
  dans Python ; le prochain build Python réapplique ses propres définitions.
- Les signatures MATLAB ne sont pas une API de compatibilité : les fonctions
  anonymes et `Parameter(expression, ...)` deviennent `DependentParameter`.
  L'enregistrement global implicite devient explicite pour les paramètres
  absents de la géométrie.

La parité avec toute la classe MATLAB `Parameter` n'est pas revendiquée : les
puissances, fonctions symboliques générales (`sin`, `cos`, `sqrt`, etc.) et
expressions textuelles restent absentes. Les puissances ne sont pas utilisées
dans les définitions scalaires des six scripts ; les chaînes trigonométriques
de l'exemple 3 nécessiteront le port de `ParametricCurve`.

## Preuves et périmètre restant

[test_matlab_parameter_patterns.py](tests/test_matlab_parameter_patterns.py)
ajoute huit tests : un par exemple pour ses calculs de paramètres/coordonnées,
un pour les arrondis limites et un pour l'enregistrement explicite.
Ils complètent les tests existants de paramètres, Vertices, géométrie et sélections.

La suite complète a été exécutée sur COMSOL : **81 tests en 21.220 s, tous
réussis**, dont 9 natifs. Les contrôles natifs couvrent les modifications des
paramètres dans COMSOL, les coordonnées et centres de rotation paramétrés,
les deux modes de construction, les sélections et les expressions relues
dans les MPH sauvegardés. Le nouveau test dans
[test_comsol_parameters.py](tests/test_comsol_parameters.py) vérifie aussi
maximum/arrondi et les paramètres explicitement enregistrés.

Les géométries MATLAB complètes ne font pas partie de cette exécution. De plus,
`tests/TestExamplesMsq3.m` du projet parent cite quatre fichiers absents :

- `example_6_msq3_membrane_chip.m`
- `example_7_msq3_meca_lc_chip.m`
- `example_8_msq3_membrane_wafer.m`
- `example_9_msq3_meca_lc_wafer.m`

Leur comportement ne peut pas être déduit de ce seul test et n'a pas été
audité. Aucun fichier MATLAB ni modèle utilisateur existant n'a été modifié.
