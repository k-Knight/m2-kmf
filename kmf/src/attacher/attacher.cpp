#include <cstddef>
#include <cstdlib>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <thread>
#include <mutex>
#include <queue>
#include <string>
#include <filesystem>
#include <fstream>

#include <windows.h>
#include <psapi.h>
#include <shlwapi.h>
#include <shellapi.h>

#include <detours.h>

using namespace std;

#define BUFSIZE 64 * 1024
#define NET_BUF_SIZE 1024 * 4
#ifndef min
#define min(a,b)    (((a) < (b)) ? (a) : (b))
#endif

extern "C" {
    /* public use */
    typedef void(__cdecl *trigger_cb_t)(void);

    __declspec(dllexport) int setup_IPC();
    __declspec(dllexport) void enable_stdout_logging();
    __declspec(dllexport) int register_global_dofile();
    __declspec(dllexport) int try_setup_lua_state_getter();
    __declspec(dllexport) void set_execute_callback(trigger_cb_t cb);
    __declspec(dllexport) void console_log(const char *message);
    __declspec(dllexport) void print(const char *message);
    __declspec(dllexport) char *try_get_request(const char *url);
    __declspec(dllexport) int try_download_installer(const char *url);
    __declspec(dllexport) void my_free(void *data);
    __declspec(dllexport) int check_exec_queue(char **ptr, unsigned int *size);

    static void write_stdout_to_file(string &&msg);
    static bool check_readable_string(const char *buf, size_t size);

    /* internal use */
    void reset_ipc(void);
    void console_output_thread(void);
    void execute_lua_thread(void);
    bool wait_for_pipes(void);

    volatile bool          exiting = false;
    volatile bool          restarting = false;
    volatile bool          stdout_thread_started = false;
    HANDLE                 console_pipe, execute_pipe;
    const char             *hello_msg = "Magicka 2 successfully attached with PID [%d]";
    LPWSTR                 console_pipe_name = (LPWSTR)L"\\\\.\\pipe\\m2_debug_console";
    LPWSTR                 execute_pipe_name = (LPWSTR)L"\\\\.\\pipe\\m2_debug_execute";
    trigger_cb_t           trigger_cb = NULL;
    queue<char *>          exec_queue;
    deque<string>          console_output;
    mutex                  ipc_mutex;
    mutex                  exec_mutex;
    mutex                  stdout_mutex;
    thread                 con_thread, exe_thread, stdout_thread;
    string                 stdout_file_path = "";
    queue<string>          stdout_messages;

    static BOOL WINAPI (*Orig_WriteConsoleW) (
        _In_ HANDLE hConsoleOutput,
        _In_reads_(nNumberOfCharsToWrite) CONST VOID *lpBuffer,
        _In_ DWORD nNumberOfCharsToWrite,
        _Out_opt_ LPDWORD lpNumberOfCharsWritten,
        _Reserved_ LPVOID lpReserved
    ) = WriteConsoleW;

    static BOOL WINAPI Hook_WriteConsoleW(
        _In_ HANDLE hConsoleOutput,
        _In_reads_(nNumberOfCharsToWrite) CONST VOID *lpBuffer,
        _In_ DWORD nNumberOfCharsToWrite,
        _Out_opt_ LPDWORD lpNumberOfCharsWritten,
        _Reserved_ LPVOID lpReserved
    ) {
        BOOL res = Orig_WriteConsoleW(hConsoleOutput, lpBuffer, nNumberOfCharsToWrite, lpNumberOfCharsWritten, lpReserved);

        printf("Hooked WriteConsoleW()\n");

        return res;
    }

    static BOOL WINAPI (*Orig_WriteFile) (
        _In_ HANDLE hFile,
        _In_reads_bytes_opt_(nNumberOfBytesToWrite) LPCVOID lpBuffer,
        _In_ DWORD nNumberOfBytesToWrite,
        _Out_opt_ LPDWORD lpNumberOfBytesWritten,
        _Inout_opt_ LPOVERLAPPED lpOverlapped
    ) = WriteFile;

    static BOOL WINAPI Hook_WriteFile(
        _In_ HANDLE hFile,
        _In_reads_bytes_opt_(nNumberOfBytesToWrite) LPCVOID lpBuffer,
        _In_ DWORD nNumberOfBytesToWrite,
        _Out_opt_ LPDWORD lpNumberOfBytesWritten,
        _Inout_opt_ LPOVERLAPPED lpOverlapped
    ) {
        BOOL res = Orig_WriteFile(hFile, lpBuffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, lpOverlapped);

        size_t max_non_read = nNumberOfBytesToWrite / 20;
        size_t bad_count = 0;
        for (size_t i = 0; i < nNumberOfBytesToWrite / 2 && bad_count < max_non_read; i++) {
            const char ch = ((char *)lpBuffer)[i];
            if (ch <= 0x20 || ch >= 0x7f)
                bad_count++;
        }

        if (check_readable_string((char *)lpBuffer, nNumberOfBytesToWrite))
            write_stdout_to_file(string((char *)lpBuffer, nNumberOfBytesToWrite));
        else {
            string conversion;
            conversion.resize(nNumberOfBytesToWrite);
            size_t ret = wcstombs(conversion.data(), (wchar_t *)lpBuffer, nNumberOfBytesToWrite / 2);
            conversion.resize(ret + 1);

            if (check_readable_string(conversion.data(), conversion.length()))
                write_stdout_to_file(string(conversion));
        }

        return res;
    }

    static bool check_readable_string(const char *buf, size_t size) {
        size_t max_non_read = size / 20;
        size_t bad_count = 0;

        for (size_t i = 0; i < size / 2 && bad_count <= max_non_read; i++) {
            const char ch = buf[i];

            if (ch == '\0')
                return false;

            if ((ch <= 0x20 || ch >= 0x7f) && ch != '\r' && ch != '\n')
                bad_count++;
        }

        return bad_count < max_non_read;
    }

    static void initialize_stdout_writer() {
        string thisPath = "";
        CHAR path[MAX_PATH];
        HMODULE hm;
        if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT, (LPSTR)&path, &hm)) {
            GetModuleFileNameA(hm, path, MAX_PATH);

            PathRemoveFileSpecA(path);
            thisPath = path;
            if (!thisPath.empty() && thisPath.back() != '\\')
                thisPath += "\\";
        }
        else {
            char tuh[2048];
            GetCurrentDirectoryA(sizeof(tuh), tuh);
            thisPath = tuh;
            thisPath += "\\";
        }

        SYSTEMTIME st;
        GetSystemTime(&st);

        char buf[1024];
        sprintf(buf,"kmf-logs/stdout-%04d-%02d-%02d-%02d-%02d-%02d.txt",
            st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond
        );
        stdout_file_path = thisPath + buf;

        string logs_dir_path = thisPath + "kmf-logs";
        if (!CreateDirectoryA(logs_dir_path.c_str(), NULL) &&
            ERROR_ALREADY_EXISTS != GetLastError()
        )
            printf("failed to create kmf-logs directory !!!\n");

        if (DetourIsHelperProcess()) {
            printf("process is a helper process, unable to detour !!!\n");
        }
        else {
            DetourRestoreAfterWith();
            DetourTransactionBegin();
            DetourUpdateThread(GetCurrentThread());
            DetourAttach(&(PVOID &)Orig_WriteConsoleW, Hook_WriteConsoleW);
            DetourAttach(&(PVOID &)Orig_WriteFile, Hook_WriteFile);
            DetourTransactionCommit();
        }
    }

    __declspec(dllexport) void enable_stdout_logging() {
        unique_lock<mutex> lock(stdout_mutex);
        initialize_stdout_writer();
    }

    static int __cdecl (*_orig_lua_gettop)(void *state) = nullptr;
    static int __cdecl (*luaL_loadfile)(void *state, const char *file_name) = nullptr;
    static int __cdecl (*lua_pcall)(void *state, int nargs, int nresults, int errfunc) = nullptr;
    static const char * __cdecl (*luaL_checklstring)(void *state, int narg, size_t *l) = nullptr;
    static void  __cdecl (*lua_pushcclosure)(void *state, void *c_fn, int n) = nullptr;
    static void __cdecl (*lua_pushstring)(void *state, const char *s) = nullptr;
    static void __cdecl (*lua_rawset)(void *state, int index) = nullptr;
    static void __cdecl (*lua_settop)(void *state, int index) = nullptr;
    static void __cdecl (*lua_pushvalue)(void *state, int index) = nullptr;
    static const char * __cdecl (*lua_tolstring)(void *state, int index, size_t *len) = nullptr;
    static int __cdecl (*lua_isstring)(void *state, int index) = nullptr;
    static int __cdecl (*luaL_loadbufferx)(void *state, const char *buff, size_t sz, const char *name, const char *mode) = nullptr;
    static int __cdecl (*luaL_error)(void *state, const char *fmt, ...) = nullptr;

    struct function_byte_signature_t {
        const char *name;
        void **fun_ptr_ptr;
        const unsigned char *signature;
        const char *mask;
        bool fail_on_missing = false;
    };

    static const function_byte_signature_t m2_exe_lua_func_signatures[] = {
        {
            "lua_gettop",
            (void **)&_orig_lua_gettop,
            (unsigned char[]){0x8B, 0x4C, 0x24, 0x04, 0x8B, 0x41, 0x14, 0x2B, 0x41, 0x10, 0xC1, 0xF8, 0x03, 0xC3},
            "xxxxxxxxxxxxxx",
            true
        },
        {
            "luaL_loadfile",
            (void **)&luaL_loadfile,
            (unsigned char[]){0x6A, 0x00, 0xFF, 0x74, 0x24, 0x0C, 0xFF, 0x74, 0x24, 0x0C, 0xE8, 0x11, 0x00, 0x00, 0x00, 0x83, 0xC4, 0x0C, 0xC3},
            "xxxxxxxxxxxxxxxxxxx"
        },
        {
            "lua_pcall",
            (void **)&lua_pcall,
            (unsigned char[]){0x8B, 0x54, 0x24, 0x04, 0x8B, 0x4C, 0x24, 0x10, 0x53, 0x56, 0x8B, 0x72, 0x08, 0x8A, 0x9E, 0x81, 0x00, 0x00, 0x00, 0x80, 0xE3, 0xF0, 0x85, 0xC9},
            "xxxxxxxxxxxxxxxxxxxxxxxx",
            true
        },
        {
            "luaL_checklstring",
            (void **)&luaL_checklstring,
            (unsigned char[]){0x8B, 0x44, 0x24, 0x08, 0x85, 0xC0, 0x78, 0x5B, 0x53, 0x56, 0x8B, 0x74, 0x24, 0x0C, 0x57, 0x8B},
            "xxxxxxxxxxxxxxxx"
        },
        {
            "lua_pushcclosure",
            (void **)&lua_pushcclosure,
            (unsigned char[]){0x56, 0x8B, 0x74, 0x24, 0x08, 0x8B, 0x4E, 0x08, 0x8B, 0x41, 0x14, 0x3B, 0x41, 0x18, 0x72, 0x07, 0x8B, 0xCE, 0xE8, 0x29, 0x74, 0x00, 0x00, 0x8B, 0x46, 0x10, 0x8B, 0x40, 0xF8, 0x80, 0x78, 0x05},
            "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
            true
        },
        {
            "lua_pushstring",
            (void **)&lua_pushstring,
            (unsigned char[]){0x56, 0x8B, 0x74, 0x24, 0x08, 0x57, 0x8B, 0x7C, 0x24, 0x10, 0x85, 0xFF, 0x75, 0x0C, 0x8B, 0x46},
            "xxxxxxxxxxxxxxxx",
            true
        },
        {
            "lua_rawset",
            (void **)&lua_rawset,
            (unsigned char[]){0x53, 0x56, 0x8B, 0x74, 0x24, 0x0C, 0x57, 0xFF, 0x74, 0x24, 0x14, 0x56, 0xE8, 0x1F, 0xED, 0xFF},
            "xxxxxxxxxxxxxxxx",
            true
        },
        {
            "lua_settop",
            (void **)&lua_settop,
            (unsigned char[]){0x8B, 0x44, 0x24, 0x08, 0x85, 0xC0, 0x78, 0x5B, 0x53, 0x56, 0x8B, 0x74, 0x24, 0x0C, 0x57, 0x8B},
            "xxxxxxxxxxxxxxxx",
            true
        },
        {
            "lua_pushvalue",
            (void **)&lua_pushvalue,
            (unsigned char[]){0x56, 0x57, 0xFF, 0x74, 0x24, 0x10, 0x8B, 0x7C, 0x24, 0x10, 0x57, 0xE8, 0x70, 0xEE, 0xFF, 0xFF},
            "xxxxxxxxxxxxxxxx",
            true
        },
        {
            "lua_tolstring",
            (void **)&lua_tolstring,
            (unsigned char[]){0x56, 0x8B, 0x74, 0x24, 0x0C, 0x57, 0x8B, 0x7C, 0x24, 0x0C, 0x56, 0x57, 0xE8, 0x0F, 0xE6, 0xFF},
            "xxxxxxxxxxxxxxxx",
            true
        },
        {
            "lua_isstring",
            (void **)&lua_isstring,
            (unsigned char[]){0xFF, 0x74, 0x24, 0x08, 0xFF, 0x74, 0x24, 0x08, 0xE8, 0x13, 0xF4, 0xFF, 0xFF, 0x8B, 0x40, 0x04, 0x83, 0xC4, 0x08, 0x83, 0xF8, 0xFB, 0x74, 0x08},
            "xxxxxxxxxxxxxxxxxxxxxxxx",
            true
        },
        {
            "luaL_loadbufferx",
            (void **)&luaL_loadbufferx,
            (unsigned char[]){0x55, 0x8B, 0xEC, 0x83, 0xE4, 0xF8, 0x83, 0xEC, 0x78, 0x8B, 0x45, 0x0C, 0x89, 0x04, 0x24, 0x8B, 0x45, 0x10, 0x89, 0x44, 0x24, 0x04, 0x56, 0x8B},
            "xxxxxxxxxxxxxxxxxxxxxxxx",
            true
        },
        {
            "luaL_error",
            (void **)&luaL_error,
            (unsigned char[]){0x8D, 0x44, 0x24, 0x0C, 0x50, 0xFF, 0x74, 0x24, 0x0C, 0xFF, 0x74, 0x24, 0x0C, 0xE8, 0x9E, 0x6F, 0x00, 0x00, 0x83, 0xC4, 0x0C, 0x50, 0xFF, 0x74},
            "xxxxxxxxxxxxxxxxxxxxxxxx",
            true
        },
    };

    static void *lua_state = 0;
    static bool got_lua_state = false;
    static bool found_necessary_funcs = false;

    static void my_lua_pushglobaltable(void *L) {
#define LUA_GLOBALSINDEX (-10002)
        lua_pushvalue(L, LUA_GLOBALSINDEX);
#undef  LUA_GLOBALSINDEX
    }

    static void my_lua_pop(void *L, int narg) {
        return lua_settop(L, -(narg) -1);
    }

    #define KMF_DOFILE_UPVALUE "kmf_dofile"

    static int __cdecl my_lua_dofile(void *L) {
#define LUA_OK 0
        if (!found_necessary_funcs)
            return luaL_error(L, "missing necessary lua functions !!!\n");

        if (!got_lua_state)
            return luaL_error(L, "missing lua state !!!\n");

#define LUA_GLOBALSINDEX    (-10002)
#define lua_upvalueindex(i) (LUA_GLOBALSINDEX-(i))
        size_t upvalue_len = 0;

        if (!lua_isstring(L, lua_upvalueindex(1)))
            return luaL_error(L, "missing or incorrect type of upvalue #1 !!!\n");

        const char *upvalue = lua_tolstring(L, lua_upvalueindex(1), &upvalue_len);
        if ((sizeof(KMF_DOFILE_UPVALUE) + 1) < upvalue_len || strcmp(upvalue, KMF_DOFILE_UPVALUE))
            return luaL_error(L, "not a kmf_dofile() call !!!\n");
#undef lua_upvalueindex
#undef LUA_GLOBALSINDEX

        if (!lua_isstring(L, 1))
            return luaL_error(L, "missing or incorrect type of argument #1 :: filename!!!\n");

        size_t arg_len = 0;
        const char *filename = lua_tolstring(L, 1, &arg_len);

        if (arg_len > 2048)
            return luaL_error(L, "file path is too large :: %u !!!\n", arg_len);

        if (filename == nullptr)
            return luaL_error(L, "filename cannot be null !!!\n");


        filesystem::path file_path(filename);
        if (!filesystem::is_regular_file(file_path))
            return luaL_error(L, "not such file :: \"%s\" !!!\n", filename);

        ifstream file(file_path, ios::binary | ios::ate);
        if (!file.is_open())
            return luaL_error(L, "cannot open file :: \"%s\" !!!\n", filename);

        size_t f_size = file.tellg();
        file.seekg(0, ios::beg);

        vector<char> buffer(f_size);
        if (!file.read(buffer.data(), f_size))
            return luaL_error(L, "cannot read file :: \"%s\" !!!\n", filename);

        bool is_bytecode = (buffer.size() >= 3 && (*(uint32_t*)buffer.data() & 0x00FFFFFF) == 0x4A4C1B) || (memchr(buffer.data(), '\0', buffer.size()) != nullptr);
        int res = luaL_loadbufferx(L, buffer.data(), buffer.size(), filename, is_bytecode ? "b" : "t");

        if (res == LUA_OK) {
            if ((res = lua_pcall(L, 0, 0, 0)) != LUA_OK) {
                size_t err_sz = 0;
                const char *err_msg = lua_tolstring(L, -1, &err_sz);

                if(err_msg && err_sz > 0)
                    return luaL_error(L, "[runtime error] %s\n", err_msg);
            }
        } else {
            size_t err_sz = 0;
            const char *err_msg = lua_tolstring(L, -1, &err_sz);

            if(err_msg && err_sz > 0)
                return luaL_error(L, "[loading error] %s\n", err_msg);
        }

        return res;
#undef  LUA_OK
    }

    static int __cdecl _hook_lua_gettop(void *state) {
        lua_state = state;
        got_lua_state = true;

        static_assert(sizeof(int) == sizeof(void *), "size of void * is not equal to into on this platform !!!");
        const int L = (int)state;

        return (*(DWORD *)(L + 20) - *(DWORD *)(L + 16)) >> 3;
    }

    static bool CheckPattern(const unsigned char *base, const unsigned char *pattern, const char *mask) {
        for (; *mask; ++mask, ++base, ++pattern) {
            if (*mask == 'x' && *base != *pattern)
                return false;
        }

        return true;
    }

    static void *FindAddress(const char *moduleName, const unsigned char *pattern, const char *mask) {
        HMODULE hModule = GetModuleHandleA(moduleName);
        if (!hModule)
            return nullptr;

        MODULEINFO mInfo;
        if (!GetModuleInformation(GetCurrentProcess(), hModule, &mInfo, sizeof(mInfo)))
            return nullptr;

        unsigned char *base = (unsigned char*)mInfo.lpBaseOfDll;
        DWORD size = mInfo.SizeOfImage;
        size_t pattern_len = strlen(mask);

        vector<void *> hits;
        hits.reserve(8);

        for (DWORD i = 0; i < size - pattern_len; i++) {
            if (CheckPattern(base + i, pattern, mask))
                hits.push_back((void*)(base + i));
        }

        if (hits.size() == 1)
            return hits[0];
        else {
            printf("too many matches found for byte sequence :: ");

            for (size_t i = 0; i < pattern_len; i++)
                printf("%02x ", (unsigned int)(pattern[i] & 0xFF));

            printf("\n");

            for (size_t i = 0; i < hits.size(); i++) {
                printf("    [%u] :: %p\n", i, hits[i]);
            }

            printf("\n");
        }

        return nullptr;
    }

    static bool find_lua_functions() {
        const size_t fun_count = sizeof(m2_exe_lua_func_signatures) / sizeof(function_byte_signature_t);
        bool found_all_necessary = true;

        for (size_t i = 0; i < fun_count; i++) {
            const auto &func_signature = m2_exe_lua_func_signatures[i];

            void *funcAddr = FindAddress(NULL, func_signature.signature, func_signature.mask);
            if (funcAddr != nullptr)
                *(func_signature.fun_ptr_ptr) = (void *)funcAddr;
            else {
                const bool necessary = func_signature.fail_on_missing;
                printf("could not find function in the executable [%s] :: %s()\n", necessary ? "necessary" : "optional", func_signature.name);

                found_all_necessary = found_all_necessary && (!necessary);
            }
        }

        return found_all_necessary;
    }

    __declspec(dllexport) int register_global_dofile() {
        if (!found_necessary_funcs) {
            printf("missing necessary lua functions !!!\n");
            return 1;
        }

        if (!got_lua_state) {
            printf("missing lua state !!!\n");
            return 2;
        }

        void *L = lua_state;

        my_lua_pushglobaltable(L);
        lua_pushstring(L, "kmf_dofile");
        lua_pushstring(L, "kmf_dofile");
        lua_pushcclosure(L, (void *)my_lua_dofile, 1);
        lua_rawset(L, -3);
        my_lua_pop(L, 1);

        return 0;
    }

    __declspec(dllexport) int try_setup_lua_state_getter() {
        found_necessary_funcs = find_lua_functions();

        if (_orig_lua_gettop == nullptr) {
            printf("failed to find even lua_gettop() !!!\n");
            return 1;
        }

        if (DetourIsHelperProcess()) {
            printf("process is a helper process, unable to detour !!!\n");
            return 2;
        }
        else {
            DetourRestoreAfterWith();
            DetourTransactionBegin();
            DetourUpdateThread(GetCurrentThread());
            DetourAttach(&(PVOID &)_orig_lua_gettop, _hook_lua_gettop);
            DetourTransactionCommit();
        }

        if (!found_necessary_funcs) {
            printf("could not find necessary lua functions !!!\n");
            return 3;
        }

        return 0;
    }

    static void stdout_output_thread() {
        DWORD dwBytesWritten;

        while (!exiting) {
            Sleep(10);

            {
                unique_lock<mutex> lock(stdout_mutex);

                if (stdout_messages.size() > 0) {
                    HANDLE hFile = CreateFileA(
                        stdout_file_path.c_str(),
                        FILE_APPEND_DATA,
                        0x0,
                        nullptr,
                        OPEN_ALWAYS,
                        FILE_ATTRIBUTE_NORMAL,
                        nullptr
                    );

                    if ( hFile == INVALID_HANDLE_VALUE )
                        continue;

                    DWORD dwMoved = SetFilePointer(
                        hFile,
                        0l,
                        nullptr,
                        FILE_END
                    );

                    if ( dwMoved == INVALID_SET_FILE_POINTER )
                        goto close_handle;

                    while (stdout_messages.size()) {
                        const string &msg = stdout_messages.front();

                        if (!Orig_WriteFile(
                            hFile,
                            msg.c_str(),
                            msg.length(),
                            &dwBytesWritten,
                            NULL
                        )) {
                            printf("failed write !!!\n");
                            break;
                        }

                        if (dwBytesWritten != msg.length()) {
                            printf("incomplete write [%lu / %d]!!!\n", dwBytesWritten, msg.length());
                        }

                        stdout_messages.pop();
                    }
    close_handle:
                    CloseHandle(hFile);
                }
            }
        }
    }

    static void write_stdout_to_file(string &&msg) {
        unique_lock<mutex> lock(stdout_mutex);

        if (!stdout_thread_started) {
            stdout_thread_started = true;

            stdout_thread = thread(stdout_output_thread);
            stdout_thread.detach();
        }

        size_t index = 0;

        while (true) {
            index = msg.find("\r\n", index);

            if (index == string::npos)
                break;

            msg.replace(index, 2, "\n");
            index += 1;
        }

        stdout_messages.push(msg);
    }

    static bool download_file_from_url_to_mem(const char *url, char **res, size_t *size) {
        char tmp[NET_BUF_SIZE], *ret;
        STARTUPINFOA info;
        PROCESS_INFORMATION processInfo;
        SECURITY_ATTRIBUTES saAttr;
        HANDLE hPipe_r, hPipe_w;
        BOOL bSuccess = FALSE;
        DWORD dwRead;
        size_t ret_sz, ret_offset = 0;
        vector<string> cmds;

        *res = NULL;
        *size = 0;

        ret_sz = 1;
        ret = (char *)malloc(1 * sizeof(char));
        ret[0] = 0;

        // this is borderline retarded, i know
        cmds.push_back(string("curl.exe -s --max-time 2 --output - ") + url);
        cmds.push_back(string("powershell -Command \"$webclient = new-object system.net.webclient; $webclient.DownloadString('") + url + "');\"");

        for (auto& cmd : cmds)
            cmd.resize(MAX_PATH);

        saAttr.nLength = sizeof(SECURITY_ATTRIBUTES);
        saAttr.bInheritHandle = TRUE;
        saAttr.lpSecurityDescriptor = NULL;

        for (auto cmd : cmds) {
            if (!CreatePipe(&hPipe_r, &hPipe_w, &saAttr, 0))
                return false;

            if (!SetHandleInformation(hPipe_r, HANDLE_FLAG_INHERIT, 0))
                goto clean;

            ZeroMemory(&info, sizeof(STARTUPINFOA));
            info.cb = sizeof(STARTUPINFOA);
            info.hStdError = NULL;
            info.hStdOutput = hPipe_w;
            info.hStdInput = NULL;
            info.dwFlags |= STARTF_USESTDHANDLES;

            if (CreateProcessA(NULL, &cmd[0], NULL, NULL, TRUE, CREATE_NO_WINDOW, NULL, NULL, &info, &processInfo)) {
                CloseHandle(hPipe_w);
            }
            else{
                continue;
            }

            while (true) {
                bSuccess = ReadFile(hPipe_r, tmp, sizeof(tmp), &dwRead, NULL);

                if (!bSuccess || dwRead == 0)
                    break;

                ret = (char*)realloc(ret, ret_sz += dwRead);

                if (!ret)
                    goto out;

                memmove(ret + ret_offset, tmp, dwRead);
                ret_offset += dwRead;
            }

            if (ret)
                ret[ret_sz - 1] = '\0';

            DWORD exit;

            if (!GetExitCodeProcess(processInfo.hProcess, &exit) || exit) {
                continue;
            }

            CloseHandle(processInfo.hProcess);
            CloseHandle(processInfo.hThread);

            break;
        }

    clean:
        if (!ret)
            CloseHandle(hPipe_w);
    out:
        CloseHandle(hPipe_r);

        if (!ret || ret_sz < 2)
            return false;

        *res = ret;
        *size = ret_sz - 1;

        return true;
    }

    __declspec(dllexport) void console_log(const char *message) {
        string str;
        bool success = true;

        try {
            str = string(message);
        }
        catch (...) {
            success = false;
        }

        if (!success)
            return;

        static mutex       interact_mutex;
        unique_lock<mutex> lock(interact_mutex);

        console_output.push_back(str);
    }

    __declspec(dllexport) void print(const char *message) {
        write_stdout_to_file(string(message) + "\n");
    }

    __declspec(dllexport) void my_free(void *data) {
        if (data != NULL)
            free(data);
    }

    __declspec(dllexport) char *try_get_request(const char *url) {
        char *res;
        size_t size;

        download_file_from_url_to_mem(url, &res, &size);

        return res;
    }

    __declspec(dllexport) char *try_get_request_or_cache(const char *url, const char *file_name) {
        char *res;
        size_t size;
        filesystem::path cache_path = "./cache/";

        cache_path /= file_name;

        if (download_file_from_url_to_mem(url, &res, &size)) {
            DWORD dwBytesWritten;
            printf("trying to write to a cache file :: %s\n", cache_path.string().c_str());

            HANDLE hFile = CreateFileA(
                cache_path.string().c_str(),
                FILE_GENERIC_WRITE,
                0x0,
                nullptr,
                CREATE_ALWAYS,
                FILE_ATTRIBUTE_NORMAL,
                nullptr
            );

            if (hFile != INVALID_HANDLE_VALUE) {
                Orig_WriteFile(
                    hFile,
                    res,
                    size,
                    &dwBytesWritten,
                    NULL
                );

                if (dwBytesWritten != size) {
                    printf("incomplete write [%lu / %d] !!!\n", dwBytesWritten, size);
                }
            }
            else {
                printf("cannot open cache file for writing [%lu] !!!\n", GetLastError());
            }
        }
        else if (filesystem::exists(cache_path)) {
            printf("network error, getting loader from cache !!!\n");

            size_t size = std::filesystem::file_size(cache_path);
            res = new char[size + 1];

            ifstream cached_file(cache_path);
            cached_file.read(res, size);
            res[size] = '\0';
        }

        return res;
    }

    __declspec(dllexport) int try_download_installer(const char *url) {
        char *content;
        size_t c_sz;

        if (!download_file_from_url_to_mem(url, &content, &c_sz) || content == NULL) {
            if (content)
                free(content);

            return 1;
        }

        FILE *file;
        file = fopen("./installer.exe", "wb");

        if (!file) {
            free(content);
            return 2;
        }

        size_t written = fwrite(content, sizeof(char), c_sz, file);
        fclose(file);
        free(content);

        if (written < c_sz)
            return 3;

        return 0;
    }

    static void console_output_thread(void) {
        bool           result;
        char           *buf;
        DWORD          written;

        buf = (char *)malloc(BUFSIZE);
        sprintf(buf, hello_msg, GetCurrentProcessId());
        console_log(buf);

        while (!exiting && !restarting) {
            if (console_output.size() > 0) {
                try {
                    string msg = console_output.back();
                    console_output.pop_back();
                    result = Orig_WriteFile(console_pipe, msg.c_str(), msg.length(), &written, NULL);

                    if (!result) {
                        thread reset_thread(reset_ipc);
                        reset_thread.detach();
                    }
                }
                catch (...) {}
            }
            else
                Sleep(10);
        }

        free(buf);
        return;
    }

    __declspec(dllexport) int check_exec_queue(char **ptr, unsigned int *size) {
        unique_lock<mutex> lock(exec_mutex);

        if (exec_queue.size() > 0) {
            try {
                *ptr = exec_queue.front();
                *size = strlen(*ptr);
                exec_queue.pop();
            }
            catch (...) {}

            return 1;
        }
        else
            return 0;
    }

    static void execute_lua_thread(void) {
        bool  result;
        char  *msg;
        char  *buf;
        DWORD read;

        buf = (char*)malloc(BUFSIZE);

        while (!exiting && !restarting) {
            try {
                result = ReadFile(execute_pipe, buf, BUFSIZE - 1, &read, NULL);
                if (read < BUFSIZE)
                    buf[read] = '\0';
                else
                    buf[BUFSIZE - 1] = '\0';

                if (result) {
                    msg = _strdup(buf);
                    unique_lock<mutex> lock(exec_mutex);
                    exec_queue.push(msg);
                }
                else {
                    if (!result) {
                        thread reset_thread(reset_ipc);
                        reset_thread.detach();
                    }
                }
            }
            catch (...) {}
        }

        free(buf);

        return;
    }

    static bool wait_for_pipes(void) {
        int err;
        ipc_mutex.lock();

        console_pipe = INVALID_HANDLE_VALUE;
        execute_pipe = INVALID_HANDLE_VALUE;

        try {
            int fail_count = 0;

            while (console_pipe == INVALID_HANDLE_VALUE) {
                console_pipe = CreateFileW(
                    console_pipe_name,    // pipe name
                    GENERIC_WRITE,        // write access only
                    0,                    // no sharing
                    NULL,                 // default security attributes
                    OPEN_EXISTING,        // opens existing pipe
                    FILE_FLAG_OVERLAPPED, // default attributes
                    NULL                  // no template file
                );

                err = GetLastError();
                if ((err != ERROR_FILE_NOT_FOUND || fail_count > 1) && err != ERROR_SUCCESS) {
                    ipc_mutex.unlock();
                    return false;
                }
                else if (err != ERROR_SUCCESS)
                    Sleep(100);

                fail_count++;
            }

            fail_count = 0;

            while (execute_pipe == INVALID_HANDLE_VALUE) {
                execute_pipe = CreateFileW(
                    execute_pipe_name,    // pipe name
                    GENERIC_READ,         // read access only
                    0,                    // no sharing
                    NULL,                 // default security attributes
                    OPEN_EXISTING,        // opens existing pipe
                    FILE_FLAG_OVERLAPPED, // default attributes
                    NULL                  // no template file
                );

                err = GetLastError();
                if ((err != ERROR_FILE_NOT_FOUND || fail_count > 1) && err != ERROR_SUCCESS) {
                    ipc_mutex.unlock();
                    return false;
                }
                else if (err != ERROR_SUCCESS)
                    Sleep(100);

                fail_count++;
            }

            con_thread.~thread();
            exe_thread.~thread();
            con_thread = thread(console_output_thread);
            exe_thread = thread(execute_lua_thread);
            con_thread.detach();
            exe_thread.detach();
            ipc_mutex.unlock();

            return true;
        }
        catch (...) {
            ipc_mutex.unlock();
        }


        return false;
    }

    __declspec(dllexport) int setup_IPC() {
        static mutex       interact_mutex;
        unique_lock<mutex> lock(interact_mutex);

        if (wait_for_pipes())
            return 1;
        //thread wait_thread(wait_for_pipes);
        //wait_thread.detach();
        return 0;
    }

    static void reset_ipc(void) {
        void *ret1, *ret2;

        ipc_mutex.lock();
        if (restarting == true) {
            ipc_mutex.unlock();
            return;
        }

        restarting = true;
        ipc_mutex.unlock();

        try {
            CloseHandle(console_pipe);
            CloseHandle(execute_pipe);

            restarting = false;
            while (!wait_for_pipes()) { }
        }
        catch (...) {}

        return;
    }

    __declspec(dllexport) void set_execute_callback(trigger_cb_t cb) {
        char buf[1024];
        sprintf(buf, "got callback ptr [%x]", (size_t)cb);
        MessageBoxA(NULL, buf, "set cb", 0);

        trigger_cb = cb;
    }
}

BOOL APIENTRY DllMain(HMODULE hModule,
    DWORD  ul_reason_for_call,
    LPVOID lpReserved
)
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
    case DLL_THREAD_ATTACH:
        filesystem::create_directory("./cache");
    case DLL_THREAD_DETACH:
    case DLL_PROCESS_DETACH:
        break;
    }

    return TRUE;
}
