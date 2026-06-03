---@class STG.Background
---Full-screen background rendered as a game object in STG 2D camera.
local M = {}
STG.Background = M

local Object = STG.Object
local Render = Core.Render

local BgObj = Object.Define()
function BgObj:init(sprite_name)
    self.img = sprite_name
    self.layer = Object.Layer.BG3D
    self.group = Object.Group.Ghost
    self.bound = false
end
function BgObj:frame() end
function BgObj:render()
    if not self.img then return end
    -- Full-screen quad at z=0, camera at z=-8, fov=60
    -- Covers the visible area: at distance 8, half-height = 8*tan(30) ≈ 4.6
    local s = 5.0
    Render.SetSpriteState(self.img, "", 255, 255, 255, 255)
    lstg.Render4V(self.img,
        -s,  s, 0, 0, 0,
         s,  s, 0, 1, 0,
         s, -s, 0, 1, 1,
        -s, -s, 0, 0, 1)
end

---Load and spawn background. Returns the background object.
---@param name string Background folder name under STG/Assets/Background/
---@return Core.Object.Base|nil
function M.Load(name)
    local dir = "STG\\Assets\\Background\\" .. name .. "\\"
    local files = lstg.FileManager.EnumFiles(dir, "png", false)
    if not files then return nil end
    for _, f in ipairs(files) do
        local ok = pcall(Core.Resource.Sprite.NewFromFile, "stg:bg_" .. name, f[1])
        if ok then
            return Object.New(BgObj, "stg:bg_" .. name)
        end
    end
    return nil
end
