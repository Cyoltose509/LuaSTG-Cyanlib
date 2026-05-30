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
---@vararg string @事件标签
function EventListener:addEvent(group, name, level, func, ...)
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
        labels = { ... }
    }
    table.insert(self.data[group], data)
    self.data[group][name] = data
    self:sort(group)
    return data
end

---添加事件（高级）
---可以指定事件的位置、优先度、标签等
---@class Core.Lib.EventListener.EventOption
---@field name string
---@field level number
---@field func function
---@field before string|nil
---@field after string|nil
---@field autoSort boolean|nil
---@field labels string[]|nil
---@param group string
---@param opt Core.Lib.EventListener.EventOption
function EventListener:addEventAdvanced(group, opt)
    local function calcLevel(refName, dir)
        local ref = self:find(group, refName)
        local list = self.data[group]
        local idx = 1
        for i, v in ipairs(list) do
            if v == ref then
                idx = i
                break
            end
        end
        local ptr
        if dir == -1 then
            ptr = max(idx - 1, 1)
            local before = list[ptr]
            return before and (before.level + ref.level) / 2 or ref.level - 1
        elseif dir == 1 then
            ptr = min(idx + 1, #list)
            local after = list[ptr]
            return after and (ref.level + after.level) / 2 or ref.level + 1
        end
    end
    local level = opt.level
    if opt.before then
        level = calcLevel(opt.before, -1)
    elseif opt.after then
        level = calcLevel(opt.after, 1)
    elseif opt.autoSort or not opt.level then
        local list = self.data[group]
        local last = list[#list]
        if last then
            level = last.level + 1
        else
            level = 0
        end
    end
    local m = self:addEvent(group, opt.name, level, opt.func)
    if opt.labels then
        m.labels = opt.labels
    end
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
            for _, l in ipairs(data.labels) do
                if l == label then
                    data.enable = true
                end
            end
        end
    end
end
function EventListener:disableByLabel(label)
    for _, events in pairs(self.data) do
        for _, data in ipairs(events) do
            for _, l in ipairs(data.labels) do
                if l == label then
                    data.enable = false
                end
            end
        end
    end
end