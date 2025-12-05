local Resource = Core.Resource
local LazyLoader = Resource.LazyLoader
local Texture = Resource.Texture
local Image = Resource.Image
local Animation = Resource.Animation
local Sound = Resource.Sound

if false then
    local bullets = "STG\\Assets\\Bullets\\"
    LazyLoader.Add(function()
        Resource.SetResourcePool(Resource.PoolType.Global)
    end)
    LazyLoader.Add(function()
        local tex = Texture.New("stg:bullet1", bullets .. "bullet1.png", true)

        local group = Image.NewGroup("stg:bullet_preimg", tex, 160, 0, 64, 64, 2, 8)
        for i, img in ipairs(group) do
            img:copy("stg:laser_preimg" .. i)
        end
        Image.NewGroup("stg:mildew", tex, 131, 0, 32, 32, 1, 16)
        Image.NewGroup("stg:ball_small", tex, 0, 0, 32, 32, 1, 16)
        local group2 = Image.NewGroup("stg:ellipse", tex, 81, 0, 48, 32, 1, 16)
        for _, img in ipairs(group2) do
            img:setScaling(1.5)
        end
    end)
    LazyLoader.Add(function()
        local tex = Texture.New("stg:bullet2", bullets .. "bullet2.png", true)
        Image.NewGroup("stg:arrow_big", tex, 160, 0, 32, 32, 1, 16)
        Image.NewGroup("stg:arrow_big_b", tex, 192, 0, 32, 32, 1, 16)
        Image.NewGroup("stg:arrow_small", tex, 32, 0, 32, 32, 1, 16)
        Image.NewGroup("stg:square", tex, 0, 0, 32, 32, 1, 16)
        Image.NewGroup("stg:grain_a", tex, 128, 0, 32, 32, 1, 16)
        Image.NewGroup("stg:grain_b", tex, 224, 0, 32, 32, 1, 16)
        Image.NewGroup("stg:grain_c", tex, 96, 0, 32, 32, 1, 16)
        Image.NewGroup("stg:grain_d", tex, 64, 0, 32, 32, 1, 16)
    end)
    LazyLoader.Add(function()
        local tex = Texture.New("stg:bullet3", bullets .. "bullet3.png", true)
        Image.NewGroup("stg:arrow_big_c", tex, 0, 0, 50, 36, 1, 16)

        Image.NewGroup("stg:arrow_small_b", tex, 133, 0, 56, 36, 1, 16)
        Image.NewGroup("stg:star_small", tex, 581, 0, 36, 36, 1, 16)
        Image.NewGroup("stg:ball_mid", tex, 191, 0, 36, 36, 1, 16)
        Image.NewGroup("stg:ball_mid_c", tex, 239, 0, 40, 36, 1, 16)
        Image.NewGroup("stg:ball_huge", tex, 768, 0, 128, 128, 2, 8)
        local group = Image.NewGroup("stg:arrow_mid", tex, 50, 0, 82, 36, 1, 16)
        for _, img in ipairs(group) do
            img:setScaling(0.75)
        end
    end)
    LazyLoader.Add(function()
        local tex = Texture.New("stg:bullet4", bullets .. "bullet4.png", true)
        for i = 1, 8 do
            Animation.New("stg:music" .. i, tex, (i - 1) * 102, 480, 96, 64, 1, 3, 8)
                     :setCenter(51, 32)
        end
        for i = 1, 8 do
            Animation.New("stg:water_drop" .. (i * 2 - 1), tex, (i - 1) * 96, 0, 96, 60, 1, 4, 4)
                     :setCenter(60, 30)
            Animation.New("stg:water_drop" .. (i * 2), tex, (i - 1) * 96, 60 * 4, 96, 60, 1, 4, 4)
                     :setCenter(60, 30)
        end
        do
            local width, height = 42, 42
            local x, y = 404, 676
            local map = {
                { 0, 0 },
                { 50, 0 },
                { 100, 0 },
                { 0, 50 },
                { 50, 50 },
                { 100, 50 },
                { 100, 0 },
                { 0, 50 },
                { 50, 50 },
                { 100, 50 },
                { 0, 0 },
                { 0, 50 },
                { 100, 0 },
                { 100, 50 },
                { 50, 0 },
                { 50, 50 },
            }
            for i = 1, 16 do
                Image.New("stg:money" .. i, tex, x + map[i][1], y + map[i][2], width, height)
            end
        end
        do
            local width, height = 86, 86
            local x, y = 7, 679
            local map = {
                { 0, 0 },
                { 100, 0 },
                { 200, 0 },
                { 0, 100 },
                { 100, 100 },
                { 200, 100 },
                { 200, 0 },
                { 0, 100 },
                { 100, 100 },
                { 200, 100 },
                { 0, 0 },
                { 0, 100 },
                { 200, 0 },
                { 200, 100 },
                { 100, 0 },
                { 100, 100 },
            }
            for i = 1, 16 do
                Image.New("stg:money_big" .. i, tex, x + map[i][1], y + map[i][2], width, height)
            end
        end
    end)
    LazyLoader.Add(function()
        local tex = Texture.New("stg:bullet5", bullets .. "bullet5.png", true)
        Image.NewGroup("stg:butterfly", tex, 0, 0, 66, 66, 16, 1)
        Image.NewGroup("stg:star_big", tex, 1025, 190, 64, 64, 16, 1)
        Image.NewGroup("stg:ball_big", tex, 0, 190, 64, 64, 16, 1)

        Image.NewGroup("stg:diamond", tex, 1056, 0, 45, 30, 16, 1)
        Image.NewGroup("stg:silence", tex, 0, 446, 78, 40, 16, 1)
        Image.NewGroup("stg:heart", tex, 0, 66, 64, 64, 16, 1)
        local group = Image.NewGroup("stg:knife_b", tex, 0, 392, 102, 44, 16, 1)
        for _, img in ipairs(group) do
            img:setScaling(0.75)
        end
    end)
    LazyLoader.Add(function()
        local tex = Texture.New("stg:gun", bullets .. "gun.png", true)
        for i = 1, 16 do
            Animation.New("stg:gun_bullet" .. i, tex, (i - 1) * 48, 0, 48, 48, 3, 1, 4)
        end
    end)
    LazyLoader.Add(function()
        local tex = Texture.New("stg:knife", bullets .. "knife.png", true)
        local w, h = tex:getSize()
        Image.NewGroup("stg:knife", tex, 0, 0, w, h / 16, 1, 16)
    end)
    LazyLoader.Add(function()
        local tex = Texture.New("stg:ball_light", bullets .. "ball_light.png", true)
        local w, h = tex:getSize()
        Image.NewGroup("stg:ball_light", tex, 0, 0, w / 4, h / 4, 4, 4)
    end)
    LazyLoader.Add(function()
        local tex = Texture.New("stg:etbreak", bullets .. "etbreak.png", true)
        for j = 1, 16 do
            Animation.New("stg:etbreak" .. j, tex, 0, 0, 128, 128, 4, 2, 3)
                     :setState(Core.Render.BlendMode.MulAdd, STG.Shots.Color[j])
        end
    end)

    local items = "STG\\Assets\\Items\\"
    LazyLoader.Add(function()
        Image.NewFromFile("stg:drop_point", items .. "drop_point.png", true, 8, 8)
             :setState(Core.Render.BlendMode.MulAdd, Core.Render.Color(150, 255, 255, 255))
    end)

    local sounds = "STG\\Assets\\Sounds\\"
    for _, v in ipairs(Core.VFS.EnumFiles(sounds, 'wav', true)) do
        local name = v[1]:sub(#sounds + 1, -5)
        LazyLoader.Add(function()
            Sound.New(name, v[1])
        end)
    end

    local lasers = "STG\\Assets\\Lasers\\"
    LazyLoader.Add(function()
        local Laser = STG.Shots.Laser.Resource
        Laser.LoadImage("stg:simple", lasers .. "laser1.png", 32, 210, 92, 210)
        Laser.LoadImage("stg:arrow", lasers .. "laser2.png", 16, 5, 236, 15)
        Laser.LoadImage("stg:ribbon", lasers .. "laser3.png", 16, 127, 1, 128)
        Laser.LoadImage("stg:beam", lasers .. "laser4.png", 16, 1, 254, 1)
        local LaserRegister = Laser.RegisterData
        LaserRegister("simple", {
            l1 = 210,
            l2 = 92,
            l3 = 210,
            realW = 10,
            other_init = function(self, master)
                self.node_img = "stg:laser_preimg" .. master.index
                self.head_img = "stg:ball_mid" .. master.index
                self.img1 = "stg:simple1" .. master.index
                self.img2 = "stg:simple2" .. master.index
                self.img3 = "stg:simple3" .. master.index
            end,
        })
        LaserRegister("arrow", {
            l1 = 5,
            l2 = 236,
            l3 = 15,
            realW = 8,
            other_init = function(self, master)
                self.node_img = "stg:laser_preimg" .. master.index
                self.head_img = "stg:ball_mid" .. master.index
                self.img1 = "stg:arrow1" .. master.index
                self.img2 = "stg:arrow2" .. master.index
                self.img3 = "stg:arrow3" .. master.index
            end,
        })
        LaserRegister("ribbon", {
            l1 = 127,
            l2 = 1,
            l3 = 128,
            realW = 6,
            other_init = function(self, master)
                self.node_img = "stg:laser_preimg" .. master.index
                self.head_img = "stg:ball_mid" .. master.index
                self.img1 = "stg:ribbon1" .. master.index
                self.img2 = "stg:ribbon2" .. master.index
                self.img3 = "stg:ribbon3" .. master.index
            end,
        })
        LaserRegister("beam", {
            l1 = 1,
            l2 = 254,
            l3 = 1,
            realW = 14,
            other_init = function(self, master)
                self.node_img = "stg:laser_preimg" .. master.index
                self.head_img = "stg:ball_mid" .. master.index
                self.img1 = "stg:beam1" .. master.index
                self.img2 = "stg:beam2" .. master.index
                self.img3 = "stg:beam3" .. master.index
            end,
        })
    end)

    LazyLoader.Add(function()
        local simple = Texture.New("stg:curve_laser:simple", lasers .. "laser_bent.png")
        local ices = {}
        local lights = {}
        for i = 1, 16 do
            ices[i] = Texture.New('stg:curve_laser:ice' .. i, lasers .. 'laser_ice' .. (i - 1) .. '.png')
            lights[i] = Texture.New('stg:curve_laser:light' .. i, lasers .. 'laser_light' .. (i - 1) .. '.png')
        end
        local CurveLaserRegister = STG.Shots.CurveLaser.Resource.RegisterData
        CurveLaserRegister("simple", {
            tex = simple,
            x = 0,
            y = 0,
            w = 256,
            h = 8,
            wRatio = 1,
            other_init = function(self, master)
                self.node_img = "stg:laser_preimg" .. master.index
                self.y = master.index * 16 - 12
            end,
        })
        CurveLaserRegister("ice", {
            tex = ices[1],
            x = 0,
            y = 0,
            w = 482,
            h = 64,
            wRatio = 3,
            other_init = function(self, master)
                self.node_img = "stg:laser_preimg" .. master.index
                self.tex = ices[master.index]
            end,
            frame = function(self, master)
                self.y = 64 * (int(0.5 * master.ani) % 4)
            end
        })
        CurveLaserRegister("light", {
            tex = lights[1],
            x = 0,
            y = 0,
            w = 512,
            h = 64,
            wRatio = 3,
            other_init = function(self, master)
                self.node_img = "stg:laser_preimg" .. master.index
                self.tex = lights[master.index]
            end,
            frame = function(self, master)
                self.y = 64 * (int(0.5 * master.ani) % 4)
            end
        })
    end)
end

