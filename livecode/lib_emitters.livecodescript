script "lib_emitters"
######################################################################################
## LIB_EMITTERS  lib_emitters  (Sunday, November 22, 2026, Claude Opus, from the owner's note)
## Energy weapons as vector lines made of math. A POWER = an ELEMENT (the look) doing a FORM
## (the shape and motion): fire + ball = fire ball. Plan: LIB_EMITTERS/PLAN.md.
##
## Four layers, top to bottom:
##   Math     Emit.Rnd Emit.Noise Emit.Jag Emit.Wobble Emit.Ring Emit.Tongue Emit.Rays
##            Emit.Displace  + Sphere.Make / Sphere.Project (every way to make a vector ball)
##            + Fig.* (2-D stick figures, side view). No objects: runs headless.
##   Data     Emit.LoadTable / Power.*  (powers/params.tsv, elements.txt, forms.txt, *.power.txt)
##   Effects  Emit.Fire / Emit.Hold / Emit.Release / Emit.Step / Emit.Hits / Emit.Targets
##   Drawing  Draw.Begin / Draw.Frame / Draw.End  (a pool of graphics made once, on one card)
##
## Library rule: no system messages in here (it sits in every message path).
## TWO ENGINES: this is plain LiveCode on a card, NOT Vibecode3D (Engine 1) and NOT xRay
## (Engine 2). The math layer is engine-free so both engines can use it later.
######################################################################################

constant kTau = 6.283185307179586
constant kDeg = 0.017453292519943
constant kMaxFx = 16
constant kMaxDots = 1500
constant kMaxSegs = 300
constant kLayers = "glowW,glowM,back,fill,core,dots"

local sSeed
-- data
local sTabKeys, sTabTab, sTabKind, sTabMin, sTabMax, sTabDef, sTabLabel
local sElem, sForm, sPow, sFolder
-- effects
local sFx, sNextId, sTargets, sBones, sHits, sStage, sFloorY
local sShake, sFlash, sFlashColor, sDotCount, sSegCount, sSegScale, sLastMS, sModels
-- drawing
local sG, sSlotOf, sSlotStyled, sFlashG, sGroup, sGlowOn

-------------------------------------------------------------------- MATH: random and noise

-- seeded random (Park-Miller): the same seed gives the same shapes on every machine
command Emit.Seed pSeed
   if pSeed is not a number then put 1 into pSeed
   put (abs(trunc(pSeed)) mod 2147483646) + 1 into sSeed
end Emit.Seed

function Emit.Rnd
   if sSeed is empty then put 12345 into sSeed
   put (sSeed * 16807) mod 2147483647 into sSeed
   return sSeed / 2147483647
end Emit.Rnd

-- a fixed random 0..1 for a whole number and a seed (no state)
function Emit.Hash pN, pSeed
   local tH
   put (abs(trunc(pN)) * 7919 + abs(trunc(pSeed)) * 104729) mod 2147483646 + 1 into tH
   if pN < 0 then put (tH + 31337) mod 2147483646 + 1 into tH
   put (tH * 16807) mod 2147483647 into tH
   put (tH * 16807) mod 2147483647 into tH
   return tH / 2147483647
end Emit.Hash

function Emit.Floor pX
   if pX >= 0 or trunc(pX) = pX then return trunc(pX)
   return trunc(pX) - 1
end Emit.Floor

-- smooth 1-D noise, -1..1
function Emit.Noise pX, pSeed
   local tI, tF, tA, tB, tT
   put Emit.Floor(pX) into tI
   put pX - tI into tF
   put Emit.Hash(tI, pSeed) into tA
   put Emit.Hash(tI + 1, pSeed) into tB
   put (1 - cos(tF * pi)) / 2 into tT
   return (tA + (tB - tA) * tT) * 2 - 1
end Emit.Noise

function Emit.Lerp pA, pB, pT
   return pA + (pB - pA) * pT
end Emit.Lerp

function Emit.Clamp pV, pMin, pMax
   if pV < pMin then return pMin
   if pV > pMax then return pMax
   return pV
end Emit.Clamp

function Emit.Dist pX1, pY1, pX2, pY2
   return sqrt((pX2 - pX1) ^ 2 + (pY2 - pY1) ^ 2)
end Emit.Dist

-- "#RRGGBB" or "r,g,b" -> "r,g,b"
function Emit.RGB pC
   local tH
   if char 1 of pC is "#" and the number of chars of pC is 7 then
      put char 2 to 7 of pC into tH
      return baseConvert(char 1 to 2 of tH, 16, 10) & comma & baseConvert(char 3 to 4 of tH, 16, 10) & comma & baseConvert(char 5 to 6 of tH, 16, 10)
   end if
   if the number of items of pC is 3 then return pC
   return "255,255,255"
end Emit.RGB

function Emit.ColorMix pC1, pC2, pT
   local tA, tB
   put Emit.RGB(pC1) into tA
   put Emit.RGB(pC2) into tB
   return round(Emit.Lerp(item 1 of tA, item 1 of tB, pT)) & comma & round(Emit.Lerp(item 2 of tA, item 2 of tB, pT)) & comma & round(Emit.Lerp(item 3 of tA, item 3 of tB, pT))
end Emit.ColorMix

-- join polylines with a blank line between them (a blank line breaks a graphic's line)
function Emit.Join pOut, pPoly
   if pPoly is empty then return pOut
   if pOut is empty then return pPoly
   return pOut & cr & cr & pPoly
end Emit.Join

-------------------------------------------------------------------- MATH: lines

-- a bolt from A to B by midpoint displacement; pBranch = chance a point sprouts a branch,
-- pDepth = branches of branches. Branches come after blank lines.
function Emit.Jag pX1, pY1, pX2, pY2, pSegs, pJitter, pSeed, pBranch, pDepth
   Emit.Seed pSeed
   return emitJagLine(pX1, pY1, pX2, pY2, pSegs, pJitter, pBranch, pDepth)
end Emit.Jag

private function emitJagLine pX1, pY1, pX2, pY2, pSegs, pJitter, pBranch, pDepth
   local tX, tY, tN, tAmp, tNX, tNY, tM, i, tDX, tDY, tLen, tOff, tOut, tAng, tL, tEX, tEY, tSub
   if pSegs < 1 then put 1 into pSegs
   put pX1 into tX[1]
   put pY1 into tY[1]
   put pX2 into tX[2]
   put pY2 into tY[2]
   put 2 into tN
   put pJitter into tAmp
   repeat while tN - 1 < pSegs
      put empty into tNX
      put empty into tNY
      put 0 into tM
      repeat with i = 1 to tN - 1
         add 1 to tM
         put tX[i] into tNX[tM]
         put tY[i] into tNY[tM]
         put tX[i + 1] - tX[i] into tDX
         put tY[i + 1] - tY[i] into tDY
         put sqrt(tDX * tDX + tDY * tDY) into tLen
         put (Emit.Rnd() * 2 - 1) * tAmp into tOff
         add 1 to tM
         if tLen > 0 then
            put (tX[i] + tX[i + 1]) / 2 - tDY / tLen * tOff into tNX[tM]
            put (tY[i] + tY[i + 1]) / 2 + tDX / tLen * tOff into tNY[tM]
         else
            put tX[i] into tNX[tM]
            put tY[i] into tNY[tM]
         end if
      end repeat
      add 1 to tM
      put tX[tN] into tNX[tM]
      put tY[tN] into tNY[tM]
      put tNX into tX
      put tNY into tY
      put tM into tN
      multiply tAmp by 0.55
   end repeat
   repeat with i = 1 to tN
      put round(tX[i]) & comma & round(tY[i]) & cr after tOut
   end repeat
   delete the last char of tOut
   if pDepth > 0 and pBranch > 0 then
      put atan2(pY2 - pY1, pX2 - pX1) into tAng
      repeat with i = 2 to tN - 1
         if Emit.Rnd() < pBranch then
            put Emit.Dist(tX[i], tY[i], pX2, pY2) * (0.3 + Emit.Rnd() * 0.3) into tL
            put tAng + (Emit.Rnd() * 2 - 1) * 0.9 into tSub
            put tX[i] + cos(tSub) * tL into tEX
            put tY[i] + sin(tSub) * tL into tEY
            put Emit.Join(tOut, emitJagLine(tX[i], tY[i], tEX, tEY, max(2, pSegs div 3), pJitter * 0.5, pBranch * 0.6, pDepth - 1)) into tOut
         end if
      end repeat
   end if
   return tOut
end emitJagLine

-- a smooth line that shivers (beams, heat, plasma); ends stay put
function Emit.Wobble pX1, pY1, pX2, pY2, pSegs, pAmp, pTime, pSeed
   local i, tT, tDX, tDY, tLen, tNX, tNY, tOff, tOut
   if pSegs < 1 then put 1 into pSegs
   put pX2 - pX1 into tDX
   put pY2 - pY1 into tDY
   put sqrt(tDX * tDX + tDY * tDY) into tLen
   if tLen = 0 then return round(pX1) & comma & round(pY1)
   put -tDY / tLen into tNX
   put tDX / tLen into tNY
   repeat with i = 0 to pSegs
      put i / pSegs into tT
      put pAmp * sin(pi * tT) * Emit.Noise(tT * pSegs * 0.35 + pTime, pSeed) into tOff
      put round(pX1 + tDX * tT + tNX * tOff) & comma & round(pY1 + tDY * tT + tNY * tOff) & cr after tOut
   end repeat
   delete the last char of tOut
   return tOut
end Emit.Wobble

-- a ring (pFrom..pTo degrees; 360 apart = closed) whose radius is pushed by noise
function Emit.Ring pCX, pCY, pR, pSegs, pFrom, pTo, pAmp, pTime, pSeed
   local i, tA, tRR, tOut, tClosed, tN, tFirst
   if pSegs < 3 then put 3 into pSegs
   put (pTo - pFrom >= 360) into tClosed
   if tClosed then
      put pSegs - 1 into tN
   else
      put pSegs into tN
   end if
   repeat with i = 0 to tN
      put (pFrom + (pTo - pFrom) * i / pSegs) * kDeg into tA
      put pR + pAmp * Emit.Noise(i * 0.6 + pTime, pSeed) into tRR
      if tRR < 0 then put 0 into tRR
      put round(pCX + cos(tA) * tRR) & comma & round(pCY + sin(tA) * tRR) & cr after tOut
   end repeat
   if tClosed then put line 1 of tOut & cr after tOut
   delete the last char of tOut
   return tOut
end Emit.Ring

-- one flame tongue as a closed polygon: base point, direction (degrees), length, width
function Emit.Tongue pX, pY, pAngle, pLen, pWidth, pTime, pSeed
   local tA, tDX, tDY, tNX, tNY, tSway, tOut, tW
   put pAngle * kDeg into tA
   put cos(tA) into tDX
   put sin(tA) into tDY
   put -tDY into tNX
   put tDX into tNY
   put Emit.Noise(pTime * 3, pSeed) * pWidth * 0.8 into tSway
   put pWidth / 2 into tW
   put round(pX + tNX * tW) & comma & round(pY + tNY * tW) & cr after tOut
   put round(pX + tDX * pLen * 0.45 + tNX * (tW * 1.1 + tSway * 0.4)) & comma & round(pY + tDY * pLen * 0.45 + tNY * (tW * 1.1 + tSway * 0.4)) & cr after tOut
   put round(pX + tDX * pLen + tNX * tSway) & comma & round(pY + tDY * pLen + tNY * tSway) & cr after tOut
   put round(pX + tDX * pLen * 0.45 - tNX * (tW * 1.1 - tSway * 0.4)) & comma & round(pY + tDY * pLen * 0.45 - tNY * (tW * 1.1 - tSway * 0.4)) & cr after tOut
   put round(pX - tNX * tW) & comma & round(pY - tNY * tW) & cr after tOut
   put line 1 of tOut after tOut
   return tOut
end Emit.Tongue

-- straight rays out of a centre, pFrom..pTo degrees, each its own segment
function Emit.Rays pCX, pCY, pCount, pFrom, pTo, pInner, pLenMin, pLenMax, pSeed
   local i, tA, tL, tOut, tPoly
   Emit.Seed pSeed
   if pCount < 1 then put 1 into pCount
   repeat with i = 1 to pCount
      if pTo - pFrom >= 360 then
         put (pFrom + 360 * (i - 1) / pCount) * kDeg into tA
      else if pCount = 1 then
         put (pFrom + pTo) / 2 * kDeg into tA
      else
         put (pFrom + (pTo - pFrom) * (i - 1) / (pCount - 1)) * kDeg into tA
      end if
      put pLenMin + (pLenMax - pLenMin) * Emit.Rnd() into tL
      put round(pCX + cos(tA) * pInner) & comma & round(pCY + sin(tA) * pInner) & cr & round(pCX + cos(tA) * tL) & comma & round(pCY + sin(tA) * tL) into tPoly
      put Emit.Join(tOut, tPoly) into tOut
   end repeat
   return tOut
end Emit.Rays

-- push other lines' points away from sources. A source line:
--   x,y,strength,reach,wave(0..1),ringRadius(0 = a point),time
function Emit.Displace pPoints, pSources
   local tOut, tL, tS, tX, tY, tDX, tDY, tD, tDD, tF, tPX, tPY
   if pSources is empty then return pPoints
   repeat for each line tL in pPoints
      if tL is empty then
         put cr after tOut
         next repeat
      end if
      put item 1 of tL into tX
      put item 2 of tL into tY
      put 0 into tPX
      put 0 into tPY
      repeat for each line tS in pSources
         put tX - item 1 of tS into tDX
         put tY - item 2 of tS into tDY
         put sqrt(tDX * tDX + tDY * tDY) into tD
         if tD < 0.001 then next repeat
         if item 6 of tS > 0 then
            put abs(tD - item 6 of tS) into tDD
         else
            put tD into tDD
         end if
         if tDD >= item 4 of tS then next repeat
         put item 3 of tS * (1 - tDD / item 4 of tS) into tF
         if item 5 of tS > 0 then
            put tF * ((1 - item 5 of tS) + item 5 of tS * sin(tDD * 0.15 - item 7 of tS * 14)) into tF
            add tF * 0.6 * sin(tX * 0.09 + item 7 of tS * 11) * item 5 of tS to tPY
         end if
         add tDX / tD * tF to tPX
         add tDY / tD * tF to tPY
      end repeat
      put round(tX + tPX) & comma & round(tY + tPY) & cr after tOut
   end repeat
   delete the last char of tOut
   return tOut
end Emit.Displace

-- move every point of a points text
function Emit.Offset pPoints, pDX, pDY
   local tOut, tL
   if pDX = 0 and pDY = 0 then return pPoints
   repeat for each line tL in pPoints
      if tL is empty then
         put cr after tOut
      else
         put round(item 1 of tL + pDX) & comma & round(item 2 of tL + pDY) & cr after tOut
      end if
   end repeat
   delete the last char of tOut
   return tOut
end Emit.Offset

-------------------------------------------------------------------- MATH: vector spheres
-- A model: pM["n"] vertices pM["x"][i] pM["y"][i] pM["z"][i] (unit sphere), pM["e"] edges
-- pM["a"][k] - pM["b"][k]. Made once (Sphere.Make), drawn every frame (Sphere.Project).

function Sphere.Methods
   return "orb,globe,latitudes,meridians,icosphere,octasphere,cubesphere,platonic,fibonacci,spiral,gyro,scatter"
end Sphere.Methods

-- pA: sRings sMeridians subdivide grid solid points links turns hoops seed (missing = defaults)
function Sphere.Make pMethod, pA
   local tM
   put 0 into tM["n"]
   put 0 into tM["e"]
   if pA["sRings"] is not a number then put 8 into pA["sRings"]
   if pA["sMeridians"] is not a number then put 12 into pA["sMeridians"]
   if pA["subdivide"] is not a number then put 1 into pA["subdivide"]
   if pA["grid"] is not a number then put 4 into pA["grid"]
   if pA["points"] is not a number then put 100 into pA["points"]
   if pA["links"] is not a number then put 3 into pA["links"]
   if pA["turns"] is not a number then put 10 into pA["turns"]
   if pA["hoops"] is not a number then put 3 into pA["hoops"]
   if pA["seed"] is not a number then put 1 into pA["seed"]
   if pA["solid"] is empty then put "icosa" into pA["solid"]
   switch pMethod
      case "globe"
         sphGlobe tM, pA["sRings"], pA["sMeridians"], true, true
         break
      case "latitudes"
         sphGlobe tM, pA["sRings"], max(12, pA["sMeridians"] * 2), true, false
         break
      case "meridians"
         sphGlobe tM, max(8, pA["sRings"] * 2), pA["sMeridians"], false, true
         break
      case "icosphere"
         sphSolid tM, "icosa"
         sphSubdivide tM, pA["subdivide"]
         break
      case "octasphere"
         sphSolid tM, "octa"
         sphSubdivide tM, pA["subdivide"]
         break
      case "cubesphere"
         sphCube tM, pA["grid"]
         break
      case "platonic"
         sphSolid tM, pA["solid"]
         break
      case "fibonacci"
         sphFibonacci tM, pA["points"], pA["links"]
         break
      case "spiral"
         sphSpiral tM, pA["turns"]
         break
      case "gyro"
         sphGyro tM, pA["hoops"]
         break
      case "scatter"
         sphScatter tM, pA["points"], pA["links"], pA["seed"]
         break
   end switch
   return tM
end Sphere.Make

-- add a vertex (pushed out to the unit sphere when pNorm); returns its number
private function sphV @pM, pX, pY, pZ, pNorm
   local tL
   if pNorm then
      put sqrt(pX * pX + pY * pY + pZ * pZ) into tL
      if tL > 0 then
         put pX / tL into pX
         put pY / tL into pY
         put pZ / tL into pZ
      end if
   end if
   add 1 to pM["n"]
   put pX into pM["x"][pM["n"]]
   put pY into pM["y"][pM["n"]]
   put pZ into pM["z"][pM["n"]]
   return pM["n"]
end sphV

-- add an edge once
private command sphE @pM, pA, pB
   local tK
   if pA = pB then exit sphE
   if pA < pB then
      put pA & "-" & pB into tK
   else
      put pB & "-" & pA into tK
   end if
   if pM["k"][tK] is true then exit sphE
   put true into pM["k"][tK]
   add 1 to pM["e"]
   put pA into pM["a"][pM["e"]]
   put pB into pM["b"][pM["e"]]
end sphE

private command sphGlobe @pM, pRings, pMer, pRingEdges, pMerEdges
   local tTop, tBot, k, j, tLat, tLon, tIdx, tR, tY, tNext
   if pMerEdges then
      put sphV(pM, 0, 1, 0, false) into tTop
      put sphV(pM, 0, -1, 0, false) into tBot
   end if
   repeat with k = 1 to pRings
      put (90 - 180 * k / (pRings + 1)) * kDeg into tLat
      put sin(tLat) into tY
      put cos(tLat) into tR
      repeat with j = 0 to pMer - 1
         put kTau * j / pMer into tLon
         put sphV(pM, cos(tLon) * tR, tY, sin(tLon) * tR, false) into tIdx[k][j]
      end repeat
   end repeat
   repeat with k = 1 to pRings
      repeat with j = 0 to pMer - 1
         put (j + 1) mod pMer into tNext
         if pRingEdges then sphE pM, tIdx[k][j], tIdx[k][tNext]
         if pMerEdges then
            if k = 1 then sphE pM, tTop, tIdx[k][j]
            if k < pRings then sphE pM, tIdx[k][j], tIdx[k + 1][j]
            if k = pRings then sphE pM, tIdx[k][j], tBot
         end if
      end repeat
   end repeat
end sphGlobe

-- the five regular solids: vertices, then edges = every pair at the shortest distance
private command sphSolid @pM, pSolid
   local tP, tL, tV, tF
   put (1 + sqrt(5)) / 2 into tP
   switch pSolid
      case "tetra"
         put "1,1,1|1,-1,-1|-1,1,-1|-1,-1,1" into tV
         break
      case "cube"
         put "1,1,1|1,1,-1|1,-1,1|1,-1,-1|-1,1,1|-1,1,-1|-1,-1,1|-1,-1,-1" into tV
         break
      case "octa"
         put "1,0,0|-1,0,0|0,1,0|0,-1,0|0,0,1|0,0,-1" into tV
         break
      case "dodeca"
         put 1 / tP into tF
         put "1,1,1|1,1,-1|1,-1,1|1,-1,-1|-1,1,1|-1,1,-1|-1,-1,1|-1,-1,-1" into tV
         put "|0," & tF & comma & tP & "|0," & tF & ",-" & tP & "|0,-" & tF & comma & tP & "|0,-" & tF & ",-" & tP after tV
         put "|" & tF & comma & tP & ",0|" & tF & ",-" & tP & ",0|-" & tF & comma & tP & ",0|-" & tF & ",-" & tP & ",0" after tV
         put "|" & tP & ",0," & tF & "|" & tP & ",0,-" & tF & "|-" & tP & ",0," & tF & "|-" & tP & ",0,-" & tF after tV
         break
      default
         -- icosa
         put "0,1," & tP & "|0,1,-" & tP & "|0,-1," & tP & "|0,-1,-" & tP into tV
         put "|1," & tP & ",0|1,-" & tP & ",0|-1," & tP & ",0|-1,-" & tP & ",0" after tV
         put "|" & tP & ",0,1|" & tP & ",0,-1|-" & tP & ",0,1|-" & tP & ",0,-1" after tV
   end switch
   replace "|" with cr in tV
   repeat for each line tL in tV
      get sphV(pM, item 1 of tL, item 2 of tL, item 3 of tL, true)
   end repeat
   sphNearestEdges pM
end sphSolid

private command sphNearestEdges @pM
   local i, j, tD, tMin
   put 99 into tMin
   repeat with i = 1 to pM["n"] - 1
      repeat with j = i + 1 to pM["n"]
         put (pM["x"][i] - pM["x"][j]) ^ 2 + (pM["y"][i] - pM["y"][j]) ^ 2 + (pM["z"][i] - pM["z"][j]) ^ 2 into tD
         if tD < tMin then put tD into tMin
      end repeat
   end repeat
   repeat with i = 1 to pM["n"] - 1
      repeat with j = i + 1 to pM["n"]
         put (pM["x"][i] - pM["x"][j]) ^ 2 + (pM["y"][i] - pM["y"][j]) ^ 2 + (pM["z"][i] - pM["z"][j]) ^ 2 into tD
         if tD < tMin * 1.05 then sphE pM, i, j
      end repeat
   end repeat
end sphNearestEdges

-- split every triangle in four, pushed out to the sphere (icosphere, octasphere)
private command sphSubdivide @pM, pTimes
   local tAdj, tFaces, k, tA, tB, tC, tL, tNew, tMid, tMidAB, tMidBC, tMidCA, s, j, tRow
   if pTimes < 1 then exit sphSubdivide
   -- faces = triangles of the edge graph (true for tetra, octa, icosa)
   repeat with k = 1 to pM["e"]
      put true into tAdj[pM["a"][k]][pM["b"][k]]
      put true into tAdj[pM["b"][k]][pM["a"][k]]
   end repeat
   repeat with k = 1 to pM["e"]
      put min(pM["a"][k], pM["b"][k]) into tA
      put max(pM["a"][k], pM["b"][k]) into tB
      put tAdj[tA] into tRow
      repeat for each key j in tRow
         if j > tB and tAdj[tB][j] is true then put tA & comma & tB & comma & j & cr after tFaces
      end repeat
   end repeat
   repeat with s = 1 to pTimes
      put empty into tNew
      repeat for each line tL in tFaces
         if tL is empty then next repeat
         put item 1 of tL into tA
         put item 2 of tL into tB
         put item 3 of tL into tC
         put sphMid(pM, tMid, tA, tB) into tMidAB
         put sphMid(pM, tMid, tB, tC) into tMidBC
         put sphMid(pM, tMid, tC, tA) into tMidCA
         put tA & comma & tMidAB & comma & tMidCA & cr after tNew
         put tB & comma & tMidBC & comma & tMidAB & cr after tNew
         put tC & comma & tMidCA & comma & tMidBC & cr after tNew
         put tMidAB & comma & tMidBC & comma & tMidCA & cr after tNew
      end repeat
      put tNew into tFaces
   end repeat
   -- edges again, from the faces
   put empty into pM["k"]
   put empty into pM["a"]
   put empty into pM["b"]
   put 0 into pM["e"]
   repeat for each line tL in tFaces
      if tL is empty then next repeat
      sphE pM, item 1 of tL, item 2 of tL
      sphE pM, item 2 of tL, item 3 of tL
      sphE pM, item 3 of tL, item 1 of tL
   end repeat
end sphSubdivide

private function sphMid @pM, @pCache, pA, pB
   local tK
   if pA < pB then
      put pA & "-" & pB into tK
   else
      put pB & "-" & pA into tK
   end if
   if pCache[tK] is a number then return pCache[tK]
   put sphV(pM, (pM["x"][pA] + pM["x"][pB]) / 2, (pM["y"][pA] + pM["y"][pB]) / 2, (pM["z"][pA] + pM["z"][pB]) / 2, true) into pCache[tK]
   return pCache[tK]
end sphMid

-- a cube with an N x N grid on each face, pushed out to the sphere
private command sphCube @pM, pN
   local tFaces, tF, tC, tU, tV, i, j, tX, tY, tZ, tKey, tSeen, tIdx, tS, tT
   if pN < 1 then put 1 into pN
   put "1,0,0;0,1,0;0,0,1|-1,0,0;0,1,0;0,0,-1|0,1,0;1,0,0;0,0,-1|0,-1,0;1,0,0;0,0,1|0,0,1;1,0,0;0,1,0|0,0,-1;-1,0,0;0,1,0" into tFaces
   replace "|" with cr in tFaces
   repeat for each line tF in tFaces
      replace ";" with cr in tF
      put line 1 of tF into tC
      put line 2 of tF into tU
      put line 3 of tF into tV
      put empty into tIdx
      repeat with i = 0 to pN
         repeat with j = 0 to pN
            put i / pN * 2 - 1 into tS
            put j / pN * 2 - 1 into tT
            put item 1 of tC + item 1 of tU * tS + item 1 of tV * tT into tX
            put item 2 of tC + item 2 of tU * tS + item 2 of tV * tT into tY
            put item 3 of tC + item 3 of tU * tS + item 3 of tV * tT into tZ
            put round(tX * 1000) & "_" & round(tY * 1000) & "_" & round(tZ * 1000) into tKey
            if tSeen[tKey] is empty then put sphV(pM, tX, tY, tZ, true) into tSeen[tKey]
            put tSeen[tKey] into tIdx[i][j]
         end repeat
      end repeat
      repeat with i = 0 to pN
         repeat with j = 0 to pN
            if i < pN then sphE pM, tIdx[i][j], tIdx[i + 1][j]
            if j < pN then sphE pM, tIdx[i][j], tIdx[i][j + 1]
         end repeat
      end repeat
   end repeat
end sphCube

-- N points spread by the golden angle; each joined to its nearest K (the nearest ones sit a
-- Fibonacci number of steps away, so only those are tried)
private command sphFibonacci @pM, pN, pK
   local i, tY, tR, tA, j, tCand, tD, tStep, tL, tC
   if pN < 4 then put 4 into pN
   repeat with i = 0 to pN - 1
      put 1 - 2 * (i + 0.5) / pN into tY
      put sqrt(max(0, 1 - tY * tY)) into tR
      put i * 2.399963229728653 into tA
      get sphV(pM, cos(tA) * tR, tY, sin(tA) * tR, false)
   end repeat
   if pK < 1 then exit sphFibonacci
   repeat with i = 1 to pN
      put empty into tCand
      repeat for each item tStep in "1,2,3,5,8,13,21,34,55,89,144,233"
         repeat for each item tC in (i - tStep) & comma & (i + tStep)
            if tC < 1 or tC > pN then next repeat
            put (pM["x"][i] - pM["x"][tC]) ^ 2 + (pM["y"][i] - pM["y"][tC]) ^ 2 + (pM["z"][i] - pM["z"][tC]) ^ 2 into tD
            put tD & comma & tC & cr after tCand
         end repeat
      end repeat
      delete the last char of tCand
      sort lines of tCand numeric by item 1 of each
      repeat with j = 1 to min(pK, the number of lines of tCand)
         put line j of tCand into tL
         if tL is not empty then sphE pM, i, item 2 of tL
      end repeat
   end repeat
end sphFibonacci

-- one line wound from pole to pole (a ball of string)
private command sphSpiral @pM, pTurns
   local tP, i, tT, tLat, tLon, tLast, tNow
   put max(24, pTurns * 24) into tP
   repeat with i = 0 to tP - 1
      put i / (tP - 1) into tT
      put (-90 + 180 * tT) * kDeg into tLat
      put kTau * pTurns * tT into tLon
      put sphV(pM, cos(tLon) * cos(tLat), sin(tLat), sin(tLon) * cos(tLat), false) into tNow
      if i > 0 then sphE pM, tLast, tNow
      put tNow into tLast
   end repeat
end sphSpiral

-- great circles at different tilts (an atom, a gyroscope)
private command sphGyro @pM, pHoops
   local h, i, tA, tX, tY, tZ, tR1, tR2, tFirst, tLast, tNow, tY2, tZ2
   repeat with h = 1 to pHoops
      put 180 * (h - 1) / pHoops * kDeg into tR1
      put 30 * kDeg into tR2
      repeat with i = 0 to 31
         put kTau * i / 32 into tA
         put cos(tA) into tX
         put sin(tA) into tY
         put 0 into tZ
         -- turn about x by 60 degrees, then about y by the hoop's angle
         put tY * cos(60 * kDeg) into tY2
         put tY * sin(60 * kDeg) into tZ2
         put sphV(pM, tX * cos(tR1) + tZ2 * sin(tR1), tY2, -tX * sin(tR1) + tZ2 * cos(tR1), false) into tNow
         if i = 0 then
            put tNow into tFirst
         else
            sphE pM, tLast, tNow
         end if
         put tNow into tLast
      end repeat
      sphE pM, tLast, tFirst
   end repeat
end sphGyro

-- random points on the sphere (from the seed), each joined to its nearest K
private command sphScatter @pM, pN, pK, pSeed
   local i, j, tY, tA, tR, tCand, tD, tL
   Emit.Seed pSeed
   if pK > 0 then put min(pN, 250) into pN
   repeat with i = 1 to pN
      put Emit.Rnd() * 2 - 1 into tY
      put Emit.Rnd() * kTau into tA
      put sqrt(max(0, 1 - tY * tY)) into tR
      get sphV(pM, cos(tA) * tR, tY, sin(tA) * tR, false)
   end repeat
   if pK < 1 then exit sphScatter
   repeat with i = 1 to pN
      put empty into tCand
      repeat with j = 1 to pN
         if j = i then next repeat
         put (pM["x"][i] - pM["x"][j]) ^ 2 + (pM["y"][i] - pM["y"][j]) ^ 2 + (pM["z"][i] - pM["z"][j]) ^ 2 & comma & j & cr after tCand
      end repeat
      delete the last char of tCand
      sort lines of tCand numeric by item 1 of each
      repeat with j = 1 to pK
         put line j of tCand into tL
         if tL is not empty then sphE pM, i, item 2 of tL
      end repeat
   end repeat
end sphScatter

-- turn, size, wobble and flatten a model onto the screen.
-- Returns tOut["front"] tOut["back"] (segments), tOut["dots"] (vertex points), tOut["edges"]
-- pBack: show | dim | hide ; pWire: edges | dots | both ; pCap: most edges drawn
function Sphere.Project pM, pCX, pCY, pR, pAX, pAY, pAZ, pPersp, pWobble, pTime, pSeed, pBack, pWire, pCap
   local tOut, i, k, tSX, tCX, tSY, tCY, tSZ, tCZ, tX, tY, tZ, tY1, tZ1, tX2, tZ2, tX3, tY3, tS
   local tPX, tPY, tPZ, tStep, tA, tB, tSeg, tDrawn, tFront
   put empty into tOut
   put 0 into tOut["edges"]
   if pM["n"] < 1 then return tOut
   put sin(pAX * kDeg) into tSX
   put cos(pAX * kDeg) into tCX
   put sin(pAY * kDeg) into tSY
   put cos(pAY * kDeg) into tCY
   put sin(pAZ * kDeg) into tSZ
   put cos(pAZ * kDeg) into tCZ
   repeat with i = 1 to pM["n"]
      put pM["x"][i] into tX
      put pM["y"][i] into tY
      put pM["z"][i] into tZ
      put tY * tCX - tZ * tSX into tY1
      put tY * tSX + tZ * tCX into tZ1
      put tX * tCY + tZ1 * tSY into tX2
      put -tX * tSY + tZ1 * tCY into tZ2
      put tX2 * tCZ - tY1 * tSZ into tX3
      put tX2 * tSZ + tY1 * tCZ into tY3
      put pR * (1 + pPersp * tZ2 * 0.3) into tS
      if pWobble > 0 then multiply tS by 1 + pWobble * 0.5 * Emit.Noise(i * 1.7 + pTime * 2, pSeed)
      put round(pCX + tX3 * tS) into tPX[i]
      put round(pCY - tY3 * tS) into tPY[i]
      put tZ2 into tPZ[i]
   end repeat
   if pWire is not "dots" then
      if pCap < 1 then put 400 into pCap
      put max(1, pM["e"] / pCap) into tStep
      repeat with k = 1 to pM["e"]
         if tStep > 1 and trunc(k / tStep) = trunc((k - 1) / tStep) then next repeat
         put pM["a"][k] into tA
         put pM["b"][k] into tB
         put tPX[tA] & comma & tPY[tA] & cr & tPX[tB] & comma & tPY[tB] into tSeg
         put (tPZ[tA] + tPZ[tB] >= 0) into tFront
         if tFront or pBack is "show" then
            put Emit.Join(tOut["front"], tSeg) into tOut["front"]
         else if pBack is "dim" then
            put Emit.Join(tOut["back"], tSeg) into tOut["back"]
         else
            next repeat
         end if
         add 1 to tOut["edges"]
      end repeat
   end if
   if pWire is not "edges" then
      repeat with i = 1 to pM["n"]
         if tPZ[i] >= 0 or pBack is "show" then put tPX[i] & comma & tPY[i] & cr after tOut["dots"]
      end repeat
      delete the last char of tOut["dots"]
   end if
   return tOut
end Sphere.Project

-------------------------------------------------------------------- MATH: stick figures (side view)
-- A pose = 9 angles in degrees: lean, backArm upper, backArm fore, frontArm upper, frontArm fore,
-- backLeg thigh, backLeg shin, frontLeg thigh, frontLeg shin.
-- Limbs: 0 = hanging straight down, 90 = pointing forward, 180 = straight up. Lean: 0 upright,
-- + leans forward. Facing 1 = looking right, -1 = left.

function Fig.Pose pName
   switch pName
      case "cast"
         return "8,-25,-15,85,90,-18,-6,20,6"
      case "charge"
         return "6,55,110,62,115,-15,-10,18,4"
      case "beam"
         return "14,82,88,88,90,-32,-12,32,4"
      case "recoil"
         return "-18,-60,-30,150,170,-10,-25,25,10"
      case "dodge"
         return "32,40,95,50,100,25,-55,75,5"
      case "jump"
         return "0,150,165,155,170,30,-40,-10,-70"
      case "splat"
         return "-12,115,100,-60,-40,90,90,85,90"
      case "cheer"
         return "0,160,175,165,178,-8,0,8,0"
      default
         -- stand
         return "0,-12,-4,14,30,-7,-2,7,2"
   end switch
end Fig.Pose

function Fig.Poses
   return "stand,cast,charge,beam,recoil,dodge,jump,splat,cheer"
end Fig.Poses

function Fig.Walk pPhase
   local tS, tC
   put sin(kTau * pPhase) into tS
   put cos(kTau * pPhase) into tC
   return 4 & comma & round(-25 * tS) & comma & round(-25 * tS + 15) & comma & round(25 * tS) & comma & round(25 * tS + 15) & comma & round(25 * tS) & comma & round(25 * tS - 30 * max(0, tC)) & comma & round(-25 * tS) & comma & round(-25 * tS - 30 * max(0, -tC))
end Fig.Walk

function Fig.Lerp pA, pB, pT
   local i, tOut
   repeat with i = 1 to 9
      put round(Emit.Lerp(item i of pA, item i of pB, pT), 1) & comma after tOut
   end repeat
   delete the last char of tOut
   return tOut
end Fig.Lerp

-- the figure's lines. pAngles = a pose; pX = hip x; pFloor = floor y; pH = height;
-- pLift = px above the floor. Returns tOut["pts"] (legs, body, arms, head as 4 lines),
-- tOut["hand"] front hand x,y, tOut["chest"], tOut["head"], tOut["feet"]
function Fig.Points pAngles, pX, pFloor, pH, pFacing, pLift
   local tOut, tLean, tTorso, tUp, tFore, tThigh, tShin, tHeadR, tNeck
   local tKB, tFB, tKF, tFF, tHipY, tLowB, tLowF, tNX, tNY, tEB, tHB, tEF, tHF, tHX, tHY, tPoly
   if pFacing is not -1 then put 1 into pFacing
   if pLift is not a number then put 0 into pLift
   put pH * 0.30 into tTorso
   put pH * 0.15 into tUp
   put pH * 0.15 into tFore
   put pH * 0.24 into tThigh
   put pH * 0.24 into tShin
   put pH * 0.08 into tHeadR
   put pH * 0.03 into tNeck
   put item 1 of pAngles into tLean
   -- legs, measured from the hip at 0,0
   put figLimb(0, 0, item 6 of pAngles, tThigh, pFacing) into tKB
   put figLimb(item 1 of tKB, item 2 of tKB, item 7 of pAngles, tShin, pFacing) into tFB
   put figLimb(0, 0, item 8 of pAngles, tThigh, pFacing) into tKF
   put figLimb(item 1 of tKF, item 2 of tKF, item 9 of pAngles, tShin, pFacing) into tFF
   put max(item 2 of tFB, item 2 of tFF, item 2 of tKB, item 2 of tKF, 1) into tLowB
   put pFloor - tLowB - pLift into tHipY
   -- neck
   put pX + pFacing * sin(tLean * kDeg) * tTorso into tNX
   put tHipY - cos(tLean * kDeg) * tTorso into tNY
   put figLimb(tNX, tNY, item 2 of pAngles, tUp, pFacing) into tEB
   put figLimb(item 1 of tEB, item 2 of tEB, item 3 of pAngles, tFore, pFacing) into tHB
   put figLimb(tNX, tNY, item 4 of pAngles, tUp, pFacing) into tEF
   put figLimb(item 1 of tEF, item 2 of tEF, item 5 of pAngles, tFore, pFacing) into tHF
   -- legs line: back foot, back knee, hip, front knee, front foot
   put figPt(pX + item 1 of tFB, tHipY + item 2 of tFB) & cr & figPt(pX + item 1 of tKB, tHipY + item 2 of tKB) & cr & figPt(pX, tHipY) & cr & figPt(pX + item 1 of tKF, tHipY + item 2 of tKF) & cr & figPt(pX + item 1 of tFF, tHipY + item 2 of tFF) into tPoly
   put tPoly into tOut["pts"]
   put Emit.Join(tOut["pts"], figPt(pX, tHipY) & cr & figPt(tNX, tNY)) into tOut["pts"]
   put Emit.Join(tOut["pts"], figPt(item 1 of tHB, item 2 of tHB) & cr & figPt(item 1 of tEB, item 2 of tEB) & cr & figPt(tNX, tNY) & cr & figPt(item 1 of tEF, item 2 of tEF) & cr & figPt(item 1 of tHF, item 2 of tHF)) into tOut["pts"]
   put tNX + pFacing * sin(tLean * kDeg) * (tNeck + tHeadR) into tHX
   put tNY - cos(tLean * kDeg) * (tNeck + tHeadR) into tHY
   put Emit.Join(tOut["pts"], Emit.Ring(tHX, tHY, tHeadR, 12, 0, 360, 0, 0, 1)) into tOut["pts"]
   put figPt(item 1 of tHF, item 2 of tHF) into tOut["hand"]
   put figPt((pX + tNX) / 2, (tHipY + tNY) / 2) into tOut["chest"]
   put figPt(tHX, tHY) into tOut["head"]
   put figPt(tHX, tHY - tHeadR) into tOut["top"]
   put figPt(pX, pFloor) into tOut["feet"]
   put round(tHeadR) into tOut["headR"]
   return tOut
end Fig.Points

private function figLimb pX, pY, pAngle, pLen, pFacing
   return (pX + pFacing * sin(pAngle * kDeg) * pLen) & comma & (pY + cos(pAngle * kDeg) * pLen)
end figLimb

private function figPt pX, pY
   return round(pX) & comma & round(pY)
end figPt

-------------------------------------------------------------------- DATA: the parameter table

-- pText = powers/params.tsv
command Emit.LoadTable pText
   local tL
   put empty into sTabKeys
   put empty into sTabTab
   put empty into sTabKind
   put empty into sTabMin
   put empty into sTabMax
   put empty into sTabDef
   put empty into sTabLabel
   set the itemDel to tab
   repeat for each line tL in pText
      if tL is empty or char 1 of tL is "#" then next repeat
      put item 1 of tL & cr after sTabKeys
      put item 2 of tL into sTabTab[item 1 of tL]
      put item 3 of tL into sTabKind[item 1 of tL]
      put item 4 of tL into sTabMin[item 1 of tL]
      put item 5 of tL into sTabMax[item 1 of tL]
      put item 6 of tL into sTabDef[item 1 of tL]
      put item 7 of tL into sTabLabel[item 1 of tL]
   end repeat
   set the itemDel to comma
   delete the last char of sTabKeys
end Emit.LoadTable

-- the keys in order; with pTab only that tab's
function Emit.Keys pTab
   local tOut, tK
   if pTab is empty then return sTabKeys
   repeat for each line tK in sTabKeys
      if sTabTab[tK] is pTab then put tK & cr after tOut
   end repeat
   delete the last char of tOut
   return tOut
end Emit.Keys

-- one key's row: tab, kind, min, max, default, label (tab separated)
function Emit.KeyInfo pKey
   return sTabTab[pKey] & tab & sTabKind[pKey] & tab & sTabMin[pKey] & tab & sTabMax[pKey] & tab & sTabDef[pKey] & tab & sTabLabel[pKey]
end Emit.KeyInfo

-- keep a value inside its limits; numbers for num/int, true/false for bool
function Emit.Fit pKey, pValue
   local tKind
   put sTabKind[pKey] into tKind
   if tKind is "num" or tKind is "int" then
      if pValue is not a number then return sTabDef[pKey]
      if sTabMin[pKey] is a number and pValue < sTabMin[pKey] then put sTabMin[pKey] into pValue
      if sTabMax[pKey] is a number and pValue > sTabMax[pKey] then put sTabMax[pKey] into pValue
      if tKind is "int" then return round(pValue)
      return round(pValue, 3)
   end if
   if tKind is "bool" then
      return (pValue is true)
   end if
   if char 1 to 5 of tKind is "list:" then
      set the itemDel to "|"
      if pValue is among the items of char 6 to -1 of tKind then
         set the itemDel to comma
         return pValue
      end if
      set the itemDel to comma
      return sTabDef[pKey]
   end if
   return pValue
end Emit.Fit

-------------------------------------------------------------------- DATA: elements, forms, powers

-- elements.txt / forms.txt: [name] then key <tab> value lines. pWhich = element | form
command Emit.LoadDefaults pWhich, pText
   local tL, tSec, tA
   set the itemDel to tab
   repeat for each line tL in pText
      if tL is empty or char 1 of tL is "#" then next repeat
      if char 1 of tL is "[" then
         put char 2 to -2 of tL into tSec
         put empty into tA[tSec]
         next repeat
      end if
      if tSec is not empty then put item 2 to -1 of tL into tA[tSec][item 1 of tL]
   end repeat
   set the itemDel to comma
   if pWhich is "element" then
      put tA into sElem
   else
      put tA into sForm
   end if
end Emit.LoadDefaults

function Emit.Elements
   local tK
   put the keys of sElem into tK
   sort lines of tK
   replace cr with comma in tK
   return tK
end Emit.Elements

function Emit.Forms
   return "bit,ball,beam,wave,blast,strike,chain,shock,burst"
end Emit.Forms

-- a power file's text -> loaded; returns its name
function Power.LoadText pText
   local tL, tA, tName
   set the itemDel to tab
   repeat for each line tL in pText
      if tL is empty or char 1 of tL is "#" then next repeat
      if item 1 of tL is "power" then next repeat
      put item 2 to -1 of tL into tA[item 1 of tL]
   end repeat
   set the itemDel to comma
   put tA["name"] into tName
   if tName is empty then return empty
   put tA into sPow[tName]
   return tName
end Power.LoadText

-- the file text of a power: only what it sets itself
function Power.Text pName
   local tOut, tK, tKeys
   put "power" & tab & 1 & cr into tOut
   repeat for each item tK in "name,element,form,seed"
      put tK & tab & sPow[pName][tK] & cr after tOut
   end repeat
   put the keys of sPow[pName] into tKeys
   sort lines of tKeys
   repeat for each line tK in tKeys
      if tK is among the items of "name,element,form,seed" then next repeat
      put tK & tab & sPow[pName][tK] & cr after tOut
   end repeat
   return tOut
end Power.Text

function Power.List
   local tK
   put the keys of sPow into tK
   sort lines of tK
   return tK
end Power.List

function Power.Exists pName
   return pName is among the lines of the keys of sPow
end Power.Exists

-- a value: the power's own, else its element's, else its form's, else the table default
function Power.Get pName, pKey
   local tE, tF
   if pKey is among the items of "name,element,form" then return sPow[pName][pKey]
   if sPow[pName][pKey] is not empty then return Emit.Fit(pKey, sPow[pName][pKey])
   put sPow[pName]["element"] into tE
   put sPow[pName]["form"] into tF
   if sElem[tE][pKey] is not empty then return Emit.Fit(pKey, sElem[tE][pKey])
   if sForm[tF][pKey] is not empty then return Emit.Fit(pKey, sForm[tF][pKey])
   return sTabDef[pKey]
end Power.Get

-- true when the power sets this key itself
function Power.Own pName, pKey
   return sPow[pName][pKey] is not empty
end Power.Own

command Power.Set pName, pKey, pValue
   if pKey is among the items of "name,element,form" then
      put pValue into sPow[pName][pKey]
   else
      put Emit.Fit(pKey, pValue) into sPow[pName][pKey]
   end if
end Power.Set

-- forget the power's own value (back to the element / form / default)
command Power.Unset pName, pKey
   delete variable sPow[pName][pKey]
end Power.Unset

-- every key, resolved
function Power.All pName
   local tA, tK
   repeat for each line tK in sTabKeys
      put Power.Get(pName, tK) into tA[tK]
   end repeat
   put sPow[pName]["name"] into tA["name"]
   put sPow[pName]["element"] into tA["element"]
   put sPow[pName]["form"] into tA["form"]
   return tA
end Power.All

function Power.Array pName
   return sPow[pName]
end Power.Array

command Power.SetArray pName, pA
   put pA into sPow[pName]
   put pName into sPow[pName]["name"]
end Power.SetArray

command Power.Make pName, pElement, pForm, pSeed
   put empty into sPow[pName]
   put pName into sPow[pName]["name"]
   put pElement into sPow[pName]["element"]
   put pForm into sPow[pName]["form"]
   if pSeed is not a number then put (the milliseconds mod 2147483000) + 1 into pSeed
   put pSeed into sPow[pName]["seed"]
end Power.Make

command Power.Copy pFrom, pTo
   put sPow[pFrom] into sPow[pTo]
   put pTo into sPow[pTo]["name"]
end Power.Copy

command Power.Delete pName
   delete variable sPow[pName]
end Power.Delete

-- nudge every unlocked number by up to pAmount (0..1) of its range. Not the GAME strip, the
-- seed or colours. pLocked = keys, comma separated.
command Power.Mutate pName, pAmount, pLocked
   local tK, tV, tRange
   Emit.Seed the milliseconds
   repeat for each line tK in sTabKeys
      if sTabTab[tK] is among the items of "GAME,SEED" then next repeat
      if tK is among the items of pLocked then next repeat
      if not (sTabKind[tK] is "num" or sTabKind[tK] is "int") then next repeat
      put Power.Get(pName, tK) into tV
      put sTabMax[tK] - sTabMin[tK] into tRange
      Power.Set pName, tK, tV + (Emit.Rnd() * 2 - 1) * pAmount * tRange
   end repeat
end Power.Mutate

-------------------------------------------------------------------- DATA: files

-- the library's own folder (LIB_EMITTERS)
function Emit.Folder
   local tF
   if sFolder is not empty then return sFolder
   put the effective filename of me into tF
   set the itemDel to "/"
   delete item -2 to -1 of tF
   set the itemDel to comma
   put tF into sFolder
   return sFolder
end Emit.Folder

command Emit.SetFolder pFolder
   put pFolder into sFolder
end Emit.SetFolder

private function emitRead pPath
   if there is not a file pPath then return empty
   return textDecode(URL ("binfile:" & pPath), "UTF-8")
end emitRead

-- load the table, the defaults and every power of LIB_EMITTERS/powers, then pUserFolder's
command Emit.LoadAll pUserFolder
   local tDir
   put Emit.Folder() & "/powers" into tDir
   Emit.LoadTable emitRead(tDir & "/params.tsv")
   Emit.LoadDefaults "element", emitRead(tDir & "/elements.txt")
   Emit.LoadDefaults "form", emitRead(tDir & "/forms.txt")
   put empty into sPow
   Emit.LoadPowers tDir
   if pUserFolder is not empty then Emit.LoadPowers pUserFolder
end Emit.LoadAll

command Emit.LoadPowers pFolder
   local tOld, tFiles, tF
   if there is not a folder pFolder then exit Emit.LoadPowers
   put the defaultFolder into tOld
   set the defaultFolder to pFolder
   put the files into tFiles
   set the defaultFolder to tOld
   repeat for each line tF in tFiles
      if tF ends with ".power.txt" then get Power.LoadText(emitRead(pFolder & "/" & tF))
   end repeat
end Emit.LoadPowers

function Power.FileName pName
   local tN
   put pName into tN
   replace space with "_" in tN
   replace "/" with "_" in tN
   replace "\" with "_" in tN
   replace ":" with "_" in tN
   return tN & ".power.txt"
end Power.FileName

-- write a power into pFolder; the result is empty or why not
command Power.Save pName, pFolder
   if there is not a folder pFolder then create folder pFolder
   put textEncode(Power.Text(pName), "UTF-8") into URL ("binfile:" & pFolder & "/" & Power.FileName(pName))
   return the result
end Power.Save

-------------------------------------------------------------------- EFFECTS

command Emit.Reset
   put empty into sFx
   put 0 into sNextId
   put empty into sHits
   put 0 into sShake
   put 0 into sFlash
   put 0 into sDotCount
   put 0 into sSegCount
   put 1 into sSegScale
   put empty into sSlotOf
end Emit.Reset

-- the stage: left, top, right, bottom and the floor's y
command Emit.SetStage pLeft, pTop, pRight, pBottom, pFloorY
   put pLeft & comma & pTop & comma & pRight & comma & pBottom into sStage
   put pFloorY into sFloorY
end Emit.SetStage

-- what can be hit: name, x, y, radius (and the owner who cannot hit itself)
command Emit.SetTarget pName, pX, pY, pR, pBones
   put pX & comma & pY & comma & pR into sTargets[pName]
   put pBones into sBones[pName]
end Emit.SetTarget

command Emit.RemoveTarget pName
   delete variable sTargets[pName]
   delete variable sBones[pName]
end Emit.RemoveTarget

function Emit.Target pName
   return sTargets[pName]
end Emit.Target

-- the nearest target to a point, not pNot (comma list), within pReach (empty = any)
function Emit.Nearest pX, pY, pNot, pReach
   local tK, tBest, tD, tBestD
   put 999999 into tBestD
   repeat for each key tK in sTargets
      if tK is among the items of pNot then next repeat
      put Emit.Dist(pX, pY, item 1 of sTargets[tK], item 2 of sTargets[tK]) into tD
      if pReach is a number and tD > pReach then next repeat
      if tD < tBestD then
         put tD into tBestD
         put tK into tBest
      end if
   end repeat
   return tBest
end Emit.Nearest

-- start a power. pFrom/pTo = "x,y"; pOwner never gets hit by it; pTarget = who it is for
-- (empty = nearest); pHeld = it lasts until Emit.Release (beams, charging balls).
-- Returns the effect id, or empty with the reason in the result.
function Emit.Fire pPower, pFrom, pTo, pOwner, pTarget, pHeld, pDepth
   local tF, tP, tId, tAng, tDX, tDY, tD, tT, tSpeed, tK, tOldest, tOldAge, tCount
   if not Power.Exists(pPower) then return empty
   if pDepth is not a number then put 0 into pDepth
   if pDepth > 3 then return empty
   -- room?
   put 0 into tCount
   put -1 into tOldAge
   repeat for each key tK in sFx
      add 1 to tCount
      if sFx[tK]["held"] is not true and sFx[tK]["age"] > tOldAge then
         put sFx[tK]["age"] into tOldAge
         put tK into tOldest
      end if
   end repeat
   if tCount >= kMaxFx then
      if tOldest is empty then return empty
      emitRemove tOldest
   end if
   put Power.All(pPower) into tP
   -- a burst goes off where it is aimed
   if tP["form"] is "burst" then put pTo into pFrom
   add 1 to sNextId
   put sNextId into tId
   if pTarget is empty then put Emit.Nearest(item 1 of pTo, item 2 of pTo, pOwner) into pTarget
   put tP into tF["p"]
   put pPower into tF["power"]
   put tP["form"] into tF["form"]
   put tP["element"] into tF["element"]
   put pOwner into tF["owner"]
   put pTarget into tF["target"]
   put pDepth into tF["depth"]
   put pFrom into tF["from"]
   put pTo into tF["to"]
   put item 1 of pFrom into tF["x"]
   put item 2 of pFrom into tF["y"]
   put 0 into tF["age"]
   put tP["life"] into tF["life"]
   put (pHeld is true) into tF["held"]
   put 0 into tF["nd"]
   put 0 into tF["dotAcc"]
   put empty into tF["hit"]
   put false into tF["done"]
   put tP["radius"] into tF["r"]
   put empty into tF["trail"]
   put 0 into tF["beamTick"]
   -- aim
   put item 1 of pTo - item 1 of pFrom into tDX
   put item 2 of pTo - item 2 of pFrom into tDY
   put max(1, sqrt(tDX * tDX + tDY * tDY)) into tD
   put atan2(tDY, tDX) into tF["ang"]
   if tF["form"] is "bit" or tF["form"] is "ball" then
      put max(40, tP["speed"]) into tSpeed
      put tD / tSpeed into tT
      put tDX / tT into tF["vx"]
      put tDY / tT - 0.5 * tP["gravity"] * tT into tF["vy"]
      if tF["held"] and tF["form"] is "ball" and tP["charge"] > 0 then
         put true into tF["charging"]
         put tP["radius"] * 0.3 into tF["r"]
      end if
   end if
   if tF["form"] is "chain" then put emitChainHops(pFrom, pTarget, pOwner, tP["jumps"], tP["reach"]) into tF["hops"]
   put tF into sFx[tId]
   -- what happens at once
   if tP["flash"] > 0 and tF["form"] is among the items of "strike,burst,blast" then emitFlash tP["flash"], tP["colorFlash"]
   if tF["form"] is among the items of "blast,strike,shock,burst" then
      if tF["form"] is "blast" or tF["form"] is "burst" then
         emitBurstDots tId, item 1 of pFrom, item 2 of pFrom, tP["burstDots"]
      else
         emitBurstDots tId, item 1 of pTo, item 2 of pTo, tP["burstDots"]
      end if
      emitInstantHits tId
   end if
   return tId
end Emit.Fire

-- a beam's end or a charging ball's aim moves; pFrom too when given
command Emit.Hold pId, pTo, pFrom
   if sFx[pId] is not an array then exit Emit.Hold
   if pTo is not empty then put pTo into sFx[pId]["to"]
   if pFrom is not empty then
      put pFrom into sFx[pId]["from"]
      if sFx[pId]["charging"] is true then
         put item 1 of pFrom into sFx[pId]["x"]
         put item 2 of pFrom into sFx[pId]["y"]
      end if
   end if
end Emit.Hold

-- let go: a beam fades out, a charging ball leaves the hand
command Emit.Release pId
   local tF, tDX, tDY, tD, tT, tSpeed
   if sFx[pId] is not an array then exit Emit.Release
   put sFx[pId] into tF
   put false into tF["held"]
   if tF["form"] is "beam" then put tF["age"] + 0.15 into tF["life"]
   if tF["charging"] is true then
      put false into tF["charging"]
      put item 1 of tF["to"] - tF["x"] into tDX
      put item 2 of tF["to"] - tF["y"] into tDY
      put max(1, sqrt(tDX * tDX + tDY * tDY)) into tD
      put max(40, tF["p"]["speed"]) into tSpeed
      put tD / tSpeed into tT
      put tDX / tT into tF["vx"]
      put tDY / tT - 0.5 * tF["p"]["gravity"] * tT into tF["vy"]
      put tF["age"] + tF["p"]["life"] into tF["life"]
   end if
   put tF into sFx[pId]
end Emit.Release

command Emit.Kill pId
   emitRemove pId
end Emit.Kill

command Emit.Clear
   local tK
   repeat for each key tK in sFx
      emitRemove tK
   end repeat
   put empty into sFx
   put 0 into sDotCount
end Emit.Clear

function Emit.Alive pId
   return sFx[pId] is an array
end Emit.Alive

function Emit.Ids
   local tK
   put the keys of sFx into tK
   sort lines of tK numeric
   return tK
end Emit.Ids

-- the hits since the last call (then forgotten): id, target, power, splat, knockback,
-- afterburn, x, y (tab separated, one a line)
function Emit.Hits
   local tH
   put sHits into tH
   put empty into sHits
   return tH
end Emit.Hits

-- effects, dots, segments, ms of the last step and draw
function Emit.Counts
   local tK, tN
   put 0 into tN
   repeat for each key tK in sFx
      add 1 to tN
   end repeat
   return tN & comma & sDotCount & comma & sSegCount & comma & sLastMS
end Emit.Counts

-- the stage shake as dx,dy for this frame
function Emit.Shake
   if sShake < 0.5 then return "0,0"
   return round((Emit.Rnd() * 2 - 1) * sShake) & comma & round((Emit.Rnd() * 2 - 1) * sShake)
end Emit.Shake

-- the flash: level 0..1, colour
function Emit.Flash
   return round(sFlash, 2) & tab & sFlashColor
end Emit.Flash

private command emitFlash pLevel, pColor
   if pLevel > sFlash then
      put pLevel into sFlash
      put pColor into sFlashColor
   end if
end emitFlash

private command emitRemove pId
   if sFx[pId] is not an array then exit emitRemove
   subtract sFx[pId]["nd"] from sDotCount
   if sDotCount < 0 then put 0 into sDotCount
   delete variable sFx[pId]
end emitRemove

-- the hops of a chain: from the hand to the first target, then the nearest not yet hit
private function emitChainHops pFrom, pTarget, pOwner, pJumps, pReach
   local tOut, tSeen, tCur, tX, tY, i, tNext
   put pFrom & cr into tOut
   put pOwner into tSeen
   put pTarget into tCur
   if tCur is empty then return pFrom
   repeat with i = 0 to pJumps
      if tCur is empty then exit repeat
      put item 1 of sTargets[tCur] into tX
      put item 2 of sTargets[tCur] into tY
      put tX & comma & tY & comma & tCur & cr after tOut
      put comma & tCur after tSeen
      put Emit.Nearest(tX, tY, tSeen, pReach) into tCur
   end repeat
   delete the last char of tOut
   return tOut
end emitChainHops

private command emitHit pId, pTarget, pScale, pX, pY
   local tP, tMidAB
   put sFx[pId]["p"] into tP
   if pTarget is empty or pTarget is sFx[pId]["owner"] then exit emitHit
   if pScale is not a number then put 1 into pScale
   put pId & tab & pTarget & tab & sFx[pId]["power"] & tab & round(tP["splat"] * pScale, 2) & tab & round(tP["knockback"] * pScale) & tab & tP["afterburn"] & tab & round(pX) & tab & round(pY) & cr after sHits
   if tP["shake"] > sShake then put tP["shake"] into sShake
   if sFx[pId]["form"] is not "beam" or sFx[pId]["burned"] is not true then
      if tP["afterburn"] is not "none" and tP["afterburnTime"] > 0 then emitAfterburn pId, pTarget
      put true into sFx[pId]["burned"]
   end if
   if tP["onHit"] is not "none" and tP["onHit"] is not empty and sFx[pId]["form"] is not "beam" then
      get Emit.Fire(tP["onHit"], round(pX) & comma & round(pY), round(pX) & comma & round(pY), sFx[pId]["owner"], pTarget, false, sFx[pId]["depth"] + 1)
   end if
end emitHit

-- the afterburn is an effect of its own that sits on the target
private command emitAfterburn pId, pTarget
   local tF, tP, tK, tNew
   -- one afterburn a target: a new one replaces the old
   repeat for each key tK in sFx
      if sFx[tK]["form"] is "afterburn" and sFx[tK]["target"] is pTarget then emitRemove tK
   end repeat
   put sFx[pId]["p"] into tP
   add 1 to sNextId
   put sNextId into tNew
   put tP into tF["p"]
   put sFx[pId]["power"] into tF["power"]
   put "afterburn" into tF["form"]
   put tP["afterburn"] into tF["kind"]
   put sFx[pId]["element"] into tF["element"]
   put pTarget into tF["target"]
   put sFx[pId]["owner"] into tF["owner"]
   put 0 into tF["age"]
   put tP["afterburnTime"] into tF["life"]
   put 0 into tF["nd"]
   put 0 into tF["dotAcc"]
   put false into tF["held"]
   put 9 into tF["depth"]
   put tF into sFx[tNew]
end emitAfterburn

-- blast, strike, shock and burst hit at once
private command emitInstantHits pId
   local tF, tP, tK, tTX, tTY, tD, tA, tDiff, tFX, tFY
   put sFx[pId] into tF
   put tF["p"] into tP
   put item 1 of tF["from"] into tFX
   put item 2 of tF["from"] into tFY
   switch tF["form"]
      case "strike"
         if tF["target"] is not empty then
            emitHit pId, tF["target"], 1, item 1 of sTargets[tF["target"]], item 2 of sTargets[tF["target"]]
         end if
         break
      case "shock"
         if tF["target"] is not empty then
            put Emit.Dist(tFX, tFY, item 1 of sTargets[tF["target"]], item 2 of sTargets[tF["target"]]) into tD
            if tD <= tP["reach"] + item 3 of sTargets[tF["target"]] then emitHit pId, tF["target"], 1, item 1 of sTargets[tF["target"]], item 2 of sTargets[tF["target"]]
         end if
         break
      case "blast"
         repeat for each key tK in sTargets
            if tK is tF["owner"] then next repeat
            put item 1 of sTargets[tK] into tTX
            put item 2 of sTargets[tK] into tTY
            put Emit.Dist(tFX, tFY, tTX, tTY) into tD
            if tD > tP["reach"] + item 3 of sTargets[tK] then next repeat
            put atan2(tTY - tFY, tTX - tFX) into tA
            put abs(tA - tF["ang"]) into tDiff
            if tDiff > pi then put 2 * pi - tDiff into tDiff
            if tDiff <= tP["cone"] * kDeg / 2 + 0.15 then emitHit pId, tK, 1, tTX, tTY
         end repeat
         break
      case "burst"
         repeat for each key tK in sTargets
            if tK is tF["owner"] then next repeat
            put Emit.Dist(tFX, tFY, item 1 of sTargets[tK], item 2 of sTargets[tK]) into tD
            if tD <= tP["radius"] + tP["growth"] * tP["life"] * 0.5 + item 3 of sTargets[tK] then emitHit pId, tK, 1, item 1 of sTargets[tK], item 2 of sTargets[tK]
         end repeat
         break
   end switch
end emitInstantHits

-- make dots: at x,y, count, direction (degrees; empty = all round)
private command emitBurstDots pId, pX, pY, pCount, pDir
   local tF, tP, i, tA, tS, tN, tSpread
   if pCount < 1 or sFx[pId] is not an array then exit emitBurstDots
   put sFx[pId] into tF
   put tF["p"] into tP
   put tF["nd"] into tN
   if pDir is a number then
      put tP["dotSpread"] into tSpread
   else
      put 360 into tSpread
      put 0 into pDir
   end if
   repeat with i = 1 to pCount
      if sDotCount >= kMaxDots then exit repeat
      put (pDir + (Emit.Rnd() - 0.5) * tSpread) * kDeg into tA
      put tP["dotSpeed"] * (0.4 + Emit.Rnd() * 0.6) into tS
      add 1 to tN
      add 1 to sDotCount
      put pX & comma & pY & comma & (cos(tA) * tS) & comma & (sin(tA) * tS) & comma & 0 & comma & (tP["dotLife"] * (0.5 + Emit.Rnd() * 0.5)) into tF["dots"][tN]
   end repeat
   put tN into tF["nd"]
   put tF into sFx[pId]
end emitBurstDots

-- move every effect on by pDT seconds, then work out its lines
command Emit.Step pDT
   local tStart, tK, tIds, tF
   put the milliseconds into tStart
   if pDT > 0.1 then put 0.1 into pDT
   if pDT < 0 then put 0 into pDT
   put max(0, sShake - pDT * 30) into sShake
   put max(0, sFlash - pDT * 4) into sFlash
   if sSegCount > kMaxSegs then
      put max(0.25, sSegScale * kMaxSegs / sSegCount) into sSegScale
   else
      put min(1, sSegScale + 0.05) into sSegScale
   end if
   put 0 into sSegCount
   put the keys of sFx into tIds
   sort lines of tIds numeric
   repeat for each line tK in tIds
      if sFx[tK] is not an array then next repeat
      emitStepOne tK, pDT
   end repeat
   put the milliseconds - tStart into sLastMS
end Emit.Step

private command emitStepOne pId, pDT
   local tF, tP, tForm, tT, tFX, tFY, tTX, tTY, tHas, tNew, tEnd
   put sFx[pId] into tF
   put tF["p"] into tP
   put tF["form"] into tForm
   add pDT to tF["age"]
   put tF into sFx[pId]
   -- where is the target now
   if tF["target"] is not empty and sTargets[tF["target"]] is not empty then
      put item 1 of sTargets[tF["target"]] into tTX
      put item 2 of sTargets[tF["target"]] into tTY
      put true into tHas
   else
      put item 1 of tF["to"] into tTX
      put item 2 of tF["to"] into tTY
      put false into tHas
   end if
   if tForm is "bit" then put "ball" into tForm
   switch tForm
      case "ball"
         emitStepProjectile pId, pDT, tTX, tTY, tHas
         break
      case "beam"
         emitStepBeam pId, pDT, tTX, tTY, tHas
         break
      case "wave"
         emitStepWave pId, pDT
         break
      case "chain"
         emitStepChain pId, pDT
         break
      case "afterburn"
         emitStepAfterburn pId, pDT
         break
      default
         -- blast, strike, shock, burst
         emitStepInstant pId, pDT, tTX, tTY
   end switch
   if sFx[pId] is not an array then exit emitStepOne
   emitStepDots pId, pDT
   if sFx[pId] is not an array then exit emitStepOne
   put sFx[pId] into tF
   -- the end of its life
   if tF["held"] is not true and tF["charging"] is not true and tF["age"] >= tF["life"] and tF["done"] is not true then
      put true into tF["done"]
      put empty into tF["g"]
      put tF into sFx[pId]
      if tP["onEnd"] is not "none" and tP["onEnd"] is not empty and tF["hit"] is empty and tF["form"] is not "afterburn" then
         get Emit.Fire(tP["onEnd"], round(tF["x"]) & comma & round(tF["y"]), round(tF["x"]) & comma & round(tF["y"]), tF["owner"], empty, false, tF["depth"] + 1)
      end if
   end if
   if sFx[pId]["done"] is true and sFx[pId]["nd"] = 0 then emitRemove pId
end emitStepOne

-- how much of the effect is left, 1 .. 0
private function emitFade pF
   if pF["held"] is true or pF["life"] <= 0 then return 1
   return Emit.Clamp(1 - pF["age"] / pF["life"], 0, 1)
end emitFade

private function emitSegs pN
   return max(2, round(pN * sSegScale))
end emitSegs

private command emitCount pText
   if pText is not empty then add the number of lines of pText to sSegCount
end emitCount

-- bits and balls: fly, home, wander, trail, hit
private command emitStepProjectile pId, pDT, pTX, pTY, pHas
   local tF, tP, tSpeed, tDX, tDY, tD, tA, tW, tR, tG, tSph, tSeed, tTime, i, tTong, tTA, tTr, tHitR, tN, tMove
   put sFx[pId] into tF
   put tF["p"] into tP
   if tF["done"] is true then exit emitStepProjectile
   put tP["seed"] into tSeed
   put tF["age"] into tTime
   if tF["charging"] is true then
      put min(tF["age"], max(0.01, tP["charge"])) / max(0.01, tP["charge"]) into tR
      put tP["radius"] * (0.3 + 0.9 * tR) into tF["r"]
   else
      -- homing and wander turn the velocity
      put sqrt(tF["vx"] ^ 2 + tF["vy"] ^ 2) into tSpeed
      if tP["homing"] > 0 and pHas then
         put pTX - tF["x"] into tDX
         put pTY - tF["y"] into tDY
         put max(1, sqrt(tDX * tDX + tDY * tDY)) into tD
         add (tDX / tD * tSpeed - tF["vx"]) * min(1, tP["homing"] * pDT * 4) to tF["vx"]
         add (tDY / tD * tSpeed - tF["vy"]) * min(1, tP["homing"] * pDT * 4) to tF["vy"]
      end if
      if tP["wander"] > 0 then
         put Emit.Noise(tTime * 2, tSeed) * tP["wander"] * pDT * 6 into tW
         put tF["vx"] * cos(tW) - tF["vy"] * sin(tW) into tDX
         put tF["vx"] * sin(tW) + tF["vy"] * cos(tW) into tDY
         put tDX into tF["vx"]
         put tDY into tF["vy"]
      end if
      -- turning never slows it down
      put sqrt(tF["vx"] ^ 2 + tF["vy"] ^ 2) into tD
      if tD > 0.001 and (tP["homing"] > 0 or tP["wander"] > 0) then
         put tF["vx"] * tSpeed / tD into tF["vx"]
         put tF["vy"] * tSpeed / tD into tF["vy"]
      end if
      add tP["gravity"] * pDT to tF["vy"]
      add tF["vx"] * pDT to tF["x"]
      add tF["vy"] * pDT to tF["y"]
      put atan2(tF["vy"], tF["vx"]) into tF["ang"]
      if tP["pulse"] > 0 then put tP["radius"] * (1 + tP["pulse"] * sin(tTime * 9)) into tF["r"]
   end if
   -- trail: newest first
   put round(tF["x"]) & comma & round(tF["y"]) & cr & tF["trail"] into tF["trail"]
   put max(2, tP["trail"] + 1) into tN
   if the number of lines of tF["trail"] > tN then delete line tN + 1 to -1 of tF["trail"]
   -- the lines
   put empty into tF["g"]
   if tP["trail"] > 0 and the number of lines of tF["trail"] > 1 then
      if tF["form"] is "bit" then
         put tF["trail"] into tF["g"]["core"]
      else
         put tF["trail"] into tF["g"]["back"]
      end if
   end if
   emitBall tF, tF["x"], tF["y"], tF["r"]
   -- flame tongues stream backward
   if tP["tongues"] > 0 then
      put tF["ang"] * 180 / pi + 180 into tA
      if tF["charging"] is true then put -90 into tA
      repeat with i = 1 to tP["tongues"]
         put tA + (i - (tP["tongues"] + 1) / 2) * (100 / max(1, tP["tongues"])) + Emit.Noise(tTime * 4 + i, tSeed) * 15 into tTA
         put tP["tongueLen"] * (0.6 + 0.4 * (Emit.Noise(tTime * 5 + i * 3, tSeed) + 1) / 2) * (tF["r"] / max(1, tP["radius"])) into tTr
         put Emit.Join(tF["g"]["fill"], Emit.Tongue(tF["x"] + cos(tTA * kDeg) * tF["r"] * 0.6, tF["y"] + sin(tTA * kDeg) * tF["r"] * 0.6, tTA, tTr, tF["r"] * 0.7, tTime + i, tSeed + i)) into tF["g"]["fill"]
      end repeat
   end if
   emitCount tF["g"]["core"]
   put tF into sFx[pId]
   -- dots from the head
   emitRateDots pId, pDT, tF["x"], tF["y"], tF["ang"] * 180 / pi + 180
   if sFx[pId]["charging"] is true then exit emitStepProjectile
   -- hits: a target, the floor, the stage's edge
   put sFx[pId] into tF
   repeat for each key i in sTargets
      if i is tF["owner"] then next repeat
      put tF["r"] + item 3 of sTargets[i] into tHitR
      if Emit.Dist(tF["x"], tF["y"], item 1 of sTargets[i], item 2 of sTargets[i]) <= tHitR then
         put i into tF["hit"]
         put true into tF["done"]
         put empty into tF["g"]
         put tF into sFx[pId]
         emitBurstDots pId, tF["x"], tF["y"], tP["burstDots"]
         emitHit pId, i, 1, tF["x"], tF["y"]
         exit emitStepProjectile
      end if
   end repeat
   if (sFloorY is a number and tF["y"] > sFloorY and tF["vy"] > 0) or (sStage is not empty and (tF["x"] < item 1 of sStage - 60 or tF["x"] > item 3 of sStage + 60)) then
      put tF["age"] into tF["life"]
      put tF into sFx[pId]
      emitBurstDots pId, tF["x"], min(tF["y"], sFloorY), tP["burstDots"] div 2
   end if
end emitStepProjectile

-- the ball itself (flat orb or a vector sphere) into the effect's lines
private command emitBall @pF, pX, pY, pR
   local tP, tM, tKey, tPr, tTime
   put pF["p"] into tP
   put pF["age"] into tTime
   if tP["sphere"] is "orb" or tP["sphere"] is empty then
      put Emit.Join(pF["g"]["core"], Emit.Ring(pX, pY, pR + tP["jitter"] * 0.6 * Emit.Noise(tTime * tP["jitterHz"], tP["seed"]), max(10, tP["segments"]), 0, 360, tP["jitter"] * 0.5, tTime * tP["jitterHz"], tP["seed"])) into pF["g"]["core"]
      put Emit.Join(pF["g"]["fill"], Emit.Ring(pX, pY, pR * 0.6, 12, 0, 360, 0, 0, 1)) into pF["g"]["fill"]
      exit emitBall
   end if
   put emitModel(tP) into tKey
   put sModels[tKey] into tM
   put Sphere.Project(tM, pX, pY, pR, tP["tilt"] + tP["spinX"] * tTime, tP["spinY"] * tTime, tP["spinZ"] * tTime, tP["perspective"], tP["wobble"], tTime * max(0.5, tP["jitterHz"] / 4), tP["seed"], tP["backFace"], tP["wire"], round(tP["edgeCap"] * sSegScale)) into tPr
   put Emit.Join(pF["g"]["core"], tPr["front"]) into pF["g"]["core"]
   put Emit.Join(pF["g"]["back"], tPr["back"]) into pF["g"]["back"]
   if tPr["dots"] is not empty then
      if pF["g"]["vdots"] is empty then
         put tPr["dots"] into pF["g"]["vdots"]
      else
         put cr & tPr["dots"] after pF["g"]["vdots"]
      end if
   end if
end emitBall

-- the model for a power's sphere settings, made once and kept
private function emitModel pP
   local tKey, tA, tK
   put pP["sphere"] into tKey
   repeat for each item tK in "sRings,sMeridians,subdivide,grid,solid,points,links,turns,hoops,seed"
      put "|" & pP[tK] after tKey
      put pP[tK] into tA[tK]
   end repeat
   if sModels[tKey] is not an array then put Sphere.Make(pP["sphere"], tA) into sModels[tKey]
   return tKey
end emitModel

-- the size of a model, for the editor: vertices, edges
function Emit.ModelSize pPower
   local tP, tKey
   put Power.All(pPower) into tP
   if tP["sphere"] is "orb" then return "1,0"
   put emitModel(tP) into tKey
   return sModels[tKey]["n"] & comma & sModels[tKey]["e"]
end Emit.ModelSize

-- beams: hand to target, held or for its life
private command emitStepBeam pId, pDT, pTX, pTY, pHas
   local tF, tP, tFX, tFY, tEX, tEY, tD, tLen, tSeed, tPts, i, tN, tT, tPX, tPY, tTick
   put sFx[pId] into tF
   put tF["p"] into tP
   if tF["done"] is true then exit emitStepBeam
   put item 1 of tF["from"] into tFX
   put item 2 of tF["from"] into tFY
   put Emit.Dist(tFX, tFY, pTX, pTY) into tD
   if tP["speed"] > 0 then
      put min(tD, tF["age"] * tP["speed"]) into tLen
   else
      put tD into tLen
   end if
   if tD > 0 then
      put tFX + (pTX - tFX) * tLen / tD into tEX
      put tFY + (pTY - tFY) * tLen / tD into tEY
   else
      put tFX into tEX
      put tFY into tEY
   end if
   put tEX into tF["x"]
   put tEY into tF["y"]
   put empty into tF["g"]
   put tP["seed"] + trunc(tF["age"] * tP["jitterHz"]) into tSeed
   if tP["smooth"] >= 0.5 then
      put Emit.Wobble(tFX, tFY, tEX, tEY, emitSegs(tP["segments"]), tP["jitter"], tF["age"] * tP["jitterHz"] / 3, tP["seed"]) into tPts
   else
      put Emit.Jag(tFX, tFY, tEX, tEY, emitSegs(tP["segments"]), tP["jitter"], tSeed, tP["branchChance"], tP["branchDepth"]) into tPts
   end if
   put tPts into tF["g"]["core"]
   -- flame tongues along the beam, pointing up
   if tP["tongues"] > 0 and tLen > 10 then
      put max(1, round(tP["tongues"] * tLen / 100)) into tN
      repeat with i = 1 to tN
         put (i - 0.5) / tN into tT
         put tFX + (tEX - tFX) * tT into tPX
         put tFY + (tEY - tFY) * tT into tPY
         put Emit.Join(tF["g"]["fill"], Emit.Tongue(tPX, tPY, -90 + Emit.Noise(tF["age"] * 3 + i, tP["seed"]) * 25, tP["tongueLen"] * (0.5 + 0.5 * (1 + Emit.Noise(tF["age"] * 6 + i * 2, tP["seed"])) / 2), tP["coreWidth"] * 3 + 4, tF["age"] + i, tP["seed"] + i)) into tF["g"]["fill"]
      end repeat
   end if
   -- the end glows: a little ring at the hit point
   put Emit.Join(tF["g"]["back"], Emit.Ring(tEX, tEY, tP["coreWidth"] * 3 + 4, 10, 0, 360, tP["jitter"] * 0.3, tF["age"] * 8, tP["seed"])) into tF["g"]["back"]
   emitCount tPts
   -- beam distortion: three points along it
   put empty into tF["src"]
   if tP["distort"] > 0 then
      repeat with i = 1 to 3
         put (tFX + (tEX - tFX) * i / 4) & comma & (tFY + (tEY - tFY) * i / 4) & comma & tP["distort"] * emitFade(tF) & comma & tP["distortReach"] & comma & tP["distortWave"] & comma & 0 & comma & tF["age"] & cr after tF["src"]
      end repeat
   end if
   put tF into sFx[pId]
   -- dots fly off a random point along it
   put Emit.Rnd() into tT
   emitRateDots pId, pDT, tFX + (tEX - tFX) * tT, tFY + (tEY - tFY) * tT, empty
   -- a beam hits while it touches, a little every 0.2 s
   if pHas and tLen >= tD - 2 then
      add pDT to sFx[pId]["beamTick"]
      if sFx[pId]["beamTick"] >= 0.2 then
         put 0 into sFx[pId]["beamTick"]
         emitHit pId, sFx[pId]["target"], 0.2, tEX, tEY
      end if
   end if
end emitStepBeam

-- waves: rings grow out from the caster, along the arc toward the target
private command emitStepWave pId, pDT
   local tF, tP, tCX, tCY, tR, k, tRK, tA0, tA1, tPts, tK, tD, tA, tDiff, tFade, i, tT, tAA, tPX, tPY, tN
   put sFx[pId] into tF
   put tF["p"] into tP
   if tF["done"] is true then exit emitStepWave
   put item 1 of tF["from"] into tCX
   put item 2 of tF["from"] into tCY
   put tP["radius"] + tP["growth"] * tF["age"] into tR
   put tR into tF["r"]
   put tF["ang"] * 180 / pi - tP["arc"] / 2 into tA0
   put tF["ang"] * 180 / pi + tP["arc"] / 2 into tA1
   put empty into tF["g"]
   put empty into tF["src"]
   put emitFade(tF) into tFade
   repeat with k = 1 to tP["rings"]
      put tR - (k - 1) * tP["ringGap"] into tRK
      if tRK <= 2 then next repeat
      put Emit.Ring(tCX, tCY, tRK, emitSegs(max(tP["segments"], round(tP["arc"] / 6))), tA0, tA1, tP["jitter"], tF["age"] * tP["jitterHz"], tP["seed"] + k) into tPts
      if k = 1 then
         put Emit.Join(tF["g"]["core"], tPts) into tF["g"]["core"]
      else
         put Emit.Join(tF["g"]["back"], tPts) into tF["g"]["back"]
      end if
      emitCount tPts
      if tP["distort"] > 0 then put tCX & comma & tCY & comma & tP["distort"] * tFade & comma & max(10, tP["distortReach"] / 3) & comma & tP["distortWave"] & comma & tRK & comma & tF["age"] & cr after tF["src"]
   end repeat
   -- flame tongues stand on the front ring
   if tP["tongues"] > 0 then
      repeat with i = 1 to tP["tongues"]
         put (i - 0.5) / tP["tongues"] into tT
         put (tA0 + (tA1 - tA0) * tT) * kDeg into tAA
         put tCX + cos(tAA) * tR into tPX
         put tCY + sin(tAA) * tR into tPY
         if sFloorY is a number and tPY > sFloorY then put sFloorY into tPY
         put Emit.Join(tF["g"]["fill"], Emit.Tongue(tPX, tPY, -90 + Emit.Noise(tF["age"] * 3 + i, tP["seed"]) * 20, tP["tongueLen"] * tFade * (0.6 + 0.4 * (1 + Emit.Noise(tF["age"] * 5 + i, tP["seed"])) / 2), 10, tF["age"] + i, tP["seed"] + i)) into tF["g"]["fill"]
      end repeat
   end if
   put tF into sFx[pId]
   -- dots from a random point of the front
   put (tA0 + (tA1 - tA0) * Emit.Rnd()) * kDeg into tAA
   emitRateDots pId, pDT, tCX + cos(tAA) * tR, tCY + sin(tAA) * tR, tAA / kDeg
   -- the front passes a target
   repeat for each key tK in sTargets
      if tK is sFx[pId]["owner"] or tK is among the items of sFx[pId]["hitList"] then next repeat
      put Emit.Dist(tCX, tCY, item 1 of sTargets[tK], item 2 of sTargets[tK]) into tD
      if tR < tD - item 3 of sTargets[tK] then next repeat
      put atan2(item 2 of sTargets[tK] - tCY, item 1 of sTargets[tK] - tCX) into tA
      put abs(tA - sFx[pId]["ang"]) into tDiff
      if tDiff > pi then put 2 * pi - tDiff into tDiff
      if tDiff <= tP["arc"] * kDeg / 2 + 0.2 then
         put comma & tK after sFx[pId]["hitList"]
         emitHit pId, tK, 1, item 1 of sTargets[tK], item 2 of sTargets[tK]
      end if
   end repeat
end emitStepWave

-- chains: one jagged hop after another (hits first, then this frame's lines)
private command emitStepChain pId, pDT
   local tF, tP, tHops, i, tN, tA, tB, tPts, tSeed, tName, tLive
   put sFx[pId] into tF
   put tF["p"] into tP
   if tF["done"] is true then exit emitStepChain
   put tF["hops"] into tHops
   put the number of lines of tHops into tN
   put 1 into tLive
   repeat with i = 2 to tN
      if tF["age"] < (i - 2) * tP["jumpDelay"] then exit repeat
      put i into tLive
      put line i of tHops into tB
      put item 3 of tB into tName
      if tName is not empty and tName is not among the items of sFx[pId]["hitList"] then
         put comma & tName after sFx[pId]["hitList"]
         emitBurstDots pId, item 1 of tB, item 2 of tB, tP["burstDots"] div 3
         emitHit pId, tName, 0.8 ^ (i - 2), item 1 of tB, item 2 of tB
      end if
   end repeat
   if sFx[pId] is not an array then exit emitStepChain
   put sFx[pId] into tF
   put empty into tF["g"]
   put tP["seed"] + trunc(tF["age"] * tP["jitterHz"]) into tSeed
   repeat with i = 2 to tLive
      put line i - 1 of tHops into tA
      put line i of tHops into tB
      put Emit.Jag(item 1 of tA, item 2 of tA, item 1 of tB, item 2 of tB, emitSegs(round(tP["segments"] * 0.8 ^ (i - 2))), tP["jitter"] * 0.8 ^ (i - 2), tSeed + i, tP["branchChance"] * 0.5, max(0, tP["branchDepth"] - 1)) into tPts
      put Emit.Join(tF["g"]["core"], tPts) into tF["g"]["core"]
      emitCount tPts
   end repeat
   put tF into sFx[pId]
end emitStepChain

-- blast, strike, shock and burst: lines only (they hit when fired)
private command emitStepInstant pId, pDT, pTX, pTY
   local tF, tP, tFX, tFY, tSeed, tGrow, tR, tPts, i, tA0, tA1, tTop, tN, tAA, tLen, tA, tL
   put sFx[pId] into tF
   put tF["p"] into tP
   if tF["done"] is true then exit emitStepInstant
   put item 1 of tF["from"] into tFX
   put item 2 of tF["from"] into tFY
   put tP["seed"] + trunc(tF["age"] * tP["jitterHz"]) into tSeed
   put Emit.Clamp(tF["age"] / max(0.05, tF["life"] * 0.4), 0, 1) into tGrow
   put empty into tF["g"]
   put empty into tF["src"]
   switch tF["form"]
      case "blast"
         put tF["ang"] * 180 / pi - tP["cone"] / 2 into tA0
         put tF["ang"] * 180 / pi + tP["cone"] / 2 into tA1
         if tP["jitter"] < 1 then
            put Emit.Rays(tFX, tFY, tP["rays"], tA0, tA1, 6, tP["reach"] * tGrow * 0.6, tP["reach"] * tGrow, tP["seed"]) into tPts
         else
            Emit.Seed tP["seed"]
            repeat with i = 1 to tP["rays"]
               put (tA0 + (tA1 - tA0) * (i - 1) / max(1, tP["rays"] - 1)) * kDeg into tA
               put tP["reach"] * tGrow * (0.6 + 0.4 * Emit.Hash(i, tP["seed"])) into tL
               put Emit.Join(tPts, Emit.Jag(tFX, tFY, tFX + cos(tA) * tL, tFY + sin(tA) * tL, emitSegs(max(2, tP["segments"] div 2)), tP["jitter"] * 0.5, tSeed + i, 0, 0)) into tPts
            end repeat
         end if
         put tPts into tF["g"]["core"]
         emitCount tPts
         put tF into sFx[pId]
         put (tA0 + (tA1 - tA0) * Emit.Rnd()) into tAA
         emitRateDots pId, pDT, tFX, tFY, tAA
         exit emitStepInstant
      case "strike"
         put item 2 of sStage into tTop
         if tTop is not a number then put pTY - 300 into tTop
         put Emit.Jag(pTX + Emit.Noise(tF["age"] * 3, tP["seed"]) * 40, tTop, pTX, pTY, emitSegs(tP["segments"]), tP["jitter"], tSeed, tP["branchChance"], tP["branchDepth"]) into tPts
         put tPts into tF["g"]["core"]
         emitCount tPts
         put pTX into tF["x"]
         put pTY into tF["y"]
         break
      case "shock"
         Emit.Seed tSeed
         put max(3, tP["segments"]) into tN
         repeat with i = 1 to 5
            put Emit.Rnd() * kTau into tA
            put Emit.Join(tPts, Emit.Jag(tFX, tFY, tFX + cos(tA) * (10 + Emit.Rnd() * 20), tFY + sin(tA) * (10 + Emit.Rnd() * 20), tN, tP["jitter"], tSeed + i, 0, 0)) into tPts
         end repeat
         if tF["target"] is not empty and Emit.Dist(tFX, tFY, pTX, pTY) <= tP["reach"] + 40 then
            put Emit.Join(tPts, Emit.Jag(tFX, tFY, pTX, pTY, emitSegs(tN * 2), tP["jitter"], tSeed + 9, tP["branchChance"], 1)) into tPts
            repeat with i = 1 to 4
               put Emit.Rnd() * kTau into tA
               put Emit.Join(tPts, Emit.Jag(pTX, pTY, pTX + cos(tA) * (8 + Emit.Rnd() * 18), pTY + sin(tA) * (8 + Emit.Rnd() * 18), tN, tP["jitter"], tSeed + 20 + i, 0, 0)) into tPts
            end repeat
         end if
         put tPts into tF["g"]["core"]
         emitCount tPts
         break
      case "burst"
         put tP["radius"] + tP["growth"] * tF["age"] into tR
         put Emit.Rays(tFX, tFY, tP["rays"], 0, 360, tR * 0.3, tR * 0.6, tR, tP["seed"]) into tPts
         put tPts into tF["g"]["core"]
         put Emit.Ring(tFX, tFY, tR, emitSegs(max(16, tP["segments"])), 0, 360, tP["jitter"], tF["age"] * tP["jitterHz"], tP["seed"]) into tF["g"]["back"]
         emitCount tPts
         if tP["tongues"] > 0 then
            repeat with i = 1 to tP["tongues"]
               put 360 * (i - 1) / tP["tongues"] + Emit.Noise(tF["age"] * 2 + i, tP["seed"]) * 15 into tAA
               put Emit.Join(tF["g"]["fill"], Emit.Tongue(tFX + cos(tAA * kDeg) * tR * 0.4, tFY + sin(tAA * kDeg) * tR * 0.4, tAA, tP["tongueLen"] * (1 - tF["age"] / max(0.05, tF["life"])) * 1.5, 12, tF["age"] + i, tP["seed"] + i)) into tF["g"]["fill"]
            end repeat
         end if
         if tP["distort"] > 0 then put tFX & comma & tFY & comma & tP["distort"] * emitFade(tF) & comma & max(10, tP["distortReach"] / 3) & comma & tP["distortWave"] & comma & tR & comma & tF["age"] & cr into tF["src"]
         put tFX into tF["x"]
         put tFY into tF["y"]
         break
   end switch
   put tF into sFx[pId]
end emitStepInstant

-- afterburns, drawn on the target's bones
private command emitStepAfterburn pId, pDT
   local tF, tP, tT, tB, tHead, tTop, tX, tY, i, tL, tN, tPts, tA, tK, tCnt
   put sFx[pId] into tF
   put tF["p"] into tP
   if tF["done"] is true or sTargets[tF["target"]] is empty then
      put tF["age"] into tF["life"]
      put true into tF["done"]
      put empty into tF["g"]
      put tF into sFx[pId]
      exit emitStepAfterburn
   end if
   put sBones[tF["target"]] into tB
   put item 1 of sTargets[tF["target"]] into tX
   put item 2 of sTargets[tF["target"]] into tY
   put tY - item 3 of sTargets[tF["target"]] * 1.4 into tTop
   put empty into tF["g"]
   put tF["age"] into tT
   switch tF["kind"]
      case "engulfed"
         put 0 into tCnt
         repeat for each line tL in tB
            if tL is empty then next repeat
            add 1 to tCnt
            if tCnt mod 3 is not 0 then next repeat
            put Emit.Join(tF["g"]["fill"], Emit.Tongue(item 1 of tL, item 2 of tL, -90 + Emit.Noise(tT * 3 + tCnt, tP["seed"]) * 25, 14 + 10 * (1 + Emit.Noise(tT * 6 + tCnt, tP["seed"])) * emitFade(tF), 9, tT + tCnt, tP["seed"] + tCnt)) into tF["g"]["fill"]
         end repeat
         put tF into sFx[pId]
         emitRateDots pId, pDT, tX + (Emit.Rnd() - 0.5) * 30, tY, -90
         exit emitStepAfterburn
      case "radiant"
         put tB into tF["g"]["core"]
         put Emit.Rays(tX, tY, 12, tT * 40, tT * 40 + 360, 30, 45, 55 + 10 * sin(tT * 8), tP["seed"]) into tF["g"]["back"]
         break
      case "dizzy"
         repeat with i = 1 to 3
            put tT * 5 + kTau * i / 3 into tA
            put Emit.Join(tF["g"]["core"], Emit.Ring(tX + cos(tA) * 16, tTop + sin(tA) * 5, 3, 5, 0, 360, 0, 0, 1)) into tF["g"]["core"]
         end repeat
         break
      case "frizz"
         repeat with i = 1 to 7
            put (-150 + i * 15) * kDeg into tA
            put Emit.Join(tF["g"]["core"], Emit.Jag(tX + cos(tA) * 8, tTop + 6 + sin(tA) * 8, tX + cos(tA) * 22, tTop + 6 + sin(tA) * 22, 4, 4, tP["seed"] + i + trunc(tT * 12), 0, 0)) into tF["g"]["core"]
         end repeat
         break
      case "stun"
         if trunc(tT * 12) mod 2 = 0 then put Emit.Displace(tB, tX & comma & tY & ",4,200,1,0," & tT) into tF["g"]["core"]
         break
      case "sweat"
         put tF into sFx[pId]
         emitRateDots pId, pDT, tX + (Emit.Rnd() - 0.5) * 20, tTop + 6, 90
         exit emitStepAfterburn
      case "goo"
         put tF into sFx[pId]
         put the number of lines of tB into tN
         if tN > 0 then
            put line (1 + trunc(Emit.Rnd() * tN)) of tB into tL
            if tL is not empty then emitRateDots pId, pDT, item 1 of tL, item 2 of tL, 90
         end if
         exit emitStepAfterburn
   end switch
   put tF into sFx[pId]
end emitStepAfterburn

-- dots made at the effect's rate while it lives
private command emitRateDots pId, pDT, pX, pY, pDir
   local tF, tN
   put sFx[pId] into tF
   if tF["done"] is true or tF["p"]["rate"] <= 0 then exit emitRateDots
   add tF["p"]["rate"] * pDT to tF["dotAcc"]
   put trunc(tF["dotAcc"]) into tN
   subtract tN from tF["dotAcc"]
   put tF into sFx[pId]
   if tN > 0 then emitBurstDots pId, pX, pY, tN, pDir
end emitRateDots

-- move and age the dots
private command emitStepDots pId, pDT
   local tF, tP, tD, i, tN, tNew, tL, tX, tY, tVX, tVY, tAge, tLife, tDrag, tG, tOut
   put sFx[pId] into tF
   if tF["nd"] = 0 then exit emitStepDots
   put tF["p"] into tP
   put tP["dotGravity"] into tG
   put max(0, 1 - tP["dotDrag"] * pDT * 3) into tDrag
   put 0 into tN
   repeat with i = 1 to tF["nd"]
      put tF["dots"][i] into tL
      put item 5 of tL + pDT into tAge
      put item 6 of tL into tLife
      if tAge >= tLife then next repeat
      put item 3 of tL * tDrag into tVX
      put (item 4 of tL + tG * pDT) * tDrag into tVY
      put item 1 of tL + tVX * pDT into tX
      put item 2 of tL + tVY * pDT into tY
      if sFloorY is a number and tY > sFloorY then
         put sFloorY into tY
         put -tVY * 0.3 into tVY
      end if
      add 1 to tN
      put tX & comma & tY & comma & tVX & comma & tVY & comma & tAge & comma & tLife into tNew[tN]
      put round(tX) & comma & round(tY) & cr after tOut
   end repeat
   subtract tF["nd"] - tN from sDotCount
   if sDotCount < 0 then put 0 into sDotCount
   put tNew into tF["dots"]
   put tN into tF["nd"]
   delete the last char of tOut
   if tF["g"]["vdots"] is not empty then
      put tF["g"]["vdots"] & cr & tOut into tF["g"]["dots"]
   else
      put tOut into tF["g"]["dots"]
   end if
   put tF into sFx[pId]
end emitStepDots

-- the distortion sources of every live effect, for Emit.Bend
function Emit.Sources pWhat
   local tK, tOut, tKey
   put "bend" & toUpper(char 1 of pWhat) & char 2 to -1 of pWhat into tKey
   repeat for each key tK in sFx
      if sFx[tK]["src"] is empty then next repeat
      if pWhat is not empty and sFx[tK]["p"][tKey] is false then next repeat
      put sFx[tK]["src"] after tOut
   end repeat
   -- projectiles push from their head
   repeat for each key tK in sFx
      if sFx[tK]["form"] is not among the items of "bit,ball" or sFx[tK]["p"]["distort"] <= 0 or sFx[tK]["done"] is true then next repeat
      if pWhat is not empty and sFx[tK]["p"][tKey] is false then next repeat
      put round(sFx[tK]["x"]) & comma & round(sFx[tK]["y"]) & comma & sFx[tK]["p"]["distort"] & comma & sFx[tK]["p"]["distortReach"] & comma & sFx[tK]["p"]["distortWave"] & comma & 0 & comma & sFx[tK]["age"] & cr after tOut
   end repeat
   return tOut
end Emit.Sources

-- bend a stage line (pWhat: floor, grid, figures) by the live effects
function Emit.Bend pPoints, pWhat
   local tS
   put Emit.Sources(pWhat) into tS
   if tS is empty then return pPoints
   return Emit.Displace(pPoints, tS)
end Emit.Bend

-- an effect's lines this frame: core, back, fill, dots (for tests and other drawers)
function Emit.Lines pId
   return sFx[pId]["g"]
end Emit.Lines

function Emit.Info pId, pKey
   return sFx[pId][pKey]
end Emit.Info

-------------------------------------------------------------------- DRAWING (one card)
-- A pool of graphics made once inside the group pGroup (its rect clips them):
-- per slot: glowW, glowM, back, fill, core, dots; and one flash rectangle on top.

command Draw.Begin pGroup
   local tSlot, tLayer, tR, tG, tOldDef
   Draw.End
   put pGroup into sGroup
   put the rect of group pGroup into tR
   lock screen
   repeat with tSlot = 1 to kMaxFx
      repeat for each item tLayer in kLayers
         reset the templateGraphic
         set the style of the templateGraphic to "polygon"
         set the foregroundColor of the templateGraphic to "255,255,255"
         set the backgroundColor of the templateGraphic to "255,255,255"
         set the opaque of the templateGraphic to false
         set the filled of the templateGraphic to (tLayer is "fill")
         set the antialiased of the templateGraphic to true
         set the capStyle of the templateGraphic to "round"
         set the joinStyle of the templateGraphic to "round"
         set the showBorder of the templateGraphic to false
         set the traversalOn of the templateGraphic to false
         set the visible of the templateGraphic to false
         set the lockLoc of the templateGraphic to false
         create graphic ("EmG_" & tSlot & "_" & tLayer) in group pGroup
         put it into tG
         put tG into sG[tSlot][tLayer]
      end repeat
   end repeat
   reset the templateGraphic
   set the style of the templateGraphic to "rectangle"
   set the foregroundColor of the templateGraphic to "255,255,255"
   set the backgroundColor of the templateGraphic to "255,255,255"
   set the opaque of the templateGraphic to true
   set the filled of the templateGraphic to true
   set the lineSize of the templateGraphic to 0
   set the visible of the templateGraphic to false
   create graphic "EmG_flash" in group pGroup
   put it into sFlashG
   set the rect of sFlashG to tR
   reset the templateGraphic
   put empty into sSlotOf
   put empty into sSlotStyled
   unlock screen
end Draw.Begin

command Draw.End
   local tSlot, tLayer, tG
   repeat for each key tSlot in sG
      repeat for each item tLayer in kLayers
         put sG[tSlot][tLayer] into tG
         if tG is not empty and exists(tG) then delete tG
      end repeat
   end repeat
   if sFlashG is not empty and exists(sFlashG) then delete sFlashG
   put empty into sG
   put empty into sFlashG
   put empty into sSlotOf
   put empty into sSlotStyled
end Draw.End

-- give each live effect a slot, style a slot when its effect changes, write the points
command Draw.Frame
   local tStart, tSlot, tId, tUsed, tFree, tK, tIds, tOff, tDX, tDY, tFl
   put the milliseconds into tStart
   if sG is not an array then exit Draw.Frame
   lock screen
   -- slots of effects that are gone become free
   repeat with tSlot = 1 to kMaxFx
      put sSlotOf[tSlot] into tId
      if tId is not empty and sFx[tId] is not an array then put empty into sSlotOf[tSlot]
      if sSlotOf[tSlot] is not empty then put true into tUsed[sSlotOf[tSlot]]
   end repeat
   put the keys of sFx into tIds
   sort lines of tIds numeric
   repeat for each line tId in tIds
      if tUsed[tId] is true then next repeat
      repeat with tSlot = 1 to kMaxFx
         if sSlotOf[tSlot] is empty then
            put tId into sSlotOf[tSlot]
            exit repeat
         end if
      end repeat
   end repeat
   put Emit.Shake() into tOff
   put item 1 of tOff into tDX
   put item 2 of tOff into tDY
   repeat with tSlot = 1 to kMaxFx
      drawSlot tSlot, tDX, tDY
   end repeat
   -- flash
   put Emit.Flash() into tFl
   set the itemDel to tab
   if item 1 of tFl > 0.02 then
      set the backgroundColor of sFlashG to Emit.RGB(item 2 of tFl)
      set the blendLevel of sFlashG to round(100 - item 1 of tFl * 70)
      set the visible of sFlashG to true
   else
      set the visible of sFlashG to false
   end if
   set the itemDel to comma
   unlock screen
   add the milliseconds - tStart to sLastMS
end Draw.Frame

private command drawSlot pSlot, pDX, pDY
   local tId, tF, tP, tG, tCore, tShow, tLayer, tW, tObj
   put sSlotOf[pSlot] into tId
   if tId is empty then
      repeat for each item tLayer in kLayers
         put sG[pSlot][tLayer] into tObj
         if the visible of tObj then set the visible of tObj to false
      end repeat
      exit drawSlot
   end if
   put sFx[tId] into tF
   put tF["p"] into tP
   if sSlotStyled[pSlot] is not tId then
      drawStyle pSlot, tP, tF["form"]
      put tId into sSlotStyled[pSlot]
   end if
   put tF["g"] into tG
   if pDX is not 0 or pDY is not 0 then
      repeat for each item tLayer in "core,back,fill,dots"
         if tG[tLayer] is not empty then put Emit.Offset(tG[tLayer], pDX, pDY) into tG[tLayer]
      end repeat
   end if
   -- flicker hides the lines for a frame
   put not (tP["flicker"] > 0 and Emit.Rnd() < tP["flicker"]) into tShow
   put tG["core"] into tCore
   drawSet sG[pSlot]["core"], tCore, tShow
   drawSet sG[pSlot]["glowW"], tCore, tShow and tP["glowLayers"] >= 1 and tP["glowWidth"] > 0
   drawSet sG[pSlot]["glowM"], tCore, tShow and tP["glowLayers"] >= 2 and tP["glowWidth"] > 0
   drawSet sG[pSlot]["back"], tG["back"], tShow
   drawSet sG[pSlot]["fill"], tG["fill"], true
   drawSet sG[pSlot]["dots"], tG["dots"], true
   -- fade the whole effect out at the end of its life
   put round((1 - emitFade(tF)) * 60) into tW
   if tF["held"] is not true then
      put sG[pSlot]["core"] into tObj
      set the blendLevel of tObj to tW
      put sG[pSlot]["back"] into tObj
      set the blendLevel of tObj to max(55, tW)
   end if
end drawSlot

private command drawSet pG, pPoints, pShow
   if pPoints is empty or not pShow then
      if the visible of pG then set the visible of pG to false
      exit drawSet
   end if
   set the points of pG to pPoints
   if not the visible of pG then set the visible of pG to true
end drawSet

private command drawStyle pSlot, pP, pForm
   local tCore, tGlow, tEdge, tS, tG
   put Emit.RGB(pP["colorCore"]) into tCore
   put Emit.RGB(pP["colorGlow"]) into tGlow
   put Emit.RGB(pP["colorEdge"]) into tEdge
   put sG[pSlot]["glowW"] into tG
   set the foregroundColor of tG to tGlow
   set the lineSize of tG to max(1, pP["glowWidth"])
   set the blendLevel of tG to pP["glowFade"]
   put sG[pSlot]["glowM"] into tG
   set the foregroundColor of tG to Emit.ColorMix(tGlow, tCore, 0.4)
   set the lineSize of tG to max(1, round(pP["glowWidth"] / 2))
   set the blendLevel of tG to max(0, pP["glowFade"] - 25)
   put sG[pSlot]["back"] into tG
   set the foregroundColor of tG to tGlow
   set the lineSize of tG to max(1, pP["coreWidth"] - 1)
   set the blendLevel of tG to 55
   put sG[pSlot]["fill"] into tG
   set the foregroundColor of tG to tEdge
   set the backgroundColor of tG to tEdge
   set the lineSize of tG to 0
   set the blendLevel of tG to pP["fillFade"]
   put sG[pSlot]["core"] into tG
   set the foregroundColor of tG to tCore
   set the lineSize of tG to pP["coreWidth"]
   set the blendLevel of tG to 0
   -- LiveCode's own glow only when asked (it is slow); off only where it was turned on
   if pP["realGlow"] is true then
      set the outerGlow["color"] of tG to tGlow
      set the outerGlow["size"] of tG to max(4, pP["glowWidth"])
      set the outerGlow["blendMode"] of tG to "normal"
      set the outerGlow["opacity"] of tG to 200
      put true into sGlowOn[pSlot]
   else if sGlowOn[pSlot] is true then
      set the outerGlow["opacity"] of tG to 0
      put false into sGlowOn[pSlot]
   end if
   put sG[pSlot]["dots"] into tG
   put pP["dotSize"] into tS
   set the foregroundColor of tG to tEdge
   set the backgroundColor of tG to tEdge
   set the hiliteColor of tG to tEdge
   set the lineSize of tG to 0
   set the markerPoints of tG to -tS & comma & -tS & cr & tS & comma & -tS & cr & tS & comma & tS & cr & -tS & comma & tS & cr & -tS & comma & -tS
   set the markerLineSize of tG to 1
   set the markerDrawn of tG to true
   set the markerFilled of tG to true
end drawStyle
