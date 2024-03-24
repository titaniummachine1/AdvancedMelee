---@class Common
local Common = {}
local G = require("AdvancedMelee.Globals")
local Menu = G.Menu

---@type boolean, LNXlib
local libLoaded, Lib = pcall(require, "LNXlib")
assert(libLoaded, "LNXlib not found, please install it!")
assert(Lib.GetVersion() >= 1, "LNXlib version is too old, please update it!")

-- Import utility functions
Math = Lib.Utils.Math
Conversion = Lib.Utils.Conversion
Input = Lib.Utils.Input
Commands = Lib.Utils.Commands
Timer = Lib.Utils.Timer
Conversion = Lib.Utils.Conversion

-- Import TF2 related functions
WPlayer = Lib.TF2.WPlayer
WWeapon = Lib.TF2.WWeapon
Helpers = Lib.TF2.Helpers
Prediction = Lib.TF2.Prediction

-- Import UI related functions
Notify = Lib.UI.Notify
Fonts = Lib.UI.Fonts
Log = Lib.Utils.Logger.new("AdvancedMelee")
Log.Level = 0

--[[Common Functions]]--

function Common.Normalize(vec)
    local length = math.sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)
    return Vector3(vec.x / length, vec.y / length, vec.z / length)
end

local LastAttackTick = 0
local AttackHappened = false

function Common.GetLastAttackTime(cmd, weapon)
    local TickCount = globals.TickCount()
    local NextAttackTime = G.pLocal.Actions.NextAttackTime
    --return (nextPrimaryAttack <= G.CurTime()) and (nextAttack <= G.CurTime())
    if AttackHappened == false and NextAttackTime >= TickCount then
        LastAttackTick = TickCount
        --print(LastAttackTick)
        AttackHappened = true
        return LastAttackTick, AttackHappened
    elseif NextAttackTime < TickCount and AttackHappened == true then
        AttackHappened = false
    end
    return LastAttackTick, false
end

function Common.SetupWeaponData()
    local pLocal = G.pLocal.entity

--[[Primary Weapon Data]]--
    G.pLocal.WpData.PWeapon.Weapon =  pLocal:GetEntityForLoadoutSlot( LOADOUT_POSITION_PRIMARY )
    local weapon = G.pLocal.WpData.PWeapon.Weapon

    if not weapon then print("no Primary Weapon") else
        G.pLocal.WpData.PWeapon.WeaponData = weapon:GetWeaponData()
        G.pLocal.WpData.PWeapon.WeaponID = weapon:GetWeaponID()
        G.pLocal.WpData.PWeapon.WeaponDefIndex = weapon:GetPropInt("m_iItemDefinitionIndex")
        if G.pLocal.WpData.PWeapon.WeaponDefIndex then
            G.pLocal.WpData.PWeapon.WeaponDef = itemschema.GetItemDefinitionByID(G.pLocal.WpData.PWeapon.WeaponDefIndex)
            G.pLocal.WpData.PWeapon.WeaponName = G.pLocal.WpData.PWeapon.WeaponDef:GetName()
        end
    end

--[[Melee Weapon Data]]--
    G.pLocal.WpData.MWeapon.Weapon =  pLocal:GetEntityForLoadoutSlot( LOADOUT_POSITION_MELEE )
    weapon = G.pLocal.WpData.MWeapon.Weapon

    if not weapon then print("no Melee Weapon") return false end
    G.pLocal.WpData.MWeapon.WeaponData = weapon:GetWeaponData()
    G.pLocal.WpData.MWeapon.WeaponID = weapon:GetWeaponID()
    G.pLocal.WpData.MWeapon.WeaponDefIndex = weapon:GetPropInt("m_iItemDefinitionIndex")
    G.pLocal.WpData.MWeapon.WeaponDef = itemschema.GetItemDefinitionByID(G.pLocal.WpData.MWeapon.WeaponDefIndex)
    G.pLocal.WpData.MWeapon.WeaponName = G.pLocal.WpData.MWeapon.WeaponDef:GetName()

--[[Current Weapon Data]]--
    G.pLocal.WpData.UsingMargetGarden = false
    weapon = G.pLocal.WpData.CurrWeapon.Weapon
    if not weapon then print("no Current Weapon") return false end
        local currWeapon = G.pLocal.WpData.CurrWeapon
        currWeapon.WeaponData = weapon:GetWeaponData()
        currWeapon.WeaponID = weapon:GetWeaponID()
        currWeapon.WeaponDefIndex = weapon:GetPropInt("m_iItemDefinitionIndex")
        currWeapon.WeaponDef = itemschema.GetItemDefinitionByID(currWeapon.WeaponDefIndex)
        currWeapon.WeaponName = currWeapon.WeaponDef:GetName()

    if weapon:IsMeleeWeapon() then
        local swingData = G.pLocal.WpData.SwingData 
        -- Swing properties
            swingData.SmackDelay = Conversion.Time_to_Ticks(currWeapon.WeaponData.smackDelay) or 13
            G.pLocal.UsingMargetGarden = currWeapon.WeaponDefIndex == MarketGardenIndex

        --[[Swing Data]]--
        local swingRange = weapon:GetSwingRange() or G.Static.DefaultSwingRange
        local isDisciplinaryAction = (currWeapon.WeaponDef:GetName() == "The Disciplinary Action")
        local swingHullSize = isDisciplinaryAction and disciplinaryActionHullSize or G.Static.defaultHullSize
        local halfHullSize = G.Static.HalfHullSize
            swingData.SwingRange = swingRange
            swingData.SwingHullSize = swingHullSize
            swingData.TotalSwingRange = swingRange + halfHullSize
            swingData.SwingHull = {
                Max = Vector3(halfHullSize, halfHullSize, halfHullSize),
                Min = Vector3(-halfHullSize, -halfHullSize, -halfHullSize)
            }

            if G.StrafeData.inaccuracy then -- If we got inaccuracy in strafe calculations
                local inaccuracy = math.abs(G.StrafeData.inaccuracy[G.pLocal.index] or 0)
                swingData.TotalSwingRange = swingData.TotalSwingRange - inaccuracy
            end
        G.pLocal.WpData.SwingData = swingData --save values
    end
    G.pLocal.WpData.CurrWeapon = currWeapon --save values
    return true
end

local maxTick = Conversion.Time_to_Ticks(G.Gui.FakeLatencyAmount / 1000)

function Common.GetBestTarget(me)
    local bestTarget = nil
    local bestFactor = 0

    for _, player in pairs(G.Players) do
        if player == nil or not player:IsAlive()
        or player:IsDormant()
        or player == me or player:GetTeamNumber() == me:GetTeamNumber()
        or gui.GetValue("ignore cloaked") == 1 and player:InCond(4) then
            goto continue
        end

        local playerOrigin = player:GetAbsOrigin()
        local distance = (playerOrigin - G.pLocal.GetAbsOrigin):Length()

        if distance <= 770 then
            local Pviewoffset = player:GetPropVector("localdata", "m_vecViewOffset[0]")
            local Pviewpos = playerOrigin + Pviewoffset

            local angles = Math.PositionAngles(G.pLocal.GetAbsOrigin, Pviewpos)
            local fov = Math.AngleFov(G.pLocal.ViewAngles, angles)

            if fov <= Menu.Aimbot.AimbotFOV then
                local distanceFactor = Math.RemapValClamped(distance, 0, 1000, 1, 0.9)
                local fovFactor = Math.RemapValClamped(fov, 0, Menu.Aimbot.AimbotFOV, 1, 1)

                local factor = distanceFactor * fovFactor
                if factor > bestFactor then
                    bestTarget = player
                    bestFactor = factor
                end
            end
        end
        ::continue::
    end

    return bestTarget
end

-- Function to check if target is in range
function Common.checkInRange(targetPos, spherePos, sphereRadius)
    local HitboxMin = G.Target.vHitbox.Min
    local HitboxMax = G.Target.vHitbox.Max
    local TargetEntity = G.Target.entity
    --if Menu.Misc.ChargeReach and pLocalClass == 4 and chargeLeft == 100 then sphereRadius = 128 end
    local hitbox_min_trigger = G.Target.GetAbsOrigin + HitboxMin
    local hitbox_max_trigger = G.Target.GetAbsOrigin + HitboxMax

    -- Calculate the closest point on the hitbox to the sphere
    local closestPoint = Vector3(
        math.max(hitbox_min_trigger.x, math.min(spherePos.x, hitbox_max_trigger.x)),
        math.max(hitbox_min_trigger.y, math.min(spherePos.y, hitbox_max_trigger.y)),
        math.max(hitbox_min_trigger.z, math.min(spherePos.z, hitbox_max_trigger.z))
    )

    -- Calculate the distance from the closest point to the sphere center
    local distanceAlongVector = (spherePos - closestPoint):Length()

    -- Check if the target is within the sphere radius
    if sphereRadius > distanceAlongVector then
        -- Calculate the direction from spherePos to closestPoint
        local direction = Common.Normalize(closestPoint - spherePos)
        local closestPointLine = spherePos + direction * G.pLocal.WeaponsData.MeleeWeapon.SwingData.TotalSwingRange

        if G.Menu.Misc.AdvancedHitreg then
            local trace = engine.TraceLine(spherePos, closestPointLine, MASK_SHOT_HULL)
            if trace.fraction < 1 and trace.entity == TargetEntity then
                return true, closestPoint
            else
                trace = engine.TraceHull(spherePos, closestPointLine, G.pLocal.WeaponsData.MeleeWeapon.SwingData.SwingHull.Min, G.pLocal.WeaponsData.MeleeWeapon.SwingData.SwingHull.Max, MASK_SHOT_HULL)
                if trace.fraction < 1 and trace.entity == TargetEntity then
                    return true, closestPoint
                else
                    return false, nil
                end
            end
        end

        return true, closestPoint
    else
        -- Target is not in range
        return false, nil
    end
end

--[[ Sphere cache and drawn edges cache
local sphere_cache = { vertices = {}, radius = 90, center = Vector3(0, 0, 0) }
local drawnEdges = {}

local function setup_sphere(center, radius, segments)
    sphere_cache.center = center
    sphere_cache.radius = radius
    sphere_cache.segments = segments
    sphere_cache.vertices = {}  -- Clear the old vertices

    local thetaStep = math.pi / segments
    local phiStep = 2 * math.pi / segments

    for i = 0, segments - 1 do
        local theta1 = thetaStep * i
        local theta2 = thetaStep * (i + 1)

        for j = 0, segments - 1 do
            local phi1 = phiStep * j
            local phi2 = phiStep * (j + 1)

            -- Generate a square for each segment
            table.insert(sphere_cache.vertices, {
                Vector3(math.sin(theta1) * math.cos(phi1), math.sin(theta1) * math.sin(phi1), math.cos(theta1)),
                Vector3(math.sin(theta1) * math.cos(phi2), math.sin(theta1) * math.sin(phi2), math.cos(theta1)),
                Vector3(math.sin(theta2) * math.cos(phi2), math.sin(theta2) * math.sin(phi2), math.cos(theta2)),
                Vector3(math.sin(theta2) * math.cos(phi1), math.sin(theta2) * math.sin(phi1), math.cos(theta2))
            })
        end
    end
end]]

function Common.L_line(start_pos, end_pos, secondary_line_size)
    if not (start_pos and end_pos) then
        return
    end
    local direction = end_pos - start_pos
    local direction_length = direction:Length()
    if direction_length == 0 then
        return
    end
    local normalized_direction = Common.Normalize(direction)
    local perpendicular = Vector3(normalized_direction.y, -normalized_direction.x, 0) * secondary_line_size
    local w2s_start_pos = client.WorldToScreen(start_pos)
    local w2s_end_pos = client.WorldToScreen(end_pos)
    if not (w2s_start_pos and w2s_end_pos) then
        return
    end
    local secondary_line_end_pos = start_pos + perpendicular
    local w2s_secondary_line_end_pos = client.WorldToScreen(secondary_line_end_pos)
    if w2s_secondary_line_end_pos then
        draw.Line(w2s_start_pos[1], w2s_start_pos[2], w2s_end_pos[1], w2s_end_pos[2])
        draw.Line(w2s_start_pos[1], w2s_start_pos[2], w2s_secondary_line_end_pos[1], w2s_secondary_line_end_pos[2])
    end
end

function Common.arrowPathArrow2(startPos, endPos, width)
    if not (startPos and endPos) then return nil, nil end

    local direction = endPos - startPos
    local length = direction:Length()
    if length == 0 then return nil, nil end
    direction = Common.Normalize(direction)

    local perpDir = Vector3(-direction.y, direction.x, 0)
    local leftBase = startPos + perpDir * width
    local rightBase = startPos - perpDir * width

    local screenStartPos = client.WorldToScreen(startPos)
    local screenEndPos = client.WorldToScreen(endPos)
    local screenLeftBase = client.WorldToScreen(leftBase)
    local screenRightBase = client.WorldToScreen(rightBase)

    if screenStartPos and screenEndPos and screenLeftBase and screenRightBase then
        draw.Line(screenStartPos[1], screenStartPos[2], screenEndPos[1], screenEndPos[2])
        draw.Line(screenLeftBase[1], screenLeftBase[2], screenEndPos[1], screenEndPos[2])
        draw.Line(screenRightBase[1], screenRightBase[2], screenEndPos[1], screenEndPos[2])
    end

    return leftBase, rightBase
end

function Common.arrowPathArrow(startPos, endPos, arrowWidth)
    if not startPos or not endPos then return end

    local direction = endPos - startPos
    if direction:Length() == 0 then return end

    -- Normalize the direction vector and calculate perpendicular direction
    direction = Common.Normalize(direction)
    local perpendicular = Vector3(-direction.y, direction.x, 0) * arrowWidth

    -- Calculate points for arrow fins
    local finPoint1 = startPos + perpendicular
    local finPoint2 = startPos - perpendicular

    -- Convert world positions to screen positions
    local screenStartPos = client.WorldToScreen(startPos)
    local screenEndPos = client.WorldToScreen(endPos)
    local screenFinPoint1 = client.WorldToScreen(finPoint1)
    local screenFinPoint2 = client.WorldToScreen(finPoint2)

    -- Draw the arrow
    if screenStartPos and screenEndPos then
        draw.Line(screenEndPos[1], screenEndPos[2], screenFinPoint1[1], screenFinPoint1[2])
        draw.Line(screenEndPos[1], screenEndPos[2], screenFinPoint2[1], screenFinPoint2[2])
        draw.Line(screenFinPoint1[1], screenFinPoint1[2], screenFinPoint2[1], screenFinPoint2[2])
    end
end

function Common.drawPavement(startPos, endPos, width)
    if not (startPos and endPos) then return nil end

    local direction = endPos - startPos
    local length = direction:Length()
    if length == 0 then return nil end
    direction = Common.Normalize(direction)

    -- Calculate perpendicular direction for the width
    local perpDir = Vector3(-direction.y, direction.x, 0)

    -- Calculate left and right base points of the pavement
    local leftBase = startPos + perpDir * width
    local rightBase = startPos - perpDir * width

    -- Convert positions to screen coordinates
    local screenStartPos = client.WorldToScreen(startPos)
    local screenEndPos = client.WorldToScreen(endPos)
    local screenLeftBase = client.WorldToScreen(leftBase)
    local screenRightBase = client.WorldToScreen(rightBase)

    -- Draw the pavement
    if screenStartPos and screenEndPos and screenLeftBase and screenRightBase then
        draw.Line(screenStartPos[1], screenStartPos[2], screenEndPos[1], screenEndPos[2])
        draw.Line(screenStartPos[1], screenStartPos[2], screenLeftBase[1], screenLeftBase[2])
        draw.Line(screenStartPos[1], screenStartPos[2], screenRightBase[1], screenRightBase[2])
    end

    return leftBase, rightBase
end


-- Call setup_sphere once at the start of your program
--setup_sphere(Vector3(0, 0, 0), 90, 7)

local white_texture = draw.CreateTextureRGBA(string.char(
	0xff, 0xff, 0xff, 25,
	0xff, 0xff, 0xff, 25,
	0xff, 0xff, 0xff, 25,
	0xff, 0xff, 0xff, 25
), 2, 2);

--[[local drawPolygon = (function()
	local v1x, v1y = 0, 0;
	local function cross(a, b)
		return (b[1] - a[1]) * (v1y - a[2]) - (b[2] - a[2]) * (v1x - a[1])
	end

	local TexturedPolygon = draw.TexturedPolygon;

	return function(vertices)
		local cords, reverse_cords = {}, {};
		local sizeof = #vertices;
		local sum = 0;

		v1x, v1y = vertices[1][1], vertices[1][2];
		for i, pos in pairs(vertices) do
			local convertedTbl = {pos[1], pos[2], 0, 0};

			cords[i], reverse_cords[sizeof - i + 1] = convertedTbl, convertedTbl;

			sum = sum + cross(pos, vertices[(i % sizeof) + 1]);
		end


		TexturedPolygon(white_texture, (sum < 0) and reverse_cords or cords, true)
	end
end)();]]

return Common