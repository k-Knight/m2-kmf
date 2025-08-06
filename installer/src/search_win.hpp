#ifndef SEARCH_WIN
#define SEARCH_WIN

#include <filesystem>
#include <functional>
#include <vector>
#include <string>
#include <regex>

namespace search_win {
    namespace fs = std::filesystem;

    using path_t = fs::path;

    enum class path_type_t {
        directory,
        file
    };

    struct path_entry_t {
        path_t path;
        path_type_t type;
    };

    using paths_t = std::vector<path_t>;
    using names_t = std::vector<std::wstring>;
    using paths_typed_t =std::vector<path_entry_t>;

    struct context_t {
        const path_t &path;
        bool valid;
        bool continue_search;

        bool files_exist(const names_t &files) const;
        bool dirs_exist(const names_t &dirs) const;
        bool paths_exist(const paths_typed_t &paths) const;
    };

    using validator_t = std::function<void (context_t &)>;

    struct entry_t {
        std::wstring name;
        path_type_t type;
        validator_t validator;
    };

    using descriptor_t = std::vector<entry_t>;

    paths_t get_windows_drives();
    paths_t search_filesystem(const descriptor_t &descriptor);
}

#endif //SEARCH_WIN