#include "input_handler.hpp"

#define _WIN32_DCOM

#include <thread>
#include <chrono>
#include <ctime>
#include <string>
#include <utility>
#include <filesystem>

#include <windows.h>
#include <wchar.h>
#include <comdef.h>
#include <wincred.h>
//  Include the task header file.
#include <taskschd.h>
#pragma comment(lib, "taskschd.lib")
#pragma comment(lib, "comsupp.lib")
#pragma comment(lib, "credui.lib")
#include <mstask.h>

#include <sdl_gamepad_state.hpp>
#include <defer.hpp>

#if defined(DEBUG) || defined(_DEBUG)
#   include "debug_logger.hpp"
#endif //DEBUG

HANDLE hMapFile;
volatile bool *gamepad_btn_status = NULL;
volatile bool gamepad_listener_initialized = false;
std::wstring executable_path;
const wchar_t *scheduler_task_name = L"KMF game controller listener";

void stop_gamepad_listener() {
    UnmapViewOfFile((void *)gamepad_btn_status);
    CloseHandle(hMapFile);
}

static bool create_shared_memory() {
    SECURITY_ATTRIBUTES sec_attr;

    sec_attr.nLength = sizeof(sec_attr); // Set up security attibutes
    sec_attr.bInheritHandle = false;      // So handle can be inherited
    sec_attr.lpSecurityDescriptor = NULL;

    hMapFile = CreateFileMappingW(
        INVALID_HANDLE_VALUE,           // use paging file
        &sec_attr,                      // default security
        PAGE_READWRITE,                 // read/write access
        0,                              // maximum object size (high-order DWORD)
        sizeof(bool) * GAMEPAD_BTN_NUM, // maximum object size (low-order DWORD)
        shared_mem_name                 // name of mapping object
    );

    if (hMapFile == NULL)
    {
#if defined(DEBUG) || defined(_DEBUG)
        debug_write("could not create file mapping object (%d)\n", GetLastError());
#endif //DEBUG

        gamepad_listener_initialized = false;

        return false;
    }

    gamepad_btn_status = (bool *)MapViewOfFile(
        hMapFile,            // handle to map object
        FILE_MAP_ALL_ACCESS, // read/write permission
        0,
        0,
        sizeof(bool) * GAMEPAD_BTN_NUM
    );

    if (gamepad_btn_status == NULL)
    {
#if defined(DEBUG) || defined(_DEBUG)
        debug_write("could not map view of file (%d)\n", GetLastError());
#endif //DEBUG

        CloseHandle(hMapFile);
        gamepad_listener_initialized = false;

        return false;
    }

    return true;
}

static bool check_ts_result(const char *err_msg, HRESULT res) {
    if (FAILED(res)) {
#if defined(DEBUG) || defined(_DEBUG)
        debug_write(err_msg, res);
#endif //DEBUG

        return false;
    }

    return true;
}

static bool start_gamepad_listener() {

    std::time_t t = std::time(0);   // get time now
    std::tm *now = std::localtime(&t);
    wchar_t buff[32];
    swprintf(buff, sizeof(buff), L"%04i-%02i-%02iT%02i:%02i:%02i",
        now->tm_year + 1900,
        now->tm_mon,
        now->tm_mday,
        now->tm_hour,
        now->tm_min,
        now->tm_sec + 5
    );

    ITaskService *pService = NULL;
    ITaskFolder *pRootFolder = NULL;
    ITaskDefinition *pTask = NULL;
    IRegistrationInfo *pRegInfo = NULL;
    IPrincipal *pPrincipal = NULL;
    ITaskSettings *pSettings = NULL;
    IIdleSettings *pIdleSettings = NULL;
    ITriggerCollection *pTriggerCollection = NULL;
    ITrigger *pTrigger = NULL;
    ITimeTrigger *pTimeTrigger = NULL;
    IActionCollection *pActionCollection = NULL;
    IAction *pAction = NULL;
    IExecAction *pExecAction = NULL;
    IRegisteredTask *pRegisteredTask = NULL;

    //  Initialize COM.
    if (!check_ts_result(
        "\nCoInitializeEx failed: %x\n",
        CoInitializeEx(NULL, COINIT_MULTITHREADED)
    ))
        return false;

    DEFER([]() {
        CoUninitialize();
    });

    //  Set general COM security levels.
    HRESULT secInitRes = CoInitializeSecurity(
        NULL,
        -1,
        NULL,
        NULL,
        RPC_C_AUTHN_LEVEL_PKT_PRIVACY,
        RPC_C_IMP_LEVEL_IMPERSONATE,
        NULL,
        0,
        NULL
    );

    // MSDN says if RPC_E_TOO_LATE is returned we must have called CoInitializeSecurity() a second time,
    //     surely we can then continue (clueless)
    if (FAILED(secInitRes) && secInitRes != RPC_E_TOO_LATE) {
#if defined(DEBUG) || defined(_DEBUG)
        debug_write("CoInitializeSecurity failed: %x\n", secInitRes);
#endif //DEBUG

        return false;
    }

    //  Create an instance of the Task Service. 
    if (!check_ts_result(
        "Failed to create an instance of ITaskService: %x\n",
        CoCreateInstance(CLSID_TaskScheduler,
            NULL,
            CLSCTX_INPROC_SERVER,
            IID_ITaskService,
            (void **)&pService
        )
    ))
        return false;

    DEFER([pService] {
        pService->Release();
    });

    //  Connect to the task service.
    if (!check_ts_result(
        "ITaskService::Connect failed: %x\n",
        pService->Connect(_variant_t(), _variant_t(), _variant_t(), _variant_t())
    ))
        return false;

    //  Get the pointer to the root task folder.  This folder will hold the new task that is registered.
    if (!check_ts_result(
        "Cannot get Root folder pointer: %x\n",
        pService->GetFolder(_bstr_t(L"\\"), &pRootFolder)
    ))
        return false;

    DEFER([pRootFolder] {
        pRootFolder->Release();
    });

    //  If the same task exists, remove it.
    pRootFolder->DeleteTask(_bstr_t(scheduler_task_name), 0);

    //  Create the task definition object to create the task.
    if (!check_ts_result(
        "Failed to CoCreate an instance of the TaskService class: %x\n",
        pService->NewTask(0, &pTask)
    ))
        return false;

    DEFER([pTask] {
        pTask->Release();
    });

    //  Get the registration info for setting the identification.
    if (!check_ts_result(
        "Cannot get identification pointer: %x\n",
        pTask->get_RegistrationInfo(&pRegInfo)
    ))
        return false;

    DEFER([pRegInfo] {
        pRegInfo->Release();
    });

    if (!check_ts_result(
        "Cannot put identification info: %x\n",
        pRegInfo->put_Author(_bstr_t(L"kmf"))
    ))
        return false;

    //  Create the principal for the task - these credentials are overwritten with the credentials passed to RegisterTaskDefinition
    if (!check_ts_result(
        "Cannot get principal pointer: %x\n",
        pTask->get_Principal(&pPrincipal)
    ))
        return false;
    
    DEFER([pPrincipal] {
        pPrincipal->Release();
    });

    //  Set up principal logon type to interactive logon
    if (!check_ts_result(
        "Cannot put principal info: %x\n",
        pPrincipal->put_LogonType(TASK_LOGON_INTERACTIVE_TOKEN)
    ))
        return false;

    //  Create the settings for the task
    if (!check_ts_result(
        "Cannot get settings pointer: %x\n",
        pTask->get_Settings(&pSettings)
    ))
        return false;
    
    DEFER([pSettings] {
        pSettings->Release();
    });

    //  Set setting values for the task.  
    if (!check_ts_result(
        "Cannot put setting information: %x\n",
        pSettings->put_StartWhenAvailable(VARIANT_TRUE)
    ))
        return false;

    if (!check_ts_result(
        "Cannot put setting information: %x\n",
        pSettings->put_ExecutionTimeLimit(_bstr_t(L"PT0S"))
    ))
        return false;

    if (!check_ts_result(
        "Cannot put setting information: %x\n",
        pSettings->put_DisallowStartIfOnBatteries(false)
    ))
        return false;

    if (!check_ts_result(
        "Cannot put setting information: %x\n",
        pSettings->put_MultipleInstances(TASK_INSTANCES_STOP_EXISTING)
    ))
        return false;

    if (!check_ts_result(
        "Cannot get idle setting information: %x\n",
        pSettings->get_IdleSettings(&pIdleSettings)
    ))
        return false;

    if (!check_ts_result(
        "Cannot get idle setting information: %x\n",
        pIdleSettings->put_WaitTimeout(_bstr_t(L"PT5M"))
    ))
        return false;

    DEFER([pIdleSettings] {
        pIdleSettings->Release();
    });

    //  Get the trigger collection to insert the time trigger.
    if (!check_ts_result(
        "Cannot get trigger collection: %x\n",
        pTask->get_Triggers(&pTriggerCollection)
    ))
        return false;

    DEFER([pTriggerCollection] {
        pTriggerCollection->Release();
    });

    //  Add the time trigger to the task.
    if (!check_ts_result(
        "Cannot get trigger collection: %x\n",
        pTriggerCollection->Create(TASK_TRIGGER_TIME, &pTrigger)
    ))
        return false;

    DEFER([pTrigger] {
        pTrigger->Release();
    });

    if (!check_ts_result(
        "QueryInterface call failed for ITimeTrigger: %x\n",
        pTrigger->QueryInterface(IID_ITimeTrigger, (void **)&pTimeTrigger)
    ))
        return false;

    DEFER([pTimeTrigger] {
        pTimeTrigger->Release();
    });

    if (!check_ts_result(
        "Cannot put trigger ID: %x\n",
        pTimeTrigger->put_Id(_bstr_t(L"Trigger1"))
    ))
        return false;

    if (!check_ts_result(
        "Cannot add start boundary to trigger: %x\n",
        pTimeTrigger->put_StartBoundary(_bstr_t(buff))
    ))
        return false;

    //  Get the task action collection pointer.
    if (!check_ts_result(
        "Cannot get Task collection pointer: %x\n",
        pTask->get_Actions(&pActionCollection)
    ))
        return false;

    DEFER([pActionCollection] {
        pActionCollection->Release();
    });

    //  Create the action, specifying that it is an executable action.
    if (!check_ts_result(
        "Cannot create the action: %x\n",
        pActionCollection->Create(TASK_ACTION_EXEC, &pAction)
    ))
        return false;

    DEFER([pAction] {
        pAction->Release();
    });

    //  QI for the executable task pointer.
    if (!check_ts_result(
        "QueryInterface call failed for IExecAction: %x\n",
        pAction->QueryInterface(IID_IExecAction, (void **)&pExecAction)
    ))
        return false;

    DEFER([pExecAction] {
        pExecAction->Release();
    });

    //  Set the path of the executable to notepad.exe.
    if (!check_ts_result(
        "Cannot put action path: %x\n",
        pExecAction->put_Path(_bstr_t(executable_path.c_str()))
    ))
        return false;

    //  Save the task in the root folder.
    if (!check_ts_result(
        "Error saving the Task : %x\n",
        pRootFolder->RegisterTaskDefinition(
            _bstr_t(scheduler_task_name),
            pTask,
            TASK_CREATE_OR_UPDATE,
            _variant_t(),
            _variant_t(),
            TASK_LOGON_INTERACTIVE_TOKEN,
            _variant_t(L""),
            &pRegisteredTask
        )
    ))
        return false;

    DEFER([pRegisteredTask] {
        pRegisteredTask->Release();
    });

#if defined(DEBUG) || defined(_DEBUG)
    debug_write("Task successfully registered\n");
#endif //DEBUG

    // Call ITask::Run to start the execution of "Test Task".

    if (!check_ts_result(
        "Failed calling ITask::Run, error = 0x%x\n",
        pRegisteredTask->Run(_variant_t(), NULL)
    ))
        return false;

    return true;
}

void init_gamepad_listener(std::filesystem::path *path) {
    executable_path = path->wstring();
    std::wstring w_cmd = L"explorer \"" + executable_path + L"\"";
    std::string cmd;

    cmd.resize(w_cmd.length() + 1);
    size_t ret = wcstombs(cmd.data(), w_cmd.c_str(), w_cmd.length());
    cmd[ret] = '\0';

    if (!create_shared_memory())
        return;

    if (!start_gamepad_listener())
        system(cmd.c_str());

    gamepad_listener_initialized = true;
}

bool is_gamepad_btn_pressed(gamepad_btn_t btn) {
    if (!gamepad_listener_initialized || !gamepad_btn_status)
        return false;

    return gamepad_btn_status[(int)btn];
}
