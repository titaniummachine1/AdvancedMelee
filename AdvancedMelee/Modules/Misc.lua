local Misc = {}
local Globals = require("AdvancedMelee.Globals")

local function OnCreateMove(pCmd)
    if not Globals.pLocal.entity or not Globals.pLocal.entity:IsAlive() then return end
    local weapon = Globals.pLocal.Weapon
    if not weapon then return end

    -- Check conditions for TroldierAssist
    if Globals.Menu.Misc.TroldierAssist then
            local state = ""
            print(state)
            Globals.pLocal.BlastJump = Globals.pLocal.entity:InCond(81)
            if Globals.pLocal.BlastJump then
                pCmd:SetButtons(pCmd.buttons | IN_DUCK)
                state = "slot3"
            elseif Globals.pLocal.UsingMargetGarden then
                state = "slot1"
            end
            client.Command(state, true)
    end

    -- Check conditions for CritRefill
    if Globals.Menu.Misc.CritRefill.Active then
        if weapon:IsMeleeWeapon() then
            if Globals.vTarget == nil or Globals.vTarget.entity == nil then
                local CritValue = 39  -- Base value for crit token bucket calculation
                local CritBucket = Globals.pLocal.Weapon:GetCritTokenBucket()
                local NumCrits = CritValue * Globals.Menu.Misc.CritRefill.NumCrits

                -- Cap NumCrits to ensure CritBucket does not exceed 1000
                NumCrits = math.clamp(NumCrits, 27, 1000)

                if CritBucket < NumCrits then
                    gui.SetValue("Crit Hack Key", 0)  -- Set to 0 to disable
                    gui.SetValue("Melee Crit Hack", 2) -- Stop using crit bucket to stock up crits
                    pCmd:SetButtons(pCmd:GetButtons() | IN_ATTACK)
                else
                    gui.SetValue("Crit Hack Key", Globals.Gui.CritHackKey)
                    gui.SetValue("Melee Crit Hack", Globals.Menu.Misc.CritMode)
                end
            else
                gui.SetValue("Melee Crit Hack",  Globals.Menu.Misc.CritMode)
            end
        end
    end
end

--[[ Callbacks ]]
--Unregister previous callbacks--
callbacks.Unregister("CreateMove", "AM_OnTickMisc")                     -- unregister the "CreateMove" callback
--Register callbacks--
callbacks.Register("CreateMove", "AM_OnTickMisc", OnCreateMove)        -- register the "CreateMove" callback

return Misc