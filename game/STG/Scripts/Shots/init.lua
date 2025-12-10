---@class STG.Shots:STG.Shots.Utils
---@field Bullet STG.Shots.Bullet
---@field Laser STG.Shots.Laser
---@field CurveLaser STG.Shots.CurveLaser
---@field Utils STG.Shots.Utils
local M = {}
STG.Shots = M

local Object = STG.Object
---颜色表
---如果是string的话则是颜色id，如果是number的话则是color索引
M.Color = {
    Core.Render.Color.AHSV(192, 0, 0.5, 0.75),
    Core.Render.Color.AHSV(192, 0, 0.5, 1), --red
    Core.Render.Color.AHSV(192, 295, 0.5, 0.75),
    Core.Render.Color.AHSV(192, 295, 0.5, 1), --purple
    Core.Render.Color.AHSV(192, 240, 0.5, 0.75),
    Core.Render.Color.AHSV(192, 240, 0.5, 1), --blue
    Core.Render.Color.AHSV(192, 189, 0.5, 0.75),
    Core.Render.Color.AHSV(192, 189, 0.5, 1), --cyan
    Core.Render.Color.AHSV(192, 113, 0.5, 0.75),
    Core.Render.Color.AHSV(192, 113, 0.5, 1), --green
    Core.Render.Color.AHSV(192, 61, 0.5, 0.75),
    Core.Render.Color.AHSV(192, 61, 0.5, 1), --yellow
    Core.Render.Color.AHSV(192, 20, 0.5, 0.75),
    Core.Render.Color.AHSV(192, 20, 0.5, 1), --orange
    Core.Render.Color.AHSV(192, 0, 0, 0.75),
    Core.Render.Color.AHSV(192, 0, 0, 1), --gray
    Red0 = 1,
    Red = 2,
    Purple0 = 3,
    Purple = 4,
    Blue0 = 5,
    Blue = 6,
    Cyan0 = 7,
    Cyan = 8,
    Green0 = 9,
    Green = 10,
    Yellow0 = 11,
    Yellow = 12,
    Orange0 = 13,
    Orange = 14,
    Gray0 = 15,
    Gray = 16
}

local BreakEff = Object.Define()
function BreakEff:frame()
    if self.timer >= 23 then
        Object.Del(self)
    end
end
function M.BreakEff(x, y, index)
    local self = Object.New(BreakEff)
    self.x = x
    self.y = y
    self.index = index
    self.group = Object.Group.Ghost
    self.layer = Object.Layer.EnemyBullet - 50
    self.img = "stg:etbreak" .. index
    --
    self.rot = ran:Float(0, 360)
    return self
end

require("STG.Scripts.Shots.Bullet")
require("STG.Scripts.Shots.Laser")
require("STG.Scripts.Shots.CurveLaser")
require("STG.Scripts.Shots.Utils")
setmetatable(M, {
    __index = function(t, k)
        local v = M.Utils[k]
        if v ~= nil then
            rawset(t, k, v)
            return v
        end
    end
})
