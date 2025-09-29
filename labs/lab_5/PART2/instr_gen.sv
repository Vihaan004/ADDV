`include "uvm_macros.svh"
import uvm_pkg::*;
//Add -ntb_opts uvm to the VCS command line

class instruction extends uvm_transaction;
  rand bit [4:0] reg_a, reg_b, reg_c;
  rand bit [5:0] opcode, funct;
  rand bit [31:0] mem_addr;
  rand bit [15:0] immediate;
  rand bit [15:0] branch_offset;

  //sets registers to only be $1, $2, $3, $4
  constraint unique_regs {
    soft reg_a inside {[1:4]};   //rt
    soft reg_b inside {[1:4]};   //rs
    soft reg_c inside {[1:4]};   //rd
  }

  //generate valid opcodes
  constraint valid_opcode {
    soft opcode dist {6'b000000:= 0, 6'b100011:=30, 6'b101011:= 50, 6'b000100:= 0}; //R-type, LW, SW, BEQ
  }

  //ensure valid R-type instr
  constraint valid_funct {
    if (opcode == 6'b000000) soft funct inside {6'b100000, 6'b100100}; //ADD, AND
    else funct inside {0};
  }

  //limit immediate value to 16 bits
  constraint small_immediate {
    soft immediate inside {[0:65534]};
  }
  
  //limit memory to the first 4 addresses
  constraint valid_mem_addr {
    (opcode == 6'b100011 || opcode == 6'b101011) -> soft (mem_addr inside {0, 4, 8, 12} && reg_b == 0);
  }

  //limit branching up to 3 instructions
  constraint valid_branch_offset {
    if (opcode == 6'b000100) branch_offset inside {1, 2, 3};
    else branch_offset inside {0};
  }

  `uvm_object_utils(instruction)

  function new(string name = "instruction");
    super.new(name);
  endfunction

  function void print_me();
    $display("Opcode: %h\nFunct: %h\nreg_a: %d, reg_b: %d, reg_c: %d\nimmediate: %d\nmem_addr: %h\n, branch_offset: %d\n", this.opcode, this.funct, this.reg_a, this.reg_b, this.reg_c, this.immediate, this.mem_addr, this.branch_offset);
  endfunction
endclass: instruction

class instruction_generator;
  instruction instr_list[$];
  bit [31:0] machine_code_list[$];

  function new(string name = "gen");
    //this.instr_list = new[0];
    //this.machine_code_list = new[0];
  endfunction

  //generates a single random instruction 
  function void generate_individual();

    instruction instr = new();
    assert(instr.randomize());

    //instr.print_me();

    instr_list.push_back(instr);
  endfunction

  function void generate_pairs();
    instruction tx1 = new();
    instruction tx2 = new();
    bit[4:0] dep_reg;
    bit[15:0] dep_mem;

    assert(std::randomize(dep_reg) with {dep_reg inside {[1:4]}; });
    assert(std::randomize(dep_mem) with {dep_mem inside {0, 4, 8, 12}; });

    assert(tx1.randomize() with {opcode inside {6'b000000, 6'b100011, 6'b101011}; });

    if (tx1.opcode == 6'b000000) begin //If R-type, random R-type with data dep
      tx1.reg_c = dep_reg;
      assert(tx2.randomize() with {opcode == 6'b000000 && reg_a == dep_reg; });
    end else if (tx1.opcode == 6'b100011) begin  //If LW, randomize SW with mem dep
      tx1.mem_addr = dep_mem;
      assert(tx2.randomize() with {opcode == 6'b101011 && mem_addr == dep_mem; });
    end else if (tx1.opcode == 6'b101011) begin //If SW, randomize LW with mem dep
      tx1.mem_addr = dep_mem;
      assert(tx2.randomize() with {opcode == 6'b100011 && mem_addr == dep_mem; });
    end

    instr_list.push_back(tx1);
    instr_list.push_back(tx2);
  endfunction

  function void insert_gaps();
    instruction gap_instr;
    int gap = $urandom_range(1,4);

    instruction prev_instr = instr_list[instr_list.size() -1];
    //checks for data dep
    for (int i = 0; i < gap; i++) begin
      gap_instr = new();
      assert(gap_instr.randomize() with {opcode == 6'b000000 && !(reg_a inside {prev_instr.reg_c}) && !(reg_b inside {prev_instr.reg_c}); });
      instr_list.push_back(gap_instr);
    end
  endfunction

  function void generate_branch();
    instruction branch_instr;
    bit taken;
    bit [4:0] dep_reg;
    int offset;

    //randomize taken and equality reg
    assert(std::randomize(taken));
    assert(std::randomize(dep_reg) with {dep_reg inside {[1:4]}; });
    branch_instr = new();
    assert(branch_instr.randomize() with {opcode == 6'b000100 && reg_a == dep_reg && reg_b == (taken ? dep_reg : (dep_reg % 4 + 1)); });
    //determines offset
    offset = branch_instr.branch_offset;

    instr_list.push_back(branch_instr);

    //if not taken, generate a fallback instruction
    if (!taken) begin
      generate_individual();
    end

    //insert gaps and final branched instruction
    for (int i = 1; i < offset; i++) begin
      insert_gaps();
    end
    generate_individual();

  endfunction

  function void generate_sequence();

    //generate random values and store to reg $5-$8
    //sw instructions to save them to memory
    //generate random values to reg 1-4

    instruction setup_instr;

    for (int i = 5; i < 9; i++) begin
      setup_instr = new();
      assert(setup_instr.randomize() with {
        opcode == 6'b001000 &&
        reg_a == i &&
        reg_b == 0 &&
        immediate inside {[1:256]};
      });
      instr_list.push_back(setup_instr);
    end

    begin
      int mem_val = 0;
      for (int i = 5; i < 9; i++) begin
        setup_instr = new();
        assert(setup_instr.randomize() with {
          opcode == 6'b101011 &&
          reg_a == i &&
          reg_b == 0 &&
          mem_addr == mem_val;
        });
        instr_list.push_back(setup_instr);
        mem_val += 4;
      end
    end

    setup_instr = new();
    assert(setup_instr.randomize() with {opcode == 6'b001000 && reg_a == 1 && reg_b == 0 && reg_c == 0 && immediate inside {[1:256]}; });
    instr_list.push_back(setup_instr);

    setup_instr = new();
    assert(setup_instr.randomize() with {opcode == 6'b001000 && reg_a == 2 && reg_b == 0 && reg_c == 0 && immediate inside {[1:256]}; });
    instr_list.push_back(setup_instr);

    setup_instr = new();
    assert(setup_instr.randomize() with {opcode == 6'b001000 && reg_a == 3 && reg_b == 0 && reg_c == 0 && immediate inside {[1:256]}; });
    instr_list.push_back(setup_instr);

    setup_instr = new();
    assert(setup_instr.randomize() with {opcode == 6'b001000 && reg_a == 4 && reg_b == 0 && reg_c == 0 && immediate inside {[1:256]}; });
    instr_list.push_back(setup_instr);

    //instruction sequence
    for (int i = 0; i < 2; i++) begin
      for (int i = 0; i < 3; i++) begin
        generate_individual();
      end

      generate_pairs();
      insert_gaps();

      generate_branch();

      for (int i = 0; i < 3; i++) begin
        generate_individual();
      end

      for (int i = 0; i < 3; i++) begin
        generate_pairs();
      end
    end
  
  endfunction

  function void generate_machine_code();

    bit [31:0] instr_word; 

    foreach (instr_list[i]) begin
      instruction instr = instr_list[i];

      case(instr.opcode) 

        //R-Type
        6'b000000: begin
          instr_word = {instr.opcode, instr.reg_b, instr.reg_a, instr.reg_c, 5'b00000, instr.funct};
        end
        //ADDI
        6'b001000: begin
          instr_word = {instr.opcode, instr.reg_b, instr.reg_a, instr.immediate};
        end
        //LW and SW
        6'b100011, 6'b101011: begin
          instr_word = {instr.opcode, instr.reg_b, instr.reg_a, instr.mem_addr[15:0]};
        end
        //BEQ
        6'b000100: begin
          instr_word = {instr.opcode, instr.reg_b, instr.reg_a, instr.branch_offset};
        end

        default: begin
          $display("Unknown instruction, opcode: %b at instr: \n", instr.opcode, i);
          instr_word = 32'h00000000;
        end
      endcase

      machine_code_list.push_back(instr_word);
    end
  
    $writememh ("instruction_file.memh", machine_code_list);
  endfunction

  function void display_all();
    foreach (instr_list[i]) begin
      instr_list[i].print_me();
    end
  endfunction
endclass: instruction_generator

module testbench;


  logic clk;
  logic reset;
  logic [31:0] writedata, dataadr;
  logic memwrite;

  top dut(.clk(clk), .reset(reset), .writedata(writedata), .dataadr(dataadr), .memwrite(memwrite));

  instruction_generator gen;

  always begin
    #5 clk = ~clk;
  end

  initial begin
    clk = 0;
    $fsdbDumpMDA();
    $fsdbDumpvars();

    gen = new();
    gen.generate_sequence();
    gen.generate_machine_code();
    gen.display_all();
    $readmemh("instruction_file.memh", dut.imem.RAM);
    $display("\nseed: %d\n", $get_initial_random_seed());
    reset = 1;
    //Copy memory from gen to the instr mem
    //OR: Call $readmemh on that file you wrote using $writememh
    //$readmemh("instruction_file.memh", dut.imem.RAM);
    //Deassert reset
    @(posedge clk);
    @(posedge clk);
    reset = 0;

    repeat(80) @(posedge clk);
    $finish;
  end
endmodule

