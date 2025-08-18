#include <filesystem>
#include <vector>
#include <string>

#include <windows.h>

void load_file(const std::filesystem::path &path, std::vector<char> &buffer);
void sprintf_to_string(std::string &dest, const char *fmt, ...);
bool path_exists(const std::string& arg);
bool path_available(const std::string& arg);
bool to_uint64(const std::string& arg, uint64_t &value);
bool load_resource(int res_id, const LPWSTR res_type_id, std::vector<char> &data, std::string &error);