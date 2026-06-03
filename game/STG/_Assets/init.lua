local Resource = Core.Resource
local LazyLoader = Resource.LazyLoader
local Texture = Resource.Texture
local Sprite = Resource.Sprite
local Animation = Resource.Animation
local Sound = Resource.Sound

LazyLoader.Add(function()
    Resource.SetResourcePool(Resource.PoolType.Global)
end)
LazyLoader.Add(function()
    local path = "STG\\_Assets\\Sprites\\"
    Sprite.NewFromFile("stg:enemy_break_ef", path .. "enemy_break_ef.png")
    local tex = Texture.New("stg:bullet_fog", path .. "bullet_fog.png")
    Sprite.NewGroup("stg:bullet_fog", tex, 0, 0, 64, 64, 2, 8)
    for i, img in ipairs(Sprite.res_group["stg:bullet_fog"]) do
        img:copy("stg:laser_fog" .. i)
    end
    Sprite.NewFromFile("stg:player_aura", path .. "player_aura.png")
    Sprite.NewFromFile("stg:player_center", path .. "player_center.png")
end)