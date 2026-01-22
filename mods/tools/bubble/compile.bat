@echo off
for /f "delims=" %%i in ('"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath') do set vs_path=%%i
call "%vs_path%\VC\Auxiliary\Build\vcvarsall.bat" x64
clang++ -m64 -Wno-deprecated-declarations -O3 -std=c++17 -Izlib/include -static -fms-runtime-lib=static -fno-exceptions -c bubble.cpp -o bubble.obj -D_MT
clang-cl bubble.obj /Febubble.exe /MT /link /nodefaultlib:msvcrt.lib /nodefaultlib:ucrt.lib libcmt.lib libvcruntime.lib libucrt.lib zlibstatic.lib /libpath:zlib/lib /ignore:4217 /ignore:4286