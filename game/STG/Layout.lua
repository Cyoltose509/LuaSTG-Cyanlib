---@class STG.Layout
---STG game window layout: centered play area + right-side HUD panel.
---World 384x448 mapped via 2D camera to a centered viewport.
local M = {}
STG.Layout = M

local Render = Core.Render
local Object = STG.Object

-- World dimensions (centered at origin)
M.WORLD_L = -192
M.WORLD_R = 192
M.WORLD_B = -224
M.WORLD_T = 224
M.WORLD_W = M.WORLD_R - M.WORLD_L   -- 384
M.WORLD_H = M.WORLD_T - M.WORLD_B   -- 448
M.BOUND_MARGIN = 32

---@param px_w number Window width in physical pixels
---@param px_h number Window height in physical pixels
---@param panel_w number|nil HUD panel width (default 260)
---@param panel_gap number|nil Gap between game and panel (default 16)
---@return table
function M.CalcViewport(px_w, px_h, panel_w, panel_gap)
    panel_w = panel_w or 260
    panel_gap = panel_gap or 16
    local world_aspect = M.WORLD_W / M.WORLD_H

    local game_h = math.floor(px_h * 0.78)
    local game_w = math.floor(game_h * world_aspect)
    local game_l = math.floor((px_w - game_w) / 2)
    local game_r = game_l + game_w
    local game_b = math.floor((px_h - game_h) / 2)
    local game_t = game_b + game_h
    local panel_l = game_r + panel_gap
    local panel_r = panel_l + panel_w

    return {
        game_l = game_l, game_r = game_r,
        game_b = game_b, game_t = game_t,
        panel_l = panel_l, panel_r = panel_r,
        game_w = game_w, game_h = game_h,
    }
end

---Setup STG layout on a scene. Returns { camera, hud_root, viewport }.
---@param scene table
---@param panel_width number|nil
---@return table
function M.Setup(scene, panel_width)
    local px_w, px_h = Core.Display.Window.GetSize()
    local sw, sh = Core.Display.Screen.GetSize()
    local L = M.CalcViewport(px_w, px_h, panel_width)

    -- 3D background camera (priority -1, renders behind 2D layer)
    local bg_cam = Core.Display.Camera3D():register(-1)
    bg_cam.fov = 60
    bg_cam.z_near = 0.1
    bg_cam.z_far = 100
    bg_cam.z_buffer_enable = true
    bg_cam.x, bg_cam.y, bg_cam.z = 0, 0, -8
    bg_cam:setViewport(L.game_l, L.game_r, L.game_b, L.game_t)
    bg_cam:captureLayers("STG", Object.Layer.BG3D - 10, Object.Layer.BG3D + 10)

    -- 2D combat camera (priority 0)
    local stg_cam = Core.Display.Camera2D():register(0)
    stg_cam:setView(0, 0, M.WORLD_W, M.WORLD_H)
    stg_cam:setViewport(L.game_l, L.game_r, L.game_b, L.game_t)
    stg_cam:captureLayers("STG", -10000, 10000)

    Core.World.New(M.WORLD_L, M.WORLD_R, M.WORLD_B, M.WORLD_T, M.BOUND_MARGIN):apply()

    local hud_root = Core.UI.Manager.CreateHUDRoot("STG.HUD", 1)

    -- Frame border in UI logical coords
    local px_to_lx = sw / px_w
    local px_to_ly = sh / px_h
    hud_root:addChild(Core.UI.Immediate("stg_frame", -100, function()
        M._drawFrame(L, px_to_lx, px_to_ly)
    end))

    scene._bg_cam = bg_cam
    scene._stg_cam = stg_cam
    scene._stg_layout = L
    scene._stg_px_to_lx = px_to_lx
    scene._stg_px_to_ly = px_to_ly

    return {
        camera = stg_cam,
        hud_root = hud_root,
        viewport = { l = L.game_l, r = L.game_r, b = L.game_b, t = L.game_t },
    }
end

function M._drawFrame(L, px_to_lx, px_to_ly)
    local Draw = Render.Draw
    local bw = 2 * px_to_lx
    local gl = L.game_l * px_to_lx
    local gr = L.game_r * px_to_lx
    local gb = L.game_b * px_to_ly
    local gt = L.game_t * px_to_ly
    local pl = L.panel_l * px_to_lx
    local pr = L.panel_r * px_to_lx

    Draw.SetState(Render.BlendMode.Default, Render.Color(200, 140, 150, 160))
    Draw.Rect(gl - bw, gl, gb - bw, gt + bw)
    Draw.Rect(gr, gr + bw, gb - bw, gt + bw)
    Draw.Rect(gl - bw, gr + bw, gb - bw, gb)
    Draw.Rect(gl - bw, gr + bw, gt, gt + bw)

    Draw.SetState(Render.BlendMode.Default, Render.Color(50, 20, 18, 35))
    Draw.Rect(pl, pr, gb, gt)

    Draw.SetState(Render.BlendMode.Default, Render.Color(80, 120, 130, 140))
    Draw.Rect(gr + 1 * px_to_lx, gr + 3 * px_to_lx, gb, gt)
end

function M.Cleanup(scene)
    if scene._stg_cam then
        scene._stg_cam:release()
        scene._stg_cam = nil
    end
    if scene._bg_cam then
        scene._bg_cam:release()
        scene._bg_cam = nil
    end
end

---@return table|nil { left, right, bottom, top, centerX, centerY }
function M.GetPanelRect(scene)
    local L = scene._stg_layout
    if not L then return nil end
    local plx = scene._stg_px_to_lx or 1
    local ply = scene._stg_px_to_ly or 1
    return {
        left   = L.panel_l * plx,
        right  = L.panel_r * plx,
        bottom = L.game_b * ply,
        top    = L.game_t * ply,
        centerX = (L.panel_l + L.panel_r) / 2 * plx,
        centerY = (L.game_b + L.game_t) / 2 * ply,
    }
end

return M
