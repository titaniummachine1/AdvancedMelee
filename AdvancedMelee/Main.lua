--[[
    Advanced Melee for Lmaobox
    Author: titaniummachine1 (https://github.com/titaniummachine1)
    Credits:
    LNX (github.com/lnx00) for libries
    GoodEveningFellOff (https://github.com/GoodEveningFellOff/Lbox-Basic-Backtrack/blob/main/main.lua) for bactkrack insight
]]

--[[ Annotations ]]
---@alias PlayerData { Angle: EulerAngles[], Position: Vector3[], SimTime: number[] }

--[[ Imports ]]
local Common = require("AdvancedMelee.Common")
local G = require("AdvancedMelee.Globals")
require("AdvancedMelee.Config")
require("AdvancedMelee.Visuals")
require("AdvancedMelee.Menu")

--[[Modules]]
--require("AdvancedMelee.Modules.Aimbot")
require("AdvancedMelee.Modules.Misc")

--[[Utils]]--
local Predict = require("AdvancedMelee.Utils.Prediction")

local function OnCreateMove(cmd)
    -- Update local player data
    G.pLocal.entity = entities.GetLocalPlayer() -- Update local player entity
    local pLocal = G.pLocal.entity
    if not pLocal or not pLocal:IsAlive() then return end -- If local player is not valid, returns

    Predict.Strafe()

    G.Players = entities.FindByClass("CTFPlayer")
    local pLflags = pLocal:GetPropInt("m_fFlags")

    -- GUI properties
    G.Gui.Backtrack = gui.GetValue("Backtrack")
    G.Gui.FakeLatency = gui.GetValue("Fake Latency")
    G.Gui.FakeLatencyAmount = gui.GetValue("Fake Latency Value (MS)")
    if not G.Gui.IsVisible then --dont force update if menu is open
        G.Gui.CritHackKey = gui.GetValue("Crit Hack Key")
    end

    -- World properties
    G.World.Gravity = client.GetConVar("sv_gravity")
    G.World.StepHeight = pLocal:GetPropFloat("localdata", "m_flStepSize")
    G.World.Lerp = client.GetConVar("cl_interp") or 0
    G.World.latOut = clientstate.GetLatencyOut()
    G.World.latIn = clientstate.GetLatencyIn()
    G.World.Latency = Conversion.Time_to_Ticks((G.World.latOut + G.World.latIn) * (globals.TickInterval() * 66.67)) -- Converts time to ticks

    -- Player properties
    G.pLocal.Class = pLocal:GetPropInt("m_iClass") or 1
    G.pLocal.index = pLocal:GetIndex() or 1
    G.pLocal.team = pLocal:GetTeamNumber() or 1
    G.pLocal.ViewAngles = engine.GetViewAngles() or EulerAngles(0, 0, 0)
    G.pLocal.OnGround = (pLflags & FL_ONGROUND == 1) or false

    G.pLocal.GetAbsOrigin = pLocal:GetAbsOrigin() or Vector3(0, 0, 0)
    local pLocalOrigin = G.pLocal.GetAbsOrigin
    local viewOffset = pLocal:GetPropVector("localdata", "m_vecViewOffset[0]") or Vector3(0, 0, 75)
    local adjustedHeight = pLocalOrigin + viewOffset
    local viewheight = (adjustedHeight - pLocalOrigin):Length()
    G.pLocal.Viewheight = viewheight
    G.pLocal.VisPos = G.pLocal.GetAbsOrigin + Vector3(0, 0, G.pLocal.Viewheight)
    pLflags = pLocal:GetPropInt("m_fFlags")
    local DUCKING = (pLflags & FL_DUCKING == 2)
    if DUCKING then
        G.pLocal.vHitbox.Max.z = 62
    else
        G.pLocal.vHitbox.Max.z = 82
    end

    G.pLocal.BlastJump = pLocal:InCond(81)
    G.pLocal.ChargeLeft = pLocal:GetPropInt("m_flChargeMeter") or 0

    -- Weapon properties
    G.pLocal.WpData.CurrWeapon.Weapon = pLocal:GetPropEntity("m_hActiveWeapon") or nil
    local weapon = G.pLocal.WpData.CurrWeapon.Weapon
    if not weapon then return end
    Common.SetupWeaponData()

    --G.pLocal.Actions.NextAttacmTime2 = Conversion.Time_to_Ticks(pLocal:GetPropFloat("bcc_localdata", "m_flNextAttack"))
    G.pLocal.Actions.NextAttackTime = Conversion.Time_to_Ticks(weapon:GetPropFloat("m_flLastFireTime") or 0)
    G.pLocal.Actions.LastAttackTime, G.pLocal.Actions.Attacked = Common.GetLastAttackTime(cmd, weapon) or 0, false

    --[[pLocal Prediction]]--

    G.pLocal.PredData = Predict.PlayerMovement(pLocal, G.pLocal.WpData.SwingData.SmackDelay or 13, G.StrafeData.strafeAngles[G.pLocal.index] or 0)
    if not G.pLocal.PredData then print("No Prediction") return end
    --print(#G.pLocal.PredData.pos)

    local keybind = G.Menu.Aimbot.Keybind
    if keybind == 0 or input.IsButtonDown(keybind) then
        G.ShouldFindTarget = true
    else
        G.ShouldFindTarget = false
    end
end

--[[ Callbacks ]]
--Unregister previous callbacks--
callbacks.Unregister("CreateMove", "AdvancedMelee")                     -- unregister the "CreateMove" callback
--Register callbacks--
callbacks.Register("CreateMove", "AdvancedMelee", OnCreateMove)        -- register the "CreateMove" callback

--[[ Play sound when loaded ]]--
client.Command('play "ui/buttonclick"', true) -- Play the "buttonclick" sound when the script is loaded