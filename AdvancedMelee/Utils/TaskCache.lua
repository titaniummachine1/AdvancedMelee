local TaskCache = {}
TaskCache.entries = {}

--- Executes a task or returns cached results if called too frequently.
--- @param id string A unique identifier for the task.
--- @param func function The function to execute.
--- @param args table The arguments for the function.
function TaskCache.Execute(func, args, id, cooldown)
    local currentTime = globals.TickCount()
    local entry = TaskCache.entries[id]
    cooldown = cooldown or 1

    -- If entry is new or cooldown has passed, execute and cache the result.
    if not entry or currentTime - entry.lastExecuted >= cooldown then
        local result = {func(table.unpack(args))}

        -- Update entries with new execution time and result.
        TaskCache.entries[id] = {
            lastExecuted = currentTime,
            result = result
        }

        return table.unpack(result)
    else
        -- Return cached result if within cooldown period.
        return table.unpack(entry.result)
    end
end

return TaskCache