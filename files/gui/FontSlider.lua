dofile_once("mods/CustomFont/files/lib/fn.lua")
dofile_once("mods/CustomFont/files/misc/SearchForList.lua")

local WinFontList = nil
---返回win安装字体列表
---@return table
local function GetWinFontList()
    if not Cpp.PathExists("mods/CustomFont/cache/win_fonts.lua") then
        return {}
    end
    if WinFontList then
        return WinFontList
    end
    WinFontList = {}

    local rawData = dofile_once("mods/CustomFont/cache/win_fonts.lua")
    
    for _, t in ipairs(rawData) do
        for _, font in ipairs(t) do
            local typeName = Cpp.PathGetFileType(font.path)
            if typeName and typeName:lower() ~= "fon" then--排除fon字体，这是位图字体
                WinFontList[#WinFontList+1] = font
            end
        end
    end
    return WinFontList
end

local UserFontList = nil
---返回User字体列表
---@return table
local function GetUserFontList()
    if not Cpp.PathExists("mods/CustomFont/cache/user_fonts.lua") then
        return {}
    end
    if UserFontList then
        return UserFontList
    end
    UserFontList = {}

    local rawData = dofile_once("mods/CustomFont/cache/user_fonts.lua")
    
    for _, t in ipairs(rawData) do
        for _, font in ipairs(t) do
            local typeName = Cpp.PathGetFileType(font.path)
            if typeName and typeName:lower() ~= "fon" then--排除fon字体，这是位图字体
                UserFontList[#UserFontList+1] = font
            end
        end
    end
    return UserFontList
end
