cmake_minimum_required(VERSION 3.15)

project(installer)

function(get_all_targets _result _dir)
    get_property(_subdirs DIRECTORY "${_dir}" PROPERTY SUBDIRECTORIES)
    foreach(_subdir IN LISTS _subdirs)
        get_all_targets(${_result} "${_subdir}")
    endforeach()
    get_property(_sub_targets DIRECTORY "${_dir}" PROPERTY BUILDSYSTEM_TARGETS)
    set(${_result} ${${_result}} ${_sub_targets} PARENT_SCOPE)
endfunction()

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY  "${CMAKE_CURRENT_LIST_DIR}/../bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY  "${CMAKE_CURRENT_LIST_DIR}/../bin")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}/../bin")
set(BUILD_SHARED_LIBS TRUE)

set(CMAKE_CXX_STANDARD 17)

include(CheckIPOSupported)
check_ipo_supported(RESULT supported OUTPUT error)

add_compile_options(
    -target i686-pc-windows-msvc
    -m32
    -static
    -O3
    -DUNICODE
    -D_UNICODE
    -D_CRT_SECURE_NO_WARNINGS
    $<$<CONFIG:Debug>:-fms-runtime-lib=static_dbg>
    $<$<CONFIG:Release>:-fms-runtime-lib=static>
)

add_link_options(
    -m32
    -static
    -O3
    -municode
    $<$<CONFIG:Debug>:-fms-runtime-lib=static_dbg>
    $<$<CONFIG:Release>:-fms-runtime-lib=static>
)

include_directories(
    "../libs/zstd/include"
)

link_directories(
    "../libs/zstd/lib"
)

link_libraries(
    libzstd_static.lib
)

if (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    enable_language("RC")
endif()

add_executable(packager packager.cpp ifa.cpp ifa.hpp clipp.hpp util.hpp util.cpp)
add_custom_target(build_ifa
    COMMAND "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>/packager.exe"
        -i "${CMAKE_CURRENT_LIST_DIR}/../files_to_install"
        -o "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/data.ifa"
        -m 0x2AEB8536C2BAD540
        -c
)
add_executable(installer installer.cpp ifa.cpp ifa.hpp resource.h resource.rc search_win.cpp search_win.hpp  util.hpp util.cpp)

add_dependencies(build_ifa packager)
add_dependencies(installer build_ifa)

get_all_targets(all_targets ".")

set_target_properties(${all_targets} PROPERTIES
    MSVC_RUNTIME_LIBRARY $<IF:$<CONFIG:Release>,MultiThreaded,MultiThreadedDebug>
)

target_link_options(packager PUBLIC
    -Wl,/ignore:4099
    -Wl,/SUBSYSTEM:CONSOLE
)

target_link_options(installer PUBLIC
    -Wl,/ignore:4099
    -Wl,/SUBSYSTEM:$<IF:$<CONFIG:Release>,WINDOWS,CONSOLE>
)

target_link_libraries(installer
    Comctl32.lib
)

if(supported)
    message(STATUS "IPO / LTO enabled")
    set_target_properties(${all_targets} PROPERTIES
        INTERPROCEDURAL_OPTIMIZATION TRUE
    )
else()
    message(STATUS "IPO / LTO not supported: <${error}>")
endif()
