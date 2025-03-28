#pragma once
#include <map>
#include <string>
#include <vector>

namespace NFontBin {
	std::map<std::string, std::string> GetArgKeyToValue(int argc, char* argv[]);
	template<typename T1, typename k, typename v>
	bool CheckMapValue(const T1& map, const k& key, const v& value) {
		if (map.count(key) && map.at(key) == value) {
			return true;
		}
		return false;
	}
	std::vector<std::string> split(const std::string& str, char delimiter);
}
