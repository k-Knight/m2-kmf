cmake_minimum_required(VERSION 3.15)

set(TARGET m2_mod_settings)

file(GLOB SRC_FILES "${CMAKE_CURRENT_LIST_DIR}/*.cpp" "${CMAKE_CURRENT_LIST_DIR}/*.hpp" "${CMAKE_CURRENT_LIST_DIR}/*.h")

if (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    enable_language("RC")
    file(GLOB WIN32_RESOURCES "${CMAKE_CURRENT_LIST_DIR}/*.rc")
endif()

add_executable(${TARGET} ${SRC_FILES} ${WIN32_RESOURCES})

target_include_directories(${TARGET} PUBLIC
    ${CMAKE_SOURCE_DIR}/../bin/$<$<CONFIG:Release>:Release>$<$<CONFIG:Debug>:Debug>
    ${CMAKE_SOURCE_DIR}/kmf_util/
    ${CMAKE_SOURCE_DIR}/../libs/wx/include
    ${CMAKE_SOURCE_DIR}/../libs/wx/include/msvc
)

target_link_directories(${TARGET} PUBLIC
    ${CMAKE_SOURCE_DIR}/../libs/wx/lib/vc_lib
    ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/$<$<CONFIG:Release>:Release>$<$<CONFIG:Debug>:Debug>
)

target_link_libraries(${TARGET} PUBLIC
    kmf_util.lib
)

target_compile_options(${TARGET} PUBLIC
)

target_link_options(${TARGET} PUBLIC
    -Wl,/SUBSYSTEM:$<$<CONFIG:Release>:WINDOWS>$<$<CONFIG:Debug>:CONSOLE>
)

add_custom_command(
    TARGET ${TARGET}  POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
        \"${CMAKE_SOURCE_DIR}/../graphics/mem_resources/data.ifa\"
        \"${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$<$<CONFIG:Release>:Release>$<$<CONFIG:Debug>:Debug>\"
)
