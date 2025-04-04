#pragma once
#include <string>
#include <filesystem>
#include <iostream>
#include "fn.h"

#include "lua.hpp"


namespace lua {
	int lua_GetDirectoryPath(lua_State* L);
	int lua_GetDirectoryPathAll(lua_State* L);
	int lua_CurrentPath(lua_State* L);
	int lua_GetAbsPath(lua_State* L);
	int lua_PathGetFileName(lua_State* L);
	int lua_PathGetFileType(lua_State* L);
	int lua_PathExists(lua_State* L);
	int lua_CreateDir(lua_State* L);
	int lua_CreateDirs(lua_State* L);
	int lua_Rename(lua_State* L);
	int lua_Remove(lua_State* L);
	int lua_RemoveAll(lua_State* L);
}
