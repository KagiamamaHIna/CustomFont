#include "NFontBin.h"

namespace NFontBin {
	struct DWRawByte {
		uint8_t DW[4] = { 0,0,0,0 };

		const uint8_t& operator[](size_t index)const {
			return DW[index];
		}
		uint8_t& operator[](size_t index) {
			return DW[index];
		}

		uint8_t* begin() {
			return DW;
		}

		uint8_t* end() {
			return DW + 4;
		}

		const uint8_t* begin()const {
			return DW;
		}

		const uint8_t* end()const {
			return DW + 4;
		}
	};

	template<typename T1, typename T2>
	void push_container(T1& container, const T2& datas) {
		container.insert(container.end(), datas.begin(), datas.end());
	}

	//单浮点转双字原始字节序列，大端序，win默认小端
	static DWRawByte SF2DWRawByteBE(float num) {
		uint8_t* u8ptr = reinterpret_cast<uint8_t*>(&num);
		DWRawByte result;
		for (size_t i = 0; i < 4; i++) {
			result[3 - i] = *u8ptr;
			u8ptr++;
		}
		return result;
	}

	static DWRawByte u32ToDWRawByteBE(uint32_t num) {
		uint8_t* u8ptr = reinterpret_cast<uint8_t*>(&num);
		DWRawByte result;
		for (size_t i = 0; i < 4; i++) {
			result[3 - i] = *u8ptr;
			u8ptr++;
		}
		return result;
	}

	static void WriteBinFile(const std::string& path, const std::vector<uint8_t>& BinData) {//写入二进制文件
		std::ofstream outputFile(path, std::ios::binary | std::ios::trunc);
		outputFile.write((const char*)BinData.data(), BinData.size());
		outputFile.close();
	}

	void FontBin::AddFontData(uint32_t unicode, float RectX, float RectY, float RectW, float RectH, float VecX, float VecY, float width) {
		data.push_back(FontData(unicode, RectX, RectY, RectW, RectH, VecX, VecY, width));
	}

	std::vector<uint8_t> FontBin::Serialization() {
		std::vector<uint8_t> result;
		result.reserve(24 + SpritePath.size() + data.size() * 32);//24为前8字节+后十六字节（存元数据的预分配），整体为提前申请好足够的空间
		push_container(result, u32ToDWRawByteBE(1));//我不知道！
		push_container(result, u32ToDWRawByteBE(SpritePath.size()));//字符串长度
		push_container(result, SpritePath);//精灵图路径
		push_container(result, SF2DWRawByteBE(width));//字形宽度

		push_container(result, DWRawByte());//填充两个0
		push_container(result, DWRawByte());

		push_container(result, u32ToDWRawByteBE(data.size()));//字形数
		for (const auto& font : data) {//字体数据插入
			push_container(result, u32ToDWRawByteBE(font.unicode));

			push_container(result, SF2DWRawByteBE(font.Rect.x));
			push_container(result, SF2DWRawByteBE(font.Rect.y));
			push_container(result, SF2DWRawByteBE(font.Rect.w));
			push_container(result, SF2DWRawByteBE(font.Rect.h));

			push_container(result, SF2DWRawByteBE(font.Vec2.x));
			push_container(result, SF2DWRawByteBE(font.Vec2.y));

			push_container(result, SF2DWRawByteBE(font.width));
		}
		return result;
	}
	void FontBin::SerializationToFile(const std::string& path) {
		WriteBinFile(path, Serialization());
	}
}
