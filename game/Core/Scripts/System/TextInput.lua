---@class Core.System.TextInput
local M = {}
Core.System.TextInput = M

local Window = require("lstg.Window")
---@type lstg.Window
local main_window = Window.getMain()
---@type lstg.Window.TextInputExtension
local text_input_ext = main_window:queryInterface("lstg.Window.TextInputExtension")
---@type lstg.Window.InputMethodExtension
local input_method_ext = main_window:queryInterface("lstg.Window.InputMethodExtension")

---刷新查询接口
function M.Refresh()
    main_window = Window.getMain()
    text_input_ext = main_window:queryInterface("lstg.Window.TextInputExtension")
    input_method_ext = main_window:queryInterface("lstg.Window.InputMethodExtension")
end

function M.Available()
    return text_input_ext and true
end
function M.IsEnabled()
    if text_input_ext then
        return text_input_ext:isEnabled()
    end
end
function M.SetEnabled(enabled)
    if text_input_ext then
        text_input_ext:setEnabled(enabled)
    end
end
function M.Clear()
    if text_input_ext then
        text_input_ext:clear()
    end
end
function M.Get()
    if text_input_ext then
        return text_input_ext:toString()
    end
end
function M.GetCursorPosition()
    if text_input_ext then
        return text_input_ext:getCursorPosition()
    end
end
function M.SetCursorPosition(position)
    if text_input_ext then
        text_input_ext:setCursorPosition(position)
    end
end
function M.AddCursorPosition(offset)
    if text_input_ext then
        text_input_ext:addCursorPosition(offset)
    end
end

---在指定位置插入文本
---这里有很诡异的bug，我觉得是要让底层修复的
---如果直接把中文插进去，就会出问题并崩溃
---Insert text at the specified position
---There is a bug here that I think needs to be fixed
---If you directly insert Chinese into it, it will crash and fail
---@param text string 要插入的文本
---@param position number?
---@overload fun(text:string)
function M.Insert(text, position)
    if text_input_ext then
        for _, c in string.utf8_codes(text) do
            if position then
                text_input_ext:insert(position, string.utf8_char(c))
            else
                text_input_ext:insert(string.utf8_char(c))
            end
            text_input_ext:setCursorPosition(text_input_ext:getCursorPosition() + 1)
        end
    end
end

---@overload fun()
---@overload fun(position:number, count:number)
---@overload fun(position:number)
function M.Remove(position, count)
    if text_input_ext then
        text_input_ext:remove(position, count)
    end
end

---@overload fun()
---@overload fun(count:number)
function M.Backspace(count)
    if text_input_ext then
        text_input_ext:backspace(count)
    end
end

function M.IsInputMethodEnabled()
    return input_method_ext and input_method_ext:isInputMethodEnabled()
end
function M.SetInputMethodEnabled(enabled)
    if input_method_ext then
        input_method_ext:setInputMethodEnabled(enabled)
    end
end
function M.SetInputMethodPosition(x, y)
    if input_method_ext then
        input_method_ext:setInputMethodPosition(x, y)
    end
end