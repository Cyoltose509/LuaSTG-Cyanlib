---@class STG.Enemy.Resource
local M = {}
STG.Enemy.Resource = M

---@type STG.Enemy.Resource.Data[]
M.Datas = {}

---@class STG.Enemy.Resource.Data
local base = Core.Class()
function base:init()
    self.name = ""
    self.color_index = 1
    self.collide_r = 10
    ---@type STG.Enemy.Resource.Data.AnimationEntry[]
    self.animators = {}
end
---@param creator fun(self:STG.Animator)
---@return self
function base:addAnimator(creator, color, blend)
    ---@class STG.Enemy.Resource.Data.AnimationEntry
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
    assert(data, "Enemy Resource Data not found: " .. name)
    return data
end

---安全查找，不存在返回 nil
function M.GetSafe(name)
    return M.Datas[name]
end

---@param name string
---@return STG.Enemy.Resource.Data
function M.Register(name, collide_r, color_index)
    return M.Define(name, { collide_r = collide_r, color_index = color_index })
end

---一站式定义：注册资源 + 动画 + 默认属性
---@param name    string  敌机类型名
---@param config  table   { collide_r, color_index, animators[], hp, size, score, ... }
---@return STG.Enemy.Resource.Data
function M.Define(name, config)
    name = name or ""
    config = config or {}
    if M.Datas[name] then
        error("Enemy Resource Data already registered: " .. name)
    end
    local data = base()
    data.name = name
    data.collide_r = config.collide_r or 10
    data.color_index = config.color_index or 1

    -- 动画创建者（支持两种格式：creator 函数 或 { creator, color, blend }）
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

    -- 玩法默认值（Spawning 时自动合并）
    data.defaults = {}
    for k, v in pairs(config) do
        if k ~= "collide_r" and k ~= "color_index"
           and k ~= "animators" and k ~= "color" and k ~= "blend" then
            data.defaults[k] = v
        end
    end

    M.Datas[name] = data
    return data
end

---注册一个空data占位
M.Define("")