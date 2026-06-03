---@class STG.Collision
local M = {}
STG.Collision = M

local Object = STG.Object
local Group = Object.Group

---Iterate all active objects in a collision group.
---@param group number
---@param func fun(obj: Core.Object.Base)
function M.ForEachInGroup(group, func)
    if not group or not func then
        return
    end
    for _, obj in lstg.ObjList(group) do
        func(obj)
    end
end

function M.ForEachEnemyBullet(func)
    M.ForEachInGroup(Group.EnemyBullet, func)
end

function M.ForEachEnemy(func)
    M.ForEachInGroup(Group.Enemy, func)
end

function M.ForEachPlayerShot(func)
    M.ForEachInGroup(Group.PlayerShots, func)
end

function M.ForEachItem(func)
    M.ForEachInGroup(Group.Item, func)
end

function M.ForEachBullet(func)
    M.ForEachInGroup(Group.EnemyBullet, func)
    M.ForEachInGroup(Group.InDes, func)
end

function M.ForEachEnemyAndNotCollide(func)
    M.ForEachInGroup(Group.Enemy, func)
    M.ForEachInGroup(Group.NotCollide, func)
end

return M
