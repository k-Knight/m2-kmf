#ifndef SDL_GAMEPAD_STATE
#define SDL_GAMEPAD_STATE

enum gamepad_btn_t {
	gamepad_d_up = 0,
	gamepad_d_down,
	gamepad_d_left,
	gamepad_d_right,
	gamepad_start,
	gamepad_back,
	gamepad_left_thumb,
	gamepad_right_thumb,
	gamepad_left_shoulder,
	gamepad_right_shoulder,
	gamepad_left_trigger,
	gamepad_right_trigger,
	gamepad_a,
	gamepad_b,
	gamepad_x,
	gamepad_y,
	GAMEPAD_BTN_NUM
};

const wchar_t shared_mem_name[] = L"Local\\kmf_gamepad_state";

#endif //SDL_GAMEPAD_STATE

