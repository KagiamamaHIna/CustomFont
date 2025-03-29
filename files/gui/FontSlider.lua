dofile_once("mods/CustomFont/files/lib/fn.lua")
dofile_once("mods/CustomFont/files/misc/SearchForList.lua")

local WinFontList = nil
local WinKeyToFont = nil
---返回win安装字体列表
---@return table, table
local function GetWinFontList()
    if not Cpp.PathExists("mods/CustomFont/cache/win_fonts.lua") then
        return {},{}
    end
    if WinFontList and WinKeyToFont then
        return WinFontList, WinKeyToFont
    end
    WinFontList = {}
    WinKeyToFont = {}
    local rawData = dofile_once("mods/CustomFont/cache/win_fonts.lua")
    
    for _, t in ipairs(rawData) do
        for _, font in ipairs(t) do
            local typeName = Cpp.PathGetFileType(font.path)
            if typeName and typeName:lower() ~= "fon" then--排除fon字体，这是位图字体
                font.id = string.format("%s%d", font.path, font.face_index)
                WinFontList[#WinFontList+1] = font
            end
        end
    end
    local userRawData = dofile_once("mods/CustomFont/cache/user_fonts.lua")
    
    for _, t in ipairs(userRawData) do
        for _, font in ipairs(t) do
            local typeName = Cpp.PathGetFileType(font.path)
            if typeName and typeName:lower() ~= "fon" then--排除fon字体，这是位图字体
                font.id = string.format("%s%d", font.path, font.face_index)
                WinFontList[#WinFontList+1] = font
            end
        end
    end

    for k,v in pairs(WinFontList) do
        if WinKeyToFont[k] then
            WinKeyToFont[k] = v.id
        end
    end

    return WinFontList, WinKeyToFont
end

local SliderTextKey = {
    "$custom_font_pixel_width",
    "$custom_font_pixel_height",
    "$custom_font_font_spacing",
    "$custom_font_space_width",
}

local GenFontPath = "mods/CustomFont/gen_font_file"--生成的字体文件

local BuildFlag = true--代表当前是否可以构建
local function BuildFont(pixel_width, pixel_height, font_spacing, space_width, fonts)
    if not BuildFlag then
        return
    end
    pixel_height = math.floor(pixel_height)
    pixel_width = math.floor(pixel_width)
    if pixel_height == 0 and pixel_width == 0 then
        pixel_height = 32
    end
    Cpp.Remove(GenFontPath .. "/new.bin")--先移除
    Cpp.Remove(GenFontPath .. "/new.png")
    local builder = FontCommandSetBuilder()
    builder.BinFilePath = GenFontPath .. "/new.bin"
    builder.SpriteFilePath = GenFontPath .. "/new.png"
    builder.BinSpriteFilePath = GenFontPath .. "/current.png"
    builder.PixelWidth = pixel_width
    builder.PixelHeight = pixel_height
    builder.FontSpacing = math.floor(font_spacing)
    builder.HalfwidthSpaceWidth = math.floor(space_width)
    builder.Char32SetAny = true

    builder.log = "mods/CustomFont/cache/font_build_log.txt"

    for _,v in ipairs(fonts)do
        builder:AddFont(v.path, v.face_index)
    end

    ExecuteFontGen(builder:Build())
    BuildFlag = false
end

function BuildCheck()
    if not BuildFlag then
        local flag1 = Cpp.PathExists(GenFontPath.."/new.bin")
        local flag2 = Cpp.PathExists(GenFontPath .. "/new.png")
        if flag1 and flag2 then
            BuildFlag = true
        end
    end
end

local function CheckFontNewFile()
    return BuildFlag
end

local ChooseItem = {}
local ChooseItemList = {}
---绘制字体选择框
---@param UI Gui
function DrawFontSlider(UI)
    local ScrollWidth = 130--最小宽度
    local rawList = GetWinFontList()
    for _, v in ipairs(rawList) do--初始化
        local FontName = string.format("%s %s", v.family_name, v.style_name)
        local w = UI.TextDimensions(FontName)
        if w > ScrollWidth then
            ScrollWidth = w
        end
    end
    ScrollWidth = ScrollWidth + 20
    local ScrollX = UI.ScreenWidth / 2 - ScrollWidth / 2

    local list, return_keyword = SearchInputBox(UI, "FontListSearch", rawList, ScrollX + ScrollWidth + 15, 2, 102.5, 0, false,
        function(v, keyword)
            local FontName = string.format("%s %s", v.family_name, v.style_name)
            return Cpp.AbsPartialPinyinRatio(FontName:lower(), keyword)
        end
    )
    local SearchBoxInfo = UI.WidgetInfoTable()
    UI.ScrollContainer("FontCustomGUI", SearchBoxInfo.x, SearchBoxInfo.y + SearchBoxInfo.height + 5, 0, 0)
    UI.AddAnywhereItem("FontCustomGUI", function()
        UI.BeginVertical(0, 0, true)
        local SliderAlgin = 0
        for _, v in ipairs(SliderTextKey) do
            local text = GameTextGet(v)
            local newWidth = GuiGetTextDimensions(UI.gui, text)
            if newWidth > SliderAlgin then
                SliderAlgin = newWidth
            end
        end
        local last_pixel_width = UI.GetSliderValue("FontPixelWidth") or 0
        local last_pixel_height = UI.GetSliderValue("FontPixelHeight") or 32
        
        local PixelWidthFormatText = ""
        if last_pixel_width == 0 and last_pixel_height == 0 then
            PixelWidthFormatText = "$custom_font_default"
        elseif last_pixel_width == 0 and last_pixel_height ~= 0 then
            PixelWidthFormatText = "$custom_font_auto"
        else
            PixelWidthFormatText = tostring(last_pixel_width)
        end
        local pixel_width = SameWidthSlider(UI, "FontPixelWidth", SliderAlgin, 0, 0,"$custom_font_pixel_width",0,48,0,60,nil,nil,false, PixelWidthFormatText)
        
        local PixelHeightFormatText = ""
        if last_pixel_width == 0 and last_pixel_height == 0 then
            PixelHeightFormatText = "$custom_font_default"
        elseif last_pixel_width ~= 0 and last_pixel_height == 0 then
            PixelHeightFormatText = "$custom_font_auto"
        else
            PixelHeightFormatText = tostring(last_pixel_height)
        end

        UI.VerticalSpacing(1)
        local pixel_height = SameWidthSlider(UI, "FontPixelHeight", SliderAlgin, 0, 0,"$custom_font_pixel_height",0,48,32,60,nil,nil,false, PixelHeightFormatText)

        UI.VerticalSpacing(1)
        local font_spacing = SameWidthSlider(UI, "FontSpacing", SliderAlgin, 0, 0,"$custom_font_font_spacing",0,16,2,60,nil,nil,false)

        UI.VerticalSpacing(1)
        local space_width = SameWidthSlider(UI, "FontSpaceWidth", SliderAlgin, 0, 0,"$custom_font_space_width",0,48,16,60,nil,nil,false)

        UI.VerticalSpacing(1)
        UI.NextZDeep(0)
        local CreateClick = UI.TextBtn("FontCreate", 0, 0, "$custom_font_font_create")
        UI.GuiTooltip("$custom_font_important_notice")

        if CreateClick and CheckFontNewFile() then
            BuildFont(pixel_width, pixel_height, font_spacing, space_width, ChooseItemList)
        end

        UI.LayoutEnd()
    end)
    UI.NextZDeep(-100)
    UI.DrawScrollContainer("FontCustomGUI", true, true)

    local FontSliderID = "FontSlider"
    if return_keyword ~= "" then
        FontSliderID = FontSliderID .. "Searched"
    end

    UI.ScrollContainer(FontSliderID, ScrollX, 2, ScrollWidth, UI.ScreenHeight - 40)
    UI.AddAnywhereItem(FontSliderID,function ()
        UI.BeginVertical(0, 0, true)
        for i, v in ipairs(list) do
            UI.NextZDeep(0)
            local FontName = string.format("%s %s", v.family_name, v.style_name)
            local w = UI.TextDimensions(FontName)
            if ChooseItem[v.id] then--颜色渲染
                UI.NextColor(237, 169, 73, 255)
            end
            
            local click, right = UI.TextBtn(FontName .. tostring(v.face_index), ScrollWidth / 2 - w / 2, 0, FontName)
            local info = UI.WidgetInfoTable()
            if ChooseItem[v.id] then--选择的字体会提示序号
                UI.NextOption(GUI_OPTION.Layout_NoLayouting)
                UI.NextZDeep(0)
                UI.Text(ScrollX + 2, info.y, string.format("%d.", ChooseItem[v.id]))
            end

            local ctrl = InputIsKeyDown(Key_RCTRL) or InputIsKeyDown(Key_LCTRL)
            if ctrl and click and ChooseItem[v.id] == nil then--多选，检测是否存有是为了防止出bug
                ChooseItemList[#ChooseItemList+1] = v
                ChooseItem[v.id] = #ChooseItemList
            elseif click then--单选
                ChooseItem = { [v.id] = 1 }
                ChooseItemList = {v}
            end

            if right and ChooseItem[v.id] then--右键移除
                for ChooseIndex = #ChooseItemList, 1, -1 do
                    if ChooseItemList[ChooseIndex].id == v.id then
                        table.remove(ChooseItemList, ChooseIndex)
                        ClickSound()
                        break
                    end
                end
                ChooseItem = {}
                for ci,cv in ipairs(ChooseItemList)do
                    ChooseItem[cv.id] = ci
                end
            end
        end
        UI.LayoutEnd()
    end)
    UI.NextZDeep(-100)
    UI.DrawScrollContainer(FontSliderID)
end
