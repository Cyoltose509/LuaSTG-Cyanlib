
---@class Core.Lib
---@field Debug Core.Lib.Debug
---@field EventListener fun():Core.Lib.EventListener
---@field Table Core.Lib.Table
---@field Geom Core.Lib.Geom
---@field Easing Core.Lib.Easing
---@field Draw Core.Render.Draw
---@field Json Core.Lib.Json
---@field StateMachine Core.Lib.StateMachine
---@field Controller Core.Lib.Controller
local M = {}
Core.Lib = M

require("Core.Scripts.Lib.Debug")
require("Core.Scripts.Lib.EventListener")
require("Core.Scripts.Lib.Table")
require("Core.Scripts.Lib.Geom")
require("Core.Scripts.Lib.Easing")
require("Core.Scripts.Lib.Json")
require("Core.Scripts.Lib.StateMachine")
require("Core.Scripts.Lib.Controller")


