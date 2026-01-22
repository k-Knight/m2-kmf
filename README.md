# Magicka 2 Mods

To install the mods, run the installer and give it the path to the Magicka 2 root directory *(that is where `data` and `engine` folders are located)*.

So far only Windows is supported.


### >>> <a href="https://github.com/k-Knight/m2-kmf/raw/master/installer.exe">DOWNLOAD</a> <<<

<br>
## I get virus warnings!
Those are false positives; here is why that happens:

- The loader script is here for ***legacy reasons*** and will be deleted in the ***near future***.

- The loader script is obfuscated so people cannot get tier 2 access without completing challenges.

- The only thing the loader script does is check the Steam user ID locally (it does not send or record anything) to see if the user has tier 2 access or whether to activate extended functionality; nothing binary gets decoded.

- I have written the installer myself because I wanted to, and it has to scan part of your system to find the Magicka 2 installation directory (scanning is very minimal, since I try to do it in a smart way; results are not sent anywhere), and after installation it deletes zone identifier streams so users will not have warnings when trying to launch the executables.

- The only logging that is being done is done locally, so you can send me crash logs if you want to (I do not send them automatically) and for debugging purposes (it is not done when you do not have the debugger running that I do not distribute with mods).

- I do not do DLL injection; the attacher is there to basically attach to the debugger. I modify game files to make the games load needed DLLs themselves.

- I have hotkey functions, so I have to listen to inputs, but you can check that no logging occurs.

- Since I support gamepad hotkeys, I have to listen to it too, but I cannot do it as a child process of Magicka 2; as such, I have to use Windows Scheduler or tricks to launch an unrelated process to Magicka 2.

- Detours are only used for debugging and crash logging.

## Notes

- Usually windows system detects utility files as viruses, this is a false positive, probably best course of action is to add `Magicka 2/engine` folder to antivirus exclusions.
- If you are interested here is <a href="https://github.com/k-Knight/m2-kmf/commits">changelog</a>, kinda ...

## Requirements for building m2-kmf

The build process for m2-kmf involves several stages, including the configuration of compilation environments, the extraction of game assets, and the decompilation of source files for modification. The project consists of three primary components:

*   **Python and C/C++ Tooling:** Required for manipulating game data bundles and automation.
*   **KMF Utilities:** C++ components that enable Lua scripts to access extended functionality not provided by the game.
*   **Modified Lua Scripts:** Revised game logic where functional changes are implemented.

**Note:**
- [Precompiled tools and libraries](https://pepega.online/download?file=m2_tools_prebuilt.7z) are available to reduce the effort required for a full build from scratch.
- Decompiled sources' diffs assume the use of [luajit-decompiler-v2](https://github.com/marsinator358/luajit-decompiler-v2).
- This repository and automation scripts assume **LF** line endings (**not CRLF**), it is recommended to clone this repo as such.
- As of right now m2-kmf can only be built on Windows and for Windows (Linux support is expected to be implemented in the future).

### Requirements

#### Common Dependencies
*   **Git:** Utilized by various automation scripts.
*   **Python:** The primary dependency for most tooling.
*   **MSYS2:** May be required for script execution (not tested).

#### KMF Utilities Dependencies
Building the KMF utilities requires the following software and libraries:

*   **Build Environment:** [Microsoft Build Tools](https://visualstudio.microsoft.com) or [Visual Studio](https://visualstudio.microsoft.com) (specifically `vcvarsall.bat` for x86 compilation).
*   **Build Tools:** [CMake](https://cmake.org) and the [Clang compiler](https://llvm.org).
*   **Libraries:** 
    *   **wxWidgets:** Version 3.2.3.
    *   **Microsoft Detours:** Version 4.0.1 (required for debugging and third-party mod loading).
    *   **Steamworks SDK Headers:** Header files only.
    *   **SDL:** Version 2.0.
    *   **ZLib:** Version 1.3.1 (required for modifying game bundles).
    *   **Zstandard (zstd):** Version 1.5.6 (required if compiling the installer).

#### Game Scripts Modification Dependencies
*   **Bubble:** Both new and old versions are required for automation scripts.
*   **[luajit-decompiler-v2](https://github.com/marsinator358/luajit-decompiler-v2):** Needed to decompile game's sources.
*   **LuaJIT:** Needed to compile scripts (testing shows that version 2.0.5 works with no issues).

**Note:**
*   LuaJIT's script for producing bytecode **is modified** to produce useful debugging information in-game.

## Environment Setup

The following instructions outline the recommended procedure for configuring the build environment. While alternative methods may yield successful results, the scripts and commands provided herein assume adherence to this specific structure.

**Note:** This section does not cover the compilation of external library dependencies.

### Initial Project Initialization
1.  **Create workspace:** Establish a root directory for the project:
    ```bash
    mkdir m2-project
    cd m2-project/
    ```
2.  **Clone repository:** Execute the following command to ensure correct line-ending handling:
    ```bash
    git -c core.eol=lf -c core.autocrlf=false clone https://github.com
    ```
3.  **Prepare tools:** Copy the contents of `m2-kmf/mods/tools` to a new `tools` directory within the project root.

### Tool Compilation
To prepare the necessary automation and decompilation tools, perform the following steps:

*   **Bubble**
    *   Navigate to `tools/bubble` and execute `compile.bat`.
    *   **Note:** This process requires **ZLib**.

*   **LuaJIT**
    *   Compile **LuaJIT** and move the resulting build files to the `tools/luajit` directory.
    *   **WARNING:** Do **not** replace the existing `bcsave.lua` file. The repository's version is modified for compatibility, overwriting it will cause `mod_packager.py` to malfunction.

*   **luajit-decompiler-v2**
    *   Build [luajit-decompiler-v2](https://github.com).
    *   Relocate the compiled output files into the `tools/ljd` directory.

### Extraction and Decompilation
1.  **Extract game assets:** Create a directory named `m2-data` and copy the original game bundles from `<game_root>/data` into it.
2.  **Unpack bundles:** Create a directory named `m2-unpacked` and execute the batch unbundler script:
    ```bash
    python tools/data_upacker.py -i m2-data/ -o m2-unpacked/
    ```
3.  **Decompile sources:** Create a directory named `m2-decomp` and run the batch decompiler script:
    ```bash
    python tools/bitsquid2lua.py -d m2-unpacked/ -o m2-decomp/ -t 8
    ```
4.  **Prepare sources for modding:** Create a directory named `m2-mod-src` and copy all files from `m2-decomp/` into it. It is recommended to set `m2-decomp` to read-only status to prevent accidental modification of the original source.
5.  **Apply diffs:** Run the following script to apply existing diffs to the source files:
    ```bash
    python tools/apply_tree_diff.py -d m2-kmf/mods/src/ -t m2-mod-src/
    ```

### Building KMF Utilities
This stage requires **CMake**, **SDL**, **Detours**, **wxWidgets** libraries and **Steamworks SDK** headers (compiled library files for Steamworks are not required).
1.  **Bundle resources:** Navigate to `m2-kmf/kmf/graphics` and execute `resource_encoder.py`.
2.  **Configuration and compilation:** Navigate to `m2-kmf/kmf` and run `configure.bat`, followed by `compile.bat Release` (or `Debug`).
3.  **Deployment:** Copy the following files from `m2-kmf/kmf/bin/<build_type>/` to the `<game_root>/engine` directory:
    *   `attacher.dll`
    *   `data.ifa`
    *   `kmf_util.dll`
    *   `m2_mod_settings.exe`
    *   `sdl_gamepad_listener.exe`
    *   `SDL2.dll`

### Building Game Bundles
1.  **Necessary configuration:** Copy the contents of the `m2-kmf/mods/config` directory into the `m2-project` root directory.
2.  **Output preparation:** Create a directory named `m2-updated` to hold the modified bundles. Modify `mod_packager.yml` if specific configuration changes are necessary.
3.  **Package bundles:** Execute the packaging script:
    ```bash
    python tools/mod_packager.py -d m2-mod-src/ -o m2-updated/ -c mod_packager.yml -p
    ```
    *Note: Verify the output log confirms that "adding new network config..." is present, absence indicates the script could not locate the `new.network_config` file.*
4.  **Deployment:** Copy the newly created bundles from `m2-updated/` to the `<game_root>/data` directory.

### Building the Installer
Building the installer requires the **Zstandard (zstd)** library.
1.  **Installation file tree setup:** Create a directory structure representing the final installation at `m2-kmf/installer/files_to_install`.
2.  **Payload:** Copy the required binaries from `m2-kmf/kmf/bin/<build_type>/` and the updated bundles from `m2-updated/` into the appropriate subdirectories within the installer's file tree.
3.  **Compilation:** Navigate to `m2-kmf/installer`, run `configure.bat`, and then execute `compile-release.bat` (or `compile-debug.bat`).

### Repository Maintenance
To update the source files within the public-facing repository after local modifications, use the following command:
```bash
python tools/update_public_src.py -s m2-decomp/ -d m2-mod-src/ -o m2-kmf/mods/src -c mod_packager.yml
