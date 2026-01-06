#include "ifa.hpp"

#include <filesystem>
#include <fstream>
#include <vector>
#include <string>

#include <stdint.h>
#include <stdio.h>

#include <zstd.h>

#include "util.hpp"

extern "C" {
    struct data_index_entry {
        size_t offset;
        size_t comp_size;
        size_t orig_size;
        size_t name_len;
    };

    struct data_index {
        size_t size;
        size_t entry_count;
    };
}

#ifdef ENABLE_MASKING
static void mask_array(const uint64_t mask, char *arr, const size_t arr_size) {
    uint64_t bytes = 0;
    char *ptr = arr;
    size_t to_proc = 0;
    const char *arr_end = arr + arr_size;

    for (; ptr < arr + arr_size; ptr += to_proc) {
        bytes = 0;
        to_proc = arr_end - ptr > 8 ? 8 : arr_end - ptr;
        memmove(&bytes, ptr, to_proc);
        bytes ^= mask;
        memmove(ptr, &bytes, to_proc);
    }
}
#endif // ENABLE_MASKING

bool validate_indexed_file_amalgamation(const std::vector<file_info> &files, const ifa_t &meta_data, std::string &error) {
    for (const auto &file : files) {
        bool found = false;

        for (const auto &entry : meta_data) {
            if (entry.name == file.name) {
                std::vector<char> orig;
                std::vector<char> decomp;
                size_t ret;

                found = true;
                load_file(file.path, orig);

                if (!get_data(entry, decomp)) {
                    sprintf_to_string(error, "inflation failed : 0x%zx", ret);

                    return false;
                }

                if (decomp.size() != orig.size()) {
                    sprintf_to_string(error, "files \"%s\" do not match (size) : %zu -> %zu", file.name.c_str(), orig.size(), decomp.size());

                    return false;
                }

                for (size_t i = 0; i < decomp.size(); i++) {
                    if (decomp[i] != orig[i]) {
                        sprintf_to_string(error, "files \"%s\" do not match (data) :\n\tat %zu [ %02x -> %02x ]",
                            file.name.c_str(), i, 0xff & orig[i], 0xff & decomp[i]
                        );

                        return false;
                    }
                }

                break;
            }
        }

        if (!found) {
            sprintf_to_string(error, "file \"%s\" is missing", file.name.c_str());

            return false;
        }
    }

    return true;
}

#ifdef ENABLE_MASKING
bool load_indexed_file_amalgamation(std::vector<char> &data, ifa_t &meta_data, const uint64_t mask) {
#else
bool load_indexed_file_amalgamation(std::vector<char> &data, ifa_t &meta_data) {
#endif // ENABLE_MASKING

    data_index index = {0};
    char *ptr;
    const char *data_end;
    const char *index_end;
    bool valid = true;

    ptr = data.data();
    data_end = ptr + data.size();

    memmove(&index, ptr, sizeof(data_index));
    index_end = ptr + index.size;
    ptr += sizeof(data_index);

    if (index.size > data.size())
        return false; // sanity check

    if (ptr + sizeof(data_index_entry) * index.entry_count > index_end)
        return false; // sanity check

    meta_data.reserve(index.entry_count);

    for (size_t i = 0; i < index.entry_count; i++) {
        std::string name;
        const data_index_entry &entry = *(data_index_entry *)ptr;
        char *data_start = data.data() + entry.offset;
    
        ptr += sizeof(data_index_entry);

        if (data_start + entry.comp_size > data_end) {
            valid = false;
            break;
        }

        if (ptr + entry.name_len > index_end) {
            valid = false;
            break;
        }

        name.resize(entry.name_len);
        memmove(name.data(), ptr, entry.name_len);
        ptr += entry.name_len;
        meta_data.push_back({name, entry.comp_size, entry.orig_size, data_start});

#ifdef ENABLE_MASKING
        if (mask)
            mask_array(mask, data_start, entry.comp_size);
#endif // ENABLE_MASKING
    }

    if (!valid) {
        meta_data.clear();

        return false;
    }

    return true;
}

#ifdef ENABLE_MASKING
bool read_indexed_file_amalgamation(const std::filesystem::path &path, std::vector<char> &data, ifa_t &meta_data, const uint64_t mask) {
    load_file(path, data);

    return load_indexed_file_amalgamation(data, meta_data, mask);
}
#else
bool read_indexed_file_amalgamation(const std::filesystem::path &path, std::vector<char> &data, ifa_t &meta_data) {
    load_file(path, data);

    return load_indexed_file_amalgamation(data, meta_data);
}
#endif // ENABLE_MASKING

#ifdef ENABLE_MASKING
bool create_indexed_file_amalgamation(const std::filesystem::path &path, const std::vector<file_info> &files, const uint64_t mask) {
#else
bool create_indexed_file_amalgamation(const std::filesystem::path &path, const std::vector<file_info> &files) {
#endif // ENABLE_MASKING
    std::vector<data_index_entry> entries;
    std::ofstream ifa(path, std::ios::binary);
    data_index index = {0};

    index.size = sizeof(data_index);

    for (const auto &file : files) {
        index.entry_count++;
        index.size += sizeof(data_index_entry) + file.name.length();
        entries.push_back({0, 0, 0, file.name.length()});
    }

    ifa.seekp(index.size);

    for (size_t i = 0; i < files.size(); i++) {
        std::vector<char> deflated;
        size_t ret;

        {
            std::vector<char> orig;

            load_file(files[i].path, orig);
            entries[i].orig_size = orig.size();
            deflated.resize(ZSTD_compressBound(orig.size()));

            if(ZSTD_isError(ret = ZSTD_compress(deflated.data(), deflated.size(), orig.data(), orig.size(), 9)))
                return false;
        }

        deflated.resize(ret);
        entries[i].comp_size = deflated.size();
        entries[i].offset = ifa.tellp();

#ifdef ENABLE_MASKING
        if (mask)
            mask_array(mask, deflated.data(), deflated.size());
#endif // ENABLE_MASKING

        ifa.write(deflated.data(), deflated.size());
    }

    ifa.seekp(0, std::ios::beg);
    ifa.write((char *)&index, sizeof(data_index));

    for (size_t i = 0; i < files.size(); i++) {
        ifa.write((char *)&(entries[i]), sizeof(data_index_entry));
        ifa.write(files[i].name.c_str(), files[i].name.length());
    }

    return true;
}

bool get_data(const ifa_entry_t &entry, std::vector<char> &dst) {
    size_t ret;

    dst.resize(entry.orig_size);

    if(ZSTD_isError(ret = ZSTD_decompress(dst.data(), dst.size(), entry.comp_data, entry.comp_size))) {
        return false;
    }

    dst.resize(ret);
    dst.shrink_to_fit();

    return true;
}
