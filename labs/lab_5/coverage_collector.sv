// Part 3: Monitor + Coverage + Env + Test + Testbench
`include "uvm_macros.svh"
import uvm_pkg::*;

// Lightweight transaction observed by the monitor
class instr_tx extends uvm_object;
  `uvm_object_utils(instr_tx)
  // Decoded fields from fetched instruction
  rand bit [5:0] opcode, funct;
  rand bit [4:0] reg_a, reg_b, reg_c; // rt, rs, rd fields mapping same as Part 2
  rand bit [15:0] immediate, branch_offset;
  rand bit [31:0] mem_addr; // reuse lower 16 for LW/SW
  bit [31:0] pc;            // PC of this instruction
  bit taken;                // For BEQ, whether taken (computed by PC flow)

  function new(string name = "instr_tx");
    super.new(name);
  endfunction
endclass

// Monitor: watches instruction fetch interface and publishes instr_tx
class instr_monitor extends uvm_monitor;
  `uvm_component_utils(instr_monitor)
  virtual instr_mem_if vif;
  uvm_analysis_port #(instr_tx) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual instr_mem_if)::get(this, "", "instr_mem_if", vif))
      `uvm_fatal("vif", "Virtual instr_mem_if not set")
  endfunction

  task run_phase(uvm_phase phase);
    bit first = 1;
    bit [31:0] prev_pc, prev_instr;
    bit [31:0] curr_pc, curr_instr;
    instr_tx tr;

    phase.raise_objection(this);
    @(negedge vif.reset);
    forever begin
      @(posedge vif.clk);
      curr_pc    = vif.pc;
      curr_instr = vif.instr;

      if (!first) begin
        tr = instr_tx::type_id::create("tr", this);
        // Decode previous instruction word into fields
        tr.opcode        = prev_instr[31:26];
        tr.funct         = prev_instr[5:0];
        tr.reg_a         = prev_instr[20:16];
        tr.reg_b         = prev_instr[25:21];
        tr.reg_c         = prev_instr[15:11];
        tr.immediate     = prev_instr[15:0];
        tr.branch_offset = prev_instr[15:0];
        tr.mem_addr      = {16'b0, prev_instr[15:0]};
        tr.pc            = prev_pc;

        // Compute BEQ taken by observing PC progression
        if (tr.opcode == 6'b000100) begin
          bit [31:0] target_pc = prev_pc + 32'd4 + { {14{1'b0}}, tr.branch_offset, 2'b00 };
          tr.taken = (curr_pc == target_pc);
        end else begin
          tr.taken = 1'b0;
        end
        ap.write(tr);
      end

      prev_pc    = curr_pc;
      prev_instr = curr_instr;
      first = 0;
    end
    phase.drop_objection(this);
  endtask
endclass

// Coverage subscriber
class instr_coverage extends uvm_subscriber #(instr_tx);
  `uvm_component_utils(instr_coverage)

  uvm_tlm_analysis_fifo #(instr_tx) fifo;

  typedef enum { ADD, AND, LW, SW, BEQ, ADDI, UNKNOWN } instr_type_e;

  // Shadow fields for covergroups
  bit [5:0]  opcode, funct;
  bit [4:0]  reg_a, reg_b, reg_c;
  bit [15:0] immediate, branch_offset;
  bit [31:0] mem_addr;
  bit        taken;

  instr_type_e prev_type, curr_type;
  bit mem_dep, reg_dep;
  bit is_lw_sw, is_sw_lw;

  covergroup instr_fields_cg;
    coverpoint opcode {
      bins rtype = {6'b000000};
      bins lw    = {6'b100011};
      bins sw    = {6'b101011};
      bins beq   = {6'b000100};
    }
    coverpoint funct {
      bins add_r = {6'b100000};
      bins and_r = {6'b100100};
    }
    coverpoint reg_a { bins regs_a = {[1:4]}; }
    coverpoint reg_b { bins regs_b = {[1:4]}; }
    coverpoint reg_c { bins regs_c = {[1:4]}; }
    coverpoint immediate { bins imm_range[] = {[0:65535]}; }
    coverpoint mem_addr {
      bins a0 = {0}; bins a4 = {4}; bins a8 = {8}; bins aC = {12};
    }
    coverpoint branch_offset { bins bo = {1,2,3,4}; }
    coverpoint taken { bins not_taken = {0}; bins was_taken = {1}; }
  endgroup

  covergroup instr_order_cg;
    coverpoint is_lw_sw { bins yes = {1}; bins no = {0}; }
    coverpoint is_sw_lw { bins yes = {1}; bins no = {0}; }
    coverpoint mem_dep  { bins dep = {1}; bins nde = {0}; }
    coverpoint reg_dep  { bins dep = {1}; bins nde = {0}; }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    fifo = new("fifo");
    instr_fields_cg = new();
    instr_order_cg  = new();
  endfunction

  function instr_type_e decode_type(instr_tx t);
    case (t.opcode)
      6'b000000: begin
        case (t.funct)
          6'b100000: return ADD; // ADD
          6'b100100: return AND; // AND
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

  function void write(instr_tx t);
    fifo.write(t);
  endfunction

  task run_phase(uvm_phase phase);
    instr_tx prev, curr;
    phase.raise_objection(this);

    fifo.get(prev); // seed previous
    forever begin
      fifo.get(curr);

      // Populate mirrors for covergroups
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

      prev_type = decode_type(prev);
      curr_type = decode_type(curr);
      is_lw_sw  = (prev_type == LW && curr_type == SW);
      is_sw_lw  = (prev_type == SW && curr_type == LW);

      reg_dep = ((curr.reg_a == prev.reg_c && curr.reg_a != 0) ||
                 (curr.reg_b == prev.reg_c && curr.reg_b != 0));

      mem_dep = ((prev_type == LW || prev_type == SW) &&
                 (curr_type == LW || curr_type == SW) &&
                 (prev.mem_addr == curr.mem_addr));

      instr_order_cg.sample();

      prev = curr;
    end

    phase.drop_objection(this);
  endtask
endclass

class instr_env extends uvm_env;
  `uvm_component_utils(instr_env)
  instr_monitor  mon;
  instr_coverage cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = instr_monitor ::type_id::create("mon", this);
    cov = instr_coverage::type_id::create("cov", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    mon.ap.connect(cov.analysis_export);
  endfunction
endclass

class my_test extends uvm_test;
  `uvm_component_utils(my_test)
  instr_env env;

  function new(string name = "my_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = instr_env::type_id::create("env", this);
  endfunction
endclass

// Testbench that reuses Part 2 generator and DUT
module testbench;
  import uvm_pkg::*;

  logic clk, reset;
  logic [31:0] writedata, dataadr;
  logic memwrite;

  // Interface for monitor
  instr_mem_if vif(.clk(clk), .reset(reset));

  // DUT
  top dut(.clk(clk), .reset(reset), .writedata(writedata), .dataadr(dataadr), .memwrite(memwrite));

  // Map internal signals to vif (assuming visibility of pc/instr names as in top)
  assign vif.pc    = {dut.pc[7:2], 2'b00};
  assign vif.instr = dut.instr;

  // Generator from Part 2
  instruction_generator gen;

  always #5 clk = ~clk;

  initial begin
    clk = 0;
    reset = 1;
    uvm_config_db#(virtual instr_mem_if)::set(null, "uvm_test_top.*", "instr_mem_if", vif);
    $fsdbDumpMDA();
    $fsdbDumpvars();

    // Build program and load into imem
    gen = new();
    gen.generate_sequence();
    gen.generate_machine_code();
    gen.display_all();
    $readmemh("instruction_file.memh", dut.imem.RAM);

    // Release reset and run UVM
    repeat (2) @(posedge clk);
    reset = 0;
    run_test("my_test");
  end

  initial begin
    // End sim automatically after a bounded time window
    repeat (150) @(posedge clk);
    $display("\nseed: %0d\n", $get_initial_random_seed());
    $finish;
  end
endmodule
