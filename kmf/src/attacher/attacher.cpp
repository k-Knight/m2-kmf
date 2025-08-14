#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <thread>
#include <mutex>
#include <queue>
#include <string>
#include <format>

#include <windows.h>
#include <shlwapi.h>
#include <shellapi.h>

using namespace std;

#define BUFSIZE 64 * 1024
#define NET_BUF_SIZE 1024 * 4
#ifndef min
#define min(a,b)    (((a) < (b)) ? (a) : (b))
#endif

extern "C" {
    typedef struct {
        char *data;
        size_t size;
    } console_msg_t;
    
    /* public use */
    typedef void(__cdecl *trigger_cb_t)(void);
    
    __declspec(dllexport) int setup_IPC();
    __declspec(dllexport) void set_execute_callback(trigger_cb_t cb);
    __declspec(dllexport) void console_log(const char *message);
    __declspec(dllexport) void print(const char *message);
    __declspec(dllexport) char *try_get_request(char *url);
    __declspec(dllexport) void my_free(void *data);
    __declspec(dllexport) int check_exec_queue(char **ptr, unsigned int *size);
    
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
    deque<console_msg_t *> console_output;
    mutex                  ipc_mutex;
    mutex                  stdout_mutex;
    thread                 con_thread, exe_thread, stdout_thread;
    string                 stdout_file_path = "";
    queue<string>          stdout_messages;
    
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
        while (!exiting) {
            {
                std::unique_lock<std::mutex> lock(stdout_mutex);

                if (stdout_messages.size() > 0) {
                    FILE *stdout_file = fopen(stdout_file_path.c_str(), "a");;

                    while (stdout_messages.size()) {
                        fprintf(stdout_file, "%s\n", stdout_messages.front().c_str());
                        stdout_messages.pop();
                    }

                    fclose(stdout_file);
                }
            }

            Sleep(10);
        }
    }

    static void write_stdout_to_file(const char *msg) {
        std::unique_lock<std::mutex> lock(stdout_mutex);

        if (!stdout_thread_started) {
            stdout_thread_started = true;
            get_dll_path();

            stdout_thread = thread(stdout_output_thread);
            stdout_thread.detach();
        }

        stdout_messages.push(msg);
    }

    __declspec(dllexport) void send_debugger_message(unsigned char type, const char *message) {
        console_msg_t *msg = NULL;

        try {
            size_t msg_size = strlen(message);

            msg = new console_msg_t;
            msg->data = new char[msg_size + 2];
            *(msg->data) = type;
            memmove(msg->data + 1, message, sizeof(char) * msg_size);
            msg->data[msg_size + 1] = '\0';
            msg->size = msg_size + 1;
        }
        catch (...) {
            if (msg->data)
                free(msg->data);
            if (msg)
                free(msg);
        }

        static mutex       interact_mutex;
        unique_lock<mutex> lock(interact_mutex);

        console_output.push_back(msg);
    }

    __declspec(dllexport) void console_log(const char *message) {
        send_debugger_message(0x01, message);
    }

    __declspec(dllexport) void print(const char *message) {
        write_stdout_to_file(message);
    }

    __declspec(dllexport) void my_free(void *data) {
        free(data);
    }

    __declspec(dllexport) char *try_get_request(char *url) {
        char tmp[NET_BUF_SIZE], *ret = NULL;
        STARTUPINFOA info;
        PROCESS_INFORMATION processInfo;
        SECURITY_ATTRIBUTES saAttr;
        HANDLE hPipe_r, hPipe_w;
        BOOL bSuccess = FALSE;
        DWORD dwRead;
        size_t ret_sz, ret_offset = 0;
        std::vector<std::string> cmds;

        // this is borderline retarded, i know
        cmds.push_back(std::string("curl.exe -s ") + url);
        cmds.push_back(std::string("powershell -Command \"$webclient = new-object system.net.webclient; $webclient.DownloadString('") + url + "');\"");

        for (auto& cmd : cmds)
            cmd.resize(MAX_PATH);

        saAttr.nLength = sizeof(SECURITY_ATTRIBUTES);
        saAttr.bInheritHandle = TRUE;
        saAttr.lpSecurityDescriptor = NULL;

        if (!CreatePipe(&hPipe_r, &hPipe_w, &saAttr, 0))
            return NULL;

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

                if (!ret)
                    ret = (char*)malloc(ret_sz = dwRead + 1);
                else
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

        return ret;
    }
    
    static void console_output_thread(void) {
        bool           result;
        char           *buf;
        DWORD          written;
        console_msg_t  *msg;
    
        buf = (char *)malloc(BUFSIZE);
        sprintf(buf, hello_msg, GetCurrentProcessId());
        console_log(buf);
    
        while (!exiting && !restarting) {
            if (console_output.size() > 0) {
                try {
                    msg = (console_msg_t*)console_output.back();
                    console_output.pop_back();
                    result = WriteFile(console_pipe, msg->data, msg->size, &written, NULL);

                    delete msg->data;
                    delete msg;

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
