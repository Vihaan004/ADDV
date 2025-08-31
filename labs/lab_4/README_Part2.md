# Lab 4 - Part 2: DPI-Based FIFO Verification

## Overview
This directory contains the DPI-based verification setup for the asynchronous FIFO design from Lab 1.

## Files Description

### Design Files (from Lab 1):
- `async_fifo_top.sv` - Top-level asynchronous FIFO module
- `fifomem_module.sv` - FIFO memory module (with bug injection capability)
- `sync_modules.sv` - Clock domain crossing synchronizers  
- `rptr_empty_module.sv` - Read pointer and empty flag generation
- `wptr_full_module.sv` - Write pointer and full flag generation

### Verification Files:
- `dpi.c` - C golden reference model with FIFO functions
- `fifo_dpi_testbench.sv` - SystemVerilog testbench with DPI checker
- `Makefile` - Build and simulation targets

## C Golden Reference Model

The C model (`dpi.c`) implements a software-based FIFO with the following functions:

### Key Functions:
- `fifo_init()` - Initialize FIFO state
- `fifo_push(data)` - Push data, returns 1 if successful, 0 if full
- `fifo_pop()` - Pop data, returns data if successful, -1 if empty  
- `fifo_is_empty()` - Returns 1 if empty, 0 otherwise
- `fifo_is_full()` - Returns 1 if full, 0 otherwise
- `fifo_get_count()` - Returns current FIFO occupancy

### State Management:
- Uses 2D array `fifo_data[FIFO_DEPTH]` for data storage
- Integer counters for `write_ptr`, `read_ptr`, and `count`
- Maintains FIFO ordering and capacity limits

## SystemVerilog Checker Module

The `fifo_checker` module in `fifo_dpi_testbench.sv` implements:

### Checking Strategy:
1. **Write Verification**: When `winc` is asserted, calls C `fifo_push()` with same data
2. **Read Verification**: When `rinc` is asserted, calls C `fifo_pop()` and compares with DUT `rdata`
3. **Flag Verification**: Continuously compares DUT `wfull`/`rempty` with C model `fifo_is_full()`/`fifo_is_empty()`
4. **Mismatch Detection**: Uses `$error` for mismatches, `$display` for successful checks

## Bug Injection

### Plusarg Control:
- `+inject_bug` - Enable bug injection mode
- `+bug_drop_every=N` - Drop every Nth write operation (default N=3)
- `+no_bug` - Disable bug injection (normal operation)

### Bug Implementation:
- Located in `fifomem_module.sv`
- Drops every Nth write operation by not storing data in memory
- C model continues to track expected behavior
- Checker detects mismatches when DUT has missing data

## Running Simulations

### Compilation and Execution:
```bash
# Normal operation (no bugs)
make run_normal

# With bug injection (drops every 3rd write)
make run_with_bug

# With waveform generation
make run_waves

# Clean up
make clean
```

### Expected Behavior:
- **Normal Mode**: All checks should pass, no error messages
- **Bug Mode**: Checker should detect and report data mismatches via `$error`

## Test Scenarios Covered

1. **Sequential Write/Read Operations**
2. **Fill FIFO to Capacity** 
3. **Empty FIFO Completely**
4. **Write to Full FIFO (blocked)**
5. **Read from Empty FIFO (blocked)**
6. **Concurrent Write/Read Operations**
7. **Flag Verification** (wfull, rempty)

The testbench provides comprehensive coverage of FIFO functionality while demonstrating the effectiveness of the DPI-based golden reference model approach.
