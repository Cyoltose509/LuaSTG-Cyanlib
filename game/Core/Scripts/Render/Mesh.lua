---@class Core.Render.Mesh
local M = {}
Core.Render.Mesh = M

local Mesh = require("lstg.Mesh")
local MeshRenderer = require("lstg.MeshRenderer")
local Texture2D = require("lstg.Texture2D")

---@class lstg.PrimitiveTopology
M.PrimitiveTopology = {
    TriangleList = 4,
    TriangleStrip = 5,
}

local options = {
    vertex_count = 0,
    index_count = 0,
    vertex_index_compression = false,
    vertex_color_compression = false,
    primitive_topology = M.PrimitiveTopology.TriangleList,
}
---创建Mesh对象
---@param vertexCount number 顶点数量
---@param indexCount number 索引数量
---@param vertexIndexCompression boolean 是否压缩顶点索引
---@param vertexColorCompression boolean 是否压缩顶点颜色
---@param primitiveTopology lstg.PrimitiveTopology 图元类型
---@return lstg.Mesh
function M.Create(vertexCount, indexCount, vertexIndexCompression, vertexColorCompression, primitiveTopology)
    options.vertex_count = vertexCount
    options.index_count = indexCount
    options.vertex_index_compression = vertexIndexCompression
    options.vertex_color_compression = vertexColorCompression
    options.primitive_topology = primitiveTopology
    return Mesh.create(options)
end
M.CreateTexture = Texture2D.createFromFile
M.CreateRenderer = MeshRenderer.create

