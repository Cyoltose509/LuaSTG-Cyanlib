---@class Core.Object.Group
local M = {}
Core.Object.Group = M


local MIN_GROUP = 0
local MAX_GROUP = 15
function M.IsValid(g)
    if int(g) == g and g >= MIN_GROUP and g <= MAX_GROUP then
        return true
    else
        return false
    end
end

---碰撞对，用于碰撞检测
---@type table[]
local CollisionPairs = {}

--Group.CollisionPairs = CollisionPairs
function M.GetCollisionPairs()
    return CollisionPairs
end
function M.RegisterCollisionPair(group1, group2)
    assert(M.IsValid(group1) and M.IsValid(group2), "Invalid group")
    assert(group1 ~= group2, "group1 and group2 should not be the same")
    for i = 1, #CollisionPairs do
        local v = CollisionPairs[i]
        if v[1] == group1 and v[2] == group2 then
            return
        end
    end
    table.insert(CollisionPairs, { group1, group2 })
end
function M.UnregisterCollisionPair(group1, group2)
    for i = #CollisionPairs, 1, -1 do
        local v = CollisionPairs[i]
        if v[1] == group1 and v[2] == group2 then
            table.remove(CollisionPairs, i)
            return
        end
    end
end
function M.CollisionCheck()
    for _, v in ipairs(CollisionPairs) do
        lstg.CollisionCheck(v[1], v[2])
    end
end
function M.ResetCollisionPairs()
    for i = 1, #CollisionPairs do
        CollisionPairs[i] = nil
    end
end
---@param group number
---@return fun():lstg.GameObject,number,number
function M.GetToCollide(group)
    local iterators = {}
    for _, p in ipairs(CollisionPairs) do
        if p[2] == group then
            table.insert(iterators, lstg.ObjList(p[1]))
        end
    end
    local i = 1
    local current_iter = iterators[i]
    return function()
        while current_iter do
            local obj, n1, n2 = current_iter()
            if obj and obj.colli then
                return obj, n1, n2
            else
                i = i + 1
                current_iter = iterators[i]
            end
        end
        return nil
    end
end