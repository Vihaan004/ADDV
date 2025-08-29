# Lab #1: FIFO Design

<aside>
💡

You will need to work in groups of 2 for this Lab.

</aside>

<aside>
💡

Each student has to give a 5-minute demo. No credit will be given if the demo is not done.

</aside>

<aside>
💡

You will use Synopsys tools (VCS, Verdi and Design Compiler) for this lab. Please create your own command files (Makefiles, etc) based on the ones provided for Lab #0. Get familiar with these tools by playing around with them using some simple code (say code from a prior course on Verilog).

</aside>

---

This lab focuses on design and verification of two components, an Asynchronous FIFO and a Data Interleaving circuit that uses this FIFO.

## Materials to review FIFO design concepts

- Lecture slides and video: [https://amankbm.notion.site/2-1bfef012eb5c80688ca8ff055b544cae?pvs=4](https://www.notion.so/2-22b1e9cb48538154a5f7e7bd2c3283e5?pvs=21)
- Cliff Cummings’ paper: [http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf](http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf)
- FIFO depth calculations: [https://hardwaregeeksblog.wordpress.com/wp-content/uploads/2016/12/fifodepthcalculationmadeeasy2.pdf](https://hardwaregeeksblog.wordpress.com/wp-content/uploads/2016/12/fifodepthcalculationmadeeasy2.pdf)

## Part I: Asynchronous FIFO

Design an asynchronous FIFO in SystemVerilog. You can use code from the Cliff Cummings paper linked above. You may need to modify code to satisfy the requirements below.

### Design requirements:

Your design must meet the following requirements:

1. **SystemVerilog syntax**: 
    1. Use `always_comb` and `always_ff` instead of `always`.
    2. Use `.*` (named port connection) while instantiating other modules.
    3. Use `logic` instead of wire and reg
2. **Parameterization**: Design must be parameterized for input/output data width and depth.
3. **Asynchronous o**peration: Must have different clocks for read and write operations.
4. Use **synchronizers** and **gray code** pointers.
5. **Status flags**: Include `almost_full` and `almost_empty` flags. Assert these flags when the FIFO is 3/4th full or 3/4th empty respectively.

### Verification requirements:

Create a SystemVerilog testbench to verify your FIFO design. Testbench should at least check the following conditions:

1. FIFO empty and then filled, FIFO full and then emptied.
2. Correct assertion of `almost_full` and `almost_empty` flags. 
3. Simultaneous read and write with different clock frequencies.

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Deliverables for Part I (50 points):**

1. A microarchitecture diagram of your FIFO design. This can be hand-drawn diagram on paper or on a tablet. It must include:
    1. Main memory/register array block
    2. Synchronizer FFs (Mark signals crossing clock domains)
    3. Logic for status flags (`full`, `empty`, `almost_full`, and `almost_empty`)
    4. Logic for read and write pointers
2. Snapshots of simulation waveform showing the 3 verification requirements defined above.
3. In your FIFO design, are the FULL and EMPTY signals Mealy or Moore style outputs? Support your answer with 1-2 sentences of explanation.
4. Your code in a zip file
    1. Include Makefile and a README file on how to run your code. Do not include tool generated files like csrc/, simv.daidir, novas.fsdb, etc. 
    2. Please make sure you document your code well. Points will be deducted for poorly documented code.
</aside>

---

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Extra Credit (10 points):** 

1. Use SystemVerilog interfaces and modports in FIFO and Data sorter design(Even/Odd Alternating Circuit of Part II).
    1. Use `interface` when defining and instantiating the FIFO or memory block
2. Synthesize the FIFO design using Synopsys Design Compiler and report the following:
    1. Maximum frequency of operation for both read and write clock domains
    2. Details of any constraints applied.
    3. Total area and power estimates.
</aside>

---

## Part II: Even/Odd Alternating Circuit

In this part, you will design a circuit that takes an input stream of numbers that contains a mix of even and odd numbers. The order in which even and odd numbers appears is not consistent. This circuit creates an output stream that has always even and odd number in an alternating manner (i.e. no two consecutive numbers that come out are both even or both odd), but the order of numbers is the same as the input stream.

The interface of this design/circuit is:

| **Direction** | **Name** | **Bit width** | **Role** |
| --- | --- | --- | --- |
| Input | Clock | 1 |  |
| Input | Reset | 1 |  |
| Input | Data_in | 8 | This is the input stream of numbers going into the circuit.  |
| Input | Write_en | 1 | This is asserted by a producer (testbench, in our case) to send a number into the circuit |
| Output | Data_out | 8 | This is the output stream of numbers coming out of the circuit |
| Input | Read_en | 1 | This is asserted by a consumer (testbench, in our case) to read a number from the circuit |

<aside>
💡

**Hints:** 

- For this design, you will instantiate two FIFOs, one for storing even values and one for storing odd values.
- Then you will write some logic around these FIFOs. On the write side, the logic will be very simple (likely only combinational). On the read side, the logic will involve some sequential logic (may be a simple 2-state FSM).
- You will not need to use the fifo_full, almost_full, fifo_empty, and almost_empty flags of the FIFOs.
</aside>

<aside>
💡

For this part of the lab, you do not need an asynchronous FIFO. So, you can either design a synchronous FIFO or just use the asychronous FIFO designed in part 1. No points will be deducted either way.

</aside>

### Design requirements:

1. Data will be written into this design at a rate of 80 data items per 100 clock cycles. You should assume that out of 80 data items, 40 are even and 40 are odd, just not in alternating order. This is an important assumption.
2. Data will be read from this design at a rate of 8 data items per 10 clock cycles.
3. The circuit has to pause or stay in idle state if one of the FIFOs is empty and should not output a 0.

### Verification requirements:

1. Generate inputs at a rate of 80 data items per 100 clock cycles and request outputs at a rate of 8 data items per 10 clock cycles
2. Generate input data such that at least two cases get tested listed in the FIFO size calculation  document linked above. One of these should be the case you used to find the size of the FIFOs. 

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Deliverables for Part II (50 points):**

1. Snapshots of simulation waveforms showing input and output data streams.
2. Explain how you determined the size of FIFOs used in your design.
3. Your code in a zip file. 
    1. Include Makefile and a README file on how to run your code. Do not include tool generated files like csrc/, simv.daidir, novas.fsdb, etc. 
    2. Please make sure you document your code well. Points will be deducted for poorly documented code.
</aside>

---

### Lab demo:

Schedule a 5-minute demo using the link, and include a screenshot of the schedule confirmation in the report: 

Slots are available from 2-3:30PM on June 2nd, Monday and 5-6:30PM on June 3rd, Tuesday.

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

5 points will be deducted from the total score obtained for every incorrect answer during the demo.

</aside>