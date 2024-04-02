#include <string>
#include <sstream>
#include <stacktrace>

std::string get_stacktrace() {
    std::stringstream buffer;
    buffer << std::stacktrace::current() << std::endl;

    return buffer.str();
}
