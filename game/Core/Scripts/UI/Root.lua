---@class Core.UI.Root
local M = Core.Class()
Core.UI.Root = M

local before = "update.Before"
local after = "update.After"

---@alias Core.UI.Root.New Core.UI.Root|fun(name:string, layer:number):Core.UI.Root
function M:init(name, layer)
    ---@type Core.UI.Child[]
    self.children = {}
    self.name = name
    self.layer = layer or 0
    self.timer = 0
    self._x = 0
    self._y = 0
    self._hscale = 1
    self._vscale = 1
    self._need_sort = false
    self.eventListener = Core.Lib.EventListener()
    self.eventListener:create(before)
    self.eventListener:create(after)
    ---@type Core.Display.Camera.Base
    self.camera = nil
end

function M:addChild(child)
    table.insert(self.children, child)
    child.parent = self
    self._need_sort = true
    return self
end

function M:removeChild(child)
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            child.parent = nil
            self._need_sort = true
            return
        end
    end
end

function M:update()
    self.eventListener:dispatch(before, self)
    Core.Task.Do(self)
    self.timer = self.timer + 1
    if self._need_sort then
        table.sort(self.children, function(a, b)
            return (a.layer or 0) < (b.layer or 0)
        end)
        self._need_sort = nil
    end
    for _, child in ipairs(self.children) do
        if child.before_update then
            child:before_update()
        end
    end
    for _, child in ipairs(self.children) do
        if child.update then
            child:update()
        end
    end
    self.eventListener:dispatch(after, self)
end

function M:draw()
    for _, child in pairs(self.children) do
        if child.draw then
            child:draw()
        end
    end
end

function M:release()
    if self.camera then
        self.camera:removeRenderObjects(self.name)
    else
        Core.UI.Manager.DestroyHUDRoot(self)
    end

end
---添加主更新前事件
---Add main update before event
---@param name string
---@param level number
---@param func fun(self:self)
---@param label string
function M:addBeforeEvent(name, level, func, label)
    self.eventListener:addEvent(before, name, level, func, label)
end
---添加主更新后事件
---Add main update after event
---@param name string
---@param level number
---@param func fun(self:self)
---@param label string
function M:addAfterEvent(name, level, func, label)
    self.eventListener:addEvent(after, name, level, func, label)
end
---移除主更新前事件
---Remove main update before event
---@param name string
function M:removeBeforeEvent(name)
    self.eventListener:remove(before, name)
end
---移除主更新后事件
---Remove main update after event
---@param name string
function M:removeAfterEvent(name)
    self.eventListener:remove(after, name)
end
---禁用指定标签的事件
---Disable events with the specified label
---@param label string
function M:disableEventByLabel(label)
    self.eventListener:disableByLabel(label)
end
---启用指定标签的事件
---Enable events with the specified label
---@param label string
function M:enableEventByLabel(label)
    self.eventListener:enableByLabel(label)
end

function M:serialize()
    local data = {
        name = self.name,
        layer = self.layer,
    }
    data.children = {}
    for _, child in ipairs(self.children) do
        if child.can_serialize then
            table.insert(data.children, child:serialize())
        end
    end
    return data
end

function M:deserialize(data)
    self.name = data.name
    self.layer = data.layer
    self.children = {}
    for _, childData in ipairs(data.children) do
        local child = Core.UI.ParseName(childData._name)()
        child:deserialize(childData)
        self:addChild(child)
    end
end

