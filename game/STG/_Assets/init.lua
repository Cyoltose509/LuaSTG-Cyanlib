---STG Assets — universal (common) sprites, sounds, and music.
---All assets loaded from STG/Assets/ directly with "stg:" prefix.
STG.Assets = {}

local Resource = Core.Resource
local LazyLoader = Resource.LazyLoader
local Texture = Resource.Texture
local Sprite = Resource.Sprite
local Animation = Resource.Animation
local Sound = Resource.Sound
local Music = Resource.Music

local BASE = "STG\\_Assets\\"
local function fp(sub)
    return BASE .. sub
end

---Load a single sprite from a PNG file (= LoadImageFromFile).
local function fromFile(name, relPath)
    LazyLoader.Add(function()
        Sprite.NewFromFile("stg:" .. name, fp(relPath))
    end)
end

---Load a texture then create sub-images from it (= LoadImageGroup).
local function fromGrid(prefix, relPath, x, y, w, h, cols, rows)
    LazyLoader.Add(function()
        local texName = "stg:" .. prefix .. "_tex"
        local tex = Texture.New(texName, fp(relPath))
        Sprite.NewGroup("stg:" .. prefix, tex, x, y, w, h, cols, rows)
    end)
end

---Import all legacy/common assets.
---（原 STG.Config.Get("import_legacy_assets") 检查已移除——
--- 配置项不存在，且资产加载应在游戏初始化阶段无条件执行。）
function STG.Assets.Import()
    LazyLoader.Add(function()
        Resource.SetResourcePool(Resource.PoolType.Global)
    end)

    -- ==================== UI ====================
    fromFile("ui.boss_ui", "UI\\boss_ui.png")
    fromFile("ui.hint", "UI\\hint.png")
    fromFile("ui.logo", "UI\\logo.png")
    fromFile("ui.menu_bg", "UI\\menu_bg.png")
    fromFile("ui.menu_bg1", "UI\\menu_bg1.png")
    fromFile("ui.menu_bg_2", "UI\\menu_bg_2.png")
    fromFile("ui.pause", "UI\\pause.png")
    fromFile("ui.rank", "UI\\rank.png")
    fromFile("ui.replay_title", "UI\\replay_title.png")
    fromFile("ui.save_rep_title", "UI\\save_rep_title.png")
    fromFile("ui.ui_bg", "UI\\ui_bg.png")
    fromFile("ui.ui_bg_2", "UI\\ui_bg_2.png")
    fromFile("ui.line", "UI\\line.png")
    fromFile("ui.hint1", "UI\\hint1.png")

    -- ==================== Enemy ====================
    fromFile("enemy.boss", "Enemy\\boss.png")
    fromFile("enemy.lifebar", "Enemy\\lifebar.png")
    fromFile("enemy.ring00", "Enemy\\ring00.png")
    fromFile("enemy.shockwave", "Enemy\\shockwave.png")
    fromFile("enemy.eff_cnlight", "Enemy\\eff_cnlight.png")
    fromFile("enemy.eff_magicsquare", "Enemy\\eff_magicsquare.png")
    fromFile("enemy.scname_sign", "Enemy\\scname_sign.png")
    fromFile("enemy.sc_his_stage", "Enemy\\sc_his_stage.png")
    fromFile("enemy.timesign", "Enemy\\timesign.png")
    fromFile("enemy.undefined", "Enemy\\undefined.png")

    -- enemy1.png sprite sheet (512x512 atlas)
    LazyLoader.Add(function()
        local tex = Texture.New("stg:enemy1", fp("Enemy\\enemy1.png"), true)
        -- Rows of 12 color variants x 1 anim frame each (32x32)
        Sprite.NewGroup("stg:enemy1_", tex, 0, 384, 32, 32, 12, 1)  -- 12 sprites
        Sprite.NewGroup("stg:enemy2_", tex, 0, 416, 32, 32, 12, 1)  -- 12 sprites
        Sprite.NewGroup("stg:enemy3_", tex, 0, 448, 32, 32, 12, 1)  -- 12 sprites
        Sprite.NewGroup("stg:enemy4_", tex, 0, 480, 32, 32, 12, 1)  -- 12 sprites
        -- 4 color variants x 3 anim frames each (48x32)
        Sprite.NewGroup("stg:enemy5_", tex, 0, 0, 48, 32, 4, 3)  -- 12 sprites
        Sprite.NewGroup("stg:enemy6_", tex, 0, 96, 48, 32, 4, 3)  -- 12 sprites
        -- 4 color variants x 3 anim frames (48x48)
        Sprite.NewGroup("stg:enemy7_", tex, 320, 0, 48, 48, 4, 3)  -- 12 sprites
        Sprite.NewGroup("stg:enemy8_", tex, 320, 144, 48, 48, 4, 3)  -- 12 sprites
        -- 4 color variants x 3 anim frames (64x64)
        Sprite.NewGroup("stg:enemy9_", tex, 0, 192, 64, 64, 4, 3)  -- 12 sprites
        -- 2 color x 2 frames (32x32)
        Sprite.NewGroup("stg:kedama", tex, 256, 320, 32, 32, 2, 2)  -- 4 sprites
        -- 4 color x 1 frame (32x32)
        Sprite.NewGroup("stg:enemy_x", tex, 192, 32, 32, 32, 4, 1)  -- 4 sprites
        Sprite.NewGroup("stg:enemy_orb", tex, 192, 64, 32, 32, 4, 1)  -- 4 sprites
        Sprite.NewGroup("stg:enemy_orb_ring", tex, 192, 96, 32, 32, 4, 1)  -- 4 sprites
        Sprite.NewGroup("stg:enemy_aura", tex, 192, 32, 32, 32, 4, 1)  -- 4 sprites (same pos as enemy_x)
    end)

    -- enemy2.png sprite sheet
    LazyLoader.Add(function()
        local tex = Texture.New("stg:enemy2", fp("Enemy\\enemy2.png"), true)
        Sprite.NewGroup("stg:enemy10_", tex, 0, 0, 32, 32, 12, 1)  -- 12 sprites
        Sprite.NewGroup("stg:enemy11_", tex, 0, 32, 32, 32, 12, 1)  -- 12 sprites
        Sprite.NewGroup("stg:enemy12_", tex, 0, 64, 32, 32, 12, 1)  -- 12 sprites
        Sprite.NewGroup("stg:enemy13_", tex, 0, 96, 32, 32, 12, 1)  -- 12 sprites
        Sprite.NewGroup("stg:enemy14_", tex, 0, 128, 64, 64, 6, 2)  -- 12 sprites
        Sprite.NewGroup("stg:enemy15_", tex, 0, 288, 32, 32, 12, 1)  -- 12 sprites
        Sprite.NewGroup("stg:enemy16_", tex, 0, 352, 32, 32, 12, 1)  -- 12 sprites
        Sprite.NewGroup("stg:enemy17_", tex, 0, 416, 32, 32, 12, 1)  -- 12 sprites
        Sprite.NewGroup("stg:enemy18_", tex, 0, 480, 32, 32, 12, 1)  -- 12 sprites
    end)

    -- enemy3.png sprite sheet
    LazyLoader.Add(function()
        local tex = Texture.New("stg:enemy3", fp("Enemy\\enemy3.png"), true)
        Sprite.NewGroup("stg:Ghost1", tex, 0, 0, 32, 32, 8, 1)  -- 8 sprites
        Sprite.NewGroup("stg:Ghost2", tex, 0, 32, 32, 32, 8, 1)  -- 8 sprites
        Sprite.NewGroup("stg:Ghost3", tex, 0, 64, 32, 32, 8, 1)  -- 8 sprites
        Sprite.NewGroup("stg:Ghost4", tex, 0, 96, 32, 32, 8, 1)  -- 8 sprites
    end)

    -- ==================== Player ====================
    fromFile("player.spellmask", "Player\\spellmask.png")

    -- Reimu player sprites
    LazyLoader.Add(function()
        local rtex = Texture.New("stg:reimu_sheet", fp("Player\\Reimu\\reimu.png"), true)
        Sprite.NewGroup("stg:reimu_player", rtex, 0, 0, 32, 48, 8, 3)  -- 24 sprites (8 cols x 3 rows)
        -- Support option sprite
        Sprite.New("stg:reimu_support", rtex, 64, 144, 16, 16)
        -- Bullet sprites
        Sprite.New("stg:reimu_bullet_red", rtex, 192, 160, 64, 16)
        Sprite.New("stg:reimu_bullet_blue", rtex, 0, 160, 16, 16)
        Sprite.New("stg:reimu_bullet_orange", rtex, 64, 176, 64, 16)
    end)

    -- Marisa player sprites
    LazyLoader.Add(function()
        local mtex = Texture.New("stg:marisa_sheet", fp("Player\\Marisa\\marisa.png"), true)
        Sprite.NewGroup("stg:marisa_player", mtex, 0, 0, 32, 48, 8, 3)  -- 24 sprites
        Sprite.New("stg:marisa_support", mtex, 144, 144, 16, 16)
        Sprite.New("stg:marisa_bullet", mtex, 0, 144, 32, 16)
    end)

    -- ==================== Laser ====================
    fromFile("laser.laser1", "Laser\\laser1.png")
    fromFile("laser.laser2", "Laser\\laser2.png")
    fromFile("laser.laser3", "Laser\\laser3.png")
    fromFile("laser.laser4", "Laser\\laser4.png")
    fromFile("laser.laser5", "Laser\\laser5.png")
    fromFile("laser.laser_bent", "Laser\\laser_bent.png")

    -- ==================== Item ====================
    -- item.png: 128x160, assumed 2-col (normal/up) × 5-row layout, each cell 32x32
    -- Row 0: Point, Row 1: Power, Row 2: BigPoint, Row 3: Bomb, Row 4: Life
    LazyLoader.Add(function()
        local item_tex = Texture.New("stg:item_tex", fp("Item\\item.png"))
        local cw, ch = 32, 32
        local item_types = {
            "point", "power", "bigpoint", "bomb", "life",
        }
        for i, name in ipairs(item_types) do
            local y = (i - 1) * ch
            Sprite.New("stg:item_" .. name, item_tex, 0, y, cw, ch)
            Sprite.New("stg:item_" .. name .. "_up", item_tex, cw, y, cw, ch)
        end
        -- drop_point: use white sprite with mul+add blend (no dedicated file in Assets)
        Sprite.New("stg:drop_point", item_tex, 0, 0, 16, 16)
    end)

    -- ==================== Misc / particles ====================
    LazyLoader.Add(function()
        local misc_tex = Texture.New("stg:misc_tex", fp("Misc\\misc.png"))
        -- player_aura: UV (128, 0, 64, 64) matching legacy misc.lua
        Sprite.New("stg:player_aura", misc_tex, 128, 0, 64, 64)
        -- use white from misc.png as player_center (16x16 at UV 56,8)
        Sprite.New("stg:player_center", misc_tex, 56, 8, 16, 16)
    end)
    fromFile("misc.img_void", "Misc\\img_void.png")
    fromFile("enemy_break_ef", "Misc\\enemy_break_ef.png")
    fromGrid("misc.particles", "Misc\\particles.png", 0, 0, 16, 16, 8, 8)

    -- bullet_fog: 16 sprites (2 cols × 8 rows) + laser_fog copies
    LazyLoader.Add(function()
        local tex = Texture.New("stg:bullet_fog", fp("Bullet\\bullet_fog.png"))
        Sprite.NewGroup("stg:bullet_fog", tex, 0, 0, 64, 64, 2, 8)
        for i, img in ipairs(Sprite.res_group["stg:bullet_fog"]) do
            img:copy("stg:laser_fog" .. i)
        end
    end)

    -- etbreak: 16 color variants, etbreak.png is 256x128 (2x1 grid of 128x128)
    -- Legacy uses LoadImageGroup('etbreak'..j, 'etbreak', 0, 0, 128, 128, 4, 2) per color
    -- Effective frames: (0,0) and (128,0) — 2 frames per group
    -- All 16 color groups share the same texture; colors applied via SetImageState
    LazyLoader.Add(function()
        local etbreak_tex = Texture.New("stg:etbreak_tex", fp("Bullet\\etbreak.png"))
        for j = 1, 16 do
            -- Match legacy: 4x2 grid (only first 2 cols are valid on 256x128 texture)
            Sprite.NewGroup("stg:etbreak" .. j, etbreak_tex, 0, 0, 128, 128, 4, 2)
            for i = 1, 8 do
                local s = Sprite.res["stg:etbreak" .. j .. i]
                if s then s:setScaling(0.5) end
            end
            -- Set mul+add blend with color matching bullet color table
            local col = STG.Shots.Color[j] or Core.Render.Color.Default
            for i = 1, 8 do
                local s = Sprite.res["stg:etbreak" .. j .. i]
                if s then s:setState(Core.Render.BlendMode.MulAdd, col) end
            end
        end
    end)

    -- ==================== Bullet Sprites (cake community-creations atlas) ====================
    -- Texture bullet1 — 512x512, vertical columns of 16 frames each
    LazyLoader.Add(function()
        local tex1 = Texture.New("stg:bullet1", fp("Bullet\\bullet1.png"), true)
        -- column x=0,   w=30 h=32, 16 frames (arrow_big)
        Sprite.NewGroup("stg:arrow_big", tex1, 0, 0, 30, 32, 1, 16)
        -- column x=32,  w=32 h=32, 16 frames (gun_bullet)
        Sprite.NewGroup("stg:gun_bullet", tex1, 32, 0, 32, 32, 1, 16)
        -- column x=64,  w=64 h=64, 8 frames (preimg / laser_node)
        Sprite.NewGroup("stg:preimg", tex1, 64, 0, 64, 64, 1, 8)
        Sprite.NewGroup("stg:laser_node", tex1, 64, 0, 64, 64, 1, 8)
        -- column x=128, w=32 h=32, 16 frames (star_small), center (16,17)
        local ss = Sprite.NewGroup("stg:star_small", tex1, 128, 0, 32, 32, 1, 16)
        for _, img in ipairs(ss) do
            img:setCenter(16, 17)
        end
        -- column x=160, w=64 h=64, 8 frames (butterfly)
        Sprite.NewGroup("stg:butterfly", tex1, 160, 0, 64, 64, 1, 8)
        -- column x=224, w=32 h=32, 16 frames (square)
        Sprite.NewGroup("stg:square", tex1, 224, 0, 32, 32, 1, 16)
        -- column x=256 top, w=32 h=32, 8 frames (ball_mid)
        Sprite.NewGroup("stg:ball_mid", tex1, 256, 0, 32, 32, 1, 8)
        -- column x=256 bottom, w=32 h=16, 16 frames (grain_b)
        Sprite.NewGroup("stg:grain_b", tex1, 256, 256, 32, 16, 1, 16)
        -- column x=288 top, w=32 h=16, 16 frames (arrow_small)
        Sprite.NewGroup("stg:arrow_small", tex1, 288, 0, 32, 16, 1, 16)
        -- column x=288 bottom, w=32 h=32, 8 frames (money)
        Sprite.NewGroup("stg:money", tex1, 288, 256, 32, 32, 1, 8)
        -- column x=320 top, w=64 h=32, 8 frames (ellipse)
        Sprite.NewGroup("stg:ellipse", tex1, 320, 0, 64, 32, 1, 8)
        -- column x=320 bottom, w=32 h=16, 16 frames (grain_a)
        Sprite.NewGroup("stg:grain_a", tex1, 320, 256, 32, 16, 1, 16)
        -- column x=352 bottom, w=16 h=16, 16 frames (ball_small)
        Sprite.NewGroup("stg:ball_small", tex1, 352, 256, 16, 16, 1, 16)
        -- column x=368 bottom, w=16 h=16, 16 frames (mildew)
        Sprite.NewGroup("stg:mildew", tex1, 368, 256, 16, 16, 1, 16)
        -- column x=384, w=64 h=64, 8 frames (ball_big)
        Sprite.NewGroup("stg:ball_big", tex1, 384, 0, 64, 64, 1, 8)
        -- column x=448 top, w=64 h=32, 8 frames (knife)
        Sprite.NewGroup("stg:knife", tex1, 448, 0, 64, 32, 1, 8)
        -- column x=448 bottom, w=32 h=32, 8 frames (ball_mid_c)
        Sprite.NewGroup("stg:ball_mid_c", tex1, 448, 256, 32, 32, 1, 8)
        -- column x=480 bottom, w=32 h=16, 16 frames (grain_c)
        Sprite.NewGroup("stg:grain_c", tex1, 480, 256, 32, 16, 1, 16)
        -- set arrow_big center (9, 16)
        for _, img in ipairs(Sprite.res_group["stg:arrow_big"] or {}) do
            img:setCenter(9, 16)
        end
    end)

    -- Texture bullet2 — 512x512, vertical columns
    LazyLoader.Add(function()
        local tex2 = Texture.New("stg:bullet2", fp("Bullet\\bullet2.png"), true)
        -- column x=0,   w=64 h=64, 8 frames (star_big)
        Sprite.NewGroup("stg:star_big", tex2, 0, 0, 64, 64, 1, 8)
        -- column x=64,  w=64 h=64, 8 frames (arrow_mid), scaling 0.5
        local am = Sprite.NewGroup("stg:arrow_mid", tex2, 64, 0, 64, 64, 1, 8)
        for _, img in ipairs(am) do
            img:setScaling(0.5)
        end
        -- column x=128, w=64 h=64, 8 frames (heart)
        Sprite.NewGroup("stg:heart", tex2, 128, 0, 64, 64, 1, 8)
        -- column x=192, w=32 h=32, 16 frames (kite)
        Sprite.NewGroup("stg:kite", tex2, 192, 0, 32, 32, 1, 16)
        -- column x=256, w=64 h=64, 8 frames (knife_b), scaling 0.5
        local kb = Sprite.NewGroup("stg:knife_b", tex2, 256, 0, 64, 64, 1, 8)
        for _, img in ipairs(kb) do
            img:setScaling(0.5)
        end
        -- column x=352, w=64 h=64, 8 frames (ball_mid_b)
        Sprite.NewGroup("stg:ball_mid_b", tex2, 352, 0, 64, 64, 1, 8)
        -- column x=448, w=64 h=64, 8 frames (silence)
        Sprite.NewGroup("stg:silence", tex2, 448, 0, 64, 64, 1, 8)
    end)

    -- Texture bullet3 — 512x512, 2x4 grids of 128x128
    LazyLoader.Add(function()
        local tex3 = Texture.New("stg:bullet3", fp("Bullet\\bullet3.png"), true)
        -- ball_light: 2x4 grid, blend mul+add
        local bl = Sprite.NewGroup("stg:ball_light", tex3, 0, 0, 128, 128, 2, 4)
        for _, img in ipairs(bl) do
            img:setState(Core.Render.BlendMode.MulAdd)
        end
        -- ball_huge: 2x4 grid, y=256, blend mul+add
        local bh = Sprite.NewGroup("stg:ball_huge", tex3, 0, 256, 128, 128, 2, 4)
        for _, img in ipairs(bh) do
            img:setState(Core.Render.BlendMode.MulAdd)
        end
    end)

    -- Texture bullet_water_drop — animations
    LazyLoader.Add(function()
        local texW = Texture.New("stg:bullet_water_drop", fp("Bullet\\bullet_water_drop.png"), true)
        for i = 1, 8 do
            Animation.New("stg:water_drop" .. i, texW,
                    (i - 1) * 96, 0, 96, 64, 1, 4, 3)
                     :setCenter(48, 32)
        end
    end)

    -- Texture bullet_music — animations
    LazyLoader.Add(function()
        local texM = Texture.New("stg:bullet_music", fp("Bullet\\bullet_music.png"), true)
        for i = 1, 6 do
            Animation.New("stg:music" .. i, texM,
                    (i - 1) * 120, 0, 120, 64, 1, 3, 3)
                     :setCenter(60, 32)
        end
    end)

    -- ==================== Sound Effects ====================
    LazyLoader.Add(function()
        local se = "Se\\"
        Sound.New("stg:se.damage00", fp(se .. "se_damage00.wav"))
        Sound.New("stg:se.damage01", fp(se .. "se_damage01.wav"))
        Sound.New("stg:se.pldead00", fp(se .. "se_pldead00.wav"))
        Sound.New("stg:se.graze", fp(se .. "se_graze.wav"))
        Sound.New("stg:se.item00", fp(se .. "se_item00.wav"))
        Sound.New("stg:se.power00", fp(se .. "se_power0.wav"))
        Sound.New("stg:se.powerup00", fp(se .. "se_powerup.wav"))
        Sound.New("stg:se.extend", fp(se .. "se_extend.wav"))
        Sound.New("stg:se.cardget", fp(se .. "se_cardget.wav"))
        Sound.New("stg:se.border", fp(se .. "se_border.wav"))
        Sound.New("stg:se.select00", fp(se .. "se_select00.wav"))
        Sound.New("stg:se.cancel00", fp(se .. "se_cancel00.wav"))
        Sound.New("stg:se.ok00", fp(se .. "se_ok00.wav"))
        Sound.New("stg:se.pause", fp(se .. "se_pause.wav"))
        Sound.New("stg:se.gun00", fp(se .. "se_gun00.wav"))
        Sound.New("stg:se.kira00", fp(se .. "se_kira00.wav"))
        Sound.New("stg:se.kira01", fp(se .. "se_kira01.wav"))
    end)

    -- ==================== Music ====================
    LazyLoader.Add(function()
        Music.New("stg:bgm.menu", fp("Music\\luastg 0.08.540 - 1.27.800.ogg"))
        Music.New("stg:bgm.spellcard", fp("Music\\spellcard.ogg"))
        Music.New("stg:bgm.player_score", fp("Music\\player_score.ogg"))
    end)
end

-- Trigger import during lazy load phase
STG.Assets.Import()
