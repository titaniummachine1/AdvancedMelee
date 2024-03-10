--[[Swing Prediction Module]]--
--[[         Aimbot        ]]--

local G = require("AdvancedMelee.Globals")
--local Common = require("AdvancedMelee.Common")

local Aimbot = {}

local function OnCreateMove()

end


--[[ Callbacks ]]
--Unregister previous callbacks--
callbacks.Unregister("CreateMove", "AM_OnTick")                     -- unregister the "CreateMove" callback
--Register callbacks--
callbacks.Register("CreateMove", "AM_OnTick", OnCreateMove)        -- register the "CreateMove" callback

return Aimbot