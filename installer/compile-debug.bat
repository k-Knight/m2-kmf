@echo off
del /f ".\.cmake_cache\CMakeFiles\installer.dir\Release\resource.rc.res"
del /f ".\bin\data.ifa"

rmdir files_to_install
mklink /j files_to_install files_to_install_m2_debug

for /f "delims=" %%i in ('"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath') do set vs_path=%%i
call "%vs_path%\VC\Auxiliary\Build\vcvarsall.bat" x86
cmake --build .cmake_cache --config Release %*

del /f ".\bin\installer_debug.exe"
copy /b ".\bin\Release\installer.exe" ".\bin\installer_debug.exe"
