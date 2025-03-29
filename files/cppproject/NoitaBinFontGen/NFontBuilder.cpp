#include "NFontBuilder.h"

namespace NFontBin {
	std::optional<std::vector<FontMetaData>> GetFontMetaData(const std::string& FontPath) {
		FT_Library ftl;
		if (FT_Init_FreeType(&ftl)) {
			return std::nullopt;
		}
		FT_Face GetNumFace;
		if (FT_New_Face(ftl, FontPath.c_str(), -1, &GetNumFace)) {
			FT_Done_FreeType(ftl);
			return std::nullopt;
		}
		FT_Long num_face = GetNumFace->num_faces;
		std::vector<FontMetaData> result;
		for (FT_Long i = 0; i < num_face; i++) {
			FT_Face face;
			if (FT_New_Face(ftl, FontPath.c_str(), i, &face)) {
				continue;
			}
			if (FT_Select_Charmap(face, FT_ENCODING_UNICODE)) {//仅筛选支持unicode的
				continue;
			}
			result.push_back({ FontPath , face->family_name, face->style_name, i });
			FT_Done_Face(face);
		}
		FT_Done_Face(GetNumFace);
		FT_Done_FreeType(ftl);
		return result;
	}

	NFontBuilder::BuildInfo NFontBuilder::BuildWithInfo() {
		BuildInfo result;
		if (ErrorCache) {
			result.msg = "FT_Library was not successfully initialized";
			return result;
		}
		if (BinFilePath == "" || SpriteFilePath == "" || BinSpriteFilePath == "") {
			result.msg = "String path missing";
			return result;
		}
		if (!Char32SetAny && Char32Set.size() == 0) {
			result.msg = "The set has no elements";
			return result;
		}
		if (faces.size() == 0) {
			result.msg = "There are no fonts";
			return result;
		}
		image::BSPTree bsp(1, SpriteWidthMax, SpriteHeightMax);
		NFontBin::FontBin NoitaFont(FontWidth, BinSpriteFilePath);

		std::vector<int> baselines;
		for (auto& v : faces) {//字形初始化
			FT_Set_Pixel_Sizes(v, PixelWidth, PixelHeight);
			FT_Select_Charmap(v, encoding);
			baselines.push_back(v->size->metrics.ascender >> 6);
		}
		std::vector<std::tuple<image::stb_image, char32_t, int>> imgs;

		if (Char32SetAny) {
			std::set<char32_t> newSet;//存储已渲染过的字符集合
			FT_UInt glyph_index;
			for (size_t i = 0; i < faces.size(); i++) {
				const FT_Face& face = faces[i];
				FT_UInt glyphIndex = 0;
				char32_t c = FT_Get_First_Char(face, &glyph_index);
				glyphIndex = FT_Get_Char_Index(face, c);
				while (glyph_index != 0) {
					if (newSet.count(c)) {//已经渲染过了则跳过渲染
						c = FT_Get_Next_Char(face, c, &glyph_index);
						continue;
					}
					if (FT_Load_Glyph(face, glyphIndex, FT_LOAD_RENDER)) {//渲染失败了就跳过渲染
						c = FT_Get_Next_Char(face, c, &glyph_index);
						continue;
					}
					FT_GlyphSlot g = face->glyph;
					int yOffset = baselines[i] - g->bitmap_top;
					imgs.push_back(std::tuple(image::stb_image(g->bitmap.buffer, g->bitmap.width, g->bitmap.rows, 1), c, yOffset));
					newSet.insert(c);
					c = FT_Get_Next_Char(face, c, &glyph_index);
					glyphIndex = FT_Get_Char_Index(face, c);
				}
			}
		}
		else {
			for (const auto& c : Char32Set) {
				bool hasGlyph = false;
				for (size_t i = 0; i < faces.size(); i++) {
					const FT_Face& face = faces[i];
					FT_UInt glyphIndex = FT_Get_Char_Index(face, c);
					if (glyphIndex == 0) {
						continue;
					}
					if (FT_Load_Glyph(face, glyphIndex, FT_LOAD_RENDER)) {
						continue;
					}
					FT_GlyphSlot g = face->glyph;
					int yOffset = baselines[i] - g->bitmap_top;
					imgs.push_back(std::tuple(image::stb_image(g->bitmap.buffer, g->bitmap.width, g->bitmap.rows, 1), c, yOffset));
					hasGlyph = true;
					break;
				}
				if (!hasGlyph) {
					result.UnrenderedChars.push_back(c);
				}
			}
		}

		std::sort(imgs.begin(), imgs.end(), [](const std::tuple<image::stb_image, char32_t, int>& a, const std::tuple<image::stb_image, char32_t, int>& b) {
			return std::get<0>(a).GetWidth() > std::get<0>(b).GetWidth();
		});

		int PixelLine = PixelWidth == 0 ? PixelHeight : PixelWidth;
		image::stb_image ErrorRender(PixelLine, PixelLine, 1);

		image::rgba white;
		white.channels = 1;
		white.rgbaArray[0] = 255;

		for (int x = 0; x < PixelLine; x++) {
			ErrorRender.SetPixel(x, 0, white);
			ErrorRender.SetPixel(0, x, white);
			ErrorRender.SetPixel(x, PixelLine - 1, white);
			ErrorRender.SetPixel(PixelLine - 1, x, white);
		}

		image::BSPTree::InsertResult bspresult = bsp.insert(ErrorRender);
		int ErrorRenderX = bspresult.x;
		int ErrorRenderY = bspresult.y;

		for (auto& v : imgs) {
			auto& [img, c, yOffset] = v;
			image::BSPTree::InsertResult bspresult = bsp.insert(img);
			if (bspresult.flag) {
				if (CharMap.count(c)) {//字符映射实现
					c = CharMap[c];
				}
				if (c != 0x20 && c != 0x3000) {
					NoitaFont.AddFontData(c, bspresult.x, bspresult.y, img.GetWidth(), img.GetHeight(), 0, yOffset, img.GetWidth() + FontSpacing);
				}
			}
			else {
				result.UnrenderedChars.push_back(c);
			}
		}
		if (!Char32SetAny && result.UnrenderedChars.size() == Char32Set.size()) {
			result.msg = "No character was rendered successfully";
			return result;
		}
		for (const auto& c : result.UnrenderedChars) {//不支持的字符就映射到这里
			NoitaFont.AddFontData(c, ErrorRenderX, ErrorRenderY, PixelLine, PixelLine, 0, 0, PixelLine + FontSpacing);
		}
		NoitaFont.AddFontData(0x20, 0, 0, 0, 0, 0, 0, HalfwidthSpaceWidth);//恒定插入，避免问题
		NoitaFont.AddFontData(0x3000, 0, 0, 0, 0, 0, 0, HalfwidthSpaceWidth * 2);

		bsp.Create().WritePng(SpriteFilePath);
		NoitaFont.SerializationToFile(BinFilePath);
		result.flag = true;
		return result;
	}

	bool NFontBuilder::Build() {
		return BuildWithInfo().flag;
	}
}
