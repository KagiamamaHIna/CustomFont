dofile_once("mods/CustomFont/files/lib/fn.lua")
dofile_once("mods/CustomFont/files/lib/unsafe.lua")

local SrcCsv = ModTextFileGetContent("data/translations/common.csv")--设置新语言文件
local AddCsv = ModTextFileGetContent("mods/CustomFont/files/lang/lang.csv")
ModTextFileSetContent("data/translations/common.csv", SrcCsv .. AddCsv)

local CachePath = "mods/CustomFont/cache"--缓存
if not Cpp.PathExists(CachePath) then
    Cpp.CreateDir(CachePath)
end

local PreviewCachePath = "mods/CustomFont/cache/preview" --预览缓存
if not Cpp.PathExists(PreviewCachePath) then
    Cpp.CreateDir(PreviewCachePath)
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
if not ModSettingGet(ModID .. ".disable_font") and not ModSettingGet(ModID .. "DisableFontAndClear") and Cpp.PathExists(GenFontPath .. "/current.bin") and Cpp.PathExists(GenFontPath .. "/current.png") then
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
end
if ModSettingGet(ModID .. "DisableFontAndClear") then--禁用时删除
    Cpp.Remove(GenFontPath .. "/current.bin")
    Cpp.Remove(GenFontPath .. "/current.png")
    ModSettingSet(ModID .. "DisableFontAndClear", false)
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

--[[  无视这个:), 他只是在其他地方用的生成脚本
local CJKLocal = {
    "zh-cn",
    "jp",
    "ko",
}

local StartNormalSize = 30
local StartHugeSize = 41
local Count = 10
local Step = 4

local VituralSize = 48

local NormalFont = "mods/better_cjk_pixel_font/data/fonts/generated/fusion-pixel-12px_%s_font_%d.%s"
local CJKHugeFontPath = "mods/better_cjk_pixel_font/data/fonts/generated/fusion-pixel-12px_huge_%s_font_%d.%s"
local BinSpritePath = "data/fonts/generated/fusion-pixel-12px_%s_font_%d.png"
local BinHugeSpritePath = "data/fonts/generated/fusion-pixel-12px_huge_%s_font_%d.png"
local charsetPath = "mods/CustomFont/charset/%s.txt"

for _,v in ipairs(CJKLocal)do
    local builder = FontCommandSetBuilder()
    local builderHuge = FontCommandSetBuilder()
    builder.PreCharsetFile[#builder.PreCharsetFile + 1] = string.format(charsetPath, v)
    builderHuge.PreCharsetFile = builder.PreCharsetFile
    builder:AddFont("mods/CustomFont/fontfiles/fusion-pixel-12px-proportional-zh_hans.ttf")
    builderHuge.Fonts = builder.Fonts
    builder.PixelHeight = StartNormalSize
    builderHuge.PixelHeight = StartHugeSize
    local ThisTempVitural = VituralSize
    for i=1,Count do
        builder.BinFilePath = string.format(NormalFont, v, ThisTempVitural, "bin")
        builder.SpriteFilePath = string.format(NormalFont, v, ThisTempVitural, "png")
        builder.BinSpriteFilePath = string.format(BinSpritePath, v, ThisTempVitural, "png")
        builderHuge.BinFilePath = string.format(CJKHugeFontPath, v, ThisTempVitural, "bin")
        builderHuge.SpriteFilePath = string.format(CJKHugeFontPath, v, ThisTempVitural, "png")
        builderHuge.BinSpriteFilePath = string.format(BinHugeSpritePath, v, ThisTempVitural, "png")
        ExecuteFontGen(builder:Build())
        ExecuteFontGen(builderHuge:Build())

        if i == 1 or i % 2 == 0 then
            builder.PixelHeight = builder.PixelHeight - Step
            builderHuge.PixelHeight = builderHuge.PixelHeight - Step

            builder.HalfwidthSpaceWidth = builder.HalfwidthSpaceWidth - (Step / 2)
            builderHuge.HalfwidthSpaceWidth = builderHuge.HalfwidthSpaceWidth - (Step / 2)
        end

        ThisTempVitural = ThisTempVitural - 4
    end
end]]

local initFlag = false
GuiUpdate = nil
function OnWorldPostUpdate()
    if not initFlag then
        initFlag = true
        GuiUpdate = dofile_once("mods/CustomFont/files/gui/update.lua")
    end
	GuiUpdate()
end
