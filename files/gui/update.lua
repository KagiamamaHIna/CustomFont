---@type Gui
local UI = dofile("mods/CustomFont/files/lib/gui.lua")
dofile_once("mods/CustomFont/files/lib/fn.lua")
dofile_once("mods/CustomFont/files/misc/SearchForList.lua")
dofile_once("mods/CustomFont/files/gui/FontSlider.lua")

local drawGUI = false
UI.MainTickFn["Main"] = function()
    BuildCheck()
    if InputIsKeyJustDown(Key_HOME) then
        drawGUI = not drawGUI
    end
    if drawGUI then
        DrawFontSlider(UI)
    end
end

return UI.DispatchMessage
