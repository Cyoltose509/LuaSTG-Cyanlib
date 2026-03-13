local Resource = Core.Resource
Resource.SetResourcePool(Resource.PoolType.Global)

local spath = "Core\\Assets\\Sprites\\"
Resource.Sprite.NewFromFile("white", spath .. "white.png")
Resource.Sprite.NewFromFile("img_void", spath .. "img_void.png")
Resource.Sprite.NewFromFile("bright", spath .. "bright.png", true)
Resource.Sprite.NewFromFile("bright_fog", spath .. "bright_fog.png", true)
Resource.Sprite.NewFromFile("bright_big", spath .. "bright_big.png", true)
Resource.Sprite.NewFromFile("bright_line", spath .. "bright_line.png", true)
Resource.Sprite.NewFromFile("pure_circle", spath .. "pure_circle.png", true)
Resource.Sprite.NewFromFile("bright_ring", spath .. "bright_ring.png", true)
local tex = Resource.Texture.New("particles", spath .. "particles.png")
Resource.Sprite.NewGroup("parimg", tex, 0, 0, 32, 32, 4, 4)

local fpath = "Core\\Assets\\Fonts\\"
Resource.TTF.New("exo2", fpath .. "exo2.ttf", 100)
Resource.TTF.New("wenkai", fpath .. "wenkai.ttf", 100)
Resource.TTF.New("heiti", fpath .. "heiti.otf", 100)
Resource.TTF.New("songti", fpath .. "songti.otf", 75)

local shaderpath = "Core\\Assets\\Shaders\\"
Resource.Shader.New("core:gray", shaderpath .. "gray.hlsl")
