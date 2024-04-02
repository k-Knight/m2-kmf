cmake_minimum_required(VERSION 3.15)

set(TARGET attacher)

file(GLOB SRC_FILES "${CMAKE_CURRENT_LIST_DIR}/*.cpp")

add_library(${TARGET} ${SRC_FILES})

target_include_directories(${TARGET} PUBLIC
)

target_link_directories(${TARGET} PUBLIC
)

target_link_libraries(${TARGET} PUBLIC
    Shlwapi.lib
)

target_compile_options(${TARGET} PUBLIC
)

target_link_options(${TARGET} PUBLIC
    -Wl,/SUBSYSTEM:WINDOWS
)