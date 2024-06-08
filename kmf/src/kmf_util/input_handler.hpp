#ifndef KMF_INPUT_HANDLER
#define KMF_INPUT_HANDLER

#include <sdl_gamepad_state.hpp>

#include <filesystem>

bool is_gamepad_btn_pressed(gamepad_btn_t btn);
void init_gamepad_listener(std::filesystem::path *path);
void stop_gamepad_listener();

#endif //KMF_INPUT_HANDLER