cmake_minimum_required(VERSION 3.15)

set(TARGET sdl_gamepad_listener)

file(GLOB SRC_FILES "${CMAKE_CURRENT_LIST_DIR}/*.cpp")

add_executable(${TARGET} ${SRC_FILES})

target_include_directories(${TARGET} PUBLIC
    ${CMAKE_SOURCE_DIR}/../libs/sdl/include
)

target_link_directories(${TARGET} PUBLIC
    ${CMAKE_SOURCE_DIR}/../libs/sdl/lib/x86
)

target_link_libraries(${TARGET} PUBLIC
    SDL2.lib
)

target_compile_options(${TARGET} PUBLIC
)

target_link_options(${TARGET} PUBLIC
    -Wl,/SUBSYSTEM:WINDOWS
)

add_custom_command(
    TARGET ${TARGET}  POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
        \"${CMAKE_SOURCE_DIR}/../libs/sdl/lib/x86/SDL2.dll\"
        \"${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<$<CONFIG:Release>:Release>$<$<CONFIG:Debug>:Debug>\"
)
