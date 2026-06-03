---@class STG.Run.GameScene
local M = {}
STG.Run.GameScene = M

---Create a new gameplay scene.
---This is a SceneManager-compatible scene with init/frame/del lifecycle.
---
---Usage:
---   local scene = STG.Run.GameScene.New({
---       difficulty = "NORMAL",
---       stage = 1,
---       onStageSetup = function(run) ... end,
---   })
---   Core.SceneManager.NewScene("gameplay", scene)
---   Core.SceneManager.SetScene("gameplay")
---
---@param opt table
---@return table scene
function M.New(opt)
    opt = opt or {}
    local scene = {}
    local run
    local player

    function scene:init()
        -- Create the Run orchestrator
        run = STG.Run.New({
            difficulty = opt.difficulty,
            stage = opt.stage,
            lives = opt.lives,
            bombs = opt.bombs,
            replay_mode = opt.replay_mode,
            replay_data = opt.replay_data,
            seed = opt.seed,
            character = opt.character,
        })

        -- Create player
        local w = Core.World.GetMain()
        player = STG.Player.Spawn(
            opt.player_x or (w.l + w.r) / 2,
            opt.player_y or (w.b + w.t) / 2,
            opt.player_profile
        )
        run.player = player

        -- Set up stage-specific logic
        if opt.onStageSetup then
            opt.onStageSetup(run, player)
        end

        run:start()
    end

    function scene:frame()
        if not run then
            return
        end

        local state = run.sm:getCurrentStateName()

        if state == "playing" then
            run:update(player.time:getDelta())

            -- Call stage-specific frame logic
            if opt.onStageFrame then
                opt.onStageFrame(run, player)
            end
        elseif state == "paused" then
            -- Only handle pause input
            STG.Pause.Update()
            if not STG.Pause.IsPaused() then
                run:resume()
            end
        elseif state == "result" or state == "ending" then
            -- Transition to result scene
            if opt.onGameEnd then
                opt.onGameEnd(run, player)
            end
        end
    end

    function scene:del()
        if run then
            run:_finalizeReplay()
        end
        run = nil
        player = nil
        STG.Run.Current = nil
        STG.Pause.ForceResume()
    end

    return scene
end

return M
