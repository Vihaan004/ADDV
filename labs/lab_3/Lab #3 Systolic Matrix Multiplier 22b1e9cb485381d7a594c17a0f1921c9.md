# Lab #3: Systolic Matrix Multiplier

In this lab, you will be designing a 4x4 systolic matrix multiplier with a floating-point processing element and an APB interface.

---

### Code and documents for reference:

- Floating-point Multiplier: https://github.com/fbrosser/DSP48E1-FP/tree/master/src/FPMult
- Floating-point Adder: https://github.com/fbrosser/DSP48E1-FP/tree/master/src/FP_AddSub
- APB specification: [AMBA APB 2.0 Protocol](https://developer.arm.com/documentation/ihi0024/b) (Focus sections: 4.1, 3.1, 2.1, 2.2)
- APB Verilog code examples:
    - https://github.com/maomran/APB-Slave/tree/master
    - https://electrobinary.blogspot.com/2020/06/csr-register-operations-using-apb.html
    - https://logicmadness.com/apb-protocol/

---

## Part #1: Floating-point arithmetic units

This part focuses on creating the main computational block (processing element) for the accelerator.

You will use an 8-bit floating point format, which we call **FP8,** with the following notation**:** `e3m4` ****

- `e3m4` format has 1 sign bit, 3 exponent bits, and 4 mantissa bits.
- There is an implicit leading bit of the fraction/significand that is not stored.
- The exponent bias will be 2^(3-1)-1 = 2^2-1 = **3**

### **Tasks:**

1. Design modifications:
    1. Use the code referenced above, which is in FP32 format. You will need to convert it to support the FP8 format
    2. The referenced design is pipelined; you will need to remove the pipeline registers to make it a combinational design.
2. Arithmetic requirements:
    1. You do **not** need to support denormalized numbers.
    2. Your designs **must** support normalized numbers and correctly handle special values: zeros, infinities, and NaNs.
    3. You can choose any rounding method you prefer. See what method the provided code uses.
3. Simulation and Verification:
    1. Create a testbench to verify your FP8 adder and multiplier. A few test cases for each operation (like adding two positive numbers, multiplying by zero, operation resulting in infinity) are sufficient.

<aside>
💡

**Note that:**

- An FP8 number multiplied with an FP8 number should result in an FP8 number (This is unlike integer multiplication where an 8-bit number multiplied by an 8-bit number results in a 16-bit number). In the code we've provided, there is some logic to truncate bits outside of the multiplier. That logic will not be needed in the FP case because the multiplier’s output itself will be 8 bit wide.
- The designs shown in the floating-point lecture were multi-cycle. But your designs should be single-cycle.
</aside>

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Deliverables for Part I:** (50 points)

1. FP8 representation table: Create a table showing the value ranges and representations FP8 (e3m4) format for the following:
    1. Zeros, Infinities, NaNs
    2. Positive and negative normalized values
    3. Positive and negative denormalized values
2. A brief description of your FP8 adder and multiplier designs. Mention the rounding method used.
3. Simulation waveforms verifying the functionality of your FP8 adder and multiplier. (Make sure your screenshot clearly shows all the different cases in your testbench)
4. Zip file:
    1. All the SystemVerilog design and testbench files, Makefiles(if used), README file
</aside>

---

## Part #2: Updates to the systolic matrix multiplier

In this part, you will integrate the FP8 arithmetic blocks designed in Part I into a systolic array design provided and add a standard APB control interface.

Verilog code and testbench for a 4x4 Systolic array using 8-bit integer MACs is provided at  `/usr/local2/COURSES/ADDV/LAB3` on the Apporto server. Contents of this directory are shown below: 

```markdown
Lab3/
├── matmul.v                # 4x4 Systolic Array based matrix multiplier
├── matmul_with_ram.v       # Top module with control logic and memory blocks 
├── matmul_with_ram_tb.v    # Testbench
├── apb_slave.v             # Partial code for an APB slace
└── example_tb.v            # Partial testbench showing APB read and write tasks
```

- An overview of the architecture and the code was provided in the lecture.
- Note the control interface and the data interfaces in the design.

### **Tasks:**

1. Use SystemVerilog Syntax:
    - There are no specific requirements like interfaces or enums. Points will only be deducted if **no** SystemVerilog syntax is observed.
2. Replace Integer MAC with FP8 MAC:
    1. Replace the existing MAC with an FP8 MAC. That essentially means replacing the adder in seq_mac (that currently is inferred from the + operator) with the FP8 adder designed in Part I and multiplier in seq_mac (that currently is inferred from the * operator) with the FP8 multiplier designed in Part I.
    2. The existing integer units do not have exception flags. Your floating-point units do. When you instantiate the floating-point units in the MAC, create a logical OR of the flags coming out of the adder and the multiplier. Then create a logical OR of the exception flags coming out of all the MACs/PEs in the array. Add a new output of the systolic matrix multiplier block that will be driven by this combined flag signal.
3. Add APB control interface:
    1. Think of your matrix multiplier as an accelerator in a larger System-on-Chip (SoC). The CPU in the SoC needs to control/observe this accelerator. So, we want to have an APB interface (a standardized protocol from ARM) on it so that it can be easily integrated into any SoC.
    2. There is a simple control FSM in the matmul_with_ram.v file. You will need to replace this with a new piece of control logic - APB slave logic. Example of APB code is provided with the lab. (file `apb_slave.v`) You can also look at the “Code and documents for reference” section above.
    3. **APB Signals:** Add the following APB signals to the top-level of your matrix multiplier design. Assume that each register is **16-bit wide,**  APB interface width will be 16 bits. (`PWDATA`, `PRDATA`). You can read the APB specification in the link provided in the “Code and documents for reference” section above.  
        
        `PCLK`, `PRESETn`, `PADDR`, `PWRITE`, `PSEL`, `PENABLE`, `PWDATA`, `PRDATA`, `PREADY`
        
    4. Your top-level design will have an APB interface now (that will replace the control and status signals listed below). Your APB slave logic can always keep `PREADY` asserted. 
    5. **Control/Status Registers (CSRs):** The following signals of the matrix multiplier will be controlled and observed via the APB interface. 
        - Control Signals (CPU writes to these): `start`, `address_mat_a`, `address_mat_b`, `address_mat_c`, `address_stride_a`, `address_stride_b`, `address_stride_c`.
        - **Status Signals (CPU reads from these):** `done`, `flags`.
        - You can choose a register map as you like. That is, you can choose to have multiple of these signals in one register or have separate registers for each signal.
    6. **Simulation and Verification:**
        1. To perform a matrix multiplication operation using this new design, you will have to “write” into the registers. You will first write the addresses, strides, and then write the “start” register. After that, you will poll for “done” by reading the “done” register.
        2. We have provided APB read and write tasks in a file (`example_tb.v`) to configure the registers. Please use those to write/read values into/from registers in the APB slave.
        3. You will also need to provide FP8 values for the input matrices in the testbench. You can generate the expected value of the output matrix by using a regular calculator. Just one set of input matrices with some random FP8 values is enough.
    7. **Synthesis:**
        1. Synthesize both the baseline integer design and your new FP8 design.  **Only synthesize the matmul_4x4_systolic module** (i.e. the file matmul.v). Do not use the top-level module (with the control logic and memories) for synthesis.

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Deliverables for Part II:** (50 points)

1. A brief description of the changes made to provided design, including how you integrated the FP8 MAC, handled the exception flags, and introduced the APB interface.
2. A brief description of the APB register map implemented.
3. Simulation waveforms showing APB write/read transactions to configure and run the multiplier, and showing the `done` flag assertion upon completion.
4. A table comparing the synthesis results (Area, Frequency) of the baseline integer design vs. new FP8 design.
5. Zip file:
    1. All the SystemVerilog design and testbench files, Makefiles(if used), README file
</aside>

---

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Extra Credit:** (10 points**)**

1. Include both INT8 and FP8 processing elements in the design and provide a signal to select between these two modes. Control this signal through a bit in a register that can be configured using the APB interface.
2. A microarchitecture diagram showing how a larger 8x8 matmul can be created using four 4x4 matmuls. Design and verification are not required. Show all the signal connections clearly.
</aside>

---

### Lab demo:

Schedule a 5-minute demo using the link, and include a screenshot of the schedule confirmation in the report: 

Slots are available from 5-6:30PM on June 12th, Thursday and 3-4:30PM on June 13th, Friday.

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

5 points will be deducted from the total score obtained for every incorrect answer during the demo.

</aside>