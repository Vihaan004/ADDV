# Lab #4: FIFO Verification

<aside>
💡

You can use the SystemVerilog version of FIFO implementation from the Cliff Cummings paper for this lab. You need not have the additional modifications done in Lab 1. 

</aside>

---

## Materials to review

- Sample code provided with the lab, which shows different styles of testbenches for an adder example
- Lecture slides from the “System Verilog for Verification” lecture

<aside>
💡

Sample code has been provided at: /usr/local2/COURSES/ADDV/LAB4 on Approto

</aside>

---

## Part 1: Verification Plan (20 points)

For the first part of this lab, you will need to create a detailed verification plan for the asynchronous FIFO from Lab 1.

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Tasks and Deliverables for Part 1:**

1. Testbench architecture and strategy:
    - Draw a block diagram of a testbench architecture. Show key components like the DUT, driver, monitor, checker. Follow a style similar to Slide 50 of “System Verilog for Verification”.
    - Include a high-level methodology (simulation, formal) and sign-off metrics
2. Stimulus and coverage plan:
    - Write a list of scenarios and boundary conditions (also called corner cases) you will include
3. Checking plan:
    - Write a list of checks that you will perform
</aside>

---

<aside>
💡

Ideally, stimulus and coverage are two separate sections in the verification plan. In the stimulus plan, you write down various things you will randomize and constraints you will use. In the coverage plan, you write down specific scenarios you want to cover. In this lab, however, since we are not doing any randomization, the stimulus and coverage plans are the same - a list of scenarios.

</aside>

---

## Part 2: DPI-Based Verification (40 points)

In this part, you will create a golden reference model in C/C++ and use the SystemVerilog Direct Programming Interface (DPI) to test your FIFO design.

### Tasks:

1. Write a golden model in C/C++
    1. The model should maintain state (e.g., use 2D array for data storage and integer counters for pointers).
    2. It will have functions like `push()`, `pop()`, `is_empty()`, `is_full()`, etc.
2. Use DPI to import the functions from this model into SystemVerilog testbench.
3. In your testbench, write a checker module that calls these functions from C code based on the pin toggling of the signals going into the DUT. For example:
    1. When the testbench asserts `winc` to the DUT, it should also call the C model's `.push()` function with the same data.
    2. When the testbench asserts `rinc`, it should call `.pop()` and compare the output data from the DUT with the return value from the C function.
    3. Continuously call `.is_empty()` and `.is_full()` C functions and compare their return values to `rempty` and `wfull` flags from the DUT.
    4. Use `$display` or `$error` to print a message if there is any mismatch.
4. Stimulus and Verification
    1. There is no specific requirement for stimulus. You can use the same stimulus as Lab1. You may want to add more stimulus to ensure that various parts of the checker are hit.
    2. Inject a bug into your design, run the simulation again, and show that your checker model is working correctly. 
        1. Enabling/disabling this bug should be controlled by a plusarg. See the Tips page on Notion website on how to use plusargs: [Notes](https://www.notion.so/Notes-22b1e9cb485381799976d4efcaa3c58a?pvs=21) 
            1. Add two different targets in the makefile for simulating with and without errors.
        2. This bug should drop every Nth data written into the FIFO 

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Deliverables for Part 2:**

1. Briefly describe your C/C++ golden model and its functions. Highlight relevant code snippets in your report.
2. Briefly describe the checker module implementation and highlight relevant code snippets in the report.
3. Attach screenshots of the terminal output and Verdi waveform window for Task 4(a).
4. Attach screenshots of terminal output displaying the error/mismatch and the Verdi simulation waveforms showing a mismatch in the checker for Task 4(b).
5. Include all the files(design, testbench, README, and Makefiles) in a .zip folder.
</aside>

---

## Part 3: SV-Style Scoreboard-Based Verification (40 points)

In this part of the lab, you will use SystemVerilog classes and Object-Oriented programming concepts to create a verification setup for the asynchronous FIFO. 

### Tasks:

1. Define two interfaces to connect to the DUT. One for the write side signals and one for the read side signals.
2. Define a transaction class:
    1. Create a class to represent a transaction of the FIFO. Determine what properties this class should have.
3. Write a monitor
    1. Create a monitor class that monitors the pin toggling activity on the FIFO interface.
    2. This monitor should capture data or signals from the design, create a transaction object, and post it to a mailbox.
4. Write a scoreboard/checker
    1. Write a scoreboard class. This class will pull transactions from the mailbox populated by the monitor.
    2. This scoreboard should contain a reference model similar to the C model, but with a SystemVerilog queue `q[$]`.
    3. Whenever this scoreboard receives a transaction, it should perform checks. It will compare the data in transaction object (from DUT) with the state from the reference model. 
    4. Use `$display` or `$error` to print a message if there is any mismatch.
5. Stimulus and Verification:
    1. Rum simulation with the same stimulus as Lab 1. 
    2. Inject a bug into the FIFO design, run the simulation again, and show that your scoreboard correctly identifies the error.
        1. Enabling/disabling this bug should be controlled by a plusarg. See the Tips page on Notion website on how to use plusargs: [Notes](https://www.notion.so/Notes-22b1e9cb485381799976d4efcaa3c58a?pvs=21) 
        2. This bug should drop every Nth data written into the FIFO 

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Deliverables for Part 3:**

1. Briefly describe your transaction class and its properties. Highlight relevant code snippets in your report.
2. Briefly describe the monitor implementation. Highlight relevant code snippets in your report. 
3. Briefly describe the scoreboard implementation and reference model inside it. Highlight relevant code snippets in your report.
4. Attach screenshots of the terminal output and Verdi waveform window for Task 5(a).
5.  Attach screenshots of terminal output displaying the error/mismatch and the Verdi simulation waveforms showing a mismatch in the scoreboard for Task 5(b).
6. Include all the files(design, testbench, README, and Makefiles) in a .zip folder.
</aside>

---

### Extra Credit (10 points)

1. **Monitor enhancement (should be done for the code from Part 3):**
    - Include a timestamp property in your transaction.
    - Add logging functionality into the monitor. Whenever the monitor creates a complete transaction and posts it to the mailbox, it should print a message.
    - This logging functionality is controlled by a plusarg. The plusarg will have 3 possible values. 0 means the logger is disabled, 1 means the logger prints very brief messages (say, just the fact that a transaction was generated and the timestamp), 2 means the logger prints details messages (all fields of the transaction).
2. **Assertions (can be done for the code from Part 2 or Part 3):**
    1. Write SystemVerilog Assertions (SVA) inside your `interface`. Write the following properties to check for illegal conditions. You can use XMRs to probe signals inside the DUT.
        1. If `wfull` is high and `winc` is asserted, no write should happen and the write pointer should not change on the next `wclk` edge.
        2. If `rempty` is high and `rinc` is asserted, no read should happen, and the read pointer should not change on the next `rclk` edge.
    2. Note that we have very briefly discussed assertions in class. There will be a lecture where we will go into more details about assertions. So, for this you may have to google search to find the right syntax that you need.

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Deliverables for Extra Credit:**

1. In your report, mention the name of the plusarg that controls the logger functionality. Include screenshots of the terminal showing the messages from the 3 different settings of the logger. Show the commands (or include the Makefile).
2. In your report, include the code for the assertions/properties you wrote. Inject an error in the design (you can hand edit the design) and make the assertion fail and include snapshots of the terminal showing the failure for each assertion.
</aside>

---

### Lab demo:

Schedule a 5-minute demo using the link, and include a screenshot of the schedule confirmation in the report: 

Slots are available from 5-6:30 PM on June 26th, Thursday, and 2-3:30 PM on June 27th, Friday.

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

5 points will be deducted from the total score obtained for every incorrect answer during the demo.

</aside>

---