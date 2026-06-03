---@class STG.Data.Score
local M = {}
STG.Data.Score = M

local Event = STG.Event

---@class STG.Data.Score.Entry
---@field score number
---@field graze number
---@field date string
---@field character string

---@type table<string, table<string, table<number, STG.Data.Score.Entry>>>
local scores = {}
local scoredata = Core.Data.Score.Get()
scoredata.scores = scores

---Record a score for a given character, difficulty, and stage.
---Only saves if it's higher than the existing high score.
---@param character string
---@param difficulty string
---@param stage number
---@param entry STG.Data.Score.Entry
---@return boolean is_new_high_score
function M.RecordScore(character, difficulty, stage, entry)
    difficulty = difficulty or "NORMAL"
    character = character or "default"
    stage = stage or 1

    scores[character] = scores[character] or {}
    scores[character][difficulty] = scores[character][difficulty] or {}

    local current = scores[character][difficulty][stage]
    local new_score = (entry and entry.score) or 0
    local old_score = current and current.score or 0

    if new_score > old_score then
        entry.date = entry.date or os.date("%Y-%m-%dT%H:%M:%S")
        scores[character][difficulty][stage] = entry
        return true
    end
    return false
end

---Get the high score entry.
---@param character string
---@param difficulty string
---@param stage number
---@return STG.Data.Score.Entry|nil
function M.GetHighScore(character, difficulty, stage)
    local c = scores[character or "default"]
    if not c then
        return nil
    end
    local d = c[difficulty or "NORMAL"]
    if not d then
        return nil
    end
    return d[stage or 1]
end

---Get all scores for a character/difficulty.
---@param character string
---@param difficulty string
---@return table<number, STG.Data.Score.Entry>
function M.GetAllScores(character, difficulty)
    local c = scores[character or "default"]
    if not c then
        return {}
    end
    return c[difficulty or "NORMAL"] or {}
end

---Get total score across all stages.
---@param character string
---@param difficulty string
---@return number
function M.GetTotalScore(character, difficulty)
    local all = M.GetAllScores(character, difficulty)
    local total = 0
    for _, entry in pairs(all) do
        total = total + (entry.score or 0)
    end
    return total
end
