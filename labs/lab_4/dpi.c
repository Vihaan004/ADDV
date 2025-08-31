#include <stdio.h>

// FIFO Golden Model Parameters
#define FIFO_DEPTH 16  // 2^4 = 16 (ASIZE=4)
#define DATA_WIDTH 8   // DSIZE=8

// FIFO Golden Model State
static int fifo_data[FIFO_DEPTH];
static int write_ptr = 0;
static int read_ptr = 0;
static int count = 0;

// Initialize the FIFO model
void fifo_init() {
    write_ptr = 0;
    read_ptr = 0;
    count = 0;
    for (int i = 0; i < FIFO_DEPTH; i++) {
        fifo_data[i] = 0;
    }
    printf("FIFO Golden Model Initialized\n");
}

// Push data into FIFO (returns 1 if successful, 0 if full)
int fifo_push(int data) {
    if (count >= FIFO_DEPTH) {
        printf("C Model: FIFO Full, cannot push data=0x%02x\n", data);
        return 0;  // FIFO full
    }
    
    fifo_data[write_ptr] = data & 0xFF;  // Mask to 8 bits
    write_ptr = (write_ptr + 1) % FIFO_DEPTH;
    count++;
    printf("C Model: Pushed data=0x%02x, count=%d, wptr=%d\n", data & 0xFF, count, write_ptr);
    return 1;  // Success
}

// Pop data from FIFO (returns data if successful, -1 if empty)
int fifo_pop() {
    if (count <= 0) {
        printf("C Model: FIFO Empty, cannot pop\n");
        return -1;  // FIFO empty
    }
    
    int data = fifo_data[read_ptr];
    read_ptr = (read_ptr + 1) % FIFO_DEPTH;
    count--;
    printf("C Model: Popped data=0x%02x, count=%d, rptr=%d\n", data, count, read_ptr);
    return data;
}

// Check if FIFO is empty
int fifo_is_empty() {
    return (count == 0) ? 1 : 0;
}

// Check if FIFO is full
int fifo_is_full() {
    return (count >= FIFO_DEPTH) ? 1 : 0;
}

// Get current FIFO count
int fifo_get_count() {
    return count;
}

// Original add function (keeping for reference)
int add(int a, int b) {
    return a+b;
}