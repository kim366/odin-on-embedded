#include <zephyr/kernel.h>

void odin_k_panic() {
  k_panic();  
}

void main(void) {
    void odin_main(void);
    odin_main();
}
