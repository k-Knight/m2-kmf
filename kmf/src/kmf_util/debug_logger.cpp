#include "debug_logger.hpp"

#if defined(DEBUG) || defined(_DEBUG)
#include <stdio.h>
#include <fstream>
#include <stdarg.h>
#include <mutex>
#include <filesystem>

std::ofstream debug_log;
char *reusable_buffer;
size_t buffer_size;
std::mutex debug_log_mutex;
#endif //DEBUG

void debug_log_init(std::filesystem::path path) {
#if defined(DEBUG) || defined(_DEBUG)
    debug_log = std::ofstream(path);
    reusable_buffer = NULL;
    buffer_size = 0;
#endif //DEBUG
}

void debug_write(const char *format, ...)
{
#if defined(DEBUG) || defined(_DEBUG)
    std::unique_lock<std::mutex> lock(debug_log_mutex);

    va_list args;
    va_start(args, format);

    size_t needed = vsnprintf(NULL, 0, format, args) + 1;

    if (needed > buffer_size) {
        reusable_buffer = (char *)realloc(reusable_buffer, needed);

        if (reusable_buffer == NULL) {
            debug_log.write("realloc could not allocated memory\n", 35);
            debug_log.flush();
            std::terminate();
        }

        buffer_size = needed;
    }

    vsnprintf(reusable_buffer, needed, format, args);

    va_end(args);

    printf("%s", reusable_buffer);
    debug_log.write(reusable_buffer, needed - 1);
    debug_log.flush();
#endif //DEBUG
}