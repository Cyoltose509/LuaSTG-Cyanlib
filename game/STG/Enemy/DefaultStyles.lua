---@class STG.Enemy.DefaultStyles
---Default enemy styles using STG.Animator with texture UV coordinates.
local Register = STG.Enemy.Resource.Register
local ColorID = STG.Enemy.Color

---Register frames from a single row in a texture.
local function rowGrid(ani, texture, y, w, h, count)
    for i = 1, count do
        ani:registerFrame("f" .. i, (i - 1) * w, y, w, h, texture)
    end
    local frames = {}
    for i = 1, count do
        frames[i] = { id = "f" .. i }
    end
    ani:registerAnimation("idle", frames, 10000, true)
    ani:copyAnimation("idle_left", "idle")
    ani:copyAnimation("idle_right", "idle")
    -- Simple idle-only state machine (no move/cast transitions)
    ani.walkSystem:registerAnimationState("idle_left")
      :registerAnimationState("idle_right")
    ani.walkSystem.stateMachine:setState("idle_left")
end

---Single-frame idle from a texture.
local function singleFrame(ani, texture, x, y, w, h)
    ani:registerFrame("f1", x, y, w, h, texture)
    ani:registerAnimation("idle", {{ id = "f1" }}, 10000, true)
    ani:copyAnimation("idle_left", "idle")
    ani:copyAnimation("idle_right", "idle")
    ani.walkSystem:registerAnimationState("idle_left")
      :registerAnimationState("idle_right")
    ani.walkSystem.stateMachine:setState("idle_left")
end

-- ========================================
-- enemy1.png (512x512)
-- ========================================
local T1 = "stg:enemy1"

Register("petticoat_lantern_fairy_gray", 24, ColorID.Gray)
    :addAnimator(function(a) rowGrid(a, T1, 384, 32, 32, 12) end)
Register("petticoat_lantern_fairy_red", 24, ColorID.Red)
    :addAnimator(function(a) rowGrid(a, T1, 416, 32, 32, 12) end)
Register("petticoat_lantern_fairy_orange", 24, ColorID.Orange)
    :addAnimator(function(a) rowGrid(a, T1, 448, 32, 32, 12) end)

Register("uniform_horn_fairy_purple", 24, ColorID.Purple)
    :addAnimator(function(a) rowGrid(a, T1, 0, 48, 32, 12) end)   -- enemy5_ y=0
Register("uniform_horn_fairy_orange", 24, ColorID.Orange)
    :addAnimator(function(a) rowGrid(a, T1, 96, 48, 32, 12) end)   -- enemy6_ y=96

Register("flower_fairy_small_red", 8, ColorID.Red)
    :addAnimator(function(a) rowGrid(a, T1, 192, 64, 64, 12) end)  -- enemy9_ y=192
Register("flower_fairy_small_blue", 8, ColorID.Blue)
    :addAnimator(function(a) singleFrame(a, T1, 0, 0, 32, 32) end)  -- first sub-image

Register("large_fairy_red", 48, ColorID.Red)
    :addAnimator(function(a) singleFrame(a, T1, 320, 0, 48, 48) end) -- enemy7_
Register("large_fairy_blue", 48, ColorID.Blue)
    :addAnimator(function(a) singleFrame(a, T1, 320, 144, 48, 48) end) -- enemy8_

-- ========================================
-- enemy2.png
-- ========================================
local T2 = "stg:enemy2"

Register("advanced_fairy_red", 64, ColorID.Red)
    :addAnimator(function(a) rowGrid(a, T2, 0, 32, 32, 12) end)     -- enemy10_
Register("advanced_fairy_blue", 64, ColorID.Blue)
    :addAnimator(function(a) rowGrid(a, T2, 32, 32, 32, 12) end)    -- enemy11_

-- ========================================
-- enemy3.png
-- ========================================
local T3 = "stg:enemy3"

Register("ghost_red", 16, ColorID.Red)
    :addAnimator(function(a) rowGrid(a, T3, 0, 32, 32, 8) end)      -- Ghost1
Register("ghost_blue", 16, ColorID.Blue)
    :addAnimator(function(a) rowGrid(a, T3, 32, 32, 32, 8) end)     -- Ghost2
Register("ghost_green", 16, ColorID.Green)
    :addAnimator(function(a) rowGrid(a, T3, 64, 32, 32, 8) end)     -- Ghost3

-- ========================================
-- Boss / orb sprites — default swirling "undefined" + override texture
-- ========================================
---Simplest possible animator: single frame, no state machine, just set currentFrame directly.
---Used for boss default and orb sprites.
local function simpleStatic(ani, texture, x, y, w, h)
    ani.walkSystem:registerFrame("f1", x, y, w, h, texture)
    ani.walkSystem:registerAnimation("idle", {{ id = "f1" }}, 10000, true)
    -- Directly set current frame bypassing state machine
    local anim = ani.walkSystem.animations["idle"]
    if anim and anim.frames and anim.frames[1] then
        ani.walkSystem.currentAnimation = anim
        ani.walkSystem.currentFrame = anim.frames[1]
        ani.walkSystem.animationIndex = 1
    end
end

-- Boss default (no specific image): swirling undefined
Register("boss_default", 160, ColorID.Red)
    :addAnimator(function(a) simpleStatic(a, "stg:enemy.undefined", 0, 0, 128, 128) end)

-- Yinyang orb: use enemy1 texture (verified working) at a distinctive location
Register("yinyang_orb_red", 40, ColorID.Red)
    :addAnimator(function(a) simpleStatic(a, "stg:enemy1", 0, 192, 64, 64) end)

local colorNames = {"purple","blue","cyan","green","yellow","orange","gray"}
for _, c in ipairs(colorNames) do
    Register("yinyang_orb_" .. c, 40, ColorID[c:sub(1,1):upper() .. c:sub(2)] or ColorID.Red)
        :addAnimator(function(a) simpleStatic(a, "stg:enemy1", 0, 192, 64, 64) end)
end
