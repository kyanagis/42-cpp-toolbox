#include <stdlib.h>

int deref(int *p) {
    return *p;
}

int main(void) {
    int *p = NULL;
    if (rand() == 42) p = malloc(sizeof(int));
    return deref(p);
}
