---@class Core.Collision
---@field Collider Core.Collision.Collider
local M = {}
Core.Collision = M

local Object = Core.Object

---@param self Core.Collision.Collider.Base
---@param other Core.Collision.Collider.Base
---@param nx number
---@param ny number
---@param distance number 碰撞距离
---@param px number
---@param py number
function M.NewInfo(self, other, nx, ny, px, py, distance)
    ---@class Core.Collision.Info
    local info = {
        self = self,
        other = other,
        normal = { x = nx, y = ny },
        distance = distance,
        point = { x = px, y = py },
    }
    return info
end

---@type Core.Collision.Collider.Base[][]
M.Colliders = {}

---@type Core.Collision.Collider.Base[]
M.FreeColliders = {}

M.UseCustomCollisionPairs = false
M.CustomCollidePairs = {

}
---是否启用自定义碰撞对
---默认不启用，使用Object模块的碰撞对
---@param enable boolean
function M.EnableCustomCollisionPairs(enable)
    M.UseCustomCollisionPairs = enable
end

---@param collider Core.Collision.Collider.Base
function M.AddCollider(collider, group)
    local list = M.Colliders
    if group then
        M.Colliders[group] = M.Colliders[group] or {}
        list = M.Colliders[group]
    end
    for _, c in ipairs(list) do
        if c == collider then
            return
        end
    end
    collider._in_group = list
    table.insert(list, collider)
end
function M.RemoveCollider(collider)
    if collider._in_group then
        for i, c in ipairs(collider._in_group) do
            if c == collider then
                table.remove(collider._in_group, i)
                break
            end
        end
    end
end
function M.UpdateColliders()
    for _, collider in ipairs(M.FreeColliders) do
        collider:update()
    end
    for _, group in pairs(M.Colliders) do
        for _, collider in ipairs(group) do
            collider:update()
        end
    end
end

function M.CheckCollisions()
    for i = 1, #M.FreeColliders do
        local c1 = M.FreeColliders[i]
        for j = i + 1, #M.FreeColliders do
            local c2 = M.FreeColliders[j]
            local info = c1:check(c2)
            if info then
                c1:onCollide(info)
                c2:onCollide(info)
            end
        end
    end
    ---与底层一样，单向碰撞
    local pairs_list = M.UseCustomCollisionPairs and M.CustomCollidePairs or Object.Group.GetCollisionPairs()
    for _, pair in ipairs(pairs_list) do
        if M.Colliders[pair[1]] then
            for _, my in ipairs(M.Colliders[pair[1]]) do
                if my.colli then
                    for _, other in ipairs(M.Colliders[pair[2]]) do
                        if other.colli then
                            local info = my:check(other)
                            if info then
                                my:onCollide(info)
                            end
                        end
                    end
                    for _, other in Object.Group.GetToCollide(pair[1]) do
                        local info = my:check(other, M.Collider.GetObjectType(other))
                        if info then
                            my:onCollide(info)
                        end
                    end
                end
            end
        end
    end
end

function M.ResetColliders()
    M.FreeColliders = {}
    M.Colliders = {}
end

require("Core.Scripts.Collision.Collider")