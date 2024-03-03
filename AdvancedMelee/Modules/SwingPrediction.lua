--[[Swing Prediction Module]]--
--[[    Predicting swing   ]]--

local Globals = require("AdvancedMelee.Globals")
local Common = require("AdvancedMelee.Common")

local SwingPrediction = {}

local function OnCreateMove()

end


--[[ Callbacks ]]
--Unregister previous callbacks--
callbacks.Unregister("CreateMove", "AM_OnTick")                     -- unregister the "CreateMove" callback
--Register callbacks--
callbacks.Register("CreateMove", "AM_OnTick", OnCreateMove)        -- register the "CreateMove" callback

return SwingPrediction