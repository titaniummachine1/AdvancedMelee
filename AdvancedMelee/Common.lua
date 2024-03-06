---@class Common
local Common = {}
local Globals = require("AdvancedMelee.Globals")
local Menu = Globals.Menu

---@type boolean, LNXlib
libLoaded, Lib = pcall(require, "LNXlib")
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
    local NextAttackTime = Globals.pLocal.Actions.NextAttackTime
    --return (nextPrimaryAttack <= globals.CurTime()) and (nextAttack <= globals.CurTime())
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

--local fFalse = function () return false end

-- [WIP] Predict the position of a player
---@param player WPlayer
---@param t integer
---@param d number?
---@param shouldHitEntity fun(entity: WEntity, contentsMask: integer): boolean?
---@return { pos : Vector3[], vel: Vector3[], onGround: boolean[] }?
function Common.PredictPlayer(player, t, d)
        if not Globals.World.Gravity or not Globals.World.StepHeight then return nil end
        local vUp = Vector3(0, 0, 1)
        local vStep = Vector3(0, 0, Globals.World.StepHeight)
        local shouldHitEntity = function(entity) return entity:GetName() ~= player:GetName() end --trace ignore simulated player 
        local pFlags = player:GetPropInt("m_fFlags")
        local OnGround = pFlags & FL_ONGROUND == 1
        local vHitbox = Globals.pLocal.vHitbox and player == Globals.pLocal.entity
        or Globals.vTarget.vHitbox 
        or Globals.Defaults.vHitbox
        local pLocal = Globals.pLocal.entity
        local pLocalIndex = Globals.pLocal.index

        -- Add the current record
        local _out = {
            pos = { [0] = player:GetAbsOrigin() },
            vel = { [0] = player:EstimateAbsVelocity() },
            onGround = { [0] = OnGround }
        }

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
            if not onGround1 then downStep = Vector3() end

            -- Ground collision
            local groundTrace = engine.TraceHull(pos + vStep, pos - downStep, vHitbox.Min, vHitbox.Max, MASK_PLAYERSOLID_BRUSHONLY, shouldHitEntity)
            if groundTrace.fraction < 1 then
                -- We'll hit the ground
                local normal = groundTrace.plane
                local angle = math.deg(math.acos(normal:Dot(vUp)))

                -- Check the ground angle
                if angle < 45 then
                    if onGround1 and player:GetIndex() == pLocalIndex and gui.GetValue("Bunny Hop") == 1 and input.IsButtonDown(KEY_SPACE) then
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
                vel.z = vel.z - Globals.World.Gravity * globals.TickInterval()
            end

            -- Add the prediction record
            _out.pos[i], _out.vel[i], _out.onGround[i] = pos, vel, onGround1
        end

        return _out
end

local maxTick = Conversion.Time_to_Ticks(Globals.Gui.FakeLatencyAmount / 1000)

function Common.GetBestTarget(me)
    local bestTarget = nil
    local bestFactor = 0

    for _, player in pairs(Globals.Players) do
        if player == nil or not player:IsAlive()
        or player:IsDormant()
        or player == me or player:GetTeamNumber() == me:GetTeamNumber()
        or gui.GetValue("ignore cloaked") == 1 and player:InCond(4) then
            goto continue
        end

        local numBacktrackTicks = gui.GetValue("Fake Latency") == 1 and maxTick or gui.GetValue("Fake Latency") == 0 and gui.GetValue("Backtrack") == 1 and 4 or 0

        if numBacktrackTicks ~= 0 then
            local playerIndex = player:GetIndex()
            playerTicks[playerIndex] = playerTicks[playerIndex] or {}
            table.insert(playerTicks[playerIndex], player:GetAbsOrigin())

            if #playerTicks[playerIndex] > numBacktrackTicks then
                table.remove(playerTicks[playerIndex], 1)
            end
        end

        local playerOrigin = player:GetAbsOrigin()
        local distance = (playerOrigin - Globals.pLocal.GetAbsOrigin):Length()

        if distance <= 770 then
            local Pviewoffset = player:GetPropVector("localdata", "m_vecViewOffset[0]")
            local Pviewpos = playerOrigin + Pviewoffset

            local angles = Math.PositionAngles(Globals.pLocal.GetAbsOrigin, Pviewpos)
            local fov = Math.AngleFov(Globals.pLocal.ViewAngles, angles)

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
    local HitboxMin = Globals.vTarget.vHitbox.Min
    local HitboxMax = Globals.vTarget.vHitbox.Max
    local TargetEntity = Globals.vTarget.entity
    --if Menu.Misc.ChargeReach and pLocalClass == 4 and chargeLeft == 100 then sphereRadius = 128 end
    local hitbox_min_trigger = Globals.vTarget.GetAbsOrigin + HitboxMin
    local hitbox_max_trigger = Globals.vTarget.GetAbsOrigin + HitboxMax

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
        local closestPointLine = spherePos + direction * Globals.pLocal.SwingData.SwingRange

        if Globals.Menu.Misc.AdvancedHitreg then
            if sphereRadius > distanceAlongVector - Globals.pLocal.SwingData.SwingHullSize then --if trace line is needed
 
                local trace = engine.TraceLine(spherePos, closestPointLine, MASK_SHOT_HULL)
                if trace.fraction < 1 and trace.entity == TargetEntity then
                    return true, closestPoint
                else
                    trace = engine.TraceHull(spherePos, closestPointLine, Globals.SwingData.SwingHull.Min, Globals.SwingData.SwingHull.Max, MASK_SHOT_HULL)
                    if trace.fraction < 1 and trace.entity == TargetEntity then
                        return true, closestPoint
                    else
                        return false, nil
                    end
                end
            else
                local trace = engine.TraceHull(spherePos,  closestPointLine, HitboxMin, HitboxMax, MASK_SHOT_HULL)
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

function Common.CalcStrafe()
    local autostrafe = gui.GetValue("Auto Strafe")
    local flags = Globals.pLocal.entity:GetPropInt("m_fFlags")
    local OnGround = flags & FL_ONGROUND == 1

    for idx, entity in ipairs(Globals.Players) do
        local entityIndex = entity:GetIndex()

        if not entity or not entity:IsValid() and entity:IsDormant() or not entity:IsAlive() then
            Globals.StrafeData.lastAngles[entityIndex] = nil
            Globals.StrafeData.lastDeltas[entityIndex] = nil
            Globals.StrafeData.avgDeltas[entityIndex] = nil
            Globals.StrafeData.strafeAngles[entityIndex] = nil
            Globals.StrafeData.inaccuracy[entityIndex] = nil
            goto continue
        end

        local v = entity:EstimateAbsVelocity()
        if entity == Globals.pLocal.entity then
            table.insert(Globals.StrafeData.pastPositions, 1, entity:GetAbsOrigin())
            if #Globals.StrafeData.pastPositions > Globals.StrafeData.maxPositions then
                table.remove(Globals.StrafeData.pastPositions)
            end

            if not onGround and autostrafe == 2 and #Globals.StrafeData.pastPositions >= Globals.StrafeData.maxPositions then
                v = Vector3(0, 0, 0)
                for i = 1, #Globals.StrafeData.pastPositions - 1 do
                    v = v + (Globals.StrafeData.pastPositions[i] - Globals.StrafeData.pastPositions[i + 1])
                end
                v = v / (Globals.StrafeData.maxPositions - 1)
            else
                v = entity:EstimateAbsVelocity()
            end
        end

        local angle = v:Angles()

        if Globals.StrafeData.lastAngles[entityIndex] == nil then
            Globals.StrafeData.lastAngles[entityIndex] = angle
            goto continue
        end

        local delta = angle.y - Globals.StrafeData.lastAngles[entityIndex].y

        -- Calculate the average delta using exponential smoothing
        local smoothingFactor = 0.2
        local avgDelta = (Globals.StrafeData.lastDeltas[entityIndex] or delta) * (1 - smoothingFactor) + delta * smoothingFactor

        -- Save the average delta
        Globals.StrafeData.avgDeltas[entityIndex] = avgDelta

        local vector1 = Vector3(1, 0, 0)
        local vector2 = Vector3(1, 0, 0)

        -- Apply deviation
        local ang1 = vector1:Angles()
        ang1.y = ang1.y + (Globals.StrafeData.lastDeltas[entityIndex] or delta)
        vector1 = ang1:Forward() * vector1:Length()

        local ang2 = vector2:Angles()
        ang2.y = ang2.y + avgDelta
        vector2 = ang2:Forward() * vector2:Length()

        -- Calculate the distance between the two vectors
        local distance = (vector1 - vector2):Length()

        -- Save the strafe angle
        Globals.StrafeData.strafeAngles[entityIndex] = avgDelta

        -- Calculate the inaccuracy as the distance between the two vectors
        Globals.StrafeData.inaccuracy[entityIndex] = distance

        -- Save the last delta
        Globals.StrafeData.lastDeltas[entityIndex] = delta

        Globals.StrafeData.lastAngles[entityIndex] = angle

        ::continue::
    end
end

return Common