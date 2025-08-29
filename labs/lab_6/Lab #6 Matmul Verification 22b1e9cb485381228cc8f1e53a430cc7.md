# Lab #6: Matmul Verification

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

- https://vlsiverify.com/uvm/
- https://www.doulos.com/knowhow/systemverilog/uvm/easier-uvm/
- UVM lectures from the class
</aside>

<aside>
💡

UVM testbench example for a simple adder is here : /usr/local2/COURSES/ADDV/LAB5/serialalu_uvm/

</aside>

---

## General notes:

In this lab, you will be verifying the systolic matrix multiplier using UVM. You will develop UVM agents for the various interfaces of the systolic matrix multiplier we used in Lab 3. You will write sequences for the various interfaces. 

You will use the design you modified in Lab 3. You don’t need to use the enhanced design with FP units, but you do need the design with an APB slave inside and an APB interface on it.

<aside>
💡

Config_DB vs Resource_DB: The data structure is the same. Just the API is different. Some people prefer uvm_config_db, whereas some people prefer uvm_resource_db

</aside>

<aside>
💡

UVM testbench hierarchy

Just like there is a module/instance hierarchy on the design side:

testbench.top.instA.instB.signal

There is a testbench component hierarchy on the UVM testbench side:

uvm_test_top.env.agentA.monA → uvm_resource_db or uvm_config_db

env.agentA.read() → Using class object handles and variable/method names

</aside>

---

## Part #1: Incorporate APB agent

In this part, you will verify the matmul with APB control interface from Lab #3 Part #2 (Don’t worry if your DUT doesn’t have the FP units; we only need the APB changes.)

Instead of driving the APB interface using SV tasks (like you did in Lab 3), you will use a UVM agent and sequence.

### Tasks:

1. **Set up the testbench and environment:**
    1. Download the APB Verification IP (VIP) from this Github repo: https://github.com/asveske/apb_vip/tree/master
        - This codebase has a master and a slave agent, and the testbench they have provided doesn’t have a DUT. The master agent talks to the slave agent on the APB interface.
        - Your design has an APB slave inside it. So, you won’t use the slave agent from this codebase. You will only need the master agent.
    2. Create a testbench that instantiates an APB interface and connect it to the DUT. You can start from the `tb/testbench.sv` file in this codebase and modify it.
    3. Create a UVM environment (extending from `uvm_env`) that will house the APB master agent. You can use the `tb/apb_env.svh` file in this codebase and modify it.
2. **Write an APB sequence**
    1. Create a new sequence that extends from `uvm_sequence`.
    2. This sequence will first send APB write transactions to program the addresses and strides, and then write to the "start" register inside your DUT.
    3. Then it will send read transactions that will poll for the “done” register inside your DUT (inside a loop waiting for done signal to be HIGH).
    4. Add `uvm_info() prints in this sequence to print what's going on per transaction.
3. **Create a test:**
    1. Create a UVM test (extending from uvm_test) that will instantiate the environment and start this sequence. You can start from the `tb/apb_test.svh` file in this codebase and modify it.
4. **Add debug features**
    
    Look through the two links below. These links provide various debug features for debugging UVM testbenches.
    
    [https://learnuvmverification.com/index.php/2016/05/22/debugging-uvm-environment/](https://learnuvmverification.com/index.php/2016/05/22/debugging-uvm-environment/)
    
    [https://ignitarium.com/top-uvm-debugging-hacks-that-will-transform-your-workflow/](https://ignitarium.com/top-uvm-debugging-hacks-that-will-transform-your-workflow/)
    
    Now, make changes to your code or command line to do the following one by one: 
    
    - Print the UVM testbench topology
    - Enable the config/resource database print
    - Add a .print() on any component (say your env)
    - Add a .print() on any object (say, the transactions in your sequence)
    - Print the objection trace
    - Print the phase trace
    - Change UVM verbosity (to UVM_HIGH)

<aside>
💡

Note: In this part, no changes are to be made to the mechanism of configuring the RAMs with matrices A and B, and no changes will be made to the mechanism of checking matrix C.

</aside>

<aside>
💡

The given APB agent drives and samples things are posedge. You may want to change that to negedge (because our DUT works at posedge)

</aside>

<aside>
<img src="https://www.notion.so/icons/gradebook_orange.svg" alt="https://www.notion.so/icons/gradebook_orange.svg" width="40px" />

**Deliverables for Part 1: (40 points)**

1. A brief description of your testbench and how you integrated the APB master agent. 
2. Provide a brief description of the APB sequence you wrote, along with snapshots of your code to assist the description.
3. For each of the debug features you enabled, include snapshots of the terminal in your report.
</aside>

---

## Part #2: Write and incorporate memory interface agents

In this part, you will create custom UVM agents to model the memories that interface with the DUT.

### Tasks:

1. **Modify the DUT:**
    1. The DUT for this part of the lab will be slightly different from the DUT you used in Part 1. This DUT will not have the memory (RAM) blocks instantiated inside it.
    2. For creating this DUT, create a new hierarchy that just has the matmul and the APB block. The raw memory interfaces will be exposed to the top-level of the DUT. 
    3.  This DUT will have 4 main interfaces:
        1. APB interface
        2. Matrix A interface (a_data, a_addr, a_mem_access, clk, reset)
        3. Matrix B interface (b_data, b_addr, b_mem_access, clk, reset)
        4. Matrix C interface (c_data_out, c_addr, c_data_available, clk, reset)
    
    <aside>
    💡
    
    We will modify the DUT some more. `a_mem_access` and `b_mem_access` are internal signals in the DUT. Please pull out these two signals to the top-level of the DUT. These signals will serve as the enable signals on the memory read interfaces. 
    
    The signal `c_data_available` will serve as the enable signal on the memory write interface. This signal is already exposed to the top-level of the DUT.
    
    </aside>
    
    Matrix A, matrix B, and matrix C interfaces can have the same definition. This interface will have signals: addr, data, enable, clock, and reset. It’ll just be instantiated thrice.
    
2. **Design a memory slave agent:** 
    1. Design a UVM agent for the memory interfaces that acts like a slave. The matmul acts as a master on these interfaces. 
    2. We are expecting only these: interface, defines, seq_item, driver, sqr, sequence, agent, pkg. You do not need to create monitors or cfg etc. 
    - The agent just needs to act like a memory and will respond with the right data (matrix A and B) or write the result into the memory (matrix C).
    1. To differentiate between the behavior of the various instances of this agent (read vs write), you will add a parameter in the agent. This parameter will be configured using the `uvm_config_db` or `uvm_resouce_db`.
    - For the agents connected to Matrix A and Matrix B interfaces, this parameter will be configured to “READ”, and for the agent connected to the Matrix C interface, this parameter will be configured to “WRITE”.
    1. These agents will have a memory model in them.  The memory model will be populated by your test (see instructions later). 
        1. You can use any array style you prefer. One option is associative array using a syntax similar to:`bit [31:0] mem_model[*];` 
    2. For the READ agent, the driver should respond to read requests from the DUT by looking up the address in its memory model and drive the data onto the interface.
    3. For the WRITE agent, the driver should see write requests from the DUT and update its internal memory model with this data.
    
    Pseudocode for the run_phase of the driver is shown below:
    
    ```makefile
    task run_phase(uvm_phase phase);
      super.run_phase(phase);
      init_signals();
      wait_for_reset();
      get_and_drive();
    endtask
    
    task get_and_drive();
      forever begin
        @(posedge vif.enable);
        tr = ...::type_id::create(...);
        seq_item_port.get_next_item(tr);
        if (mode == WRITE) begin
          mem[vif.addr] <= vif.data;
          tr.data <= vif.data;
          tr.addr <= vif.addr;
          tr.dir <= WRITE;
        end
        else begin
          vif.data <= mem[vif.addr]; 
          tr.data <= vif.data;
          tr.addr <= vif.addr;
          tr.dir <= READ;
        end
        seq_item_port.item_done();
      end
    endtask     
    ```
    
3. **Write slave sequences:**
    1. These memory agents are slave agents with no blocking capabilities. The sequencer will always return a `seq_item` to the driver immediately. Write a simple slave sequence with a forever loop that is always ready to respond to the DUT. Here’s the code that you will use:

```cpp
    task body();
        forever begin
            tr = ....type_id::create("tr",,get_full_name());
            start_item();
            finish_item();
        end
    endtask: body
```

1. **Define the environment:**
    1. Create a new testbench environment that instantiates the 4 agents (1 APB master agent and 3 memory slave agents, one for each matrix). The APB master agent is the one you used in Part 1 of the lab.
2. **Create a test:**
    1. Write a test extending from `uvm_test` that has:
        1. 3 variables for A, B, and C matrices. 
    2. In the build phase of this test, create the environment and:
        1. Randomize the A and B matrices and calculate the expected matrix C. 
    3. In the configure phase, configure the matrix values into the memory models inside the agents.
        1. You can reach to the memory models in each agent using handles (agent.mem)
        2. An alternative is to use config_db or resource_db. You can `set` the memory model from the test, and `get` it inside the agents. This will avoid using handles.
    4. In the run phase, start multiple sequences or use a virtual sequence that starts multiple sequences. This sequence should perform the following actions:
        1. Start an APB sequence (this will configure the registers in the APB slave in the DUT, and end with asserting the “start” bit). This is the sequence you used in Part 1 of the lab.
        2. Start the sequences on the Matrix A interface agent’s sequencer, the Matrix B interface agent’s sequencer, and the Matrix C interface agent’s sequencer.
        3. Start an APB sequence (that will poll for the “done” bit). This is the sequence you used in Part 1 of the lab.
    5. After the done bit is asserted, using code, check the memory model of the Matrix C agent to ensure the results written by the DUT match your expected Matrix C. Call `uvm_info and `uvm_error accordingly.
    6. In the testbench, instantiate the DUT, instantiate the interfaces, and call uvm’s `run_test()`

<aside>
💡

Note that some of the sequences have forever loops inside them. So, use fork-join, fork-join_none, etc. statements.

</aside>

<aside>
💡

Read about virtual sequences here:

https://www.chipverify.com/uvm/uvm-virtual-sequence

https://www.chipverify.com/uvm/uvm-virtual-sequencer

</aside>

<aside>
💡

config_db and resource_db usage can get complicated. There are many resources available online for help. Here are a couple of links. 

[https://thetechieblog.com/uvm/difference-between-uvm_config_db-and-uvm_resource_db/](https://thetechieblog.com/uvm/difference-between-uvm_config_db-and-uvm_resource_db/)

[https://www.chipverify.com/uvm/uvm-config-db-examples](https://www.chipverify.com/uvm/uvm-config-db-examples)

</aside>

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Deliverables for Part 2: (50 points)**

1. A brief description of your memory slave agent's architecture. Incorporate snapshots of important parts of your code to assist your description
2. An explanation of how you used `uvm_resource_db` or `uvm_config_db`to configure the agents.
3. A description of your self-checking test and virtual sequence or test.
4. A screenshot of the terminal showing that the test passed (i.e., matrix C was correct).
</aside>

---

## Part #3: Assertions

In this part, you will add SystemVerilog Assertions (SVA) to your testbench to automatically check for correct behavior.

### Tasks:

1. **Write Assertions:**
    1. Several assertions are present in the APB agent we have given you. You can read them.
    2. Write any 4 assertions for your DUT. Here is an example:
        1. After `start_mat_mul` is asserted, the `c_data_available` should be asserted N cycles later
    3. Inject some errors using `force` and `release` statements from the testbench. Show the assertion failing in waveforms/log file/terminal.
        1. Example syntax:
        
        ```makefile
        module testbench;
          initial begin
            force dut.mdA.signB = 1'b0; //this is the signal the assertion was expecting to be 1
          end
        endmodule    
        ```
        

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Deliverables for Part 3: (10 points)**

1. A list of the assertions you wrote, with a brief description for each.
2. Snapshots of simulation waveforms or log file or terminal showing your assertions failing when you injected an error.
</aside>

---

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Extra Credit: (10 points)**

**Task:** Showcase some reuse from the unit-level DUT. Assume the unit-level DUT is the processing_element unit. You can do one of the following:

1. Write a checker for the processing_element unit. Check that the output of the processing_element is as expected.
    - Reuse this checker at the top-level. You will have 16 instances of this checker at the top level.
2. Write 4 assertions at the PE level. Some examples are provided below. Bind these assertions to the top-level. You will have 16 bindings. Search for the “bind” keyword online to find out how to use it.
    - `in_a` should match `out_a` after 1 cycle
    - `out_c` should have a value of `in_a` * `in_b`+ older value of `out_c` after 1 cycle

**Deliverables:**

1. A description the PE-level checker or assertions.
2. A snapshot of the code using instantiating these checkers or assertions at the top-level DUT
</aside>

---

### Lab demo:

Schedule a 5-minute demo using the link, and include a screenshot of the schedule confirmation in the report: 

Slots are available from 5-6 PM on July 10th, Thursday;  2-3 PM and 4-5.30 PM on July 11th, Friday.

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

5 points will be deducted from the total score obtained for every incorrect answer during the demo.

</aside>

---