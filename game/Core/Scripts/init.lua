---@class Core
local M = {}
Core = M

local function classCreate(instance, class, ...)
    local ctor = rawget(class, "init")
    if ctor then
        ctor(instance, ...)
    else
        local super = rawget(class, "super")
        if super then
            classCreate(instance, super, ...)
        end
    end
end

---声明一个类
---@generic T
---@param base T 基类
---@return T
function M.Class(base)
    local class = { _mbc = {}, super = base }

    local function new(t, ...)
        local instance = {}
        local meta = {
            __index = t,
            __tostring = class.__tostring,
            __add = class.__add,
            __sub = class.__sub,
            __mul = class.__mul,
            __div = class.__div,
            __mod = class.__mod,
            __pow = class.__pow,
            __unm = class.__unm,
            __len = class.__len,
            __concat = class.__concat,
            __call = class.__call,
            __eq = class.__eq,
            __lt = class.__lt,
            __le = class.__le,
        }
        setmetatable(instance, meta)
        classCreate(instance, t, ...)
        return instance
    end

    local function indexer(t, k)
        local member = t._mbc[k]
        if member == nil then
            if base then
                member = base[k]
                t._mbc[k] = member
            end
        end
        return member
    end
    local meta = {
        __call = new,
        __index = indexer
    }
    setmetatable(class, meta)

    return class
end

require("Core.Scripts.Lib")
require("Core.Scripts.Math")
require("Core.Scripts.VFS")
require("Core.Scripts.Object")
require("Core.Scripts.RNG")
require("Core.Scripts.Resource")

require("Core.Scripts.System")
require("Core.Scripts.Input")
require("Core.Scripts.Display")
require("Core.Scripts.Render")
require("Core.Scripts.Effect")

require("Core.Scripts.World")

require("Core.Scripts.SceneManager")
require("Core.Scripts.AudioManager")

require("Core.Scripts.Data")
require("Core.Scripts.I18n")
require("Core.Scripts.Task")
require("Core.Scripts.Animator")

require("Core.Scripts.UI")
require("Core.Scripts.Menu")

require("Core.Scripts.Collision")
require("Core.Scripts.MainLoop")

require("Core.Scripts.Time")
require("Core.Scripts.Steam")


--[[
require("Core.Scripts.misc")

require("Core.Scripts.ext")

require("Core.Scripts.Rogue")
require("Core.Scripts.STG")
require("Core.Scripts.UI")

require("Core.Scripts.SE")
require("Core.Scripts.Shader")
require("Core.Scripts.WalkImageSystem")

require("Core.Scripts.se")

require("Core.Scripts.Platform")--]]