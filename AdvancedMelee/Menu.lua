--[[debug commands
    client.SetConVar("cl_vWeapon_sway_interp",              0)             -- Set cl_vWeapon_sway_interp to 0
    client.SetConVar("cl_jiggle_bone_framerate_cutoff", 0)             -- Set cl_jiggle_bone_framerate_cutoff to 0
    client.SetConVar("cl_bobcycle",                     10000)         -- Set cl_bobcycle to 10000
    client.SetConVar("sv_cheats", 1)                                    -- debug fast setup
    client.SetConVar("mp_disable_respawn_times", 1)
    client.SetConVar("mp_respawnwavetime", -1)
    client.SetConVar("mp_teams_unbalance_limit", 1000)

    -- debug command: ent_fire !picker Addoutput "health 99999" --superbot
]]
local MenuModule = {}

--[[ Imports ]]
local Globals = require("AdvancedMelee.Globals")

---@type boolean, ImMenu
local menuLoaded, ImMenu = pcall(require, "ImMenu")
assert(menuLoaded, "ImMenu not found, please install it!")
assert(ImMenu.GetVersion() >= 0.66, "ImMenu version is too old, please update it!")

local lastToggleTime = 0
local Lbox_Menu_Open = true
local toggleCooldown = 0.1  -- 200 milliseconds

function MenuModule.toggleMenu()
    local currentTime = globals.RealTime()
    if currentTime - lastToggleTime >= toggleCooldown then
        Lbox_Menu_Open = not Lbox_Menu_Open  -- Toggle the state
        Globals.Gui.IsVisible = Lbox_Menu_Open
        lastToggleTime = currentTime  -- Reset the last toggle time
    end
end

function MenuModule.GetPressedkey()
    local pressedKey = Input.GetPressedKey()
        if not pressedKey then
            -- Check for standard mouse buttons
            if input.IsButtonDown(MOUSE_LEFT) then return MOUSE_LEFT end
            if input.IsButtonDown(MOUSE_RIGHT) then return MOUSE_RIGHT end
            if input.IsButtonDown(MOUSE_MIDDLE) then return MOUSE_MIDDLE end

            -- Check for additional mouse buttons
            for i = 1, 10 do
                if input.IsButtonDown(MOUSE_FIRST + i - 1) then return MOUSE_FIRST + i - 1 end
            end
        end
        return pressedKey
end


local bindTimer = 0
local bindDelay = 0.25  -- Delay of 0.25 seconds

local function handleKeybind(noKeyText, keybind, keybindName)
    if KeybindName ~= "Press The Key" and ImMenu.Button(KeybindName or noKeyText) then
        bindTimer = os.clock() + bindDelay
        KeybindName = "Press The Key"
    elseif KeybindName == "Press The Key" then
        ImMenu.Text("Press the key")
    end

    if KeybindName == "Press The Key" then
        if os.clock() >= bindTimer then
            local pressedKey = MenuModule.GetPressedkey()
            if pressedKey then
                if pressedKey == KEY_ESCAPE then
                    -- Reset keybind if the Escape key is pressed
                    keybind = 0
                    KeybindName = "Always On"
                    Notify.Simple("Keybind Success", "Bound Key: " .. KeybindName, 2)
                else
                    -- Update keybind with the pressed key
                    keybind = pressedKey
                    KeybindName = Input.GetKeyName(pressedKey)
                    Notify.Simple("Keybind Success", "Bound Key: " .. KeybindName, 2)
                end
            end
        end
    end
    return keybind, keybindName
end

function OnDrawMenu()
    draw.SetFont(Fonts.Verdana)
    draw.Color(255, 255, 255, 255)
    local Menu = Globals.Menu
    local Main = Menu.Main

    -- Inside your OnCreateMove or similar function where you check for input
    if input.IsButtonDown(KEY_INSERT) then  -- Replace 72 with the actual key code for the button you want to use
        MenuModule.toggleMenu()
    end

    if Lbox_Menu_Open == true and ImMenu and ImMenu.Begin("Advanced Melee", true) then
            local Tabs = Menu.Tabs

            ImMenu.BeginFrame(1)
            for tab, _ in pairs(Tabs) do
                if ImMenu.Button(tab) then
                    for otherTab, _ in pairs(Tabs) do
                        Menu.Tabs[otherTab] = (otherTab == tab)
                    end
                end
            end
            ImMenu.EndFrame()

            if Tabs.Aimbot then
                ImMenu.BeginFrame(1)
                    Menu.Aimbot.Aimbot = ImMenu.Checkbox("Enable", Menu.Aimbot.Aimbot)
                ImMenu.EndFrame()

                if Menu.Aimbot.Aimbot then
                    ImMenu.BeginFrame(1)
                        Menu.Aimbot.Silent = ImMenu.Checkbox("Silent Aim", Menu.Aimbot.Silent)
                    ImMenu.EndFrame()

                    ImMenu.BeginFrame(1)
                        Menu.Aimbot.AimbotFOV = ImMenu.Slider("Fov", Menu.Aimbot.AimbotFOV, 1, 360)
                    ImMenu.EndFrame()

                    ImMenu.BeginFrame(1)
                        ImMenu.Text("Keybind: ")
                        Menu.Aimbot.Keybind, Menu.Aimbot.KeybindName = handleKeybind("Always On", Menu.Aimbot.Keybind,  Menu.Aimbot.KeybindName)
                    ImMenu.EndFrame()
                end
            end

            if Tabs.ChargeBot then
                ImMenu.BeginFrame(1)
                    Menu.ChargeBot.ChargeBot = ImMenu.Checkbox("ChargeBot", Menu.ChargeBot.ChargeBot)
                ImMenu.EndFrame()
                if Menu.ChargeBot.ChargeBot then
                    ImMenu.BeginFrame(1)
                        Menu.ChargeBot.ChargeReach = ImMenu.Checkbox("Charge Reach", Menu.ChargeBot.ChargeReach)
                    ImMenu.EndFrame()

                    ImMenu.BeginFrame(1)
                        Menu.ChargeBot.ChargeControl = ImMenu.Checkbox("Charge Control", Menu.ChargeBot.ChargeControl)
                    ImMenu.EndFrame()

                    ImMenu.BeginFrame(1)
                        Menu.ChargeBot.ChargeSensitivity = ImMenu.Slider("Control Sensetivity", Menu.ChargeBot.ChargeSensitivity, 1, 100)
                    ImMenu.EndFrame()
                else
                    Menu.ChargeBot.ChargeReach = false
                    Menu.ChargeBot.ChargeControl = false
                end
            end

            if Tabs.Misc then
                ImMenu.BeginFrame(1)
                    Menu.Misc.TroldierAssist = ImMenu.Checkbox("Troldier Assist", Menu.Misc.TroldierAssist)
                ImMenu.EndFrame()

                ImMenu.BeginFrame(1)
                    Menu.Misc.CritRefill.Active = ImMenu.Checkbox("Auto Crit refill", Menu.Misc.CritRefill.Active)
                    if Menu.Misc.CritRefill.Active then
                        Menu.Misc.CritRefill.NumCrits = ImMenu.Slider("Crit Number", Menu.Misc.CritRefill.NumCrits, 1, 25)
                    end
                ImMenu.EndFrame()
                ImMenu.BeginFrame(1)
                    if Menu.Misc.CritRefill.Active then
                        Menu.Misc.CritMode = ImMenu.Option(Menu.Misc.CritMode, Menu.Misc.CritModes)
                    end
                ImMenu.EndFrame()
            end

            if Tabs.Visuals then
                ImMenu.BeginFrame(1)
                Menu.Visuals.EnableVisuals = ImMenu.Checkbox("Enable", Menu.Visuals.EnableVisuals)
                ImMenu.EndFrame()

                ImMenu.BeginFrame(1)
                    Menu.Visuals.Section = ImMenu.Option(Menu.Visuals.Section, Menu.Visuals.Sections)
                ImMenu.EndFrame()

                if Menu.Visuals.Section == 1 then
                    Menu.Visuals.Local.RangeCircle = ImMenu.Checkbox("Range Circle", Menu.Visuals.Local.RangeCircle)
                    Menu.Visuals.Local.path.enable = ImMenu.Checkbox("Local Path", Menu.Visuals.Local.path.enable)
                    Menu.Visuals.Local.path.Style = ImMenu.Option(Menu.Visuals.Local.path.Style, Menu.Visuals.Local.path.Styles)
                    Menu.Visuals.Local.path.width = ImMenu.Slider("Width", Menu.Visuals.Local.path.width, 1, 20, 0.1)
                end

                if Menu.Visuals.Section == 2 then
                    Menu.Visuals.Target.path.enable = ImMenu.Checkbox("Target Path", Menu.Visuals.Target.path.enable)
                    Menu.Visuals.Target.path.Style = ImMenu.Option(Menu.Visuals.Target.path.Style, Menu.Visuals.Target.path.Styles)
                    Menu.Visuals.Target.path.width = ImMenu.Slider("Width", Menu.Visuals.Target.path.width, 1, 20, 0.1)
                end

                if Menu.Visuals.Section == 3 then
                    ImMenu.BeginFrame(1)
                    ImMenu.Text("Experimental")
                    Menu.Visuals.Sphere = ImMenu.Checkbox("Range Shield", Menu.Visuals.Sphere)
                    ImMenu.EndFrame()
                end

                --[[ImMenu.BeginFrame(1)
                Menu.Visuals.Visualization = ImMenu.Checkbox("Visualization", Menu.Visuals.Visualization)
                Menu.Visuals.RangeCircle = ImMenu.Checkbox("Range Circle", Menu.Visuals.RangeCircle)
                ImMenu.EndFrame()]]
            end
        ImMenu.End()
    end
end

--[[ Callbacks ]]
callbacks.Unregister("Draw", "OnDrawMenu")                                   -- unregister the "Draw" callback
callbacks.Register("Draw", "OnDrawMenu", OnDrawMenu)                              -- Register the "Draw" callback 

return MenuModule