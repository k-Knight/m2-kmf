@echo off
for /f "delims=" %%i in ('"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath') do set vs_path=%%i
call "%vs_path%\VC\Auxiliary\Build\vcvarsall.bat" x64

clang++ -m64 -Wno-deprecated-declarations -O3 -std=c++23 -Izlib/include -static -fms-runtime-lib=static -fno-exceptions -c str2hash.cpp -o str2hash.obj -D_MT
clang-cl str2hash.obj /Festr2hash.exe /MT /link /nodefaultlib:msvcrt.lib /nodefaultlib:ucrt.lib libcmt.lib libvcruntime.lib libucrt.lib /ignore:4217 /ignore:4286

clang++ -m64 -Wno-deprecated-declarations -O3 -std=c++23 -Izlib/include -static -fms-runtime-lib=static -fno-exceptions -c hash2str.cpp -o hash2str.obj -D_MT
clang-cl hash2str.obj /Fehash2str.exe /MT /link /nodefaultlib:msvcrt.lib /nodefaultlib:ucrt.lib libcmt.lib libvcruntime.lib libucrt.lib /ignore:4217 /ignore:4286
