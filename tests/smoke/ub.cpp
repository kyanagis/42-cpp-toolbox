#include <climits>

int main(int argc, char**) {
    int x = INT_MAX;
    x += argc;
    return x;
}
