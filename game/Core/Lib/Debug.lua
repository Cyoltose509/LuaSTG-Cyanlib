---@author 璀境石
---@class Core.Lib.Debug
local M = {}
Core.Lib.Debug = M

--------------------------------------------------------------------------------
local imgui_exist, imgui = pcall(require, "imgui")


-- global cheat = false

local b_show_all = true
local b_show_menubar = false

local b_show_demo_window = false
local b_show_memuse_window = false
local b_show_framept_window = false
local b_show_testinput_window = false
local b_show_resmgr_window = false

function M.Available()
    return imgui_exist and true
end

function M.Update()
    if imgui_exist then
        local flag = false
        if b_show_all then
            flag = flag or b_show_menubar
            flag = flag or b_show_demo_window
            flag = flag or b_show_memuse_window
            flag = flag or b_show_framept_window
            flag = flag or b_show_testinput_window
            flag = flag or b_show_resmgr_window
        end
        imgui.backend.NewFrame(flag)
    end
end

local menu = {
    ["Reload"] = {},
    ["Test"] = {},
}

function M.AddMenu(name)
    menu[name] = {}
end

function M.DelMenu(name)
    menu[name] = nil
end

function M.DelMenuItem(menu_name, name)
    menu[menu_name][name] = nil
end

function M.AddButton(menu_name, name, func)
    menu[menu_name] = menu[menu_name] or {}
    menu[menu_name][name] = function()
        if imgui.ImGui.Button(name) then
            func()
        end
    end
end
---@param text string|fun():string
function M.AddText(menu_name, name, text)
    menu[menu_name] = menu[menu_name] or {}
    menu[menu_name][name] = function()
        local tmp = text
        if type(text) == "function" then
            tmp = text()
        end
        imgui.ImGui.Text(tmp)
    end
end
---func示例写法
---function(value)
---     xxx=value or xxx
---     return xxx
---end
---@param func fun(value:number):number
function M.AddSliderFloat(menu_name, name, func, minv, maxv)
    menu[menu_name] = menu[menu_name] or {}
    menu[menu_name][name] = function()
        local _, value = imgui.ImGui.SliderFloat(name, func(), minv, maxv)
        func(value)
    end
end
---func示例写法
---function(value)
---     xxx=value or xxx
---     return xxx
---end
---@param func fun(value:number):number
function M.AddSliderInt(menu_name, name, func, minv, maxv)
    menu[menu_name] = menu[menu_name] or {}
    menu[menu_name][name] = function()
        local _, value = imgui.ImGui.SliderInt(name, func(), minv, maxv)
        func(value)
    end
end

function M.Layout()
    --if F1_trigger() then
    --    b_show_all = not b_show_all
    --end
    if Core.Input.Keyboard.IsDown(Core.Input.Keyboard.Key.F3) then
        b_show_menubar = not b_show_menubar
    end
    if imgui_exist then
        imgui.ImGui.NewFrame()
        if b_show_all then
            if b_show_menubar then
                if imgui.ImGui.BeginMainMenuBar() then
                    for k, v in pairs(menu) do
                        if imgui.ImGui.BeginMenu(k) then
                            for _, item in pairs(v) do
                                item()
                            end
                            imgui.ImGui.EndMenu()
                        end
                    end
                    if imgui.ImGui.BeginMenu("Reload") then
                        -- 添加自己的按钮
                        --if imgui.ImGui.MenuItem("example") then lstg.DoFile("example.lua") end
                        imgui.ImGui.EndMenu()
                    end
                    if imgui.ImGui.BeginMenu("Test") then
                        imgui.ImGui.EndMenu()
                    end

                    if imgui.ImGui.BeginMenu("Tool") then
                        if imgui.ImGui.MenuItem("Memory Usage", nil, b_show_memuse_window) then
                            b_show_memuse_window = not b_show_memuse_window
                        end
                        if imgui.ImGui.MenuItem("Frame Statistics", nil, b_show_framept_window) then
                            b_show_framept_window = not b_show_framept_window
                        end
                        if imgui.ImGui.MenuItem("Test Input", nil, b_show_testinput_window) then
                            b_show_testinput_window = not b_show_testinput_window
                        end
                        if imgui.ImGui.MenuItem("Resource Manager", nil, b_show_resmgr_window) then
                            b_show_resmgr_window = not b_show_resmgr_window
                        end
                        if imgui.ImGui.MenuItem("Demo", nil, b_show_demo_window) then
                            b_show_demo_window = not b_show_demo_window
                        end
                        imgui.ImGui.EndMenu()
                    end
                    imgui.ImGui.EndMainMenuBar()
                end
            end

            if b_show_demo_window then
                b_show_demo_window = imgui.ImGui.ShowDemoWindow(b_show_demo_window)
            end
            if b_show_memuse_window and imgui.backend.ShowMemoryUsageWindow then
                b_show_memuse_window = imgui.backend.ShowMemoryUsageWindow(b_show_memuse_window)
            end
            if b_show_framept_window and imgui.backend.ShowFrameStatistics then
                b_show_framept_window = imgui.backend.ShowFrameStatistics(b_show_framept_window)
            end

            if b_show_testinput_window and imgui.backend.ShowTestInputWindow then
                b_show_testinput_window = imgui.backend.ShowTestInputWindow(b_show_testinput_window)
            end

            if b_show_resmgr_window and imgui.backend.ShowResourceManagerDebugWindow then
                b_show_resmgr_window = imgui.backend.ShowResourceManagerDebugWindow(b_show_resmgr_window)
            end
        end
        imgui.ImGui.EndFrame()
    end
end

function M.Draw()
    if imgui_exist then
        if b_show_all then
            imgui.ImGui.Render()
            imgui.backend.RenderDrawData()
        end
    end
end

