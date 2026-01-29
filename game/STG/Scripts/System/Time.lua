---@class STG.System.Time
local M = Core.Class()
STG.System.Time = M

local FPS = Core.MainLoop.FPS
local Time = Core.Time

function M:init()
    self.scale = 1
end

function M:getDelta(dt)
    dt = dt and (dt * 60) or Time.GetSpeed()
    return self.scale
end

function M:setScale(s)
    self.scale = s
end
