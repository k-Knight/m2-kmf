#include "debug_logger.hpp"

#if defined(DEBUG) || defined(_DEBUG)
#include <filesystem>
#include <stdio.h>
#include <stdarg.h>

extern debug_logger_state_t debug_logger_state;
#endif //DEBUG


void debug_log_init(std::filesystem::path path) {
#if defined(DEBUG) || defined(_DEBUG)
    debug_logger_state.debug_log = std::ofstream(path);
    debug_logger_state.reusable_buffer = NULL;
    debug_logger_state.buffer_size = 0;
#endif //DEBUG
}

void debug_write(const char *format, ...)
{
#if defined(DEBUG) || defined(_DEBUG)
    std::unique_lock<std::mutex> lock(debug_logger_state.debug_log_mutex);

    va_list args;
    va_start(args, format);

    size_t needed = vsnprintf(NULL, 0, format, args) + 1;

    if (needed > debug_logger_state.buffer_size) {
        debug_logger_state.reusable_buffer = (char *)realloc(debug_logger_state.reusable_buffer, needed);

        if (debug_logger_state.reusable_buffer == NULL) {
            debug_logger_state.debug_log.write("realloc could not allocated memory\n", 35);
            debug_logger_state.debug_log.flush();
            std::terminate();
        }

        debug_logger_state.buffer_size = needed;
    }

    vsnprintf(debug_logger_state.reusable_buffer, needed, format, args);

    va_end(args);

    printf("%s", debug_logger_state.reusable_buffer);
    debug_logger_state.debug_log.seekp(0, std::ios::end);
    debug_logger_state.debug_log.write(debug_logger_state.reusable_buffer, needed - 1);
    debug_logger_state.debug_log.flush();
#endif //DEBUG
}