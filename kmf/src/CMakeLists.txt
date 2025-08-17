cmake_minimum_required(VERSION 3.15)

project(kmf)

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

set(CMAKE_CXX_STANDARD 23)

include(CheckIPOSupported)
check_ipo_supported(RESULT supported OUTPUT error)

include_directories(BEFORE
    common
)

add_compile_options(
    -target i686-pc-windows-msvc
    -m32
    -static
    $<$<CONFIG:Release>:-O3>
    $<$<CONFIG:Debug>:-O0>
    -DUNICODE
    -D_UNICODE
    -D_CRT_SECURE_NO_WARNINGS
    $<$<CONFIG:Debug>:-fms-runtime-lib=static_dbg>
)

add_link_options(
    -m32
    -static
    $<$<CONFIG:Release>:-O3>
    $<$<CONFIG:Debug>:-O0>
)

add_subdirectory(attacher)
add_subdirectory(sdl_gamepad_listener)
add_subdirectory(kmf_util)
add_subdirectory(m2_mod_settings)
add_subdirectory(test)

add_dependencies(kmf_util sdl_gamepad_listener)
add_dependencies(m2_mod_settings kmf_util)
add_dependencies(test m2_mod_settings kmf_util)

get_all_targets(all_targets ".")

set_target_properties(${all_targets} PROPERTIES
    MSVC_RUNTIME_LIBRARY $<IF:$<CONFIG:Release>,MultiThreaded,MultiThreadedDebug>
)

if( supported )
    message(STATUS "IPO / LTO enabled")
    set_target_properties(${all_targets} PROPERTIES
        INTERPROCEDURAL_OPTIMIZATION TRUE
    )
else()
    message(STATUS "IPO / LTO not supported: <${error}>")
endif()
