#include "kmf_util.hpp"

#include <string>
#include <vector>
#include <sstream>

static const std::vector<const char *> player_targets = {
    "caster", "everyone"
};
static const std::vector<const char *> keyboard_buttons = {
    "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12",
    "alt", "ctrl", "shift", "enter", "space", "insert", "delete", "backspace", "tab", "minus", "equal",
    "home", "end", "page up", "page down", "up", "down", "left", "right",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
};
static const std::vector<const char *> gamepad_buttons = {
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

static inline void tolower(std::string &s) {
    std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) {
        return std::tolower(c);
    });
}

static inline void ltrim(std::string &s) {
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](unsigned char ch) {
        return !std::isspace(ch);
    }));
}

static inline void rtrim(std::string &s) {
    s.erase(std::find_if(s.rbegin(), s.rend(), [](unsigned char ch) {
        return !std::isspace(ch);
    }).base(), s.end());
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