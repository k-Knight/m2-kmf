#ifndef KMF_DEBUG_LOGGER
#define KMF_DEBUG_LOGGER

#include <filesystem>

#if defined(DEBUG) || defined(_DEBUG)
#include <fstream>
#include <mutex>

struct debug_logger_state_t {
    bool initialzed = false;
    std::ofstream debug_log;
    char *reusable_buffer;
    size_t buffer_size;
    std::mutex debug_log_mutex;
};
#endif //DEBUG

void debug_log_init(std::filesystem::path path);
void debug_write(const char *format, ...);

#endif //KMF_DEBUG_LOGGER