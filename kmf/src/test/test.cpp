#include <stdio.h>
#include <windows.h>
#include <kmf_util.hpp>

#include <map>
#include <thread>

char *__cdecl (*try_get_request)(char *url);

static void attacher_request_test() {
    HINSTANCE hGetProcIDDLL = LoadLibrary(".\\attacher.dll");
}

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

void run_test() {
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

    //display_settings_menu();

    lock_mod_settings();
    mod_data_array = get_mod_settings();
    print_mod_data_array(mod_data_array);
    unlock_mod_settings();

    if (try_init_keyboard_watcher())
        printf("try_init_keyboard_watcher() :: success\n");
    else
        printf("try_init_keyboard_watcher() :: failure\n");

    const char *example_mapping = "stop_move:lEft ctrl;lightning:a;arCane:s;earth:w;fire:f;asdaSdasd;water:q;life:d;shield:e;cold:r;activate_uP:;;pause:Esc;";
    set_kbd_mapping(example_mapping);
    const auto &mapping = get_kbd_mapping();

    printf("mapping length :: %zu\n", mapping.size());

    for (const auto &map : mapping) {
        const char *kf_name = get_key_function_name(map.first);
        const char *key_name = get_key_name(map.second);

        printf("%s :: %s\n", key_name ? key_name : "(null)", kf_name ? kf_name : "(null)");
    }

}

HWND hwnd;

LRESULT CALLBACK WndProc(HWND hwnd, UINT Msg, WPARAM wParam, LPARAM lParam) {
    switch(Msg) {
        case WM_DESTROY:
            std::terminate();
            break;
        case WM_PAINT: {
            PAINTSTRUCT ps;
            HDC         hdc;
            RECT        rc;
    
            hdc = BeginPaint(hwnd, &ps);

            GetClientRect(hwnd, &rc);
            SetTextColor(hdc, 0);
            SetBkMode(hdc, TRANSPARENT);
            DrawTextA(hdc, "test.exe running", -1, &rc, DT_CENTER|DT_SINGLELINE|DT_VCENTER);

            EndPaint(hwnd, &ps);
        } break;
        default:
            return DefWindowProc(hwnd, Msg, wParam, lParam);
    }

    return 0;
}

int wmain() {
    if (__argc > 1) {
        gen_random_numbers();
        std::terminate();
    }

    const wchar_t CLASS_NAME[]  = L"test_class";

    WNDCLASS wc = { };

    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = NULL;
    wc.lpszClassName = CLASS_NAME;

    RegisterClass(&wc);

    // Create the window.

    HWND hwnd = CreateWindowEx(
        0,
        CLASS_NAME,
        L"test.exe",
        WS_OVERLAPPEDWINDOW,
        200, 200, 200, 200,
        NULL,
        NULL,
        NULL,
        NULL
    );

    if (hwnd == NULL) {
        return 1;
    }

    ShowWindow(hwnd, SW_SHOW);
    UpdateWindow(hwnd);

    run_test();

    MSG Msg;
    uint64_t counter = 0;


    while(true) {
        if (PeekMessage(&Msg, NULL, 0, 0, PM_REMOVE)) {
            TranslateMessage(&Msg);
            DispatchMessage(&Msg);
        }
        
        if (counter % 10 == 0) {
            if (gamepad_btn_pressed(gamepad_x))
                printf("gamepad button x is pressed\n");
        }

        if (counter % 100 == 0) {
            std::string elems = "asf\0";

            printf("ordering elements [%s]\n", elems.data());
            order_inputs_by_time(elems.data());
            printf("press order       [%s]\n", elems.data());
        }

        Sleep(10);
        counter++;
    }

    return 0;
}
