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
---@field CSV Core.Lib.CSV@CSV解析
---@field YAML Core.Lib.YAML@YAML解析
---@field Matcher Core.Lib.Matcher@搜索匹配
---@field Smooth Core.Lib.Smooth@自动控制平滑
local M = {}
Core.Lib = M

require("Core.Lib.Accessor")
require("Core.Lib.Debug")
require("Core.Lib.Table")
require("Core.Lib.Easing")
require("Core.Lib.Smooth")
require("Core.Lib.Json")
require("Core.Lib.EventListener")
require("Core.Lib.StateMachine")
require("Core.Lib.ComponentSystem")
require("Core.Lib.ComponentBase")
require("Core.Lib.CSV")
require("Core.Lib.Matcher")
require("Core.Lib.YAML")

