---@class STG.Object.Group
local M = {
    ---0
    Ghost = 0,
    ---1
    EnemyBullet = 1,
    ---2
    Enemy = 2,
    ---3
    PlayerShots = 3,
    ---4
    Player = 4,
    ---5
    InDes = 5,
    ---6
    Item = 6,
    ---7
    NotCollide = 7,
    ---8
    Spell = 8,
}
STG.Object.Group = M

local CollisionPairs = {
    { M.Player, M.EnemyBullet },
    { M.Player, M.Enemy },
    { M.Player, M.InDes },
    { M.Enemy, M.PlayerShots },
    { M.NotCollide, M.PlayerShots },
    { M.Item, M.Player },
    { M.Spell, M.Enemy },
    { M.Spell, M.NotCollide },
    { M.Spell, M.EnemyBullet },
    { M.Spell, M.InDes },
}

for _, pair in ipairs(CollisionPairs) do
    Core.Object.Group.RegisterCollisionPair(pair[1], pair[2])
end