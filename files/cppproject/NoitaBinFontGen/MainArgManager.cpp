#include "MainArgManager.h"


namespace NFontBin {
	std::map<std::string, std::string> GetArgKeyToValue(int argc, char* argv[]) {
		std::map<std::string, std::string> result;
		if ((argc + 1) % 2 != 0) {//强制偶数对
			argc--;
		}
		for (int i = 1; i < argc; i += 2) {
			result[argv[i]] = argv[i + 1];
		}
		return result;
	}

	std::vector<std::string> split(const std::string& str, char delimiter) {
		std::vector<std::string> result;
		size_t start = 0;
		size_t end = str.find(delimiter);

		while (end != std::string::npos) {
			result.push_back(str.substr(start, end - start));
			start = end + 1;
			end = str.find(delimiter, start);
		}

		result.push_back(str.substr(start));
		return result;
	}
}
