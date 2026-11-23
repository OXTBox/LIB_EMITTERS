script "lib_duel"
######################################################################################
## SPELL SPLAT  lib_duel  (LIB_EMITTERS step 6, Sunday, November 22, 2026, Claude Opus)
## PROMPT (cyan) and GLAZE (magenta) throw energy powers at each other: a food fight, nobody is
## hurt. A hit fills the splat meter; at 100 a figure is GLAZED (sits down covered in the mess)
## and loses the round; best of three. Shots of the two sides that meet in mid-air pop together.
## Each side casts from its LIB_POWERBAR bar (pages of powers on the same keys) and pays energy.
## Bots dodge (jump low shots, duck high ones), keep their distance and pick what they can pay.
##
## YOU (PROMPT, when set to "you"): A / D move, W jump, S duck, 1-6 cast, hold Shift / Ctrl for
## pages 2 / 3, Q / E flip pages, F casts the selected, R selects the next. Escape pauses.
## Space starts a new match when one is over.
##
## Called by energy_editor's stack script: Duel.Init (once), Duel.Build (makes card "Duel"),
## Duel.Open / Duel.Close (openCard / closeCard), Duel.Frame dt (every frame), Duel.Click name,
## Duel.TogglePause. Needs lib_emitters and LIB_POWERBAR's lib_powerbar in use.
## Library rule: no system messages in here. Plain LiveCode graphics (not Engine 1, not Engine 2).
######################################################################################

constant kL = 8
constant kT = 32
constant kR = 1192
constant kB = 556
constant kFigH = 130
constant kWho = "PROMPT,GLAZE"
constant kPrompt = "0,230,255"
constant kGlaze = "255,70,220"
constant kText = "220,220,224"
constant kDim = "140,140,152"
constant kPanel = "34,34,42"
constant kBorder = "70,70,86"
constant kInk = "124,255,124"

local sF, sFloorY, sRound, sState, sStateUntil, sPaused, sKeysWas, sT, sBanter, sGridPts, sFloorPts
local sBent, sBarAt, sEmitFolder, sBarFolder, sBarsReady, sFps, sFrames, sFpsAt, sWinner

-------------------------------------------------------------------- setting up

-- pEmitFolder = LIB_EMITTERS, pBarFolder = LIB_POWERBAR
command Duel.Init pEmitFolder, pBarFolder
   local tL, tText
   put pEmitFolder into sEmitFolder
   put pBarFolder into sBarFolder
   put empty into sBanter
   put duRead(pEmitFolder & "/powers/duel_banter.txt") into tText
   set the itemDel to tab
   repeat for each line tL in tText
      if tL is empty or char 1 of tL is "#" then next repeat
      put item 3 of tL & cr after sBanter[item 1 of tL][item 2 of tL]
   end repeat
   set the itemDel to comma
   put false into sBarsReady
end Duel.Init

private function duRead pPath
   if there is not a file pPath then return empty
   return textDecode(URL ("binfile:" & pPath), "UTF-8")
end duRead

private command duTemplate pType
   switch pType
      case "button"
         reset the templateButton
         set the style of the templateButton to "rectangle"
         set the opaque of the templateButton to true
         set the threeD of the templateButton to false
         set the showBorder of the templateButton to true
         set the borderColor of the templateButton to kBorder
         set the backgroundColor of the templateButton to kPanel
         set the foregroundColor of the templateButton to kText
         set the textColor of the templateButton to kText
         set the textSize of the templateButton to 11
         break
      case "field"
         reset the templateField
         set the opaque of the templateField to false
         set the showBorder of the templateField to false
         set the lockText of the templateField to true
         set the traversalOn of the templateField to false
         set the threeD of the templateField to false
         set the foregroundColor of the templateField to kText
         set the textColor of the templateField to kText
         set the backgroundColor of the templateField to kPanel
         set the textSize of the templateField to 11
         set the margins of the templateField to "2,3,2,0"
         break
      default
         reset the templateGraphic
         set the foregroundColor of the templateGraphic to kText
         set the backgroundColor of the templateGraphic to kPanel
         set the antialiased of the templateGraphic to true
   end switch
end duTemplate

private function duMake pType, pName, pRect, pGroup
   duTemplate pType
   switch pType
      case "button"
         create button pName
         break
      case "field"
         if pGroup is empty then
            create field pName
         else
            create field pName in group pGroup
         end if
         break
      default
         if pGroup is empty then
            create graphic pName
         else
            create graphic pName in group pGroup
         end if
   end switch
   set the rect of it to pRect
   return it
end duMake

-- makes the Duel card's controls (the card must be the current one)
command Duel.Build
   local tG, tF, tX, tY, tW, tPts, tL, i
   put kB - 36 into sFloorY
   get duMake("button", "Du_Back", "8,4,108,26")
   set the label of it to "< EDITOR"
   get duMake("button", "Du_PromptMode", "116,4,236,26")
   set the label of it to "PROMPT: bot"
   get duMake("button", "Du_GlazeMode", "244,4,364,26")
   set the label of it to "GLAZE: bot"
   set the enabled of it to false
   get duMake("button", "Du_New", "372,4,512,26")
   set the label of it to "NEW MATCH"
   put duMake("field", "Du_Info", "524,6,1192,26") into tF
   set the textColor of tF to kInk
   set the text of tF to "SPELL SPLAT"
   -- the stage
   create group "DuelStage"
   set the rect of it to kL, kT, kR, kB
   set the lockLoc of it to true
   set the showBorder of it to false
   set the margins of it to 0
   put duMake("graphic", "Du_Bg", kL & comma & kT & comma & kR & comma & kB, "DuelStage") into tG
   set the style of tG to "rectangle"
   set the filled of tG to true
   set the opaque of tG to true
   set the lineSize of tG to 0
   set the backgroundColor of tG to "6,8,14"
   repeat with tX = kL + 24 to kR - 24 step 48
      put empty into tL
      repeat with tY = kT + 8 to sFloorY step 24
         put tX & comma & tY & cr after tL
      end repeat
      delete the last char of tL
      put Emit.Join(tPts, tL) into tPts
   end repeat
   repeat with tY = kT + 24 to sFloorY - 24 step 48
      put empty into tL
      repeat with tX = kL + 8 to kR - 8 step 24
         put tX & comma & tY & cr after tL
      end repeat
      delete the last char of tL
      put Emit.Join(tPts, tL) into tPts
   end repeat
   put tPts into sGridPts
   put duMake("graphic", "Du_Grid", kL & comma & kT & comma & kR & comma & kB, "DuelStage") into tG
   set the style of tG to "polygon"
   set the filled of tG to false
   set the foregroundColor of tG to "26,32,46"
   set the points of tG to sGridPts
   put empty into tPts
   repeat with tX = kL to kR step 12
      put tX & comma & sFloorY & cr after tPts
   end repeat
   delete the last char of tPts
   put tPts into sFloorPts
   put duMake("graphic", "Du_Floor", kL & comma & kT & comma & kR & comma & kB, "DuelStage") into tG
   set the style of tG to "polygon"
   set the filled of tG to false
   set the lineSize of tG to 2
   set the foregroundColor of tG to "90,96,120"
   set the points of tG to sFloorPts
   repeat for each item tW in kWho
      put duMake("graphic", "Du_Fig_" & tW, kL & comma & kT & comma & kR & comma & kB, "DuelStage") into tG
      set the style of tG to "polygon"
      set the filled of tG to false
      set the lineSize of tG to 4
      set the capStyle of tG to "round"
      set the joinStyle of tG to "round"
      set the foregroundColor of tG to duColor(tW)
   end repeat
   -- meters, banter and the banner sit over the stage (made after it)
   repeat for each item tW in kWho
      if tW is "PROMPT" then
         put kL + 16 into tX
      else
         put kR - 16 - 300 into tX
      end if
      put duMake("field", "Du_Name_" & tW, tX & comma & (kT + 8) & comma & (tX + 200) & comma & (kT + 28)) into tF
      set the textColor of tF to duColor(tW)
      set the textStyle of tF to "bold"
      set the text of tF to tW
      put duMake("field", "Du_Wins_" & tW, (tX + 200) & comma & (kT + 8) & comma & (tX + 300) & comma & (kT + 28)) into tF
      set the textAlign of tF to "right"
      set the textColor of tF to kInk
      repeat for each item tL in "E,S"
         if tL is "S" then
            put kT + 44 into tY
         else
            put kT + 30 into tY
         end if
         put duMake("graphic", "Du_" & tL & "Back_" & tW, tX & comma & tY & comma & (tX + 300) & comma & (tY + 10)) into tG
         set the style of tG to "rectangle"
         set the filled of tG to true
         set the opaque of tG to true
         set the lineSize of tG to 1
         set the foregroundColor of tG to kBorder
         set the backgroundColor of tG to "20,20,26"
         put duMake("graphic", "Du_" & tL & "Bar_" & tW, tX & comma & tY & comma & (tX + 300) & comma & (tY + 10)) into tG
         set the style of tG to "rectangle"
         set the filled of tG to true
         set the opaque of tG to true
         set the lineSize of tG to 0
         if tL is "E" then
            set the backgroundColor of tG to "90,200,255"
         else
            set the backgroundColor of tG to "255,150,60"
         end if
      end repeat
      put duMake("field", "Du_Say_" & tW, "0,0,260,24") into tF
      set the textAlign of tF to "center"
      set the textSize of tF to 13
      set the textColor of tF to duColor(tW)
      set the visible of tF to false
   end repeat
   put duMake("field", "Du_Labels", (kL + 330) & comma & (kT + 28) & comma & (kL + 420) & comma & (kT + 58)) into tF
   set the textColor of tF to kDim
   set the textSize of tF to 9
   set the text of tF to "energy" & cr & "splat"
   put duMake("field", "Du_Banner", (kL + 300) & comma & (kT + 120) & comma & (kR - 300) & comma & (kT + 200)) into tF
   set the textAlign of tF to "center"
   set the textSize of tF to 34
   set the textStyle of tF to "bold"
   set the textColor of tF to kInk
   set the visible of tF to false
   put duMake("field", "Du_Help", "8,640,1192,712") into tF
   set the textColor of tF to kDim
   set the text of tF to "YOU (set PROMPT: you): A / D move, W jump, S duck, 1-6 cast, hold Shift / Ctrl for pages 2 / 3, Q / E flip pages, F casts the selected, R selects the next." & cr & "A hit fills the splat meter; at 100 that side is GLAZED and loses the round (best of three). Shots that meet in mid-air pop together. Escape pauses; Space starts a new match when one is over."
end Duel.Build

private function duColor pWho
   if pWho is "PROMPT" then return kPrompt
   return kGlaze
end duColor

private function duOther pWho
   if pWho is "PROMPT" then return "GLAZE"
   return "PROMPT"
end duOther

private function duBar pWho
   return pWho && "duel"
end duBar

-- the card opens: the effects pool moves here, the bars appear, a new match starts
command Duel.Open
   local tW, tThing, p, s
   -- after the library is reloaded, read the stage lines back from the card
   if sFloorY is not a number then put kB - 36 into sFloorY
   if sGridPts is empty then put the points of graphic "Du_Grid" into sGridPts
   if sFloorPts is empty then put the points of graphic "Du_Floor" into sFloorPts
   Emit.Clear
   Emit.ClearTargets
   Emit.SetStage kL, kT, kR, kB, sFloorY
   Draw.Begin "DuelStage"
   if sBarsReady is not true then
      get PowerBar.Load(duRead(sBarFolder & "/bars/PROMPT_duel.powerbar.txt"))
      get PowerBar.Load(duRead(sBarFolder & "/bars/GLAZE_duel.powerbar.txt"))
      put true into sBarsReady
   end if
   repeat for each item tW in kWho
      if not PowerBar.Exists(duBar(tW)) then
         PowerBar.New duBar(tW), 3, 6
      end if
      repeat with p = 1 to 3
         repeat with s = 1 to 6
            put PowerBar.Get(duBar(tW), p, s) into tThing
            if tThing is not empty and Power.Exists(tThing) then
               PowerBar.SetInfo duBar(tW), tThing, Power.Get(tThing, "glyph"), Power.Get(tThing, "cost"), Power.Get(tThing, "cooldown")
            end if
         end repeat
      end repeat
   end repeat
   PowerBar.Draw duBar("PROMPT"), kL + 8, kB + 6, 50
   PowerBar.Draw duBar("GLAZE"), kR - 8 - 6 * 54, kB + 6, 50
   if sF["PROMPT"]["bot"] is empty then put true into sF["PROMPT"]["bot"]
   put true into sF["GLAZE"]["bot"]
   put false into sPaused
   put 0 into sT
   Duel.NewMatch
end Duel.Open

command Duel.Close
   Emit.Clear
   Emit.ClearTargets
   Draw.End
   PowerBar.Remove duBar("PROMPT")
   PowerBar.Remove duBar("GLAZE")
end Duel.Close

command Duel.NewMatch
   put 0 into sF["PROMPT"]["wins"]
   put 0 into sF["GLAZE"]["wins"]
   put 0 into sRound
   Duel.NewRound
end Duel.NewMatch

command Duel.NewRound
   local tW
   add 1 to sRound
   Emit.Clear
   repeat for each item tW in kWho
      if tW is "PROMPT" then
         put kL + 300 into sF[tW]["x"]
         put 1 into sF[tW]["face"]
      else
         put kR - 300 into sF[tW]["x"]
         put -1 into sF[tW]["face"]
      end if
      put 100 into sF[tW]["energy"]
      put 0 into sF[tW]["splat"]
      put 0 into sF[tW]["lift"]
      put 0 into sF[tW]["vy"]
      put 0 into sF[tW]["crouch"]
      put 0 into sF[tW]["recoil"]
      put 0 into sF[tW]["kickV"]
      put empty into sF[tW]["castAt"]
      put 0 into sF[tW]["poseUntil"]
      put 0 into sF[tW]["think"]
      put 0 into sF[tW]["dodgeCool"]
      put empty into sF[tW]["seen"]
      put empty into sF[tW]["final"]
      put Fig.Pose("stand") into sF[tW]["angles"]
      put 0 into sF[tW]["walk"]
   end repeat
   put "play" into sState
   put empty into sWinner
   duBanner "ROUND" && sRound, 1.4
end Duel.NewRound

command Duel.TogglePause
   put not (sPaused is true) into sPaused
   if sPaused then
      duBanner "PAUSED  (Escape goes on)", 9999
   else
      duBanner empty, 0
   end if
end Duel.TogglePause

command Duel.Click pName
   local tWho
   switch pName
      case "Du_Back"
         go card "Editor"
         break
      case "Du_New"
         Duel.NewMatch
         break
      case "Du_PromptMode"
         put not (sF["PROMPT"]["bot"] is true) into sF["PROMPT"]["bot"]
         if sF["PROMPT"]["bot"] then
            set the label of button "Du_PromptMode" to "PROMPT: bot"
         else
            set the label of button "Du_PromptMode" to "PROMPT: you"
         end if
         break
   end switch
end Duel.Click

-------------------------------------------------------------------- every frame

command Duel.Frame pDT
   local tKeys, tW, tHits, tL, tTarget, tFrom, tPop, tNow
   if sPaused is true then put 0 into pDT
   add pDT to sT
   put keysDown() into tKeys
   -- Space starts a new match once one is over
   if sState is "matchEnd" and 32 is among the items of tKeys and not (32 is among the items of sKeysWas) then Duel.NewMatch
   repeat for each item tW in kWho
      duFighter tW, pDT, tKeys
   end repeat
   Emit.Step pDT
   -- shots that met in mid-air
   put Emit.Collide() into tPop
   if tPop is not empty then duSay item random(2) of kWho, "pop", 0.6
   -- hits
   put Emit.Hits() into tHits
   set the itemDel to tab
   repeat for each line tL in tHits
      put item 2 of tL into tTarget
      -- (the item delimiter is tab here: name the two, not kWho's items)
      if tTarget is not "PROMPT" and tTarget is not "GLAZE" then next repeat
      if sState is not "play" then next repeat
      put duOther(tTarget) into tFrom
      put min(100, sF[tTarget]["splat"] + item 4 of tL) into sF[tTarget]["splat"]
      put 0.3 into sF[tTarget]["recoil"]
      put sF[tFrom]["face"] * item 5 of tL * 0.8 into sF[tTarget]["kickV"]
      duSay tTarget, "hit", 0.25
      duSay tFrom, "land", 0.15
   end repeat
   set the itemDel to comma
   duRounds
   duDrawStage
   Draw.Frame
   -- the bars: cooldowns, a buffered press, the picture every 0.1 s
   repeat for each item tW in kWho
      get PowerBar.Step(duBar(tW), pDT, sF[tW]["energy"])
      if it is not empty then duCast tW, it
   end repeat
   put the milliseconds into tNow
   if tNow - sBarAt > 100 then
      put tNow into sBarAt
      repeat for each item tW in kWho
         PowerBar.Refresh duBar(tW), sF[tW]["energy"]
      end repeat
      duInfo
   end if
   add 1 to sFrames
   if tNow - sFpsAt >= 1000 then
      put sFrames into sFps
      put 0 into sFrames
      put tNow into sFpsAt
   end if
   put tKeys into sKeysWas
end Duel.Frame

-- one fighter: think or read keys, move, jump, cast, pose, and become a target
private command duFighter pW, pDT, pKeys
   local tE, tPose, tA, tPts, tFig, tForm, tId, tChest
   put duOther(pW) into tE
   if sState is "play" then
      put min(100, sF[pW]["energy"] + 12 * pDT) into sF[pW]["energy"]
      put false into sF[pW]["moving"]
      if sF[pW]["bot"] is true then
         duBot pW, pDT
      else
         duPlayer pW, pDT, pKeys
      end if
   end if
   -- jumping
   if sF[pW]["lift"] > 0 or sF[pW]["vy"] < 0 then
      add 1500 * pDT to sF[pW]["vy"]
      subtract sF[pW]["vy"] * pDT from sF[pW]["lift"]
      if sF[pW]["lift"] <= 0 then
         put 0 into sF[pW]["lift"]
         put 0 into sF[pW]["vy"]
      end if
   end if
   subtract pDT from sF[pW]["crouch"]
   subtract pDT from sF[pW]["recoil"]
   subtract pDT from sF[pW]["dodgeCool"]
   -- knocked back, then slowing down
   add sF[pW]["kickV"] * pDT to sF[pW]["x"]
   put sF[pW]["kickV"] * max(0, 1 - 5 * pDT) into sF[pW]["kickV"]
   put max(kL + 40, min(kR - 40, sF[pW]["x"])) into sF[pW]["x"]
   if pW is "PROMPT" then
      put min(sF[pW]["x"], sF[tE]["x"] - 140) into sF[pW]["x"]
   else
      put max(sF[pW]["x"], sF[tE]["x"] + 140) into sF[pW]["x"]
   end if
   -- the cast leaves the hand
   if sF[pW]["castAt"] is a number and sT >= sF[pW]["castAt"] and sState is "play" then
      put empty into sF[pW]["castAt"]
      put sT + 0.35 into sF[pW]["poseUntil"]
      put Emit.Target(tE) into tChest
      put Emit.Fire(sF[pW]["castPow"], sF[pW]["hand"], item 1 to 2 of tChest, pW, tE, false) into tId
   end if
   -- the pose
   if sF[pW]["final"] is not empty then
      put Fig.Pose(sF[pW]["final"]) into tPose
   else if sF[pW]["recoil"] > 0 then
      put Fig.Pose("recoil") into tPose
   else if sF[pW]["castAt"] is a number or sT < sF[pW]["poseUntil"] then
      put Power.Get(sF[pW]["castPow"], "form") into tForm
      if tForm is "beam" then
         put Fig.Pose("beam") into tPose
      else
         put Fig.Pose("cast") into tPose
      end if
   else if sF[pW]["lift"] > 0 then
      put Fig.Pose("jump") into tPose
   else if sF[pW]["crouch"] > 0 then
      put Fig.Pose("dodge") into tPose
   else if sF[pW]["moving"] is true then
      add pDT * 1.6 to sF[pW]["walk"]
      put Fig.Walk(sF[pW]["walk"]) into tPose
   else
      put Fig.Pose("stand") into tPose
   end if
   put Fig.Lerp(sF[pW]["angles"], tPose, min(1, pDT * 14)) into sF[pW]["angles"]
   put Fig.Points(sF[pW]["angles"], sF[pW]["x"], sFloorY, kFigH, sF[pW]["face"], sF[pW]["lift"]) into tFig
   put tFig["hand"] into sF[pW]["hand"]
   put tFig["top"] into sF[pW]["top"]
   put tFig["pts"] into sF[pW]["pts"]
   put tFig["chest"] into tChest
   Emit.SetTarget pW, item 1 of tChest, item 2 of tChest, round(kFigH * 0.26), tFig["pts"]
end duFighter

-- start a cast: pay, wind up; the power leaves the hand after its cast time
private command duCast pW, pThing
   local tCost
   if pThing is empty or not Power.Exists(pThing) then exit duCast
   if sF[pW]["castAt"] is a number or sState is not "play" then exit duCast
   put Power.Get(pThing, "cost") into tCost
   if sF[pW]["energy"] < tCost then exit duCast
   subtract tCost from sF[pW]["energy"]
   put pThing into sF[pW]["castPow"]
   put sT + Power.Get(pThing, "castTime") into sF[pW]["castAt"]
   duSay pW, "cast", 0.3
end duCast

-- the player's keys (keysDown codes; a press = down now, not down last frame)
private command duPlayer pW, pDT, pKeys
   local tBar, i, tCode, tThing, tE
   put duBar(pW) into tBar
   put sF[pW]["energy"] into tE
   if 97 is among the items of pKeys or 65 is among the items of pKeys then
      subtract 180 * pDT from sF[pW]["x"]
      put true into sF[pW]["moving"]
   end if
   if 100 is among the items of pKeys or 68 is among the items of pKeys then
      add 180 * pDT to sF[pW]["x"]
      put true into sF[pW]["moving"]
   end if
   if duPressed(119, pKeys) or duPressed(87, pKeys) then duJump pW
   if 115 is among the items of pKeys or 83 is among the items of pKeys then put 0.1 into sF[pW]["crouch"]
   -- page holds: Shift = page 2, Control = page 3
   get PowerBar.Action(tBar, "page_hold_2", duAny("65505,65506", pKeys), tE)
   get PowerBar.Action(tBar, "page_hold_3", duAny("65507,65508", pKeys), tE)
   if duPressed(113, pKeys) then get PowerBar.Action(tBar, "page_prev", true, tE)
   if duPressed(101, pKeys) then get PowerBar.Action(tBar, "page_next", true, tE)
   if duPressed(114, pKeys) then get PowerBar.Action(tBar, "power_next", true, tE)
   if duPressed(102, pKeys) then
      put PowerBar.Action(tBar, "power_fire", true, tE) into tThing
      duCast pW, tThing
   end if
   -- 1-6 (and their shifted signs, ! @ # $ % ^)
   repeat with i = 1 to 6
      if duPressed(48 + i, pKeys) or duPressed(item i of "33,64,35,36,37,94", pKeys) then
         put PowerBar.Action(tBar, "slot_" & i, true, tE) into tThing
         duCast pW, tThing
      end if
   end repeat
end duPlayer

private function duPressed pCode, pKeys
   return pCode is among the items of pKeys and not (pCode is among the items of sKeysWas)
end duPressed

private function duAny pCodes, pKeys
   local tC
   repeat for each item tC in pCodes
      if tC is among the items of pKeys then return true
   end repeat
   return false
end duAny

private command duJump pW
   if sF[pW]["lift"] <= 0 and sF[pW]["vy"] >= 0 then put -620 into sF[pW]["vy"]
end duJump

-- the bot: dodge what comes, keep its distance, cast what it can pay for
private command duBot pW, pDT
   local tE, tId, tX, tVX, tDist, tChest, tBar, p, s, tThing, tReady, tN, tPick, tForm, tReach
   put duOther(pW) into tE
   put Emit.Target(pW) into tChest
   -- dodge: each incoming shot is judged once; three in four are dodged
   repeat for each line tId in Emit.Ids()
      if Emit.Info(tId, "owner") is not tE then next repeat
      if Emit.Info(tId, "form") is not among the items of "bit,ball" then next repeat
      if Emit.Info(tId, "done") is true or Emit.Info(tId, "charging") is true then next repeat
      if tId is among the items of sF[pW]["seen"] then next repeat
      put Emit.Info(tId, "x") into tX
      put abs(tX - sF[pW]["x"]) into tDist
      if tDist > 240 then next repeat
      put comma & tId after sF[pW]["seen"]
      if random(4) = 1 or sF[pW]["dodgeCool"] > 0 then next repeat
      put 0.6 into sF[pW]["dodgeCool"]
      if Emit.Info(tId, "y") >= item 2 of tChest - 12 then
         duJump pW
      else
         put 0.55 into sF[pW]["crouch"]
      end if
      duSay pW, "dodge", 0.3
   end repeat
   -- distance: not too near, not too far
   put abs(sF[tE]["x"] - sF[pW]["x"]) into tDist
   if tDist < 420 then
      subtract sF[pW]["face"] * 110 * pDT from sF[pW]["x"]
      put true into sF[pW]["moving"]
   else if tDist > 700 then
      add sF[pW]["face"] * 110 * pDT to sF[pW]["x"]
      put true into sF[pW]["moving"]
   end if
   -- think now and then
   if sT < sF[pW]["think"] or sF[pW]["castAt"] is a number then exit duBot
   put sT + 0.45 + random(80) / 100 into sF[pW]["think"]
   put duBar(pW) into tBar
   put 0 into tN
   repeat with p = 1 to 3
      repeat with s = 1 to 6
         if not PowerBar.Ready(tBar, p, s, sF[pW]["energy"]) then next repeat
         put PowerBar.Get(tBar, p, s) into tThing
         put Power.Get(tThing, "form") into tForm
         -- touch and short powers only when near enough
         if tForm is "shock" or tForm is "blast" then
            put Power.Get(tThing, "reach") into tReach
            if tDist > tReach + 60 then next repeat
         end if
         add 1 to tN
         put p & comma & s into tReady[tN]
      end repeat
   end repeat
   if tN = 0 then exit duBot
   put tReady[random(tN)] into tPick
   PowerBar.ShowPage tBar, item 1 of tPick
   PowerBar.Select tBar, item 2 of tPick
   put PowerBar.Fire(tBar, sF[pW]["energy"]) into tThing
   duCast pW, tThing
end duBot

-- glazed? the round (and maybe the match) ends; the next starts after a pause
private command duRounds
   local tW, tLoser
   if sState is "play" then
      repeat for each item tW in kWho
         if sF[tW]["splat"] >= 100 then put tW into tLoser
      end repeat
      if tLoser is empty then exit duRounds
      put duOther(tLoser) into sWinner
      add 1 to sF[sWinner]["wins"]
      put "splat" into sF[tLoser]["final"]
      put "cheer" into sF[sWinner]["final"]
      put empty into sF[tLoser]["castAt"]
      put empty into sF[sWinner]["castAt"]
      duSay tLoser, "glazed", 1
      if sF[sWinner]["wins"] >= 2 then
         put "matchEnd" into sState
         put sT + 7 into sStateUntil
         duBanner sWinner && "WINS THE MATCH!" & cr & "Space: new match", 7
         duSay sWinner, "win", 1
      else
         put "roundEnd" into sState
         put sT + 3 into sStateUntil
         duBanner tLoser && "IS GLAZED!", 2.5
      end if
      exit duRounds
   end if
   if sState is "roundEnd" and sT >= sStateUntil then Duel.NewRound
   -- two bots play on by themselves
   if sState is "matchEnd" and sT >= sStateUntil and sF["PROMPT"]["bot"] is true then Duel.NewMatch
end duRounds

-------------------------------------------------------------------- drawing

private command duDrawStage
   local tW, tHead, tSay, tX
   repeat for each item tW in kWho
      set the points of graphic ("Du_Fig_" & tW) to Emit.Bend(sF[tW]["pts"], "figures")
      put kL + 16 into tX
      if tW is "GLAZE" then put kR - 16 - 300 into tX
      set the rect of graphic ("Du_EBar_" & tW) to tX, kT + 30, tX + max(1, round(3 * sF[tW]["energy"])), kT + 40
      set the rect of graphic ("Du_SBar_" & tW) to tX, kT + 44, tX + max(1, round(3 * sF[tW]["splat"])), kT + 54
      set the text of field ("Du_Wins_" & tW) to "rounds" && sF[tW]["wins"]
      if sF[tW]["sayUntil"] is a number and sT < sF[tW]["sayUntil"] then
         put sF[tW]["top"] into tHead
         set the loc of field ("Du_Say_" & tW) to item 1 of tHead, item 2 of tHead - 22
         set the visible of field ("Du_Say_" & tW) to true
      else
         set the visible of field ("Du_Say_" & tW) to false
      end if
   end repeat
   if Emit.Sources() is not empty then
      set the points of graphic "Du_Floor" to Emit.Bend(sFloorPts, "floor")
      set the points of graphic "Du_Grid" to Emit.Bend(sGridPts, "grid")
      put true into sBent
   else if sBent is true then
      set the points of graphic "Du_Floor" to sFloorPts
      set the points of graphic "Du_Grid" to sGridPts
      put false into sBent
   end if
   if sF["banner"] is a number and sT >= sF["banner"] then
      set the visible of field "Du_Banner" to false
      put empty into sF["banner"]
   end if
end duDrawStage

private command duInfo
   local tC
   put Emit.Counts() into tC
   set the text of field "Du_Info" to "SPELL SPLAT   round" && sRound & "   PROMPT" && sF["PROMPT"]["wins"] && "-" && sF["GLAZE"]["wins"] && "GLAZE      fx" && item 1 of tC & "  dots" && item 2 of tC & "  ms" && item 4 of tC & "  fps" && sFps
end duInfo

private command duBanner pText, pSecs
   if pText is empty then
      set the visible of field "Du_Banner" to false
      put empty into sF["banner"]
      exit duBanner
   end if
   set the text of field "Du_Banner" to pText
   set the visible of field "Du_Banner" to true
   put sT + pSecs into sF["banner"]
end duBanner

-- a line from duel_banter.txt over the head, now and then (pChance 0..1)
private command duSay pW, pMoment, pChance
   local tLines, tN
   if random(100) > pChance * 100 then exit duSay
   put sBanter[pW][pMoment] into tLines
   put the number of lines of tLines into tN
   if tN = 0 then exit duSay
   set the text of field ("Du_Say_" & pW) to line random(tN) of tLines
   put sT + 1.6 into sF[pW]["sayUntil"]
end duSay
