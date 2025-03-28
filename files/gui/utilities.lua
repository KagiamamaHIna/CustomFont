dofile_once("mods/CustomFont/files/lib/unsafe.lua")
dofile_once("mods/CustomFont/files/lib/fn.lua")

function ClickSound()
	GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", GameGetCameraPos())
end

function ItemSound()
	GamePlaySound("data/audio/Desktop/ui.bank", "ui/item_switch_places", GameGetCameraPos())
end


---带向上取整和方向键减少增加功能的滑条
---@param UI Gui
---@param id string
---@param x number
---@param y number
---@param text string
---@param value_min number
---@param value_max number
---@param value_default number
---@param width number
---@param value_formatting string?
---@return number
function EasyCeilSlider(UI, id, x, y, text, value_min, value_max, value_default, width, value_formatting)
	value_formatting = Default(value_formatting, "")
	local value = UI.Slider(id, x, y, text, value_min, value_max, value_default, 1, value_formatting, width)
	local _, _, hover = UI.WidgetInfo()
	local result = math.ceil(value)
	UI.SetSliderValue(id, result)
	local SliderFrKey = id .. "SliderFr"
	if hover then
		local function MoveSlider()
			local left = InputIsKeyDown(Key_KP_MINUS) or InputIsKeyDown(Key_LEFT) or InputIsKeyDown(Key_MINUS)
			local right = InputIsKeyDown(Key_KP_PLUS) or InputIsKeyDown(Key_RIGHT) or InputIsKeyDown(Key_EQUALS)
			local num = 1
			if left then
				UI.SetSliderValue(id, value - num)
			elseif right then
				UI.SetSliderValue(id, value + num)
			end
		end
		local hasPush = InputIsKeyDown(Key_KP_MINUS) or InputIsKeyDown(Key_LEFT) or InputIsKeyDown(Key_MINUS)
			or InputIsKeyDown(Key_KP_PLUS) or InputIsKeyDown(Key_RIGHT) or InputIsKeyDown(Key_EQUALS)
		if hasPush then
			if UI.UserData[SliderFrKey] == nil then --如果在悬浮，就分配一个帧检测时间
				UI.UserData[SliderFrKey] = 30
			else
				if UI.UserData[SliderFrKey] == 30 then
					MoveSlider()
				end
				if UI.UserData[SliderFrKey] ~= 0 then
					UI.UserData[SliderFrKey] = UI.UserData[SliderFrKey] - 1
				else --如果到了0
					MoveSlider()
				end
			end
		else
			UI.UserData[SliderFrKey] = 30
		end
	else
		UI.UserData[SliderFrKey] = nil
	end
	return UI.GetSliderValue(id)
end

---可以提前设置保存值的带向上取整的滑条
---@param UI Gui
---@param id string
---@param x number
---@param y number
---@param text string
---@param value_min number
---@param value_max number
---@param value_default number
---@param width number
---@param savedValue number?
---@param value_formatting string?
---@param isDecimals boolean? false
---@param tooltip_fn function?
---@return number
function EasySlider(UI, id, x, y, text, value_min, value_max, value_default, width, savedValue, value_formatting, isDecimals, tooltip_fn)
    value_formatting = Default(value_formatting, "")
	UI.BeginHorizontal(0, 0, true)
	local flag = false
	if UI.GetSliderValue(id) == nil then
		flag = true
	end
    EasyCeilSlider(UI, id, x, y, text, value_min, value_max, value_default, width, value_formatting)
	if tooltip_fn then
		tooltip_fn()
	end
    if flag and savedValue then
        UI.SetSliderValue(id, savedValue)
    end
	local number
	local numberStr
	if isDecimals then
        number = UI.GetSliderValue(id) or 0
		numberStr = tostring(number)
    else
		number = math.ceil(UI.GetSliderValue(id) or 0)
		if number and number < 0 then
            numberStr = tostring(number - 1)
        elseif number then
			numberStr = tostring(number)
		end
	end
	if value_formatting ~= "" then
		numberStr = value_formatting
	end
	GuiAnimateBegin(UI.gui)--帮助滑条能完整的显示文本
	GuiAnimateAlphaFadeIn(UI.gui, UI.NewID(id.."ANI"), 0, 0, false)
    UI.Text(0, 0, numberStr)
    GuiAnimateEnd(UI.gui)
    UI.LayoutEnd()
	return UI.GetSliderValue(id)
end

---相同(左边)文本宽度的滑条
---@param UI Gui
---@param id string
---@param Align number
---@param x number
---@param y number
---@param text string
---@param value_min number
---@param value_max number
---@param value_default number
---@param width number
---@param tooltip string?
---@param savedValue number?
---@return number
function SameWidthSlider(UI, id, Align, x, y, text, value_min, value_max, value_default, width, tooltip, savedValue,
                         isDecimals, format)
    format = format or ""
    UI.BeginHorizontal(0, 0, true)
    UI.NextZDeep(0)
    text = GameTextGet(text)
    local left = UI.TextBtn(id .. "TextBtn", 0, 0, text)
    if left then
        UI.SetSliderValue(id, value_min)
    end
    local _, _, hover, tx, ty, textWitdh = UI.WidgetInfo()
    local number
    local numberStr
    if isDecimals then
        number = UI.GetSliderValue(id) or 0
        numberStr = tostring(number)
    else
        number = math.ceil(UI.GetSliderValue(id) or 0)
        if number and number < 0 then
            numberStr = tostring(number - 1)
        elseif number then
            numberStr = tostring(number)
        end
    end
    if format ~= "" then
        numberStr = format
    end
    if hover then
        UI.NextOption(GUI_OPTION.Layout_NoLayouting)
        UI.NextZDeep(0)
        UI.Text(tx + textWitdh + width + 6 + Align - textWitdh, ty + 1, numberStr)
        local TextInfo = UI.WidgetInfoTable()
        local offset_x = 8
        if TextInfo.x > UI.ScreenWidth * 0.5 then --大于半屏后的偏移
            offset_x = offset_x + textWitdh + width + 6 + Align - textWitdh
        end
        if tooltip then
            UI.BetterTooltipsNoCenter(function() --强制绘制悬浮窗
                UI.Text(0, 0, tooltip)
            end, -3000, offset_x, nil, nil, nil, true, nil, nil, true)
        end
    end
    UI.NextZDeep(0)
    local result
    if isDecimals then
        local flag = false
        if UI.GetSliderValue(id) == nil then
            flag = true
        end
        result = UI.Slider(id, x + Align - textWitdh, y + 1, "", value_min, value_max, value_default, 0.01, format, width)
        if flag and savedValue then
            UI.SetSliderValue(id, savedValue)
        end
    else
        result = EasySlider(UI, id, x + Align - textWitdh, y + 1, "", value_min, value_max, value_default, width,
            savedValue, format, isDecimals
            , function()
            if tooltip then
                UI.GuiTooltip(tooltip)
            end
        end)
    end


    UI.LayoutEnd()
    return result
end

---输入阻止框
---@param UI Gui
---@param id string
---@param x number
---@param y number
---@param w number
---@param h number
---@param mw number
---@param mh number
function InputBlock(UI, id, x, y, w, h, mw, mh)
	GuiAnimateBegin(UI.gui)
    GuiAnimateAlphaFadeIn(UI.gui, UI.NewID(id), 0, 0, false)
	GuiLayoutBeginLayer(UI.gui)
	UI.NextZDeep(1)
	GuiOptionsAddForNextWidget(UI.gui, GUI_OPTION.AlwaysClickable)
	GuiBeginScrollContainer(UI.gui, UI.NewID(id.."隐形"), x, y, w, h, true, mw, mh)
	
	GuiEndScrollContainer(UI.gui)

	GuiLayoutEndLayer(UI.gui)
	GuiAnimateEnd(UI.gui)
end

---更简易的版本
---@param UI Gui
---@param id string
---@param info GuiInfo
function InputBlockEasy(UI, id, info)
	InputBlock(UI, id, info.x - 2, info.y - 2, info.width, info.height, 2, 2)
end
