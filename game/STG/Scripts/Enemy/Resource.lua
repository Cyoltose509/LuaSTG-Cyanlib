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
    assert(data, "Player Resource Data not found: " .. name)
    return data
end

---@param name string
---@return STG.Enemy.Resource.Data
function M.Register(name, collide_r, color_index)
    name = name or ""
    if M.Datas[name] then
        error("Enemy Resource Data already registered: " .. name)
    end
    local data = base()
    data.name = name
    data.collide_r = collide_r or 10
    data.color_index = color_index or 1
    M.Datas[name] = data
    return data
end

---注册一个空data占位
M.Register("")