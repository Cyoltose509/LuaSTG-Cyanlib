---@class Core.SceneManager
local M = {}
Core.SceneManager = M

---@type table<string, Core.SceneManager.Scene>
M.scenes = {}

---@type Core.SceneManager.Scene
M.next = nil
---@type Core.SceneManager.Scene
M.current = nil

---创建新场景
---注意，渲染行为将不再由Scene管理，请在Camera中添加渲染事件
---Scene的del方法将极为重要，记得在del中清理资源
function M.NewScene(name)
    ---@class Core.SceneManager.Scene
    local self = {  }
    function self:init()
    end
    function self:frame()
    end
    function self:del()

    end
    self.name = name
    M.scenes[name] = self
    return self
end

function M.SetScene(name)
    M.next = assert(M.scenes[name], "Scene not found: " .. name)
end

function M.GetCurrent()
    return M.current
end

---每帧更新
function M.Update()
    if M.next then
        Core.MainLoop.OnSceneChangeBefore()
        if M.current then
            M.current:del()
        end
        M.next:init()
        M.current=M.next
        M.next = nil
        Core.MainLoop.OnSceneChangeAfter()
    end
    if M.current then
        M.current:frame()
    end
end

function M.Restart()
    M.next = M.current
end
