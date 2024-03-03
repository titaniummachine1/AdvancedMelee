--[[
    Advanced Melee for Lmaobox Recode
    Author: titaniummachine1 (https://github.com/titaniummachine1)
    Credits:
    LNX (github.com/lnx00) for libries
    GoodEveningFellOff (https://github.com/GoodEveningFellOff/Lbox-Basic-Backtrack/blob/main/main.lua) for bactkrack insight
]]

--[[ Annotations ]]
---@alias PlayerData { Angle: EulerAngles[], Position: Vector3[], SimTime: number[] }

--[[ Imports ]]
local Common = require("AdvancedMelee.Common")
local Globals = require("AdvancedMelee.Globals")
require("AdvancedMelee.Config")
require("AdvancedMelee.Visuals")
require("AdvancedMelee.Menu")

--Modules--
require("AdvancedMelee.Modules.Misc")

local function OnCreateMove()
    -- Update local player data
    Globals.pLocal.entity = entities.GetLocalPlayer() -- Update local player entity
    local pLocal = Globals.pLocal.entity
    if not pLocal or not pLocal:IsAlive() then return end -- If local player is not valid, returns

    Globals.Players = entities.FindByClass("CTFPlayer")
    local flags = pLocal:GetPropInt("m_fFlags")

    -- Update strafe angles
    Common.CalcStrafe()

    -- Player properties
    Globals.pLocal.Class = pLocal:GetPropInt("m_iClass") or 1
    Globals.pLocal.index = pLocal:GetIndex() or 1
    Globals.pLocal.team = pLocal:GetTeamNumber() or 1
    Globals.pLocal.GetAbsOrigin = pLocal:GetAbsOrigin() or Vector3(0, 0, 0)
    Globals.pLocal.ViewAngles = engine.GetViewAngles() or EulerAngles(0, 0, 0)
    Globals.pLocal.OnGround = (flags & FL_ONGROUND == 1) or false
    Globals.pLocal.Viewheight = pLocal:GetPropVector("localdata", "m_vecViewOffset[0]") or Vector3(0, 0, 75)
    Globals.pLocal.VisPos = Globals.pLocal.GetAbsOrigin + Globals.pLocal.Viewheight
    Globals.pLocal.BlastJump = pLocal:InCond(81)
    Globals.pLocal.ChargeLeft = pLocal:GetPropInt("m_flChargeMeter") or 0

    -- Weapon properties
    Globals.pLocal.Weapon = pLocal:GetPropEntity("m_hActiveWeapon") or nil
    local weapon = Globals.pLocal.Weapon
    if not weapon then return end

    Globals.pLocal.pWeaponData = weapon:GetWeaponData()
    Globals.pLocal.WeaponID = weapon:GetWeaponID()
    Globals.pLocal.WeaponDefIndex = weapon:GetPropInt("m_iItemDefinitionIndex")
    Globals.pLocal.WeaponDef = itemschema.GetItemDefinitionByID(Globals.pLocal.WeaponDefIndex)
    Globals.pLocal.WeaponName = Globals.pLocal.WeaponDef:GetName()
    Globals.pLocal.UsingMargetGarden = Globals.pLocal.WeaponDefIndex == 416

    -- Swing properties
    Globals.pLocal.SwingRange = weapon:GetSwingRange() or 48
    Globals.pLocal.SwingHullSize = Globals.pLocal.WeaponDef:GetName() == "The Disciplinary Action" and 55.8 or 35.6
    Globals.pLocal.SwingRange = Globals.pLocal.SwingRange + (Globals.pLocal.SwingHullSize / 2)
    if Globals.StrafeData.inaccuracy then -- If we got inaccuracy in strafe calculations
        Globals.pLocal.SwingRange = Globals.pLocal.SwingRange - math.abs(Globals.StrafeData.inaccuracy[Globals.pLocal.index] or 0)
    end

    -- World properties
    Globals.World.Gravity = client.GetConVar("sv_gravity")
    Globals.World.StepHeight = pLocal:GetPropFloat("localdata", "m_flStepSize")
    Globals.World.Lerp = client.GetConVar("cl_interp") or 0
    Globals.World.latOut = clientstate.GetLatencyOut()
    Globals.World.latIn = clientstate.GetLatencyIn()
    Globals.World.Latency = Conversion.Time_to_Ticks((Globals.World.latOut + Globals.World.latIn) * (globals.TickInterval() * 66.67)) -- Converts time to ticks

    -- GUI properties
    Globals.Gui.Backtrack = gui.GetValue("Backtrack")
    Globals.Gui.FakeLatency = gui.GetValue("Fake Latency")
    Globals.Gui.FakeLatencyAmount = gui.GetValue("Fake Latency Value (MS)")
    if not Globals.Gui.IsVisible then --dont force update if menu is open
        Globals.Gui.CritHackKey = gui.GetValue("Crit Hack Key")
    end
end

--[[ Callbacks ]]
--Unregister previous callbacks--
callbacks.Unregister("CreateMove", "AdvancedMelee")                     -- unregister the "CreateMove" callback
--Register callbacks--
callbacks.Register("CreateMove", "AdvancedMelee", OnCreateMove)        -- register the "CreateMove" callback

--[[ Play sound when loaded ]]--
client.Command('play "ui/buttonclick"', true) -- Play the "buttonclick" sound when the script is loaded