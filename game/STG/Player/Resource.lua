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
    name = name or ""
    if M.Datas[name] then
        error("Player Resource Data already registered: " .. name)
    end
    local data = base()
    data.name = name
    M.Datas[name] = data
    return data
end

---注册一个空data占位
M.Register("")