---@class Core.Object : Core.Object.Utils
---@field Utils Core.Object.Utils
---@field Layer Core.Object.Layer
---@field Group Core.Object.Group
---@field AttributeProxy Core.Object.AttributeProxy
---@field GameObjectMixin Core.Object.GameObjectMixin
---@field GameObject Core.Object.GameObject
local M = {}
Core.Object = M

---@param self Core.Object.Base
local emptyfunc = function(self)
end
local all_class = {}

---base class of all classes
---@class Core.Object.Base  : lstg.GameObject
local object = { 0, 0, 0, 0, 0, 0,
                 is_class = true,
                 init = emptyfunc,
                 del = emptyfunc,
                 frame = emptyfunc,
                 render = lstg.DefaultRenderFunc,
                 colli = emptyfunc,
                 kill = emptyfunc
}
table.insert(all_class, object)

M.Base = object

---将目标的回调函数给自己
local function Equivalent(self, target)
    self.init = target.init
    self.del = target.del
    self.frame = target.frame
    self.render = target.render
    self.colli = target.colli
    self.kill = target.kill
end

---对回调函数进行整理，给底层调用
local function ClassSort(class)
    class[1] = class.init
    class[2] = class.del
    class[3] = class.frame
    class[4] = class.render
    class[5] = class.colli
    class[6] = class.kill
end
---定义新类
---@param base Core.Object.Base
---@param define Core.Object.Base
---@param sort boolean@是否现场整理
---@return Core.Object.Base
function M.Define(base, define, sort)
    base = base or object
    local result = { emptyfunc, emptyfunc, emptyfunc, emptyfunc, emptyfunc, emptyfunc, is_class = true, base = base }
    Equivalent(result, base)
    if type(define) == "table" then
        for k, v in pairs(define) do
            result[k] = v
        end
    end
    if sort then
        ClassSort(result)
    else
        table.insert(all_class, result)
    end
    return result
end

function M.InitAll()
    for _, v in pairs(all_class) do
        ClassSort(v)
    end
    all_class = {}
end

require("Core.Scripts.Object.Layer")
require("Core.Scripts.Object.Group")
require("Core.Scripts.Object.Utils")
require("Core.Scripts.Object.AttributeProxy")
require("Core.Scripts.Object.GameObjectMixin")
require("Core.Scripts.Object.GameObject")

setmetatable(M, {
    __index = function(t, k)
        local v = M.Utils[k]
        if v ~= nil then
            rawset(t, k, v)
            return v
        end
    end
})



