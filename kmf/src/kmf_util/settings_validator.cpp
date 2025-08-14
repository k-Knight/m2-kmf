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
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "mouse_forward", "mouse_backward"
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

static const char *full_focus_on_magic_desc = ""
"#Functionality\n"
"Will refill the targeted player's focus fully\n"
"when any magick is used.\n"
"#Settings\n"
"Sets the player target type to pick out players\n"
"that will benefit from this functionality.\n"
;
static const char *enable_lok_element_desc = ""
"#Functionality\n"
"Enables the player to conjure Lok's element\n"
"when the player input's elements that normally\n"
"would cancel out.\n"
"#Examples\n"
"  - shield + shield = lok element\n"
"  - fire + frost = lok element\n"
"#Settings\n"
"Sets the key a player must hold while conjuring\n"
"elements.\n"
"If player is holding down the button and\n"
"conjures conflicting elements, they will instead\n"
"combine into a Lok's element.\n"
"If player is NOT holding the button, then\n"
"conflicting elements cancel out as normal.\n"
;
static const char *suspend_element_logic_desc = ""
"#Functionality\n"
"Enables the player to stop element combination\n"
"and cancellation logic when holding a button.\n"
"#Examples\n"
"  - fire + frost do not cancel out\n"
"  - water + frost do not combine\n"
"#Settings\n"
"Sets the key a player must hold while conjuring\n"
"elements.\n"
"If player is holding down the button conjured\n"
"elements will not combine or cancel out.\n"
"If player is NOT holding the button, then\n"
"the elements combine or cancel out as normal.\n"
;
static const char *toggle_element_opposites_desc = ""
"#Functionality\n"
"Enables the player to stop conjured elements\n"
"from cancelling out as it normally would happen.\n"
"#Examples\n"
"  - fire + frost do not cancel out\n"
"  - life + arcane do not cancel out\n"
"#Settings\n"
"Sets the key combination that the player must\n"
"hit to turn the functionality on or off.\n"
;
static const char *no_magic_conjure_cooldown_desc = ""
"#Functionality\n"
"When enabled removes the 3 seconds cooldown that\n"
"is present when casting magicks by manual input.\n"
;
static const char *rock_demon_desc = ""
"#Functionality\n"
"When enabled the non-elemental rock spells that\n"
"the player casts will result in rocks that fly\n"
"around at maximum speed (without requiring\n"
"charging-up) and bounce off obstacles without\n"
"being destroyed significant number of times.\n"
;
static const char *icy_rock_desc = ""
"#Functionality\n"
"When enabled the combination of rock + ice\n"
"elements will no longer result in a ice shard\n"
"shotgun spell, but will instead launch a large\n"
"ice shard with significant damage that is also\n"
"network-guided on all clients.\n"
"#Notes\n"
"All elements that are not rock or ice do not\n"
"do anything and resulting aoe does not deal\n"
"any damage.\n"
;
static const char *always_max_rotation_speed_desc = ""
"#Functionality\n"
"When enabled the player character will always\n"
"have maximum rotation speed that will not be\n"
"slowed down by shooting spells or any status\n"
"effects that player character has.\n"
;
static const char *self_respawn_desc = ""
"#Functionality\n"
"Enables the player to press the configured\n"
"hotkey to resurrect his own player character\n"
"or reset it when pressing the button while\n"
"character is alive.\n"
"#Examples\n"
"  - Hotkey is pressed when character is dead:\n"
"      character gets resurrected as if the\n"
"      resurrection magick was used.\n"
"  - Hotkey is pressed when character is alive:\n"
"      character gets deleted from the game, then\n"
"      new character is created anew for the\n"
"      current player.\n"
"#Notes\n"
"Pressing the hotkey while character is alive can\n"
"be used to change equipment in-game.\n"
"#Settings\n"
"Sets the key combination that serves as a hotkey\n"
"for this modification.\n"
;
static const char *anti_kick_desc = ""
"#Functionality\n"
"When enabled the host and other players cannot\n"
"kick the player out of the lobby by regular\n"
"means.\n"
"Notifications will be sent in the chat box if\n"
"someone tried to kick the player.\n"
"#Notes\n"
"Turbo-kick functionality can still be used to\n"
"kick the player out.\n"
;
static const char *change_equipment_in_game_desc = ""
"#Functionality\n"
"When enabled additional button that is called \n"
"\"Equipment\" will be added in the player menu\n"
"for local player while in-game.\n"
"The button has the same function as the button\n"
"with the similar name in the main menu.\n"
"#Notes\n"
"In-game button \"Reset Player\" can be used to\n"
"apply the equipment changes to the player.\n"
"Also, \"self respaw\" mod can be used to apply\n"
"the equipment changes.\n"
;
static const char *become_spectator_button_desc = ""
"#Functionality\n"
"When enabled additional button that is called \n"
"\"Become Spectator\" will be added in the player\n"
"menu for local player while in-game.\n"
"The button removed the player character from the\n"
"game while leaving the player connected to the\n"
"lobby allowing for spectating.\n"
"#Notes\n"
"In-game button \"Reset Player\" can be used to\n"
"return back from the spectator mode.\n"
"Also, \"self respaw\" mod can be used to return\n"
"back from the spectator mode.\n"
;
static const char *self_invulnerable_desc = ""
"#Functionality\n"
"Enables the player to press the configured\n"
"hotkey to stop/start receiving damage (apart\n"
"from some kill-zones).\n"
"This turns the player almost fully invulnerable.\n"
"#Settings\n"
"Sets the key combination that serves as a hotkey\n"
"for this modification.\n"
;
static const char *force_camera_on_player_desc = ""
"#Functionality\n"
"Enables the player to press the configured\n"
"hotkey to toggle whether the camera is strictly\n"
"bound to the player or not.\n"
"This allows to explore some unreachable regions\n"
"in different levels of the game and prevents\n"
"the player from dying when going outside of the\n"
"camera view.\n"
"#Settings\n"
"Sets the key combination that serves as a hotkey\n"
"for this modification.\n"
;
static const char *necromancer_master_host_desc = ""
"#Functionality\n"
"When enabled every summon skeleton magick cast\n"
"will spawn 100 skeletons if the player is host.\n"
"#Notes\n"
"This modification does not work if the player\n"
"is not the host of the lobby.\n"
;
static const char *name_changer_desc = ""
"#Functionality\n"
"When enabled changes the name of the player and \n"
"player's profile.\n"
"Other peers will also see the changes.\n"
"#Notes\n"
"Do not use it to be an ass, please.\n"
;
static const char *optional_bug_fixes_desc = ""
"#Functionality\n"
"When enabled changes the game's logic to fix\n"
"a lot of different bugs and exploits.\n"
"#Notes\n"
"Does not affect how other players see the game\n"
"function, unless they have enabled this as well.\n"
;
static const char *balance_fun_provements_desc = ""
"#Functionality\n"
"When enabled changes the game's logic, this is \n"
"visible only to players who have this\n"
"modification enabled as well.\n"
"This modification rebalances a few aspects of\n"
"the game and reimagines some spells to make the\n"
"game more fun.\n"
"The balancing of this modification is mostly\n"
"centered around PvP.\n"
"#Changes\n"
"  - elemental rocks now fly in trajectory like\n"
"    mortar shells\n"
"  - ice shards have some homing added to them,\n"
"    except for ice shotgun spell\n"
"  - simple shield has reduced HP and is now\n"
"    somewhat network-synchronized\n"
"  - elemental wards were significantly buffed\n"
"  - beams now have some aim-assist to them\n"
;
static const char *remove_magick_hud_desc = ""
"#Functionality\n"
"When enabled removes the player's magick hotbar.\n"
"This disabled it for all players, but only\n"
"visible for players who have this modification\n"
"enabled.\n"
"This makes it impossible to cast magicks without\n"
"manual input.\n"
;
static const char *movement_convenience_desc = ""
"#Functionality\n"
"Enables the player to press the configured\n"
"hotkey that the player must hold to stop\n"
"own character's rotation and only set the\n"
"movement direction.\n"
"The mouse is bound in a small circle of the\n"
"original position when the hotkey was pressed\n"
"and moving the mouse in that circle sets the\n"
"character's movement direction.\n"
"#Settings\n"
"Sets the key combination that serves as a hotkey\n"
"for this modification.\n"
;


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

const char *get_mod_description(const std::string *mod) {
    if (*mod == "full focus on magic")
        return full_focus_on_magic_desc;
    if (*mod == "enable lok element")
        return enable_lok_element_desc;
    if (*mod == "suspend element logic")
        return suspend_element_logic_desc;
    if (*mod == "toggle element opposites")
        return toggle_element_opposites_desc;
    if (*mod == "no magic conjure cooldown")
        return no_magic_conjure_cooldown_desc;
    if (*mod == "rock demon")
        return rock_demon_desc;
    if (*mod == "icy rock")
        return icy_rock_desc;
    if (*mod == "always max rotation speed")
        return always_max_rotation_speed_desc;
    if (*mod == "self respawn")
        return self_respawn_desc;
    if (*mod == "anti-kick")
        return anti_kick_desc;
    if (*mod == "change equipment in-game")
        return change_equipment_in_game_desc;
    if (*mod == "become spectator button")
        return become_spectator_button_desc;
    if (*mod == "self invulnerable")
        return self_invulnerable_desc;
    if (*mod == "force camera on player")
        return force_camera_on_player_desc;
    if (*mod == "necromancer master - host")
        return necromancer_master_host_desc;
    if (*mod == "name changer")
        return name_changer_desc;
    if (*mod == "optional bug fixes")
        return optional_bug_fixes_desc;
    if (*mod == "balance fun-provements")
        return balance_fun_provements_desc;
    if (*mod == "remove magick hud")
        return remove_magick_hud_desc;
    if (*mod == "movement convenience")
        return movement_convenience_desc;

    return NULL;
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