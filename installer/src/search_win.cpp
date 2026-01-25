#include "search_win.hpp"

#include <windows.h>
#include <wchar.h>
#include <stdio.h>

using namespace search_win;

typedef struct {
    const entry_t &entry;
    const std::string utf8_name;
} proc_entry_t;

typedef std::vector<proc_entry_t> proc_descriptor_t;
typedef std::vector<std::string> proc_names_t;

static void print_paths(const paths_t &to_print) {
    for (const auto &elem : to_print) {
        wprintf(L"    %ls\n", elem.wstring().c_str());
    }
}

static void print_proc_descriptor(const proc_descriptor_t &to_print) {
    for (const auto &elem : to_print) {
        wprintf(L"    %ls -> %s\n", elem.entry.name.c_str(), elem.utf8_name.c_str());
    }
}

static bool wstr_to_str(const std::wstring& src, std::string &dst) {
    if (src.empty()) {
        dst = "";
        return true;
    }

    const int size_needed = WideCharToMultiByte(CP_UTF8, 0, src.data(), (int)src.size(), NULL, 0, NULL, NULL);

    if (size_needed <= 0)
        return false;

    dst.resize(size_needed);
    WideCharToMultiByte(CP_UTF8, 0, src.data(), (int)src.size(), dst.data(), size_needed, NULL, NULL);

    return true;
}

static void wstrs_to_strs(const names_t& src, proc_names_t &dst) {
    dst.reserve(src.size());

    for (const auto &wstr : src) {
        std::string str;

        if(!wstr_to_str(wstr, str))
            continue;

        dst.push_back(str);
    }
}

static bool check_names_exist(
    const path_t &path,
    const names_t &names,
    bool (fs::directory_entry::*verify_type)(void) const
) {
    proc_names_t f_names;

    wstrs_to_strs(names, f_names);

    if (!f_names.size())
        return false;

    for (const auto &fs_entry : fs::directory_iterator(path)) {
        wprintf(L"found [%ls] :: type_match %ls\n", fs_entry.path().wstring().c_str(), (fs_entry.*verify_type)() ? L"true" : L"false");
        if (!(fs_entry.*verify_type)())
            continue;

        if (!f_names.size())
            return true;

        const path_t &f_path = fs_entry.path();
        std::string name;
        size_t matched = f_names.size();

        if(!wstr_to_str(f_path.filename().wstring(), name))
            continue;

        for (size_t i = 0; i < f_names.size(); i++) {
            const std::regex re(f_names.at(i), std::regex_constants::ECMAScript | std::regex_constants::icase);

            if (std::regex_match(name, re)) {
                matched = i;
                break;
            }
        }

        if (matched >= f_names.size())
            return false;
        else
            f_names.erase(f_names.begin() + matched);
    }

    return f_names.size() < 1;
}

bool search_win::context_t::paths_exist(const paths_typed_t &paths) const {
    for (const auto &t_path : paths) {
        const auto &f_path = path / t_path.path;

        if (!fs::exists(f_path))
            return false;

        if (t_path.type == path_type_t::file && !fs::is_regular_file(f_path))
            return false;

        if (t_path.type == path_type_t::directory && !fs::is_directory(f_path))
            return false;
    }

    return true;
}

bool search_win::context_t::files_exist(const names_t &files) const {
    return check_names_exist(path, files, &fs::directory_entry::is_regular_file);
}

bool search_win::context_t::dirs_exist(const names_t &dirs) const {
    return check_names_exist(path, dirs, &fs::directory_entry::is_directory);
}

paths_t search_win::get_windows_drives() {
    paths_t res;
    DWORD drives = GetLogicalDrives();

    for (DWORD i = 0; i < 26; i++) {
        if (drives & ( 1 << i )) {
            const wchar_t drive[] = { wchar_t(L'A' + i), L':', L'\\', L'\0' };
            res.push_back(drive);
        }
    }

    return res;
}

paths_t search_win::search_filesystem(const descriptor_t &descriptor) {
    paths_t search_paths = get_windows_drives();
    paths_t search_matches;
    proc_descriptor_t proc_desc;

    proc_desc.reserve(descriptor.size());

    for (const auto &entry : descriptor) {
        std::string utf8_name;

        if(!wstr_to_str(entry.name, utf8_name))
            continue;

        proc_desc.push_back({entry, utf8_name});
    }

    if (!proc_desc.size())
        return search_matches;

    while (search_paths.size()) {
        path_t path = search_paths.back();
        search_paths.pop_back();

        try {
            for (const auto &fs_entry : fs::directory_iterator(path, fs::directory_options::skip_permission_denied)) {
                const path_t &new_path = fs_entry.path();
                std::string name;

                if(!wstr_to_str(new_path.filename().wstring(), name))
                    continue;

                for (const auto &entry : proc_desc) {
                    const std::regex re(entry.utf8_name, std::regex_constants::ECMAScript | std::regex_constants::icase);

                    if (std::regex_match(name, re)) {
                        if (entry.entry.type == path_type_t::file && !fs::is_regular_file(new_path))
                            continue;

                        if (entry.entry.type == path_type_t::directory && !fs::is_directory(new_path))
                            continue;

                        context_t context = {new_path, false, false};
                        entry.entry.validator(context);

                        if (context.valid) {
                            if (context.continue_search && entry.entry.type != path_type_t::file)
                                search_paths.push_back(new_path);
                            else
                                search_matches.push_back(new_path);
                        }
                    }
                }
            }
        } catch ( ... ) { }
    }

    return search_matches;
}
