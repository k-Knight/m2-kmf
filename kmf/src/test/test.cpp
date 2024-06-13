#include <stdio.h>
#include <windows.h>
#include <kmf_util.hpp>

#include <map>

static void print_mod_data_array(ModDataArray *arr) {
    printf("mods config:\n");
    for (size_t i = 0; i < arr->length; i++) {
        ModData *data = &arr->data[i];
        printf("[%s]\n", data->mod_name);
        printf("status = %s\n", data->enabled ? "true" : "false");
        for (size_t j = 0; j < data->setting_length; j++) {
            ModSetting *setting = &data->setting_data[j];
            printf("%s = %s\n", setting->name, setting->value);
        }

        printf("\n");
    }
}

static void gen_random_numbers() {
    std::map<int, int> results;
    size_t gen_count = 100000;
    int min, max;

    results.clear();
    min = 0;
    max = 100;
    printf("testing generate_uniform_from_to() ::    min %u    max%u\n", min, max);
    for (size_t i = 0; i < gen_count; i++) {
        int val = generate_uniform_from_to(min, max);
        if (!results.count(val))
            results[val] = 1;
        else
            results[val]++;
    }

    for (const auto &val : results) {
        printf("    %u :: %0.3f\n", val.first, val.second / double(gen_count));
    }

    results.clear();
    min = 3;
    max = 9;
    printf("testing generate_my_random_from_to() ::    min %u    max%u\n", min, max);
    for (size_t i = 0; i < gen_count; i++) {
        int val = generate_my_random_from_to(min, max);
        if (!results.count(val))
            results[val] = 1;
        else
            results[val]++;
    }

    for (const auto &val : results) {
        printf("    %u :: %0.3f\n", val.first, val.second / double(gen_count));
    }

    results.clear();
    min = 1;
    max = 4;
    printf("testing generate_bernoulli() ::    p (%u / %u)\n", min, max);
    for (size_t i = 0; i < gen_count; i++) {
        int val = generate_bernoulli(min / double(max));
        if (!results.count(val ? 1 : 0))
            results[val ? 1 : 0] = 1;
        else
            results[val ? 1 : 0]++;
    }

    for (const auto &val : results) {
        printf("    %u :: %0.3f\n", val.first, val.second / double(gen_count));
    }
}

int main(int argc, char *argv[]) {
    if (argc > 1) {
        gen_random_numbers();
        return 1;
    }

    auto cur_path = std::filesystem::current_path();
    ModDataArray *mod_data_array;
    printf("%s\n", cur_path.generic_string().c_str());

    //Sleep(10 * 1000);

    //display_settings_menu();

    lock_mod_settings();
    mod_data_array = get_mod_settings();
    print_mod_data_array(mod_data_array);
    unlock_mod_settings();

    const char* mod_config_str = R"(
            [full focus on magic]
            target player=caster

            [enable lok element]
            keyboard hotkey=ctrl
            gamepad hotkey=R3

            [suspend element logic]
            keyboard hotkey=alt
            gamepad hotkey=L3

            [toggle element opposites]
            keyboard hotkey=ctrl + alt
            gamepad hotkey=L3 + R3

            [no magic conjure cooldown]

            [rock demon]

            [icy rock]

            [always max rotation speed]

            [self respawn]
            keyboard hotkey=F4
            gamepad hotkey=R3 + up

            [anti-kick]

            [change equipment in-game]

            [become spectator button]

            [self invulnerable]
            keyboard hotkey=F5
            gamepad hotkey=R3 + down

            [force camera on player]
            keyboard hotkey=F6
            gamepad hotkey=R3 + left

            [necromancer master - host]

            [name hider]
            wizard name=Wizard
            profile name=Anonymous Wizard
        )";

    printf("\n\nupdating mod config ...\n\n\n");
    update_config_file((char *)mod_config_str);

    display_settings_menu();

    lock_mod_settings();
    mod_data_array = get_mod_settings();
    print_mod_data_array(mod_data_array);
    unlock_mod_settings();

    //for (size_t i = 0; i < 300; i++) {
    //    if (gamepad_btn_pressed(gamepad_x))
    //        printf("gamepad button x is pressed\n");
    //    Sleep(100);
    //}
    return 0;
}
