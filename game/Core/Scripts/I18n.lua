---@class Core.I18n
local M = {}
Core.I18n = M

local Lib = Core.Lib

---@private
M.cur_language = nil
---@private
M.language_list = {}
---@private
M.language_set = {}

---@private
M.language_directory = {}

---@private
M.jargon_sign = "{{([^{}]+)}}"

---@private
M.load_default_lang_value = "ZH-CN"

---这是当前语言存储的多语言文本
---@type string[]
---@private
M.cur_texts = {}

---这是当前语言存储的术语表
---@type string[]
---@private
M.cur_jargon = {}

---这是每个语言通用的命令更换
---@type fun[]
---@private
M.commands = {}

---针对特定语言注册多语言文本，将会一直存储
---@type string[][]
---@private
M.registered_texts = {}

---针对特定语言注册术语表，将会一直存储
---@type string[][]
---@private
M.registered_jargon = {}

function M.GetJargon(key, depth)
    depth = depth or 0
    if depth > 10 then
        return key
    end

    local val = M.cur_jargon[key]
    if not val then
        return key
    end

    local resolved = val:gsub(M.jargon_sign, function(k)
        return M.GetJargon(k, depth + 1)
    end)
    -- 如果解析后变了，就缓存结果
    M.cur_jargon[key] = resolved

    return resolved
end


function M.Reload()
    local lang = M.cur_language
    if not lang then
        return
    end
    M.cur_texts = {}
    M.cur_jargon = {}

    local function LoadCSV(name)
        local data = Lib.CSV.Parse(Core.VFS.LoadTextFile(name), true)
        local is_jargon = name:lower():find("jargon")--使用名字来判断jargon
        for _, v in pairs(data) do
            local value = v[M.cur_language]
            if not value or value == "" then
                value = v[M.load_default_lang_value]
            end
            if value then
                if is_jargon then
                    M.cur_jargon[v.key] = value
                end
                M.cur_texts[v.key] = value
            end
        end
    end
    local function SkimDirectory(dir)
        for _, files in ipairs(Core.VFS.EnumFiles(dir, nil, true)) do
            local name, is_folder = files[1], files[2]
            if is_folder then
                SkimDirectory(name)
            elseif name:lower():find("%.lua$") then
                local data = Core.VFS.DoFile(name)
                if data.is_jargon then
                    data.is_jargon = nil
                    Lib.Table.Merge(M.cur_jargon, data)
                end
                Lib.Table.Merge(M.cur_texts, data)--如果是术语，会同时存在key和jargon
            elseif name:lower():find("%.json$") then
                local data = Lib.Json.Decode(Core.VFS.LoadTextFile(name))
                if data.is_jargon then
                    data.is_jargon = nil
                    Lib.Table.Merge(M.cur_jargon, data)
                end
                Lib.Table.Merge(M.cur_texts, data)--如果是术语，会同时存在key和jargon
            elseif name:lower():find("%.csv$") then
                LoadCSV(name)
            end
        end
    end
    local function SkimCSV(dir)
        for _, files in ipairs(Core.VFS.EnumFiles(dir, nil, true)) do
            local name, is_folder = files[1], files[2]
            if is_folder then
                SkimCSV(name)
            elseif name:lower():find("%.csv$") then
                LoadCSV(name)
            end
        end
    end

    for _, dir in pairs(M.language_directory) do
        SkimDirectory(dir .. lang .. "/")
        SkimCSV(dir)
    end

    
    if M.registered_texts[lang] then
        Lib.Table.Merge(M.cur_texts, M.registered_texts[lang])
    end
    if M.registered_jargon[lang] then
        Lib.Table.Merge(M.cur_jargon, M.registered_jargon[lang])
    end
    ---扁平化
    for k in pairs(M.cur_jargon) do
        M.cur_jargon[k] = M.GetJargon(k)
    end
end

function M.SetLanguage(lang)
    if not M.language_set[lang] then
        error(("Language %s is not registered!"):format(lang))
    end
    M.cur_language = lang
    M.Reload()
end

---如果在csv加载中，未找到其他语言，则自动装载的语言
function M.SetDefaultLanguageWhenLoad(lang)
    M.load_default_lang_value = lang
end

---注册能够自动扫描多语言文件的目录
---Register a directory that can automatically scan for language files
function M.RegisterDirectory(name, dir)
    M.language_directory[name] = dir
end

function M.RegisterLanguage(lang)
    if M.language_set[lang] then
        return
    end
    table.insert(M.language_list, lang)
    M.language_set[lang] = true
end

function M.UnregisterDirectory(name)
    M.language_directory[name] = nil
end

---@overload fun(lang:string,tbl: table)
---@param lang string
---@param key string
---@param value string
function M.RegisterKey(lang, key, value)
    M.registered_texts[lang] = M.registered_texts[lang] or {}
    if type(key) == "table" then
        Lib.Table.Merge(M.registered_texts[lang], key)
    else
        M.registered_texts[lang][key] = value
    end
end

---@overload fun(lang:string,tbl: table)
---@param lang string
---@param key string
---@param value string
function M.RegisterJargon(lang, key, value)
    M.registered_jargon[lang] = M.registered_jargon[lang] or {}
    if type(key) == "table" then
        Lib.Table.Merge(M.registered_jargon[lang], key)
    else
        M.registered_jargon[lang][key] = value
    end
end

---@param pattern string
---@param repl function
---注册命令
---命令是不会被重置的
---@see string.gsub
function M.RegisterCommand(pattern, repl)
    M.commands[pattern] = repl
end

function M.GetAvailableLanguages()
    return Lib.Table.Copy(M.language_list)
end

---@param key string
---@return string
---获取纯净的多语言文本，不带术语与命令
function M.GetRaw(key)
    return M.cur_texts[key] or key
end

function M.Exists(key)
    return M.cur_texts[key] ~= nil
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
    local text = M.cur_texts[key] or key
    text = text:gsub(M.jargon_sign, function(kw)
        return M.cur_jargon[kw] or kw
    end)
    for kw, func in pairs(M.commands) do
        text = text:gsub(kw, func)
    end
    --M._cache[key] = text
    return text
end

