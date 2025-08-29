# Lab #2: MIPS Processor Design

## Materials to review MIPS processor concepts

1. Book chapter (recommended)
    
    [Chapter-7---Microarchitecture_2007_Digital-Design-and-Computer-Architecture.pdf](https://arizonastateu-my.sharepoint.com/:b:/g/personal/aaror112_asurite_asu_edu/EZIbukE93TdCvH3YI9w1puQBaCvOKtaqREuOTARaI5u-QQ?e=7eT81i)
    
2. Videos (optional)

| **David Blask-Schafer** |  https://www.youtube.com/watch?v=0SVAcqgMzJc |
| --- | --- |
| **Padraic Edginton** |   https://www.youtube.com/playlist?list=PL1C2GgOjAF-KFxGFauGAF3wOjYbmezNG0 |
| **NPTEL** | https://youtu.be/CiTkP_HWi-8?si=4m9nmpXt6V9Ma-8C,  https://www.youtube.com/watch?v=erBW3qRXWKY&list=PLJ5C_6qdAvBELELTSPgzYkQg3HgclQh-5&index=38, https://www.youtube.com/watch?v=aDonbRsdO9s&list=PLJ5C_6qdAvBELELTSPgzYkQg3HgclQh-5&index=39 → Has Verilog coding |
1. Blog and code (recommended)
    - https://medium.com/@LambdaMamba/building-a-mips-5-stage-pipeline-processor-in-verilog-6d627a31127c
    - https://github.com/LambdaMamba/FPGAprojects/tree/main/PIPELINE_CPU

<aside>
💡

This code is pretty comprehensive and similar to what we’re asking you to do in this lab. So, you can use this code as a reference. Please walk through this code to understand it.

</aside>

---

## Part #1: Pipelined Processor

Verilog code and testbench for a non-pipelined MIPS processor are provided at  `/usr/local2/COURSES/ADDV/LAB2` on the Apporto server. Contents of this directory are shown below: 

```markdown
Lab2/
├── testbench.v               # Testbench
├── top.v                     # Top level design instance
├── controller.v              # Controller 
├── datapath.v                # Data path
├── top_with_sram.v           # Alternative top level design, uses memory cells for imem and dmem
├── compile_with_sram.tcl     # Synthesis script to map memories to memory cells
└── sram_32x64/
    ├── SRAM_32x64_1rw.db     # SRAM library for synthesis
    └── SRAM_32x64_1rw.v      # Behavioral verilog model for simulation
```

The code provided in the above directory is taken from the book chapter mentioned above, and the testbench is based on the MIPS processor lecture in CSE 320.

This design supports the following instructions: `add`, `sub`, `and`, `or`, `slt`, `lw`, `sw`, `beq`.

### Your tasks:

1. **Convert to 5-Stage Pipeline:**
    
    Modify the given non-pipelined MIPS processor design into a 5-stage pipelined processor.
    
2. **Use SystemVerilog Syntax:**
    1. Given code uses Verilog, you need to update it to use SystemVerilog syntax. For example, use `always_ff` instead of `always`, and `logic` instead of `reg` or `wire`.
    2. Try using as much System Verilog syntax as possible. There are no specific requirements like interfaces or enums. Points will only be deducted if no SystemVerilog syntax is observed.
3. **Hazard Handling:**
    1. You are **not required** to implement any special methods like forwarding or flushing for hazard management.
    2. Instead, **stall the pipeline** whenever any hazard is detected.
4. **Simulation and Verification:**
    1. Simulate and verify your pipelined processor design using the provided testbench.
    2. You should test all the instructions supported: `add`, `sub`, `and`, `or`, `slt`, `lw`, `sw`, `beq`. For this, add machine code to `memfile.dat` to populate instruction memory and update `expected_data`, `expected_addr` arrays in the testbench. You can refer to the CSE 320 slides for the Processor Design lecture (it’ll save some work for you).
5. **Synthesis:**
    1. Synthesize both the original non-pipelined design and your new pipelined design.
6. Synthesis with SRAM library:
    1. The synthesis you just did mapped both imem and dmem to flip-flops. That’s because we only provided a standard cell library to the synthesis tool that has only logic gates and flip-flops. But this is inefficient for large memories. Let’s do a short experiment to map the imem and dmem blocks to memory arrays (SRAMs).
    2. Modify your design to use the SRAM model given in `/usr/local2/COURSES/ADDV/LAB2/sram_32x64/` and synthesize using `compile_with_sram.tcl`  script provided.
    3. While doing this, you will need to replace top.sv with top_with_sram.sv
    4. Note that behavioral Verilog model of SRAM should be used only for simulation, not for synthesis. We are not asking you to do simulate in this part of the lab though, so the Verilog model is not going to be used.

---

> You are not allowed to change the top-level interface (only change internals). Strictly follow the design hierarcy shown below:
> 

```markdown
- testbench
 - top
 	 - mips
		 - controller
		 - datapath
	 - imem
	 - dmem
```

> The datapath file should be structured in the following order:
> 

```markdown
- Fetch logic
- Fetch-to-decode pipeline registers
- Decode/RF logic (Including an instance of register file and other logic)
- Decode-to-execute pipeline registers
- Execute logic (Including an instance of ALU and other logic)
- Execute-to-memory pipeline registers
- Memory logic (if any)
- Memory-to-writeback pipeline registers
- Writeback logic
```

---

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Deliverables for Part I:** (60 points)

PDF report:

1. **Draw a Microarchitectural Diagram** of your pipelined MIPS design and highlight the critical path on it. You may use the diagram from the book chapter linked above.
2. Make a comparison between the non-pipelined (already provided, non-SRAM memory design) and pipelined MIPS designs. Create a table in your report to compare the following metrics:
    1. Latency (Cycles Per Instruction)
    2. Throughput (Instructions Per Cycle)
    3. Area
    4. Clock Frequency (or Critical Path Delay)
3. Point out the lines in the provided synthesis script is used to specify the memory cell library.
4. Write a short description of the changes you made to support pipeline stalls in the case of hazards.
5. Attach a screenshot of simulation waveforms showing the complete pipeline flow of a load instruction.
6. Attach a screenshot of the terminal output for simulation.

ZIP file:

1. SystemVerilog design files
2. Testbench
3. memfile.dat with contents of Instruction memory
4. MIPS assembly program file (.txt)
5. Makefiles (if any)
6. README
</aside>

---

## Part #2: Customizations to the processor

This section includes adding a custom instruction and a performance monitoring unit to your pipelined MIPS processor.

### Tasks:

1. Add `MULADD` instruction:
    - Add support for a new custom instruction called MULADD that performs c = a*b+c. Assume that multiplying two 32-bit numbers results in a 32-bit answer (instead of 64-bit).
    - Note that this instruction needs 3 operands. Think of how you can obtain 3 operands.
    - An example of this instruction is `MULADD $1, $2, $3` which will perform this operation:
        - $1 (new value) ← $2 * $3 + $1 (current value)
    - Add a `MULADD` instruction to the program and verify this instruction.
2. Add Performance Monitor Capability
    - Performance monitors (also called perfmon) are blocks added into the design to monitor the performance of a processor. Generally, these blocks count different types of important events happening in a processor, such as the number of cache misses, and their values can be read by a programmer using special instructions.
    - Create a new `performance_monitor` module with two counters:
        - Cycle counter - Counts the number of cycles elapsed since the last reset
        - Instruction counter - Counts the number of instructions finished since the last reset
    - Add a new `perfmon` instruction with the following format: `perfmon <register>, <flag>`
        - When this instruction is executed, one of the two counters (specified in the instruction using the flag: 0=cycle counter, 1=instruction counter) is read into a register (specified in the instruction)
    - An example of this instruction is `perfmon $1, 0` which will return the cycle counter in the register $1
    - Add a `perfmon` instruction to the program and verify this instruction.

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Deliverables for Part II:** (40 points)

PDF report:

1. MULADD:
    1. Write a brief description of the changes you made to add the `MULADD` instruction.
    2. Highlight the code you added or modified for supporting this instruction (Copy relevant code snippets to your report)
    3. Attach a screenshot of simulation waveforms showing the complete pipeline flow for `MULADD` instruction.  
2. Performance monitor:
    1. Write a description of the changes you made to add the `perfmon` instruction.
    2. Highlight the code you added or modified for supporting this instruction (Copy relevant code snippets to your report)
    3. Attach a screenshot of simulation waveforms showing the complete pipeline flow for `perfmon` instruction.

ZIP file:

1. SystemVerilog design files
2. Testbench
3. memfile.dat with contents of Instruction memory
4. MIPS assembly program file (.txt)
5. Makefiles (if any)
6. README
</aside>

---

## Extra Credit:

1. **Data Hazards:** Forwarding logic for the `ADD` instruction ONLY
    - Implement data forwarding logic in your pipelined processor that only applies to the `ADD` instruction.
    - Add a specific test case (a new instruction file) with a sequence of instructions involving data hazards with `ADD` instructions. Verify that your forwarding logic works correctly.
2. **Control hazards:** Flushing logic for the `BEQ` instruction ONLY
    - Implement pipeline flushing logic to handle control hazards caused by the `BEQ` (Branch if Equal) instruction only.
    - Add a specific test case (a new instruction file) with a sequence of instructions that cause control hazards with `BEQ` instructions. Verify that your flushing logic works correctly.

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Deliverables for extra credit:** (10 points)

PDF report:

1. Write a description of the changes you made to implement the forwarding logic for data hazards and flushing logic for control hazards.
2. Highlight the code you added or modified for this implementation (Copy relevant code snippets to your report)
3. Attach a screenshots of simulation waveforms showing the complete pipeline flow for:
    1. ADD instruction sequence showing forwarding to handle data hazard.
    2. BEQ instruction sequence showing flushing to handle control hazard. 
4. Report the improved IPC for instruction sequences that benefit from the forwarding logic for ADD instruction.
5. Report the improved IPC for instruction sequences that benefit from the flushing logic for BEQ instruction.

ZIP file:

1. SystemVerilog design files
2. Testbench
3. memfile.dat with contents of Instruction memory
4. MIPS assembly program files (.txt)
5. Makefiles (if any)
6. README
</aside>

---

### Lab demo:

Schedule a 5-minute demo using the link, and include a screenshot of the schedule confirmation in the report: 

Slots are available from 5-6:30PM on June 12th, Thursday and 3-4:30PM on June 13th, Friday.

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

5 points will be deducted from the total score obtained for every incorrect answer during the demo.

</aside>

## Additional information:

For synthesis tool: use “analyze -sverilog” to synthesize SystemVerilog code

To avoid the synthesis tool optimizing out the imem and dmem,

set_dont_touch [get_cells "imem"]
set_dont_touch [get_cells "dmem"]