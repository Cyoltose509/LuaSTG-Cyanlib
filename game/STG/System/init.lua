---@class STG.System
---@field Time STG.System.Time @适用于STG的计时器，该计时器不使用真正的Delta，因此不受帧率影响。而且为1/60秒为一个单位
---@field Score STG.System.Score @计分与成绩系统
---@field Config STG.System.Config @游戏配置管理
local M = {}
STG.System = M

require("STG.System.Time")
require("STG.System.Score")
require("STG.System.Config")

-- ========================================
-- Score 全局单例
-- ========================================

---@type STG.System.Score
M._score = STG.System.Score()

---获取全局 Score 实例
---@return STG.System.Score
function M.GetScore()
    return M._score
end

---重置 Score（新游戏开始时调用）
function M.ResetScore()
    M._score:reset()
end
