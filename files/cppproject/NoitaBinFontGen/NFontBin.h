#pragma once
#include <string>
#include <vector>
#include <fstream>

namespace NFontBin {
	class FontBin {
	public:
		FontBin(float width, std::string SpritePath = "") :width{ width }, SpritePath{ SpritePath } {}
		virtual ~FontBin() = default;

		void SetSpritePath(const std::string& path) {
			SpritePath = path;
		}
		std::string GetSpritePath() {
			return SpritePath;
		}

		void AddFontData(uint32_t unicode, float RectX, float RectY, float RectW, float RectH, float VecX, float VecY, float width);
		std::vector<uint8_t> Serialization();
		void SerializationToFile(const std::string& path);
	private:
		struct FontData {
			FontData(uint32_t unicode, float RectX, float RectY, float RectW, float RectH, float VecX, float VecY, float width) :width{ width }, unicode{ unicode } {
				Rect.x = RectX;
				Rect.y = RectY;
				Rect.w = RectW;
				Rect.h = RectH;
				Vec2.x = VecX;
				Vec2.y = VecY;
			}
			struct {
				float x;
				float y;
				float w;
				float h;
			} Rect;

			struct {
				float x;
				float y;
			} Vec2;

			float width;
			uint32_t unicode;
		};

		std::vector<FontData> data;
		std::string SpritePath;
		float width;
	};
}
