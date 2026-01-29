local Resource = Core.Resource
local LazyLoader = Resource.LazyLoader
local Texture = Resource.Texture
local Image = Resource.Image
local Animation = Resource.Animation
local Sound = Resource.Sound

LazyLoader.Add(function()
    Resource.SetResourcePool(Resource.PoolType.Global)
end)
LazyLoader.Add(function()
    local path = "STG\\Assets\\Sprites\\"
    Image.NewFromFile("stg:enemy_break_ef", path .. "enemy_break_ef.png")
    local tex = Texture.New("stg:bullet_fog", path .. "bullet_fog.png")
    Image.NewGroup("stg:bullet_fog", tex, 0, 0, 64, 64, 2, 8)
    for i, img in ipairs(Image.res_group["stg:bullet_fog"]) do
        img:copy("stg:laser_fog" .. i)
    end
end)