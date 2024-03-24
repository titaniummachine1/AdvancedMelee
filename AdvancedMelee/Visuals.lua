--[[ Imports ]]
local Common = require("AdvancedMelee.Common")
local G = require("AdvancedMelee.Globals")
local Visuals = {}

local tahoma_bold = draw.CreateFont("Tahoma", 12, 800, FONTFLAG_OUTLINE)

--[[ Functions ]]
local function doDraw()
local Menu = G.Menu
if (engine.Con_IsVisible() or engine.IsGameUIVisible()) or not Menu.Visuals.EnableVisuals then return end
  -- Define local variables
local pLocal = G and G.pLocal or nil
if not pLocal then return end

local smackDelay = pLocal.WpData and pLocal.WpData.SwingData and pLocal.WpData.SwingData.SmackDelay or 13
local pLocalOrigin = pLocal.GetAbsOrigin
local pLocalPath = pLocal.PredData.pos -- Predicted positions
local pLocalFuture = pLocalPath[smackDelay] -- The last tick of the predicted positions
local pWeapon = pLocal.WpData and pLocal.WpData.CurrWeapon and pLocal.WpData.CurrWeapon.Weapon or nil
local pLocalClass = pLocal.Class
local chargeLeft = pLocal.ChargeLeft

if pWeapon and pWeapon:IsMeleeWeapon() and pLocal.entity and pLocal.entity:IsAlive() then
    draw.Color( 255, 255, 255, 255 )
    local w, h = draw.GetScreenSize()
    if Menu and Menu.Visuals and Menu.Visuals.Local and Menu.Visuals.Local.RangeCircle == true and pLocalFuture then
        local center = pLocalFuture -- Center of the circle at the player's feet
        local viewPos = pLocalFuture + Vector3(0,0,G and G.pLocal and G.pLocal.Viewheight or 0)-- View position to shoot traces from
        local radius = (Menu and Menu.Misc and Menu.Misc.ChargeReach and pLocalClass == 4 and chargeLeft == 100 and G and G.Static and G.Static.ChargeReach) or G.pLocal.WpData.SwingData.TotalSwingRange or G.Static.DefaultSwingRange + G.Static.HalfHullSize or 66
        local segments = 32 -- Number of segments to draw the circle
        local angleStep = (2 * math.pi) / segments
        -- Determine the color of the circle based on TargetPlayer
        local circleColor
        if Target then
            circleColor = {10, 255, 0, 255} -- Green if TargetPlayer exists
        else
            circleColor = {255, 255, 255, 255} -- White otherwise
        end

        draw.Color(table.unpack(circleColor))

        local vertices = {} -- Table to store adjusted vertices

        -- Calculate vertices and adjust based on trace results
        for i = 1, segments do
            local angle = angleStep * i
            local circlePoint = center + Vector3(math.cos(angle), math.sin(angle), 0) * radius

            local trace = engine.TraceLine(viewPos, circlePoint, MASK_SHOT_HULL) --engine.TraceHull(viewPos, circlePoint, vHitbox[1], vHitbox[2], MASK_SHOT_HULL)
            local endPoint = trace and trace.fraction < 1.0 and trace.endpos or circlePoint

            vertices[i] = client.WorldToScreen(endPoint)
        end

        -- Draw the circle using adjusted vertices
        for i = 1, segments do
            local j = (i % segments) + 1 -- Wrap around to the first vertex after the last one
            if vertices[i] and vertices[j] then
                draw.Line(vertices[i][1], vertices[i][2], vertices[j][1], vertices[j][2])
            end
        end
    end
    local Target = G.Target.entity
    if Target then
        local vPlayerPath = G.Target.PredTicks -- Predicted positions
        local vPlayerFuture = vPlayerPath[smackDelay] -- The last tick of the predicted positions
    end
            if Menu.Visuals.Local.path.enable and pLocalFuture then
                local style = Menu.Visuals.Local.path.Style
                local width1 = Menu.Visuals.Local.path.width
                if style == 1 then
                    local lastLeftBaseScreen, lastRightBaseScreen = nil, nil
                    -- Pavement Style
                    for i = 1, #pLocalPath - 1 do
                        local startPos = pLocalPath[i]
                        local endPos = pLocalPath[i + 1]

                        if startPos and endPos then
                            local leftBase, rightBase = Common.drawPavement(startPos, endPos, width1)

                            if leftBase and rightBase then
                                local screenLeftBase = client.WorldToScreen(leftBase)
                                local screenRightBase = client.WorldToScreen(rightBase)

                                if screenLeftBase and screenRightBase then
                                    if lastLeftBaseScreen and lastRightBaseScreen then
                                        draw.Line(lastLeftBaseScreen[1], lastLeftBaseScreen[2], screenLeftBase[1], screenLeftBase[2])
                                        draw.Line(lastRightBaseScreen[1], lastRightBaseScreen[2], screenRightBase[1], screenRightBase[2])
                                    end

                                    lastLeftBaseScreen = screenLeftBase
                                    lastRightBaseScreen = screenRightBase
                                end
                            end
                        end
                    end

                    -- Draw the final line segment
                    if lastLeftBaseScreen and lastRightBaseScreen and #pLocalPath > 0 then
                        local finalPos = pLocalPath[#pLocalPath]
                        local screenFinalPos = client.WorldToScreen(finalPos)

                        if screenFinalPos then
                            draw.Line(lastLeftBaseScreen[1], lastLeftBaseScreen[2], screenFinalPos[1], screenFinalPos[2])
                            draw.Line(lastRightBaseScreen[1], lastRightBaseScreen[2], screenFinalPos[1], screenFinalPos[2])
                        end
                    end
                elseif style == 2 then
                    local lastLeftBaseScreen, lastRightBaseScreen = nil, nil

                    -- Start from the second element (i = 2)
                    for i = 2, #pLocalPath - 1 do
                        local startPos = pLocalPath[i]
                        local endPos = pLocalPath[i + 1]

                        if startPos and endPos then
                            local leftBase, rightBase = Common.arrowPathArrow2(startPos, endPos, width1)

                            if leftBase and rightBase then
                                local screenLeftBase = client.WorldToScreen(leftBase)
                                local screenRightBase = client.WorldToScreen(rightBase)

                                if screenLeftBase and screenRightBase then
                                    if lastLeftBaseScreen and lastRightBaseScreen then
                                        draw.Line(lastLeftBaseScreen[1], lastLeftBaseScreen[2], screenLeftBase[1], screenLeftBase[2])
                                        draw.Line(lastRightBaseScreen[1], lastRightBaseScreen[2], screenRightBase[1], screenRightBase[2])
                                    end

                                    lastLeftBaseScreen = screenLeftBase
                                    lastRightBaseScreen = screenRightBase
                                end
                            end
                        end
                    end

                elseif style == 3 then
                    -- Arrows Style
                     for i = 1, #pLocalPath - 1 do
                        local startPos = pLocalPath[i]
                        local endPos = pLocalPath[i + 1]

                        if startPos and endPos then
                            Common.arrowPathArrow(startPos, endPos, width1)
                        end
                    end
                elseif style == 4 then
                    -- L Line Style
                    for i = 1, #pLocalPath - 1 do
                        local pos1 = pLocalPath[i]
                        local pos2 = pLocalPath[i + 1]

                        if pos1 and pos2 then
                            Common.L_line(pos1, pos2, width1)  -- Adjust the size for the perpendicular segment as needed
                        end
                    end
                elseif style == 5 then
                    -- Draw a dashed line for pLocalPath
                    for i = 1, #pLocalPath - 1 do
                        local pos1 = pLocalPath[i]
                        local pos2 = pLocalPath[i + 1]

                        local screenPos1 = client.WorldToScreen(pos1)
                        local screenPos2 = client.WorldToScreen(pos2)

                        if screenPos1 ~= nil and screenPos2 ~= nil and i % 2 == 1 then
                            draw.Line(screenPos1[1], screenPos1[2], screenPos2[1], screenPos2[2])
                        end
                    end
                elseif style == 6 then
                    -- Draw a dashed line for pLocalPath
                    for i = 1, #pLocalPath - 1 do
                        local pos1 = pLocalPath[i]
                        local pos2 = pLocalPath[i + 1]
    
                        local screenPos1 = client.WorldToScreen(pos1)
                        local screenPos2 = client.WorldToScreen(pos2)
    
                        if screenPos1 ~= nil and screenPos2 ~= nil then
                            draw.Line(screenPos1[1], screenPos1[2], screenPos2[1], screenPos2[2])
                        end
                    end
                end
            end
---------------------------------------------------------sphere
                --[[if Menu.Visuals.Sphere then
                    -- Function to draw the sphere
                    local function draw_sphere()
                        local playerYaw = engine.GetViewAngles().yaw
                        local cos_yaw = math.cos(math.rad(playerYaw))
                        local sin_yaw = math.sin(math.rad(playerYaw))

                        local playerForward = Vector3(-cos_yaw, -sin_yaw, 0)  -- Forward vector based on player's yaw

                        for _, vertex in ipairs(sphere_cache.vertices) do
                            local rotated_vertex1 = Vector3(-vertex[1].x * cos_yaw + vertex[1].y * sin_yaw, -vertex[1].x * sin_yaw - vertex[1].y * cos_yaw, vertex[1].z)
                            local rotated_vertex2 = Vector3(-vertex[2].x * cos_yaw + vertex[2].y * sin_yaw, -vertex[2].x * sin_yaw - vertex[2].y * cos_yaw, vertex[2].z)
                            local rotated_vertex3 = Vector3(-vertex[3].x * cos_yaw + vertex[3].y * sin_yaw, -vertex[3].x * sin_yaw - vertex[3].y * cos_yaw, vertex[3].z)
                            local rotated_vertex4 = Vector3(-vertex[4].x * cos_yaw + vertex[4].y * sin_yaw, -vertex[4].x * sin_yaw - vertex[4].y * cos_yaw, vertex[4].z)

                            local worldPos1 = sphere_cache.center + rotated_vertex1 * sphere_cache.radius
                            local worldPos2 = sphere_cache.center + rotated_vertex2 * sphere_cache.radius
                            local worldPos3 = sphere_cache.center + rotated_vertex3 * sphere_cache.radius
                            local worldPos4 = sphere_cache.center + rotated_vertex4 * sphere_cache.radius

                            -- Trace from the center to the vertices with a hull size of 18x18
                            local hullSize = Vector3(18, 18, 18)
                            local trace1 = engine.TraceHull(sphere_cache.center, worldPos1, -hullSize, hullSize, MASK_SHOT_HULL)
                            local trace2 = engine.TraceHull(sphere_cache.center, worldPos2, -hullSize, hullSize, MASK_SHOT_HULL)
                            local trace3 = engine.TraceHull(sphere_cache.center, worldPos3, -hullSize, hullSize, MASK_SHOT_HULL)
                            local trace4 = engine.TraceHull(sphere_cache.center, worldPos4, -hullSize, hullSize, MASK_SHOT_HULL)

                            local endPos1 = trace1.fraction < 1.0 and trace1.endpos or worldPos1
                            local endPos2 = trace2.fraction < 1.0 and trace2.endpos or worldPos2
                            local endPos3 = trace3.fraction < 1.0 and trace3.endpos or worldPos3
                            local endPos4 = trace4.fraction < 1.0 and trace4.endpos or worldPos4

                            local screenPos1 = client.WorldToScreen(endPos1)
                            local screenPos2 = client.WorldToScreen(endPos2)
                            local screenPos3 = client.WorldToScreen(endPos3)
                            local screenPos4 = client.WorldToScreen(endPos4)

                            -- Calculate normal vector of the square
                            local normal = Normalize(rotated_vertex2 - rotated_vertex1):Cross(rotated_vertex3 - rotated_vertex1)

                            -- Draw square only if its normal faces towards the player
                            if normal:Dot(playerForward) > 0.1 then
                                if screenPos1 and screenPos2 and screenPos3 and screenPos4 then
                                    -- Draw the square
                                    drawPolygon({screenPos1, screenPos2, screenPos3, screenPos4})

                                    -- Optionally, draw lines between the vertices of the square for wireframe visualization
                                    draw.Color(255, 255, 255, 25) -- Set color and alpha for lines
                                    draw.Line(screenPos1[1], screenPos1[2], screenPos2[1], screenPos2[2])
                                    draw.Line(screenPos2[1], screenPos2[2], screenPos3[1], screenPos3[2])
                                    draw.Line(screenPos3[1], screenPos3[2], screenPos4[1], screenPos4[2])
                                    draw.Line(screenPos4[1], screenPos4[2], screenPos1[1], screenPos1[2])
                                end
                            end
                        end
                    end

                    -- Example draw call
                    sphere_cache.center = pLocalOrigin  -- Replace with actual player origin
                    sphere_cache.radius = swingrange    -- Replace with actual swing range value
                    draw_sphere()
                end]]

                    -- enemy
                    if Target and G.Target.PredTicks then
                        local vPlayerPath =  G.Target.PredTicks

                        -- Draw lines between the predicted positions
                        if Menu.Visuals.Target.path.enable then
                            local style = Menu.Visuals.Target.path.Style
                            local width = Menu.Visuals.Target.path.width

                            if style == 1 then
                                local lastLeftBaseScreen, lastRightBaseScreen = nil, nil
                                -- Pavement Style
                                for i = 1, #vPlayerPath - 1 do
                                    local startPos = vPlayerPath[i]
                                    local endPos = vPlayerPath[i + 1]

                                    if startPos and endPos then
                                        local leftBase, rightBase = Common.drawPavement(startPos, endPos, width)
 
                                        if leftBase and rightBase then
                                            local screenLeftBase = client.WorldToScreen(leftBase)
                                            local screenRightBase = client.WorldToScreen(rightBase)

                                            if screenLeftBase and screenRightBase then
                                                if lastLeftBaseScreen and lastRightBaseScreen then
                                                    draw.Line(lastLeftBaseScreen[1], lastLeftBaseScreen[2], screenLeftBase[1], screenLeftBase[2])
                                                    draw.Line(lastRightBaseScreen[1], lastRightBaseScreen[2], screenRightBase[1], screenRightBase[2])
                                                end

                                                lastLeftBaseScreen = screenLeftBase
                                                lastRightBaseScreen = screenRightBase
                                            end
                                        end
                                    end
                                end

                                -- Draw the final line segment
                                if lastLeftBaseScreen and lastRightBaseScreen and #vPlayerPath > 0 then
                                    local finalPos = vPlayerPath[#vPlayerPath]
                                    local screenFinalPos = client.WorldToScreen(finalPos)

                                    if screenFinalPos then
                                        draw.Line(lastLeftBaseScreen[1], lastLeftBaseScreen[2], screenFinalPos[1], screenFinalPos[2])
                                        draw.Line(lastRightBaseScreen[1], lastRightBaseScreen[2], screenFinalPos[1], screenFinalPos[2])
                                    end
                                end
                            elseif style == 2 then
                                local lastLeftBaseScreen, lastRightBaseScreen = nil, nil

                                -- Start from the second element (i = 2)
                                for i = 2, #vPlayerPath - 1 do
                                    local startPos = vPlayerPath[i]
                                    local endPos = vPlayerPath[i + 1]

                                    if startPos and endPos then
                                        local leftBase, rightBase =  Common.arrowPathArrow2(startPos, endPos, width)

                                        if leftBase and rightBase then
                                            local screenLeftBase = client.WorldToScreen(leftBase)
                                            local screenRightBase = client.WorldToScreen(rightBase)

                                            if screenLeftBase and screenRightBase then
                                                if lastLeftBaseScreen and lastRightBaseScreen then
                                                    draw.Line(lastLeftBaseScreen[1], lastLeftBaseScreen[2], screenLeftBase[1], screenLeftBase[2])
                                                    draw.Line(lastRightBaseScreen[1], lastRightBaseScreen[2], screenRightBase[1], screenRightBase[2])
                                                end

                                                lastLeftBaseScreen = screenLeftBase
                                                lastRightBaseScreen = screenRightBase
                                            end
                                        end
                                    end
                                end

                            elseif style == 3 then
                                -- Arrows Style
                                 for i = 1, #vPlayerPath - 1 do
                                    local startPos = vPlayerPath[i]
                                    local endPos = vPlayerPath[i + 1]

                                    if startPos and endPos then
                                        Common.arrowPathArrow(startPos, endPos, width)
                                    end
                                end
                            elseif style == 4 then
                                -- L Line Style
                                for i = 1, #vPlayerPath - 1 do
                                    local pos1 = vPlayerPath[i]
                                    local pos2 = vPlayerPath[i + 1]

                                    if pos1 and pos2 then
                                        Common.L_line(pos1, pos2, width)  -- Adjust the size for the perpendicular segment as needed
                                    end
                                end
                            elseif style == 5 then
                                -- Draw a dashed line for vPlayerPath
                                for i = 1, #vPlayerPath - 1 do
                                    local pos1 = vPlayerPath[i]
                                    local pos2 = vPlayerPath[i + 1]

                                    local screenPos1 = client.WorldToScreen(pos1)
                                    local screenPos2 = client.WorldToScreen(pos2)

                                    if screenPos1 ~= nil and screenPos2 ~= nil and i % 2 == 1 then
                                        draw.Line(screenPos1[1], screenPos1[2], screenPos2[1], screenPos2[2])
                                    end
                                end
                            elseif style == 6 then
                                -- Draw a dashed line for vPlayerPath
                                for i = 1, #vPlayerPath - 1 do
                                    local pos1 = vPlayerPath[i]
                                    local pos2 = vPlayerPath[i + 1]

                                    local screenPos1 = client.WorldToScreen(pos1)
                                    local screenPos2 = client.WorldToScreen(pos2)

                                    if screenPos1 ~= nil and screenPos2 ~= nil then
                                        draw.Line(screenPos1[1], screenPos1[2], screenPos2[1], screenPos2[2])
                                    end
                                end
                            end
                        end

                        --[[if aimposVis then
                            --draw predicted local position with strafe prediction
                            local screenPos = client.WorldToScreen(aimposVis)
                            if screenPos ~= nil then
                                draw.Line( screenPos[1] + 10, screenPos[2], screenPos[1] - 10, screenPos[2])
                                draw.Line( screenPos[1], screenPos[2] - 10, screenPos[1], screenPos[2] + 10)
                            end
                        end]]

                    if false then --hitbox draw
                        --Calculate min and max points
                        local minPoint = drawVhitbox[1]
                        local maxPoint = drawVhitbox[2]

                        -- Calculate vertices of the AABB
                        -- Assuming minPoint and maxPoint are the minimum and maximum points of the AABB:
                        local vertices = {
                            Vector3(minPoint.x, minPoint.y, minPoint.z),  -- Bottom-back-left
                            Vector3(minPoint.x, maxPoint.y, minPoint.z),  -- Bottom-front-left
                            Vector3(maxPoint.x, maxPoint.y, minPoint.z),  -- Bottom-front-right
                            Vector3(maxPoint.x, minPoint.y, minPoint.z),  -- Bottom-back-right
                            Vector3(minPoint.x, minPoint.y, maxPoint.z),  -- Top-back-left
                            Vector3(minPoint.x, maxPoint.y, maxPoint.z),  -- Top-front-left
                            Vector3(maxPoint.x, maxPoint.y, maxPoint.z),  -- Top-front-right
                            Vector3(maxPoint.x, minPoint.y, maxPoint.z)   -- Top-back-right
                        }

                        -- Convert 3D coordinates to 2D screen coordinates
                        for i, vertex in ipairs(vertices) do
                            vertices[i] = client.WorldToScreen(vertex)
                        end

                            -- Draw lines between vertices to visualize the box
                            if vertices[1] and vertices[2] and vertices[3] and vertices[4] and vertices[5] and vertices[6] and vertices[7] and vertices[8] then
                                -- Draw front face
                                draw.Line(vertices[1][1], vertices[1][2], vertices[2][1], vertices[2][2])
                                draw.Line(vertices[2][1], vertices[2][2], vertices[3][1], vertices[3][2])
                                draw.Line(vertices[3][1], vertices[3][2], vertices[4][1], vertices[4][2])
                                draw.Line(vertices[4][1], vertices[4][2], vertices[1][1], vertices[1][2])

                                -- Draw back face
                                draw.Line(vertices[5][1], vertices[5][2], vertices[6][1], vertices[6][2])
                                draw.Line(vertices[6][1], vertices[6][2], vertices[7][1], vertices[7][2])
                                draw.Line(vertices[7][1], vertices[7][2], vertices[8][1], vertices[8][2])
                                draw.Line(vertices[8][1], vertices[8][2], vertices[5][1], vertices[5][2])

                                -- Draw connecting lines
                                draw.Line(vertices[1][1], vertices[1][2], vertices[5][1], vertices[5][2])
                                draw.Line(vertices[2][1], vertices[2][2], vertices[6][1], vertices[6][2])
                                draw.Line(vertices[3][1], vertices[3][2], vertices[7][1], vertices[7][2])
                                draw.Line(vertices[4][1], vertices[4][2], vertices[8][1], vertices[8][2])
                            end
                        end
                    end
        end
end

--[[ Callbacks ]]
callbacks.Unregister("Draw", "AMVisuals_Draw")                                   -- unregister the "Draw" callback
callbacks.Register("Draw", "AMVisuals_Draw", doDraw)                              -- Register the "Draw" callback 

return Visuals