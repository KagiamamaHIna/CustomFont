dofile_once("mods/CustomFont/files/lib/fn.lua")
dofile_once("mods/CustomFont/files/lib/unsafe.lua")

local SrcCsv = ModTextFileGetContent("data/translations/common.csv")--设置新语言文件
local AddCsv = ModTextFileGetContent("mods/CustomFont/files/lang/lang.csv")
ModTextFileSetContent("data/translations/common.csv", SrcCsv .. AddCsv)

local CachePath = "mods/CustomFont/cache"--缓存
if not Cpp.PathExists(CachePath) then
    Cpp.CreateDir(CachePath)
end

local UserFontPath = "mods/CustomFont/fontfiles"--用户自定义的字体
if not Cpp.PathExists(UserFontPath) then
    Cpp.CreateDir(UserFontPath)
end

local CharsetFontPath = "mods/CustomFont/charset"--预设字符集
if not Cpp.PathExists(CharsetFontPath) then
    Cpp.CreateDir(CharsetFontPath)
end

if Cpp.PathExists("mods/CustomFont/cache/win_fonts.lua") then
    Cpp.Remove("mods/CustomFont/cache/win_fonts.lua")
end

if Cpp.PathExists("mods/CustomFont/cache/user_fonts.lua") then
    Cpp.Remove("mods/CustomFont/cache/user_fonts.lua")
end

ExecuteFontGen(PathFontDataToFile(WinFontPath, "mods/CustomFont/cache/win_fonts.lua"))--读取系统安装字体
ExecuteFontGen(PathFontDataToFile(UserFontPath, "mods/CustomFont/cache/user_fonts.lua"))--读取用户自定义的字体

local initFlag = false
GuiUpdate = nil
function OnWorldPostUpdate()
    if not initFlag then
        initFlag = true
        GuiUpdate = dofile_once("mods/CustomFont/files/gui/update.lua")
    end
	GuiUpdate()
end
