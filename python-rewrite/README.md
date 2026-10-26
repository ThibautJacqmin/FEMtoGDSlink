# Projet Python — COMSOL et GDS

Ce projet crée des formes dans COMSOL avec `mph` et écrit leur géométrie GDS
avec `klayout.db`. La première forme disponible est `Square`. Les longueurs
numériques sont en micromètres et les angles numériques en degrés. Les
paramètres peuvent porter une autre unité compatible.

Dans COMSOL, on travaille toujours dans un **composant 3D** :

```text
Component (comp1)
└── Geometry (geom1, 3D)
    └── Work Plane (wp1)
        └── Plane Geometry (2D)
            └── Square
```

## Un carré

```python
from femtogds import Project
from femtogds.primitives import Square

project = Project()
metal = project.add_layer("metal", comsol=True, gds=True)
Square(project, layer=metal, side=20, position=(10, 5))
project.build()
```

Les deux destinations se choisissent indépendamment **par couche**. Utiliser
`comsol=False` pour produire seulement le GDS. Avec `Project(live=True)`, chaque
forme est construite dès sa création ; sinon, appeler `project.build()`.

`project.show()` ouvre les interfaces. Dans COMSOL Desktop, sélectionner le
modèle indiqué dans la console avec **File > COMSOL Multiphysics Server >
Import Application from Server**. KLayout recharge le GDS automatiquement.

## Utiliser les exemples

Les exemples sont des scripts ordinaires : modifier les paramètres en haut,
puis appuyer sur **Run** dans l'éditeur. Les variables `project`, `square` ou
`rotated` restent accessibles après l'exécution dans une console interactive.
Ils suivent l'ordre imports, paramètres, projet et couches, géométrie,
construction et affichage.

Configurer l'éditeur une fois avec l'interpréteur
`python-rewrite/.venv/Scripts/python.exe` et le dossier de travail
`python-rewrite/`. Les fichiers créés se trouvent dans son dossier `output/`.
Le serveur COMSOL doit être ouvert sur `localhost:2036` avant d'exécuter une
couche COMSOL.

| Script | Objet de l'exemple |
| --- | --- |
| `example_square.py` | Un carré avec `angle` directement dans sa définition. |
| `example_rotation.py` | Un carré et sa copie créée par `Rotate`. |
| `example_selections.py` | Des sélections FEM regroupant deux couches. |
| `example_live.py` | La construction immédiate, cellule par cellule. |
| `example_parameters.py` | Des paramètres et des formules conservés dans COMSOL. |
| `example_vertices.py` | Un tableau de positions paramétrées, un pas commun et une translation. |

Pour produire uniquement le GDS, mettre `comsol=False` sur les couches.
Pour construire sans ouvrir les fenêtres, commenter `project.show()`.
Le chemin de sortie se modifie directement dans `Project(output=...)`.
Les connexions au serveur utilisent les valeurs par défaut ; si nécessaire,
les préciser une fois dans `Project(host="localhost", port=2036, ...)`.

Dans `example_live.py`, les commentaires `# %%` délimitent les cellules.
Exécuter d'abord la cellule du projet, sélectionner son modèle dans COMSOL,
puis exécuter les cellules de géométrie pour voir les changements successifs.
La création des objets déclenche la construction ; après modification d'un
attribut existant, appeler `project.build()` comme dans la dernière cellule.

Relancer un script dans la même console réutilise la connexion COMSOL et crée
un nouveau modèle. Les fenêtres déjà lancées pour cette sortie sont réutilisées ;
dans COMSOL, sélectionner le nouveau modèle indiqué dans la console avec
**Import Application from Server**. Les modèles précédents restent disponibles.

Une nouvelle exécution met normalement à jour les fichiers de sortie. Si un
autre modèle garde le fichier MPH ouvert, l'export utilise automatiquement un
nom numéroté (`example_square_2.mph`, etc.) et affiche son chemin. Le fichier
ouvert reste intact. `project.mph_path` indique toujours le chemin réellement
utilisé ; le GDS conserve son chemin habituel pour la prévisualisation.

## Paramètres et formules

`Parameter` représente une valeur modifiable, `DependentParameter` une formule
nommée. Les dimensions, positions, angles et centres de rotation acceptent ces
objets directement :

```python
from femtogds import Project, Parameter, DependentParameter
from femtogds.primitives import Square
from femtogds.transforms import Rotate

width = Parameter(20, "width", unit="um", description="Largeur du carré")
gap = Parameter(500, "gap", unit="nm")
angle = Parameter(45, "angle", unit="deg")
pitch = DependentParameter(width + 2 * gap, "pitch")

project = Project(output="output/parameters")
metal = project.add_layer("metal", comsol=True, gds=True)
square = Square(project, layer=metal, side=width,
                position=(pitch, 0), angle=angle)
rotated = Rotate(square, angle=angle / 2, keep=True)
project.build()
```

Les paramètres utilisés et leurs dépendances sont détectés automatiquement.
`project.parameters` permet de retrouver ces objets par leur nom. Un nom doit
commencer par une lettre et contenir des lettres ASCII, chiffres ou `_`.
Réutiliser le même objet lorsque plusieurs features partagent un paramètre ;
deux objets distincts portant le même nom dans un projet sont refusés.

Pour un paramètre destiné à la simulation mais encore absent de la géométrie,
utiliser `project.add_parameter(parameter)`. Ses dépendances sont aussi incluses.
L'enregistrement ne déclenche ni connexion ni construction, même en mode live ;
`build()` exporte sa définition dès qu'une couche COMSOL est activée.

Dans COMSOL, les paramètres des couches COMSOL deviennent des paramètres
globaux : `width = 20[um]`, `gap = 500[nm]`, `pitch = width + 2*gap`.
La feature garde `width` comme côté et `pitch` comme position. Les formules
restent donc utilisables lors d'une modification dans COMSOL ou d'un balayage
paramétrique. Le GDS contient les polygones évalués à la construction.

Pour mettre à jour les deux exports depuis Python :

```python
width.value = 30
project.build()
print(pitch.value)  # 31 µm : la dépendance se recalcule.
```

Appeler `build()` après une modification de valeur, **même en mode live**.
Passer `side=width` conserve la dépendance ; passer `side=width.value` fixe
une valeur numérique à cet instant. Un changement dans COMSOL n'est pas
recopié dans Python ; le prochain `project.build()` réapplique les définitions
Python utilisées par la géométrie ou enregistrées avec `add_parameter`, sans
effacer les autres paramètres COMSOL.

Les opérations disponibles sont `+`, `-`, `*`, `/`, les parenthèses et le signe
unaire `-`, ainsi que `maximum(a, b)` et `round(expression)`. Ces deux fonctions
prennent des arguments sans unité et conservent leurs dépendances :

```python
from femtogds import maximum

um = Parameter(1, "um_ref", unit="um")
radius = Parameter(8, "fillet_r", unit="um")
count = DependentParameter(maximum(8, round(3 * radius / um)), "fillet_n")
project.add_parameter(count)
project.build()  # fillet_n = 24 ; la formule reste modifiable dans COMSOL.
```

Diviser par une longueur de référence rend l'argument sans unité. L'arrondi
paramétré est à l'entier, avec les demi-entiers éloignés de zéro : 2.5 donne 3,
-2.5 donne -3, comme dans les exemples MATLAB. `round_nearest(expression)`
est son nom explicite importable depuis `femtogds` ; contrairement à
`round(2.5)` sur un nombre Python ordinaire, `round(parameter_expression)`
utilise cette règle. `maximum` compare exactement deux expressions ; le
`max` Python ordinaire ne construit pas de formule paramétrée.

Les puissances `**`, fonctions telles que `sin`, `cos` ou `sqrt`, lambdas et
formules sous forme de texte ne sont pas prises en charge dans cette version.
La comparaison détaillée avec les anciens scripts est dans
[MATLAB_EXAMPLES_AUDIT.md](MATLAB_EXAMPLES_AUDIT.md).

Les unités acceptées sont `nm`, `um`, `mm`, `m`, `deg`, `rad` et `""` pour une
valeur sans unité. Les additions convertissent les unités compatibles : ici,
`width + 2*gap` vaut initialement 21 µm. Ajouter une longueur à un angle ou à
un nombre sans unité est refusé ; le zéro littéral est accepté. Les produits
et quotients conservent les dimensions ; `width/gap` est sans unité.
À l'entrée de la géométrie, un nombre ou un paramètre sans unité prend l'unité
du champ : µm pour une longueur, degrés pour un angle.

`Parameter.value` s'exprime dans l'unité déclarée. `DependentParameter.value`
utilise par défaut les µm, degrés ou leurs produits. Par exemple,
`DependentParameter(width + 2*gap, "pitch_nm", unit="nm")` permet de lire cette
même longueur en nm, sans changer sa formule COMSOL. La valeur d'un paramètre
dépendant est calculée et ne s'affecte pas ; sa formule peut être changée avec
`pitch.expression = width + 3*gap`. Les noms et unités sont fixes.

Les unités incompatibles, dépendances circulaires, divisions par zéro et
valeurs non finies sont refusées avant l'export. Pour travailler hors ligne,
mettre `comsol=False` sur les couches ; le calcul des paramètres est autonome.

## Tableaux de coordonnées : Vertices

`Vertices` regroupe des points 2D composés de nombres, de paramètres ou
d'expressions. Les références aux paramètres sont conservées après une
translation, une multiplication, une extraction ou une concaténation.

```python
from femtogds import Vertices, Parameter, Square, Rotate

pitch = Parameter(20, "pitch", unit="um")
gap = Parameter(500, "gap", unit="nm")
points = Vertices([[0, 0], [1, 0], [2, 1]], pitch)
points = points + Vertices([gap, 0])

square = Square(project, layer=metal, side=4, position=points[1])
rotated = Rotate(square, angle=45, origin=points[0])
project.build()

pitch.value = 30
project.build()  # Les positions et le centre de rotation suivent pitch.
```

Le constructeur accepte un point `[x, y]`, un tableau `N × 2`, ou une grille
`N × M × 2` aplatie dans l'ordre Python : le second indice varie en premier.
Les listes, tuples, tableaux NumPy numériques ou `dtype=object` sont acceptés.
Le tableau peut mélanger nombres, `Parameter`, `DependentParameter` et formules.
`Vertices.xy(x, y)` crée un point ; `Vertices.from_components(...)` est un autre
nom pour la construction à partir de composantes. Un tableau vide est accepté.

Les nombres sans unité sont en **µm**, indépendamment des autres composantes.
Par exemple, avec `gap = 500[nm]`, `Vertices([gap, 2]).value` vaut
`[[0.5, 2.0]]` en µm. `Vertices([gap, 2], unit="nm")` vaut `[[0.5, 0.002]]`.
Une unité explicite s'applique aux nombres et paramètres sans unité ; les
paramètres portant une longueur gardent leur propre unité. Les unités de
longueur compatibles sont converties ; les angles sont refusés.

Le deuxième argument est un facteur commun : `Vertices([[1, 0], [0, 1]], pitch)`.
Les composantes doivent alors être des coefficients sans unité. La notation
`Vertices([[1, 0], [0, 1]]) * pitch`, ainsi que `pitch * Vertices(...)`, est aussi
acceptée pour un tableau de coefficients créé sans unité explicite. Multiplier
à nouveau des coordonnées déjà dimensionnées par une longueur est refusé.

| Opération | Résultat |
| --- | --- |
| `points.value` | Liste `N × 2` des valeurs actuelles en µm. |
| `points.values(unit="nm")` | Les mêmes valeurs en nm, sans arrondi GDS. |
| `points.xvalue`, `points.yvalue` | Listes des coordonnées en µm. |
| `points[0]`, `points[1:]` | Nouveau `Vertices` contenant les lignes choisies. |
| `points[0, 1]` | Expression scalaire de la coordonnée y du premier point. |
| `for point in points` | Parcours des points, chacun sous forme de `Vertices`. |
| `points + [dx, dy]` | Translation commune ; un autre tableau de même taille est aussi accepté. |
| `points * factor`, `points / factor`, `-points` | Calcul coordonnée par coordonnée avec un facteur sans unité. |
| `points.concat(other)` | Concaténation, même avec des unités ou facteurs différents. |
| `points.centroid()` | Moyenne des coordonnées physiques sous forme d'un point paramétré. |
| `points.to_comsol()` | Tableau des expressions COMSOL, avec les unités et les noms. |
| `points.parameters` | Dictionnaire des paramètres utilisés, dépendances comprises. |

Les indices commencent à zéro. `points[0] = [x, y]` et `points[0, 1] = y`
permettent de modifier les coordonnées ; les nombres utilisent l'unité donnée
à la construction. L'affectation d'une tranche conserve le nombre de points.
Une affectation invalide laisse le tableau précédent intact. `points.array`
donne une vue immuable des lignes d'expressions.

Une position ou un centre de rotation doit contenir **exactement un point**.
Si le même `Vertices` est directement affecté à une feature, ses modifications
sont prises en compte au prochain `build()`. Une extraction comme `points[0]`
copie les expressions de cette ligne : modifier la structure du tableau source
ne modifie pas la copie, tandis que changer les paramètres partagés la met à jour.
Les sorties numériques sont des copies et ne modifient pas la géométrie.
Les tableaux irréguliers, valeurs non finies, unités incompatibles et divisions
par zéro sont refusés ; un tableau vide n'a pas de centroïde.

## Sélections pour la simulation FEM

Une `Selection` regroupe des résultats géométriques indépendamment des layers.
Une feature peut appartenir à plusieurs groupes. Ces groupes sont enregistrés
dans le fichier MPH sous **Component > Definitions**, avec leur nom lisible.

```python
from femtogds.transforms import Rotate

conductors = project.add_selection("conductors", entity="boundary")
terminal = project.add_selection("terminal_1", entity="boundary")
square = Square(project, layer=metal, side=20, position=(40, 0),
                selections=[conductors])
rotated = Rotate(square, angle=90, keep=True, selections=[terminal])
project.build()

print(conductors.tag)       # Tag stable pour selection().named(...).
print(conductors.entities())  # Numéros actuels, uniquement pour inspection.
```

Les sélections suivent les transformations par défaut : ici `conductors`
contient le carré original et sa copie, et `terminal` seulement la copie.
`propagate_selections=False` sur `Rotate` désactive cette propagation.
`square.rotate(...)` accepte les mêmes options. Le paramètre `selections`
ajoute des appartenances ; il ne remplace pas les appartenances propagées.

`conductors.add(obj)` et `conductors.remove(obj)` modifient les appartenances
explicites ; appeler `project.build()` ensuite en mode différé. En mode live,
ces méthodes reconstruisent immédiatement. `conductors.members` contient
les objets explicitement ajoutés, tandis que COMSOL suit leurs descendants.
Retirer une appartenance explicite à une transformation ne supprime donc pas
une appartenance encore propagée depuis son entrée.

Le niveau concerne la géométrie **3D finale** : `boundary` sélectionne les
surfaces des carrés, `edge` leurs contours et `point` leurs sommets. `domain`
est réservé aux volumes ; ajouter un carré plan à une sélection de domaines
provoque une erreur claire à la construction. Les membres d'une couche
`comsol=False` restent des métadonnées Python et sont ignorés dans COMSOL.
Les sélections ne changent pas la géométrie GDS.

Dans `example_selections.py`, `conductors` contient les deux carrés et la
copie tournée ; `rotated_only` contient uniquement la copie. Les groupes sont
visibles sous **Component > Definitions** dans COMSOL.

## Organisation du code

- `femtogds/project.py` : projet, construction et affichage.
- `femtogds/_comsol.py` : réutilisation de la connexion dans une même session Python.
- `femtogds/layer.py` : réglages d'une couche.
- `femtogds/geometry.py` : classe commune `GeometryObject`.
- `femtogds/selection.py` : classe `Selection` et groupes COMSOL natifs.
- `femtogds/parameters.py` : paramètres, expressions, unités et dépendances.
- `femtogds/vertices.py` : tableaux de coordonnées et opérations paramétrées.
- `femtogds/primitives.py` : `Square` et noms réservés pour les futures primitives.
- `femtogds/transforms.py` : `Rotate` et noms réservés pour les futures transformations.

Les imports sont `from femtogds.primitives import Square` et
`from femtogds.transforms import Rotate`. Les deux classes sont aussi disponibles
directement avec `from femtogds import Square, Rotate`, comme `Project`,
`Selection`, `Parameter`, `DependentParameter` et `Vertices`. Toute la bibliothèque se trouve
désormais dans `femtogds/` ; les anciens imports `from Primitives ...` et
`from Transforms ...` doivent être remplacés.

## Environnement et tests

Le poste utilise Python Windows dans `.venv` et COMSOL 6.4. Les dépendances
sont déclarées dans `requirements.txt`. Le serveur COMSOL doit être ouvert
sur `localhost:2036` pour les couches COMSOL.

Depuis ce dossier, avec le Python de `.venv` :

```text
python -m unittest discover -s tests -v
```

Pour les tests COMSOL, utiliser une session interactive qui restera connectée :

```text
python -i tests/run_comsol_tests.py
```

Ce lanceur active `FEMTOGDS_TEST_COMSOL=1` et garde la console Python ouverte
après les tests. Ne pas fermer cette session si le serveur doit rester actif.
Les tests refusent une connexion depuis un processus non interactif et ne
déconnectent plus automatiquement le client. Le contrôle préalable du port doit
être passif (`netstat`), sans connexion TCP jetable.

COMSOL peut arrêter son serveur quand le client Python se termine : l'option
par défaut `-multi auto` a ce comportement pour les clients autres que le Desktop.
Pour rendre les futurs lancements indépendants de la durée de vie des clients,
COMSOL documente l'option de lancement `-multi on` ; le projet ne modifie pas
automatiquement la configuration du serveur.
[Documentation COMSOL](https://doc.comsol.com/6.4/doc/com.comsol.help.comsol/comsol_ref_running.38.20.html).

Les tests natifs vérifient notamment la géométrie parente 3D,
le plan de travail 2D, les deux modes de construction, les entités réellement
sélectionnées, la propagation et la conservation des sélections dans le MPH.
Ils exécutent aussi chaque exemple deux fois dans le même interpréteur et
vérifient la protection d'un fichier MPH déjà ouvert. Les appels d'ouverture
des fenêtres sont remplacés pendant les tests pour ne pas lancer les interfaces.
Le test des paramètres modifie également une valeur directement dans COMSOL,
reconstruit la géométrie sans Python, puis vérifie les expressions sauvegardées.
Le test des `Vertices` contrôle les positions, centres de rotation et sélections
dans les deux modes, les unités mixtes et les expressions relues depuis le MPH.
Les tests hors ligne couvrent les unités, les dépendances, le GDS et les
expressions envoyées à l'API COMSOL avec un enregistreur d'appels.

Les [consignes](AGENTS.md), le [contexte](CONTEXT.md) et les
[références](REFERENCES.md) servent à reprendre le travail. Les manuels locaux
sont dans `references/manuals/`. Ce projet est indépendant du code MATLAB.
