@echo off
del /f ".\.cmake_cache\CMakeFiles\installer.dir\Debug\resource.rc.res"
del /f ".\.cmake_cache\CMakeFiles\installer.dir\Release\resource.rc.res"
for /f "delims=" %%i in ('"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath') do set vs_path=%%i
call "%vs_path%\VC\Auxiliary\Build\vcvarsall.bat" x86
cmake --build .cmake_cache --config %*