import uvm_pkg::*;
`include "uvm_macros.svh"

class instruction extends uvm_transaction;
  rand bit [4:0] reg_a, reg_b, reg_c;
  rand bit [5:0] opcode, funct;
  rand bit [31:0] mem_addr;
  rand bit [15:0] immediate;
  rand bit [15:0] branch_offset;
  bit [31:0] pc;
  bit taken;

  //sets registers to only be $1, $2, $3, $4
  constraint unique_regs {
    soft reg_a inside {[1:4]};   //rt
    soft reg_b inside {[1:4]};   //rs
    soft reg_c inside {[1:4]};   //rd
  }

  //generate valid opcodes
  constraint valid_opcode {
    soft opcode inside {6'b000000, 6'b100011, 6'b101011, 6'b000100}; //R-type, LW, SW, BEQ
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
    (opcode == 6'b100011 || opcode == 6'b101011) -> soft (mem_addr inside {0, 4, 8, 12} && reg_a == 0);
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
  endfunction

  //generates a single random instruction 
  function void generate_individual();

    instruction instr = new();
    assert(instr.randomize() with {opcode inside {6'b000000, 6'b100011, 6'b101011}; });

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
    branch_instr.taken = taken;
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

    //generate instr addi $0 $0 0?
    //generate random values and store to reg $5-$8
    //sw instructions to save them to memory

    instruction setup_instr;

    for (int i = 5; i < 9; i++) begin
      setup_instr = new();
      assert(setup_instr.randomize() with {
        opcode == 6'b001000 &&
        reg_a == i &&
        reg_b == 0 &&
        immediate inside {[1:65534]};
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

class instr_monitor extends uvm_monitor;
  `uvm_component_utils(instr_monitor)

  virtual instr_mem_if vif;

  uvm_analysis_port #(instruction) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction: new

  function void build_phase(uvm_phase phase);
    //Get vif from resource db
    super.build_phase(phase);
    if (!uvm_config_db#(virtual instr_mem_if)::get(this, "", "instr_mem_if", vif))
      `uvm_fatal("vif", "Virtual interface not set!")
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    instruction tr;
    phase.raise_objection(this);

    @(negedge vif.reset);
    //wait for reset
    forever begin
      @(posedge vif.clk);
      //tr = new();
      tr = instruction::type_id::create
          (.name("tr"), .contxt(get_full_name()));
      tr.opcode = vif.instr[31:26];
      tr.funct = vif.instr[5:0];
      tr.reg_a = vif.instr[25:21];
      tr.reg_b = vif.instr[20:16];
      tr.reg_c = vif.instr[15:11];
      tr.mem_addr = vif.instr[15:0];
      tr.branch_offset = vif.instr[15:0];
      tr.immediate = vif.instr[15:0];
      tr.pc = vif.pc;
      ap.write(tr);
    end
    
    phase.drop_objection(this);
  endtask
endclass

class instr_coverage extends uvm_subscriber #(instruction);
  `uvm_component_utils(instr_coverage)

  uvm_tlm_analysis_fifo #(instruction) fifo;

  typedef enum {
    ADD, AND, LW, SW, BEQ, ADDI, UNKNOWN
  } instr_type_e;

  // ------ Covergroup parameters ------
  bit [5:0] opcode, funct;
  bit [4:0] reg_a, reg_b, reg_c;
  bit [15:0] immediate, branch_offset;
  bit [31:0] mem_addr;
  bit taken;

  instr_type_e prev_type, curr_type;
  bit mem_dep, reg_dep;
  bit is_lw_sw, is_sw_lw;

  // ------ Covergroups ------
  covergroup instr_fields_cg;
    coverpoint opcode {
      bins rtype  = {6'b000000};
      bins sw     = {6'b101011};
      bins lw     = {6'b100011};
      bins beq    = {6'b000100};
    }
    coverpoint reg_a { bins regs = {[1:4]}; }
    coverpoint reg_b { bins regs = {[1:4]}; }
    coverpoint reg_c { bins regs = {[1:4]}; }
    coverpoint funct {
      bins add_r = {6'b100000};
      bins and_r = {6'b100100};
    }
    coverpoint immediate { bins imm_val = {[0:65534]}; }
    coverpoint mem_addr {
      bins mem_val_addr0 = {0};
      bins mem_val_addr1 = {4};
      bins mem_val_addr2 = {8};
      bins mem_val_addr3 = {12};
    }
    coverpoint branch_offset { bins branch_offsets = {1, 2, 3}; }
    coverpoint taken {
      bins not_taken = {0};
      bins was_taken = {1};
    }
  endgroup

  covergroup instr_order_cg;
    coverpoint is_lw_sw {
      bins yes = {1};
      bins no  = {0};
    }

    coverpoint is_sw_lw {
      bins yes = {1};
      bins no  = {0};
    }

    coverpoint mem_dep {
      bins yes_mem_hazard = {1};
      bins no_mem_hazard  = {0};
    }

    coverpoint reg_dep {
      bins yes_reg_dep = {1};
      bins no_reg_dep  = {0};
    }
  endgroup



  // Constructors
  function new(string name, uvm_component parent);
    super.new(name, parent);
    fifo = new("fifo");
    instr_fields_cg = new();
    instr_order_cg  = new();
  endfunction

  function instr_type_e decode_instr_type(instruction instr);
    case (instr.opcode)
      6'b000000: begin
        case(instr.funct)
          6'b100000: return ADD;
          6'b100100: return AND;
          default:   return UNKNOWN;
        endcase
      end
      6'b100011: return LW;
      6'b101011: return SW;
      6'b000100: return BEQ;
      6'b001000: return ADDI;
      default:   return UNKNOWN;
    endcase
  endfunction

  function void write(instruction t);
    fifo.write(t); 
  endfunction


  task run_phase(uvm_phase phase);
    instruction prev;
    instruction curr;
    phase.raise_objection(this);

    fifo.get(prev);

    forever begin
      fifo.get(curr);

      // Assign fields for covergroup
      opcode        = curr.opcode;
      funct         = curr.funct;
      reg_a         = curr.reg_a;
      reg_b         = curr.reg_b;
      reg_c         = curr.reg_c;
      immediate     = curr.immediate;
      branch_offset = curr.branch_offset;
      mem_addr      = curr.mem_addr;
      taken         = curr.taken;

      instr_fields_cg.sample();

      prev_type = decode_instr_type(prev);
      curr_type = decode_instr_type(curr);

      is_lw_sw = (prev_type == LW && curr_type == SW);
      is_sw_lw = (prev_type == SW && curr_type == LW);


      reg_dep = (
        (curr.reg_a == prev.reg_c && curr.reg_a != 0) ||
        (curr.reg_b == prev.reg_c && curr.reg_b != 0)
      );

      mem_dep = (
        ((prev_type == LW || prev_type == SW) &&
         (curr_type == LW || curr_type == SW)) &&
        (prev.mem_addr == curr.mem_addr)
      );

      instr_order_cg.sample();

      prev = curr;
    end

    phase.drop_objection(this);
  endtask

endclass

class instr_env extends uvm_env;
  `uvm_component_utils(instr_env)

  instr_monitor mon;
  instr_coverage cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = instr_monitor::type_id::create("mon", this);
    cov = instr_coverage::type_id::create("cov", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    mon.ap.connect(cov.fifo.analysis_export);
  endfunction
endclass

class my_test extends uvm_test;

    instr_env env;

    `uvm_component_utils(my_test)

    function new (string name = "my_test", uvm_component parent = null);
      super.new (name, parent);
    endfunction

    function void build_phase (uvm_phase phase);
         super.build_phase (phase);
         env  = instr_env::type_id::create ("my_env", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
    endfunction
endclass

module testbench;

  logic clk, reset;
  logic [31:0] writedata, dataadr;
  logic memwrite;

  instr_mem_if vif(.clk(clk), .reset(reset));

  top dut(.clk(clk), .reset(reset), .writedata(writedata), .dataadr(dataadr), .memwrite(memwrite));

  assign vif.pc = {dut.pc[7:2], 2'b00};
  assign vif.instr = dut.instr;

  instruction_generator gen;

  always begin
    #5 clk = ~clk;
  end

  initial begin
    uvm_config_db#(virtual instr_mem_if)::set(null, "uvm_test_top.*", "instr_mem_if", vif);
    $fsdbDumpMDA();
    $fsdbDumpvars();
    //Code from the instr generator part:
    gen = new();
    gen.generate_sequence();
    gen.generate_machine_code();
    gen.display_all();
    //Note you will merge the codes from the instr generator and the coverage collector properly. I'm just showing something basic.
    $readmemh("instruction_file.memh", dut.imem.RAM);
    run_test("my_test");
    //Copy memory from gen to the instr mem
    //OR: Call $readmemh on that file you wrote using $writememh
    //Deassert reset
  end

  initial begin
    clk = 0;
    reset = 1;
    @(posedge clk);
    @(posedge clk);
    reset = 0;
    repeat(70) @(posedge clk);
    $display("\nseed: %d\n", $get_initial_random_seed());
    $finish;
  end
endmodule
