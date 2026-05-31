#include <cstring>

int main() {
    char* buf = new char[8];
    std::strcpy(buf, "0123456789");
    return buf[0];
}
