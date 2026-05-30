---@class Core.Render.Ball
local M = {}
Core.Render.Ball = M

local Mesh = Core.Render.Mesh

local function CreateBallMesh(color, lat_segments, lon_segments)
    lat_segments = lat_segments or 32
    lon_segments = lon_segments or 64
    color = color or lstg.Color(255, 255, 255, 255)

    local vcount = (lat_segments + 1) * (lon_segments + 1)
    local icount = lat_segments * lon_segments * 6

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
            mesh:setVertex(index, x, y, z, u, v, color)
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

--- @param texture_path string 贴图路径
function M.New(color, texture_path, lat_segments, lon_segments)
    texture_path = texture_path or "Core\\Assets\\Sprites\\white.png"
    local mesh = CreateBallMesh(color, lat_segments, lon_segments)
    local meshRenderer = Mesh.CreateRenderer(mesh, Mesh.CreateTexture(texture_path))
    return meshRenderer
end