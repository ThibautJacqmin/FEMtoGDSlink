# Contexte du projet Python

## Audit des exemples MATLAB et validation native — 26 octobre 2026

Dernière demande : comparer tous les anciens exemples pour `Parameter`,
`DependentParameter`, `Vertices` et leurs compositions. Les six scripts
`example_1.m` à `example_6.m` présents dans le projet parent ont été relus.
Le bilan, les adaptations et les limites sont dans `MATLAB_EXAMPLES_AUDIT.md`.
Quatre exemples MSQ3 cités par un ancien test sont absents du dépôt et n'ont
donc pas pu être vérifiés. Les sources MATLAB n'ont pas été modifiées.

Deux lacunes corrigées :

- `maximum(a, b)` et `round_nearest(x)` (également `round(expression)`) conservent
  les références aux paramètres. Arguments sans unité ; pour le nombre de
  points de l'exemple 1, normaliser le rayon par un paramètre de référence 1 µm.
  L'arrondi à l'entier éloigne les demi-entiers de zéro. La formule COMSOL
  utilise `sign`, `floor`, `abs` et une comparaison pour reproduire cette règle,
  vérifiée sur le serveur, même aux limites flottantes testées.
- `project.add_parameter(p)` inclut un paramètre nommé et ses dépendances même
  sans feature qui l'utilise. Aucun accès serveur lors de l'enregistrement ;
  export au `build()` si une couche COMSOL est activée. Collisions contrôlées
  avant modification. `project.parameters` inclut aussi ces paramètres explicites.

Huit tests hors ligne supplémentaires reprennent les calculs des six exemples,
les cas limites d'arrondi et l'enregistrement explicite. Un test natif vérifie
ces formules, les modifications dans COMSOL et leur conservation dans le MPH.
Ce contrôle ne porte pas les géométries manquantes (courbes, routage, réseaux,
booléens, etc.). Les expressions textuelles de `ParametricCurve` restent absentes.
Les puissances et fonctions symboliques générales ne sont pas implémentées.

L'utilisateur a ensuite explicitement autorisé : **« Then you can test on the
comsol server »**. Cette instruction remplace la restriction hors ligne décrite
dans l'entrée historique suivante. Validation finale : **81 tests réussis,
aucun ignoré, dont 9 tests COMSOL natifs**, en 21.220 s. Cela valide aussi les
nouveaux `Vertices`, les deux modes, les sélections et les expressions des MPH.
Un premier passage avait échoué uniquement sur un module de test resté chargé
dans l'ancienne session ; après rechargement de ce module en conservant le
client, toute la suite a réussi.

La session interactive **66489** est désormais **connectée** à localhost:2036
et reste ouverte après les tests. Ne pas envoyer EOF/exit, fermer le client,
recharger le module de connexion ou arrêter ce processus. Aucun arrêt serveur
ni changement de configuration. Les tests ne retirent que leurs propres modèles.
Lors d'une reprise, vérifier si cette session est encore disponible et la
réutiliser ; les identifiants de session ne sont pas garantis après un redémarrage.

## Vertices, organisation et serveur — 26 octobre 2026

Demande traitée : porter `Vertices` depuis MATLAB en conservant les paramètres,
et déplacer les primitives dans le package Python.

- `femtogds/vertices.py` : point 2D seul, tableau N×2 ou grille N×M×2 aplatie
  dans l'ordre Python. Listes, tuples, NumPy, nombres, paramètres, paramètres
  dépendants et expressions. Les nombres sont en µm par défaut, avec `unit=`
  explicite possible ; les unités des paramètres voisins ne sont pas héritées.
- Préfacteur commun avec coefficients sans unité, multiplication à gauche/droite,
  translation avec diffusion d'un point, division par un scalaire sans unité,
  extraction, concaténation, itération et centroïde paramétré. `.value` en µm,
  `.values(unit=...)`, `.to_comsol()` et `.parameters` se recalculent à la lecture.
- Affectations `[row]`, `[row, column]` et tranches de lignes validées avant
  mutation. Une extraction copie les expressions en conservant les paramètres.
  `Square.position` et `Rotate.origin` conservent un `Vertices` fourni directement
  et demandent exactement un point. Aucun arrondi supplémentaire avant le GDS.
- Un scalaire interne `_UnitValue` applique explicitement une unité aux nombres
  et paramètres sans unité des coordonnées, sans faux paramètres globaux.
  Le dispatch arithmétique permet `Parameter * Vertices`.
- `Primitives.py` et `Transforms.py` ont été déplacés en
  `femtogds/primitives.py` et `femtogds/transforms.py`, sans modules de compatibilité.
  Les imports Python et exemples sont mis à jour. `Square`, `Rotate` et
  `Vertices` sont aussi importables directement depuis `femtogds`.
- Nouvel exemple plat : `example_vertices.py`. Tableau de positions, pitch
  commun, translation, sélection FEM et rotation autour d'un point du tableau.

Validation finale hors ligne : **64 tests réussis, 8 tests COMSOL ignorés**
(`FEMTOGDS_TEST_COMSOL=0`, 72 tests découverts). L'exemple Vertices est exécuté
deux fois sans GUI ni COMSOL et reconstruit après modification de pitch.
La tentative native a échoué avant la création des modèles avec une erreur
COMSOL **License error -15 — Cannot connect to license server system**.
L'utilisateur a ensuite demandé **de terminer hors ligne**. Ne pas présenter
les tests natifs de Vertices comme validés ni les relancer sans une nouvelle
indication. Les validations natives historiques ci-dessous concernent l'état
antérieur du code.

Instruction forte : **ne pas fermer le serveur COMSOL après les tests**.
La routine de test a perdu sa déconnexion automatique `atexit`; la bibliothèque
n'effectue plus de connexion TCP de sondage. Les contrôles de port sont passifs
(`netstat` Windows). La sandbox masquait le port local alors que le contrôle
hors sandbox montrait bien localhost:2036 ; ne pas multiplier les demandes de
redémarrage avant d'avoir vérifié hors sandbox.

COMSOL `-multi auto` peut quitter à la disparition d'un client Python : enlever
`disconnect()` seul ne suffit pas. Le nouveau lanceur est
`python -i tests/run_comsol_tests.py`, qui garde l'interpréteur ouvert après les
tests et vérifie la connexion une seule fois avant la suite. Les tests natifs
refusent un interpréteur non interactif. La configuration serveur n'a pas été
modifiée. L'option documentée `-multi on` est expliquée dans le README pour les
futurs lancements, mais n'est pas appliquée automatiquement.

Une session d'exécution interactive **66489** a été laissée ouverte après la
tentative échouée de connexion (licence -15). Ne pas envoyer EOF/exit ni arrêter
un client susceptible d'être connecté au serveur. Avant une reprise autorisée,
vérifier son état et réutiliser/recharger la session au lieu de multiplier les
processus clients. Aucun modèle utilisateur n'a été effacé.

## Paramètres Python — 25 octobre 2026

L'utilisateur a validé l'implémentation de `Parameter` et `DependentParameter`
et a explicitement abandonné les PCells. Le cœur est `femtogds/parameters.py` :
arithmétique `+ - * /` et signe unaire, références vivantes aux dépendances,
contrôle des unités et des noms, détection des cycles. Aucun moteur symbolique
externe, analyse de lambda ou évaluation de chaîne de caractères.

- `Parameter(value, name, unit="", description="")` : `.value` modifiable,
  nom et unité fixes. Unités : nm/um/mm/m, deg/rad, sans unité.
- `DependentParameter(expression, name, unit=None, description="")` : valeur
  calculée dans les unités canoniques µm/degrés (ou unité compatible explicite),
  formule `.expression` modifiable avec validation avant acceptation.
- `Square` conserve les références dans side/position/angle, `Rotate` dans
  origin/angle. Les futures features déclareront leurs scalaires dans
  `parameter_values()` pour la détection automatique des paramètres.
- `project.parameters` retourne les paramètres utilisés par tous les objets,
  dépendances avant dépendants. Les noms identiques sur des objets distincts
  sont refusés avant enregistrement ou export.
- Le build inscrit ou met à jour les paramètres nécessaires aux couches
  COMSOL avant les features. Les dimensions restent des expressions natives.
  Les autres paramètres COMSOL ne sont pas supprimés.
- Le GDS est évalué numériquement à chaque build. Une modification de `.value`
  demande un `project.build()`, y compris en mode live. Les changements faits
  dans COMSOL ne remontent pas dans Python ; un build Python réapplique ses
  propres définitions.
- `example_parameters.py` est un script plat, comme les autres exemples.

Contrainte de connexion levée explicitement pendant cette implémentation :
« J'ai pu lancer un serveur comsol. Profites en pour tester ». La sonde Windows
sur localhost:2036 a réussi. Le test natif ciblé des paramètres a réussi.
Le serveur est ensuite devenu indisponible ; l'utilisateur l'a relancé à la
demande, puis la suite complète a réussi.

Validation finale : **50 tests réussis, aucun skip**, COMSOL activé, en 37 s
avec le Python Windows de `.venv`. Cela comprend 43 tests hors ligne et
7 tests d'intégration. Le nouvel exemple et les quatre anciens sont exécutés
chacun deux fois dans un même interpréteur, sans ouvrir les GUI.
Le test natif vérifie les unités nm/um et rad/deg, les expressions de `Square`
et `Rotate`, les sélections après modification d'un paramètre directement
dans COMSOL (sans rebuild Python), puis le retour aux valeurs Python et les
expressions relues depuis le MPH sauvegardé. Les tests ne retirent que leurs
propres modèles temporaires. Les validations historiques ci-dessous restent
des instantanés.

## Exemples simplifiés et relances — 25 octobre 2026

L'utilisateur a validé la simplification au niveau des exemples MATLAB :
scripts plats, paramètres directement modifiables et commandes `build()` /
`show()`. Les exemples n'ont plus de `main()`, de parser, de garde `__name__`,
de prompts ou de branches de modes. Les objets restent dans l'espace de travail.

- `example_square.py` : angle directement dans `Square`.
- `example_rotation.py` : carré et copie par `Rotate`.
- `example_selections.py` : deux couches regroupées pour la FEM.
- `example_live.py` : cellules `# %%`, construction immédiate puis modification.

La connexion MPh est désormais réutilisée par `femtogds/_comsol.py`, y compris
entre deux exécutions d'un script dans le même interpréteur. Un nouveau projet
crée son propre modèle, sans effacer les précédents. Les exports utilisent
`model.java.save(path, True)` (copie COMSOL documentée), ce qui évite qu'un
export conserve lui-même un verrou empêchant la prochaine exécution.
Si un autre modèle tient le fichier MPH ouvert, seul ce cas de verrou déclenche
un nom numéroté ; `project.mph_path` expose le chemin réel et la bibliothèque
l'affiche. Le GDS garde son chemin de prévisualisation. Les autres erreurs de
sauvegarde remontent normalement. Les viewers lancés pour la même sortie sont
réutilisés et relancés s'ils ont été fermés ; le nouveau modèle COMSOL doit être
sélectionné dans la fenêtre via Import Application from Server.

Validation terminée : **31 tests réussis sans skip**, COMSOL activé, en 54 s.
Les quatre scripts ont chacun été exécutés deux fois dans le même interpréteur.
Vérifications : géométrie COMSOL/GDS, sélections, connexion réutilisée, modèles
distincts, fichier MPH ouvert conservé octet pour octet, export numéroté stable.
L'ouverture des GUI a été remplacée dans ces tests ; un test séparé vérifie la
réutilisation et le redémarrage des processus de visualisation simulés.
Les tests n'ont retiré que leurs propres modèles temporaires.

## Sélections FEM implémentées — 25 octobre 2026

L'utilisateur a demandé puis autorisé l'implémentation d'une classe `Selection`
indépendante des layers. Elle est dans `femtogds/selection.py`, exportée par
`femtogds`, et se crée avec `project.add_selection(name, entity="boundary")`
ou `Selection(project, name, entity="boundary")`.

- `Square(..., selections=[...])`, `Rotate(..., selections=[...])` et
  `square.rotate(...)` acceptent plusieurs groupes.
- `selection.add(*objects)` et `.remove(*objects)` modifient les appartenances
  explicites ; reconstruction immédiate en mode live, `build()` en mode différé.
- `selection.members` contient les membres explicitement ajoutés.
- `Rotate(..., propagate_selections=True)` suit la propagation COMSOL native.
  Avec `keep=True`, une sélection de l'entrée contient aussi la copie ; une
  sélection ajoutée uniquement à `Rotate` contient seulement sa sortie.
- `selection.tag` permet une référence par `selection().named(tag)` dans les
  réglages FEM ; `.entities()` lit les entités après construction, pour inspection.
- `boundary`, `edge`, `point` concernent la géométrie 3D finale. `domain` est
  accepté pour un groupe vide, mais les objets plans ne peuvent pas y contribuer.
- Les membres GDS uniquement restent des métadonnées, sans connexion implicite.

Le backend active les sélections natives de résultats et `wp1.selplaneshow`.
Chaque groupe devient une sélection `Union` sous Component > Definitions.
Les références suivent les tags de résultats, pas une liste figée de numéros.
Vérification importante COMSOL 6.4 : `componentSelection()` sur une feature
du plan retourne un tableau vide ; les tags promus sont exposés par le
WorkPlane parent (`geom1_wp1_sq1_bnd`, etc.). Les tests ont aussi confirmé
`selresultshow="all"` dans les features du plan sur cette installation.
Utiliser `JInt` pour `Union.entitydim` et un tableau `JString` pour `input`,
y compris lorsque le groupe devient vide, afin de résoudre les surcharges Java.

Validation : **28 tests réussis**, sans skip, avec
`FEMTOGDS_TEST_COMSOL=1` et le Python Windows de `.venv` après sonde Windows du
port 2036. Ils mesurent les entités sélectionnées, couvrent les deux modes,
les quatre combinaisons keep/propagation, les changements géométriques,
l'ajout/retrait des membres, et la relecture des groupes dans un MPH sauvegardé.
Les tests COMSOL partagent désormais un client par processus et retirent
uniquement leurs modèles temporaires. Une erreur révélée par la modification
de paramètres numériques entiers a été corrigée en convertissant explicitement
les valeurs en flottants avant les appels Java de `Square` et `Rotate`.

Le nouvel exemple `example_selections.py` illustre deux layers, un groupe
`conductors` et un groupe `rotated_only`. Le README décrit l'API actuelle.
Les indications de structure dans les sections historiques ci-dessous
restent des instantanés anciens.

## Vérification de la rotation — 24 octobre 2026

Les sources présentes ont évolué depuis l'état décrit ci-dessous : `Square`
est dans `Primitives.py`, `Rotate` dans `Transforms.py`, avec la méthode
`square.rotate(...)`. L'exemple crée un carré de côté 20 µm, centré en
`(10, 5)`, puis une rotation de 45° autour de ce centre. `keep=False` consomme
l'entrée ; le GDS ne contient que le résultat final.

Vérification après reprise : **17 tests GDS réussis** (10 rotation, 7 carré).
Le test COMSOL du carré a été ignoré lors de cette commande, car son activation
est explicite. L'exemple avec rotation a ensuite été exécuté et vérifié contre
le serveur COMSOL `localhost:2036`, dans les modes différé et immédiat.
Les deux fichiers MPH sauvegardés ont été relus : features natives `Square`
et `Rotate` dans un WorkPlane 2D d'une géométrie 3D, aire mesurée
`399.999999796 µm²`, limites conformes à la rotation attendue. Les deux GDS
contiennent exactement le losange attendu sur la couche 1/0, avec une aire
de `399.992328 µm²` après arrondi sur la grille de 1 nm.

La première exécution a rencontré un verrou sur `output/square.mph`, détenu
par un autre modèle. L'exemple accepte désormais `--output` pour choisir un
autre chemin sans modifier le modèle ouvert. Les sorties validées et leur
script de vérification sont dans `output/rotation_check_c34f91/` (ignoré par
Git). Les interfaces graphiques n'ont pas été lancées pendant cette vérification.
Les anciennes indications de structure et d'import ci-dessous et dans le
README restent à réconcilier avec les sources présentes.

## État actuel — 24 octobre 2026

L'utilisateur a autorisé et confirmé le fonctionnement d'un premier exemple
Python avec `Square`, COMSOL et KLayout. L'interdiction d'implémenter de
l'analyse historique ci-dessous est levée pour ce périmètre. La simplicité
du code et la consultation avant toute implémentation complexe restent exigées.

Dernières demandes :

- Travailler uniquement dans `python-rewrite/`.
- Toujours créer un composant avec une géométrie **3D**, puis dessiner les
  features 2D dans un **WorkPlane** de cette géométrie.
- Utiliser un fichier par feature : `femtogds/square.py` contient `Square` ;
  une future classe `Circle` aura son fichier `circle.py`.

Le code sauvegardé avant cette reprise créait déjà `geom1` en dimension 3,
puis `wp1` de type `WorkPlane`. Les features sont émises dans `wp1.geom()`.
Cette structure est conservée et rendue explicite dans le code et le README.
`Layer` est maintenant dans `layer.py` et `GeometryObject` dans `geometry.py`.
L'import public reste `from femtogds import Project, Square`.

Les flags indépendants `comsol` et `gds` sont portés par les couches.
`Project(live=True)` construit à chaque création ; le mode différé utilise
`project.build()`. `project.show()` ouvre les interfaces COMSOL et KLayout.
Les longueurs de cette première version Python sont en micromètres.

L'environnement `.venv` utilise Python Windows. Les tests existants vérifient
les exports GDS et, sur activation explicite, la géométrie COMSOL 3D contenant
un plan 2D, dans les deux modes. Le fichier `CODE_REVIEW.md` mentionné dans
l'ancienne analyse n'est pas présent dans le dossier récupéré.

Validation du 24 octobre : **8 tests réussis**, dont le test d'intégration
COMSOL activé avec `FEMTOGDS_TEST_COMSOL=1`, exécutés avec le Python Windows
de `.venv` après vérification du port 2036 depuis Windows. Les tests utilisent
leurs propres modèles temporaires et les retirent en fin d'exécution.

## Analyse historique du 23 octobre 2026

Les sections suivantes conservent les pistes et observations initiales.
Les décisions actuelles ci-dessus et `AGENTS.md` priment sur cette analyse.

État : 23 octobre 2026. Analyse documentaire et relecture du code, sans
implémentation ni essai de connexion à COMSOL.

## Demande utilisateur et décisions actuelles

Créer un projet entièrement Python, séparé de FEMtoGDSlink MATLAB. Le projet
actuel reste intact. `mph` doit permettre de créer la géométrie COMSOL ;
`klayout.db` doit permettre de produire les représentations GDS correspondantes.

COMSOL est la référence pour le sens des paramètres, objets et transformations.
La cible annoncée est un équivalent Python des objets et transformations
COMSOL, pas seulement un export de polygones vers COMSOL. Le périmètre complet
devra être recensé ; les classes MATLAB existantes n'en constituent qu'une partie.

Les dernières précisions utilisateur priment sur les idées initiales :

1. **Ne rien implémenter pour l'instant.** Livrer l'analyse et ce contexte.
2. **Rester très simple**, dans le code et dans l'utilisation, au niveau licence.
3. **Demander l'avis de l'utilisateur avant toute implémentation complexe.**
4. **Choisir les destinations sur les layers**, avec deux flags indépendants
   `comsol` et `gds`. Cette décision remplace le flag par objet évoqué auparavant.

Les objets doivent hériter d'une classe commune donnant accès aux transformations.
Les détails d'architecture ci-dessous restent des propositions à discuter.

## Couches et destinations

Une couche logique regroupe les objets et leur affectation aux deux moteurs.
Elle porte ses réglages COMSOL (par exemple le plan de travail et la sélection)
et GDS (numéro de couche, datatype), ainsi que les deux flags explicites.

| `comsol` | `gds` | Destination des objets de la couche |
| --- | --- | --- |
| vrai | vrai | COMSOL et GDS |
| vrai | faux | COMSOL uniquement |
| faux | vrai | GDS uniquement |
| faux | faux | Couche désactivée dans les deux sorties |

Le flag COMSOL n'a aucun effet sur le flag GDS. L'absence de connexion COMSOL
ne doit pas empêcher l'usage autonome des couches GDS. Le GDS activé par
défaut serait cohérent avec la demande précédente de tout construire dans
KLayout ; les valeurs par défaut de l'API restent à arrêter.

« Construire toutes les géométries GDS » signifie traiter les objets et
transformations des couches activées pour le GDS. L'insertion des objets
intermédiaires dans le fichier est une question distincte : après une
différence A − B, réinsérer aussi A remplirait la découpe. Proposition simple :
exporter les résultats finaux, conserver les entrées uniquement quand cela
est demandé. Ce comportement est à expliciter, pas à confondre avec les flags.

Deux cas nécessitent une décision avant implémentation :

- Une opération sur une couche COMSOL utilise une entrée d'une couche GDS
  uniquement. Proposition : une erreur claire indiquant l'entrée incompatible,
  plutôt qu'une activation implicite de cette entrée dans COMSOL. Même question
  dans l'autre sens pour le GDS.
- Une opération réunit des couches de plans de travail différents. Proposition
  initiale : refuser la combinaison et demander un plan commun ; une conversion
  géométrique automatique demanderait une conception supplémentaire.

## Structure objet minimale envisagée

Les quelques responsabilités nécessaires sont :

- Un objet de projet/session qui possède les couches, les objets et les commandes
  de construction. La création d'un simple paramètre ne doit pas se connecter
  à COMSOL ni modifier un modèle caché.
- Une classe géométrique de base, avec `move`, `rotate`, `scale`, `mirror`
  et les booléens usuels ; toutes les primitives et opérations en bénéficient.
- Des classes explicites pour les primitives et opérations, avec des arguments
  nommés et des méthodes courtes.
- Deux composants de construction, l'un COMSOL et l'autre KLayout, utilisant
  les mêmes descriptions géométriques et les réglages des couches.
- Des paramètres avec unités et expressions lorsque nécessaires ; un simple
  rectangle numérique ne doit pas obliger l'utilisateur à maîtriser ce mécanisme.

Une méthode telle que `rectangle.rotate(...)` peut retourner un objet
transformation qui référence son entrée. Cela conserve un historique cohérent
avec la séquence COMSOL et évite de modifier involontairement toutes les
utilisations du rectangle. Ce petit graphe de dépendances doit rester un détail
interne simple. Aucun framework de graphe ou système d'extension n'est décidé.

Une feature COMSOL et un objet géométrique de sortie ne sont pas toujours en
correspondance un-à-un : une opération peut produire plusieurs objets ou
consommer ses entrées. La représentation interne doit respecter cette réalité
sans imposer les tags Java et les sélections internes aux scripts ordinaires.

Pour un étudiant, le parcours attendu est court : créer le projet, définir
quelques couches, créer les formes, appliquer des transformations, construire.
Les unités et conventions d'angles doivent être explicites et constantes ;
les erreurs doivent nommer l'objet, le paramètre ou la couche en cause.

## Géométrie native et représentation GDS

Conserver les paramètres COMSOL et leurs expressions jusqu'à la construction
de ses features. Une approximation polygonale nécessaire au GDS ne remplace
pas la primitive native côté COMSOL.

La représentation KLayout est numérique. Il faudra distinguer :

- la tolérance du noyau géométrique COMSOL ;
- la précision d'échantillonnage des courbes ;
- la grille entière du fichier GDS.

Une tolérance géométrique lisible est préférable à un nombre arbitraire de
points pour l'usage courant. Le mécanisme exact et le traitement des expressions
COMSOL difficiles à évaluer en Python nécessitent une discussion avant toute
solution complexe. Aucun moteur symbolique général n'est prévu à ce stade.

Les courbes doivent rester des courbes après translation ou rotation, pour
pouvoir ensuite les épaissir correctement. Préserver les contours extérieurs,
trous et composantes séparées. Ne pas réduire toute géométrie à une seule liste
de sommets ou à une surface pleine dès sa création.

Les points, courbes sans largeur, objets de construction et objets 3D n'ont pas
tous un équivalent direct en polygone de fabrication. Il faut choisir clairement
la représentation GDS attendue. Les coupes/projections 3D et les objets sans
surface nécessitent un avis utilisateur avant de développer une solution.
Une couche COMSOL uniquement permet déjà de gérer simplement les éléments
qui ne doivent pas apparaître dans le GDS.

## Ce que la relecture change

Le projet actuel fournit une bonne liste de scénarios : primitives, opérations,
paramètres, sélections par couche, branches, ports et routage. Il ne faut pas
le traduire ligne à ligne. Les points suivants demandent une conception propre :

- Les ponts `MphProxy`, `JavaHandle`, `pyenv` et les conversions MATLAB deviennent
  inutiles en Python natif.
- Les flags actuels par objet et l'activation COMSOL déduite d'un workplane ne
  correspondent plus à la décision explicite de deux flags par couche.
- Les courbes d'interpolation ouvertes sont actuellement abaissées en polylignes
  dans COMSOL ; ce compromis ne doit pas définir la nouvelle primitive.
- Les traitements des tableaux obliques, exclusions de copies, miroirs, coins,
  épaississements et unités de routage demandent attention ; détails dans
  [CODE_REVIEW.md](CODE_REVIEW.md).
- Les caches et paramètres mutables peuvent devenir incohérents. Commencer par
  une reconstruction simple est une piste préférable à un système complexe
  d'invalidation tant que le besoin de performance n'est pas établi.

## Étapes possibles, sans autorisation d'implémenter

1. Examiner ensemble cette analyse, les choix de couches et les cas ambigus.
2. Arrêter un petit exemple d'API lisible et le périmètre géométrique de départ.
3. Lorsqu'une implémentation sera demandée, valider l'accès MPh à la version
   COMSOL du poste et le cycle minimal rectangle → transformation → GDS.
4. Étendre progressivement la couverture avec des exemples vérifiant réellement
   la géométrie et ses unités ; conserver le routage et les composants comme
   une couche ultérieure.

L'objectif de couverture COMSOL demeure large. L'étendre ne justifie pas une
architecture compliquée dès le départ. En particulier, génération automatique
de wrappers, moteur d'expressions, reconstructions incrémentales, projections
3D et routage avec obstacles exigent une présentation et l'avis de l'utilisateur
avant leur implémentation.

## État technique relevé

- Dépôt lu : `FEMtoGDSlink`, révision
  `0f3fca17e2730ae74b8e2e45af08753318e88ad2`.
- Répertoire de référence :
  `/mnt/c/Users/ThibautJacqmin/Documents/GitHub/FEMtoGDSlink`.
- Environnement agent : Ubuntu/WSL2 ; COMSOL et MATLAB actuels côté Windows.
- Configuration COMSOL lue : installation `COMSOL64`, hôte `localhost`,
  port `2036`. Ce sont des valeurs de configuration, pas une connexion vérifiée.
- Python Windows pour le futur moteur est une piste cohérente avec ce poste ;
  aucun environnement n'est créé, aucune version de paquet locale n'est validée.
- PDF utilisateur : COMSOL 6.3. Compléments téléchargés : Programming et
  LiveLink 6.4. Voir [REFERENCES.md](REFERENCES.md) pour les distinctions.
- Le statut Git initial ne montrait que `.codex` non suivi. Ce travail doit
  ajouter uniquement le dossier `python-rewrite/`.
