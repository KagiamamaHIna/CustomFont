#ifdef NoitaBinFontGenRelease
#pragma comment( linker, "/subsystem:\"windows\" /entry:\"mainCRTStartup\"" )
#endif // NoitaBinFontGenRelease


#include <iostream>
#include <string>
#include <filesystem>
#include <vector>
#include <map>
#include "BSPTree.h"
#include "NFontBin.h"
#include <ft2build.h>
#include <tuple>
#include FT_FREETYPE_H

#include "NFontBuilder.h"
#include "MainArgManager.h"

std::map<std::string, FT_Encoding_> FT_EncodingMap = {
	{"FT_ENCODING_NONE", FT_ENCODING_NONE},
	{"FT_ENCODING_MS_SYMBOL", FT_ENCODING_MS_SYMBOL},
	{"FT_ENCODING_UNICODE", FT_ENCODING_UNICODE},
	{"FT_ENCODING_SJIS", FT_ENCODING_SJIS},
	{"FT_ENCODING_PRC", FT_ENCODING_PRC},
	{"FT_ENCODING_BIG5", FT_ENCODING_BIG5},
	{"FT_ENCODING_WANSUNG", FT_ENCODING_WANSUNG},
	{"FT_ENCODING_JOHAB", FT_ENCODING_JOHAB},

	/* for backward compatibility */
	{"FT_ENCODING_GB2312", FT_ENCODING_PRC},
	{"FT_ENCODING_MS_SJIS", FT_ENCODING_SJIS},
	{"FT_ENCODING_MS_GB2312", FT_ENCODING_PRC},
	{"FT_ENCODING_MS_BIG5", FT_ENCODING_BIG5},
	{"FT_ENCODING_MS_WANSUNG", FT_ENCODING_WANSUNG},
	{"FT_ENCODING_MS_JOHAB", FT_ENCODING_JOHAB},

	{"FT_ENCODING_ADOBE_STANDARD", FT_ENCODING_ADOBE_STANDARD},
	{"FT_ENCODING_ADOBE_EXPERT", FT_ENCODING_ADOBE_EXPERT},
	{"FT_ENCODING_ADOBE_CUSTOM", FT_ENCODING_ADOBE_CUSTOM},
	{"FT_ENCODING_ADOBE_LATIN_1", FT_ENCODING_ADOBE_LATIN_1},
	{"FT_ENCODING_OLD_LATIN_2", FT_ENCODING_OLD_LATIN_2},
	{"FT_ENCODING_APPLE_ROMAN", FT_ENCODING_APPLE_ROMAN}
};

/*
builder.AddCharsetRange(0, 0x17f);
builder.AddCharsetRange(0x1E00, 0x1EFF);
builder.AddCharsetRange(0x2C60, 0x2C7F);
builder.AddCharsetRange(0xA720, 0xA7FF);
builder.AddCharsetRange(0xAB30, 0xAB6F);
builder.AddCharsetRange(0xFF00, 0xFFEF);
builder.AddCharsetRange(0x2000, 0x206F);
builder.AddCharsetRange(0x3000, 0x303F);
builder.AddCharsetRange(0x4E00, 0x9FFF);
*/

int main(int argc, char* argv[]) {
	std::map<std::string, std::string> Args = NFontBin::GetArgKeyToValue(argc, argv);
	bool logAlways = false;
	if (Args.count("logAlways") && Args["logAlways"] == "true") {
		logAlways = true;
	}
	try {
		if (NFontBin::CheckMapValue(Args, "NFontBuilder", "true")) {
			NFontBin::NFontBuilder builder;
			if (Args.count("BinFilePath")) {
				builder.BinFilePath = Args["BinFilePath"];
			}

			if (Args.count("SpriteFilePath")) {
				builder.SpriteFilePath = Args["SpriteFilePath"];
			}

			if (Args.count("BinSpriteFilePath")) {
				builder.BinSpriteFilePath = Args["BinSpriteFilePath"];
			}

			if (Args.count("AddFont")) {//字体数据处理
				for (const auto& v : NFontBin::split(Args["AddFont"], '|')) {
					std::vector<std::string> data = NFontBin::split(v, ',');
					builder.AddFont(data[0], data.size() > 1 ? std::stoi(data[1]) : 0);
				}
			}

			if (Args.count("CharsetRange")) {//字体集数据处理，数据应按 start,end|start,end 顺序排列
				for (const auto& v : NFontBin::split(Args["CharsetRange"], '|')) {
					std::vector<std::string> CharsetData = NFontBin::split(v, ',');
					builder.AddCharsetRange(std::stoi(CharsetData[0]), std::stoi(CharsetData[1]));
				}
			}

			if (Args.count("PreCharsetFile")) {//预设字符集，十六进制按行读取
				for (const auto& v : NFontBin::split(Args["PreCharsetFile"], '|')) {
					std::fstream r_file;
					r_file.open(v, std::ios::in);
					if (!r_file.is_open()) {
						continue;
					}
					std::string bufStr;//读行缓存
					while (std::getline(r_file, bufStr)) {//按十六进制读取
						builder.Char32Set.insert(std::stoi(bufStr, nullptr, 16));
					}
				}
			}

			if (Args.count("encoding") && FT_EncodingMap.count(Args["encoding"])) {
				builder.encoding = FT_EncodingMap[Args["encoding"]];
			}

			if (Args.count("SpriteWidthMax")) {
				builder.SpriteWidthMax = std::stoi(Args["SpriteWidthMax"]);
			}

			if (Args.count("SpriteHeightMax")) {
				builder.SpriteHeightMax = std::stoi(Args["SpriteHeightMax"]);
			}

			if (Args.count("PixelWidth")) {
				builder.PixelWidth = std::stoi(Args["PixelWidth"]);
			}

			if (Args.count("PixelHeight")) {
				builder.PixelHeight = std::stoi(Args["PixelHeight"]);
			}

			if (Args.count("FontWidth")) {
				builder.FontWidth = std::stoi(Args["FontWidth"]);
			}

			if (Args.count("FontSpacing")) {
				builder.FontSpacing = std::stoi(Args["FontSpacing"]);
			}

			if (Args.count("HalfwidthSpaceWidth")) {
				builder.HalfwidthSpaceWidth = std::stoi(Args["HalfwidthSpaceWidth"]);
			}

			auto info = builder.BuildWithInfo();
			if (Args.count("log") && (!info.flag || logAlways)) {
				std::fstream w_file;
				w_file.open(Args["log"], std::ios::out | std::ios::trunc);
				if (!w_file.is_open()) {
					return 0;
				}
				w_file << "build flag: " << (info.flag ? "true" : "false") << '\n';
				w_file << "msg: " << info.msg << '\n';
				for (const auto& c : info.UnrenderedChars) {
					w_file << "UnrenderedChars ID: " << c << '\n';
				}
			}
		}
		else if (NFontBin::CheckMapValue(Args, "GetPathsFontData", "true")) {
			std::string path;
			std::string OutputPath;
			if (Args.count("FromPath")) {
				path = Args["FromPath"];
				char last = path[path.size() - 1];
				if (last != '/' && last != '\\') {
					path += '/';
				}
			}
			else {
				return 0;
			}

			if (Args.count("OutputPath")) {
				OutputPath = Args["OutputPath"];
			}
			else {
				return 0;
			}
			std::vector<std::vector<NFontBin::FontMetaData>> result;
			std::filesystem::directory_iterator dir_iter(path);
			for (const auto& entry : dir_iter) {
				if (entry.is_directory()) {
					continue;
				}
				std::optional<std::vector<NFontBin::FontMetaData>> data = NFontBin::GetFontMetaData(entry.path().string());
				if (data && data.value().size() > 0) {
					result.push_back(data.value());
				}
			}
			std::fstream w_file;
			w_file.open(OutputPath, std::ios::out | std::ios::trunc);
			if (!w_file.is_open()) {
				return 0;
			}
			auto AddSpace = [&](int size) {
				for (int i = 0; i < size; i++) {
					w_file << "    ";
				}
				};

			w_file << "return {\n";//序列化参数到lua表
			for (const auto& v : result) {
				AddSpace(1), w_file << "{\n";
				for (const auto& font : v) {
					AddSpace(2), w_file << "{\n";
					AddSpace(3), w_file << "path = " << "[[" << font.path << "]]" << ',' << '\n';
					AddSpace(3), w_file << "family_name = " << "[[" << font.family_name << "]]" << ',' << '\n';
					AddSpace(3), w_file << "style_name = " << "[[" << font.style_name << "]]" << ',' << '\n';
					AddSpace(3), w_file << "face_index = " << font.face_index << ',' << '\n';
					AddSpace(2), w_file << "},\n";
				}
				AddSpace(1), w_file << "},\n";
			}
			w_file << "}";
			w_file.close();
		}
	}
	catch (const std::exception& e) {
		if (Args.count("log") && logAlways) {
			std::fstream w_file;
			w_file.open(Args["log"], std::ios::out | std::ios::trunc);
			if (!w_file.is_open()) {
				return 0;
			}
			w_file << "C++ Exception: " << typeid(e).name() << '\n';
			w_file << "what: " << e.what() << '\n';
		}
	}
}
