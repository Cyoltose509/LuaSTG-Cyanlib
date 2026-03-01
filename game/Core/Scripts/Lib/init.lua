---@class Core.Lib
---@field Debug Core.Lib.Debug
---@field Table Core.Lib.Table@table相关函数
---@field Easing Core.Lib.Easing@缓动函数库
---@field Json Core.Lib.Json@Json工具库
---@field EventListener fun():Core.Lib.EventListener@事件监听器
---@field StateMachine Core.Lib.StateMachine@状态机
---@field ComponentSystem Core.Lib.ComponentSystem
---@field ComponentBase Core.Lib.ComponentBase
---@field Accessor Core.Lib.Accessor@一个getter&setter，支持"."路径解析
local M = {}
Core.Lib = M

require("Core.Scripts.Lib.Accessor")
require("Core.Scripts.Lib.Debug")
require("Core.Scripts.Lib.Table")
require("Core.Scripts.Lib.Easing")
require("Core.Scripts.Lib.Json")
require("Core.Scripts.Lib.EventListener")
require("Core.Scripts.Lib.StateMachine")
require("Core.Scripts.Lib.ComponentSystem")
require("Core.Scripts.Lib.ComponentBase")


