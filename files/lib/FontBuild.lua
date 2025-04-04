FT_Encoding = {
    FT_ENCODING_NONE = "FT_ENCODING_NONE",
    FT_ENCODING_MS_SYMBOL = "FT_ENCODING_MS_SYMBOL",
    FT_ENCODING_UNICODE = "FT_ENCODING_UNICODE",
    FT_ENCODING_SJIS = "FT_ENCODING_SJIS",
    FT_ENCODING_PRC = "FT_ENCODING_PRC",
    FT_ENCODING_BIG5 = "FT_ENCODING_BIG5",
    FT_ENCODING_WANSUNG = "FT_ENCODING_WANSUNG",
    FT_ENCODING_JOHAB = "FT_ENCODING_JOHAB",

    -- for backward compatibility
    FT_ENCODING_GB2312 = "FT_ENCODING_PRC",
    FT_ENCODING_MS_SJIS = "FT_ENCODING_SJIS",
    FT_ENCODING_MS_GB2312 = "FT_ENCODING_PRC",
    FT_ENCODING_MS_BIG5 = "FT_ENCODING_BIG5",
    FT_ENCODING_MS_WANSUNG = "FT_ENCODING_WANSUNG",
    FT_ENCODING_MS_JOHAB = "FT_ENCODING_JOHAB",

    FT_ENCODING_ADOBE_STANDARD = "FT_ENCODING_ADOBE_STANDARD",
    FT_ENCODING_ADOBE_EXPERT = "FT_ENCODING_ADOBE_EXPERT",
    FT_ENCODING_ADOBE_CUSTOM = "FT_ENCODING_ADOBE_CUSTOM",
    FT_ENCODING_ADOBE_LATIN_1 = "FT_ENCODING_ADOBE_LATIN_1",
    FT_ENCODING_OLD_LATIN_2 = "FT_ENCODING_OLD_LATIN_2",
    FT_ENCODING_APPLE_ROMAN = "FT_ENCODING_APPLE_ROMAN"
}

---将任意参数序列化为前后带"的安全字符串
---@param any any
---@return string
local function SerializeAny(any)
    local result = { '"', string.format("%s", tostring(any)), '"' }
    return table.concat(result)
end

---@class FontMetaData
---@field path string
---@field face_index integer

---@class FontCommandSetBuildClass

---字体生成程序指令集建造者
---@return FontCommandSetBuildClass
function FontCommandSetBuilder()
    ---@class FontCommandSetBuildClass
    local result = {
        BinFilePath = "",                           --二进制文件输出路径
        SpriteFilePath = "",                        --精灵图输出路径
        BinSpriteFilePath = "",                     --二进制文件中精灵图的路径，只能用 '/' 分隔，因为noita是这样写的

        SpriteWidthMax = 4096,                      --精灵图最大宽度限制
        SpriteHeightMax = 20000,                    --精灵图最大高度限制
        encoding = FT_Encoding.FT_ENCODING_UNICODE, --字符编码
        PixelWidth = 0,                             --字符渲染宽，0则自动确认（另一方得定义正确的数字）
        PixelHeight = 32,                           --字符渲染高，0则自动确认（另一方得定义正确的数字）
        FontWidth = 48,                             --字符宽度
        FontSpacing = 2,                            --字符间距(不影响空格，不影响精灵图)

        HalfwidthSpaceWidth = 16,                   --半角字符空格宽，全角空格通过此推断出来宽度，高度选择PixelHeight的

        log = nil,                                  --日志文件路径
        logAlways = false,                          --总是生成日志

        PreCharsetFile = {},                        --提前预设的字符集文件，按行分割，十六进制

        Char32SetAny = false,                       --开启后将尝试渲染字体中的所有字符

        ---@type table<table<integer,integer>>
        Char32Set = {},                             --字符集合，用于存储要渲染的编码
        ---@type table<FontMetaData>
        Fonts = {},                                 --字体数组，用于设置字体及其后备字体
    }

    ---增加指定范围的字符集
    ---@param StartChar integer
    ---@param EndChar integer
    ---@return FontCommandSetBuildClass self
    function result:AddCharsetRange(StartChar, EndChar)
        self.Char32Set[#self.Char32Set + 1] = { StartChar, EndChar }
        return self
    end

    ---增加字体
    ---@param fontPath string
    ---@param face_index integer? face_index = 0
    ---@return FontCommandSetBuildClass self
    function result:AddFont(fontPath, face_index)
        if face_index == nil then
            face_index = 0
        end
        self.Fonts[#self.Fonts + 1] = { path = fontPath, face_index = face_index }
        return self
    end

    ---构建
    ---@return string
    function result:Build()
        local resultTable = {
            "NFontBuilder", "true",

            "BinFilePath", SerializeAny(self.BinFilePath),
            "SpriteFilePath", SerializeAny(self.SpriteFilePath),
            "BinSpriteFilePath", SerializeAny(self.BinSpriteFilePath),

            "SpriteWidthMax", SerializeAny(self.SpriteWidthMax),
            "SpriteHeightMax", SerializeAny(self.SpriteHeightMax),
            "encoding", SerializeAny(self.encoding),
            "PixelWidth", SerializeAny(self.PixelWidth),
            "PixelHeight", SerializeAny(self.PixelHeight),
            "FontWidth", SerializeAny(self.FontWidth),
            "FontSpacing", SerializeAny(self.FontSpacing),

            "HalfwidthSpaceWidth", SerializeAny(self.HalfwidthSpaceWidth),

            "logAlways", SerializeAny(self.logAlways),
        }
        if self.log then
            resultTable[#resultTable + 1] = "log"
            resultTable[#resultTable + 1] = SerializeAny(self.log)
        end

        local FontStrArray = {}
        for k, v in ipairs(self.Fonts) do
            FontStrArray[#FontStrArray+1] = table.concat({v.path, ',', v.face_index})
        end
        resultTable[#resultTable + 1] = "AddFont"
        resultTable[#resultTable + 1] = SerializeAny(table.concat(FontStrArray, '|'))
        
        if not self.Char32SetAny and #self.Char32Set > 0 then
            local CharsetStrArray = {}
            for k, v in ipairs(self.Char32Set)do
                CharsetStrArray[#CharsetStrArray+1] = table.concat({v[1], ',', v[2]})
            end
            resultTable[#resultTable + 1] = "CharsetRange"
            resultTable[#resultTable + 1] = SerializeAny(table.concat(CharsetStrArray, '|'))
        elseif self.Char32SetAny then
            resultTable[#resultTable + 1] = "Char32SetAny"
            resultTable[#resultTable + 1] = "true"
        end


        if #self.PreCharsetFile > 0 then
            resultTable[#resultTable + 1] = "PreCharsetFile"
            resultTable[#resultTable + 1] = SerializeAny(table.concat(self.PreCharsetFile, '|'))
        end

        return table.concat(resultTable, ' ')
    end

    return result
end

---生成 从指定路径加载字体数据到一个指定文件 的指令
---@param fromPath string
---@param toPath string
---@return string
function PathFontDataToFile(fromPath, toPath)
    return table.concat({
        "GetPathsFontData", "true",
        "FromPath", SerializeAny(fromPath),
        "OutputPath", SerializeAny(toPath)
    }, ' ')
end

local ffi = require("ffi")

ffi.cdef[[
typedef int BOOL;
typedef unsigned long DWORD;
typedef void* HANDLE;
typedef const char* LPCSTR;
typedef char* LPSTR;
typedef unsigned short WORD;
typedef unsigned char BYTE, *LPBYTE;

typedef struct {
    DWORD cb;
    LPCSTR lpReserved;
    LPCSTR lpDesktop;
    LPCSTR lpTitle;
    DWORD dwX;
    DWORD dwY;
    DWORD dwXSize;
    DWORD dwYSize;
    DWORD dwXCountChars;
    DWORD dwYCountChars;
    DWORD dwFillAttribute;
    DWORD dwFlags;
    WORD wShowWindow;
    WORD cbReserved2;
    LPBYTE lpReserved2;
    HANDLE hStdInput;
    HANDLE hStdOutput;
    HANDLE hStdError;
} STARTUPINFOA;

typedef struct {
    HANDLE hProcess;
    HANDLE hThread;
    DWORD dwProcessId;
    DWORD dwThreadId;
} PROCESS_INFORMATION;

BOOL CreateProcessA(
    LPCSTR lpApplicationName,
    LPSTR lpCommandLine,
    void* lpProcessAttributes,
    void* lpThreadAttributes,
    BOOL bInheritHandles,
    DWORD dwCreationFlags,
    void* lpEnvironment,
    LPCSTR lpCurrentDirectory,
    STARTUPINFOA* lpStartupInfo,
    PROCESS_INFORMATION* lpProcessInformation
);

DWORD GetLastError();
]]

---FFI静默新建进程执行程序
---@param program string
---@param args string
---@return boolean
function StartProcessSilent(program, args)
    local startupInfo = ffi.new("STARTUPINFOA")
    local processInfo = ffi.new("PROCESS_INFORMATION")
    
    startupInfo.cb = ffi.sizeof(startupInfo)
    startupInfo.wShowWindow = 0  -- 隐藏窗口
    startupInfo.dwFlags = 0x00000001 -- STARTF_USESHOWWINDOW

    local cmd = program .. " " .. args
    local result = ffi.C.CreateProcessA(
        nil, ffi.cast("LPSTR", cmd), nil, nil, false, 0x08000000, -- CREATE_NO_WINDOW
        nil, nil, startupInfo, processInfo
    )

    if result == 0 then
        print("Failed to start process, error:", ffi.C.GetLastError())
        return false
    end

    return true
end
