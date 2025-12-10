---@class STG.Object : Core.Object
---@field Group STG.Object.Group
---@field Layer STG.Object.Layer
local M = {}
STG.Object = M

require("STG.Scripts.Object.Group")
require("STG.Scripts.Object.Layer")

setmetatable(M, { __index = Core.Object })