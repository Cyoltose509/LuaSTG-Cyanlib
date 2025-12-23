local Core = Core

---@class Test.DataVisual.Scene : Core.SceneManager.Scene
local M = Core.SceneManager.NewScene("Test.DataVisual")
Test.DataVisual.Scene = M

local colors = {
    string = { 135, 220, 120 },
    number = { 100, 150, 150 },
    boolean = { 200, 100, 100 },
    table = { 255, 255, 255 },
    ["function"] = { 150, 150, 255 },
    userdata = { 255, 227, 132 },
    thread = { 135, 206, 235 }
}
function M:newNode(name, position, parent, is_static)
    local nodeType = type(position)
    name = name or "Node"
    if nodeType == "function" then
        name = name .. "()"
    end
    ---@class Test.Node
    local node = {
        name = name,
        position = position,
        color = colors[nodeType],
        parent = parent,
        is_static = is_static,
        children = {},
        r = parent and parent.r * 0.9 or 30,
        x = parent and parent.x or 0,
        y = parent and parent.y or 0,
        z = parent and parent.z or 0,
        vx = 0,
        vy = 0,
        vz = 0,
        fx = 0,
        fy = 0,
        fz = 0,
        hide = true,
        alpha = 0,
        aim = 0,
        mass = 1,

    }
    local function addmass(me)
        if me.parent then
            me.parent.r = me.parent.r + (-me.parent.r + 60) * 0.1
            addmass(me.parent)
        end
    end
    --addmass(node)
    table.insert(self.nodes, node)
    return node
end
local T=1
function M:fullScreenEffect()
    --[[
    self.camera:shake(30, 5, 1, 1.5, 1)
    local _T=T
    T=T+1
    Core.Task.New(self, function()

        for k = 1, 20 do
            Core.Render.ScreenRT.Do(_T, Core.Effect.Post.Glitch(10 * (1 - k / 20), 0.1, 100, 10))
            --Core.Render.ScreenRT.Do(_T*2, Core.Effect.Post.RadialChromatic(0.05* (1 - k / 20)))
            Core.Task.Wait()

        end
        --Core.Render.ScreenRT.Stop()
    end)--]]
end

function M:spawnNodes(parentNode, max_depth)
    local position = parentNode.position
    if type(position) == "table" and max_depth > 0 and position ~= M then
        for module, map in pairs(position) do
            if type(module) ~= "number" then
                --一种减少大量无效节点的方式
                local new = true
                for _, node in pairs(self.nodes) do
                    if node.name == module or node.name == tostring(module) .. '()' then
                        new = false
                        break
                    end
                end
                if new then
                    local node = self:newNode(module, map, parentNode)
                    table.insert(parentNode.children, node)
                    self:spawnNodes(node, max_depth - 1)
                end
            end
        end
    end

end

function M:updateGraph()
    local spring_k = self.spring_k      -- 弹簧强度
    local spring_length = self.spring_length  -- 期望距离
    local repulsion_k = self.repulsion_k * (1)  -- 斥力
    local gravity = self.gravity  --
    local groundY = -1000

    for _, n in ipairs(self.nodes) do
        n.fx = 0
        n.fy = 0
        n.fz = 0
    end

    for _, n in ipairs(self.nodes) do
        if n.parent and not n.hide then
            local p = n.parent
            local dx = n.x - p.x
            local dy = n.y - p.y
            local dz = n.z - p.z
            if dx == 0 and dy == 0 and dz == 0 then
                dx = ran:Float(-1, 1)
                dy = ran:Float(-1, 1)
                dz = ran:Float(-1, 1)
            end
            local dist = sqrt(dx * dx + dy * dy + dz * dz)
            if dist < 1 then
                dist = 1
            end

            local diff = dist - spring_length * sqrt(#n.parent.children + 1 + #n.children)
            local force = spring_k * diff

            local fx = force * dx / dist
            local fy = force * dy / dist
            local fz = force * dz / dist

            n.fx = n.fx - fx
            n.fy = n.fy - fy
            n.fz = n.fz - fz
            p.fx = p.fx + fx
            p.fy = p.fy + fy
            p.fz = p.fz + fz
        end
    end
    --]]
    for i = 1, #self.nodes do
        local a = self.nodes[i]
        for j = i + 1, #self.nodes do
            local b = self.nodes[j]
            if not a.hide and not b.hide then
                local dx = a.x - b.x
                local dy = a.y - b.y
                local dz = a.z - b.z
                local dist2 = dx * dx + dy * dy + dz * dz
                if dx == 0 and dy == 0 and dz == 0 then
                    dx = ran:Float(-1, 1)
                    dy = ran:Float(-1, 1)
                    dz = ran:Float(-1, 1)
                end
                if dist2 < 1 then
                    dist2 = 1
                end
                local dist = sqrt(dist2)

                local force = min(10, repulsion_k / dist2)
                force = force * a.mass * b.mass
                local fx = force * dx / dist
                local fy = force * dy / dist
                local fz = force * dz / dist

                a.fx = a.fx + fx
                a.fy = a.fy + fy
                a.fz = a.fz + fz
                b.fx = b.fx - fx
                b.fy = b.fy - fy
                b.fz = b.fz - fz
            end
        end
    end
    for _, n in ipairs(self.nodes) do
        if not n.is_static and not n.hide then
            local maxf = 10
            --[[
            local boundf = 3
            if n.x - n.r < w.l then
                n.fx = n.fx + (w.l - (n.x - n.r)) * boundf
            end
            if n.x + n.r > w.r then
                n.fx = n.fx + (w.r - (n.x + n.r)) * boundf
            end
            if n.y + n.r > w.t then
                n.fy = n.fy + (w.t - (n.y + n.r)) * boundf
            end
            if n.y - n.r < w.b then
                n.fy = n.fy + (w.b - (n.y - n.r)) * boundf
            end--]]
            n.fy = n.fy - gravity
            if n.y - n.r < groundY then
                n.fy = n.fy + (groundY - n.y + n.r) * 0.1
            end
            n.fx = clamp(n.fx, -maxf, maxf)
            n.fy = clamp(n.fy, -maxf, maxf)
            n.fz = clamp(n.fz, -maxf, maxf)
            n.vx = n.vx + n.fx / n.mass
            n.vy = n.vy + n.fy / n.mass
            n.vz = n.vz + n.fz / n.mass
            n.vx = n.vx * 0.9
            n.vy = n.vy * 0.9
            n.vz = n.vz * 0.9
            n.x = n.x + n.vx
            n.y = n.y + n.vy
            n.z = n.z + n.vz

        end

    end

    local aim_node
    local mx, my = Core.Input.Mouse.GetPosition()
    for i = #self.nodes, 1, -1 do
        local n = self.nodes[i]
        if n.hide then
            n.alpha = max(0, n.alpha - 0.05)
            if n.parent then
                n.x = n.x + (n.parent.x - n.x) * (1 - n.alpha)
                n.y = n.y + (n.parent.y - n.y) * (1 - n.alpha)
                n.z = n.z + (n.parent.z - n.z) * (1 - n.alpha)
            end
            if n.alpha <= 0 and #n.children == 0 then
                if n.parent then
                    for j, child in ipairs(n.parent.children) do
                        if child == n then
                            table.remove(n.parent.children, j)
                            break
                        end
                    end
                end
                table.remove(self.nodes, i)
            end
        else
            n.alpha = min(1, n.alpha + 0.1)
        end
        local np = Core.Math.Vector3.New(n.x, n.y, n.z)
        local plane = Core.Math.Plane.New(np, Core.Math.Vector3.New(self.camera:getForward()))
        local p = self.camera:screenToRay(mx, my, true):intersectPlane(plane)
        if p and (p - np):magnitude() < n.r and not n.hide then
            n.aim = n.aim + (-n.aim + 1) * 0.1
            aim_node = n
        else
            n.aim = n.aim * 0.9
        end
    end
    local Mouse = Core.Input.Mouse
    if aim_node then
        if Mouse.IsDown(Mouse.Key.Left) then
            self.selected_node = aim_node
            self.dragging.node = self.selected_node
            local np = Core.Math.Vector3.New(self.selected_node.x, self.selected_node.y, self.selected_node.z)
            local plane = Core.Math.Plane.New(np, Core.Math.Vector3.New(self.camera:getForward()))
            local start = self.camera:screenToRay(mx, my, true):intersectPlane(plane)
            self.dragging.start_x = start.x
            self.dragging.start_y = start.y
            self.dragging.start_z = start.z
            self.dragging.node_x = self.selected_node.x
            self.dragging.node_y = self.selected_node.y
            self.dragging.node_z = self.selected_node.z
            self.dragging.timer = 0
            self.dragging.stop_act = false
        end
    end
    if self.selected_node then
        if Mouse.IsPressed(Mouse.Key.Left) then
            local np = Core.Math.Vector3.New(self.selected_node.x, self.selected_node.y, self.selected_node.z)
            local plane = Core.Math.Plane.New(np, Core.Math.Vector3.New(self.camera:getForward()))
            local n = self.camera:screenToRay(mx, my, true):intersectPlane(plane)
            if n then
                local dx = n.x - self.dragging.start_x
                local dy = n.y - self.dragging.start_y
                local dz = n.z - self.dragging.start_z
                self.selected_node.x = self.dragging.node_x + dx
                self.selected_node.y = self.dragging.node_y + dy
                self.selected_node.z = self.dragging.node_z + dz
                if (abs(dx) > 1e-2 or abs(dy) > 1e-2 or abs(dz) > 1e-2) and self.dragging.timer > 10 then
                    self.dragging.stop_act = true
                end
            end
            self.dragging.timer = self.dragging.timer + 1

        end
        if Mouse.IsUp(Mouse.Key.Left) then
            if not self.dragging.stop_act then
                if #self.selected_node.children == 0 then
                    self:spawnNodes(self.selected_node, 1)
                    self:fullScreenEffect()
                end
                for _, child in ipairs(self.selected_node.children) do
                    child.hide = not child.hide
                end
            end
            self.selected_node = nil


        end
    end
    if Core.Input.IsDown(Core.Input.Keyboard.Key.Z) then
        local open_list = {}
        for _, n in ipairs(self.nodes) do
            local nohide = {}
            for _, child in ipairs(n.children) do
                if not child.hide then
                    table.insert(nohide, child)
                end
            end
            if #nohide == 0 and not n.hide then
                table.insert(open_list, n)
            end
        end
        if #open_list > 0 then
            self:fullScreenEffect()
            for _, n in ipairs(open_list) do
                self:spawnNodes(n, 1)
                for _, child in ipairs(n.children) do
                    child.hide = false
                end
            end
        end

    elseif Core.Input.IsDown(Core.Input.Keyboard.Key.X) then
        local close_list = {}
        for _, n in ipairs(self.nodes) do
            local nohide = {}
            for _, child in ipairs(n.children) do
                if not child.hide then
                    table.insert(nohide, child)
                end
            end
            if #nohide == 0 and not n.hide then
                table.insert(close_list, n)
            end
        end
        for _, n in ipairs(close_list) do
            n.hide = true
        end
    end
end

function M:init()
    ---@type Test.Node[]
    self.nodes = {}
    self.spring_k = 0.01
    self.spring_length = 60
    self.repulsion_k = 900
    self.gravity = 1

    ---@type Test.Node
    self.selected_node = nil
    self.dragging = {
        node = nil,
        start_x = 0,
        start_y = 0,
        start_z = 0,
        node_x = 0, node_y = 0, node_z = 0,
        stop_act = false,
        timer = 0,
    }
    --  require("lstg.RenderTarget").create()

    -- self:newNode("Core", Core, nil).hide = false
    self:newNode("Core", Core, nil).hide = false

    Core.Lib.Debug.AddButton("Test", "Add lstg node", function()
        self:newNode("lstg", lstg, nil).hide = false
    end)
    Core.Lib.Debug.AddButton("Test", "Add Core node", function()
        self:newNode("Core", Core, nil).hide = false
    end)
    Core.Resource.Music.Get("test"):fadePlay(60)

    self.skybox = Core.Render.Skybox.NewSphere("Test\\Assets\\Textures\\night.jpg")

    local scale = 10000
    self.skybox:setScale(scale, scale, scale):setLegacyBlendState("mul+add")
    self.camera = Core.Display.Camera3D()
    self.camera:setSkybox(self.skybox):setResponsiveViewport(true):register(2)
    self.camera:setPosition(0, 0, -1000)
    self.camera:setViewDistance(0.2, 15000)
    self.camera:addBeforeRenderEvent("plane", 1, function()
        Core.Render.Draw.SetState(Core.Render.BlendMode.Default, Core.Render.Color(100, 255, 255, 255))
        local s = 10000
        local Y = -1000
        Core.Render.Draw.Quad(-s, Y, s, s, Y, s, s, Y, -s, -s, Y, -s)
    end)
    self.camera_controller =Test.Camera.Controller3D(self.camera)--]

    self.ui_root = Test.DataVisual.UI.Main(self)
    self.keyTriggerList = {}
    self.keyTriggerShow = true


end

function M:frame()
    self.skybox:setRotationYawPitchRoll(self.timer * 0.0001, sin(self.timer * 0.0002) * 0.1, 0)
    local lastkey = self.keyTriggerShow and Core.Input.GetLast()
    if lastkey then
        table.insert(self.keyTriggerList, 1, {
            key = lastkey,
            name = Core.Input.GetKeyName(lastkey, true),
            timer = 0,
            pos = 1,
            alpha = 0,
        })
    end
    for i = #self.keyTriggerList, 1, -1 do
        local v = self.keyTriggerList[i]
        v.timer = v.timer + 1
        v.pos = v.pos + (-v.pos + i) * 0.1
        if v.timer > 50 then
            v.alpha = max(0, v.alpha - 0.05)
            if v.alpha == 0 then
                table.remove(self.keyTriggerList, i)
            end
        else
            v.alpha = min(1, v.alpha + 0.1)
        end
    end
    self:updateGraph()
    if self.camera_controller then
        self.camera_controller:frame()
    end
    Core.Display.Window.SetTitle("Data visualizer test | Objects: " .. lstg.GetnObj())
end

function M:del()
    self.camera:release()
    self.ui_root:release()
end

--[[
function M:render()
    self.default_camera:apply()



    self.camera:apply(self.skybox)


    Core.Render.Draw.SetState(Core.Render.BlendMode.MulAdd, Core.Render.Color(100, 255, 227, 132))
    local w = 3
    local L = 10000
    Core.Render.Draw.Quad(-w, L, 0, w, L, 0, w, -L, 0, -w, -L, 0)
    Core.Render.Draw.Quad(0, L, -w, 0, L, w, 0, -L, w, 0, -L, -w)

    Core.Render.Draw.Quad(L, -w, 0, L, w, 0, -L, w, 0, -L, -w, 0)
    Core.Render.Draw.Quad(L, 0, -w, L, 0, w, -L, 0, w, -L, 0, -w)

    Core.Render.Draw.Quad(-w, 0, L, w, 0, L, w, 0, -L, -w, 0, -L)
    Core.Render.Draw.Quad(0, -w, L, 0, w, L, 0, w, -L, 0, -w, -L)

local world = self.world:getParams()

self.camera:apply()
Core.Render.Draw.SetState(Core.Render.BlendMode.MulAdd, Core.Render.Color(255, 255, 255, 255))
Core.Render.Draw.RectOutline(world.centerX, world.centerY, world.width, world.height, 0, -5)

            local mx, my =Core.Input.Mouse.GetPosition(self.camera, 0.5)
            Core.Render.Draw.SetState(Core.Render.BlendMode.Default, Core.Render.Color(255, 100, 100, 255))
            Core.Render.Draw.Line(mx, my, 0,30,30,0.5)

    for _, m in ipairs(self.nodes) do
        local s = m.aim
        local A = m.alpha * (0.7 + s * 0.3)
        local size = m.r + s * 3
        local r, g, b = m.color[1], m.color[2], m.color[3]
        local x, y = m.x, m.y
        Core.Render.Draw.SetState(Core.Render.BlendMode.Default, Core.Render.Color(150 * A, r, g, b))
        Core.Render.Draw.Sector(x, y, 0, size, 0, 360, 15)
        --Core.Render.Text("exo2", ("%s"):format(m.name), x, y - m.r * 1.4,
        --      0.6, Core.Render.Color(200 * A, 255, 255, 255), "centerpoint")

        if false then
            --力的渲染
            local multi = 100
            local fx, fy = m.fx * multi, m.fy * multi
            Core.Render.Draw.SetState(Core.Render.BlendMode.MulAdd, Core.Render.Color(100 * A, 255, 0, 0))
            Core.Render.Draw.Line(x + fx / 2, y + fy / 2, atan2(fy, fx), hypot(fx, fy), 6)
        end
        if m.parent then
            Core.Render.Draw.SetState(Core.Render.BlendMode.MulAdd, Core.Render.Color(100 * A, 100, 200, 235))
            local cx, cy = (m.x + m.parent.x) / 2, (m.y + m.parent.y) / 2
            local rot = atan2(m.y - m.parent.y, m.x - m.parent.x)
            local dist = hypot(m.x - m.parent.x, m.y - m.parent.y)
            Core.Render.Draw.Line(cx, cy, rot, dist - m.r * 2, 6)
        end
    end
end--]]

