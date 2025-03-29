dofile_once("mods/CustomFont/files/lib/fn.lua")
dofile_once("mods/CustomFont/files/lib/unsafe.lua")

local SrcCsv = ModTextFileGetContent("data/translations/common.csv")--设置新语言文件
local AddCsv = ModTextFileGetContent("mods/CustomFont/files/lang/lang.csv")
ModTextFileSetContent("data/translations/common.csv", SrcCsv .. AddCsv)

local CachePath = "mods/CustomFont/cache"--缓存
if not Cpp.PathExists(CachePath) then
    Cpp.CreateDir(CachePath)
end

local GenFontPath = "mods/CustomFont/gen_font_file"--生成的字体文件
if not Cpp.PathExists(GenFontPath) then
    Cpp.CreateDir(GenFontPath)
end

if Cpp.PathExists(GenFontPath.."/new.bin") and Cpp.PathExists(GenFontPath.."/new.png") then
    --不管是谁存在谁不存在，都删一遍就行
    Cpp.Remove(GenFontPath .. "/current.bin")
    Cpp.Remove(GenFontPath .. "/current.png")
    Cpp.Rename(GenFontPath .. "/new.png", GenFontPath .. "/current.png")
    Cpp.Rename(GenFontPath .. "/new.bin", GenFontPath .. "/current.bin")
else
    --不管是谁存在谁不存在，都删一遍就行
    Cpp.Remove(GenFontPath .. "/new.bin")
    Cpp.Remove(GenFontPath .. "/new.png")
end

CustomFontState = false
if not ModSettingGet(ModID .. "DisableFont") and Cpp.PathExists(GenFontPath .. "/current.bin") and Cpp.PathExists(GenFontPath .. "/current.png") then
    local langList = { "en", "ru", "pt-br", "es-es", "de", "fr-fr", "it", "pl", "zh-cn", "jp", "ko" }
    for _,v in ipairs(langList)do
        local fontXmlPath = string.format("data/translations/%s.xml", v)
        local nxml = dofile_once("mods/CustomFont/files/lib/nxml.lua")
        local fontXml = nxml.parse(ModTextFileGetContent(fontXmlPath))
        local fontBinPath = GenFontPath .. "/current.bin"
    
        fontXml.attr.font_default = fontBinPath
        fontXml.attr.font_inventory_title = fontBinPath
        fontXml.attr.font_important_message_title = fontBinPath
        fontXml.attr.font_world_space_message = fontBinPath
        fontXml.attr.fonts_utf8 = "1"
        fontXml.attr.fonts_pixel_font = "0"
        ModTextFileSetContent(fontXmlPath, tostring(fontXml))
        CustomFontState = true
    end
elseif ModSettingGet(ModID .. "DisableFont") then--禁用时删除
    Cpp.Remove(GenFontPath .. "/current.bin")
    Cpp.Remove(GenFontPath .. "/current.png")
    ModSettingSet(ModID .. "DisableFont", false)
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
