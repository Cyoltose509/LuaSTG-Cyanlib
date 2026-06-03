---@class STG.Player.DefaultStyles
---Default player styles using STG.Animator with 3-row walk sheets (32x48, 8x3=24 frames).
local Register = STG.Player.Resource.Register

local function walkSheet3Row(ani, texture)
    local fw, fh = 32, 48
    for i = 1, 8 do
        ani:registerFrame("idle_" .. i, (i - 1) * fw, 0, fw, fh, texture)
    end
    for i = 1, 8 do
        ani:registerFrame("side_" .. i, (i - 1) * fw, fh, fw, fh, texture)
    end
    for i = 1, 8 do
        ani:registerFrame("back_" .. i, (i - 1) * fw, fh * 2, fw, fh, texture)
    end

    local idleFrames = {}
    for i = 1, 8 do idleFrames[i] = { id = "idle_" .. i } end
    ani:registerAnimation("idle_left", idleFrames, 6, true)
    ani:copyAnimation("idle_right", "idle_left")

    local sideFrames = {}
    for i = 1, 8 do sideFrames[i] = { id = "side_" .. i } end
    ani:registerAnimation("move_right_loop", sideFrames, 6, true)
    ani:copyAnimation("move_left_loop", "move_right_loop", false, true)
    -- Required by setupEnemyDefaultStates (no separate enter/exit frames yet)
    ani:copyAnimation("move_right_enter", "move_right_loop")
    ani:copyAnimation("move_right_exit", "move_right_loop")
    ani:copyAnimation("move_left_enter", "move_left_loop")
    ani:copyAnimation("move_left_exit", "move_left_loop")

    ani:setupEnemyDefaultStates({ moveThreshold = 0.5 })
end

Register("reimu_player"):addAnimator(function(a) walkSheet3Row(a, "stg:reimu_sheet") end)
Register("marisa_player"):addAnimator(function(a) walkSheet3Row(a, "stg:marisa_sheet") end)
