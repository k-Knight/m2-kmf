#ifndef INDEXED_FILE_AMALGAMATION
#define INDEXED_FILE_AMALGAMATION

#include <vector>
#include <string>
#include <filesystem>

#include <stdint.h>

//#define ENABLE_MASKING

struct file_info {
    std::string name;
    std::filesystem::path path;
};

typedef struct {
    std::string name;
    size_t comp_size;
    size_t orig_size;
    char *comp_data;
} ifa_entry_t;

typedef std::vector<ifa_entry_t> ifa_t;

bool validate_indexed_file_amalgamation(const std::vector<file_info> &files, const ifa_t &meta_data, std::string &error);
bool get_data(const ifa_entry_t &entry, std::vector<char> &dst);

#ifdef ENABLE_MASKING
bool load_indexed_file_amalgamation(std::vector<char> &data, ifa_t &meta_data, const uint64_t mask = 0);
bool read_indexed_file_amalgamation(const std::filesystem::path &path, std::vector<char> &data, ifa_t &meta_data, const uint64_t mask = 0);
bool create_indexed_file_amalgamation(const std::filesystem::path &path, const std::vector<file_info> &files, const uint64_t mask = 0);
#else
bool load_indexed_file_amalgamation(std::vector<char> &data, ifa_t &meta_data);
bool read_indexed_file_amalgamation(const std::filesystem::path &path, std::vector<char> &data, ifa_t &meta_data);
bool create_indexed_file_amalgamation(const std::filesystem::path &path, const std::vector<file_info> &files);
#endif // ENABLE_MASKING

#endif //INDEXED_FILE_AMALGAMATION