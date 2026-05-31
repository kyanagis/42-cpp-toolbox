#include <thread>

static long counter = 0;

static void bump() {
    for (int i = 0; i < 100000; ++i) ++counter;
}

int main() {
    std::thread a(bump), b(bump);
    a.join();
    b.join();
    return static_cast<int>(counter & 1);
}
