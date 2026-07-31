
---@class STG
STG = {}

require("STG.Constants")


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
require("STG.Animator")
require("STG.Object")
require("STG.Effect")
require("STG.Shots")
require("STG.Enemy")
require("STG.Player")
require("STG.Item")
require("STG.World")
require("STG.System")
require("STG.Replay")
require("STG.Run")
require("STG.Background")
require("STG.Stage")
require("STG.Layout")
require("STG.HUD")
require("STG.Pause")
require("STG.Menu")
require("STG.TestScene")

require("STG._Assets")