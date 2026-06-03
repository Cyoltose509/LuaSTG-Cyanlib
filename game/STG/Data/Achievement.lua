---@class STG.Data.Achievement
local M = {}
STG.Data.Achievement = M

local Event = STG.Event

---@class STG.Data.Achievement.Entry
---@field id string
---@field name string
---@field description string
---@field unlocked boolean
---@field unlock_date string|nil

---@type table<string, STG.Data.Achievement.Entry>
local achievements = {}

---Register an achievement.
---@param entry STG.Data.Achievement.Entry
function M.Register(entry)
    if not entry or not entry.id then
        return
    end
    achievements[entry.id] = entry
end

---Unlock an achievement by ID.
---@param id string
---@return boolean was_newly_unlocked
function M.Unlock(id)
    local a = achievements[id]
    if not a or a.unlocked then
        return false
    end
    a.unlocked = true
    a.unlock_date = os.date("%Y-%m-%dT%H:%M:%S")
    return true
end

---Check if an achievement is unlocked.
---@param id string
---@return boolean
function M.IsUnlocked(id)
    local a = achievements[id]
    return a and a.unlocked or false
end

---Get all achievements.
---@return table<string, STG.Data.Achievement.Entry>
function M.GetAll()
    return achievements
end

---Get count of unlocked achievements.
---@return number
function M.GetUnlockedCount()
    local count = 0
    for _, a in pairs(achievements) do
        if a.unlocked then
            count = count + 1
        end
    end
    return count
end

