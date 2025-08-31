# Lab 4 - Part 1: FIFO Verification Plan

## 1. Testbench Architecture and Strategy

### Testbench Block Diagram
```
                    ┌─────────────┐
                    │   Coverage  │
                    └──────┬──────┘
                           │
    ┌───────────────────────┼───────────────────────┐
    │                       │                       │
    │  ┌──────────┐    ┌─────▼──────┐    ┌──────────┐  │
    │  │  Write   │    │   Checker/ │    │   Read   │  │
    │  │ Monitor  │◄───┤ Scoreboard │───►│ Monitor  │  │
    │  └──────────┘    └────────────┘    └──────────┘  │
    │       ▲                                     ▲     │
    │       │                                     │     │
    │  ┌────┴─────┐    ┌─────────────┐    ┌─────┴────┐ │
    │  │  Write   │◄───┤    ASYNC    │───►│   Read   │ │
    │  │ Driver   │    │    FIFO     │    │  Driver  │ │
    │  │          │    │    (DUT)    │    │          │ │
    │  └──────────┘    └─────────────┘    └──────────┘ │
    │       ▲                                     ▲     │
    │       │                                     │     │
    │  ┌────┴─────┐                        ┌─────┴────┐ │
    │  │  Write   │                        │   Read   │ │
    │  │ Stimulus │                        │ Stimulus │ │
    │  └──────────┘                        └──────────┘ │
    └───────────────────────────────────────────────────┘
                    ┌─────────────┐
                    │ Assertions  │
                    └─────────────┘
```

### Key Components:
- **DUT (Design Under Test)**: Asynchronous FIFO with separate read/write clock domains
- **Write Driver**: Generates write transactions (wdata, winc) on write clock domain
- **Read Driver**: Generates read transactions (rinc) on read clock domain  
- **Write Monitor**: Captures write-side signals and creates write transactions
- **Read Monitor**: Captures read-side signals and creates read transactions
- **Checker/Scoreboard**: Contains reference model to verify FIFO behavior
- **Coverage**: Tracks functional coverage metrics
- **Assertions**: Real-time property checking using SVA

### High-Level Methodology:
- **Primary Method**: Constrained-random simulation with directed tests
- **Secondary Method**: Formal verification for key properties (optional)
- **Reference Model**: Software-based golden model (C/C++ or SystemVerilog)

### Sign-off Metrics:
- **Functional Coverage**: 100% of defined coverpoints hit
- **Code Coverage**: >95% line/branch coverage
- **Assertion Coverage**: 100% of assertions exercised
- **Bug Detection**: All injected bugs detected by checkers

## 2. Stimulus and Coverage Plan

### Test Scenarios and Boundary Conditions:

#### Basic Functionality Tests:
1. **Single Write/Read Operations**
   - Write single data item to empty FIFO
   - Read single data item from FIFO with one item
   - Verify data integrity (write data matches read data)

2. **Sequential Operations**
   - Write multiple items sequentially
   - Read multiple items sequentially
   - Mixed write/read operations

#### Boundary/Corner Cases:
1. **FIFO Full Conditions**
   - Fill FIFO to maximum capacity (2^ASIZE items)
   - Attempt to write when FIFO is full (verify wfull assertion)
   - Write right at the edge of becoming full
   - Verify almost_full flag behavior

2. **FIFO Empty Conditions**
   - Read from completely empty FIFO
   - Attempt to read when FIFO is empty (verify rempty assertion)
   - Read right at the edge of becoming empty
   - Verify almost_empty flag behavior

3. **Clock Domain Crossing Tests**
   - Different write/read clock frequencies (wclk faster than rclk)
   - Different write/read clock frequencies (rclk faster than wclk)
   - Same frequency but different phase relationships
   - Clock ratio variations (2:1, 1:2, 3:1, etc.)

4. **Reset Scenarios**
   - Write domain reset during active write operations
   - Read domain reset during active read operations  
   - Simultaneous reset of both domains
   - Reset recovery verification

5. **Concurrent Operations**
   - Simultaneous write and read operations
   - High-frequency concurrent operations
   - Burst write followed by burst read
   - Interleaved write/read patterns

6. **Stress Tests**
   - Back-to-back write operations until full
   - Back-to-back read operations until empty
   - Continuous write/read operations for extended periods
   - Random delays between operations

#### Coverage Points:
- **Control Signal Coverage**: winc, rinc, wfull, rempty, almost_full, almost_empty
- **Data Pattern Coverage**: All 0s, all 1s, alternating patterns, random data
- **FIFO Depth Coverage**: Empty, quarter-full, half-full, three-quarter-full, full
- **Clock Edge Coverage**: Rising/falling edges of wclk and rclk
- **Cross Coverage**: Control signals vs FIFO occupancy levels

## 3. Checking Plan

### List of Checks to Perform:

#### Data Integrity Checks:
1. **FIFO Ordering Check**
   - Verify data is read in the same order it was written (FIFO behavior)
   - Compare expected vs actual read data using reference model

2. **Data Corruption Check**
   - Ensure written data matches read data bit-by-bit
   - Verify no data modification during storage

#### Control Signal Checks:
3. **Full Flag Verification**
   - Check wfull assertion when FIFO reaches maximum capacity
   - Verify wfull de-assertion when space becomes available
   - Verify almost_full flag timing

4. **Empty Flag Verification**
   - Check rempty assertion when FIFO becomes empty
   - Verify rempty de-assertion when data is written
   - Verify almost_empty flag timing

5. **Write Enable Checking**
   - Verify no write occurs when wfull is asserted and winc is high
   - Check write pointer doesn't advance when write is blocked

6. **Read Enable Checking**
   - Verify no read occurs when rempty is asserted and rinc is high
   - Check read pointer doesn't advance when read is blocked

#### Pointer and Address Checks:
7. **Write Pointer Verification**
   - Monitor write pointer advancement on valid writes
   - Verify write pointer wraps correctly at FIFO boundary
   - Check write pointer synchronization across clock domains

8. **Read Pointer Verification**
   - Monitor read pointer advancement on valid reads
   - Verify read pointer wraps correctly at FIFO boundary  
   - Check read pointer synchronization across clock domains

9. **Occupancy Level Checking**
   - Calculate and verify current FIFO occupancy level
   - Cross-check with almost_full/almost_empty assertions

#### Reset and Initialization Checks:
10. **Reset Behavior Verification**
    - Verify all pointers reset to initial values
    - Check all flags reset to correct states (empty=1, full=0)
    - Verify proper reset synchronization in both clock domains

#### Timing and Protocol Checks:
11. **Setup/Hold Time Verification**
    - Check data setup and hold times relative to clock edges
    - Verify control signal timing requirements

12. **Clock Domain Crossing Verification**
    - Verify proper synchronization of pointers between domains
    - Check for metastability issues (through extended simulation)

#### Error Injection Checks:
13. **Fault Detection Capability**
    - Inject known bugs (data corruption, pointer errors)
    - Verify checker detects and reports all injected faults
    - Test checker's ability to catch boundary condition violations

### Checking Methods:
- **Real-time Checking**: Using SystemVerilog assertions (SVA) for immediate violation detection
- **Scoreboard Checking**: Transaction-level checking using reference model comparison
- **Self-Checking**: DUT internal consistency checks through monitors
- **Coverage-Driven Checking**: Ensure all defined scenarios are verified
