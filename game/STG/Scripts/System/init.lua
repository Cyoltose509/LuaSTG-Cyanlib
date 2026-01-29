---@class STG.System
---@field Time STG.System.Time @适用于STG的计时器，该计时器不使用真正的Delta，因此不受帧率影响。而且为1/60秒为一个单位
local M = {}
STG.System = M

require("STG.Scripts.System.Time")