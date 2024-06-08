#ifndef KMF_DEBUG_LOGGER
#define KMF_DEBUG_LOGGER

#include <filesystem>

void debug_log_init(std::filesystem::path path);
void debug_write(const char *format, ...);

#endif //KMF_DEBUG_LOGGER