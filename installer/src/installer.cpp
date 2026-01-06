#include <string>
#include <vector>
#include <fstream>

#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include <windows.h>
#include <wchar.h>
#include <Shlobj.h>
#include <commctrl.h>

#include "ifa.hpp"
#include "util.hpp"
#include "search_win.hpp"
#include "resource.h"

search_win::paths_t potential_magicka2_dirs; 

void display_error(const wchar_t *format, const wchar_t *data, const wchar_t *advice) {
    wchar_t *buf;

    buf = (wchar_t *)malloc(sizeof(wchar_t) * 2048);
    wsprintf(buf, format, data, advice);
    MessageBoxW(NULL, buf, L"Unlucky!", MB_ICONWARNING);
    free(buf);

    return;
}

void install_file(const ifa_entry_t &entry, const std::filesystem::path *file_path) {
    std::wstring alt_data_stream = file_path->wstring();
    BOOL res;
    const wchar_t decomp_fail[] = L"Installer cannot decompress file \"%s\".\n%s";
    const wchar_t delete_fail[] = L"Installer cannot delete old file at \"%s\".\n%s";
    const wchar_t create_fail[] = L"Installer cannot create new file at \"%s\".\n%s";
    const wchar_t action[] = L"Skipping the file.\nMaybe run installer as an administrator.";

    if (std::filesystem::exists(*file_path)) {
        res = DeleteFileW(alt_data_stream.c_str());

        if (!res)
            return display_error(delete_fail, alt_data_stream.c_str(), action);
    }

    std::vector<char> data;
    res = get_data(entry, data);
    if (!res) {
        std::wstring wsTmp(entry.name.begin(), entry.name.end());
        return display_error(decomp_fail, wsTmp.c_str(), action);
    }

    std::ofstream out(*file_path, std::ios::binary);

    if (!out.is_open())
        return display_error(create_fail, alt_data_stream.c_str(), action);

    out.write(data.data(), data.size());
    out.close();

    alt_data_stream += L":Zone.Identifier";
    DeleteFileW(alt_data_stream.c_str());
}

bool try_create_directories(const std::filesystem::path *dir_path) {
    bool ret = false;
    try {
        ret = (std::filesystem::exists(*dir_path) && std::filesystem::is_directory(*dir_path)) ||
                std::filesystem::create_directories(*dir_path);
    }
    catch (...) {  }

    return ret;
}

RECT GetProgressBarRect()
{
   RECT r;
   int x, y, w, h;

   HWND hDesktop = GetDesktopWindow();
   GetWindowRect(hDesktop, &r);

   w = x = r.right - r.left;
   h = y = r.bottom - r.top;
   x /= 2;
   y /= 2;
   w /= 4;
   h /= 16;
   x -= w / 2;
   y -= h / 2;
   x += r.left;
   y += r.top;

   return {x, y, w, h};
}

bool try_find_magicka() {
    const auto kmf_dll = L"engine\\kmf_util.dll";
    search_win::descriptor_t magicka_desc = {
        {
            L"Magicka 2.*",
            search_win::path_type_t::directory,
            [](search_win::context_t &context) {
                context.valid = context.paths_exist({
                    {"data", search_win::path_type_t::directory},
                    {"data\\dlc", search_win::path_type_t::directory},
                    {"engine", search_win::path_type_t::directory},
                    {"engine\\Magicka2.exe", search_win::path_type_t::file},
                });
            }
        },
        {
            L"(Games)|(Игры)|(Steam)|(SteamLibrary)|(steamapps)|(common)",
            search_win::path_type_t::directory,
            [](search_win::context_t &context) {
                context.valid = true;
                context.continue_search = true;
            }
        },
        {
            L"Program Files(\\s\\(x86\\)){0,1}",
            search_win::path_type_t::directory,
            [](search_win::context_t &context) {
                context.valid = true;
                context.continue_search = true;
            }
        }
    };

    potential_magicka2_dirs = search_win::search_filesystem(magicka_desc);

    for (size_t i = 0; i < potential_magicka2_dirs.size(); i++) {
        const auto &dll_path = potential_magicka2_dirs.at(i) / kmf_dll;

        wprintf(L"finding dll at :: %ls\n", dll_path.wstring().c_str());

        if (search_win::fs::exists(dll_path) && search_win::fs::is_regular_file(dll_path)) {
            wprintf(L"    found dll, moving to front\n");
            std::swap(potential_magicka2_dirs[0], potential_magicka2_dirs[i]);
            break;
        }
    }

    for (const auto &result : potential_magicka2_dirs) {
        wprintf(L"found :: %ls\n", result.wstring().c_str());
    }

    return potential_magicka2_dirs.size() > 0;
}

int CALLBACK BrowseNotify(HWND hwnd, UINT uMsg, LPARAM lParam, LPARAM lpData) {
    static bool first_msg = true;

    if (first_msg && try_find_magicka()) {
        first_msg = false;
        SendMessage(hwnd, BFFM_SETEXPANDED, 1, (LPARAM)potential_magicka2_dirs[0].wstring().c_str());
        SendMessage(hwnd, BFFM_SETSELECTIONW, 1, (LPARAM)potential_magicka2_dirs[0].wstring().c_str());
        SendMessage(hwnd, BFFM_SETSTATUSTEXTW, 0, (LPARAM)L"found Magicka 2 install, please verify location");

        wchar_t *tmp = (wchar_t *)malloc(4096);
        wsprintf(tmp, L"Found Magicka 2 install at:\n    %ls\n\nPlease verify location", potential_magicka2_dirs[0].wstring().c_str());
        MessageBoxW(NULL,tmp,  L"Found Magicka 2", MB_ICONINFORMATION | MB_OK);
        free(tmp);

        return 1;
    }

    return 0;
}

#if defined(DEBUG) || defined(_DEBUG)
int wmain(int argc, wchar_t *argv[]) {
    HINSTANCE hInstance = NULL;
#else
int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PWSTR pCmdLine, int nCmdShow) {
#endif // DEBUG
    WCHAR szDir[MAX_PATH];
    BROWSEINFOW bInfo;
    wchar_t *tmp;
    int ret;
    bool res;

#ifdef ENABLE_MASKING
    volatile uint64_t num1 = 0x2c197f9df512bc40;
    volatile uint64_t num2 = 0x8b9fea92bf947ea5;
#endif // ENABLE_MASKING

    bInfo.hwndOwner = NULL;
    bInfo.pidlRoot = NULL; 
    bInfo.pszDisplayName = szDir; // Address of a buffer to receive the display name of the folder selected by the user
    bInfo.lpszTitle = L"Please select the Magicka 2 game's root directory";
    bInfo.ulFlags = BIF_USENEWUI | BIF_RETURNONLYFSDIRS | BIF_DONTGOBELOWDOMAIN;
    bInfo.lpfn = &BrowseNotify;
    bInfo.lParam = 0;
    bInfo.iImage = -1;

    LPITEMIDLIST lpItem = SHBrowseForFolderW(&bInfo);
    if (lpItem == NULL) {
        MessageBoxW(NULL, L"You failed to select a directory, unlucky.\nInstaller will exit.\n:/", L"Epic Fail!", MB_ICONWARNING);
        return 1;
    }

    if (!SHGetPathFromIDListW(lpItem, szDir)) {
        MessageBoxW(NULL, L"Idk wtf this shit is.\nInstaller will exit.\n:/", L"Epic Fail!", MB_ICONERROR);
        return 2;
    }

    tmp = (wchar_t *)malloc(2048);
    wsprintf(tmp, L"Are your sure you want to install to:.\n%ls", szDir);
    ret = MessageBoxW(NULL,tmp,  L"Proceed?", MB_ICONQUESTION | MB_OKCANCEL);
    free(tmp);

    if (IDCANCEL == ret) {
        MessageBoxW(NULL, L"I mean ok man. Sure.\nInstaller will exit.\n:/", L"Unlucky!", MB_ICONWARNING);
        return 3;
    }

    std::filesystem::path install_dir(szDir);
    ifa_t ifa_meta;
    std::vector<char> data;
    std::string error;
#ifdef ENABLE_MASKING
    volatile uint64_t mask = num1 * num2;
#endif // ENABLE_MASKING

    printf("trying to load memory resource\n");
    if (!load_resource(IDI_DATA_IFA, RT_RCDATA, data, error)) {
        MessageBoxW(NULL, L"Somehow failed to load memory resource ???\nThank you Windows\nInstaller will exit.\n:/",  L"Epic Fail!", MB_ICONERROR);
        return 4;
    }
    printf("loaded memory resource :: %zu\n", data.size());

#ifdef ENABLE_MASKING
    printf("reading resources with mask 0x%16llx\n", mask);
    res = load_indexed_file_amalgamation(data, ifa_meta, mask);
#else
    printf("reading resources\n");
    res = load_indexed_file_amalgamation(data, ifa_meta);
#endif // ENABLE_MASKING
    if (!res)  {
        MessageBoxW(NULL, L"Fucking HOW ???\nInstaller will exit.\n:/",  L"Epic Fail!", MB_ICONERROR);
        return 5;
    }

    HWND hwndPB;
    RECT pbRECT = GetProgressBarRect();
    int counter = 0;
    InitCommonControls();

    hwndPB = CreateWindowEx(0, PROGRESS_CLASS, (LPTSTR)NULL, WS_POPUP | WS_VISIBLE,
        pbRECT.left, pbRECT.top, pbRECT.right, pbRECT.bottom, NULL, (HMENU) 0, hInstance, NULL);

    SendMessage(hwndPB, PBM_SETRANGE, 0, MAKELPARAM(0, ifa_meta.size()));
    SendMessage(hwndPB, PBM_SETPOS, counter, 0);

    Sleep(150);

    printf("creating directories\n");
    if (!try_create_directories(&install_dir))
    {
        MessageBoxW(NULL, L"Installer cannot create needed directories. Unlucky.\nInstaller will exit.",
            L"Epic Fail!", MB_ICONERROR);
        return 6;
    }

    printf("installing files\n");
    for (const auto &entry : ifa_meta) {
        std::filesystem::path file_path = install_dir;
        std::filesystem::path file_dir;

        file_path.append(entry.name);
        file_dir = file_path.parent_path();

        if (try_create_directories(&file_dir))
            install_file(entry, &file_path);

        SendMessage(hwndPB, PBM_SETPOS, ++counter, 0);
        Sleep(50);
    }

    DestroyWindow(hwndPB);

    MessageBoxW(NULL, L"Installer finished work.\nHopefully successfully.",
            L"All Done", MB_ICONASTERISK);

    return 0;
}