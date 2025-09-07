`timescale 1ns/1ns

// Simple FIFO testbench to debug basic functionality
// Import the C functions using DPI
import "DPI-C" function void fifo_init();
import "DPI-C" function int fifo_push(int data);
import "DPI-C" function int fifo_pop();
import "DPI-C" function int fifo_is_empty();
import "DPI-C" function int fifo_is_full();

module simple_fifo_test;

    // FIFO parameters
    parameter int DSIZE = 8;
    parameter int ASIZE = 4;

    // Signals
    logic [DSIZE-1:0] rdata;
    logic             wfull;
    logic             rempty;
    logic             almost_full;
    logic             almost_empty;
    logic [DSIZE-1:0] wdata;
    logic             winc;
    logic             wclk;
    logic             wrst_n;
    logic             rinc;
    logic             rclk;
    logic             rrst_n;

    // Test control
    integer c_result;
    integer test_step = 0;

    // Clock generation - Using same frequency to avoid async issues initially
    initial begin
        wclk = 0;
        rclk = 0;
    end
    
    always #5 wclk = ~wclk;   // 10ns period
    always #5 rclk = ~rclk;   // Same frequency for initial testing

    // DUT instantiation
    async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE)) dut_inst (
        .rdata(rdata),
        .wfull(wfull),
        .rempty(rempty),
        .almost_full(almost_full),
        .almost_empty(almost_empty),
        .wdata(wdata),
        .winc(winc),
        .wclk(wclk),
        .wrst_n(wrst_n),
        .rinc(rinc),
        .rclk(rclk),
        .rrst_n(rrst_n)
    );

    // Waveform dump
    initial begin
        $fsdbDumpvars();
        $display("FSDB dump enabled");
    end

    // Test sequence
    initial begin
        // Initialize signals
        wdata = 0;
        winc = 0;
        rinc = 0;
        wrst_n = 0;
        rrst_n = 0;
        
        // Initialize C model
        fifo_init();
        $display("Time %0t: C Model and DUT initialized", $time);
        
        // Reset sequence
        #20;
        wrst_n = 1;
        rrst_n = 1;
        #10;
        $display("Time %0t: Reset released", $time);
        
        // Check initial state
        $display("Time %0t: Initial state - DUT: rempty=%b, wfull=%b", $time, rempty, wfull);
        $display("Time %0t: Initial state - C Model: empty=%0d, full=%0d", $time, fifo_is_empty(), fifo_is_full());
        
        // Test 1: Write 4 simple values
        $display("\n=== TEST 1: Write 4 Values ===");
        test_step = 1;
        
        write_data(8'hAA);
        write_data(8'hBB); 
        write_data(8'hCC);
        write_data(8'hDD);
        
        $display("Time %0t: After 4 writes - DUT: rempty=%b, wfull=%b", $time, rempty, wfull);
        $display("Time %0t: After 4 writes - C Model: empty=%0d, full=%0d", $time, fifo_is_empty(), fifo_is_full());
        
        // Wait a bit before reading
        repeat(5) @(posedge rclk);
        
        // Test 2: Read 4 values back
        $display("\n=== TEST 2: Read 4 Values ===");
        test_step = 2;
        
        read_and_check();
        read_and_check();
        read_and_check();
        read_and_check();
        
        $display("Time %0t: After 4 reads - DUT: rempty=%b, wfull=%b", $time, rempty, wfull);
        $display("Time %0t: After 4 reads - C Model: empty=%0d, full=%0d", $time, fifo_is_empty(), fifo_is_full());
        
        // Test 3: Write and read alternating
        $display("\n=== TEST 3: Write-Read Alternating ===");
        test_step = 3;
        
        write_data(8'h11);
        read_and_check();
        write_data(8'h22);
        read_and_check();
        
        repeat(10) @(posedge wclk);
        $display("\n=== Simple FIFO Test Complete ===");
        $finish;
    end

    // Task to write data
    task write_data(logic [7:0] data);
        begin
            @(posedge wclk);
            wdata = data;
            winc = 1;
            
            // Call C model push
            c_result = fifo_push(data);
            $display("Time %0t: WRITE - DUT: wdata=0x%02x, winc=1, C Model push result=%0d", $time, data, c_result);
            
            @(posedge wclk);
            winc = 0;
            
            // Give some settling time
            repeat(2) @(posedge wclk);
        end
    endtask

    // Task to read and check data - Fixed timing for proper FIFO read
    task read_and_check();
        begin
            // Capture the data BEFORE asserting rinc (this is the data we should get)
            logic [7:0] expected_data;
            expected_data = rdata;  // This is the current data available
            
            @(posedge rclk);
            rinc = 1;
            
            // Call C model pop (should match the data that was visible before rinc)
            c_result = fifo_pop();
            
            @(posedge rclk);
            rinc = 0;
            
            // For asynchronous read FIFO, compare with the data that was available
            $display("Time %0t: READ - Expected data (before rinc)=0x%02x, C Model pop result=0x%02x", $time, expected_data, c_result);
            
            if (c_result != expected_data) begin
                $error("Time %0t: MISMATCH - C Model=0x%02x, DUT Expected=0x%02x", $time, c_result, expected_data);
            end else begin
                $display("Time %0t: MATCH - Both show 0x%02x", $time, expected_data);
            end
            
            // Give some settling time
            repeat(2) @(posedge rclk);
        end
    endtask

    // Monitor for continuous display
    always @(posedge wclk or posedge rclk) begin
        if ($time > 0) begin
            $display("Time %0t: Monitor - wdata=0x%02x, winc=%b, rdata=0x%02x, rinc=%b, empty=%b, full=%b", 
                     $time, wdata, winc, rdata, rinc, rempty, wfull);
        end
    end

endmodule