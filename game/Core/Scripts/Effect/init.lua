---@class Core.Effect
---@field Post Core.Effect.Post
local M = {}
Core.Effect = M

local rand = Core.RNG:newRaw(Core.RNG.Algorithm.Xoshiro128ss, os.time())
M.rand = rand

require("Core.Scripts.Effect.Post")

