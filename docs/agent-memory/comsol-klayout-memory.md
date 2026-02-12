# COMSOL + KLayout Memory (FEMtoGDSlink)

This file is a persistent compact memory for future Codex sessions on this repo.

## Canonical Sources
- COMSOL Programming Reference Manual (v5.4, 2018): `C:\Users\ThibautJacqmin\Downloads\COMSOL_ProgrammingReferenceManual.pdf`
- LiveLink for MATLAB User's Guide (v6.4, 2025): `C:\Users\ThibautJacqmin\Downloads\LiveLinkForMATLABUsersGuide.pdf`
- KLayout Geometry API: `https://www.klayout.de/doc/programming/geometry_api.html`

Local searchable text caches:
- `.codex_cache/COMSOL_ProgrammingReferenceManual.txt`
- `.codex_cache/LiveLinkForMATLABUsersGuide.txt`

## COMSOL Geometry API Facts Used By This Project

### Geometry Sequence + WorkPlanes
- Create work plane:
  - `model.component(<ctag>).geom(<tag>).create(<ftag>,"WorkPlane");`
  - Cache lines: COMSOL `11430-11436`, `18340-18344`.
- Add 2D feature inside work plane:
  - `...feature(<wp>).geom().create(<ftag>, <type>)`
  - Cache lines: COMSOL `11434-11436`.
- In work plane Plane Geometry, `selresultshow` and `selindividualshow` are unavailable.
  - Cache line: COMSOL `18404`.

### Selections + Layer/Entity Propagation
- Create cumulative selection:
  - `...geom(<tag>).selection().create(<seltag>,"CumulativeSelection");`
  - Cache line: COMSOL `11532`.
- Add feature contribution:
  - `...feature(<ftag>).set("contributeto", <seltag>);`
  - Cache line: COMSOL `11536`.
- `selresult` + `selresultshow` + `contributeto` appear on most geometry features.
  - Representative lines: COMSOL `12311-12314`, `13108-13114`.

### Primitive/Transform/Boolean Features
- Rectangle feature properties include `base`, `pos`, `rot`, `size`.
  - Cache lines: COMSOL `17062-17079`.
- Circle feature properties include `base`, `pos`, `r`, `rot`, `angle`.
  - Cache lines: COMSOL `12883-12897`.
- Polygon properties include coordinate vectors `x`, `y`, `z`.
  - Cache lines: COMSOL `16856-16858`.
- Move/Copy translation uses `displ` (vector or vector list), not documented as `displx/disply`.
  - Cache lines: COMSOL `16046-16053`, `16072`, `16086-16088`.
- Rotate uses `input`, `pos`, `rot`.
  - Cache lines: COMSOL `17295`, `17315-17319`.
- Scale uses `factor`, `input`, `pos`.
  - Cache lines: COMSOL `17403-17406`.
- Mirror uses `input`, `pos`, `axis`, `keep`.
  - Cache lines: COMSOL `15958-15962`.
- Difference supports `selection("input2")`.
  - Cache lines: COMSOL `13100`, `12366`.
- Fillet point selection pattern:
  - `g.feature('fil1').selection('point').set('r1(1)',1:4);`
  - Cache line: COMSOL `14566`.
- `keep` is deprecated on some operations; `keepinput`/`keeptool` may be required.
  - Cache lines: COMSOL `16522-16523`, `16541-16543`.

### Array Semantics
- Array feature syntax:
  - `...create(<ftag>,"Array");`
  - Cache lines: COMSOL `12273`, `12281-12284`.
- Key properties: `input`, `displ`, `size`, `selresult`.
  - Cache lines: COMSOL `12308-12312`, `12317-12330`.
- Note: `linearsize` appears in a different section (not the core geometry Array table here), so validate usage per version before edits.

## LiveLink for MATLAB Facts Used By This Project
- Base model creation:
  - `model = ModelUtil.create(<ModelTag>);`
  - Cache line: LiveLink `1285`.
- Geometry sequence workflow:
  - `geom.create`, `geometry.feature.create`, `geometry.feature(...).set(...)`, `geometry.run`.
  - Cache lines: LiveLink `1935`, `1947`, `1954`, `1964`.
- Plot geometry and work plane:
  - `mphgeom(model, <geomtag>, 'workplane', <wptag>)`
  - Cache lines: LiveLink `1968-1974`, `2003-2009`, `12353-12365`.
- Launch COMSOL Desktop from MATLAB:
  - `mphlaunch`, `mphlaunch(model)`, optional timeout
  - Cache lines: LiveLink `1796-1825`, `13715-13735`.
- Parameter updates are associative with geometry/mesh updates before solve.
  - Cache lines: LiveLink `2711`, `2788-2790`.

## KLayout Geometry API Facts Used By This Project

Primary docs:
- Overview: `https://www.klayout.de/doc/programming/geometry_api.html`
- Layout class: `https://www.klayout.de/doc/code/class_Layout.html`
- Polygon class: `https://www.klayout.de/doc/code/class_Polygon.html`
- Region class: `https://www.klayout.de/doc/code/class_Region.html`
- Trans class: `https://www.klayout.de/doc/code/class_Trans.html`
- CplxTrans class: `https://www.klayout.de/doc/code/class_CplxTrans.html`

Validated method mapping for current backend:
- `Layout.create_cell`, `Layout.layer`, `Layout.write`, `Layout.dbu` are available.
- `Polygon.from_s` and `Polygon.ellipse(Box, n)` are available.
- `Region.insert`, `Region.merge`, `Region.round_corners`, `Region.transformed` are available.
- Region boolean operations are supported; Python aliases such as `and_` exist for keyword collisions.
- `Trans` supports point/vector-based translation and constants like `M0`/`M90`.
- `CplxTrans` supports constructors with `(mag, rot, mirrx, x, y)` and composes operations in the documented order.

## Project-Specific Notes
- `GDSModeler.pydbu = 0.001`, i.e. 1 database unit = 1 nm.
- Geometry is snapped/rounded to integer nanometers before GDS emission in `GeometrySession.gds_integer(...)`.
- Watch for doc-version drift:
  - COMSOL backend currently sets some properties (`linearsize`, `displx`, `disply`) that are not primary names in the cited geometry tables; verify against target COMSOL version when changing these areas.

## Fast Lookup Commands
```powershell
rg -n "WorkPlane|CumulativeSelection|contributeto|Move, Copy|Rotate|Scale|Mirror|Difference|Fillet|Array|linearsize|keepinput|keeptool" .codex_cache\COMSOL_ProgrammingReferenceManual.txt
rg -n "ModelUtil.create|geom.create|feature.create|geometry.run|mphgeom|workplane|mphlaunch|param.set" .codex_cache\LiveLinkForMATLABUsersGuide.txt
```
