---@class STG
STG = {}

--TODO:如果要真完善的话，需要在很多地方尽量插入事件监听。


--region register button
local Input = Core.Input
Input.RegisterButton("Player.MoveUp", {
    Input.Keyboard.Key.Up,
})
Input.RegisterButton("Player.MoveDown", {
    Input.Keyboard.Key.Down,
})
Input.RegisterButton("Player.MoveLeft", {
    Input.Keyboard.Key.Left,
})
Input.RegisterButton("Player.MoveRight", {
    Input.Keyboard.Key.Right,
})
Input.RegisterButton("Player.Slow", {
    Input.Keyboard.Key.Shift
})
Input.RegisterButton("Player.Shoot", {
    Input.Keyboard.Key.Z
})
Input.RegisterButton("Player.Bomb", {
    Input.Keyboard.Key.X
})
Input.RegisterButton("Player.Special", {
    Input.Keyboard.Key.C
})


Input.RegisterAxis("Player.MoveHorizontal", function()
    return Input.ButtonPressed("Player.MoveLeft")
end, function()
    return Input.ButtonPressed("Player.MoveRight")
end)
Input.RegisterAxis("Player.MoveVertical", function()
    return Input.ButtonPressed("Player.MoveDown")
end, function()
    return Input.ButtonPressed("Player.MoveUp")
end)

--endregion
require("STG.Scripts.Animator")
require("STG.Scripts.Object")
require("STG.Scripts.Effect")
require("STG.Scripts.Shots")
require("STG.Scripts.Enemy")
require("STG.Scripts.Player")
require("STG.Scripts.Item")
require("STG.Scripts.Area")
require("STG.Scripts.System")