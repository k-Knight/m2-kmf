#include <vector>
#include <string>
#include <filesystem>
#include <iostream>

#include <stdlib.h>
#include <stdio.h>

#include "clipp.hpp"
#include "ifa.hpp"
#include "util.hpp"

using namespace clipp;

bool find_files(const std::filesystem::path &path, std::vector<file_info> &files) {
    if (!std::filesystem::exists(path))
        return false;

    if (std::filesystem::is_regular_file(path))
        files.push_back({path.filename().string(), path});
    else if (std::filesystem::is_directory(path)) {
        for (std::filesystem::recursive_directory_iterator i(path), end; i != end; ++i)
            if (!std::filesystem::is_directory(i->path())) {
                files.push_back({i->path().lexically_relative(path).string(), i->path()});
            }
    }
    else
        return false;

    return true;
}

int main(int argc, char **argv) {
    std::vector<char> data_ifa;
    ifa_t ifa_meta;

    std::string in_path, out_path, mask_str;
    uint64_t mask;
    bool normalize = false;
    bool print_help = false;
    bool validate = false;

    auto input_opt = (required("-i", "--input") & value("input path", in_path)).doc("path to file or directory to compress");
    auto output_opt = (required("-o", "--output") & value("output path", out_path)).doc("output file path");
    auto mask_opt = (option("-m", "--mask") & value("mask", mask_str)).doc("mask to apply to contents");
    auto norm_opt = option("-n", "--normalize").set(normalize).doc("normalize file names");
    auto help_opt = option("-h", "--help").set(print_help).doc("print help");
    auto validate_opt = option("-c", "--validate").set(validate).doc("validate created ifa");
    auto cli = (input_opt,  output_opt, mask_opt, norm_opt, validate_opt, help_opt);
    auto parse_ret = parse(argc, argv, cli);

    if (print_help || !parse_ret) {
        std::cout << make_man_page(cli, "packager") << '\n';

        return print_help ? 0 : 1;
    }

    if (!path_exists(in_path)) {
        printf("Input path does not point to a valid directory or file\n");
        return 2;
    }

    if (!path_available(out_path)) {
        printf("Cannot write to output path\n");
        return 2;
    }

    if (!to_uint64(mask_str, mask)) {
        printf("Mask is not a valid 64bit integer\n");
        return 2;
    }

    printf("Using mask :    0x%016llx\n", mask);

    std::vector<file_info> files;
    find_files(in_path, files);

    printf("Found files :\n");

    for (const auto &file : files) {
        printf("    %s\n", file.name.c_str());
    }

#ifdef ENABLE_MASKING
    if (!create_indexed_file_amalgamation(out_path, files, mask)) {
#else
    if (!create_indexed_file_amalgamation(out_path, files)) {
#endif // ENABLE_MASKING
        std::filesystem::remove(out_path);
        printf("Failed to create ifa\n");
        return 3;
    }

    printf("\nLoading ifa :\n");

#ifdef ENABLE_MASKING
    if (!read_indexed_file_amalgamation(out_path, data_ifa, ifa_meta, mask)) {
#else
    if (!read_indexed_file_amalgamation(out_path, data_ifa, ifa_meta)) {
#endif // ENABLE_MASKING
        printf("Could not load ifa\n");
        return 4;
    }
    else {
        for (const auto &entry : ifa_meta)
            printf("    %40s    [ %15zu -> %15zu ]\n", entry.name.c_str(), entry.comp_size, entry.orig_size);
    }

    if (validate) {
        printf("\nValidating ifa :\n");
        std::string error;

        if (!validate_indexed_file_amalgamation(files, ifa_meta, error)) {
            printf("%s\n", error.c_str());
            printf("Validation failure\n");
            return 5;
        }
        else
            printf("Validation success\n");
    }

    return 0;
}