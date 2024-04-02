@echo off
for /f "delims=" %%i in ('"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath') do set vs_path=%%i
call "%vs_path%\VC\Auxiliary\Build\vcvarsall.bat" x86
cmake -G "Ninja Multi-Config" -DCMAKE_C_COMPILER=clang.exe -DCMAKE_CXX_COMPILER=clang++.exe -B .cmake_cache -DCMAKE_CONFIGURATION_TYPES="Release;Debug" src %*
