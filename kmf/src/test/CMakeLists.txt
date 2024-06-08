cmake_minimum_required(VERSION 3.15)

set(TARGET test)

file(GLOB SRC_FILES "${CMAKE_CURRENT_LIST_DIR}/*.cpp" "${CMAKE_CURRENT_LIST_DIR}/*.hpp" "${CMAKE_CURRENT_LIST_DIR}/*.h")

add_executable(${TARGET} ${SRC_FILES} ${WIN32_RESOURCES})

target_include_directories(${TARGET} PUBLIC
    ${CMAKE_SOURCE_DIR}/../bin/$<$<CONFIG:Release>:Release>$<$<CONFIG:Debug>:Debug>
    ${CMAKE_SOURCE_DIR}/kmf_util/
)

target_link_directories(${TARGET} PUBLIC
    ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/$<$<CONFIG:Release>:Release>$<$<CONFIG:Debug>:Debug>
)

target_link_libraries(${TARGET} PUBLIC
    kmf_util.lib
)

target_compile_options(${TARGET} PUBLIC
)

target_link_options(${TARGET} PUBLIC
    -Wl,/SUBSYSTEM:CONSOLE
)