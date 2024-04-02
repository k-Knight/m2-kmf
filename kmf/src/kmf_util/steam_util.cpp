#include "kmf_util.hpp"

#include <windows.h>
#include <steam_api.h>
#include <mutex>

typedef decltype(&SteamFriends) steam_friends_t;
extern std::mutex libary_function_mutex;

extern "C" {
    void open_player_profile(const char *hex_id) {
        std::unique_lock<std::mutex> lock(libary_function_mutex);

        debug_write("in open_player_profile()\n");

        std::string user_id_str = hex_id;
        char *end;
        long long unsigned user_id = strtoull(user_id_str.data(), &end, 16);

        if (end < user_id_str.data() + user_id_str.length()) {
            debug_write("    failed to parse user id [%s]\n", user_id_str.c_str());
            return;
        }

        static HMODULE hSteamDLL = 0;
        if (!hSteamDLL) {
            hSteamDLL = GetModuleHandle(L"steam_api.dll");
            debug_write("    hSteamDLL :: 0x%016x\n", (long long)hSteamDLL);
        }

        static steam_friends_t steam_fiends = NULL;
        if (!steam_fiends) {
            steam_fiends = (steam_friends_t)GetProcAddress(hSteamDLL, "SteamFriends");
            debug_write("    steam_fiends :: 0x%016x\n", (long long)steam_fiends);
        }

        (*steam_fiends)()->ActivateGameOverlayToUser("steamid", CSteamID(user_id));
    }
}