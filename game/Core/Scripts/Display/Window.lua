---@class Core.Display.Window
local M = {}
Core.Display.Window = M

M.ResponsiveLayout = true
M.window_width = 100
M.window_height = 100

local Display = require("lstg.Display")
local Window = require("lstg.Window")
local SwapChain = require("lstg.SwapChain")
local main_display
for _, d in ipairs(Display.getAll()) do
    if d:isPrimary() then
        main_display = d
    end
end
local main_window = Window.getMain()
local main_swapchain = SwapChain.getMain()

function M.SetSize(w, h)
    main_swapchain:setSize(w, h)
    M.window_width = w
    M.window_height = h
end

function M.GetClientAreaSize()
    local size = main_window:getClientAreaSize()
    return size.width, size.height
end
function M.GetSize()
    return M.window_width, M.window_height
end
function M.SetResponsiveLayout(flag)
    M.ResponsiveLayout = flag
end

---@param set Core.Data.Setting.Settings
function M.ChangeVideoMode(set)
    set = set or Core.Data.Setting.Get()
    local gs = set.graphics_system
    if not gs.fullscreen then
        if lstg.ChangeVideoMode(gs.width, gs.height, not gs.fullscreen, gs.vsync) then
            M.window_width = gs.width
            M.window_height = gs.height
        else
            error("Failed to change video mode")
        end
    else
        local w, h = Core.Display.GetResolution()
        if lstg.ChangeVideoMode(w, h, not gs.fullscreen, gs.vsync) then
            M.window_width = w
            M.window_height = h
        else
            error("Failed to change video mode")
        end
    end
end

M.SetSplash = lstg.SetSplash
M.SetTitle = lstg.SetTitle