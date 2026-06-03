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
function BreakEff:render()
    -- Animate through 8 frames (etbreak sprite group: index1..index8)
    local frame_idx = int(self.timer / 3) + 1
    frame_idx = clamp(frame_idx, 1, 8)
    local img_name = "stg:etbreak" .. self.index .. frame_idx
    lstg.Render(img_name, self.x, self.y, self.rot, self.scale / 2, self.scale / 2)
end
function M.BreakEff(x, y, index)
    local self = Object.New(BreakEff)
    self.x = x
    self.y = y
    self.index = clamp(index, 1, 16)
    self.scale = ran:Float(0.5, 0.75)
    self.rot = ran:Float(0, 360)
    self.group = Object.Group.Ghost
    self.layer = Object.Layer.EnemyBullet - 50
    -- img is not used; render() computes it dynamically
    return self
end

require("STG.Shots.Bullet")
require("STG.Shots.Laser")
require("STG.Shots.CurveLaser")
require("STG.Shots.Utils")
setmetatable(M, {
    __index = function(t, k)
        local v = M.Utils[k]
        if v ~= nil then
            rawset(t, k, v)
            return v
        end
    end
})
