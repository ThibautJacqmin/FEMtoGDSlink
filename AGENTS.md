# FEMtoGDSlink Agent Bootstrap

Use this file to preserve project memory across sessions.

## Mandatory Preload For COMSOL/KLayout Work
- Read `docs/agent-memory/comsol-klayout-memory.md` first.
- Use `.codex_cache/COMSOL_ProgrammingReferenceManual.txt` and `.codex_cache/LiveLinkForMATLABUsersGuide.txt` for exact property names and syntax checks before changing backend code.

## Source Documents
- `C:\Users\ThibautJacqmin\Downloads\COMSOL_ProgrammingReferenceManual.pdf`
- `C:\Users\ThibautJacqmin\Downloads\LiveLinkForMATLABUsersGuide.pdf`
- `https://www.klayout.de/doc/programming/geometry_api.html`

## Regenerate Local Text Cache (if needed)
```powershell
& 'C:\Users\ThibautJacqmin\AppData\Local\Programs\MiKTeX\miktex\bin\x64\pdftotext.exe' -layout 'C:\Users\ThibautJacqmin\Downloads\COMSOL_ProgrammingReferenceManual.pdf' '.codex_cache\COMSOL_ProgrammingReferenceManual.txt'
& 'C:\Users\ThibautJacqmin\AppData\Local\Programs\MiKTeX\miktex\bin\x64\pdftotext.exe' -layout 'C:\Users\ThibautJacqmin\Downloads\LiveLinkForMATLABUsersGuide.pdf' '.codex_cache\LiveLinkForMATLABUsersGuide.txt'
```

## Guardrails
- Prefer documented COMSOL properties (`displ`, `size`, `input`, `input2`, `contributeto`, etc.) over guessed aliases.
- When COMSOL API behavior differs between versions, note the exact manual/version line in commit notes.
- For KLayout Python API calls, verify method names against class docs (`Polygon`, `Region`, `Layout`, `Trans`, `CplxTrans`) before patching.
