--[[Swing Prediction Module]]--
--[[    Predicting swing   ]]--

local Globals = require("AdvancedMelee.Globals")
local Common = require("AdvancedMelee.Common")

local SwingPrediction = {}

local function OnCreateMove()
    local Swinghull = Globals.pLocal.SwingData.SwingHullSize or 35.6
    local SwingRange = Globals.pLocal.SwingData.SwingRange or 48
    local TotalSwingRange = Globals.pLocal.SwingData.TotalSwingRange or 48 + (35.6 / 2)

end


--[[ Callbacks ]]
--Unregister previous callbacks--
callbacks.Unregister("CreateMove", "AM_OnTick")                     -- unregister the "CreateMove" callback
--Register callbacks--
callbacks.Register("CreateMove", "AM_OnTick", OnCreateMove)        -- register the "CreateMove" callback

return SwingPrediction