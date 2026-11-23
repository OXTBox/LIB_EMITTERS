# LIB_EMITTERS: the plan

Sunday, November 22, 2026. Written by Claude (Opus) from the owner's note
`LIB_LLMIN/LIB_EMITTERS/LIB_EMITTERS_ENERGY_WEAPONS.txt` (moved to `LIB_LLMOUT/Read/LIB_EMITTERS/`).

What he asked for, in short:

- energy weapons drawn as **vector lines made of math**: sound wave, static shock, lightning
  strike, chain lightning, ball lightning, heat wave, fire ball / beam / wave / burst, plasma
  ball / beam / wave, photon bit / beam / blast / burst, "etc.";
- an **editor stack** `LIB_EMITTERS/energy_editor.livecodescript` to try these powers and new
  ones, by procedural generation and **distortion of lines around stick figures**;
- the PROMPT & GLAZE pair in a **fighting-game duel**, passing energy back and forth, as cute as
  a food fight (the feel of Vector Toss / Photon Ball, not blood);
- **LIB_POWERBAR**: an RPG/MMO "pick the next / default power" input, with several **pages** of
  buttons on the **same keys** (its own plan: `LIB_POWERBAR/PLAN.md`).

Nothing has been built or run yet. LiveCode was busy with other work, so this whole plan was
made from files only.

---

## 1. The one idea that holds it together

Every power in the list is **an element doing a form**:

| | bit | ball | beam | wave | blast | strike | chain | shock | burst |
|---|---|---|---|---|---|---|---|---|---|
| **Pressure** (sound) | | | | sound wave | | | | | |
| **Static** | | | | | | | | static shock | |
| **Lightning** | | ball lightning | | | | lightning strike | chain lightning | | |
| **Heat** | | | | heat wave | | | | | |
| **Fire** | | fire ball | fire beam | fire wave | | | | | fire burst |
| **Plasma** | | plasma ball | plasma beam | plasma wave | | | | | |
| **Photon** | photon bit | | photon beam | | photon blast | | | | photon burst |

The 17 named powers fill 17 squares. The empty squares are the "etc.": an editor that lets any
element do any form gives **7 elements x 9 forms = 63 powers** from 16 recipes, and every one
can then be tuned by hand. So the library is built as:

- an **element** = the LOOK (colours, how the line shivers, what dots fly off, what it leaves on
  the target);
- a **form** = the SHAPE and the MOTION (where it starts, how it travels, what it touches);
- a **power** = element + form + the numbers the editor changed, saved as one small text file.

---

## 2. The elements (the look)

Each element is a set of defaults for the look parameters (section 6). Colours are written as
core / glow / edge. The "splat" is what it does to the target in a food fight: cute, never hurt.

| Element | Lines look like | Dots (particles) | Distortion of nearby lines | Splat on the target (afterburn) |
|---|---|---|---|---|
| **Pressure** | pale rings, no glow, thick-to-thin; nearly colourless (white 30%) | dust puffs pushed outward | **strong**: rings bend the floor, the grid and the figure's bones as they pass | knocked back, dizzy stars circle the head |
| **Static** | tiny short jags (3-6 segments), flicker on and off | sparks that jump and die fast | none | hair stands up (spikes on the head), little crackles on the limbs |
| **Lightning** | long jagged bolt, branches, very bright core, blue-white glow | few, bright, at the ends | slight shiver along the bolt | stunned: limbs twitch, a dark outline flashes (skeleton gag) |
| **Heat** | almost invisible: shimmer lines rising, orange haze | none or slow rising motes | **strong, wavy**: everything behind it wobbles like a hot road | sweat drops, the figure slows down |
| **Fire** | flame tongues (polygons with noise) yellow -> orange -> red, smoke grey tail | embers that rise and fade | mild upward wobble | **engulfed** on destruction (owner's note): flames on every limb, then soot face |
| **Plasma** | thick blobby outline, wobbles like jelly, magenta / violet | sticky drips that fall with gravity | soft bulge around the blob | goo: covered in drips, slides back slowly |
| **Photon** | crisp straight lines, white core, yellow glow, a lens-flare cross at the head | tiny bright dots in straight lines | none (light is clean) | **radiant** on destruction (owner's note): glowing outline + rays for a while |

More elements for "etc." (later, one line each in the editor's list): **Frost** (shards, crystal
lines, target freezes into a cube outline), **Gravity** (lines curl inward to a dark point,
target lifts and spins), **Ink** (wobbly black splats, target gets a moustache), **Bubble**
(round outlines that pop), **Magnet** (curved field lines between the figures), **Sonic boom**
(Pressure variant: a cone, not a ring).

---

## 3. The forms (the shape and the motion)

| Form | Starts at | Travels | Hits | Held? | Main math |
|---|---|---|---|---|---|
| **bit** | caster's hand | fast, straight or slightly homing, short trail | first thing it meets | no | path + trail of past points |
| **ball** | hand, grows while charging | slow, can arc (gravity) or wander | target or ground, then bursts | charge (hold to grow) | orb: core circle + flickering corona polygon + orbiting sparks |
| **beam** | hand | reaches the target at once (or grows at beam speed) | the whole line, every frame | **yes**: lasts while the key is held, costs energy per second | jagged or wobbling polyline + glow layers; struggle point when two beams meet |
| **wave** | caster's feet or hand | an arc / ring front grows outward along the ground | everything the front passes | no | ring or arc points + distortion amplitude, thickness falls with distance |
| **blast** | hand | a short cone, at once | everything in the cone | no | 5-20 short rays fanned in an angle, then particles |
| **strike** | sky above the target | top to bottom in 1-3 frames | target (+ small ground splash) | no | jagged line (midpoint displacement) from a point above the target |
| **chain** | hand | jumps target to target (figures, props, posts) | each in turn, N jumps | no | a strike between each pair, delay per jump |
| **shock** | hand, touching range | none (reach 0-80 px) | target in reach | no | a cluster of tiny jags around the hand and the target |
| **burst** | the point of impact or destruction | a radial explosion, then the afterburn | everything in the radius | no | radial rays + ring + particles; triggers the element's splat |

A power can **chain forms**: a fire ball ends in a fire burst; a photon bit that kills ends in a
photon burst. The power file names its `onHit` and `onEnd` follow-up power (section 7).

---

## 3b. Vector balls: every way to make a sphere (owner, 22 Nov)

The owner: balls come in "variant sizes and intensity and number of vertices and edges ...
There's all kinds of spheres to make with math. Let the developer of games decide the
complexity of their vector balls and method of wiring." So a ball's look is picked from a menu
of **methods**, and every method has its own detail numbers. The editor shows the vertex and
edge counts and the frame cost live, so the game's developer chooses how heavy a ball may be.

All of them are made once as 3-D points + edges (unit size), then each frame: turn, scale,
push by noise if asked, and project to the 2-D stage (plain or with a little perspective).

| Method | How it is made | Detail numbers | Vertices / edges (example) |
|---|---|---|---|
| `globe` | latitude rings x longitude meridians (the classic UV ball) | `rings` 2-24, `meridians` 3-48 | 8 x 12: 98 / 204 |
| `latitudes` | only the rings (a stack of hoops) | `rings` | 8 rings of 24: 192 / 192 |
| `meridians` | only the meridians (a cage, a melon) | `meridians` | 12 x 16: 170 / 192 |
| `icosphere` | icosahedron, each triangle split in 4, pushed out to the sphere | `subdivide` 0-3 | 0: 12/30, 1: 42/120, 2: 162/480, 3: 642/1920 |
| `octasphere` | the same from an octahedron (rounder poles, square-ish feel) | `subdivide` 0-4 | 0: 6/12, 2: 66/192 |
| `cubesphere` | a cube with N x N grid faces pushed out to the sphere | `grid` 1-12 | 4: 98/192 |
| `platonic` | tetra, cube, octa, dodeca, icosa (the five solids, not rounded) | `solid` | 4/6 ... 20/30 |
| `fibonacci` | N points spread evenly by the golden angle; dots, or each joined to its nearest K | `points` 8-600, `links` 0-6 | 100 points, K 3: 100 / 171 |
| `spiral` | one line wound from pole to pole (a loxodrome): a ball of string | `turns` 2-40, `points` | 10 turns: 1 line of 200 points |
| `gyro` | 2-8 great circles at different tilts (an atom, a gyroscope) | `hoops` 2-8 | 3 hoops of 32: 96 / 96 |
| `scatter` | random points on the sphere (from the seed) joined to the nearest K: fuzzy, crackling | `points`, `links` | |
| `orb` | no 3-D at all: the flat P4 orb (circle + corona), the cheapest | | 1 circle + 1 polygon |

How it is wired (any method):

| Choice | Options |
|---|---|
| `wire` | edges, dots (at the vertices), both |
| `backFace` | show (see-through), dim (back edges faint: reads as 3-D), hide (front only) |
| `spin` x, y, z | degrees a second; `tilt` the starting tilt |
| `wobble` | radius pushed by noise per vertex (plasma jelly, a fire ball's boil), with `jitterHz` |
| `pulse` | the size breathes, 0-50% |
| `perspective` | 0 flat ... 1 strong |
| `edgeCap` | the most edges drawn a frame (from the frame budget; the rest are skipped evenly) |

"Intensity" = the look numbers already in section 6 (core / glow widths, glow layers, flicker)
plus the size (`radius`) and `pulse`. So a photon bit can be a tiny 12-vertex icosahedron spinning
fast, and a plasma ball a wobbling 42-vertex icosphere with back edges dimmed.

---

## 4. The building blocks (primitives)

Every form above is drawn from these few pieces. They are the real library.

| # | Primitive | What it draws | Drawn with (LiveCode) |
|---|---|---|---|
| P1 | **Jag** | jagged line between two points (midpoint displacement, recursive), optional branches | one line graphic, segments separated by blank lines |
| P2 | **Wobble line** | smooth line that shivers by noise (beams, heat, plasma edge) | line graphic, `points` |
| P3 | **Ring / arc** | circle or arc as N points, radius grows, each point pushed by noise | polygon graphic (closed) or line (arc) |
| P4 | **Orb** | core circle + corona polygon whose radius flickers per point + orbiting sparks | oval graphic + polygon + markers |
| P5 | **Flame tongue** | a teardrop polygon whose tip sways by noise, colour by age | polygon graphic, filled, blendLevel |
| P6 | **Rays** | N straight lines from a centre (blast, burst, lens flare) | one line graphic, blank-line separated |
| P7 | **Dots** | all particles of one colour as ONE graphic: positions in `points`, the dot shape in `markerPoints` | polygon, lineSize 0, markerDrawn + markerFilled (DotMaze lesson: 1000 dots ~7 ms) |
| P8 | **Trail** | the last N positions of a moving thing, thinner and fainter toward the tail | line graphic, or 2-3 graphics of falling width |
| P9 | **Glow** | the same points drawn 2-3 times: wide + faint, medium, thin + bright core | 2-3 graphics stacked, blendLevel 70 / 40 / 0; optional real `outerGlow` (slow: a quality switch) |
| P10 | **Distortion field** | pushes OTHER lines' points: floor, background grid, stick figure bones | math only: a function that moves points near a source (`Emit.Displace`) |
| P11 | **Flash** | the whole stage tinted for 1-3 frames | one card-sized rectangle, blendLevel |
| P12 | **Shake** | the stage offset by a few pixels for a moment | offset added to every point before drawing |
| P13 | **Vector sphere** | a 3-D wire ball, turned and seen from the side: many ways to build it (section 3b) | one line graphic for the front edges, one dimmer for the back, one for the dots |

Every random choice comes from a **seed**, as in LIB_SFX: the same seed is the same bolt shape
everywhere, so a power that looks good can be kept exactly.

---

## 5. Every power from the note, as a recipe

| Power | Recipe (primitives, in drawing order) | Sound (LIB_SFX preset, later) |
|---|---|---|
| sound wave | 3-5 P3 arcs, gap between them, growing; P10 strong on floor + figure; P7 dust | hit / blip, low pitch |
| static shock | P1 x 4-8 tiny jags around hand and target, new seed every frame; P7 sparks | blip, noisy |
| lightning strike | P11 flash, P1 sky -> target with 2 branches, P9 glow blue-white, P12 shake, P7 sparks at ground | explosion, short |
| chain lightning | P1 between each pair, delay 0.08 s per jump, fewer branches each jump | laser, repeated |
| ball lightning | P4 orb (corona = P1 tiny jags round the edge), wanders on noise, P1 jumps to anything near | laser, warbling |
| heat wave | P3 low arc along the ground, almost invisible, P10 wavy strong, P2 shimmer lines rising | hit, very low |
| fire ball | P4 orb core yellow, P5 tongues trailing backward, P7 embers rising, ends in fire burst | explosion, soft |
| fire beam | P2 wobble line + P5 tongues along it, P9 glow orange, P7 embers | noise loop |
| fire wave | P3 arc along the ground with P5 tongues standing on it, P7 embers | explosion, long |
| fire burst | P6 rays + P3 ring + P5 tongues all round + **engulfed** afterburn on the target | explosion |
| plasma ball | P4 orb with jelly outline (P3 + noise, slow), drips (P7 with gravity) | power-up, low |
| plasma beam | P2 thick wobble, wide P9 glow magenta, blobs travelling along it | laser, warbling |
| plasma wave | P3 ring with big slow noise (jelly), bulge P10 | power-up |
| photon bit | tiny dot + P8 straight trail, crisp, very fast | laser, high |
| photon beam | P2 with zero wobble + P9 white/yellow, P6 lens-flare cross at the hand and the hit | laser, held |
| photon blast | P6 cone of straight rays + P7 dots in lines | laser, short |
| photon burst | P6 many rays + P11 white flash + **radiant** afterburn on the target | power-up, high |

---

## 6. Parameters and their limits

These are the numbers the editor shows as sliders. Units: px = pixels on the stage, s =
seconds. "Hard" limits are clamped in the code so a mutate can never break the frame budget.

### Look (from the element)

| Name | Meaning | Min | Max | Default |
|---|---|---|---|---|
| `colorCore` | colour of the thin bright line | any | | element |
| `colorGlow` | colour of the wide faint line | any | | element |
| `colorEdge` | colour of dots / tongues / tail | any | | element |
| `coreWidth` | lineSize of the core | 1 | 12 | 2 |
| `glowWidth` | lineSize of the widest glow | 0 | 40 | 10 |
| `glowLayers` | how many glow copies (P9) | 0 | 3 | 2 |
| `glowFade` | blendLevel of the widest glow | 0 | 95 | 70 |
| `flicker` | chance per frame a line vanishes for a frame | 0 | 0.9 | 0.1 |
| `realGlow` | use LiveCode's outerGlow too (slow) | false | true | false |
| `sphere` + its detail numbers | the ball method and wiring of section 3b (ball and orb forms) | | | `orb` |

### Shape

| Name | Meaning | Min | Max | Default |
|---|---|---|---|---|
| `segments` | points along a line or ring | 2 | 128 | 16 |
| `jitter` | how far points move off the line, px | 0 | 60 | 8 |
| `jitterHz` | how often the shape changes, per s (0 = frozen) | 0 | 30 | 12 |
| `smooth` | 0 jagged (bolt) ... 1 smooth noise (beam, jelly) | 0 | 1 | 0 |
| `branchChance` | chance a bolt segment sprouts a branch | 0 | 0.6 | 0.15 |
| `branchDepth` | branches of branches | 0 | 3 | 1 |
| `radius` | orb radius / ring start radius, px | 1 | 200 | 12 |
| `growth` | ring / ball growth, px per s | 0 | 800 | 200 |
| `rings` | rings in a wave | 1 | 6 | 1 |
| `ringGap` | px between rings | 0 | 120 | 30 |
| `arc` | degrees of the ring drawn (360 = full, 90 = ground arc) | 10 | 360 | 360 |
| `rays` | rays in a blast / burst | 1 | 48 | 12 |
| `cone` | blast cone angle, degrees | 5 | 180 | 40 |
| `tongues` | flame tongues per orb / per 100 px of beam | 0 | 24 | 6 |

### Motion

| Name | Meaning | Min | Max | Default |
|---|---|---|---|---|
| `speed` | px per s (0 = beam is instant) | 0 | 2000 | 500 |
| `gravity` | px per s per s (negative rises) | -1000 | 1000 | 0 |
| `homing` | 0 straight ... 1 turns hard toward the target | 0 | 1 | 0 |
| `wander` | noise in the heading (ball lightning) | 0 | 1 | 0 |
| `life` | longest life of the effect, s | 0.05 | 6 | 1.5 |
| `trail` | past positions kept for P8 | 0 | 40 | 8 |
| `charge` | longest charge time (ball grows), s | 0 | 3 | 0 |
| `jumps` | chain: targets after the first | 0 | 8 | 3 |
| `jumpDelay` | chain: s between jumps | 0 | 0.5 | 0.08 |
| `reach` | shock / chain: furthest jump, px | 0 | 400 | 160 |

### Particles (P7)

| Name | Meaning | Min | Max | Default |
|---|---|---|---|---|
| `rate` | dots made per s while alive | 0 | 600 | 60 |
| `burstDots` | dots made at once on hit / end | 0 | 400 | 40 |
| `dotLife` | s a dot lives | 0.05 | 4 | 0.6 |
| `dotSize` | marker size, px | 1 | 8 | 2 |
| `dotSpeed` | start speed, px per s | 0 | 800 | 120 |
| `dotSpread` | degrees around the direction | 0 | 360 | 360 |
| `dotGravity` | px per s per s (embers negative, drips positive) | -600 | 600 | 0 |
| `dotDrag` | slow down per s, 0..1 | 0 | 1 | 0.3 |

### Distortion (P10)

| Name | Meaning | Min | Max | Default |
|---|---|---|---|---|
| `distort` | largest push on other lines, px | 0 | 30 | 0 |
| `distortReach` | how far from the effect lines are pushed, px | 0 | 300 | 80 |
| `distortWave` | 0 push away ... 1 wavy shimmer | 0 | 1 | 0 |
| `distortWhat` | floor, grid, figures (any of them) | | | floor,grid,figures |

### Hit (food-fight rules)

| Name | Meaning | Min | Max | Default |
|---|---|---|---|---|
| `splat` | how much the target's splat meter fills, 0..100 | 0 | 50 | 10 |
| `knockback` | px per s push | 0 | 800 | 150 |
| `shake` | stage shake px | 0 | 20 | 2 |
| `flash` | stage flash 0..1 | 0 | 1 | 0 |
| `afterburn` | none, dizzy, frizz, stun, sweat, engulfed, goo, radiant | | | element |
| `afterburnTime` | s | 0 | 8 | 2 |
| `onHit` | follow-up power on a hit (e.g. `fire burst`) | | | empty |
| `onEnd` | follow-up power when life runs out | | | empty |

### Game (read by LIB_POWERBAR and the duel): on EVERY effect, always on screen

The owner (22 Nov): "every panel emitter effect should have a cost and cooldown property ...
best for developers same UI." So these are not in a tab: the editor shows them in a strip
above the tabs for whatever power is open, and **View > Cost table** shows every power in one
list (name, element, form, cost, cooldown, castTime) where the numbers can be typed straight in.
Follow-up powers (`onHit`, `onEnd`) keep their own cost and cooldown.


| Name | Meaning | Min | Max | Default |
|---|---|---|---|---|
| `cost` | energy to cast (beam: per s) | 0 | 100 | 15 |
| `cooldown` | s before it can be cast again | 0 | 20 | 1 |
| `castTime` | s of wind-up pose before it leaves the hand | 0 | 2 | 0.15 |
| `glyph` | one character for the power bar button (from LIB_UNICODE REGISTRY.tsv) | | | element |
| `seed` | the random seed | 1 | 2^31 | random once |

### The frame budget (hard limits for the whole stage)

From the DotMaze measurements of 21 Nov: 1000 marker dots cost about 7 ms to set and draw;
1000 line segments in one graphic about 39 ms. The duel aims at 30 frames a second (33 ms), and
the figures, floor and HUD need some of that, so effects get about 15 ms:

| Limit | Value | When it is reached |
|---|---|---|
| live effects at once | 16 | the oldest non-beam effect ends early |
| dots on stage | 1500 | new dots are not made |
| line segments a frame (all bolts, rays, rings) | 300 | jitter and branches are cut back for that frame |
| graphics in the pool | 48 (made once at start, never per frame) | effects share layers by colour |
| glow layers on stage | 24 | glow drops to 1 layer |
| `realGlow` effects at once | 2 | the rest draw without it |

The editor shows the live counts (effects / dots / segments / ms) under the stage, so a power
that costs too much is seen while it is being made.

---

## 7. The power file

One plain text file per power, `key <tab> value`, the same as the input and theme files.
Missing keys take the element's default, then the form's, then the table above.

```
power	1
name	fire ball
element	fire
form	ball
seed	40417
radius	14
speed	420
gravity	300
tongues	8
rate	90
dotGravity	-160
onHit	fire burst
cost	20
cooldown	1.5
glyph	♨
```

(Glyphs: ⚡ ☀ ♪ ✦ already mean other things in LIB_UNICODE's REGISTRY.tsv, so step 1 proposes one
new, free character per element and adds the rows there first. ♨ above is only an example.)

Where they live:

| What | Where |
|---|---|
| shipped powers (the 17) | `LIB_EMITTERS/powers/<name>.power.txt` |
| element and form defaults | `LIB_EMITTERS/powers/elements.txt`, `forms.txt` |
| the player's own powers | Data folder `Scripts/Emitters/Powers/` through LIB_DATA (rule 12); same name wins |

---

## 8. The functions (library `livecode/lib_emitters.livecodescript`)

Three layers, so the math can be tested headless and ported to the engines later.

### Math (pure: no objects, testable headless, later Python / Vibecode3D / xRay)

| Function | Returns |
|---|---|
| `Emit.Rand(pSeed)` / `Emit.RandNext()` | seeded random 0..1 (own LCG, never LiveCode's `random`, so seeds match everywhere) |
| `Emit.Noise(pX, pSeed)` | smooth 1-D noise -1..1 (value noise, cosine blend) |
| `Emit.Jag(pA, pB, pSegs, pJitter, pSeed, pBranch, pDepth)` | points of a bolt; branches after blank lines |
| `Emit.Wobble(pA, pB, pSegs, pAmp, pTime, pSeed)` | points of a smooth shivering line |
| `Emit.Ring(pC, pR, pSegs, pArcFrom, pArcTo, pAmp, pTime, pSeed)` | points of a ring or arc |
| `Emit.Corona(pC, pR, pSegs, pAmp, pTime, pSeed)` | closed polygon round an orb |
| `Emit.Tongue(pBase, pDir, pLen, pWidth, pTime, pSeed)` | polygon of one flame tongue |
| `Emit.Rays(pC, pCount, pFrom, pTo, pLenMin, pLenMax, pSeed)` | ray segments, blank-line separated |
| `Emit.Displace(pPoints, pSources)` | the same points, pushed by distortion sources (`x,y,strength,reach,wave`) |
| `Emit.Lerp`, `Emit.ColorMix(pC1, pC2, pT)`, `Emit.Clamp` | helpers |

### Effects (state, no drawing)

| Handler | Does |
|---|---|
| `Emit.Fire pPower, pFrom, pTo, pOwner` | starts an effect, returns its id (empty + reason in `the result` if the budget is full) |
| `Emit.Hold pId, pTo` / `Emit.Release pId` | beams and charging balls |
| `Emit.Step pDT` | moves every effect, dot and afterburn on by pDT seconds; collisions; follow-ups |
| `Emit.Hits()` | the hits of the last step (`effectId, target, power, splat, knockback`) for the game |
| `Emit.Targets pList` | what can be hit: `name, x, y, radius` lines (figures, props) |
| `Emit.Kill pId` / `Emit.Clear` | ends one / all |
| `Emit.Counts()` | effects, dots, segments, last ms |

### Drawing (LiveCode objects, one card)

| Handler | Does |
|---|---|
| `Draw.Begin pCardRect` | makes the pool of graphics once (layers by role: back glow, glow, core, dots, flash) |
| `Draw.Frame` | writes every effect's points into the pool, inside one `lock screen` |
| `Draw.Bend pName, pPoints` | gives the stage's own lines (floor, grid, bones) to P10 and gets them back bent |
| `Draw.End` | deletes the pool (closeCard; groups only there, gotchas file) |

### Data

| Handler | Does |
|---|---|
| `Power.Load pFile` / `Power.Save pName, pFile` | read / write a power file |
| `Power.Get(pName, pKey)` / `Power.Set pName, pKey, pValue` | one value, with defaults and clamping |
| `Power.List()` | names of every loaded power |
| `Power.Make(pElement, pForm)` | a new power from the two defaults |
| `Power.Mutate pName, pAmount, pLocked` | nudges every unlocked number by up to pAmount of its range (the editor's dice) |

---

## 9. The stick figures

- Side view, 2-D. **Built (22 Nov) as its own small 2-D figure** (`Fig.*`: 9 angles a pose) rather
  than LIB_UNICODE's 3-D 웃 `Person.Pose`: the casting poses needed their own angles anyway, and
  it keeps the library free of other libraries. It can move to LIB_UNICODE later.
- New poses the duel needs, made here as small changes to the arm and leg angles: **cast**
  (arm forward), **charge** (both hands together), **beam** (arms locked forward, knees bent),
  **recoil**, **dodge** (crouch), **jump**, **splatted** (sits down, legs out), **cheer**.
  If they look good they can move into LIB_UNICODE later as more `Person.Motions`.
- One line graphic per figure (bones as blank-line-separated segments) + an oval head. The
  bones go through `Emit.Displace` every frame, so a sound wave bends the figure and heat makes
  it wobble: the owner's "distortion of lines around stick figures".
- Afterburns are drawn ON the figure: dizzy stars (P3 small ring of dots), frizz (P1 on the
  head), flames (P5 on each limb), goo (P7 drips from the bones), radiant (P9 glow on the bones +
  P6 rays).
- PROMPT is cyan, GLAZE magenta (the PROMPT & GLAZE colours).

---

## 10. The editor (`energy_editor.livecodescript`)

A stack script that builds its own controls on first open (like the HOWTO and City Editor
stacks), with LIB_THEME's dark theme, templates coloured before every create. 1200 x 720,
top left 200,32 (fits the 1536 x 864 screen at scale 1).

### Cards

| # | Card | What |
|---|---|---|
| 1 | Developer | blank for now (rule 20) |
| 2 | Editor | the workbench below |
| 3 | Duel | the food fight (section 11) |
| 4 | About | the long date, stack name, title, what it is for, keys, how to report (rule 17) |

### Editor card layout

```
+-----------------------------------------------------------------------------------------+
| Menus (one popup button, LIB_MENU style): Power  Element  Form  View  Help               |
+-------------------+---------------------------------------------+-----------------------+
| POWERS            |  STAGE 640 x 420                             | ELEMENT [fire  v]     |
| filter: [all v]   |   faint grid + floor line                    | FORM    [ball  v]     |
|  sound wave       |                                              |-----------------------|
|  static shock     |   웃 caster (PROMPT)          웃 dummy (GLAZE)| LOOK|SHAPE|MOTION|DOTS |
|  lightning strike |      hand ----- effect ------>   target      | HIT|GAME  (tab strip) |
|  ...              |                                              |  name  ====o===  [14] |
|  fire ball  <     |                                              |  name  ==o=====  [ 3] |
|                   |                                              |  (one row per param:  |
| [New][Copy][Del]  | [Fire][Loop][Slow 1.0x =o=][Step][Clear]     |   label, slider,      |
| [Rename]          | effects 3  dots 412  segs 120  ms 9.1  30fps |   number, lock)       |
+-------------------+---------------------------------------------+-----------------------+
| Seed [40417] [dice]  Mutate [small][big]  A/B [snap A][snap B][swap]  [Save][Revert]     |
| [Send to Duel]   status: saved fire ball                                                 |
+-----------------------------------------------------------------------------------------+
```

### Widgets, all of them

| Widget | Kind | Does |
|---|---|---|
| Menu bar | green graphics + ONE popup button (LIB_MENU rule) | Power: New, Copy, Rename, Delete, Save, Revert, Export text. Element / Form: pick. View: grid, floor, dummy moves, real glow, show budget. Help: keys, About |
| Power list | list field | pick a power (1-9 keys pick the first nine) |
| Filter | popup | all / one element / one form |
| New / Copy / Delete / Rename | buttons | power files (Delete moves the file to a `deleted` folder, never removes it) |
| Stage | card area with the pool graphics | the caster, the dummy, floor, grid; click = fire at that spot |
| Dummy moves | View menu | stands / walks back and forth / jumps (to test homing and chain) |
| Fire / Loop / Step / Clear | buttons | fire once (Space), fire again when it ends (Enter), one frame (period), clear |
| Slow | scrollbar 0.1x - 1x | slow motion to look at a bolt |
| Budget line | field | effects, dots, segments, ms, fps; turns red over budget |
| Element / Form | popups | change the recipe; the numbers keep their values where the new recipe uses them |
| Tab strip | LIB_THEME `Theme.TabStrip` | LOOK, SHAPE, MOTION, DOTS, DISTORT, HIT, GAME |
| Parameter row | label + scrollbar + number field + lock box | one per parameter of section 6; a slider move fires again when Loop is on; greyed when the form does not use it |
| Colour swatch | graphic | click = `answer color`; three per power (core, glow, edge) |
| Afterburn / onHit / onEnd | popups | from the lists in section 6 and the power list |
| Glyph | button | opens LIB_UNICODE's picker (or a short field) |
| Seed + dice | field + button | new seed = new shape with the same numbers |
| Mutate small / big | buttons | `Power.Mutate` 10% / 35%, locked rows stay (M key) |
| A / B | buttons | keep two versions and flip between them to compare |
| Save / Revert | buttons | power file to the Data folder; back to the file |
| Send to Duel | button | puts the power on the duel's power bar (page 1, next free slot) |
| Status line | field | last action or error |
| MCP command line | field, lower left, toggled with the backquote key (rule 19) | type a command and run it |
| Pause panel | Escape (rule 18) | pauses the loop; speed, slow motion default, quality (real glow on/off) |

### Keys (editor)

Space fire - Enter loop on/off - period one frame - M mutate - D new seed - 1..9 pick power -
Tab next tab - A / B snapshots - Escape pause - backquote command line.

Above the tabs, always showing: **COST [15]  COOLDOWN [1.0 s]  CAST [0.15 s]  GLYPH [ ]**.
View > **Cost table**: every power in one editable list (see section 6, Game).

### Titles

`Opus | energy_editor` while I drive it; `FOR OWNER | Space fires, 1-9 picks a power, H for
help` when it is his to try (rules 13-14, stack title convention).

---

## 11. The duel: a food fight with energy

Working title **Spell Splat** (the owner names it). A card in the editor first, so every power
can be thrown at once; later a small foundation game in LIB_GAMES for PROMPT & GLAZE.

| Part | Rule |
|---|---|
| Stage | side view, flat floor, faint grid behind (so distortion shows), two figures 300 px apart |
| Moving | step forward / back, jump (dodge bits and waves), crouch (dodge beams) |
| Energy | 0-100 each, refills about 12 a second; powers cost `cost` |
| Splat meter | 0-100; hits fill it by `splat`; at 100 that figure is **glazed** (covered in the element's mess) and loses the round. Best of three. Nobody is hurt, ever |
| Mid-air | two projectiles that touch pop together into a mixed burst (both elements' dots) |
| Beam clash | two beams that meet make a **struggle point**: tap the fire key to push it toward the other figure; whoever gets pushed to gets a soft blast and a splat |
| Matchups (optional switch, OFF by default) | Pressure blows out Fire; Fire boils Plasma; Plasma swallows Photon; Photon outruns Lightning; Lightning grounds through Static; Static scrambles Pressure; Heat feeds Fire (a heat wave makes the next fire power bigger). Winner of a mid-air meeting keeps going at half size |
| Combos | a burst after a ball of the same element counts double; a chain that touches a radiant target jumps once more |
| Banter | short lines on big moments, from a `banter.txt`, as in Vector Toss |
| Bots | each side can be a bot (picks the power with the best matchup it can afford, dodges what it sees coming): bot vs bot is the first test |
| Input | LIB_INPUT actions + LIB_POWERBAR (pages of powers on the same keys) |
| Stamina | later: the PROMPT & GLAZE stamina property (0-100) caps the energy refill |

---

## 12. Order of building

| Step | What | Size (my guess) | Can be tested without a LiveCode window? |
|---|---|---|---|
| 0 | this plan + LIB_POWERBAR plan | done | |
| 1 | `lib_emitters`: math layer + power files + the 17 shipped powers | 1 session | yes, headless (math only) once LiveCode is free |
| 2 | drawing pool + forms bit, ball, beam, wave + elements Fire, Photon, Lightning | 1 session | needs a window to judge the look |
| 3 | the editor stack (cards, widgets, keys, save/load, budget line) | 1-2 sessions | needs a window |
| 4 | remaining forms (blast, strike, chain, shock, burst), elements, afterburns, distortion of figures | 1 session | window |
| 5 | LIB_POWERBAR logic + widget (its plan) | 1 session | logic headless, widget window |
| 6 | the duel card, bots first, then the player | 1-2 sessions | window; bot vs bot can run alone |
| 7 | later: the same powers in Vibecode3D (XT) and xRay | when he asks | |

Each step is committed on its own branch (`emitters-<step>`) per the git rule; this plan is on
main (foundation).

### Engines

This first version draws on a plain LiveCode card (2-D graphics), **not** in either engine:
the fighting-game view is side-on and 2-D, and it keeps the editor quick. The math layer is
engine-free on purpose: for Vibecode3D (pure xTalk, Engine 1) the point lists become line
meshes in a plane; for xRay (xt3d bridge, Engine 2) raylib draws the same lists. Never edit
the generated `vibe_engine_xt3d` script for this.

---

## 13. The owner's answers (22 Nov)

1. Plain LiveCode, 2-D card: "get the look right in straight livecode in both tools and
   effect" (the editor and the duel).
2. `energy_editor.livecodescript` (the note's spelling was a typo).
3. Yes, the feel of Vector Toss / Photon Ball, and balls in every size, intensity, vertex and
   edge count, by many sphere methods, the game developer choosing: section 3b.
4. The matchup wheel was unclear, so it stays an optional switch, OFF by default. (It meant:
   when two shots meet in mid-air, one element beats the other, like rock-paper-scissors.)
5. Slot keys fire at once. Every effect has cost and cooldown, in the same window: the Game
   strip and the Cost table (section 6).
