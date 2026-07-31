---@class STG.Player.Resource
local M = {}
STG.Player.Resource = M

---@type STG.Player.Resource.Data[]
M.Datas = {}

---@class STG.Player.Resource.Data
local base = Core.Class()
function base:init()
    self.name = ""
    ---@type STG.Player.Resource.Data.AnimationEntry[]
    self.animators = {}
end
---@param creator fun(self:STG.Animator)
---@return self
function base:addAnimator(creator, color, blend)
    ---@class STG.Player.Resource.Data.AnimationEntry
    local ani = {
        creator = creator,
        color = color or Core.Render.Color.Default,
        blend = blend or Core.Render.BlendMode.Default,
    }
    table.insert(self.animators, ani)
    return self
end

function M.Get(name)
    local data = M.Datas[name]
    assert(data, "Player Resource Data not found: " .. name)
    return data
end

---@param name string
---@return STG.Player.Resource.Data
function M.Register(name)
    return M.Define(name, {})
end

---一站式定义
---@param name   string
---@param config table  { animators[], size, move, ... }
---@return STG.Player.Resource.Data
function M.Define(name, config)
    name = name or ""
    config = config or {}
    if M.Datas[name] then
        error("Player Resource Data already registered: " .. name)
    end
    local data = base()
    data.name = name

    -- 动画创建者
    local animators = config.animators
    if animators then
        for _, entry in ipairs(animators) do
            if type(entry) == "function" then
                data:addAnimator(entry)
            else
                data:addAnimator(entry.creator or entry[1], entry.color or entry[2], entry.blend or entry[3])
            end
        end
    end

    -- 玩法默认值
    data.defaults = {}
    for k, v in pairs(config) do
        if k ~= "animators" then
            data.defaults[k] = v
        end
    end

    M.Datas[name] = data
    return data
end

---安全查找
function M.GetSafe(name)
    return M.Datas[name]
end

---注册一个空data占位
M.Define("")