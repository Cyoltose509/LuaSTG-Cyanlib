local Resource = Core.Resource
Resource.SetResourcePool(Resource.PoolType.Global)

local spath = "Core\\Assets\\Sprites\\"
Resource.Image.NewFromFile("white", spath .. "white.png")
Resource.Image.NewFromFile("img_void", spath .. "img_void.png")
Resource.Image.NewFromFile("bright", spath .. "bright.png",true)
Resource.Image.NewFromFile("bright_fog", spath .. "bright_fog.png",true)
Resource.Image.NewFromFile("bright_big", spath .. "bright_big.png",true)
Resource.Image.NewFromFile("pure_circle", spath .. "pure_circle.png",true)
local tex = Resource.Texture.New("particles", spath .. "particles.png")
Resource.Image.NewGroup("parimg", tex, 0, 0, 32, 32, 4, 4)

local fpath = "Core\\Assets\\Fonts\\"
Resource.TTF.New("exo2", fpath .. "exo2.ttf", 80)
Resource.TTF.New("wenkai", fpath .. "wenkai.ttf", 80)