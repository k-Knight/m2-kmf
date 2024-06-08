#ifndef KMF_UTIL
#define KMF_UTIL

#include <vector>
#include <unordered_map>
#include <filesystem>
#include <sdl_gamepad_state.hpp>

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

extern "C"
{
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
}

#endif //KMF_UTIL
