---@class Core.Render.Skybox
local M = {}
Core.Render.Skybox = M

local Mesh = Core.Render.Mesh

local function CreateSkySphereMesh(lat_segments, lon_segments)
    lat_segments = lat_segments or 32
    lon_segments = lon_segments or 64

    local vcount = (lat_segments + 1) * (lon_segments + 1)
    local icount = lat_segments * lon_segments * 6

    ---@class Core.Render.Skybox.Mesh : lstg.Mesh
    local mesh = Mesh.Create(vcount, icount)

    local index = 0

    for lat = 0, lat_segments do
        local v = lat / lat_segments
        local theta = v * 180
        for lon = 0, lon_segments do
            local u = lon / lon_segments
            local phi = u * 360
            local x = sin(theta) * cos(phi)
            local y = cos(theta)
            local z = sin(theta) * sin(phi)
            mesh:setVertex(index, x, y, z, u, v, lstg.Color(255, 255, 255, 255))
            index = index + 1
        end
    end

    local id = 0
    local function vid(lat, lon)
        return lat * (lon_segments + 1) + lon
    end

    for lat = 0, lat_segments - 1 do
        for lon = 0, lon_segments - 1 do
            local v0 = vid(lat, lon)
            local v1 = vid(lat + 1, lon)
            local v2 = vid(lat + 1, lon + 1)
            local v3 = vid(lat, lon + 1)
            mesh:setIndex(id, v0)
            id = id + 1
            mesh:setIndex(id, v1)
            id = id + 1
            mesh:setIndex(id, v2)
            id = id + 1
            mesh:setIndex(id, v0)
            id = id + 1
            mesh:setIndex(id, v2)
            id = id + 1
            mesh:setIndex(id, v3)
            id = id + 1
        end
    end

    mesh:commit()
    mesh:setReadOnly()

    return mesh
end

--- 创建一个 SkySphere 渲染对象
---Creates a SkySphere rendering object
--- @param texture_path string 贴图路径
--- @param lat_segments number 纬度分段数
--- @param lon_segments number 经度分段数
function M.NewSphere(texture_path, lat_segments, lon_segments)
    local mesh = CreateSkySphereMesh(lat_segments, lon_segments)
    ---@class Core.Render.Skybox.MeshRenderer : lstg.MeshRenderer
    local meshRenderer = Mesh.CreateRenderer(mesh, Mesh.CreateTexture(texture_path))
    return meshRenderer
end

