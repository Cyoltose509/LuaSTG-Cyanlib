local Resource = Core.Resource
Resource.SetResourcePool(Resource.PoolType.Global)
local tpath = "Test\\Assets\\Textures\\"
Resource.Texture.New("test", tpath .. "test.jpg")

local mpath = "Test\\Assets\\Musics\\"
Resource.Music.New("test", mpath .. "test.ogg", 201, 201)
