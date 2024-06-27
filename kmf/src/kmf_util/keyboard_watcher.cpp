#include <windows.h>

#include <chrono>
#include <thread>
#include <map>
#include <string>

#include <ctype.h>

#include "kmf_util.hpp"

using hr_clock = std::chrono::high_resolution_clock;

const std::map<std::string, key_function_t> str2kf_map = {
    {"water", key_function_t::water},
    {"life", key_function_t::life},
    {"shield", key_function_t::shield},
    {"cold", key_function_t::cold},
    {"lightning", key_function_t::lightning},
    {"arcane", key_function_t::arcane},
    {"earth", key_function_t::earth},
    {"fire", key_function_t::fire},
    {"magick_tier1", key_function_t::magick_tier1},
    {"magick_tier2", key_function_t::magick_tier2},
    {"magick_tier3", key_function_t::magick_tier3},
    {"magick_tier4", key_function_t::magick_tier4},
};
const std::map<std::string, uint8_t> str2vk = {
    {"left",        VK_LBUTTON},
    {"right",       VK_RBUTTON},
    {"middle",      VK_MBUTTON},
    {"space",       VK_SPACE},
    {"0",           0x30},
    {"1",           0x31},
    {"2",           0x32},
    {"3",           0x33},
    {"4",           0x34},
    {"5",           0x35},
    {"6",           0x36},
    {"7",           0x37},
    {"8",           0x38},
    {"9",           0x39},
    {"a",           0x41},
    {"b",           0x42},
    {"c",           0x43},
    {"d",           0x44},
    {"e",           0x45},
    {"f",           0x46},
    {"g",           0x47},
    {"h",           0x48},
    {"i",           0x49},
    {"j",           0x4a},
    {"k",           0x4b},
    {"l",           0x4c},
    {"m",           0x4d},
    {"n",           0x4e},
    {"o",           0x4f},
    {"p",           0x50},
    {"q",           0x51},
    {"r",           0x52},
    {"s",           0x53},
    {"t",           0x54},
    {"u",           0x55},
    {"v",           0x56},
    {"w",           0x57},
    {"x",           0x58},
    {"y",           0x59},
    {"z",           0x5a},
    {"oem_3 (~ `)", VK_OEM_3},
    {"caps lock",   VK_CAPITAL},
    {"left shift",  VK_LSHIFT},
    {"right shift", VK_RSHIFT},
    {"left ctrl",   VK_LCONTROL},
    {"right ctrl",  VK_RCONTROL},
    {"left alt",    VK_LMENU},
    {"right alt",   VK_RMENU},
    {"end",         VK_END},
    {"home",        VK_HOME},
    {"page up",     VK_PRIOR},
    {"page down",   VK_NEXT},
    {"esc",         VK_ESCAPE},
    {"f1",          VK_F1},
    {"f2",          VK_F2},
    {"f3",          VK_F3},
    {"f4",          VK_F4},
    {"f5",          VK_F5},
    {"f6",          VK_F6},
    {"f7",          VK_F7},
    {"f8",          VK_F8},
    {"f9",          VK_F9},
    {"f10",         VK_F10},
    {"f11",         VK_F11},
    {"f12",         VK_F12},
    {"up",          VK_UP},
    {"left",        VK_LEFT},
    {"extra_1",     VK_XBUTTON1},
    {"extra_2",     VK_XBUTTON2},
};
const std::map<char, uint8_t> sym2kf = {
    {'q', (uint8_t)key_function_t::water},
    {'w', (uint8_t)key_function_t::life},
    {'e', (uint8_t)key_function_t::shield},
    {'r', (uint8_t)key_function_t::cold},
    {'a', (uint8_t)key_function_t::lightning},
    {'s', (uint8_t)key_function_t::arcane},
    {'d', (uint8_t)key_function_t::earth},
    {'f', (uint8_t)key_function_t::fire},
    {'1', (uint8_t)key_function_t::magick_tier1},
    {'2', (uint8_t)key_function_t::magick_tier2},
    {'3', (uint8_t)key_function_t::magick_tier3},
    {'4', (uint8_t)key_function_t::magick_tier4},
};
const std::map<char, uint8_t> kf2sym = {
    {(uint8_t)key_function_t::water, 'q'},
    {(uint8_t)key_function_t::life, 'w'},
    {(uint8_t)key_function_t::shield, 'e'},
    {(uint8_t)key_function_t::cold, 'r'},
    {(uint8_t)key_function_t::lightning, 'a'},
    {(uint8_t)key_function_t::arcane, 's'},
    {(uint8_t)key_function_t::earth, 'd'},
    {(uint8_t)key_function_t::fire, 'f'},
    {(uint8_t)key_function_t::magick_tier1, '1'},
    {(uint8_t)key_function_t::magick_tier2, '2'},
    {(uint8_t)key_function_t::magick_tier3, '3'},
    {(uint8_t)key_function_t::magick_tier4, '4'},
};

HHOOK kbd_hook;
hr_clock::time_point origin;
volatile uint64_t last_presses[0xff] = { 0 };
std::map<key_function_t, uint8_t> kbd_map;
std::map<uint8_t, key_function_t> kbd_map_rev;

static LRESULT CALLBACK KbdHookEvent(int nCode, WPARAM wParam, LPARAM lParam) {
    if(nCode == HC_ACTION && ((DWORD)lParam & 0x80000000) == 0) {
        last_presses[wParam & 0xff] = (std::chrono::duration_cast<std::chrono::microseconds>(hr_clock::now() - origin)).count();
#if defined(DEBUG) || defined(_DEBUG)
        debug_write("key press :: [0x%02x]\n", wParam & 0xff);
#endif //DEBUG
    }

    return CallNextHookEx(kbd_hook, nCode, wParam, lParam);
}

void set_kbd_mapping(const char *mapping) {
    static const std::string &map_delim = ";";
    static const size_t map_delim_len = map_delim.length();

    static const auto &parse_key = [](const std::string &token) {
        static const std::string &key_delim = ":";
        static const size_t key_delim_len = key_delim.length();

        debug_write("  processing token :: [%s]\n", token.c_str());

        std::string name;
        std::string key;
        size_t pos = 0;

        if ((pos = token.find(key_delim)) == std::string::npos)
            return;

        name = token.substr(0, pos);
        key = token.substr(pos + key_delim_len, token.length());

        if (name.length() > 0 && key.length() > 0 && str2kf_map.count(name.c_str()) && str2vk.count(key.c_str())) {
            uint8_t code = str2vk.at(key.c_str());
            key_function_t kf = str2kf_map.at(name.c_str());

            kbd_map[kf] = code;
            kbd_map_rev[code] = kf;
        }
    };

    std::string s = mapping;
    size_t pos = 0;
    std::string tk;

    debug_write("in set_kbd_mapping() ::\n    %s\n", s.c_str());

    std::transform(s.begin(), s.end(), s.begin(), tolower);
    kbd_map.clear();
    kbd_map_rev.clear();

    debug_write("to lower ::\n    %s\n", s.c_str());

    while ((pos = s.find(map_delim)) != std::string::npos) {
        tk = s.substr(0, pos);
        s.erase(0, pos + map_delim_len);

        if (tk.length() > 0)
            parse_key(tk);
    }

    if (s.length() > 0)
        parse_key(s);
}

const std::map<key_function_t, uint8_t> &get_kbd_mapping() {
    return kbd_map;
}

const char *get_key_function_name(const key_function_t &kf) {
    for(const auto &entry : str2kf_map) 
        if(entry.second == kf)
            return entry.first.c_str();

    return NULL;
}

const char *get_key_name(const uint8_t code) {
    for(const auto &entry : str2vk) 
        if(entry.second == code)
            return entry.first.c_str();

    return NULL;
}

static void my_insertion_sort(uint8_t *arr, int n) {
    int i, j;
    uint64_t key;
    uint8_t key_val;

    for (i = 1; i < n; i++) {
        key_val = arr[i];
        key = last_presses[key_val];
        j = i - 1;

        while (j >= 0 && last_presses[arr[j]] > key) {
            arr[j + 1] = arr[j];
            j = j - 1;
        }

        arr[j + 1] = key_val;
    }
}

void order_inputs_by_time(char *elem_str) {
    const size_t str_size = strlen(elem_str);

    if (str_size < 2) {
        debug_write("order_elements_by_time() :: only %zu elements to oder\n", str_size);
        return;
    }

    uint8_t *translated = new uint8_t[str_size];

    for (int i = 0; i < str_size; i++) {
        if (!sym2kf.count(elem_str[i])) {
            debug_write("illegal element symbol :: [%c]\n", elem_str[i]);
            return;
        }

        key_function_t kf = (key_function_t)sym2kf.at(elem_str[i]);

        if (!kbd_map.count(kf)) {
            debug_write("map does not contain this element :: [%u]\n", kf);
            return;
        }

        translated[i] = kbd_map[kf];
    }

    my_insertion_sort(translated, str_size);

    for (int i = 0; i < str_size; i++)
        elem_str[i] = kf2sym.at((uint8_t)kbd_map_rev.at(translated[i]));

    free(translated);
}

bool try_init_keyboard_watcher() {
    debug_write("in try_init_keyboard_watcher()\n");
    
    origin = hr_clock::now();

    HMODULE hMod = GetModuleHandleA(NULL);
    DWORD idThread = GetCurrentThreadId();

    if ((kbd_hook = SetWindowsHookExA(WH_KEYBOARD, KbdHookEvent, hMod, idThread)) == NULL) {
        debug_write("Failed to create keyboard hook: %lu\n", GetLastError());
        debug_write("    hMod     :: 0x%lx\n", (unsigned long)hMod);
        debug_write("    idThread :: 0x%lx\n", idThread);
        return false;
    }
    else {
        debug_write("successfully initialized keyboard hook\n");
        return true;
    }
}
