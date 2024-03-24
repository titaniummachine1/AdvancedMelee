---@diagnostic disable: undefined-field
local Predict = {}

local G = require("AdvancedMelee.Globals")

function Predict.Strafe()
    local autostrafe = gui.GetValue("Auto Strafe")
    local flags = G.pLocal.entity:GetPropInt("m_fFlags")
    local OnGround = flags & FL_ONGROUND == 1

    for idx, entity in ipairs(G.Players) do
        local entityIndex = entity:GetIndex()

        if not entity or not entity:IsValid() and entity:IsDormant() or not entity:IsAlive() then
            G.StrafeData.lastAngles[entityIndex] = nil
            G.StrafeData.lastDeltas[entityIndex] = nil
            G.StrafeData.avgDeltas[entityIndex] = nil
            G.StrafeData.strafeAngles[entityIndex] = nil
            G.StrafeData.inaccuracy[entityIndex] = nil
            goto continue
        end

        local v = entity:EstimateAbsVelocity()
        if entity == G.pLocal.entity then
            table.insert(G.StrafeData.pastPositions, 1, entity:GetAbsOrigin())
            if #G.StrafeData.pastPositions > G.StrafeData.maxPositions then
                table.remove(G.StrafeData.pastPositions)
            end

            if not onGround and autostrafe == 2 and #G.StrafeData.pastPositions >= G.StrafeData.maxPositions then
                v = Vector3(0, 0, 0)
                for i = 1, #G.StrafeData.pastPositions - 1 do
                    v = v + (G.StrafeData.pastPositions[i] - G.StrafeData.pastPositions[i + 1])
                end
                v = v / (G.StrafeData.maxPositions - 1)
            else
                v = entity:EstimateAbsVelocity()
            end
        end

        local angle = v:Angles()

        if G.StrafeData.lastAngles[entityIndex] == nil then
            G.StrafeData.lastAngles[entityIndex] = angle
            goto continue
        end

        local delta = angle.y - G.StrafeData.lastAngles[entityIndex].y

        -- Calculate the average delta using exponential smoothing
        local smoothingFactor = 0.2
        local avgDelta = (G.StrafeData.lastDeltas[entityIndex] or delta) * (1 - smoothingFactor) + delta * smoothingFactor

        -- Save the average delta
        G.StrafeData.avgDeltas[entityIndex] = avgDelta

        local vector1 = Vector3(1, 0, 0)
        local vector2 = Vector3(1, 0, 0)

        -- Apply deviation
        local ang1 = vector1:Angles()
        ang1.y = ang1.y + (G.StrafeData.lastDeltas[entityIndex] or delta)
        vector1 = ang1:Forward() * vector1:Length()

        local ang2 = vector2:Angles()
        ang2.y = ang2.y + avgDelta
        vector2 = ang2:Forward() * vector2:Length()

        -- Calculate the distance between the two vectors
        local distance = (vector1 - vector2):Length()

        -- Save the strafe angle
        G.StrafeData.strafeAngles[entityIndex] = avgDelta

        -- Calculate the inaccuracy as the distance between the two vectors
        G.StrafeData.inaccuracy[entityIndex] = distance

        -- Save the last delta
        G.StrafeData.lastDeltas[entityIndex] = delta

        G.StrafeData.lastAngles[entityIndex] = angle

        ::continue::
    end
end

-- Utility function to determine if collisions with certain entities should be ignored
local function shouldIgnoreEntity(entity, player, ignoreEntities)
    for _, ignoreEntity in ipairs(ignoreEntities) do --ignore custom
        if entity:GetClass() == ignoreEntity then
            return false
        end
    end

    local pos = entity:GetAbsOrigin() + Vector3(0,0,1)
    local contents = engine.GetPointContents(pos)
    if contents ~= 0 then return true end
    if entity:GetName() == player:GetName() then return false end --ignore self
    if entity:GetTeamNumber() ~= player:GetTeamNumber() then return false end --ignore teammates
    return true
end

-- Predicts the movement of a player taking into account potential jumps
---@diagnostic disable-next-line: undefined-doc-name
---@param player Entity The player object to predict movement for
---@param t integer Number of ticks to predict into the future
---@param d number? Optional deviation to apply to the prediction angle
---@return table Predicted positions, velocities, and on-ground states
function Predict.PlayerMovement(player, t, d, cache)
    if not G.World.Gravity or not G.World.StepHeight then return {} end

    local vUp = Vector3(0, 0, 1)
    local vStep = Vector3(0, 0, G.World.StepHeight)
    local ignoreEntities = {"CTFAmmoPack", "CTFDroppedWeapon"}
    local shouldHitEntity = function(entity) return shouldIgnoreEntity(entity, player, ignoreEntities) end --trace ignore simulated player 
    local pFlags = player:GetPropInt("m_fFlags")
    local OnGround = (pFlags & FL_ONGROUND == 1)
    local vHitbox = {}
    local isPLocal = player:GetIndex() == G.pLocal.index

    if isPLocal then
        vHitbox = G.pLocal.vHitbox or G.Defaults.vHitbox
    else
        vHitbox = G.Target.vHitbox or G.Defaults.vHitbox
    end

    -- Add the current record
    local _out = {
        pos = { [0] = player:GetAbsOrigin() },
        vel = { [0] = player:EstimateAbsVelocity() },
        onGround = { [0] = OnGround }
    }

    -- Initialize starting conditions from cache or current player state
    if cache and #cache.pos > 0 then
        -- Assume cache is the last state; start from there
        _out.pos[0] = cache.pos[#cache.pos]
        _out.vel[0] = cache.vel[#cache.vel]
        _out.onGround[0] = cache.onGround[#cache.onGround]
    end

    -- Perform the prediction
    for i = 1, t do
        local lastP, lastV, lastG = _out.pos[i - 1], _out.vel[i - 1], _out.onGround[i - 1]

        local pos = lastP + lastV * globals.TickInterval()
        local vel = lastV
        local onGround1 = lastG

        -- Apply deviation
        if d then
            local ang = vel:Angles()
            ang.y = ang.y + d
            vel = ang:Forward() * vel:Length()
        end

        --[[ Forward collision ]]

        local wallTrace = engine.TraceHull(lastP + vStep, pos + vStep, vHitbox.Min, vHitbox.Max, MASK_PLAYERSOLID_BRUSHONLY, shouldHitEntity)
        --DrawLine(last.p + vStep, pos + vStep)
        if wallTrace.fraction < 1 then
            -- We'll collide
            local normal = wallTrace.plane
            local angle = math.deg(math.acos(normal:Dot(vUp)))

            -- Check the wall angle
            if angle > 55 then
                -- The wall is too steep, we'll collide
                local dot = vel:Dot(normal)
                vel = vel - normal * dot
            end

            pos.x, pos.y = wallTrace.endpos.x, wallTrace.endpos.y
        end

        --[[ Ground collision ]]

        -- Don't step down if we're in-air
        local downStep = vStep
        local simulateJump = false
        if not onGround1 then downStep = Vector3() end

        -- Ground collision
        local groundTrace = engine.TraceHull(pos + vStep, pos - downStep, vHitbox.Min, vHitbox.Max, MASK_PLAYERSOLID_BRUSHONLY, shouldHitEntity)
        if groundTrace.fraction < 1 then
            -- We'll hit the ground
            local normal = groundTrace.plane
            local angle = math.deg(math.acos(normal:Dot(vUp)))

            -- Check the ground angle
            if angle < 45 then
                if onGround1 and isPLocal and gui.GetValue("Bunny Hop") == 1 and input.IsButtonDown(KEY_SPACE) then
                    -- Jump
                    if gui.GetValue("Duck Jump") == 1 then
                        vel.z = 277
                        onGround1 = false
                    else
                        vel.z = 271
                        onGround1 = false
                    end
                else
                    pos = groundTrace.endpos
                    onGround1 = true
                end
            elseif angle < 55 then
                vel.x, vel.y, vel.z = 0, 0, 0
                onGround1 = false
            else
                local dot = vel:Dot(normal)
                    vel = vel - normal * dot
                    onGround1 = true
            end
        else
            -- We're in the air
            onGround1 = false
        end

        -- Gravity
        --local isSwimming, isWalking = checkPlayerState(player) -- todo: fix this
        if not onGround1 then
            vel.z = vel.z - G.World.Gravity * globals.TickInterval()
        end

        -- Add the prediction record
        _out.pos[i], _out.vel[i], _out.onGround[i] = pos, vel, onGround1
    end
    return _out
end

return Predict