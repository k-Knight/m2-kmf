#include "kmf_util.hpp"

#include <windows.h>
#pragma comment(lib, "Shell32.lib")
#include <shellapi.h>

#include <steam_api.h>

#include <thread>
#include <fstream>
#include <sstream>
#include <string>
#include <mutex>
#include <cstdlib>

#include "input_handler.hpp"
#include "debug_logger.hpp"

#define MAX_MOD_COUNT 1024
#define MAX_MOD_SETTING_COUNT 32

using namespace std;

static volatile bool initialized = false;
static volatile bool file_paths_initialized = false;
static std::filesystem::path mod_config_path;
static std::filesystem::path settings_gui_path;
static std::filesystem::path debug_log_path;
static std::filesystem::path gamepad_listener_path;
static std::mutex file_io_mutex;
static std::mutex libary_function_mutex;
static bool double_buffer_initialized = false;
std::unique_lock<std::mutex> external_lock;
typedef decltype(&SteamFriends) steam_friends_t;

static const vector<const char *> player_targets = {
    "caster", "everyone"
};
static const vector<const char *> keyboard_buttons = {
    "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12",
    "alt", "ctrl", "shift", "enter", "space", "insert", "delete", "backspace", "tab", "minus", "equal",
    "home", "end", "page up", "page down", "up", "down", "left", "right",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
};
static const vector<const char *> gamepad_buttons = {
    "d_up", "d_down", "d_left", "d_right",
    "start", "back",
    "left_thumb", "right_thumb",
    "left_shoulder", "right_shoulder",
    "left_trigger", "right_trigger",
    "a", "b", "x", "y",
    NULL,
    "triangle", "circle", "cross", "square",
    "l1", "r1",
    "l2", "r2",
    "l3", "r3",
    "up", "right", "down", "left",
    "options", "share"
};
static const SettingPossibleValues unknown_settings = { SettingType::unknown_setting_type, NULL };
static const SettingPossibleValues keyboard_hotkey_settings = { SettingType::keyboard_hotkey, &keyboard_buttons };
static const SettingPossibleValues gamepad_hotkey_settings = { SettingType::gamepad_hotkey, &gamepad_buttons };
static const SettingPossibleValues player_target_settings = { SettingType::player_target, &player_targets };
static const SettingPossibleValues wizard_name_settings = { SettingType::wizard_name, NULL };
static const SettingPossibleValues profile_name_settings = { SettingType::profile_name, NULL };

static volatile ModDataArray mod_data_arr;

static struct {
    vector<ModDataEntry> first, second, *current, *unused;

    void init() {
        current = &first;
        unused = &second;
    }

    void swap_buffer(bool clear_unused = true) {
        vector<ModDataEntry> *tmp = current;

        current = unused;
        unused = tmp;

        if (clear_unused)
            unused->clear();
    }
} ModDataDoubleBuffer;

static void *stubborn_malloc(size_t size) {
    static std::mutex stubborn_malloc_mutex;

    for (size_t i = 0; i < 10; i++) {
        std::unique_lock<std::mutex> lock(stubborn_malloc_mutex);
        void *ret = malloc(size);

        if (ret != NULL)
            return ret;
    }

    debug_write("malloc disaster or skill issue\n");
    std::terminate();
}

static void execute(std::filesystem::path *to_exec) {
    std::wstring path = to_exec->wstring();
    STARTUPINFOW info = { sizeof(info) };
    PROCESS_INFORMATION processInfo;

    if (CreateProcessW(path.c_str(), (LPWSTR)L"", NULL, NULL, FALSE, DETACHED_PROCESS, NULL, NULL, &info, &processInfo)) {
        CloseHandle(processInfo.hProcess);
        CloseHandle(processInfo.hThread);
    }
    else {
        SHELLEXECUTEINFOW sei = { sizeof(sei) };

        sei.lpVerb = L"open";
        sei.lpFile = path.c_str();
        sei.hwnd = NULL;
        sei.nShow = SW_NORMAL;

        if (!ShellExecuteExW(&sei))
        {
            DWORD dwError = GetLastError();
            char *error = (char *)stubborn_malloc(1024);

            sprintf(error, "Failed to open settings GUI.\nError happened: %lu", dwError);
            MessageBoxA(NULL, error, "Action not performed", MB_ICONWARNING);
        }
    }
}

enum parsing_state {
    read_mod_name = 0,
    read_field_name,
    read_field_value
};

std::string trimmed_string_ncpy(const std::string *src, size_t start, size_t end) {
    if (!src)
        return std::string();

    while (isspace(static_cast<unsigned char>((*src)[start])))
        start++;

    while (isspace(static_cast<unsigned char>((*src)[end])))
        end--;

    if (end - start < 1)
        return std::string();

    return (*src).substr(start, end - start);
}

static void parse_mods_settings(std::istream &infile, bool clear_unused) {
    std::string line;

    if (!double_buffer_initialized) {
        ModDataDoubleBuffer.init();
        double_buffer_initialized = true;
    }

    vector<ModDataEntry> *modData = ModDataDoubleBuffer.unused;
    parsing_state state = read_mod_name;
    std::string field_name, field_value;
    size_t start_pos, end_pos;
    ModDataEntry *entry = NULL;

    while (std::getline(infile, line))
    {
        bool line_processed = false;

        while (!line_processed) {
            switch (state) {
                case read_mod_name: {
                    if (((start_pos = line.find('[')) != std::string::npos) && ((end_pos = line.find(']')) != std::string::npos)) {
                        modData->push_back(ModDataEntry());
                        entry = &(modData->back());
                        entry->name = trimmed_string_ncpy(&line, start_pos + 1, end_pos);
                        state = read_field_name;
                        line_processed = true;
                    }
                    else
                        line_processed = true;
                } break;
                case read_field_name: {
                    if ((start_pos = line.find('[')) != std::string::npos) {
                        state = read_mod_name;
                        break;
                    }

                    if ((start_pos = line.find('=')) == std::string::npos) {
                        line_processed = true;
                        break;
                    }

                    field_name = trimmed_string_ncpy(&line, 0, start_pos);

                    if (field_name.empty()) {
                        line_processed = true;
                        break;
                    }

                    field_value = trimmed_string_ncpy(&line, start_pos + 1, line.length());

                    if (field_value.empty()) {
                        line_processed = true;
                        state = read_field_value;
                        break;
                    }

                    if (field_name == "status")
                        entry->status = field_value == "enabled";
                    else {
                        entry->settings.emplace(field_name, field_value);
                    }

                    line_processed = true;
                } break;
                case read_field_value: {
                    if ((line.find('[')) != std::string::npos) {
                        state = read_mod_name;
                        break;
                    }
                    if ((line.find('=')) != std::string::npos) {
                        state = read_field_name;
                        break;
                    }

                    field_value = trimmed_string_ncpy(&line, 0, line.length());

                    if (field_value.empty()) {
                        line_processed = true;
                        break;
                    }

                    if (field_name == "status")
                        entry->status = field_value == "enabled";
                    else {
                        entry->settings.emplace(field_name, field_value);
                    }

                    line_processed = true;
                } break;
            }
        }
    }

    ModDataDoubleBuffer.swap_buffer(clear_unused);
}

void parse_string_mods_settings(const char *config_str, bool clear_unused) {
    std::unique_lock<std::mutex> lock(file_io_mutex);
    std::string tmp_str(config_str);
    std::istringstream instring(tmp_str);

    parse_mods_settings(instring, clear_unused);
}

void parse_file_mods_settings(bool clear_unused) {
    std::unique_lock<std::mutex> lock(file_io_mutex);

    if(!config_file_exists()) {
        ModDataDoubleBuffer.swap_buffer(clear_unused);
        return;
    }

    std::ifstream infile(mod_config_path);

    infile.seekg(0, std::ios::end);

    size_t size = infile.tellg();
    std::string buffer(size, '\0');

    infile.seekg(0);
    infile.read(buffer.data(), size);
    infile.close();

    std::istringstream instring(buffer);

    parse_mods_settings(instring, clear_unused);
}

static void construct_moda_data_array() {
    std::unique_lock<std::mutex> lock(file_io_mutex);
    size_t mod_count = 0;

    for (auto &entry : *ModDataDoubleBuffer.current) {
        if (mod_count >= MAX_MOD_COUNT)
            break;

        size_t setting_count = 0;
        ModData *mod_data = &(mod_data_arr.data[mod_count]);

        mod_data->enabled = entry.status;
        mod_data->mod_name = const_cast<char*>(entry.name.c_str());

        for (auto& setting : entry.settings) {
            if (setting_count >= MAX_MOD_SETTING_COUNT)
                break;

            ModSetting *mod_setting = &(mod_data->setting_data[setting_count]);

            mod_setting->name = const_cast<char*>(setting.first.c_str());
            mod_setting->value = const_cast<char*>(setting.second.c_str());

            mod_data->setting_length = ++setting_count;
        }

        mod_data_arr.length = ++mod_count;
    }
}

static void smart_mod_config_watcher() {
    char file_name[MAX_PATH];
    std::wstring wstr(mod_config_path.parent_path());
    size_t fni_size = 2 * (sizeof(FILE_NOTIFY_INFORMATION) + MAX_PATH);
    unsigned char *buf = (unsigned char *)stubborn_malloc(fni_size);
    FILE_NOTIFY_INFORMATION *strFileNotifyInfo = (FILE_NOTIFY_INFORMATION *)buf;
    DWORD dwBytesReturned = 0;

    size_t str_size = wcstombs(file_name, wstr.c_str(), MAX_PATH);
    file_name[str_size] = '\0';

    HANDLE  ch_handle = FindFirstChangeNotificationW(wstr.c_str(), FALSE, FILE_NOTIFY_CHANGE_LAST_WRITE);

    {
        std::unique_lock<std::mutex> lock(libary_function_mutex);
        parse_file_mods_settings();
    }

    while (true)
    {
        DWORD Wait = WaitForSingleObject(ch_handle, INFINITE);

        if (Wait == WAIT_OBJECT_0)
            FindNextChangeNotification(ch_handle);
        else
            break;

        ReadDirectoryChangesW(ch_handle, (LPVOID)strFileNotifyInfo, fni_size, FALSE, FILE_NOTIFY_CHANGE_LAST_WRITE, &dwBytesReturned, NULL, NULL);

        if (dwBytesReturned < fni_size - 1) {
            buf[dwBytesReturned] = 0;
            buf[dwBytesReturned + 1] = 0;
        }
        else {
            buf[fni_size - 1] = 0;
            buf[fni_size - 2] = 0;
        }

        str_size = wcstombs(file_name, strFileNotifyInfo->FileName, MAX_PATH);
        file_name[str_size] = '\0';

        if (0 == strcmp("m2_mods.cfg", file_name)) {
            std::unique_lock<std::mutex> lock(libary_function_mutex);


            parse_file_mods_settings();
            construct_moda_data_array();
        }
    }

    free(strFileNotifyInfo);
    FindCloseChangeNotification(ch_handle);
}

static void stupid_mod_config_watcher() {
    while (true) {
        if (config_file_exists()) {
            std::unique_lock<std::mutex> lock(libary_function_mutex);

            parse_file_mods_settings();
            construct_moda_data_array();
        }

        Sleep(500);
    }
}

bool config_file_exists() {
    return std::filesystem::exists(mod_config_path) && std::filesystem::is_regular_file(mod_config_path);
}

void setup_file_paths() {
    if (file_paths_initialized)
        return;

    WCHAR w_file_name[MAX_PATH + 1];
    DWORD res;

    res = GetModuleFileNameW(NULL, w_file_name, MAX_PATH);
    w_file_name[res] = L'\0';

    std::filesystem::path exe_dir(w_file_name);
    debug_log_path = settings_gui_path = mod_config_path = gamepad_listener_path = exe_dir.parent_path();
    mod_config_path.append(L"m2_mods.cfg");
    settings_gui_path.append(L"m2_mod_settings.exe");
    debug_log_path.append(L"log.txt");
    gamepad_listener_path.append(L"sdl_gamepad_listener.exe");

    file_paths_initialized = true;
}

static void initialize_manager() {
    if (initialized)
        return;

    setup_file_paths();
    debug_log_init(debug_log_path);

    const size_t mod_data_size = sizeof(ModData) * MAX_MOD_COUNT;
    const size_t mod_settings_size = sizeof(ModSetting) * MAX_MOD_SETTING_COUNT;

    mod_data_arr.length = 0;
    mod_data_arr.data = (ModData *)stubborn_malloc(mod_data_size);
    for (size_t i = 0; i < MAX_MOD_COUNT; i++) {
        ModData *entry = &(mod_data_arr.data[i]);

        entry->enabled = false;
        entry->mod_name = NULL;

        entry->setting_length = 0;
        entry->setting_data = (ModSetting *)stubborn_malloc(mod_settings_size);
        memset((char *)(entry->setting_data), 0, mod_settings_size);
    }

    init_gamepad_listener(&gamepad_listener_path);

    initialized = true;

    if (config_file_exists()) {
        parse_file_mods_settings();
        construct_moda_data_array();
    }

    std::thread watcher(stupid_mod_config_watcher);
    watcher.detach();
}

void save_mod_settings() {
    std::unique_lock<std::mutex> lock(file_io_mutex);
    std::ofstream outfile(mod_config_path);

    for (auto &entry : *ModDataDoubleBuffer.current) {
        outfile.write("[", 1);
        outfile.write(entry.name.c_str(), entry.name.length());
        outfile.write("]", 1);
        outfile.write("\n", 1);

        outfile.write("status=", 7);
        if (entry.status)
            outfile.write("enabled", 7);
        else
            outfile.write("disabled", 8);
        outfile.write("\n", 1);

        for (auto& setting : entry.settings) {
            outfile.write(setting.first.c_str(), setting.first.length());
            outfile.write("=", 1);
            outfile.write(setting.second.c_str(), setting.second.length());
            outfile.write("\n", 1);
        }

        outfile.write("\n", 1);
    }
}

std::filesystem::path get_mod_config_path() {
    setup_file_paths();

    return mod_config_path;
}

std::vector<ModDataEntry> *get_mod_config_entries() {
    return ModDataDoubleBuffer.current;
}

inline void tolower(std::string &s) {
    std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) {
        return std::tolower(c);
    });
}

inline void ltrim(std::string &s) {
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](unsigned char ch) {
        return !std::isspace(ch);
    }));
}

inline void rtrim(std::string &s) {
    s.erase(std::find_if(s.rbegin(), s.rend(), [](unsigned char ch) {
        return !std::isspace(ch);
    }).base(), s.end());
}

bool validate_value(const std::string *setting, const char *value) {
    if (!value)
        return false;

    const SettingPossibleValues &possible_values = *get_setting_possible_values(setting);
    size_t value_len = strlen(value);

    switch (possible_values.type) {
        case SettingType::gamepad_hotkey:
        case SettingType::keyboard_hotkey: {
            std::stringstream ss(value);
            std::vector<std::string> words_used;
            std::string word;
            bool prev_plus = false;
            bool prev_button = false;
            size_t word_begin = 0, word_end = 0;

            for (size_t i = 0; i < value_len; i++) {
                char cur = value[i];
                bool parse_word = false;

                if (isspace(cur)) {
                    if (word_begin != word_end) {
                        word = std::string(value + word_begin, word_end - word_begin);
                        prev_button = parse_word = true;
                    }

                    word_end = word_begin = i + 1;
                }
                else if (isalnum(cur) || cur == '_') {
                    if (prev_button)
                        return false;

                    word_end++;
                    prev_plus = false;
                }
                else if (cur == '+') {
                    if (prev_plus)
                        return false;

                    prev_button = false;
                    prev_plus = true;

                    if (word_begin != word_end) {
                        word = std::string(value + word_begin, word_end - word_begin);
                        parse_word = true;
                    }

                    word_end = word_begin = i + 1;
                }

                if (i + 1 >= value_len && word_begin != word_end) {
                    word = std::string(value + word_begin, word_end - word_begin);
                    parse_word = true;
                }

                if (parse_word) {
                    bool found = false;

                    tolower(word);

                    for (const char *possible_value : *possible_values.values)
                        if (possible_value && (word == possible_value)) {
                            found = true;
                            break;
                        }

                    if (!found)
                        return false;

                    if (std::find(words_used.begin(), words_used.end(), word) != words_used.end())
                        return false;

                    words_used.push_back(word);
                }
            }

            if (prev_plus)
                return false;
        }; break;
        case SettingType::player_target: {
            std::string word(value);

            ltrim(word);
            rtrim(word);
            tolower(word);

            bool found = false;
            for (const char *possible_value : *possible_values.values)
                if (possible_value && (word == possible_value)) {
                    found = true;
                    break;
                }

            return found;
        } break;
        case SettingType::wizard_name:
        case SettingType::profile_name: {
            if (value_len < 1)
                return false;
        } break;
        default:
            return false;
    }

    return true;
}

const SettingPossibleValues *get_setting_possible_values(const std::string *setting) {
    if (*setting == "keyboard hotkey")
        return &keyboard_hotkey_settings;
    if (*setting == "gamepad hotkey")
        return &gamepad_hotkey_settings;
    if (*setting == "target player")
        return &player_target_settings;
    if (*setting == "wizard name")
        return &wizard_name_settings;
    if (*setting == "profile name")
        return &profile_name_settings;

    return &unknown_settings;
}

extern "C" {
    void display_settings_menu() {
        std::unique_lock<std::mutex> lock(libary_function_mutex);

        initialize_manager();

        debug_write("in display_settings_menu()\n");

        execute(&settings_gui_path);
    }

    void update_config_file(char* config_str) {
        std::unique_lock<std::mutex> lock(libary_function_mutex);

        initialize_manager();

        debug_write("in update_config_file()\n");

        parse_string_mods_settings(config_str);
        parse_file_mods_settings(false);

        vector<ModDataEntry>& cfg_file = *ModDataDoubleBuffer.current;
        vector<ModDataEntry>& cfg_update = *ModDataDoubleBuffer.unused;

        for (auto &entry_f : cfg_file) {
            for (auto &entry_u : cfg_update) {
                if (entry_f.name == entry_u.name) {
                    entry_u.status = entry_f.status;

                    for (auto &setting_f : entry_f.settings)
                        if (entry_u.settings.find(setting_f.first) != entry_u.settings.end())
                            entry_u.settings[setting_f.first] = setting_f.second;

                    break;
                }
            }
        }

        ModDataDoubleBuffer.swap_buffer(false);

        construct_moda_data_array();
        save_mod_settings();
    }

#if defined(DEBUG) || defined(_DEBUG)
    static const char *btn_2_str(gamepad_btn_t btn) {
        switch (btn) {
        case gamepad_d_up:
            return "d up";
        case gamepad_d_down:
            return "d down";
        case gamepad_d_left:
            return "d left";
        case gamepad_d_right:
            return "d right";
        case gamepad_start:
            return "start";
        case gamepad_back:
            return "back";
        case gamepad_left_thumb:
            return "l3";
        case gamepad_right_thumb:
            return "r3";
        case gamepad_left_shoulder:
            return "l1";
        case gamepad_right_shoulder:
            return "r1";
        case gamepad_left_trigger:
            return "l2";
        case gamepad_right_trigger:
            return "r2";
        case gamepad_a:
            return "a";
        case gamepad_b:
            return "b";
        case gamepad_x:
            return "x";
        case gamepad_y:
            return "y";
        default:
            return "unknown";
        };
    }
#endif //DEBUG

     void lock_mod_settings() {
         external_lock = std::unique_lock<std::mutex>(libary_function_mutex);
     }

     void unlock_mod_settings() {
         if (external_lock.owns_lock())
            external_lock.unlock();
     }

    ModDataArray *get_mod_settings() {
        initialize_manager();

#if defined(DEBUG) || defined(_DEBUG)
        debug_write("in get_mod_settings()\n");

        for (gamepad_btn_t btn = gamepad_d_up; btn < GAMEPAD_BTN_NUM; btn = (gamepad_btn_t)((int)btn + 1)) {
            if (is_gamepad_btn_pressed(btn))
                debug_write("btn [%s] pressed\n", btn_2_str(btn));
        }
#endif //DEBUG

        return const_cast<ModDataArray *>(&mod_data_arr);
    }

    __declspec(dllexport) bool gamepad_btn_pressed(gamepad_btn_t btn) {
        return is_gamepad_btn_pressed(btn);
    }

    __declspec(dllexport) void open_player_profile(const char *hex_id) {
        std::unique_lock<std::mutex> lock(libary_function_mutex);

        debug_write("in open_player_profile()\n");

        std::string user_id_str = hex_id;
        char *end;
        long long unsigned user_id = strtoull(user_id_str.data(), &end, 16);

        if (end < user_id_str.data() + user_id_str.length()) {
            debug_write("    failed to parse user id [%s]\n", user_id_str.c_str());
            return;
        }

        static HMODULE hSteamDLL = 0;
        if (!hSteamDLL) {
            hSteamDLL = GetModuleHandle(L"steam_api.dll");
            debug_write("    hSteamDLL :: 0x%016x\n", (long long)hSteamDLL);
        }

        static steam_friends_t steam_fiends = NULL;
        if (!steam_fiends) {
            steam_fiends = (steam_friends_t)GetProcAddress(hSteamDLL, "SteamFriends");
            debug_write("    steam_fiends :: 0x%016x\n", (long long)steam_fiends);
        }

        (*steam_fiends)()->ActivateGameOverlayToUser("steamid", CSteamID(user_id));
    }
}

BOOL APIENTRY DllMain( HMODULE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
                     )
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
    case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}

