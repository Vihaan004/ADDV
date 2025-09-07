`timescale 1ns/1ns

// Minimal FIFO testbench for waveform verification
// Just basic write-read functionality without complex logic

module minimal_fifo_test;

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

    // Clock generation - Same frequency for simplicity
    initial begin
        wclk = 0;
        rclk = 0;
    end
    
    always #5 wclk = ~wclk;   // 10ns period (100MHz)
    always #5 rclk = ~rclk;   // Same frequency

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
        $display("FSDB dump enabled for minimal FIFO test");
    end

    // Simple test sequence
    initial begin
        // Initialize
        wdata = 0;
        winc = 0;
        rinc = 0;
        wrst_n = 0;
        rrst_n = 0;
        
        // Display test mode
        if ($test$plusargs("inject_bug")) begin
            $display("Time %0t: Starting minimal FIFO test WITH BUG INJECTION", $time);
        end else begin
            $display("Time %0t: Starting minimal FIFO test - NORMAL MODE", $time);
        end
        
        // Reset sequence
        #20;
        wrst_n = 1;
        rrst_n = 1;
        #20;
        $display("Time %0t: Reset released - rempty=%b, wfull=%b", $time, rempty, wfull);
        
        // Test 1: Write 5 simple values (3rd write will be dropped if bug injection enabled)
        $display("Time %0t: === Writing 5 values ===", $time);
        write_single(8'h11);  // Write #1
        write_single(8'h22);  // Write #2
        write_single(8'h33);  // Write #3 - WILL BE DROPPED if bug injection on
        write_single(8'h44);  // Write #4
        write_single(8'h55);  // Write #5
        
        $display("Time %0t: After writes - rempty=%b, wfull=%b", $time, rempty, wfull);
        
        // Wait a bit to see stable state
        #50;
        
        // Test 2: Read values back
        $display("Time %0t: === Reading values back ===", $time);
        if ($test$plusargs("inject_bug")) begin
            $display("Time %0t: With bug injection: expecting 0x11, 0x22, 0x44, 0x55 (0x33 dropped)", $time);
        end else begin
            $display("Time %0t: Normal mode: expecting 0x11, 0x22, 0x33, 0x44, 0x55", $time);
        end
        
        read_single();  // Should get 0x11 (normal) or 0x11 (bug)
        read_single();  // Should get 0x22 (normal) or 0x22 (bug)
        read_single();  // Should get 0x33 (normal) or 0x44 (bug) <- DIFFERENCE
        read_single();  // Should get 0x44 (normal) or 0x55 (bug) <- DIFFERENCE  
        read_single();  // Should get 0x55 (normal) or ??? (bug)  <- DIFFERENCE
        
        $display("Time %0t: After reads - rempty=%b, wfull=%b", $time, rempty, wfull);
        
        // Wait to see final state
        #50;
        
        $display("Time %0t: Minimal FIFO test complete", $time);
        $finish;
    end

    // Simple write task
    task write_single(logic [7:0] data);
        begin
            @(posedge wclk);
            wdata = data;
            winc = 1;
            $display("Time %0t: Writing 0x%02x", $time, data);
            
            @(posedge wclk);
            winc = 0;
            
            // Small delay between operations
            repeat(2) @(posedge wclk);
        end
    endtask

    // Simple read task
    task read_single();
        begin
            @(posedge rclk);
            rinc = 1;
            $display("Time %0t: Reading - data available: 0x%02x", $time, rdata);
            
            @(posedge rclk);
            rinc = 0;
            
            // Small delay between operations  
            repeat(2) @(posedge rclk);
        end
    endtask

    // Simple monitor for key signals
    always @(posedge wclk or posedge rclk) begin
        if ($time > 40) begin // Skip initial reset period
            $display("Time %0t: wdata=0x%02x winc=%b | rdata=0x%02x rinc=%b | empty=%b full=%b", 
                     $time, wdata, winc, rdata, rinc, rempty, wfull);
        end
    end

endmodule