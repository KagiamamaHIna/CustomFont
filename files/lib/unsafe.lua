dofile_once("mods/CustomFont/files/lib/define.lua")
dofile_once("mods/CustomFont/files/lib/FontBuild.lua")

SavePath = "%userprofile%/AppData/LocalLow/Nolla_Games_Noita/"
FontBuildExePath = "/mods/CustomFont/files/module/NoitaBinFontGen.exe "
WinFontPath = "%SYSTEMDRIVE%/Windows/Fonts"

if DebugMode then
	--package.cpath = package.cpath..";./mods/CustomFont/files/module/debug/?.dll"
else
	package.cpath = package.cpath..";./mods/CustomFont/files/module/?.dll"
end

Cpp = require("ConjurerExtensions") --加载模块

SavePath = Cpp.GetAbsPath(SavePath)
WinFontPath = Cpp.GetAbsPath(WinFontPath)
FontBuildExePath = Cpp.CurrentPath()..FontBuildExePath

---让NoitaBinFontGen.exe执行指定指令
---@param command string
function ExecuteFontGen(command)
    StartProcessSilent(FontBuildExePath, command)
    print("ExecuteFontGen:", command)
end
