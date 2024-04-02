cmake_minimum_required(VERSION 3.15)

set(TARGET kmf_util)

file(GLOB SRC_FILES "${CMAKE_CURRENT_LIST_DIR}/*.cpp" "${CMAKE_CURRENT_LIST_DIR}/*.hpp")

add_library(${TARGET} ${SRC_FILES})

target_include_directories(${TARGET} PUBLIC
    ${CMAKE_SOURCE_DIR}/../libs/steamapi
)

target_link_directories(${TARGET} PUBLIC
)

target_link_libraries(${TARGET} PUBLIC
)

target_compile_options(${TARGET} PUBLIC
)

target_link_options(${TARGET} PUBLIC
    -Wl,/SUBSYSTEM:WINDOWS
)