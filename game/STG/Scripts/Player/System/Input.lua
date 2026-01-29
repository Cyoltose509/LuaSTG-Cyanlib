local base = STG.Player.System.SystemBase

---@class STG.Player.System.Input:STG.Player.System.SystemBase
local M = Core.Class(base)
STG.Player.System.Input = M

local Input = Core.Input
local Vec2 = Core.Math.Vector2

---@param player STG.Player.Base
function M:init(player, system)
    base.init(self, player, system)
    self.move = Vec2.zero
    self.move_axis_h = 0
    self.move_axis_v = 0

    self.slow = false
    self.shoot = false
    self.bomb = false
    self.special = false

end
function M:update()
    self.move_axis_h = Input.GetAxis("Player.MoveHorizontal")
    self.move_axis_v = Input.GetAxis("Player.MoveVertical")
    self.move = Vec2.New(self.move_axis_h, self.move_axis_v)
    local len = self.move:magnitude()
    if len > 1 then
        self.move:normalize()
    end

    self.slow = Input.ButtonPressed("Player.Slow")
    self.shoot = Input.ButtonPressed("Player.Shoot")
    self.bomb = Input.ButtonPressed("Player.Bomb")
    self.special = Input.ButtonPressed("Player.Special")

end