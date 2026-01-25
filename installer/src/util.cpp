
#include "util.hpp"

#include <fstream>

#include <stdarg.h>

bool path_exists(const std::string& arg) {
    return std::filesystem::exists(arg) && (std::filesystem::is_regular_file(arg) || std::filesystem::is_directory(arg));
}

bool path_available(const std::string& arg) {
    const std::filesystem::path path = arg;
    const auto base = std::filesystem::path(path).remove_filename();

    return (std::filesystem::exists(base) && std::filesystem::is_directory(base)) ||
        (std::filesystem::exists(path) && (std::filesystem::is_regular_file(path) || std::filesystem::is_directory(path)));
}

bool to_uint64(const std::string& arg, uint64_t &value) {
    printf("to number: %s\n", arg.c_str());
    const char *data = arg.c_str();
    size_t length = arg.length();
    int radix = 10;
    char *end;

    if (length < 1)
        return false;

    if (data[0] == '0') {
        if (length > 1) {
            if (data[1] == 'x') {
                radix = 16;
                data = data + 2;
                length -= 2;
            }
            else {
                radix = 8;
                data = data + 1;
                length -= 1;
            }
        }
        else {
            value = 0;
            return true;
        }
    }

    if (length < 1)
        return false;

    value = strtoull(data, &end, radix);

    if (end < data + length)
        return false;

    return true;
}

void load_file(const std::filesystem::path &path, std::vector<char> &buffer) {
    std::ifstream file(path, std::ios::binary);
    size_t size = file.tellg();

    file.seekg(0, std::ios::end);
    size = size_t(file.tellg()) - size;
    file.seekg(0, std::ios::beg);

    buffer.resize(size);
    file.read(buffer.data(), size);
    file.close();
}

void sprintf_to_string(std::string &dest, const char *fmt, ...)
{
    int required = 0;

    va_list args;
    va_start(args, fmt);
    required = vsnprintf(dest.data(), 0, fmt, args);
    va_end(args);

    dest.resize(required + 1);

    va_start(args, fmt);
    vsnprintf(dest.data(), dest.size(), fmt, args);
    va_end(args);
}

bool load_resource(int res_id, const LPWSTR res_type_id, std::vector<char> &data, std::string &error) {
    HMODULE hModule = GetModuleHandleW(NULL);
    if (!hModule) {
        sprintf_to_string(error, "failed to get module handle: %lu", GetLastError());
        return false;
    }

    HRSRC hRes = FindResourceW(hModule, MAKEINTRESOURCEW(res_id), MAKEINTRESOURCEW(res_type_id));
    if (!hRes) {
        sprintf_to_string(error, "failed to find resource: %lu", GetLastError());
        return false;
    }

    HGLOBAL hMem = LoadResource(hModule, hRes);
    if (!hMem) {
        sprintf_to_string(error, "failed to load resource: %lu", GetLastError());
        return false;
    }

    DWORD size = SizeofResource(hModule, hRes);
    if (!size) {
        sprintf_to_string(error, "failed to get resource size: %lu", GetLastError());
        return false;
    }

    char *res_data = (char *)LockResource(hMem);
    if (!res_data) {
        sprintf_to_string(error, "failed to get resource data: %lu", GetLastError());
        return false;
    }

    data = std::vector<char>(res_data, res_data + size);

    FreeResource(hMem);

    return true;
}
