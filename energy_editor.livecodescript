script "energy_editor"
######################################################################################
## ENERGY EDITOR  (LIB_EMITTERS, Sunday, November 22, 2026, Claude Opus, from the owner's note)
## Try energy weapons on two stick figures: PROMPT (cyan) casts, a GLAZE dummy (magenta) takes it.
## A power = an ELEMENT (the look) doing a FORM (the shape and motion); every number is a slider.
## COST and COOLDOWN of every power sit in the strip at the top right and in the cost table
## under the stage (owner, 22 Nov: "best for developers same UI").
##
## KEYS   Space fire (hold: beams last, balls charge)   Enter loop   . one frame (paused)
##        1-9 pick a power   M mutate (shift: big)   D new seed   A / B snapshots   Tab next tab
##        H help   Escape pause   ` command line
## MOUSE  click the stage = fire at that spot; click a row's name = back to the element/form value
## NEEDS  livecode/lib_emitters.livecodescript (beside this file); LIB_DATA if found (saves go to
##        Documents/Data/Emitters/Powers), else LIB_EMITTERS/powers/user
## ENGINE plain LiveCode graphics on a card: NOT Vibecode3D (Engine 1), NOT xRay (Engine 2)
######################################################################################

constant kW = 1200
constant kH = 720
constant kStageL = 236
constant kStageT = 30
constant kStageW = 640
constant kStageH = 420
constant kFigH = 110
constant kTabs = "LOOK,SHAPE,BALL,MOTION,DOTS,BEND,HIT"
constant kBg = "15,9,21"
constant kPanel = "34,34,42"
constant kText = "220,220,224"
constant kDim = "140,140,152"
constant kAccent = "64,224,255"
constant kBorder = "70,70,86"
constant kInk = "124,255,124"
constant kStage = "6,8,14"
constant kGrid = "26,32,46"
constant kFloor = "90,96,120"
constant kPrompt = "0,230,255"
constant kGlaze = "255,70,220"
constant kMenuText = "20,20,24"
constant kMenuFace = "196,200,208"

local sPower, sTab, sLoop, sPaused, sSlow, sLastMS, sT, sFrames, sFpsAt, sFps
local sUserFolder, sLocks, sSnapA, sSnapB, sShowing, sPopupFor, sCmdOn, sHelpOn
local sCasterX, sDummyHome, sDummyX, sDummyMode, sDummyKick, sDummyRecoil, sFloorY
local sCasterA, sCasterPose, sPoseUntil, sCastAt, sCastTo, sCastHeld, sHeld, sSpaceDown
local sLoopWait, sStepOnce, sGridPts, sFloorPts, sBent, sEscMS, sBudgetAt, sDistance, sBuilt

-------------------------------------------------------------------- open and close

on preOpenStack
   local tLib
   set the title of me to "FOR OWNER | Space fires, 1-9 picks a power, H for help"
   set the rect of me to 200, 32, 200 + kW, 32 + kH
   set the backgroundColor of me to kBg
   put Ed.Folder() & "/livecode/lib_emitters.livecodescript" into tLib
   if there is not a file tLib then
      answer "Not found:" && tLib
      exit preOpenStack
   end if
   start using stack tLib
   Ed.UseData
   Emit.LoadAll sUserFolder
   if sBuilt is not true then Ed.Build
   put true into sBuilt
   go card "Editor"
   -- openCard may come with messages locked (opened from a script): start the frames anyway
   send "Ed.StartTick" to me in 50 milliseconds
end preOpenStack

on closeStackRequest
   Ed.StopTick
   Draw.End
   set the destroyStack of me to true
   close stack (the mainStack of me)
end closeStackRequest

on openCard
   if the short name of the target is "Editor" then
      Ed.StartTick
   end if
   pass openCard
end openCard

on closeCard
   if the short name of the target is "Editor" then Ed.StopTick
   pass closeCard
end closeCard

-- the folder this file is in (LIB_EMITTERS)
function Ed.Folder
   local tF
   put the effective filename of me into tF
   set the itemDel to "/"
   delete the last item of tF
   set the itemDel to comma
   return tF
end Ed.Folder

-- saves go to the Data folder through LIB_DATA when it is there (rule 12), else powers/user
command Ed.UseData
   local tData, tF
   put Ed.Folder() into tF
   set the itemDel to "/"
   delete the last item of tF
   set the itemDel to comma
   put tF & "/LIB_DATA/livecode/lib_data.livecodescript" into tData
   put empty into sUserFolder
   if there is a file tData then
      try
         start using stack tData
         put Data.Folder("Emitters", "Powers") into sUserFolder
      catch tErr
         put empty into sUserFolder
      end try
   end if
   if sUserFolder is empty then
      put Ed.Folder() & "/powers/user" into sUserFolder
      if there is not a folder sUserFolder then create folder sUserFolder
   end if
end Ed.UseData

-------------------------------------------------------------------- building the window

-- colour a template before every create (the owner's rule)
command Ed.Template pType
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
         set the hiliteColor of the templateButton to "60,100,160"
         set the textSize of the templateButton to 11
         break
      case "field"
         reset the templateField
         set the opaque of the templateField to true
         set the threeD of the templateField to false
         set the showBorder of the templateField to true
         set the borderColor of the templateField to kBorder
         set the backgroundColor of the templateField to "22,22,28"
         set the foregroundColor of the templateField to kText
         set the textColor of the templateField to kText
         set the textSize of the templateField to 11
         set the margins of the templateField to "4,3,2,0"
         set the traversalOn of the templateField to true
         break
      case "graphic"
         reset the templateGraphic
         set the foregroundColor of the templateGraphic to kText
         set the backgroundColor of the templateGraphic to kPanel
         set the borderColor of the templateGraphic to kBorder
         set the antialiased of the templateGraphic to true
         break
      case "scrollbar"
         reset the templateScrollbar
         set the style of the templateScrollbar to "scale"
         set the showValue of the templateScrollbar to false
         set the startValue of the templateScrollbar to 0
         set the endValue of the templateScrollbar to 1000
         set the backgroundColor of the templateScrollbar to kPanel
         set the foregroundColor of the templateScrollbar to kAccent
         break
   end switch
end Ed.Template

function Ed.Make pType, pName, pRect, pGroup
   Ed.Template pType
   switch pType
      case "button"
         if pGroup is empty then
            create button pName
         else
            create button pName in group pGroup
         end if
         break
      case "field"
         if pGroup is empty then
            create field pName
         else
            create field pName in group pGroup
         end if
         break
      case "scrollbar"
         if pGroup is empty then
            create scrollbar pName
         else
            create scrollbar pName in group pGroup
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
end Ed.Make

function Ed.Label pName, pText, pRect, pGroup, pColor
   local tF
   put Ed.Make("field", pName, pRect, pGroup) into tF
   set the lockText of tF to true
   set the opaque of tF to false
   set the showBorder of tF to false
   set the traversalOn of tF to false
   set the margins of tF to "2,3,2,0"
   set the bottom of tF to the bottom of tF + 4
   if pColor is not empty then set the textColor of tF to pColor
   set the text of tF to pText
   return tF
end Ed.Label

function Ed.Button pName, pLabel, pRect, pGroup
   local tB
   put Ed.Make("button", pName, pRect, pGroup) into tB
   set the label of tB to pLabel
   return tB
end Ed.Button

command Ed.Build
   local tC, tB, tF, tG, tX, i, tName
   lock screen
   lock messages
   set the name of card 1 to "Developer"
   create card "Editor"
   create card "Duel"
   create card "About"
   go card "Editor"
   set the backgroundColor of this card to kBg
   -- menu bar: green titles (graphics) + one popup button for every menu
   put Ed.Make("graphic", "MenuBar", 0 & comma & 0 & comma & kW & comma & 24) into tG
   set the style of tG to "rectangle"
   set the opaque of tG to true
   set the filled of tG to true
   set the backgroundColor of tG to "10,14,12"
   set the lineSize of tG to 0
   put 8 into tX
   repeat for each item tName in "Power,Element,Form,View,Help"
      put Ed.Make("graphic", "Menu_" & tName, tX & ",2," & (tX + 70) & ",22") into tG
      set the style of tG to "rectangle"
      set the opaque of tG to false
      set the filled of tG to false
      set the lineSize of tG to 0
      set the showName of tG to true
      set the label of tG to tName
      set the textColor of tG to kInk
      set the foregroundColor of tG to kInk
      set the textSize of tG to 12
      add 74 to tX
   end repeat
   put Ed.Label("Banner", "ENERGY EDITOR", (kW - 300) & ",3," & (kW - 8) & ",22", empty, kDim) into tF
   set the textAlign of tF to "right"
   Ed.Template "button"
   create button "EdPopup"
   set the style of it to "menu"
   set the menuMode of it to "popup"
   set the textColor of it to kMenuText
   set the backgroundColor of it to kMenuFace
   set the visible of it to false
   -- left: the powers
   get Ed.Label("PowersTitle", "POWERS", "8,30,228,48", empty, kAccent)
   put Ed.Make("field", "PowerList", "8,50,228,520") into tF
   set the listBehavior of tF to true
   set the lockText of tF to true
   set the dontWrap of tF to true
   set the vScrollbar of tF to true
   set the hiliteColor of tF to "60,100,160"
   get Ed.Button("Btn_New", "New", "8,528,78,550")
   get Ed.Button("Btn_Copy", "Copy", "82,528,152,550")
   get Ed.Button("Btn_Delete", "Delete", "156,528,228,550")
   get Ed.Button("Btn_Rename", "Rename", "8,556,110,578")
   get Ed.Button("Btn_Save", "Save", "114,556,228,578")
   put Ed.Make("field", "CmdLine", "8,604,228,626") into tF
   set the visible of tF to false
   set the toolTip of tF to "command line: type xTalk, press Return (backquote hides it)"
   -- the stage
   Ed.BuildStage
   -- under the stage
   put kStageT + kStageH + 6 into tC
   get Ed.Button("Btn_Fire", "FIRE (Space)", kStageL & comma & tC & comma & (kStageL + 96) & comma & (tC + 22))
   get Ed.Button("Btn_Loop", "LOOP: off", (kStageL + 100) & comma & tC & comma & (kStageL + 180) & comma & (tC + 22))
   get Ed.Button("Btn_Step", "STEP (.)", (kStageL + 184) & comma & tC & comma & (kStageL + 250) & comma & (tC + 22))
   get Ed.Button("Btn_Clear", "CLEAR", (kStageL + 254) & comma & tC & comma & (kStageL + 314) & comma & (tC + 22))
   get Ed.Button("Btn_Dummy", "DUMMY: stand", (kStageL + 318) & comma & tC & comma & (kStageL + 420) & comma & (tC + 22))
   get Ed.Label("SlowLabel", "SPEED", (kStageL + 428) & comma & (tC + 3) & comma & (kStageL + 470) & comma & (tC + 21), empty, kDim)
   put Ed.Make("scrollbar", "Slow", (kStageL + 470) & comma & tC & comma & (kStageL + 640) & comma & (tC + 22)) into tB
   set the startValue of tB to 10
   set the endValue of tB to 100
   set the thumbPosition of tB to 100
   add 26 to tC
   get Ed.Label("DistLabel", "DUMMY AT", kStageL & comma & (tC + 3) & comma & (kStageL + 64) & comma & (tC + 21), empty, kDim)
   put Ed.Make("scrollbar", "Distance", (kStageL + 64) & comma & tC & comma & (kStageL + 300) & comma & (tC + 22)) into tB
   set the startValue of tB to 60
   set the endValue of tB to 470
   set the thumbPosition of tB to 340
   put Ed.Label("Budget", "", (kStageL + 306) & comma & (tC + 3) & comma & (kStageL + kStageW) & comma & (tC + 21), empty, kDim) into tF
   set the textAlign of tF to "right"
   -- the cost table: every power's cost, cooldown and cast time, typed straight in
   add 28 to tC
   put Ed.Label("CostHead", "COST TABLE" & tab & "element" & tab & "form" & tab & "cost" & tab & "cooldown" & tab & "cast   (type a number, click away)", kStageL & comma & tC & comma & (kStageL + kStageW) & comma & (tC + 18), empty, kAccent) into tF
   set the tabStops of tF to "150,230,300,370,450"
   put Ed.Make("field", "CostTable", kStageL & comma & (tC + 18) & comma & (kStageL + kStageW) & comma & 640) into tF
   set the tabStops of tF to "150,230,300,370,450"
   set the vScrollbar of tF to true
   set the dontWrap of tF to true
   -- right: element, form, the game strip, the tabs
   Ed.BuildRight
   -- bottom bar
   get Ed.Label("SeedLabel", "SEED", "8,650,44,668", empty, kDim)
   put Ed.Make("field", "N_seed", "46,648,150,670") into tF
   get Ed.Button("Btn_Dice", "New seed (D)", "154,648,250,670")
   get Ed.Button("Btn_Mutate", "Mutate (M)", "254,648,340,670")
   get Ed.Button("Btn_MutateBig", "Big mutate", "344,648,430,670")
   get Ed.Button("Btn_SnapA", "Keep as A", "440,648,520,670")
   get Ed.Button("Btn_SnapB", "Keep as B", "524,648,604,670")
   get Ed.Button("Btn_Swap", "Show A / B", "608,648,700,670")
   get Ed.Button("Btn_Revert", "Revert", "704,648,780,670")
   get Ed.Button("Btn_Export", "Copy text", "784,648,876,670")
   put Ed.Label("Status", "", "8,678," & (kW - 8) & ",700", empty, kText) into tF
   -- help and pause notes over the stage
   put Ed.Make("field", "Help", (kStageL + 40) & comma & (kStageT + 30) & comma & (kStageL + kStageW - 40) & comma & (kStageT + kStageH - 30)) into tF
   set the lockText of tF to true
   set the backgroundColor of tF to "12,12,20"
   set the text of tF to Ed.HelpText()
   set the visible of tF to false
   put Ed.Label("PauseNote", "PAUSED   Escape goes on   . steps one frame", (kStageL + 160) & comma & (kStageT + 8) & comma & (kStageL + 480) & comma & (kStageT + 26), empty, kInk) into tF
   set the textAlign of tF to "center"
   set the visible of tF to false
   Ed.BuildOtherCards
   go card "Editor"
   unlock messages
   -- the effects pool sits in the stage group, over the figures
   Draw.Begin "Stage"
   put "LOOK" into sTab
   Ed.ShowTab "LOOK"
   Ed.FillList
   if Power.Exists("fire ball") then
      Ed.Select "fire ball"
   else
      Ed.Select line 1 of Power.List()
   end if
   unlock screen
   Ed.Status "Ready. Space fires" && sPower & ". Saves go to" && sUserFolder
end Ed.Build

command Ed.BuildStage
   local tG, tR, i, tX, tY, tPts, tL
   put kStageL & comma & kStageT & comma & (kStageL + kStageW) & comma & (kStageT + kStageH) into tR
   create group "Stage"
   set the rect of it to tR
   set the lockLoc of it to true
   set the showBorder of it to false
   set the margins of it to 0
   put Ed.Make("graphic", "StageBg", tR, "Stage") into tG
   set the style of tG to "rectangle"
   set the opaque of tG to true
   set the filled of tG to true
   set the backgroundColor of tG to kStage
   set the lineSize of tG to 0
   put kStageT + kStageH - 40 into sFloorY
   put kStageL + 110 into sCasterX
   put 340 into sDistance
   put sCasterX + sDistance into sDummyHome
   put sDummyHome into sDummyX
   -- grid: every 40 px, each line in 20 px steps so it can bend
   repeat with tX = kStageL + 20 to kStageL + kStageW - 20 step 40
      put empty into tL
      repeat with tY = kStageT + 10 to sFloorY step 20
         put tX & comma & tY & cr after tL
      end repeat
      delete the last char of tL
      put Emit.Join(tPts, tL) into tPts
   end repeat
   repeat with tY = kStageT + 20 to sFloorY - 20 step 40
      put empty into tL
      repeat with tX = kStageL + 10 to kStageL + kStageW - 10 step 20
         put tX & comma & tY & cr after tL
      end repeat
      delete the last char of tL
      put Emit.Join(tPts, tL) into tPts
   end repeat
   put tPts into sGridPts
   put Ed.Make("graphic", "Grid", tR, "Stage") into tG
   set the style of tG to "polygon"
   set the filled of tG to false
   set the foregroundColor of tG to kGrid
   set the lineSize of tG to 1
   set the points of tG to sGridPts
   put empty into tPts
   repeat with tX = kStageL to kStageL + kStageW step 10
      put tX & comma & sFloorY & cr after tPts
   end repeat
   delete the last char of tPts
   put tPts into sFloorPts
   put Ed.Make("graphic", "Floor", tR, "Stage") into tG
   set the style of tG to "polygon"
   set the filled of tG to false
   set the foregroundColor of tG to kFloor
   set the lineSize of tG to 2
   set the points of tG to sFloorPts
   -- three posts for chains to jump to
   repeat with i = 1 to 3
      put Ed.Make("graphic", "Post" & i, tR, "Stage") into tG
      set the style of tG to "polygon"
      set the filled of tG to false
      set the foregroundColor of tG to "110,110,130"
      set the lineSize of tG to 3
   end repeat
   Ed.PlacePosts
   -- the figures
   put Ed.Make("graphic", "CasterFig", tR, "Stage") into tG
   set the style of tG to "polygon"
   set the filled of tG to false
   set the foregroundColor of tG to kPrompt
   set the lineSize of tG to 3
   set the capStyle of tG to "round"
   set the joinStyle of tG to "round"
   put Ed.Make("graphic", "DummyFig", tR, "Stage") into tG
   set the style of tG to "polygon"
   set the filled of tG to false
   set the foregroundColor of tG to kGlaze
   set the lineSize of tG to 3
   set the capStyle of tG to "round"
   set the joinStyle of tG to "round"
   put Ed.Label("CasterName", "PROMPT", (sCasterX - 40) & comma & (sFloorY + 6) & comma & (sCasterX + 40) & comma & (sFloorY + 24), "Stage", kPrompt) into tG
   set the textAlign of tG to "center"
   put Ed.Label("DummyName", "GLAZE", (sDummyX - 40) & comma & (sFloorY + 6) & comma & (sDummyX + 40) & comma & (sFloorY + 24), "Stage", kGlaze) into tG
   set the textAlign of tG to "center"
   put Fig.Pose("stand") into sCasterA
   put "stand" into sCasterPose
   put "stand" into sDummyMode
   put 0 into sDummyKick
   put 0 into sDummyRecoil
   Emit.SetStage kStageL, kStageT, kStageL + kStageW, kStageT + kStageH, sFloorY
end Ed.BuildStage

-- posts stand behind the dummy (chain lightning jumps along them); never between the two
-- figures, or every low shot would hit a post first
command Ed.PlacePosts
   local i, tX, tTop, tGap
   put max(14, min(50, (kStageL + kStageW - 16 - sDummyHome) / 3)) into tGap
   repeat with i = 1 to 3
      put min(kStageL + kStageW - 12, sDummyHome + tGap * i) into tX
      put sFloorY - 50 - i * 6 into tTop
      set the points of graphic ("Post" & i) to tX & comma & sFloorY & cr & tX & comma & tTop & cr & tX - 6 & comma & tTop & cr & tX + 6 & comma & tTop
      Emit.SetTarget "post" & i, tX, tTop, 12, tX & comma & tTop
   end repeat
end Ed.PlacePosts

command Ed.BuildRight
   local tX, tY, tB, tF, tTab, tK, tInfo, tKind, tLabel, tGroup, tName, i
   put 884 into tX
   get Ed.Label("ElemLabel", "ELEMENT", tX & ",30," & (tX + 70) & ",50", empty, kDim)
   get Ed.Button("B_element", "fire", (tX + 72) & ",28," & (kW - 8) & ",50")
   get Ed.Label("FormLabel", "FORM", tX & ",56," & (tX + 70) & ",76", empty, kDim)
   get Ed.Button("B_form", "ball", (tX + 72) & ",54," & (kW - 8) & ",76")
   -- the game strip: always on screen
   put Ed.Make("graphic", "GameStrip", tX & ",82," & (kW - 8) & ",132") into tB
   set the style of tB to "rectangle"
   set the opaque of tB to true
   set the filled of tB to true
   set the backgroundColor of tB to "28,40,34"
   set the lineSize of tB to 1
   set the foregroundColor of tB to kInk
   get Ed.Label("R_cost", "COST", (tX + 4) & ",86," & (tX + 74) & ",104", empty, kInk)
   get Ed.Make("field", "N_cost", (tX + 76) & ",84," & (tX + 130) & ",104")
   get Ed.Label("R_cooldown", "COOLDOWN s", (tX + 140) & ",86," & (tX + 240) & ",104", empty, kInk)
   get Ed.Make("field", "N_cooldown", (tX + 244) & ",84," & (kW - 12) & ",104")
   get Ed.Label("R_castTime", "CAST s", (tX + 4) & ",110," & (tX + 74) & ",128", empty, kInk)
   get Ed.Make("field", "N_castTime", (tX + 76) & ",108," & (tX + 130) & ",128")
   get Ed.Label("R_glyph", "GLYPH", (tX + 140) & ",110," & (tX + 240) & ",128", empty, kInk)
   get Ed.Make("field", "N_glyph", (tX + 244) & ",108," & (kW - 12) & ",128")
   -- tab strip
   put 0 into i
   repeat for each item tTab in kTabs
      put Ed.Make("graphic", "TabBtn_" & tTab, (tX + i * 44) & ",138," & (tX + i * 44 + 43) & ",158") into tB
      set the style of tB to "rectangle"
      set the opaque of tB to true
      set the filled of tB to true
      set the lineSize of tB to 1
      set the showName of tB to true
      set the label of tB to tTab
      set the textSize of tB to 10
      set the textColor of tB to kText
      add 1 to i
   end repeat
   -- one group of rows per tab
   repeat for each item tTab in kTabs
      put "Tab_" & tTab into tGroup
      create group tGroup
      set the showBorder of it to false
      set the margins of it to 0
      put 166 into tY
      repeat for each line tK in Emit.Keys(tTab)
         Ed.BuildRow tK, tY, tGroup
         add 22 to tY
      end repeat
   end repeat
end Ed.BuildRight

-- one parameter row: name | slider or swatch or list button or checkbox | number | lock
command Ed.BuildRow pKey, pY, pGroup
   local tInfo, tKind, tLabel, tF, tB, tX
   put 884 into tX
   put Emit.KeyInfo(pKey) into tInfo
   set the itemDel to tab
   put item 2 of tInfo into tKind
   put item 6 of tInfo into tLabel
   set the itemDel to comma
   put Ed.Label("R_" & pKey, tLabel, tX & comma & (pY + 2) & comma & (tX + 102) & comma & (pY + 20), pGroup, kText) into tF
   set the toolTip of tF to pKey & ": click to go back to the element / form value"
   if tKind is "num" or tKind is "int" then
      put Ed.Make("scrollbar", "S_" & pKey, (tX + 104) & comma & pY & comma & (tX + 226) & comma & (pY + 20), pGroup) into tB
      get Ed.Make("field", "N_" & pKey, (tX + 230) & comma & pY & comma & (tX + 278) & comma & (pY + 20), pGroup)
   else if tKind is "color" then
      put Ed.Make("graphic", "W_" & pKey, (tX + 104) & comma & (pY + 2) & comma & (tX + 226) & comma & (pY + 18), pGroup) into tB
      set the style of tB to "rectangle"
      set the opaque of tB to true
      set the filled of tB to true
      set the lineSize of tB to 1
      set the toolTip of tB to "click to pick a colour"
      get Ed.Make("field", "N_" & pKey, (tX + 230) & comma & pY & comma & (tX + 278) & comma & (pY + 20), pGroup)
      set the textSize of it to 9
   else if tKind is "bool" then
      put Ed.Make("button", "C_" & pKey, (tX + 104) & comma & pY & comma & (tX + 226) & comma & (pY + 20), pGroup) into tB
      set the style of tB to "checkbox"
      set the opaque of tB to false
      set the showBorder of tB to false
      set the label of tB to "on"
      set the rect of tB to (tX + 104) & comma & pY & comma & (tX + 226) & comma & (pY + 20)
   else
      -- lists and powers: a button that pops its choices
      get Ed.Button("B_" & pKey, "", (tX + 104) & comma & pY & comma & (tX + 278) & comma & (pY + 20), pGroup)
   end if
   if tKind is "num" or tKind is "int" or tKind is "color" then
      put Ed.Make("button", "K_" & pKey, (tX + 104) & comma & pY & comma & (tX + 226) & comma & (pY + 20), pGroup) into tB
      set the style of tB to "checkbox"
      set the opaque of tB to false
      set the showBorder of tB to false
      set the label of tB to empty
      set the toolTip of tB to "lock: Mutate leaves it alone"
      set the rect of tB to (tX + 282) & comma & pY & comma & (tX + 304) & comma & (pY + 20)
   end if
end Ed.BuildRow

command Ed.BuildOtherCards
   local tF
   go card "Developer"
   set the backgroundColor of this card to kBg
   go card "Duel"
   set the backgroundColor of this card to kBg
   put Ed.Label("DuelNote", "THE DUEL (step 6 of LIB_EMITTERS/PLAN.md): PROMPT and GLAZE throw powers at each other, a food fight with energy. Not built yet." & cr & cr & "Back to the editor: View menu > Editor, or press E.", "40,40,1160,200", empty, kText) into tF
   set the textSize of tF to 14
   go card "About"
   set the backgroundColor of this card to kBg
   put Ed.Label("AboutText", Ed.AboutText(), "40,30,1160,690", empty, kText) into tF
   set the textSize of tF to 13
   set the dontWrap of tF to false
end Ed.BuildOtherCards

function Ed.AboutText
   local tT
   put "Sunday, November 22, 2026" & cr after tT
   put "Stack name: energy_editor    Title: FOR OWNER | Space fires, 1-9 picks a power, H for help" & cr & cr after tT
   put "BUILT TO: try energy weapons drawn as lines made of math (lightning, fire, plasma, photon, sound and heat) on two stick figures, and tune every number of a power: its look, its shape, its vector ball, its motion, its dots, how it bends the lines around it, what it does to the target, and its cost and cooldown." & cr & cr after tT
   put "HOW:" & cr after tT
   put "  - Pick a power on the left (or keys 1-9). Space fires it at the GLAZE dummy; hold Space for beams and to charge balls." & cr after tT
   put "  - Click on the stage to fire at that spot. Enter repeats the power by itself (LOOP)." & cr after tT
   put "  - ELEMENT and FORM (top right) change what it is; the tabs hold every number. Click a row's name to undo your change to it." & cr after tT
   put "  - COST / COOLDOWN / CAST sit in the green strip; the cost table under the stage lists every power." & cr after tT
   put "  - M mutates the unlocked numbers, D gives a new seed (a new shape, same numbers), A / B keep two versions to compare." & cr after tT
   put "  - Save writes the power to your Data folder (Emitters/Powers); Revert reads it back." & cr after tT
   put "  - Escape pauses (period then steps one frame); backquote opens a command line; H shows the keys." & cr & cr after tT
   put "REPORT: was it fun, which powers look right, which look wrong? Write it in LIB_LLMIN/LIB_GAMES/GAME_NOTES.txt (or tell Claude). Nothing else is watching this window." after tT
   return tT
end Ed.AboutText

function Ed.HelpText
   return "KEYS" & cr & cr & "Space        fire (hold: beams last, balls charge)" & cr & "Enter        loop on / off" & cr & ".            one frame (when paused)" & cr & "1 - 9        pick a power" & cr & "M / shift-M  mutate a little / a lot" & cr & "D            new seed" & cr & "A / B        keep this version as A / B" & cr & "Tab          next tab" & cr & "Escape       pause" & cr & "`            command line" & cr & "H            this help" & cr & cr & "Click the stage to fire at a spot." & cr & "Click a row's name: back to the element / form value."
end Ed.HelpText

-------------------------------------------------------------------- showing a power

command Ed.FillList
   local tL, tOut, tN
   repeat for each line tN in Power.List()
      put tN & cr after tOut
   end repeat
   delete the last char of tOut
   set the text of field "PowerList" to tOut
   Ed.FillCostTable
end Ed.FillList

command Ed.FillCostTable
   local tOut, tN
   repeat for each line tN in Power.List()
      put tN & tab & Power.Get(tN, "element") & tab & Power.Get(tN, "form") & tab & Power.Get(tN, "cost") & tab & Power.Get(tN, "cooldown") & tab & Power.Get(tN, "castTime") & cr after tOut
   end repeat
   delete the last char of tOut
   set the text of field "CostTable" to tOut
end Ed.FillCostTable

command Ed.Select pName
   local tN
   if pName is empty or not Power.Exists(pName) then exit Ed.Select
   put pName into sPower
   set the wholeMatches to true
   put lineOffset(pName, the text of field "PowerList") into tN
   set the wholeMatches to false
   if tN > 0 then set the hilitedLine of field "PowerList" to tN
   put empty into sSnapA
   put empty into sSnapB
   Ed.ShowPower
   Ed.Status pName & ":" && Power.Get(pName, "element") && "+" && Power.Get(pName, "form") & ". Space fires."
end Ed.Select

command Ed.ShowPower
   local tK
   lock screen
   set the label of button "B_element" to Power.Get(sPower, "element")
   set the label of button "B_form" to Power.Get(sPower, "form")
   repeat for each line tK in Emit.Keys()
      Ed.ShowKey tK
   end repeat
   unlock screen
end Ed.ShowPower

command Ed.ShowKey pKey
   local tInfo, tKind, tMin, tMax, tV, tObj
   put Emit.KeyInfo(pKey) into tInfo
   set the itemDel to tab
   put item 2 of tInfo into tKind
   put item 3 of tInfo into tMin
   put item 4 of tInfo into tMax
   set the itemDel to comma
   put Power.Get(sPower, pKey) into tV
   if there is a field ("N_" & pKey) then set the text of field ("N_" & pKey) to tV
   if there is a scrollbar ("S_" & pKey) and tMax > tMin then
      set the thumbPosition of scrollbar ("S_" & pKey) to round((tV - tMin) / (tMax - tMin) * 1000)
   end if
   if there is a graphic ("W_" & pKey) then set the backgroundColor of graphic ("W_" & pKey) to Emit.RGB(tV)
   if there is a button ("B_" & pKey) then set the label of button ("B_" & pKey) to tV
   if there is a button ("C_" & pKey) then set the hilite of button ("C_" & pKey) to (tV is true)
   -- the power's own values are bold; the rest come from the element / form
   if there is a field ("R_" & pKey) then
      if Power.Own(sPower, pKey) then
         set the textStyle of field ("R_" & pKey) to "bold"
      else
         set the textStyle of field ("R_" & pKey) to "plain"
      end if
   end if
end Ed.ShowKey

command Ed.ShowTab pTab
   local tT
   put pTab into sTab
   lock screen
   repeat for each item tT in kTabs
      set the visible of group ("Tab_" & tT) to (tT is pTab)
      if tT is pTab then
         set the backgroundColor of graphic ("TabBtn_" & tT) to "60,100,160"
      else
         set the backgroundColor of graphic ("TabBtn_" & tT) to kPanel
      end if
   end repeat
   unlock screen
end Ed.ShowTab

command Ed.Set pKey, pValue
   Power.Set sPower, pKey, pValue
   Ed.ShowKey pKey
   if pKey is among the items of "cost,cooldown,castTime" then Ed.FillCostTable
end Ed.Set

command Ed.Status pText
   if there is a field ("Status") then set the text of field "Status" to pText
end Ed.Status

-------------------------------------------------------------------- the loop

command Ed.StartTick
   Ed.StopTick
   put the milliseconds into sLastMS
   if sT is not a number then put 0 into sT
   put 0 into sFrames
   put the milliseconds into sFpsAt
   send "Ed.Tick" to me in 16 milliseconds
end Ed.StartTick

command Ed.StopTick
   local tL
   repeat for each line tL in the pendingMessages
      if item 3 of tL is "Ed.Tick" then cancel item 1 of tL
   end repeat
end Ed.StopTick

on Ed.Tick
   local tNow, tDT, tC, tOld, tErr
   put the milliseconds into tNow
   put (tNow - sLastMS) / 1000 into tDT
   put tNow into sLastMS
   if tDT > 0.1 then put 0.1 into tDT
   if sSlow is not a number then put 1 into sSlow
   multiply tDT by sSlow
   if sPaused is true then
      if sStepOnce is true then
         put 1 / 30 into tDT
         put false into sStepOnce
      else
         put 0 into tDT
      end if
   end if
   put the defaultStack into tOld
   set the defaultStack to the short name of me
   if the short name of this card is "Editor" then
      try
         Ed.Frame tDT
      catch tErr
         Ed.Status "error in the frame:" && line 1 of tErr
      end try
   end if
   -- frames a second
   add 1 to sFrames
   if tNow - sFpsAt >= 1000 then
      put sFrames into sFps
      put 0 into sFrames
      put tNow into sFpsAt
   end if
   if tNow - sBudgetAt >= 250 and the short name of this card is "Editor" then
      put tNow into sBudgetAt
      Ed.ShowBudget
   end if
   set the defaultStack to tOld
   send "Ed.Tick" to me in 16 milliseconds
end Ed.Tick

command Ed.Frame pDT
   local tTo, tHits, tL, tFig, tA, tLift, tDummyA, tPhase, tChest, tId, tAlive, tPts
   add pDT to sT
   -- Space let go: beams end, charged balls fly
   if sSpaceDown is true and not (32 is among the items of keysDown()) then
      put false into sSpaceDown
      put false into sCastHeld
      if sHeld is not empty then
         Emit.Release sHeld
         put empty into sHeld
         put sT + 0.25 into sPoseUntil
      end if
   end if
   -- the dummy
   put 0 into tLift
   switch sDummyMode
      case "walk"
         put sDummyHome + sin(sT * 1.2) * 70 into sDummyX
         put Fig.Walk(sT * 0.9) into tDummyA
         break
      case "jump"
         put sDummyHome into sDummyX
         put max(0, sin(sT * 3)) * 70 into tLift
         if tLift > 2 then
            put Fig.Pose("jump") into tDummyA
         else
            put Fig.Pose("stand") into tDummyA
         end if
         break
      default
         put sDummyHome into sDummyX
         put Fig.Pose("stand") into tDummyA
   end switch
   if sDummyRecoil > 0 then
      subtract pDT from sDummyRecoil
      put Fig.Pose("recoil") into tDummyA
   end if
   put sDummyKick * max(0, 1 - pDT * 4) into sDummyKick
   put Fig.Points(tDummyA, min(kStageL + kStageW - 20, sDummyX + sDummyKick), sFloorY, kFigH, -1, tLift) into tFig
   put tFig["chest"] into tChest
   Emit.SetTarget "dummy", item 1 of tChest, item 2 of tChest, round(kFigH * 0.3), tFig["pts"]
   put Emit.Bend(tFig["pts"], "figures") into tPts
   set the points of graphic "DummyFig" to tPts
   -- the caster: wind up, cast, back to standing
   if sPoseUntil is a number and sT >= sPoseUntil and sHeld is empty and sCastAt is empty then
      put "stand" into sCasterPose
      put empty into sPoseUntil
   end if
   put Fig.Lerp(sCasterA, Fig.Pose(sCasterPose), min(1, pDT * 14)) into sCasterA
   put Fig.Points(sCasterA, sCasterX, sFloorY, kFigH, 1, 0) into tFig
   set the points of graphic "CasterFig" to Emit.Bend(tFig["pts"], "figures")
   if sCastAt is a number and sT >= sCastAt then
      put empty into sCastAt
      if sCastTo is empty then
         put tChest into tTo
      else
         put sCastTo into tTo
      end if
      put Emit.Fire(sPower, tFig["hand"], tTo, "caster", empty, sCastHeld) into tId
      if sCastHeld is true and tId is not empty then
         put tId into sHeld
      else
         put sT + 0.35 into sPoseUntil
      end if
   end if
   if sHeld is not empty then
      if Emit.Alive(sHeld) then
         Emit.Hold sHeld, tChest, tFig["hand"]
      else
         put empty into sHeld
         put sT + 0.25 into sPoseUntil
      end if
   end if
   -- the effects
   Emit.Step pDT
   put Emit.Hits() into tHits
   set the itemDel to tab
   repeat for each line tL in tHits
      if item 2 of tL is "dummy" then
         put 0.35 into sDummyRecoil
         put min(80, sDummyKick + item 5 of tL * 0.12) into sDummyKick
      end if
   end repeat
   set the itemDel to comma
   -- the stage's own lines bend
   if Emit.Sources() is not empty then
      set the points of graphic "Floor" to Emit.Bend(sFloorPts, "floor")
      set the points of graphic "Grid" to Emit.Bend(sGridPts, "grid")
      put true into sBent
   else if sBent is true then
      set the points of graphic "Floor" to sFloorPts
      set the points of graphic "Grid" to sGridPts
      put false into sBent
   end if
   Draw.Frame
   -- loop: fire again a moment after everything is gone (afterburns do not count)
   if sLoop is true and sCastAt is empty and sHeld is empty then
      put false into tAlive
      repeat for each line tId in Emit.Ids()
         if Emit.Info(tId, "form") is not "afterburn" then put true into tAlive
      end repeat
      if tAlive then
         put empty into sLoopWait
      else if sLoopWait is empty then
         put sT + 0.5 into sLoopWait
      else if sT >= sLoopWait then
         put empty into sLoopWait
         Ed.Fire empty, false
      end if
   end if
end Ed.Frame

command Ed.ShowBudget
   local tC, tText, tSize
   put Emit.Counts() into tC
   put "fx" && item 1 of tC & "  dots" && item 2 of tC & "  lines" && item 3 of tC & "  ms" && item 4 of tC & "  fps" && sFps into tText
   if Power.Get(sPower, "form") is among the items of "ball,bit" and Power.Get(sPower, "sphere") is not "orb" then
      put Emit.ModelSize(sPower) into tSize
      put "  ball" && item 1 of tSize & "v" && item 2 of tSize & "e" after tText
   end if
   set the text of field "Budget" to tText
   if item 4 of tC > 15 or item 3 of tC > 300 then
      set the textColor of field "Budget" to "255,90,90"
   else
      set the textColor of field "Budget" to kDim
   end if
end Ed.ShowBudget

-- start a cast: the wind-up pose, then the power leaves the hand after castTime
command Ed.Fire pTo, pHeld
   local tForm
   if sPower is empty or sCastAt is not empty or sHeld is not empty then exit Ed.Fire
   put Power.Get(sPower, "form") into tForm
   if tForm is "beam" then
      put "beam" into sCasterPose
   else if tForm is "ball" and Power.Get(sPower, "charge") > 0 and pHeld is true then
      put "charge" into sCasterPose
   else
      put "cast" into sCasterPose
   end if
   put (pHeld is true) and (tForm is "beam" or (tForm is "ball" and Power.Get(sPower, "charge") > 0)) into sCastHeld
   put pTo into sCastTo
   put sT + Power.Get(sPower, "castTime") into sCastAt
end Ed.Fire

-------------------------------------------------------------------- keys

function Ed.Typing
   local tT
   put the long id of the target into tT
   if word 1 of tT is "field" and the lockText of the target is false then return true
   return false
end Ed.Typing

on keyDown pKey
   if Ed.Typing() then pass keyDown
   if the short name of this card is not "Editor" then
      if pKey is "e" then go card "Editor"
      pass keyDown
   end if
   switch pKey
      case space
         if sSpaceDown is not true then
            put true into sSpaceDown
            Ed.Fire empty, true
         end if
         break
      case "."
         put true into sStepOnce
         break
      case "m"
         if the shiftKey is down then
            Ed.Mutate 0.35
         else
            Ed.Mutate 0.1
         end if
         break
      case "d"
         Ed.Dice
         break
      case "a"
         put Power.Array(sPower) into sSnapA
         Ed.Status "kept as A"
         break
      case "b"
         put Power.Array(sPower) into sSnapB
         Ed.Status "kept as B"
         break
      case "h"
         put not (sHelpOn is true) into sHelpOn
         set the visible of field "Help" to sHelpOn
         break
      case "`"
         Ed.ToggleCmd
         break
      default
         if pKey is an integer and pKey >= 1 and pKey <= 9 then
            Ed.Select line pKey of Power.List()
         else
            pass keyDown
         end if
   end switch
end keyDown

on returnKey
   if Ed.Typing() then pass returnKey
   Ed.ToggleLoop
end returnKey

on enterKey
   if Ed.Typing() then pass enterKey
   Ed.ToggleLoop
end enterKey

on tabKey
   if Ed.Typing() then pass tabKey
   set the itemDel to comma
   get itemOffset(sTab, kTabs)
   if it >= the number of items of kTabs then
      Ed.ShowTab item 1 of kTabs
   else
      Ed.ShowTab item (it + 1) of kTabs
   end if
end tabKey

on escapeKey
   -- debounced: one press, one change
   if sEscMS is a number and the milliseconds - sEscMS < 300 then exit escapeKey
   put the milliseconds into sEscMS
   put not (sPaused is true) into sPaused
   set the visible of field "PauseNote" to sPaused
   if sPaused then
      Ed.Status "Paused. Escape goes on, period steps one frame."
   else
      Ed.Status "Going on."
   end if
end escapeKey

command Ed.ToggleLoop
   put not (sLoop is true) into sLoop
   if sLoop then
      set the label of button "Btn_Loop" to "LOOP: on"
   else
      set the label of button "Btn_Loop" to "LOOP: off"
   end if
end Ed.ToggleLoop

command Ed.ToggleCmd
   put not (sCmdOn is true) into sCmdOn
   set the visible of field "CmdLine" to sCmdOn
   if sCmdOn then
      focus on field "CmdLine"
   else
      focus on nothing
   end if
end Ed.ToggleCmd

-------------------------------------------------------------------- mouse

on mouseUp pButton
   local tName, tKey
   put the short name of the target into tName
   if the short name of this card is not "Editor" then pass mouseUp
   if tName begins with "Menu_" then
      Ed.Menu char 6 to -1 of tName
      exit mouseUp
   end if
   if tName begins with "TabBtn_" then
      Ed.ShowTab char 8 to -1 of tName
      exit mouseUp
   end if
   if tName begins with "W_" then
      Ed.PickColor char 3 to -1 of tName
      exit mouseUp
   end if
   if tName begins with "B_" then
      Ed.PickList char 3 to -1 of tName
      exit mouseUp
   end if
   if tName begins with "R_" then
      put char 3 to -1 of tName into tKey
      Power.Unset sPower, tKey
      Ed.ShowKey tKey
      Ed.Status tKey && "is back to" && Power.Get(sPower, tKey) && "(from the element / form)"
      exit mouseUp
   end if
   if tName begins with "C_" then
      Ed.Set char 3 to -1 of tName, the hilite of the target
      exit mouseUp
   end if
   if tName begins with "K_" then
      Ed.ReadLocks
      exit mouseUp
   end if
   switch tName
      case "PowerList"
         Ed.Select the selectedText of the target
         break
      case "Btn_Fire"
         Ed.Fire empty, false
         break
      case "Btn_Loop"
         Ed.ToggleLoop
         break
      case "Btn_Step"
         put true into sStepOnce
         break
      case "Btn_Clear"
         Emit.Clear
         put empty into sHeld
         put empty into sCastAt
         break
      case "Btn_Dummy"
         Ed.Popup "dummy", "stand" & cr & "walk" & cr & "jump"
         break
      case "Btn_New"
         Ed.NewPower
         break
      case "Btn_Copy"
         Ed.CopyPower
         break
      case "Btn_Delete"
         Ed.DeletePower
         break
      case "Btn_Rename"
         Ed.RenamePower
         break
      case "Btn_Save"
         Ed.SavePower
         break
      case "Btn_Revert"
         Ed.RevertPower
         break
      case "Btn_Export"
         set the clipboardData["text"] to Power.Text(sPower)
         Ed.Status "The power's text is on the clipboard."
         break
      case "Btn_Dice"
         Ed.Dice
         break
      case "Btn_Mutate"
         Ed.Mutate 0.1
         break
      case "Btn_MutateBig"
         Ed.Mutate 0.35
         break
      case "Btn_SnapA"
         put Power.Array(sPower) into sSnapA
         Ed.Status "kept as A"
         break
      case "Btn_SnapB"
         put Power.Array(sPower) into sSnapB
         Ed.Status "kept as B"
         break
      case "Btn_Swap"
         Ed.Swap
         break
      default
         -- a click on the stage fires at that spot
         if the long id of the target contains "group" and the mouseLoc is within the rect of group "Stage" then
            Ed.Fire the mouseLoc, false
         else
            pass mouseUp
         end if
   end switch
end mouseUp

on scrollbarDrag pPos
   local tName, tKey, tInfo, tMin, tMax
   put the short name of the target into tName
   if tName is "Slow" then
      put pPos / 100 into sSlow
      exit scrollbarDrag
   end if
   if tName is "Distance" then
      put pPos into sDistance
      put sCasterX + sDistance into sDummyHome
      set the loc of field "DummyName" to sDummyHome & comma & (sFloorY + 15)
      Ed.PlacePosts
      exit scrollbarDrag
   end if
   if not (tName begins with "S_") then pass scrollbarDrag
   put char 3 to -1 of tName into tKey
   put Emit.KeyInfo(tKey) into tInfo
   set the itemDel to tab
   put item 3 of tInfo into tMin
   put item 4 of tInfo into tMax
   set the itemDel to comma
   Power.Set sPower, tKey, tMin + pPos / 1000 * (tMax - tMin)
   set the text of field ("N_" & tKey) to Power.Get(sPower, tKey)
   set the textStyle of field ("R_" & tKey) to "bold"
end scrollbarDrag

on returnInField
   if Ed.FieldDone() then exit returnInField
   pass returnInField
end returnInField

on enterInField
   if Ed.FieldDone() then exit enterInField
   pass enterInField
end enterInField

on closeField
   get Ed.FieldDone()
   pass closeField
end closeField

-- a typed value: number fields, the seed, the cost table, the command line
function Ed.FieldDone
   local tName, tKey, tL, tN, tText
   put the short name of the target into tName
   if tName is "CmdLine" then
      put the text of the target into tText
      if tText is empty then return true
      try
         do tText
         Ed.Status "did:" && tText && "->" && the result
      catch tErr
         Ed.Status "error:" && line 1 of tErr
      end try
      set the text of the target to empty
      return true
   end if
   if tName is "CostTable" then
      set the itemDel to tab
      repeat for each line tL in the text of the target
         put item 1 of tL into tN
         if not Power.Exists(tN) then next repeat
         Power.Set tN, "cost", item 4 of tL
         Power.Set tN, "cooldown", item 5 of tL
         Power.Set tN, "castTime", item 6 of tL
      end repeat
      set the itemDel to comma
      Ed.FillCostTable
      Ed.ShowKey "cost"
      Ed.ShowKey "cooldown"
      Ed.ShowKey "castTime"
      Ed.Status "cost table read (save each power to keep it)"
      return false
   end if
   if tName begins with "N_" then
      put char 3 to -1 of tName into tKey
      Ed.Set tKey, the text of the target
      focus on nothing
      return true
   end if
   return false
end Ed.FieldDone

on menuPick pItem
   if the short name of the target is not "EdPopup" then pass menuPick
   Ed.Picked sPopupFor, pItem
end menuPick

-------------------------------------------------------------------- menus and pickers

command Ed.Popup pFor, pItems
   put pFor into sPopupFor
   set the text of button "EdPopup" to pItems
   popup button "EdPopup" at the mouseLoc
end Ed.Popup

command Ed.Menu pMenu
   local tL, tItems, tE
   switch pMenu
      case "Power"
         Ed.Popup "power", "New..." & cr & "Copy" & cr & "Rename..." & cr & "Delete" & cr & "-" & cr & "Save" & cr & "Revert" & cr & "Copy text" & cr & "-" & cr & "Reload all"
         break
      case "Element"
         repeat for each item tE in Emit.Elements()
            if tE is Power.Get(sPower, "element") then
               put "!c" & tE & cr after tItems
            else
               put tE & cr after tItems
            end if
         end repeat
         Ed.Popup "element", tItems
         break
      case "Form"
         repeat for each item tE in Emit.Forms()
            if tE is Power.Get(sPower, "form") then
               put "!c" & tE & cr after tItems
            else
               put tE & cr after tItems
            end if
         end repeat
         Ed.Popup "form", tItems
         break
      case "View"
         Ed.Popup "view", "Grid on/off" & cr & "Dummy: stand" & cr & "Dummy: walk" & cr & "Dummy: jump" & cr & "-" & cr & "Editor" & cr & "Duel" & cr & "About"
         break
      case "Help"
         Ed.Popup "help", "Keys" & cr & "About"
         break
   end switch
end Ed.Menu

command Ed.PickList pKey
   local tInfo, tKind, tItems
   if pKey is "element" then
      Ed.Menu "Element"
      exit Ed.PickList
   end if
   if pKey is "form" then
      Ed.Menu "Form"
      exit Ed.PickList
   end if
   put Emit.KeyInfo(pKey) into tInfo
   set the itemDel to tab
   put item 2 of tInfo into tKind
   set the itemDel to comma
   if tKind is "power" then
      put "none" & cr & Power.List() into tItems
   else
      put char 6 to -1 of tKind into tItems
      replace "|" with cr in tItems
   end if
   Ed.Popup "key:" & pKey, tItems
end Ed.PickList

command Ed.PickColor pKey
   local tC
   put Emit.RGB(Power.Get(sPower, pKey)) into tC
   answer color with tC
   if it is empty then exit Ed.PickColor
   Ed.Set pKey, Ed.Hex(it)
end Ed.PickColor

function Ed.Hex pRGB
   local tOut, i, tH
   put "#" into tOut
   repeat with i = 1 to 3
      put baseConvert(item i of pRGB, 10, 16) into tH
      if the number of chars of tH < 2 then put "0" before tH
      put tH after tOut
   end repeat
   return tOut
end Ed.Hex

command Ed.Picked pFor, pItem
   switch pFor
      case "power"
         switch pItem
            case "New..."
               Ed.NewPower
               break
            case "Copy"
               Ed.CopyPower
               break
            case "Rename..."
               Ed.RenamePower
               break
            case "Delete"
               Ed.DeletePower
               break
            case "Save"
               Ed.SavePower
               break
            case "Revert"
               Ed.RevertPower
               break
            case "Copy text"
               set the clipboardData["text"] to Power.Text(sPower)
               Ed.Status "The power's text is on the clipboard."
               break
            case "Reload all"
               Emit.LoadAll sUserFolder
               Ed.FillList
               Ed.Select sPower
               break
         end switch
         break
      case "element"
         Power.Set sPower, "element", pItem
         Ed.ShowPower
         Ed.FillCostTable
         break
      case "form"
         Power.Set sPower, "form", pItem
         Ed.ShowPower
         Ed.FillCostTable
         break
      case "dummy"
         put pItem into sDummyMode
         set the label of button "Btn_Dummy" to "DUMMY:" && pItem
         break
      case "view"
         switch pItem
            case "Grid on/off"
               set the visible of graphic "Grid" to not the visible of graphic "Grid"
               break
            case "Dummy: stand"
               Ed.Picked "dummy", "stand"
               break
            case "Dummy: walk"
               Ed.Picked "dummy", "walk"
               break
            case "Dummy: jump"
               Ed.Picked "dummy", "jump"
               break
            case "Editor"
               go card "Editor"
               break
            case "Duel"
               go card "Duel"
               break
            case "About"
               go card "About"
               break
         end switch
         break
      case "help"
         if pItem is "Keys" then
            put true into sHelpOn
            set the visible of field "Help" to true
         else
            go card "About"
         end if
         break
      default
         if pFor begins with "key:" then Ed.Set char 5 to -1 of pFor, pItem
   end switch
end Ed.Picked

-------------------------------------------------------------------- power commands

command Ed.NewPower
   local tName
   ask "Name of the new power (it starts as" && Power.Get(sPower, "element") && Power.Get(sPower, "form") & "):" with "my power"
   put it into tName
   if tName is empty then exit Ed.NewPower
   if Power.Exists(tName) then
      answer "There is already a power called" && tName & "."
      exit Ed.NewPower
   end if
   Power.Make tName, Power.Get(sPower, "element"), Power.Get(sPower, "form")
   Ed.FillList
   Ed.Select tName
end Ed.NewPower

command Ed.CopyPower
   local tName, i
   put 2 into i
   repeat while Power.Exists(sPower && i)
      add 1 to i
   end repeat
   put sPower && i into tName
   Power.Copy sPower, tName
   Ed.FillList
   Ed.Select tName
end Ed.CopyPower

command Ed.RenamePower
   local tName, tOld
   put sPower into tOld
   ask "New name for" && tOld & ":" with tOld
   put it into tName
   if tName is empty or tName is tOld then exit Ed.RenamePower
   if Power.Exists(tName) then
      answer "There is already a power called" && tName & "."
      exit Ed.RenamePower
   end if
   Power.Copy tOld, tName
   Power.Delete tOld
   Ed.FillList
   Ed.Select tName
   Ed.Status "Renamed. Save it to keep the new name (the old file stays where it was)."
end Ed.RenamePower

-- forgets the power; a saved file of yours moves to Powers/deleted (never thrown away)
command Ed.DeletePower
   local tName, tFile
   put sPower into tName
   answer "Delete" && tName & "?" with "Cancel" or "Delete"
   if it is not "Delete" then exit Ed.DeletePower
   put sUserFolder & "/" & Power.FileName(tName) into tFile
   if there is a file tFile then
      if there is not a folder (sUserFolder & "/deleted") then create folder (sUserFolder & "/deleted")
      rename file tFile to sUserFolder & "/deleted/" & Power.FileName(tName)
   end if
   Power.Delete tName
   Ed.FillList
   Ed.Select line 1 of Power.List()
   Ed.Status tName && "deleted (shipped powers come back on Reload all)."
end Ed.DeletePower

command Ed.SavePower
   Power.Save sPower, sUserFolder
   if the result is empty then
      Ed.Status "Saved" && sPower && "to" && sUserFolder
   else
      Ed.Status "Could not save:" && the result
   end if
end Ed.SavePower

command Ed.RevertPower
   local tFile
   put sUserFolder & "/" & Power.FileName(sPower) into tFile
   if there is not a file tFile then put Emit.Folder() & "/powers/" & Power.FileName(sPower) into tFile
   if there is not a file tFile then
      Ed.Status "No file for" && sPower && "yet."
      exit Ed.RevertPower
   end if
   get Power.LoadText(textDecode(URL ("binfile:" & tFile), "UTF-8"))
   Ed.ShowPower
   Ed.FillCostTable
   Ed.Status "Read back from" && tFile
end Ed.RevertPower

command Ed.Dice
   Power.Set sPower, "seed", random(2147483000)
   Ed.ShowKey "seed"
   Ed.Status "new seed: a new shape with the same numbers"
end Ed.Dice

command Ed.ReadLocks
   local tK
   put empty into sLocks
   repeat for each line tK in Emit.Keys()
      if there is a button ("K_" & tK) and the hilite of button ("K_" & tK) then put tK & comma after sLocks
   end repeat
end Ed.ReadLocks

command Ed.Mutate pAmount
   Ed.ReadLocks
   Power.Mutate sPower, pAmount, sLocks
   Ed.ShowPower
   Ed.Status "mutated (" & round(pAmount * 100) & "% of each range, locked rows kept). A / B keep versions to compare."
end Ed.Mutate

command Ed.Swap
   if sSnapA is not an array or sSnapB is not an array then
      Ed.Status "Keep a version as A and another as B first."
      exit Ed.Swap
   end if
   if sShowing is "A" then
      Power.SetArray sPower, sSnapB
      put "B" into sShowing
   else
      Power.SetArray sPower, sSnapA
      put "A" into sShowing
   end if
   Ed.ShowPower
   Ed.Status "showing" && sShowing
end Ed.Swap
