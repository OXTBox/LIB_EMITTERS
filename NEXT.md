# LIB_EMITTERS: next

22 Nov 2026 (night), Opus, with the owner's go: "tested it, it's great, get going".
Branches: LIB_EMITTERS `emitters-1`, LIB_POWERBAR `powerbar-1`, LIB_UNICODE `emitter-glyphs`,
xtalk_py `interp-key-loops`. ISSUES 0016 (LIB_SYSTEM, on main).

## Done tonight (seen in OXT-Beyond 0.2.7 through the MCP bridge)
- All four scripts compile on the engine; the editor opens, every power fired and measured:
  worst frame 9 ms (fire burst), all 17 under 15 ms.
- Fixed from what the pictures showed: the frame timer starts from preOpenStack too; `Emit.Reset`
  at load (bolts had 2 segments at first); posts all behind the dummy (a middle post caught every
  low shot); smooth rings for smooth elements (sound wave); field and label margins; budget line;
  cost table headings; `go card "X"` (owner).
- Engine quirk: a recursive call inside another call's brackets lost the main bolt (ISSUES 0016).
- Step 6 built: SPELL SPLAT on the Duel card (DUEL button under the power list). Bots fight, rounds
  and matches end, splat poses, banter, mid-air pops, both power bars with cooldown pies.
  `Emit.Displace` 10x faster (22.7 -> 2.2 ms): the duel runs 29-46 fps.

## Not yet tried
- Playing PROMPT yourself (PROMPT: bot -> you): keys are read with keysDown, which a script run
  cannot press, so only a person can test it.
- Held beams in the duel (bots cast beams for their life time only).

## Next
1. Owner plays the duel as PROMPT; tune speeds, energy refill (12/s), splat per power.
2. Look at each power with the owner; tune `powers/` defaults (fire beam tongues look like a saw).
3. Duel extras from the plan: beam clash tug of war, matchup switch (off), stamina.
4. Step 4 elements: frost, gravity, ink, bubble, magnet, sonic boom.
5. Duel into LIB_GAMES as a PROMPT & GLAZE foundation (Game Player card) when the owner says.
