# Notes

## Creating Multiple Test Scenarios without Recompilation

Say you want to test the following two scenarios (or testcases) on your DUT:

1. Scenario #1:
    1. Set inp_a = 0, inp_b = 1
    2. Wait 10 clocks
    3. Set inp_a = 1, inp_b = 1
    4. Wait 10 clocks
    5. Check out_a is 5
    6. Finish
2. Scenario #2:
    1. Set inp_a = 1, inp_b = 0
    2. Wait 15 clocks
    3. Set inp_a = 0, inp_b = 0
    4. Wait 15 clocks
    5. Check out_b is  1
    6. Finish

Also, assume that these are two different totally independent scenarios, and you cannot test them by running Scenario #1 and then Scenario #2 in the same simulation. You need to run each scenario starting from time #0.

If you design simple testbenches like the ones we have discussed in courses like CSE 320, you would create two **testbench** files. In each file, you will instantiate the DUT and have the code for each scenario. Here’s some code to illustrate this.

First testbench file:

```verilog
//File: testbench1.v
`timescale 1ns/1ns
module tb;
  //some signal declarations
  wire out_a, out_b;
  reg inp_a, inp_b;
  reg clk;
  reg rst;
  
  //clock generation logic
  always begin
    #5 clk = ~ clk;
  end
  
  //dut instantiation
  dut dut_inst(.inp_a(inp_a), inp_b(inp_b) ... );
  
  //test scenario
  initial begin
    //signal assignments for your test scenario #1 
    rst = 0;
    #10;
    inp_a = 0;
    // more statements
    $finish;
  end
  
  //code for waveform dumping
  initial begin
	  $fsdbdumpvars;
	end

endmodule
```

Second testbench file:

```verilog
//File: testbench2.v
`timescale 1ns/1ns
module tb;
  //some signal declarations
  wire out_a, out_b;
  reg inp_a, inp_b;
  reg clk;
  reg rst;
  
  //clock generation logic
  always begin
    #5 clk = ~ clk;
  end
  
  //dut instantiation
  dut dut_inst(.inp_a(inp_a), inp_b(inp_b) ... );
  
  //test scenario
  initial begin
    //signal assignments for your test scenario #2 
    rst = 1;
    #10;
    inp_a = 1;
    // more statements
    $finish;
  end
  
  //code for waveform dumping
  initial begin
	  $fsdbdumpvars;
	end

endmodule
```

And now, you will run two simulations - one for first scenario and one for the second scenario. You will create a Makefile like this:

```makefile
compile_test1:
	${VCS_HOME}/bin/vcs -full64 -sverilog design.v testbench1.v -debug_access+all -kdb -lca
	
compile_test2:
	${VCS_HOME}/bin/vcs -full64 -sverilog design.v testbench2.v -debug_access+all -kdb -lca
	
sim:
	./simv

waves_verdi:
	$(VERDI_HOME)/bin/verdi -ssf novas.fsdb -nologo
	
clean:
	rm -rf .....
```

Then you would run commands in this order:

1. You will first run `make compile_test1`. This will compile the design and testbench 1 (that has scenario 1) and will generate the simulator executable (simv). And you will run `make sim` to run the simulation for the first scenario, and then `make waves_verdi` to open Verdi and debug.
2. After that you can run `make clean` or not. Up to you. Running this will delete the temporary files and the simv (the executable).
3. Then you will run `make compile_test2`. This will compile the design and testbench 1 (that has scenario 1) and will generate the simulator executable (simv). And you will run `make sim` to run the simulation for the second scenario, and then `make waves_verdi` to open Verdi and debug.

This process works, but is complex. It needs two compilations. This can be optimized. We can use a feature of the Verilog (and hence, System Verilog) language called command line arguments. There are two main methods of doing this:

```makefile
$test$plusargs(user_string)

$value$plusargs(user_string, variable)
```

$test$plusargs returns whether a string was provided by a user on the command line during execution.

$value$plusargs returns whether a string was provided by a user on the command line during execution. It also copies the value provided into the specified variable. 

You can search about these online to get more details, but here’s how you can use these for running multiple scenarios/testcases using only a single compilation. Instead of having two testbench files, you would only have one testbench file.

```verilog
//File: testbench.v
`timescale 1ns/1ns
module tb;
  //some signal declarations
  wire out_a, out_b;
  reg inp_a, inp_b;
  reg clk;
  reg rst;
  integer scenario_num;
  
  //clock generation logic
  always begin
    #5 clk = ~ clk;
  end
  
  //dut instantiation
  dut dut_inst(.inp_a(inp_a), inp_b(inp_b) ... );
  
  //test scenarios
  //these don't need to written as tasks. i am just doing this to make the code readable
  task scenario1();
	  //signal assignments for your test scenario # 1
    rst = 0;
    #10;
    inp_a = 0;
    // more statements
  endtask  
  
  task scenario2();
	  //signal assignments for your test scenario #2 
    rst = 1;
    #10;
    inp_a = 1;
    // more statements
  endtask  
  
  //code to choose between the two scenarios
  initial begin
    if (!$test$plusargs("test")) begin
      //test not provided on the command line
      $display("No test provided. Exiting");
      $finish;
    end 
    
    //if we are here, that means the user did provide a test scenario name.
    //this could be a string instead of a decimal value, for more verbose and readable test selection
    $value$plusargs("test=%d",scenario_num);
    
    if (scenario_num == 1) begin
			scenario1();
	    $finish;
    end
    
    if (scenario_num == 2) begin
			scenario2();
	    $finish;
    end
  end  
  
  //code for waveform dumping
  initial begin
	  $fsdbdumpvars;
	end

endmodule
```

Now, your Makefile will change to:

```makefile
compile:
	${VCS_HOME}/bin/vcs -full64 -sverilog design.v testbench.v -debug_access+all -kdb -lca

#Note the +test command line argument being provided a value of 1
sim1:
	./simv +test=1

#Note the +test command line argument being provided a value of 2
sim2:
	./simv +test=2

waves_verdi:
	$(VERDI_HOME)/bin/verdi -ssf novas.fsdb -nologo
	
clean:
	rm -rf .....
```

Then you would run commands in this order:

1. You will first run `make compile`. This will compile the design and testbench and will generate the simulator executable (simv). 
2. Then you will run `make sim1`to run the simulation for the first scenario, and then `make waves_verdi` to open Verdi and debug.
3. Then you will run `make sim2` to run the simulation for the second scenario, and then `make waves_verdi` to open Verdi and debug.

Now, you are able to compile once and run the simulation twice, once for each scenario;

# FSDB Dumping

https://programmerall.com/article/42362153319/

# Apporto Setup

My suggested way to set things up is to set up a private github repo for this class. Then clone the repo in your home directory in the Apporto environment. Then you can push/pull into this repo to keep track of your work and to collaborate with your lab partners. That way you don't have to download/upload files.

For easy code editing, download VSCode in the Apporto environment. You can then run it (it integrates with git as well). You don't need sudo permissions to install vscode. Each student can do this and have VSCode in the home area.

You can also use vim or emacs if you want.