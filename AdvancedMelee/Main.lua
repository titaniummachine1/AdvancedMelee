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

local function OnCreateMove(cmd)
    -- Update local player data
    Globals.pLocal.entity = entities.GetLocalPlayer() -- Update local player entity
    local pLocal = Globals.pLocal.entity
    if not pLocal or not pLocal:IsAlive() then return end -- If local player is not valid, returns

    Globals.Players = entities.FindByClass("CTFPlayer")
    local flags = pLocal:GetPropInt("m_fFlags")

    -- Update strafe angles
    Common.CalcStrafe()

    -- GUI properties
    Globals.Gui.Backtrack = gui.GetValue("Backtrack")
    Globals.Gui.FakeLatency = gui.GetValue("Fake Latency")
    Globals.Gui.FakeLatencyAmount = gui.GetValue("Fake Latency Value (MS)")
    if not Globals.Gui.IsVisible then --dont force update if menu is open
        Globals.Gui.CritHackKey = gui.GetValue("Crit Hack Key")
    end

    -- World properties
    Globals.World.Gravity = client.GetConVar("sv_gravity")
    Globals.World.StepHeight = pLocal:GetPropFloat("localdata", "m_flStepSize")
    Globals.World.Lerp = client.GetConVar("cl_interp") or 0
    Globals.World.latOut = clientstate.GetLatencyOut()
    Globals.World.latIn = clientstate.GetLatencyIn()
    Globals.World.Latency = Conversion.Time_to_Ticks((Globals.World.latOut + Globals.World.latIn) * (globals.TickInterval() * 66.67)) -- Converts time to ticks

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
    Globals.pLocal.WeaponsData.Weapon.Weapon = pLocal:GetPropEntity("m_hActiveWeapon") or nil
    local weapon = Globals.pLocal.WeaponsData.Weapon.Weapon
    if not weapon then return end

    Common.SetupWeaponData()

    Globals.pLocal.Actions.NextAttackTime = Conversion.Time_to_Ticks(weapon:GetPropFloat("m_flLastFireTime") or 0)
    --Globals.pLocal.Actions.NextAttacmTime2 = Conversion.Time_to_Ticks(pLocal:GetPropFloat("bcc_localdata", "m_flNextAttack"))
    Globals.pLocal.Actions.LastAttackTime, Globals.pLocal.Actions.Attacked = Common.GetLastAttackTime(cmd, weapon) or 0, false

    if weapon:IsMeleeWeapon() then

        -- Swing properties
        local defaultSwingRange = 48
        local disciplinaryActionHullSize = 55.8
        local defaultHullSize = 36
        local MarketGardenIndex = 416

        Globals.pLocal.UsingMargetGarden = Globals.pLocal.WeaponDefIndex == MarketGardenIndex

        local swingRange = weapon:GetSwingRange() or defaultSwingRange
        local isDisciplinaryAction = Globals.pLocal.WeaponsData.MeleeWeapon.WeaponDef:GetName() == "The Disciplinary Action"
        local swingHullSize = isDisciplinaryAction and disciplinaryActionHullSize or defaultHullSize
        local halfHullSize = swingHullSize / 2

        Globals.pLocal.WeaponsData.MeleeWeapon.SwingData.SwingRange = swingRange
        Globals.pLocal.WeaponsData.MeleeWeapon.SwingData.SwingHullSize = swingHullSize
        Globals.pLocal.WeaponsData.MeleeWeapon.SwingData.TotalSwingRange = swingRange + halfHullSize
        Globals.pLocal.WeaponsData.MeleeWeapon.SwingData.SwingHull = {
            Max = Vector3(halfHullSize, halfHullSize, halfHullSize),
            Min = Vector3(-halfHullSize, -halfHullSize, -halfHullSize)
        }

        if Globals.StrafeData.inaccuracy then -- If we got inaccuracy in strafe calculations
            local inaccuracy = math.abs(Globals.StrafeData.inaccuracy[Globals.pLocal.index] or 0)
            Globals.pLocal.WeaponsData.MeleeWeapon.SwingData.TotalSwingRange = (Globals.pLocal.WeaponsData.MeleeWeapon.SwingData.TotalSwingRange - inaccuracy)
        end
    end

    local keybind = Globals.Menu.Aimbot.Keybind
    if keybind == 0 or input.IsButtonDown(keybind) then
        Globals.ShouldFindTarget = true
    else
        Globals.ShouldFindTarget = falses
    end
    --[-----Get best target-----]
    if Globals.ShouldFindTarget == true then
        -- Check if need to search for target
        Globals.vTarget.entity = Common.GetBestTarget(pLocal)
        if Globals.vTarget.entity then
            Globals.vTarget.index = Globals.vTarget.entity:GetIndex()
            Globals.vTarget.GetAbsOrigin = Globals.vTarget.entity:GetAbsOrigin()
            --[[prediction]]
            Globals.vTarget.PredTicks = Common.PredictPlayer(Globals.vTarget.entity, 13, Globals.StrafeData.strafeAngles[Globals.vTarget.index] or 0) or {}
            --print(Globals.vTarget.entity:GetName())
        end
    else
        Globals.ResetTarget()
        return
    end
end

--[[ Callbacks ]]
--Unregister previous callbacks--
callbacks.Unregister("CreateMove", "AdvancedMelee")                     -- unregister the "CreateMove" callback
--Register callbacks--
callbacks.Register("CreateMove", "AdvancedMelee", OnCreateMove)        -- register the "CreateMove" callback

--[[ Play sound when loaded ]]--
client.Command('play "ui/buttonclick"', true) -- Play the "buttonclick" sound when the script is loaded