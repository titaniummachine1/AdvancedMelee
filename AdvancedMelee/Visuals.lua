--[[ Imports ]]
local Common = require("AdvancedMelee.Common")
local Visuals = {}

local tahoma_bold = draw.CreateFont("Tahoma", 12, 800, FONTFLAG_OUTLINE)

--[[ Functions ]]

local function doDraw()

end

--[[ Callbacks ]]
callbacks.Unregister("Draw", "AMVisuals_Draw")                                   -- unregister the "Draw" callback
callbacks.Register("Draw", "AMVisuals_Draw", doDraw)                              -- Register the "Draw" callback 

return Visuals