local assert = assert
local type = type
local table = table
---@class Core.Lib.EventListener
local EventListener = Core.Class()
Core.Lib.EventListener = EventListener

function EventListener:init()
    ---@type table<string, table<string, Core.Lib.EventListener.Event>>
    self.data = {}
end

---创建事件组
---@param group string @事件组名称
function EventListener:create(group)
    assert(type(group) == "string")
    self.data[group] = self.data[group] or {}
end

---查找并获取事件
---@param group string @事件组名称
---@param name string @事件名称
---@return Core.Lib.EventListener.Event|nil
function EventListener:find(group, name)
    assert(type(group) == "string")
    assert(type(name) == "string")
    if self.data[group] and self.data[group][name] then
        return self.data[group][name]
    end
end

function EventListener:empty(group)
    return not self.data[group] or next(self.data[group]) == nil
end

---排序事件组
---@param group string @事件组名称
function EventListener:sort(group)
    assert(type(group) == "string")
    table.sort(self.data[group], function(a, b)
        return (a.level or 0) < (b.level or 0)
    end)
end

---添加事件
---@param group string @事件组名称
---@param name string @事件名称
---@param level number @事件优先度
---@param func function @事件函数
---@param label string @事件标签
function EventListener:addEvent(group, name, level, func, label)
    level = level or 0
    assert(type(group) == "string", "group must be string")
    assert(type(name) == "string", "name must be string")
    assert(type(level) == "number", "level must be number")
    assert(type(func) == "function", "func must be function")
    if not self.data[group] then
        self:create(group)
    end
    if self:find(group, name) then
        self:remove(group, name)
    end
    ---@class Core.Lib.EventListener.Event
    local data = {
        group = group,
        name = name,
        level = level,
        func = func,
        enable = true,
        label = label or ""
    }
    table.insert(self.data[group], data)
    self.data[group][name] = data
    self:sort(group)

end

---移除事件
---@param group string @事件组名称
---@param name string @事件名称
function EventListener:remove(group, name)
    assert(type(group) == "string")
    assert(type(name) == "string")
    local data = self:find(group, name)
    if data then
        data.level = nil
        self:sort(group)
        self.data[group][name] = nil
        table.remove(self.data[group], 1)
    end
end

---执行事件组
---@param group string @事件组名称
function EventListener:dispatch(group, ...)
    assert(type(group) == "string")
    if not self.data[group] then
        return
    end
    for _, data in ipairs(self.data[group]) do
        if data.enable then
            data.func(...)
        end
    end
end


function EventListener:enableByGroup(group)
    if not self.data[group] then
        return
    end

    for _, data in ipairs(self.data[group] or {}) do
        data.enable = true
    end
end
function EventListener:disableByGroup(group)
    if not self.data[group] then
        return
    end

    for _, data in ipairs(self.data[group] or {}) do
        data.enable = false
    end
end
function EventListener:enableByLabel(label)
    for _, events in pairs(self.data) do
        for _, data in ipairs(events) do
            if data.label == label then
                data.enable = true
            end
        end
    end
end
function EventListener:disableByLabel(label)
    for _, events in pairs(self.data) do
        for _, data in ipairs(events) do
            if data.label == label then
                data.enable = false
            end
        end
    end
end