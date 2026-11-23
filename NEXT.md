# LIB_EMITTERS: next

22 Nov 2026, Opus. Branch `emitters-1` (steps 1-3); LIB_POWERBAR branch `powerbar-1` (step 5
logic); LIB_UNICODE branch `emitter-glyphs`; xtalk_py branch `interp-key-loops` (two interpreter
fixes the tests found).

1. When LiveCode is free: compile both scripts (`LIB_MCP/tools/lcmcp compile`), open the editor,
   fix what LiveCode says. Things I could not check without it: drawing (graphics pool, marker
   dots, blend levels, group clipping), menus/popups, `answer color`, the timer loop.
2. Look at every power with the owner; tune the element/form defaults in `powers/`.
3. Measure frame time with many effects (the budget line under the stage) against the
   DotMaze numbers; cut back if over 15 ms.
4. Step 4 extras (more elements: frost, gravity, ink, bubble, magnet, sonic boom).
5. Step 6: the duel card with two LIB_POWERBAR bars, bots first.
