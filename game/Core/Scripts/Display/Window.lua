---@class Core.Display.Window
local M = {}
Core.Display.Window = M

M.width = 100
M.height = 100
M.fullscreen = false
M.vsync = true

local Window = require("lstg.Window")
local SwapChain = require("lstg.SwapChain")
local main_window = Window.getMain()
local main_swapchain = SwapChain.getMain()

---设置窗口大小
---Set the size of the window
function M.SetSize(w, h)
    main_swapchain:setSize(w, h)
    M.width = w
    M.height = h
end

---获取当前窗口的真实大小
---Get the real size of the current window
function M.GetClientAreaSize()
    local size = main_window:getClientAreaSize()
    return size.width, size.height
end

---获取当前窗口过去记录的大小
---Get the recorded size of the current window
function M.GetSize()
    return M.width, M.height
end

---是否为全屏模式
---Whether the window is in full screen mode
function M.IsFullscreen()
    return M.fullscreen
end

---设置全屏模式
---Set full screen mode
function M.SetFullscreen(fullscreen)
    M.fullscreen = fullscreen
    M.Refresh()
end

---是否为垂直同步
---Whether vertical synchronization is enabled
function M.IsVsync()
    return M.vsync
end

---设置垂直同步
---Set vertical synchronization
function M.SetVsync(vsync)
    M.vsync = vsync
    M.Refresh()
end


function M.Refresh()
    if not lstg.ChangeVideoMode(M.width, M.height, not M.fullscreen, M.vsync) then
        error("Failed to change video mode")
    end
end


M.SetSplash = lstg.SetSplash
M.SetTitle = lstg.SetTitle