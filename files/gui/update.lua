---@type Gui
local UI = dofile("mods/CustomFont/files/lib/gui.lua")
dofile_once("mods/CustomFont/files/lib/fn.lua")
dofile_once("mods/CustomFont/files/misc/SearchForList.lua")

UI.MainTickFn["Main"] = function()

end

return UI.DispatchMessage
