---@class Core.I18n
local M = {}
Core.I18n = M

M.currentLanguage = nil

M.languageMap = {}
M.languageSet = {}

M.languageDirectory = {}

M.jargonSign = "{{([^{}]+)}}"

---@type string[]
M.text = {}
---@type string[]
M.jargon = {}
---@type fun[]
M.command = {}

M._cache = {}

local function SkimDirectory(dir)
    for _, files in ipairs(Core.VFS.EnumFiles(dir, nil, true)) do
        if files[2] then
            SkimDirectory(files[1])
        elseif files[1]:lower():find("%.lua$") then
            local data = Core.VFS.DoFile(files[1])
            if data.isJargon then
                data.isJargon = nil
                M.RegisterJargon(data)
                M.RegisterKeys(data)--如果是术语，会同时存在key和jargon
            else
                M.RegisterKeys(data)
            end
        elseif files[1]:lower():find("%.json$") then
            local data = Core.Lib.Json.Decode(Core.VFS.LoadTextFile(files[1]))
            if data.isJargon then
                data.isJargon = nil
                M.RegisterJargon(data)
                M.RegisterKeys(data)--如果是术语，会同时存在key和jargon
            else
                M.RegisterKeys(data)
            end
        end
    end
end

function M.GetJargon(key, depth)
    depth = depth or 0
    if depth > 10 then
        return key
    end

    local val = M.jargon[key]
    if not val then
        return key
    end

    local resolved = val:gsub(M.jargonSign, function(k)
        return M.GetJargon(k, depth + 1)
    end)
    -- 如果解析后变了，就缓存结果
    M.jargon[key] = resolved

    return resolved
end

function M.Reload()
    local lang = M.currentLanguage
    if not lang then
        return
    end
    M.text = {}
    M.jargon = {}
    M._cache = {}

    for _, dir in pairs(M.languageDirectory) do
        SkimDirectory(dir .. lang .. "/")
    end
    ---扁平化
    for k in pairs(M.jargon) do
        M.jargon[k] = M.GetJargon(k)
    end
end

function M.SetLanguage(lang)
    if not M.languageSet[lang] then
        error(("Language %s is not registered!"):format(lang))
    end
    M.currentLanguage = lang
    M.Reload()
end

---注册能够自动扫描多语言文件的目录
---Register a directory that can automatically scan for language files
function M.RegisterDirectory(name, dir)
    M.languageDirectory[name] = dir
end

function M.UnregisterDirectory(name)
    M.languageDirectory[name] = nil
end

function M.RegisterLanguage(lang)
    if M.languageSet[lang] then
        return
    end
    table.insert(M.languageMap, lang)
    M.languageSet[lang] = true
end

function M.RegisterKey(key, value)
    M.text[key] = value
end

function M.RegisterKeys(tbl)
    Core.Lib.Table.Merge(M.text, tbl)
end

---@overload fun(tbl: table)
---@param key string
---@param value string
function M.RegisterJargon(key, value)
    if type(key) == "table" then
        for k, v in pairs(key) do
            M.jargon[k] = v
        end
    else
        M.jargon[key] = value
    end
end

---@param pattern string
---@param repl function
---注册命令
---命令是不会被重置的
---@see string.gsub
function M.RegisterCommand(pattern, repl)
    M.command[pattern] = repl
end

function M.GetAvailableLanguages()
    return Core.Lib.Table.Copy(M.languageMap)
end

---@param key string
---@return string
---获取纯净的多语言文本，不带术语与命令
function M.GetRaw(key)
    return M.text[key] or key
end

function M.Exists(key)
    return M.text[key] ~= nil
end

---获取带有术语的多语言文本
---@return string
function M.Get(key)
    if key == "" then
        return key
    end
   -- if M._cache[key] then
   --     return M._cache[key]
   -- end
    local text = M.text[key] or key
    text = text:gsub(M.jargonSign, function(kw)
        return M.jargon[kw] or kw
    end)
    for kw, func in pairs(M.command) do
        text = text:gsub(kw, func)
    end
    --M._cache[key] = text
    return text
end

---你可以覆盖它
M.RegisterKey("default-font", "heiti")

