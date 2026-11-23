# LIB_EMITTERS

Energy weapons drawn as vector lines made of math: lightning, fire, plasma, photon, sound and
heat, built as **element x form** (fire + ball = fire ball). A library, an editor stack to tune
the powers around two stick figures, and (later) a cute food-fight duel for PROMPT & GLAZE.
The plan, with every element, form, parameter limit and function: `PLAN.md`.

Plain LiveCode graphics on a card: not Vibecode3D (Engine 1), not xRay (Engine 2). The math
layer has no objects in it, so both engines can use it later.

## Open the editor

Open `energy_editor.livecodescript` in OXT-Beyond or LiveCode 9.6.3 (it is a script-only stack;
it builds its own window). Space fires the selected power at the GLAZE dummy, 1-9 picks a
power, H shows the keys. Its About card says the rest.

## Files

| File | What |
|---|---|
| `energy_editor.livecodescript` | the editor stack |
| `livecode/lib_emitters.livecodescript` | the library: math (`Emit.*`, `Sphere.*`, `Fig.*`), data (`Power.*`), effects (`Emit.Fire/Step/Hits`), drawing (`Draw.*`) |
| `powers/params.tsv` | every parameter: tab, kind, limits, default, label (the editor's rows come from it) |
| `powers/elements.txt`, `powers/forms.txt` | the defaults of the 7 elements and 9 forms |
| `powers/*.power.txt` | the 17 shipped powers (the user's own go to Documents/Data/Emitters/Powers) |
| `tests/run_tests.py` | tests without LiveCode: the library runs in xtalk_py's interpreter |

## Status (22 Nov 2026)

- Library: 58 of 58 tests pass in xtalk_py (math, 12 sphere methods with textbook vertex/edge
  counts, figures, power data and limits, all 17 powers fired at a target for 3 s).
- Editor and drawing: **written, not yet compiled or seen in LiveCode** (LiveCode was busy).
  First check: open the editor, read any compile error, fire each power once.

Licence: GPL-3.0.
