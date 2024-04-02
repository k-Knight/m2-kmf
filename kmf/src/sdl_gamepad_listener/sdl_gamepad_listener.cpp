#include <windows.h>
#include <tlhelp32.h>

#include <SDL.h>
#include <SDL_syswm.h>

#include <string>
#include <vector>
#include <map>
#include <chrono>
#include <thread>

#include <sdl_gamepad_state.hpp>

SDL_GameController *controller = NULL;
std::chrono::high_resolution_clock::time_point reinit_time;
HANDLE magicka_proc = 0;

const std::map<gamepad_btn_t, SDL_GameControllerButton> btn_2_sdl_btn = {
    {gamepad_d_up, SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_DPAD_UP},
    {gamepad_d_down, SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_DPAD_DOWN},
    {gamepad_d_left, SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_DPAD_LEFT},
    {gamepad_d_right, SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_DPAD_RIGHT},
    {gamepad_start, SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_START},
    {gamepad_back, SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_BACK},
    {gamepad_left_thumb, SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_LEFTSTICK},
    {gamepad_right_thumb, SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_RIGHTSTICK},
    {gamepad_left_shoulder, SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_LEFTSHOULDER},
    {gamepad_right_shoulder, SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_RIGHTSHOULDER},
    {gamepad_a, SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_A},
    {gamepad_b, SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_B},
    {gamepad_x, SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_X},
    {gamepad_y, SDL_GameControllerButton::SDL_CONTROLLER_BUTTON_Y}
};

const std::map<gamepad_btn_t, SDL_GameControllerAxis> btn_2_sdl_axis = {
    {gamepad_left_trigger, SDL_GameControllerAxis::SDL_CONTROLLER_AXIS_TRIGGERLEFT},
    {gamepad_right_trigger, SDL_GameControllerAxis::SDL_CONTROLLER_AXIS_TRIGGERRIGHT}
};

const std::vector<gamepad_btn_t> axis_buttons = {
    gamepad_left_trigger,
    gamepad_right_trigger
};

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

static SDL_GameController *findController() {
    int num_joysticks = SDL_NumJoysticks();

    if (!num_joysticks) {
        auto cur_time = std::chrono::high_resolution_clock::now();
        auto time_left = std::chrono::duration_cast<std::chrono::milliseconds>(cur_time - reinit_time);

        if (time_left.count() > 0) {
            SDL_QuitSubSystem(SDL_INIT_GAMECONTROLLER);
            SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER);
            reinit_time = std::chrono::high_resolution_clock::now() + std::chrono::seconds(10);
        }
    }

    for (int i = 0; i < num_joysticks; i++) {
        if (SDL_IsGameController(i)) {
            return SDL_GameControllerOpen(i);
        }
    }

    return nullptr;
}

static inline SDL_JoystickID getControllerInstanceID(SDL_GameController *controller) {
    return SDL_JoystickInstanceID( SDL_GameControllerGetJoystick(controller));
}

static bool check_gamepad_btn_down(gamepad_btn_t btn) {
    if ((btn < 0 && btn >= GAMEPAD_BTN_NUM) || !controller)
        return false;

    if (std::find(axis_buttons.begin(), axis_buttons.end(), btn) != axis_buttons.end()) {
        return fabs((float)SDL_GameControllerGetAxis(controller, btn_2_sdl_axis.at(btn)) / (float)INT16_MAX) > 0.05;
    }

    if (btn >= 0 && btn < GAMEPAD_BTN_NUM)
        return SDL_GameControllerGetButton(controller, btn_2_sdl_btn.at(btn));

    return false;
}

static void update_gamepad_btn_status(bool *gamepad_btn_status) {
    if (!gamepad_btn_status)
        return;

    for (int i = static_cast<int>(gamepad_d_up); i < GAMEPAD_BTN_NUM; i++) {
        gamepad_btn_t btn = static_cast<gamepad_btn_t>(i);

        gamepad_btn_status[btn] = check_gamepad_btn_down(btn);
    }
}

HANDLE get_process_by_name(const std::wstring &name)
{
    DWORD pid = 0;
    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    PROCESSENTRY32W process;

    ZeroMemory(&process, sizeof(process));
    process.dwSize = sizeof(process);

    if (Process32FirstW(snapshot, &process)) {
        do {
            if (name.find(process.szExeFile) != std::string::npos) {
                pid = process.th32ProcessID;
                break;
            }
        } while (Process32NextW(snapshot, &process));
    }

    CloseHandle(snapshot);

    if (pid != 0)
        return OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);

    return NULL;
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PWSTR pCmdLine, int nCmdShow) {
    magicka_proc = get_process_by_name(L"Magicka2.exe");

    // Shared memory init

    HANDLE hMapFile = NULL;
    bool *gamepad_btn_status = NULL;

    hMapFile = OpenFileMappingW(
        FILE_MAP_ALL_ACCESS, // read/write access
        FALSE,               // do not inherit the name
        shared_mem_name      // name of mapping object
    );

    gamepad_btn_status = (bool *)MapViewOfFile(
        hMapFile,            // handle to map object
        FILE_MAP_ALL_ACCESS, // read/write permission
        0,
        0,
        sizeof(bool) * GAMEPAD_BTN_NUM
    );

    if (hMapFile == NULL)
        return 1;

    if (gamepad_btn_status == NULL) {
        CloseHandle(hMapFile);
    
        return 2;
    }

    // SDL init

sdl_init:
    SDL_Event event;
    SDL_Window *window;
    SDL_SysWMinfo wmInfo;
    HWND hwnd;
    bool quit = false;

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        if (hMapFile)
            CloseHandle(hMapFile);

        return 3;
    }

    if (SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER) < 0) {
        if (hMapFile)
            CloseHandle(hMapFile);

        return 4;
    }

    window = SDL_CreateWindow("", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 1, 1, SDL_WINDOW_HIDDEN);
    
    SDL_VERSION(&wmInfo.version);
    SDL_GetWindowWMInfo(window, &wmInfo);
    hwnd = wmInfo.info.win.window;

    LONG_PTR wndStyle = GetWindowLongPtrA(hwnd, GWL_STYLE);
    wndStyle &= ~(WS_CAPTION | WS_SIZEBOX);
    SetWindowLongPtrA(hwnd, GWL_STYLE, wndStyle);
    MoveWindow(hwnd, -100, -100, 1, 1, true);

    if (window == nullptr) {
        if (hMapFile)
            CloseHandle(hMapFile);

        return 5;
    }

    SDL_GameControllerEventState(SDL_ENABLE);
    SDL_JoystickUpdate();
    SDL_GameControllerUpdate();
    
    SDL_StopTextInput();
    SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");

    while (!quit) {
        auto update_due_time = std::chrono::high_resolution_clock::now() + std::chrono::milliseconds(10);

        while (SDL_PollEvent(&event) != 0) {
            switch (event.type) {
            case SDL_QUIT:
                quit = true;
                break;
            case SDL_CONTROLLERDEVICEADDED:
                if (!controller)
                    controller = SDL_GameControllerOpen(event.cdevice.which);
                break;
            case SDL_CONTROLLERDEVICEREMOVED:
                if (controller && event.cdevice.which == getControllerInstanceID(controller))
                    SDL_GameControllerClose(controller);
                break;
            }
        }

        SDL_JoystickUpdate();
        SDL_GameControllerUpdate();

        if (!controller)
            controller = findController();

        update_gamepad_btn_status(gamepad_btn_status);

        if (!magicka_proc || !(WaitForSingleObject(magicka_proc, 1) == WAIT_TIMEOUT))
            quit = true;

        auto end = std::chrono::high_resolution_clock::now();
        auto time_left = std::chrono::duration_cast<std::chrono::milliseconds>(update_due_time - end);

        if (time_left.count() > 1)
            std::this_thread::sleep_for(time_left);
    }

    if (hMapFile)
        CloseHandle(hMapFile);

    SDL_Quit();

    return 0;
}
