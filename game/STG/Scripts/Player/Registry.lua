---@class STG.Player.Registry
local M = {}
STG.Player.Registry = M

---@private
M._defs = {}
---@private
M._owners = {}

function M.Register(id, factory, owner)
    if M._defs[id] then
        error("Player id already registered: " .. id)
    end
    M._defs[id] = factory
    M._owners[id] = owner or "hexa"
end

function M.Get(id)
    return M._defs[id]
end
