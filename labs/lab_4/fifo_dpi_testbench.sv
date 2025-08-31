// Import the C functions using DPI
import "DPI-C" function void fifo_init();
import "DPI-C" function int fifo_push(int data);
import "DPI-C" function int fifo_pop();
import "DPI-C" function int fifo_is_empty();
import "DPI-C" function int fifo_is_full();
import "DPI-C" function int fifo_get_count();

`timescale 1ns/1ns

//////////////////////
// FIFO Checker Module
/////////////////////
module fifo_checker(
    input logic        wclk,
    input logic        rclk,
    input logic        wrst_n,
    input logic        rrst_n,
    input logic [7:0]  wdata,
    input logic        winc,
    input logic        rinc,
    input logic [7:0]  rdata,
    input logic        wfull,
    input logic        rempty
);

    integer c_pop_result;
    integer c_empty, c_full;
    
    // Initialize C model on reset
    initial begin
        fifo_init();
    end
    
    // Monitor reset and reinitialize if needed
    always @(negedge wrst_n or negedge rrst_n) begin
        if (!wrst_n || !rrst_n) begin
            fifo_init();
            $display("Time %0t: C Model reinitialized due to reset", $time);
        end
    end

    // Check write operations
    always @(posedge wclk) begin
        if (wrst_n && winc && !wfull) begin
            if (!fifo_push(wdata)) begin
                $error("Time %0t: C Model rejected write but DUT accepted - data=0x%02x", $time, wdata);
            end
        end else if (wrst_n && winc && wfull) begin
            // Try to push to full FIFO - should fail in C model too
            if (fifo_push(wdata)) begin
                $error("Time %0t: C Model accepted write to full FIFO - data=0x%02x", $time, wdata);
            end
        end
    end

    // Check read operations  
    always @(posedge rclk) begin
        if (rrst_n && rinc && !rempty) begin
            c_pop_result = fifo_pop();
            @(negedge rclk); // Wait for DUT output to settle
            if (c_pop_result != rdata) begin
                $error("Time %0t: Data mismatch - C Model=0x%02x, DUT=0x%02x", $time, c_pop_result, rdata);
            end else begin
                $display("Time %0t: Read Check PASS - data=0x%02x", $time, rdata);
            end
        end else if (rrst_n && rinc && rempty) begin
            // Try to pop from empty FIFO - should fail in C model too
            c_pop_result = fifo_pop();
            if (c_pop_result != -1) begin
                $error("Time %0t: C Model returned data from empty FIFO", $time);
            end
        end
    end

    // Continuously check full/empty flags
    always @(posedge wclk or posedge rclk) begin
        if (wrst_n && rrst_n) begin
            c_empty = fifo_is_empty();
            c_full = fifo_is_full();
            
            #1; // Small delay to let signals settle
            
            if (c_empty != rempty) begin
                $error("Time %0t: Empty flag mismatch - C Model=%0d, DUT=%0d", $time, c_empty, rempty);
            end
            
            if (c_full != wfull) begin
                $error("Time %0t: Full flag mismatch - C Model=%0d, DUT=%0d", $time, c_full, wfull);
            end
        end
    end

endmodule

//////////////////////
// Testbench
/////////////////////
module testbench;

    // FIFO parameters
    parameter DSIZE = 8;
    parameter ASIZE = 4;

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

    // Clock generation
    initial begin
        wclk = 0;
        rclk = 0;
    end
    
    always #5 wclk = ~wclk;   // 100MHz write clock
    always #7 rclk = ~rclk;   // ~71MHz read clock (different frequency)

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

    // Checker instantiation
    fifo_checker checker_inst(
        .wclk(wclk),
        .rclk(rclk),
        .wrst_n(wrst_n),
        .rrst_n(rrst_n),
        .wdata(wdata),
        .winc(winc),
        .rinc(rinc),
        .rdata(rdata),
        .wfull(wfull),
        .rempty(rempty)
    );

    // Test stimulus
    initial begin
        // Initialize
        wdata = 0;
        winc = 0;
        rinc = 0;
        wrst_n = 0;
        rrst_n = 0;
        
        // Waveform dump if requested
        if ($test$plusargs("vcd")) begin
            $dumpfile("fifo_dpi.vcd");
            $dumpvars(0, testbench);
            $display("VCD dump enabled");
        end
        
        // Reset sequence
        #20;
        wrst_n = 1;
        rrst_n = 1;
        #20;
        
        $display("=== Starting FIFO DPI Verification ===");
        
        // Test 1: Write sequential data
        $display("\n--- Test 1: Write Sequential Data ---");
        for (int i = 0; i < 8; i++) begin
            @(posedge wclk);
            wdata = 8'h10 + i;  // Write 0x10, 0x11, 0x12, etc.
            winc = 1;
            @(posedge wclk);
            winc = 0;
            repeat(2) @(posedge wclk); // Add some spacing
        end
        
        // Test 2: Read back data
        $display("\n--- Test 2: Read Back Data ---");
        repeat(6) begin
            @(posedge rclk);
            rinc = 1;
            @(posedge rclk);
            rinc = 0;
            repeat(2) @(posedge rclk); // Add some spacing
        end
        
        // Test 3: Fill FIFO to full
        $display("\n--- Test 3: Fill FIFO to Full ---");
        for (int i = 0; i < 12; i++) begin  // Try to overfill
            @(posedge wclk);
            if (!wfull) begin
                wdata = 8'hA0 + i;
                winc = 1;
                @(posedge wclk);
                winc = 0;
            end else begin
                $display("FIFO is full, stopping writes at iteration %0d", i);
                break;
            end
            @(posedge wclk);
        end
        
        // Test 4: Try to write to full FIFO (should be blocked)
        $display("\n--- Test 4: Attempt Write to Full FIFO ---");
        repeat(2) begin
            @(posedge wclk);
            wdata = 8'hFF;
            winc = 1;
            @(posedge wclk);
            winc = 0;
            @(posedge wclk);
        end
        
        // Test 5: Empty FIFO completely
        $display("\n--- Test 5: Empty FIFO Completely ---");
        repeat(20) begin  // Try to over-read
            @(posedge rclk);
            if (!rempty) begin
                rinc = 1;
                @(posedge rclk);
                rinc = 0;
            end else begin
                $display("FIFO is empty, stopping reads");
                break;
            end
            repeat(2) @(posedge rclk);
        end
        
        // Test 6: Try to read from empty FIFO (should be blocked)
        $display("\n--- Test 6: Attempt Read from Empty FIFO ---");
        repeat(2) begin
            @(posedge rclk);
            rinc = 1;
            @(posedge rclk);
            rinc = 0;
            @(posedge rclk);
        end
        
        // Test 7: Concurrent operations
        $display("\n--- Test 7: Concurrent Write/Read Operations ---");
        fork
            // Write process
            begin
                for (int i = 0; i < 6; i++) begin
                    @(posedge wclk);
                    if (!wfull) begin
                        wdata = 8'h50 + i;
                        winc = 1;
                        @(posedge wclk);
                        winc = 0;
                        repeat(3) @(posedge wclk); // Variable delay
                    end
                end
            end
            
            // Read process
            begin
                #50; // Start reading after some writes
                repeat(4) begin
                    @(posedge rclk);
                    if (!rempty) begin
                        rinc = 1;
                        @(posedge rclk);
                        rinc = 0;
                        repeat(4) @(posedge rclk); // Variable delay
                    end
                end
            end
        join
        
        #200;
        $display("\n=== FIFO DPI Verification Complete ===");
        $finish;
    end

    // Monitor for debugging
    initial begin
        $monitor("Time %0t: wfull=%b, rempty=%b, wdata=0x%02x, winc=%b, rinc=%b, rdata=0x%02x", 
                 $time, wfull, rempty, wdata, winc, rinc, rdata);
    end

endmodule
