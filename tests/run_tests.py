#!/usr/bin/env python3
"""LIB_EMITTERS tests without LiveCode: the library runs in xtalk_py's interpreter.

    python3 -I tests/run_tests.py [-v]

Checks the math (bolts, rings, spheres, figures), the power data (defaults, limits) and every
shipped power fired at a target for a few simulated seconds (no drawing: that needs a window).
"""
import glob, os, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
LIB = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(os.path.dirname(LIB), 'xtalk_py'))
from xtalk import Interp   # noqa: E402

verbose = '-v' in sys.argv
fails = []
count = 0

def check(name, got, want):
    global count
    count += 1
    ok = (got == want) if not callable(want) else want(got)
    if not ok:
        fails.append(f'{name}: got {got!r}, want {want if not callable(want) else "(test)"}')
    elif verbose:
        print('ok  ', name, '=', got)

it = Interp()
it.load(open(os.path.join(LIB, 'livecode/lib_emitters.livecodescript'), encoding='utf-8').read())
check('script loads', it.load_errors, [])

def run(code):
    try:
        return it.run(code)
    except Exception as e:
        return f'ERR {type(e).__name__}: {e}'


def call(*a):
    try:
        return it.call(*a)
    except Exception as e:
        return f'ERR {type(e).__name__}: {e}'

def lit(text):
    """an xTalk expression that makes this text"""
    parts = text.split('\n')
    return ' & cr & '.join('"' + p.replace('"', '" & quote & "').replace('\t', '" & tab & "') + '"' for p in parts)

# ---------------------------------------------------------------- math
check('noise in -1..1', all(-1 <= float(it.call('Emit.Noise', x / 7, 3)) <= 1 for x in range(60)), True)
check('same seed, same bolt', it.call('Emit.Jag', 0, 0, 300, 0, 16, 20, 9, 0.2, 1), it.call('Emit.Jag', 0, 0, 300, 0, 16, 20, 9, 0.2, 1))
check('bolt ends where asked', it.call('Emit.Jag', 0, 0, 300, 40, 16, 20, 9, 0, 0).split('\n')[-1], '300,40')
check('ring closes', (lambda r: r[0] == r[-1])(it.call('Emit.Ring', 0, 0, 30, 12, 0, 360, 5, 0, 1).split('\n')), True)
check('displace pushes away', it.call('Emit.Displace', '10,0', '0,0,5,50,0,0,0'), '14,0')

for meth, key, val, want in [('icosphere', 'subdivide', 0, '12/30'), ('icosphere', 'subdivide', 1, '42/120'),
                             ('icosphere', 'subdivide', 2, '162/480'), ('octasphere', 'subdivide', 1, '18/48'),
                             ('platonic', 'solid', 'tetra', '4/6'), ('platonic', 'solid', 'cube', '8/12'),
                             ('platonic', 'solid', 'dodeca', '20/30'), ('cubesphere', 'grid', 1, '8/12'),
                             ('globe', 'sRings', 8, '98/204'), ('gyro', 'hoops', 3, '96/96')]:
    check(f'sphere {meth} {key}={val}', run(f'put "{val}" into tA["{key}"]\nput Sphere.Make("{meth}", tA) into tM\nreturn tM["n"] & "/" & tM["e"]'), want)
check('fibonacci links each point', run('put 100 into tA["points"]\nput 3 into tA["links"]\nput Sphere.Make("fibonacci", tA) into tM\nreturn tM["e"]'), lambda v: int(v) >= 150)
check('edge cap', run('put Sphere.Make("icosphere", empty) into tM\nput Sphere.Project(tM,0,0,50,0,0,0,0,0,0,1,"show","edges",30) into tO\nreturn tO["edges"]'), lambda v: int(v) <= 30)

for pose in ['stand', 'cast', 'beam', 'dodge', 'jump', 'splat']:
    check(f'figure {pose} stands on the floor', run(f'put Fig.Points(Fig.Pose("{pose}"), 100, 300, 120, 1, 0) into tF\nput 0 into tLow\nrepeat for each line tL in tF["pts"]\nif tL is not empty and item 2 of tL > tLow then put item 2 of tL into tLow\nend repeat\nreturn tLow'),
          lambda v: 295 <= int(v) <= 300)
check('figure faces left', run('put Fig.Points(Fig.Pose("cast"), 100, 300, 120, -1, 0) into tF\nreturn item 1 of tF["hand"] < 100'), 'true')

# ---------------------------------------------------------------- data
pw = os.path.join(LIB, 'powers')
it.call('Emit.LoadTable', open(os.path.join(pw, 'params.tsv'), encoding='utf-8').read())
it.call('Emit.LoadDefaults', 'element', open(os.path.join(pw, 'elements.txt'), encoding='utf-8').read())
it.call('Emit.LoadDefaults', 'form', open(os.path.join(pw, 'forms.txt'), encoding='utf-8').read())
names = []
for f in sorted(glob.glob(os.path.join(pw, '*.power.txt'))):
    names.append(it.call('Power.LoadText', open(f, encoding='utf-8').read()))
check('17 shipped powers', len([n for n in names if n]), 17)
check('elements', call('Emit.Elements'), 'fire,heat,lightning,photon,plasma,pressure,static')
check('own value wins', call('Power.Get', 'fire ball', 'gravity'), '300')
check('element before form', call('Power.Get', 'static shock', 'segments'), '6')
check('form when element is silent', call('Power.Get', 'fire ball', 'speed'), '380')
check('table default last', call('Power.Get', 'fire ball', 'homing'), '0')
check('limits clamp', run('Power.Set "fire ball", "speed", 99999\nreturn Power.Get("fire ball", "speed")'), '2000')
check('lists clamp', run('Power.Set "fire ball", "sphere", "banana"\nreturn Power.Get("fire ball", "sphere")'), 'orb')
run('Power.Unset "fire ball", "speed"\nPower.Unset "fire ball", "sphere"')
check('every power has cost and cooldown', all(call('Power.Get', n, 'cost') not in ('',) and call('Power.Get', n, 'cooldown') != '' for n in names), True)
check('mutate stays in limits', run('Power.Copy "fire ball", "mut"\nrepeat 20 times\nPower.Mutate "mut", 1, empty\nend repeat\nreturn Power.Get("mut", "speed") >= 0 and Power.Get("mut", "speed") <= 2000'), 'true')
check('power text round trip', run('put Power.Text("fire ball") into t\nPower.Delete "fire ball"\nreturn Power.LoadText(t) & "|" & Power.Get("fire ball", "onHit")'), 'fire ball|fire burst')

# ---------------------------------------------------------------- effects (no drawing)
setup = 'Emit.Reset\nEmit.SetStage 0, 0, 640, 420, 380\nEmit.SetTarget "dummy", 380, 300, 30, "480,380" & cr & "500,300" & cr & "520,380"\nEmit.SetTarget "post", 470, 330, 12, empty\n'
for n in names:
    if not n:
        continue
    t = time.time()
    near = 'Emit.SetTarget "dummy", 200, 300, 30, empty\n' if call('Power.Get', n, 'form') == 'shock' else ''
    aim = '200,300' if near else '380,300'
    code = setup + near + f'''put Emit.Fire("{n}", "140,290", "{aim}", "caster", empty, false) into tId
put 0 into tHits
put 0 into tLines
repeat 90 times
   Emit.Step 1/30
   put Emit.Hits() into tH
   if tH is not empty then add the number of lines of tH to tHits
   repeat for each line tK in Emit.Ids()
      put Emit.Lines(tK) into tG
      if tG["core"] is not empty or tG["fill"] is not empty or tG["dots"] is not empty then add 1 to tLines
   end repeat
end repeat
return tHits & "," & tLines & "," & the number of lines of Emit.Ids()'''
    try:
        r = run(code)
    except Exception as e:
        r = f'ERR {type(e).__name__}: {e}'
    secs = time.time() - t
    check(f'power {n!r} fires, draws and hits', r, lambda v: not v.startswith('ERR') and int(v.split(',')[0]) > 0 and int(v.split(',')[1]) > 0)
    if verbose or r.startswith('ERR'):
        print(f'      {n:18} hits,frames-with-lines,left = {r}   ({secs:.1f}s in Python for 3 s of play)')

# a held beam keeps going until released; a charging ball waits in the hand
check('held beam lasts', run(setup + 'put Emit.Fire("fire beam", "140,290", "500,300", "caster", empty, true) into tId\nrepeat 120 times\nEmit.Step 1/30\nend repeat\nreturn Emit.Alive(tId)'), 'true')
check('released beam ends', run('Emit.Release tId\nrepeat 30 times\nEmit.Step 1/30\nend repeat\nreturn Emit.Info(tId, "done") is true or not Emit.Alive(tId)'), 'true')
check('charging ball grows in the hand', run(setup + 'put Emit.Fire("plasma ball", "140,290", "500,300", "caster", empty, true) into tId\nput Emit.Info(tId, "r") into tA\nrepeat 20 times\nEmit.Step 1/30\nend repeat\nreturn Emit.Info(tId, "r") > tA and Emit.Info(tId, "x") = 140'), 'true')
check('fire ball sets the dummy alight', run(setup + 'put Emit.Fire("fire ball", "140,290", "500,300", "caster", empty, false) into tId\nput empty into tAll\nrepeat 60 times\nEmit.Step 1/30\nput Emit.Hits() after tAll\nend repeat\nreturn tAll'), lambda v: 'engulfed' in v)
check('nothing hits its owner', run(setup + 'Emit.SetTarget "caster", 140, 290, 30, empty\nput Emit.Fire("photon burst", "140,290", "140,290", "caster", empty, false) into tId\nrepeat 5 times\nEmit.Step 1/30\nend repeat\nreturn Emit.Hits()'), lambda v: 'caster' not in v)

print(f'{count - len(fails)} of {count} passed')
for f in fails:
    print('FAIL', f)
sys.exit(1 if fails else 0)
