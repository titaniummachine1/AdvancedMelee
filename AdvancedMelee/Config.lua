--[[ Imports ]]
local Common = require("AdvancedMelee.Common")
local Globals = require("AdvancedMelee.Globals")
local Menu = Globals.Menu

local Config = {}

local Lua__fullPath = GetScriptName()
local Lua__fileName = Lua__fullPath:match("\\([^\\]-)$"):gsub("%.lua$", "")
local folder_name = string.format([[Lua %s]], Lua__fileName)

function Config.GetFilePath()
    local success, fullPath = filesystem.CreateDirectory(folder_name)
    return tostring(fullPath .. "/config.cfg")
end

function Config.CreateCFG(table)
    if not table then
        table = Menu
    end
    local filepath = Config.GetFilePath()
    local file = io.open(filepath, "w")  -- Define the file variable here
    local filePathstring = tostring(Config.GetFilePath())
    local shortFilePath = filePathstring:match(".*\\(.*\\.*)$")

    if file then
        local function serializeTable(tbl, level)
            level = level or 0
            local result = string.rep("    ", level) .. "{\n"
            for key, value in pairs(tbl) do
                result = result .. string.rep("    ", level + 1)
                if type(key) == "string" then
                    result = result .. '["' .. key .. '"] = '
                else
                    result = result .. "[" .. key .. "] = "
                end
                if type(value) == "table" then
                    result = result .. serializeTable(value, level + 1) .. ",\n"
                elseif type(value) == "string" then
                    result = result .. '"' .. value .. '",\n'
                else
                    result = result .. tostring(value) .. ",\n"
                end
            end
            result = result .. string.rep("    ", level) .. "}"
            return result
        end

        local serializedConfig = serializeTable(table)
        file:write(serializedConfig)
        file:close()

        local successMessage = shortFilePath
        printc(100, 183, 0, 255, "Succes Loading Config: Path:" .. successMessage)
        Notify.Simple("Success! Saved Config to:", successMessage, 5)
    else
        local errorMessage = "Failed to open: " .. tostring(shortFilePath)
        printc( 255, 0, 0, 255, errorMessage)
        Notify.Simple("Error", errorMessage, 5)
    end
end

-- Function to check if all expected functions exist in the loaded config
local function checkAllFunctionsExist(expectedMenu, loadedMenu)
    for key, value in pairs(expectedMenu) do
        if type(value) == 'function' then
            -- Check if the function exists in the loaded menu and has the correct type
            if not loadedMenu[key] or type(loadedMenu[key]) ~= 'function' then
                return false
            end
        end
    end
    for key, value in pairs(expectedMenu) do
        if not loadedMenu[key] or type(loadedMenu[key]) ~= type(value) then
            return false
        end
    end
    return true
end

function Config.LoadCFG()
    local filepath = Config.GetFilePath()
    local file = io.open(filepath, "r")
    local filePathstring = tostring(Config.GetFilePath())
    local shortFilePath = filePathstring:match(".*\\(.*\\.*)$")
    Menu = Globals.Menu

    if file then
        local content = file:read("*a")
        file:close()
        local chunk, err = load("return " .. content)
        if chunk then
            local loadedMenu = chunk()
            if checkAllFunctionsExist(Menu, loadedMenu) and not input.IsButtonDown(KEY_LSHIFT) then
                local successMessage = shortFilePath
                printc(100, 183, 0, 255, "Succes Loading Config: Path:" .. successMessage)
                Notify.Simple("Success! Loaded Config from", successMessage, 5)
                Menu = loadedMenu
                Globals.Menu = Menu
                return loadedMenu
            elseif input.IsButtonDown(KEY_LSHIFT) then
                local warningMessage = "Creating a new config."
                printc( 255, 0, 0, 255, warningMessage)
                Notify.Simple("Warning", warningMessage, 5)
                Config.CreateCFG(Menu) -- Save the config
                return Menu
            else
                local warningMessage = "Config is outdated or invalid. Creating a new config."
                printc( 255, 0, 0, 255, warningMessage)
                Notify.Simple("Warning", warningMessage, 5)
                Config.CreateCFG(Menu) -- Save the config
                return Menu
            end
        else
            local errorMessage = "Error executing configuration file: " .. tostring(err)
            printc( 255, 0, 0, 255, errorMessage)
            Notify.Simple("Error", errorMessage, 5)
            Config.CreateCFG(Menu) -- Save the config
            return Menu
        end
    else
        local warningMessage = "Config file not found. Creating a new config."
        printc( 255, 0, 0, 255, warningMessage)
        Notify.Simple("Warning", warningMessage, 5)
        Config.CreateCFG(Menu) -- Save the config
        return Menu
    end
end

Config.LoadCFG() -- Load the config on load

--[[ Callbacks ]]
local function OnUnload() -- Called when the script is unloaded
    Config.CreateCFG(Menu) -- Save the configurations to a file
    UnloadLib() --unloading lualib
    -- Unload package for debugging
    Lib.Utils.UnloadPackages("AdvancedMelee")
    client.Command('play "ui/buttonclickrelease"', true) -- Play the "buttonclickrelease" sound
end

callbacks.Unregister("Unload", "AM_Unload")                                -- unregister the "Unload" callback
callbacks.Register("Unload", "AM_Unload", OnUnload)                         -- Register the "Unload" callback

return Config
