#ifndef KMF_UTIL
#define KMF_UTIL

#include <vector>
#include <unordered_map>
#include <map>
#include <filesystem>
#include <string>

#include <stdint.h>

#include <sdl_gamepad_state.hpp>

#include "debug_logger.hpp"

struct ModDataEntry {
    std::string name;
    bool status;
    std::unordered_map<std::string, std::string> settings;

    ModDataEntry() {
        status = false;
    }

    ModDataEntry(std::string &name, bool status, std::unordered_map<std::string, std::string> &settings) {
        this->name = std::string(name);
        this->status = status;
        this->settings = std::unordered_map<std::string, std::string>(settings);
    }

    ~ModDataEntry() {
        status = false;
        name.clear();
        settings.clear();
    }
};

enum class SettingType {
    unknown_setting_type = 0,
    keyboard_hotkey,
    gamepad_hotkey,
    player_target,
    wizard_name,
    profile_name
};

struct SettingPossibleValues {
    SettingType type;
    const std::vector<const char *> *values;
};

__declspec(dllexport) bool config_file_exists();
__declspec(dllexport) void setup_file_paths();
__declspec(dllexport) std::filesystem::path get_mod_config_path();
__declspec(dllexport) std::vector<ModDataEntry> *get_mod_config_entries();
__declspec(dllexport) void save_mod_settings();
__declspec(dllexport) void parse_string_mods_settings(const char* config_str, bool clear_unused = true);
__declspec(dllexport) void parse_file_mods_settings(bool clear_unused = true);

__declspec(dllexport) bool validate_value(const std::string *setting, const char *value);
__declspec(dllexport) const SettingPossibleValues *get_setting_possible_values(const std::string *setting);

enum class key_function_t {
    unknown = 0,
    water,
    life,
    shield,
    cold,
    lightning,
    arcane,
    earth,
    fire,
    magick_tier1,
    magick_tier2,
    magick_tier3,
    magick_tier4
};

__declspec(dllexport) const std::map<key_function_t, uint8_t> &get_kbd_mapping();
__declspec(dllexport) const char *get_key_function_name(const key_function_t &kf);
__declspec(dllexport) const char *get_key_name(const uint8_t code);

extern "C" {
    struct ModSetting {
        char *name;
        char *value;
    };

    struct ModData {
        char *mod_name;
        bool enabled;
        size_t setting_length;
        ModSetting *setting_data;
    };

    struct ModDataArray {
        ModData *data;
        size_t length;
    };

    __declspec(dllexport) void update_config_file(char* config_str);
    __declspec(dllexport) void lock_mod_settings();
    __declspec(dllexport) void unlock_mod_settings();
    __declspec(dllexport) ModDataArray *get_mod_settings();
    __declspec(dllexport) void display_settings_menu();

    __declspec(dllexport) bool gamepad_btn_pressed(gamepad_btn_t btn);
    __declspec(dllexport) void open_player_profile(const char *hex_id);

    __declspec(dllexport) float generate_radom_number();
    __declspec(dllexport) int generate_uniform_from_to(int min, int max);
    __declspec(dllexport) int generate_my_random_from_to(int min, int max);
    __declspec(dllexport) bool generate_bernoulli(float p);

    __declspec(dllexport) bool try_init_keyboard_watcher();
    __declspec(dllexport) void set_kbd_mapping(const char *mapping);
    __declspec(dllexport) void order_inputs_by_time(char *elem_str);
}

#endif //KMF_UTIL
