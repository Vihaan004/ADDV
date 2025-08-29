# Lab #0: Tools Tutorial

<aside>
💡

This lab assignment is to be done individually. No groups allowed.

</aside>

<aside>
💡

There is no demo requirement for this lab. There is no requirement for submitting code as well. Just submit a report. Instructions for what to submit in the report are described in the sections below.

</aside>

This lab is a tutorial for the EDA/CAD tools you will use in this course:

- Synopsys VCS → For simulation
- Synopsys Verdi → For waveform viewing and debugging
- Synopsys DC → For synthesis

There are two parts in this lab: first, you will complete training for each tool on the Synopsys website, and next, you will use these tools with a sample design on the Apporto server.

## Part I: Synopsys Online Trainings

You should have received an email with instructions to register for access to the **Synopsys SolvNetPlus** training and support site. If you have not received this email or cannot access the training site, reach out to IA or the instructor.

For each course listed below, you need to complete the lessons specified:

1. Training name: “**VCS: RTL and Gate Level Simulation**”
    
    Link: [https://training.synopsys.com/learn/courses/290/vcs-rtl-and-gate-level-simulation](https://training.synopsys.com/learn/courses/290/vcs-rtl-and-gate-level-simulation/lessons)
    
    Required lesson: Introduction to VCS
    
    You only need to complete the following parts of the lesson :
    
    1. VCS Setup and Use model information
    2. Debugging with VCS
2. Training name: “**Verdi: Debugging with Verdi I**”
    
    Link: [https://training.synopsys.com/learn/courses/132/verdi-debugging-with-verdi-i](https://training.synopsys.com/learn/courses/132/verdi-debugging-with-verdi-i)
    
    Required lesson: Verdi Core Debug
    
3. Training name:  “**Design Compiler: RTL Synthesis (2022.12)**”
    
    Link: [https://training.synopsys.com/learn/courses/86/design-compiler-rtl-synthesis-202212](https://training.synopsys.com/learn/courses/86/design-compiler-rtl-synthesis-202212/lessons)
    
    Required lessons:
    
    1. Design and Technology Data - Part 1
    2. Design and Technology Data - Part 2
    3. Timing Analysis 

If the above links don’t work, you can find these trainings on: [Synopsys Learning Center](https://training.synopsys.com/learn)

Click on “**Self-Paced Courses for University**” and search for the name of the trainings mentioned above.

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Deliverable for Part I:** (20 points)

For each training above, you will need to add a screenshot in the lab report showing completion of the required parts or lessons.

</aside>

---

## Part II: Apporto server

All the software required for this course is installed on the Apporto environment. 

You will be using the Apporto environment to access these tools. To access this environment, click on “Apporto - ECE Cad Lab” on the left side in Canvas. This will open up a new browser window that will provide you an interface to a Linux machine that has these tools installed.

You do not need to write any design or testbench files for this lab, sample files and scripts are provided in `/usr/local2/COURSES/ADDV/LAB0` on Apporto server. Contents of this directory are shown below: 

```markdown
Lab0/
├── sim/
│   └── Makefile
├── synth/
│   ├── compile_dc.tcl      # Synthesis script for DC compiler
│   └── Makefile            
├── env.cshrc               # Environment setup script
├── 18_19_Slice.v           # Design file
└── 18_19_Slice_tb.v        # Testbench file
```

Please copy these files to your working directory.

The `env.cshrc` script provided will set up the required environment variables for Synopsys tools. Note that this script works with tcsh shell and not bash. Make sure to source this script before running any tools.

Open each of the files in the directory and browse through them. Specifically, look at the targets in each Makefile. You will run the targets in the Makefiles to run various tools. For example, “make compile_verdi” will compile the design and testbench for Verdi.

For this part of the lab, you will need to run all three tools with the design provided using Makefiles. The three main tasks for this part are:

1. Task 1: VCS - Compile and Simulate
2. Task 2: Verdi - View waveforms
3. Task 3: Design Compiler - Synthesis

You can use the Makefiles provided in the sim/ folder for tasks 1 & 2, and the Makefile and compile_dc.tcl script in synth/ dir for task 3.

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Deliverables for Part II:** (20 points)

For Task 1, Include a screenshot of the terminal output showing successful completion of the task and list the files/folders generated after the compilation step and simulation step.

For Task 2, Include screenshots of the Verdi window showing design hierarchy, and waveform pane showing some signals from the design and some from the testbench.

For Task 3, Include a screenshot of the terminal window showing successful completion of synthesis. Include screenshots of the power, area, and timing values for the design from the generated reports.

</aside>

---

<aside>
<img src="https://www.notion.so/icons/gradebook_yellow.svg" alt="https://www.notion.so/icons/gradebook_yellow.svg" width="40px" />

**Answer the following questions in the lab report:** (10 points)

1. Which std cell library is used during Synthesis?
2. Which command is used to provide this library to the synthesis tool?
3. What command-line switch is used to generate the database used by Verdi?
4. Which line in the testbench file generates the waveform database (FSDB**)**?
5. Which hardware will line 23 in the design file synthesize to?
</aside>

---