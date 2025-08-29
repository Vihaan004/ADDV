# Lab #5 MIPS Verification

---

## Materials for reference and review:

<aside>
💡

Official reference links:

- UVM 1.2 user guide: https://www.accellera.org/images//downloads/standards/uvm/uvm_users_guide_1.2.pdf
- UVM code base: https://accellera.org/downloads/standards/uvm
- UVM class reference: https://uvm-docs-online.readthedocs.io/en/latest/
- System Verilog LRM: https://ieeexplore.ieee.org/document/8299595
</aside>

<aside>
💡

This is the tutorial I used to learn UVM:

https://cluelogic.com/2011/07/uvm-tutorial-for-candy-lovers-overview/

</aside>

<aside>
💡

These webpages have nice diagrams related to UVM concepts:

- Class library: https://www.chipverify.com/uvm/uvm-introduction
- Testbench hierarchy: https://www.chipverify.com/uvm/uvm-testbench-top
- Phasing: https://www.chipverify.com/uvm/uvm-phases
- Environment: https://www.chipverify.com/uvm/uvm-environment
- Reporting: https://learnuvmverification.com/index.php/2016/03/25/uvm-reporting/
</aside>

<aside>
💡

These webpages can be helpful to refer to for UVM syntax and concepts:

https://vlsiverify.com/uvm/

https://www.doulos.com/knowhow/systemverilog/uvm/easier-uvm/

</aside>

---

## Concepts to review/remember:

- Functional coverage syntax from SV lecture and Synopsys SV training
- Constrained randomization syntax from SV lecture and Synopsys SV trainings
- UVM lectures

<aside>
💡

Sample code has been provided at: /usr/local2/COURSES/ADDV/LAB5 on Approto. This includes:

- Two files called coverage_collector.sv and instr_gen.sv. These are files specific to this lab.
- A folder called serialalu_uvm. It has a full UVM testbench for a dummy DUT. I’ve checked that it compiles and runs. You can use it as starter code.
- A folder called old_easier_uvm_code. It has example UVM code from ‘Easier UVM by Doulos’. It is very old, but can be helpful.
</aside>

---

## General notes

In this lab, you will be verifying a pipelined MIPS processor. This lab only covers stimulus and coverage. No checking is required to be done. For checking, you typically need what is called an ISS (Instruction Set Simulator). That can get pretty complex. Out of scope for a lab.

You can use the pipelined processor we gave you in Lab 2 or the one you modified in Lab 2. You don’t need to use the enhanced processor from Lab 2. Any pipelined implementation that you have will work for this lab. It doesn’t have to be 100% verified/correct in functionality. 

We will be using a mix of plain SV and UVM for this lab. 

---

## Part #1:  Verification plan (20 points)

<aside>
💡

This plan should assume a pipelined processor that supports ADD, AND, LW, SW, and BEQ. Your test plan is independent of the specific design/implementation you choose.

</aside>

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Tasks and Deliverables for Part 1:** In your PDF report:

1. Strategy and architecture
    1. Draw a block diagram of your testbench architecture. Show components like DUT, instruction generator, driver, monitor, and coverage collector.
    2. Briefly mention the implementation of a checker model for this verification lab. (Note that you will NOT implement a checker for this lab, you just need to describe what an ideal implementation has to do.)
2. Stimulus
    1. Describe the strategy for generating random, valid instructions 
    2. List the types of constraints you will apply to cover all the scenarios
3. Coverage
    1. Describe the functional coverage model
    - List the specific coverage points you will use
4. Checking
    1. List some checks that you will do
</aside>

---

<aside>
💡

**IMPORTANT: To make this lab easier and limited, we are asking you to limit to the following for your stimulus and coverage:**

- **5 instructions (ADD, AND, LW, SW, BEQ)**
- **4 registers (You can choose any 4 registers, say $1, $2, $3, $4)**
- **4 data memory addresses (You can choose any 4 data memory addresses)**
- **4 gaps (You only need to have a gap of 1,2,3,4 instructions between any two instruction pairs of dependent instructions)**
- **4 offsets (You only need to have offsets of 1,2,3,4 for the branch instruction offset)**
</aside>

## Part #2: Instruction generator (40 points)

In this part, you will create a constrained-random instruction generator using SystemVerilog classes.

<aside>
💡

These pages may be helpful to refer to when coding constraints: 

https://vlsiverify.com/system-verilog/randomization-in-systemverilog/

</aside>

### Tasks:

1. Define an `instruction` class that extends from `uvm_transaction`.
    1.  Include various `rand` attributes corresponding to MIPS instruction fields.
2. Add constraints to the `instruction` class to generate valid instructions for `ADD`, `AND`, `LW`, `SW`, and `BEQ`.
3. Create a new class to generate a sequence of instructions.
    1. Randomize individual instructions. This involves ensuring you generate various values of various instruction fields. Some important things to mention:
        1. Make sure you generate branch instructions that cover both branch taken and not taken cases. Make sure that the branch address is a valid value (within the range of the program you generate).
        2. Make sure the target address for the branch instruction is within the valid range of the program you generate. 
    2. Randomize pairs of instructions. This is where you can include instruction pairs that have dependencies. Some examples:
        1. An ADD and a following AND instruction with a register dependency
        2. Store and Load with a memory location dependency.
    3. Randomize the number of instructions (gap) between instruction pairs.
    4. You can organize this class using any properties and functions you like. May be one function for each type of randomization mentioned above. 
    5. As you randomize the instructions (i.e. develop your instruction sequence containing randomized instructions), store them into a dynamic array (refer to the SystemVerilog LRM for syntax of dynamic arrays).
    6. Add a function to convert each instruction from this array to its machine code representation. This is basically an assembler.
    7. The final instruction stream (which is the main output of this class) should include some basic setup instructions (e.g., to initialize registers and memory) followed by your randomized sequence of instructions.
4. Testbench
    1. In the testbench, construct the instruction generator class and call its main function that generates the instruction sequence
    2. Copy the generated instruction sequence (in a dynamic array variable) into the instruction memory of MIPS processor.
    3. Then deassert reset to kick off the MIPS processor
5. Simulation
    1. Run simulation. Check Verdi waveforms to make sure things are working fine. This is just to check that the stimulus generated through constrained randomization is valid. Not to check the  MIPS design.

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Deliverables for Part 2:**

1. Briefly describe the structure of your instruction class, highlight relevant code snippets by copying them to the report.
2. Briefly describe the constraints used for generating randomized instruction sequence. Copy relevant code snippets to the report.
3. Screenshots from Verdi waveform viewer showing MIPS processor fetching your generated pairs of instructions.
4. All the code files in .ZIP format.
</aside>

---

## Part 3: Functional Coverage (40 points)

In this part, you will create a converge collector component using UVM style subscriber.

<aside>
💡

- To compile with UVM, add `-ntb_opts uvm` to the VCS command line.
- After you compile the code that has functional coverage in it and you simulate your testbench, there will be a .vdb file in the working directory. That’s the covearge database.
- To run Verdi with coverage, add `-cov` and `-covdir <name_of_vdb>` to the Verdi command line.
</aside>

<aside>
💡

These webpages will be helpful to review for using ports:

https://vlsiverify.com/uvm/tlm/tlm-analysis-interface/

https://vlsiverify.com/uvm/tlm/tlm-analysis-fifo/

</aside>

<aside>
💡

These webpages can be helpful to refer to when coding functional coverage:

https://vlsiverify.com/system-verilog/functional-coverage/functional-coverage/

</aside>

<aside>
💡

This video will be helpful to review to understand how to use Verdi in coverage mode:

https://www.youtube.com/watch?v=MUx_MtxZByY

</aside>

### Tasks:

1. Monitor:
    1. Write a monitor class that extends from `uvm_monitor`.
    2. Add a `uvm_analysis_port` to it.
    3. This monitor will watch the instruction fetch interface (i.e. the address, rdata, etc. signals on the instruction memory, and also the clock and reset of the processor).
    4. It will observe the signals on this interface and create an `instruction` transaction object and post it to the `uvm_analysis_port`.
2. Coverage Collector:
    1. Write a coverage collector class that extends from `uvm_subscriber`
    2. Inside this class, define `covergroups`, `coverpoints` and `bins`  that comprise your functional coverage model.
    3. You should have coverage for:
        1. Specific fields of individual instructions (including branch taken, not taken)
        2. Specific orders of instructions (including dependencies in memory addresses and register names)
        3. Specific gaps between instructions
    4. Add a `uvm_tlm_analysis_fifo` or a `uvm_analysis_imp` in it. These are ways to get data from the port into the subscriber.
        1. It’s slightly easier to use tlm_analysis_fifo. But both options are okay. The sample code we’re providing uses uvm_analysis_imp. You can see the [vlsiverify.com](http://vlsiverify.com) links above to see the syntax for both methods.
    5. As instruction transactions come in through the port, call `.sample()` on various cover groups.
3. Environment:
    1. Write an environment component class that extends `uvm_env` where you create, build and connect the monitor and coverage collector components.
4. Test:
    1. In this lab, the “test” does not have any real significance because we are not providing stimulus via UVM. So, you can skip this hierarchy of the testbench components. But it’s good to get into the habit of designing a standard UVM hierarchy. So even if it’s not going to be used, I recommend we have a test.
    2. Write a test component class that extends `uvm_test` where you create and build the environment
5. Testbench
    1. You will need to have the creation of the instruction sequence generator from Part 2
    2. After the instruction sequence has been generated and copied into the MIPS processor’s memory, deassert reset and call `run_test()`
6. Simulation:
    1. Run the simulation. Open the generated coverage database in Verdi. See what coverage bins are not hit. Iterate until all cover points are hit. You may need to improve your instruction generator or your coverage code.

<aside>
💡

**Merging coverage across runs**

One simulation run will generate one instruction stream. The coverage achieved for that instruction stream will be logged into the coverage database (default name simv.vdb). You will run multiple times (with different seeds) and this will generate multiple instruction streams. 

You can specify different vdb directory names for each run (using -cm_dir option on the simulation command line) . This will result in multiple coverage databases. Then you'll have to merge them using the urg command ($(VCS_HOME)/bin/urg -dir *.vdb -dbname merged_coverage.vdb). 

To set a seed value for a simulation run, you need to use `+ntb_random_seed=<value>` on the simulation command line.

Merging coverage from many simulation runs (aka many "test sequences") will help you hit 100% coverage.

</aside>

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Deliverables for Part 3:**

1. Briefly describe the structure of your monitor class, and highlight relevant code snippets by copying them to the report.
2. Briefly describe your coverage model in the report. Copy relevant code snippets to support your description.
3. A screenshot of the initial Verdi coverage report from your first simulation run.
4. A screenshot of the final Verdi coverage report showing your best functional coverage.
5. All code files in ZIP format.
</aside>

<aside>
💡

Ending the simulation 

This is an interesting topic in general. There are methodologies for this in various companies for end-of-sim. In this lab, you can do it in multiple ways:

- You can keep a count for the number of instructions the instruction generator generated. You can count the number of instructions fetched and executed by snooping the instruction memory interface. When all generated instructions have been executed, you can call $finish
- You can have an estimate of when your MIPS processor would have finished executing all the instructions that you have generated (say 100000 ns), and just have an initial block where you wait for that much time and call $finish.
- You can use a trick-box method. You can dedicate a data memory location (say address 0xFFFF) as a special location. You can have a store instruction writing some value (say 0xdead_beef) to this location at the end of your instruction sequence. You can snoop the instruction memory interface in the testbench and when you see this special address being written to with this special value, you can call $finish
- You can use a trick-box on the UVM side also. You can play with when you raise and lower objections in the components. For example, you can lower objections in the monitor and coverage collector when you see this special address being written to with this special value. The simulation should automatically end when there are no objections.
</aside>

---

## Extra credit: (10 points)

Code coverage

1. Enable line, toggle, condition and FSM coverage. See the example Makefile at /usr/local2/COURSES/ADDV/LAB5/serialalu_uvm/Makefile to find the arguments for enabling code coverage
2. Look at the results by opening Verdi. 
3. In your report, explain what wasn’t covered and why. Restrict to talking about 5 things maximum.
4. Include a snapshot of the coverage report from Verdi.

Incorporate a trick-box. 

- Dedicate an address in the data memory for a trick-box.
- In your program (instruction sequence), add an instruction which writes some value to this address.
- In the testbench, attach a component that snoops/monitors this address. This component can be Verilog-style or SystemVerilog-style or UVM-style (your choice).
    - When the CPU writes to this address, this component calls $display. It prints a message containing the data that was written to this address on the screen.
- This is a way of “printing” from the CPU (we are tricking the CPU to implement a “printf” like functionality)
- In the report, mention the address you dedicated to the trick-box, provide the instruction you wrote on that address, include the code for your testbench component, and a snapshot of the terminal showing the print.

---

### Lab demo:

Schedule a 5-minute demo using the link, and include a screenshot of the schedule confirmation in the report: 

Slots are available from 5PM to 6 PM on Thursday, July 3, and 3.30PM to 5PM on Monday, July 7.

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

5 points will be deducted from the total score obtained for every incorrect answer during the demo.

</aside>

---