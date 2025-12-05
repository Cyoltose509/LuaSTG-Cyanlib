---@class Core.Object.Group
local Group = {
    ---0
    Ghost = 0,
    ---1
    EnemyBullet = 1,
    ---2
    Enemy = 2,
    ---3
    PlayerBullet = 3,
    ---4
    Player = 4,
    ---5
    InDes = 5,
    ---6
    Item = 6,
    ---7
    NonColli = 7,
    ---8
    Spell = 8,
    ---9
    CPlayer = 9,
    --TODO：待删
    Laser = 10,
    ---11
    EnemyBullet2 = 11
}
Core.Object.Group = Group

local Pool = {
    Global = 1,
    Scene = 2
}
Group.Pool = Pool

local MIN_GROUP = 0
local MAX_GROUP = 15
function Group.IsValid(g)
    if int(g) == g and g >= MIN_GROUP and g <= MAX_GROUP then
        return true
    else
        return false
    end
end

---碰撞对，用于碰撞检测
---第一个是全局池，第二个是关卡池
---@type <GROUP,GROUP> table[]
local CollisionPairs = {
    {
        { Group.Player, Group.EnemyBullet },
        { Group.Player, Group.EnemyBullet2 },
        { Group.Player, Group.Enemy },
        { Group.Player, Group.InDes },
        { Group.Enemy, Group.PlayerBullet },
        { Group.NonColli, Group.PlayerBullet },
        { Group.Item, Group.Player },
        { Group.Spell, Group.Enemy },
        { Group.Spell, Group.NonColli },
        { Group.Spell, Group.EnemyBullet },
        { Group.Spell, Group.EnemyBullet2 },
        { Group.Spell, Group.InDes },
        { Group.Player, Group.Laser },
        { Group.Spell, Group.Laser },
        { Group.CPlayer, Group.Player },
        { Group.EnemyBullet2, Group.EnemyBullet }
    },
    {}
}
function Group.RegisterCollisionPairs(pool, group1, group2)
    assert(Group.IsValid(group1) and Group.IsValid(group2), "Invalid group")
    assert(group1 ~= group2, "group1 and group2 should not be the same")
    for p = 1, 2 do
        for i = 1, #CollisionPairs[p] do
            local v = CollisionPairs[p][i]
            if v[1] == group1 and v[2] == group2 then
                return
            end
        end
    end
    table.insert(CollisionPairs[pool], { group1, group2 })
end
function Group.UnregisterCollisionPairs(pool, group1, group2)
    for i = #CollisionPairs[pool], 1, -1 do
        local v = CollisionPairs[pool][i]
        if v[1] == group1 and v[2] == group2 then
            table.remove(CollisionPairs[pool], i)
            return
        end
    end
end
function Group.CollisionCheck()
    for _, v in ipairs(CollisionPairs[1]) do
        lstg.CollisionCheck(v[1], v[2])
    end
    for _, v in ipairs(CollisionPairs[2]) do
        lstg.CollisionCheck(v[1], v[2])
    end
end
function Group.ResetCollisionPairs(pool)
    for i = 1, #CollisionPairs[pool] do
        CollisionPairs[pool][i] = nil
    end
end
---@param self lstg.GameObject
---@return fun():lstg.GameObject,number,number
function Group.GetToCollide(self)
    local iterators = {}
    for i = 1, 2 do
        for _, p in ipairs(CollisionPairs[i]) do
            if p[2] == self.group then
                table.insert(iterators, lstg.ObjList(p[1]))
            end
        end
    end
    local i = 1
    local current_iter = iterators[i]
    return function()
        while current_iter do
            local obj, n1, n2 = current_iter()
            if obj then
                return obj, n1, n2
            else
                i = i + 1
                current_iter = iterators[i]
            end
        end
        return nil
    end
end