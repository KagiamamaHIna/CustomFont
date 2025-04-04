dofile("data/scripts/lib/mod_settings.lua")

function mod_setting_bool_custom( mod_id, gui, in_main_menu, im_id, setting )
	local value = ModSettingGetNextValue( mod_setting_get_id(mod_id,setting) )
	local text = setting.ui_name .. " - " .. GameTextGet( value and "$option_on" or "$option_off" )

	if GuiButton( gui, im_id, mod_setting_group_x_offset, 0, text ) then
		ModSettingSetNextValue( mod_setting_get_id(mod_id,setting), not value, false )
	end

	mod_setting_tooltip( mod_id, gui, in_main_menu, setting )
end

function mod_setting_change_callback(mod_id, gui, in_main_menu, setting, old_value, new_value)
    print(tostring(new_value))
end
local csv = dofile_once("mods/CustomFont/files/lib/csv.lua")

local currentLang = csv(ModTextFileGetContent("mods/CustomFont/files/lang/lang.csv"))
local gameLang = csv(ModTextFileGetContent("data/translations/common.csv"))
local CurrentMap = {}
for v,_ in pairs(gameLang.rowHeads) do--构建一个关联表用来查询键值
	if v ~= "" then
		local tempKey = gameLang.get("current_language",v)
		CurrentMap[tempKey] = v
	end
end
local function GetText(key) --获取文本
	if key == "" then
		return key
	end
	local GameKey
    local GameTextLangGet = GameTextGet("$current_language")
	GameKey = CurrentMap[GameTextLangGet]
    if GameKey == nil then
        GameKey = "en"
    end
    local result = currentLang.get(key, GameKey) or ""
	result = string.gsub(result, [[\n]], "\n")
	if result == nil or result == "" then
        result = currentLang.get(key, "en")
	end
	return result
end

---监听访问
---@param t table
---@param callback function
local function TableListener(t, callback)
    local function NewListener()
        local __data = {}
        local deleteList = {}
        for k, v in pairs(t) do
            __data[k] = v
            deleteList[#deleteList + 1] = k
        end
        for _, v in pairs(deleteList) do
            t[v] = nil
        end
        local result = {
            __newindex = function(table, key, value)
                local temp = callback(key, value)
                value = temp or value
                rawset(__data, key, value)
                rawset(table, key, nil)
            end,
            __index = function(table, key)
                local temp = callback(key, rawget(__data, key))
				if temp == nil then
					return rawget(__data, key)
                else
					return temp
				end
            end,
            __call = function()
                return __data
            end
        }
        return result
    end
	setmetatable(t, NewListener())
end

local function Setting(t)
    TableListener(t, function(key, value)
        if key == "ui_name" or key == "ui_description" then
            local result = GetText(value)
            return result
        end
    end)
    return t
end

local function GetTextOrKey(key)
    local result = GetText(key)
    return result or key
end

local function ValueListInit(t)
    TableListener(t, function(key, value)
        return GetTextOrKey(value)
    end)
    return t
end

local function ValueList(t)
	for k,v in pairs(t)do
		t[k] = ValueListInit(v)
	end
	return t
end

local IKnowWhatImDoing_wand_editor_reset_btn_pos = false

local mod_id = "CustomFont"
local ModID = mod_id
mod_settings_version = 1
mod_settings = 
{
    Setting({
        id = "font_preview_render",
        ui_name = "custom_font_font_preview_render",
        value_default = "hover",
        values = ValueList({
            { "no", "custom_font_font_no" },
            { "hover",  "custom_font_font_hover" },
            { "hover_shift",   "custom_font_font_hover_shift" },
        }),
        scope = MOD_SETTING_SCOPE_RUNTIME,
    }),
	Setting({
		id = "disable_font",
		ui_name = "custom_font_disable_font",
		ui_description = "custom_font_disable_font_tips",
        value_default = false,
		scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
	}),
	Setting({
        id = "disable_font_and_clear",
		ui_name = "",
		ui_description = "",
		value_default = false,
		ui_fn = function(mod_id, gui, in_main_menu, im_id, setting)
			GuiIdPushString(gui,"CustomFont_disable_font_and_clear")
            local click = GuiButton(gui, 1, 0, 0, GetText("custom_font_disable_and_clear_font"))
            GuiTooltip(gui,GetText("custom_font_disable_and_clear_font_tips"), "")
			if click then
				ModSettingSet(ModID .. "DisableFontAndClear", true)
			end
			GuiIdPop(gui)
		end
    }),
}

function ModSettingsUpdate( init_scope )
	local old_version = mod_settings_get_version( mod_id )
	mod_settings_update( mod_id, mod_settings, init_scope )
end

function ModSettingsGuiCount()
	return mod_settings_gui_count( mod_id, mod_settings )
end

function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )
end
