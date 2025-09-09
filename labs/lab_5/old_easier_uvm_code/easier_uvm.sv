  
// Filename: uvm_getting_started_1.sv

//----------------------------------------------------------------------
//  Copyright (c) 2008-2011 by Doulos Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//----------------------------------------------------------------------

// Version 1, 7-Feb-2008  Original OVM tutorial
// Version 2, 2-Oct-2008
// Version 3, 8-Jul-2010  Convert from OVM to UVM-EA
// Version 4, 8-Mar-2011  Convert from UVM-EA to UVM 1.0

// Getting Started with UVM, Tutorial Example 1

// For a full description, see http://www.doulos.com/knowhow/sysverilog/uvm

// Shows the following:
//   uvm_pkg
//   uvm_sequence_item
//   uvm_object_utils
//   uvm_component_utils
//   T::type_id::create (factory)
//   uvm_env
//   uvm_test with run_test() and +UVM_TESTNAME
//   uvm_driver
//   uvm_sequencer
//   uvm_sequence
//   uvm_seq_item_pull_port, get_next_item() and item_done()
//   raise_objection, drop_objection
//   `uvm_info()


`include "uvm_macros.svh"

interface dut_if();

  int addr;
  int data;
  bit r0w1;

  modport test (output addr, data, r0w1);
  modport dut  (input  addr, data, r0w1);

endinterface: dut_if


module dut(dut_if.dut i_f);

  always @(*)
  begin
     $display("DUT received r0w1 = %b, addr = %0d, data = %0d at %0t",
              i_f.r0w1, i_f.addr, i_f.data, $time);
  end
  
endmodule: dut


package my_pkg;

  import uvm_pkg::*;
  
  class my_transaction extends uvm_sequence_item;
  
    `uvm_object_utils(my_transaction)  
  
    rand int addr;
    rand int data;
    rand bit r0w1;
    
    function new (string name = "");
      // Without a string name the transaction would be anonymous
      super.new(name);
    endfunction: new
  
    constraint c_addr { addr >= 0; addr < 256; }
    constraint c_data { data >= 0; data < 256; }
    
  endclass: my_transaction
  
  
  class my_driver extends uvm_driver #(my_transaction);

    `uvm_component_utils(my_driver)
  
    virtual dut_if m_dut_if;                  // For access to the DUT interface

    function new(string name, uvm_component parent);
      super.new(name, parent);
      `uvm_info("", "Called my_driver::new", UVM_NONE);
    endfunction: new
   
    task run_phase(uvm_phase phase);
      `uvm_info("", "Called my_driver::run_phase", UVM_NONE);

      phase.raise_objection(this);
      forever
      begin
        my_transaction tx;
        #10

        phase.drop_objection(this);
        seq_item_port.get_next_item(tx);
        phase.raise_objection(this);
        
        `uvm_info("",$psprintf("Driving cmd = %s, addr = %0d, data = %0d}",
                               (tx.r0w1 ? "W" : "R"), tx.addr, tx.data), UVM_NONE);
        m_dut_if.r0w1 = tx.r0w1;
        m_dut_if.addr = tx.addr;
        m_dut_if.data = tx.data;
        seq_item_port.item_done();
      end
    endtask: run_phase
    
  endclass: my_driver
  
  
  typedef uvm_sequencer #(my_transaction) my_sequencer;   

 
  class my_sequence extends uvm_sequence #(my_transaction);
  
    `uvm_object_utils(my_sequence)
    
    function new (string name = "");
      super.new(name);
    endfunction: new

    task body;
      uvm_test_done.raise_objection(this);
      repeat(10)
      begin
        my_transaction tx;
        tx = my_transaction::type_id::create("tx");
        start_item(tx);
        assert( tx.randomize() );
        finish_item(tx);
      end
      uvm_test_done.drop_objection(this);
    endtask: body

  endclass: my_sequence


  class my_env extends uvm_env;

    `uvm_component_utils(my_env)
 
    my_sequencer  m_sequencer;
    my_driver     m_driver;
  
    function new(string name, uvm_component parent);
      super.new(name, parent);
      `uvm_info("", "Called my_env::new", UVM_NONE);
    endfunction: new
    
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      `uvm_info("", "Called my_env::build_phase", UVM_NONE);

      // Build the driver and sequencer using the factory
      m_driver    = my_driver   ::type_id::create("m_driver",    this);
      m_sequencer = my_sequencer::type_id::create("m_sequencer", this);
    endfunction: build_phase
    
    function void connect_phase(uvm_phase phase);
      `uvm_info("", "Called my_env::connect_phase", UVM_NONE);
      
      m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    endfunction: connect_phase
    
  endclass: my_env
  
  
endpackage: my_pkg


module top;

  import uvm_pkg::*;
  import my_pkg::*;
  
  dut_if dut_if1 ();
  
  dut    dut1 ( .i_f(dut_if1) );

  // Test classes are better placed in a package, but defining the class here
  // avoids the need to introduce set_config_db to connect the virtual interface
  // in this very simple example
  
  class my_test extends uvm_test;
  
    // my_test gets instantiated by means of the +UVM_TESTNAME command line argument and run_test()
    `uvm_component_utils(my_test)
    
    function new(string name, uvm_component parent);
      super.new(name,parent);
      `uvm_info("", "Called my_test::new", UVM_NONE);
    endfunction: new
    
    my_env m_env;   
   
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      `uvm_info("", "Called my_test::build_phase", UVM_NONE);
      
      // Always use the factory instead of new
      m_env = my_env::type_id::create("m_env", this);
    endfunction: build_phase
    
    function void connect_phase(uvm_phase phase);
      `uvm_info("", "Called my_test::connect_phase", UVM_NONE);
      
      // Connect virtual interface in driver to actual interface
      m_env.m_driver.m_dut_if = dut_if1;
    endfunction: connect_phase
    
    task run_phase(uvm_phase phase);
      my_sequence seq;
      `uvm_info("","Called my_test::run_phase", UVM_NONE);
      seq = my_sequence::type_id::create("seq");
      assert( seq.randomize() );
      seq.start( m_env.m_sequencer );
    endtask: run_phase

    function void report_phase(uvm_phase phase);
      `uvm_info("", "Called my_test::report_phase", UVM_NONE);
    endfunction: report_phase

  endclass: my_test
  
  initial
    // Calls static uvm_env::run_test to execute all test phases for all envs & top-level components
    run_test(); // Requires +UVM_TESTNAME at run-time

endmodule: top