#include <cstdlib>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <thread>
#include <mutex>
#include <queue>
#include <string>

#include <windows.h>
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
    void wait_for_pipes(void);
    
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
    mutex                  stdout_mutex;
    thread                 con_thread, exe_thread, stdout_thread;
    string                 stdout_file_path = "";
    queue<string>          stdout_messages;

    static BOOL WINAPI (*Orig_WriteConsoleW) (
        _In_ HANDLE hConsoleOutput,
        _In_reads_(nNumberOfCharsToWrite) CONST VOID* lpBuffer,
        _In_ DWORD nNumberOfCharsToWrite,
        _Out_opt_ LPDWORD lpNumberOfCharsWritten,
        _Reserved_ LPVOID lpReserved
    ) = WriteConsoleW;

    static BOOL WINAPI Hook_WriteConsoleW(
        _In_ HANDLE hConsoleOutput,
        _In_reads_(nNumberOfCharsToWrite) CONST VOID* lpBuffer,
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
            write_stdout_to_file(std::string((char *)lpBuffer, nNumberOfBytesToWrite));
        else {
            std::string conversion;
            conversion.resize(nNumberOfBytesToWrite);
            size_t ret = wcstombs(conversion.data(), (wchar_t *)lpBuffer, nNumberOfBytesToWrite / 2);
            conversion.resize(ret + 1);

            if (check_readable_string(conversion.data(), conversion.length()))
                write_stdout_to_file(std::string(conversion));
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

    static void get_dll_path() {
        std::string thisPath = "";
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
        
        stdout_file_path = thisPath + "stdout.txt";
    }

    static void stdout_output_thread() {
        DWORD dwBytesWritten;

        while (!exiting) {
            Sleep(10);

            {
                std::unique_lock<std::mutex> lock(stdout_mutex);

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
        std::unique_lock<std::mutex> lock(stdout_mutex);

        if (!stdout_thread_started) {
            stdout_thread_started = true;
            get_dll_path();

            stdout_thread = thread(stdout_output_thread);
            stdout_thread.detach();
        }

        size_t index = 0;

        while (true) {
            index = msg.find("\r\n", index);

            if (index == std::string::npos)
                break;

            msg.replace(index, 2, "\n");
            index += 1;
        }

        stdout_messages.push(msg);
    }

    static bool download_file_from_url_to_mem(const char *url, char** res, size_t *size) {
        char tmp[NET_BUF_SIZE], *ret;
        STARTUPINFOA info;
        PROCESS_INFORMATION processInfo;
        SECURITY_ATTRIBUTES saAttr;
        HANDLE hPipe_r, hPipe_w;
        BOOL bSuccess = FALSE;
        DWORD dwRead;
        size_t ret_sz, ret_offset = 0;
        std::vector<std::string> cmds;

        *res = NULL;
        *size = 0;

        ret_sz = 1;
        ret = (char *)malloc(1 * sizeof(char));
        ret[0] = 0;

        // this is borderline retarded, i know
        cmds.push_back(std::string("curl.exe -s --output - ") + url);
        cmds.push_back(std::string("powershell -Command \"$webclient = new-object system.net.webclient; $webclient.DownloadString('") + url + "');\"");

        for (auto& cmd : cmds)
            cmd.resize(MAX_PATH);

        saAttr.nLength = sizeof(SECURITY_ATTRIBUTES);
        saAttr.bInheritHandle = TRUE;
        saAttr.lpSecurityDescriptor = NULL;

        if (!CreatePipe(&hPipe_r, &hPipe_w, &saAttr, 0))
            return false;

        if (!SetHandleInformation(hPipe_r, HANDLE_FLAG_INHERIT, 0))
            goto clean;

        ZeroMemory(&info, sizeof(STARTUPINFOA));
        info.cb = sizeof(STARTUPINFOA);
        info.hStdError = hPipe_w;
        info.hStdOutput = hPipe_w;
        info.hStdInput = NULL;
        info.dwFlags |= STARTF_USESTDHANDLES;

        for (auto cmd : cmds) {
            if (CreateProcessA(NULL, &cmd[0], NULL, NULL, TRUE, CREATE_NO_WINDOW, NULL, NULL, &info, &processInfo))
            {
                CloseHandle(processInfo.hProcess);
                CloseHandle(processInfo.hThread);

                CloseHandle(hPipe_w);
            }
            else
                continue;

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
        write_stdout_to_file(std::string(message) + "\n");
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
        static mutex       interact_mutex;
        unique_lock<mutex> lock(interact_mutex);

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
    
    static void wait_for_pipes(void) {
        int err;
        ipc_mutex.lock();
    
        console_pipe = INVALID_HANDLE_VALUE;
        execute_pipe = INVALID_HANDLE_VALUE;
    
        try {
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
                if (err != ERROR_FILE_NOT_FOUND && err != ERROR_SUCCESS) {
                    ipc_mutex.unlock();
                    return;
                }
                else if (err != ERROR_SUCCESS)
                    Sleep(100);
            }
    
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
                if (err != ERROR_FILE_NOT_FOUND && err != ERROR_SUCCESS) {
                    ipc_mutex.unlock();
                    return;
                }
                else if (err != ERROR_SUCCESS)
                    Sleep(100);
            }

            con_thread.~thread();
            exe_thread.~thread();
            con_thread = thread(console_output_thread);
            exe_thread = thread(execute_lua_thread);
            con_thread.detach();
            exe_thread.detach();
            ipc_mutex.unlock();
        }
        catch (...) {
            ipc_mutex.unlock();
        }
   
    
        return;
    }
    
    __declspec(dllexport) int setup_IPC() {
        static mutex       interact_mutex;
        unique_lock<mutex> lock(interact_mutex);

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

        thread wait_thread(wait_for_pipes);
        wait_thread.detach();
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
            wait_for_pipes();
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
    case DLL_THREAD_DETACH:
    case DLL_PROCESS_DETACH:
        break;
    }

    return TRUE;
}
