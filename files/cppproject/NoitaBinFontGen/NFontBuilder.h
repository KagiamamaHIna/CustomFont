#pragma once
#include "BSPTree.h"
#include "NFontBin.h"
#include <ft2build.h>
#include FT_FREETYPE_H
#include <tuple>
#include <map>
#include <set>
#include <algorithm>
#include <optional>

namespace NFontBin {
	class FontMetaData {
	public:
		std::string path;
		std::string family_name;
		std::string style_name;
		FT_Long face_index;
	};
	std::optional<std::vector<FontMetaData>> GetFontMetaData(const std::string& FontPath);
	void PreviewsFont(const std::string& output, const std::string& fontPath, int face_index = 0, const std::string& str = "The quick brown fox jumps over the lazy dog");//str请只写ASCII字符！

	class NFontBuilder {
	public:
		NFontBuilder() {
			InitFTLib();
		}
		NFontBuilder(const NFontBuilder&) = delete;
		NFontBuilder(NFontBuilder&&) = delete;
		NFontBuilder& operator=(NFontBuilder&& src) = delete;

		virtual ~NFontBuilder() {
			ClearFont();
		}

		void ClearFTLib() {
			if (FT_LibInit) {
				FT_Done_FreeType(ftl);
				FT_LibInit = false;
			}
		}

		void InitFTLib() {
			if (!FT_LibInit) {
				FT_Error flag = FT_Init_FreeType(&ftl);//动态初始化
				if (flag) {
					ErrorCache = flag;
					return;
				}
				FT_LibInit = true;
			}
		}

		void ReloadFTLibAndClearFont() {//重加载FT库并清空字体
			ClearFont();
			ClearFTLib();
			InitFTLib();
		}

		FT_Error ErrorCache = 0;

		std::string BinFilePath = "";//二进制文件输出路径
		std::string SpriteFilePath = "";//精灵图输出路径
		std::string BinSpriteFilePath = "";//二进制文件中精灵图的路径，只能用 '/' 分隔，因为noita是这样写的

		int SpriteWidthMax = 4096;//精灵图最大宽度限制
		int SpriteHeightMax = 20000;//精灵图最大高度限制
		FT_Encoding encoding = FT_ENCODING_UNICODE;//字符编码
		int PixelWidth = 0;//字符渲染宽，0则自动确认（另一方得定义正确的数字）
		int PixelHeight = 32;//字符渲染高，0则自动确认（另一方得定义正确的数字）
		int FontWidth = 48;//字符宽度
		int FontSpacing = 2;//字符间距(不影响空格，不影响精灵图)

		int HalfwidthSpaceWidth = 16;//半角字符空格宽，全角空格通过此推断出来宽度，高度选择PixelHeight的

		bool Char32SetAny = false;//开启后将尝试渲染字体中的所有字符
		std::set<char32_t> Char32Set;//字符集合，用于存储要渲染的编码
		std::map<char32_t, char32_t> CharMap;//字符映射 (编码，目标字符) ，假如存在映射，那么按照编码渲染完后分配给特定的字符做精灵图，可以用于比如wingdings字体的渲染

		void AddCharsetRange(char32_t start, char32_t end) {
			for (char32_t i = start; i <= end; i++) {
				Char32Set.insert(i);
			}
		}

		class BuildInfo {
		public:
			std::vector<char32_t> UnrenderedChars;
			bool flag = false;//为真则成功
			std::string msg = "Done";
		};

		bool Build();
		BuildInfo BuildWithInfo();

		FT_Error AddFont(const std::string& fontPath, FT_Long face_index = 0) {
			if (!ErrorCache) {
				size_t index = faces.size();
				faces.push_back(FT_Face());
				return FT_New_Face(ftl, fontPath.c_str(), face_index, &faces[index]);
			}
			return ErrorCache;
		}

		void ClearFont() {
			for (auto& v : faces) {
				FT_Done_Face(v);
			}
			faces = std::vector<FT_Face>();
		}
	private:
		inline static FT_Library ftl = FT_Library();//全局共享
		inline static bool FT_LibInit = false;
		std::vector<FT_Face> faces;//字体数组
	};
}
