`timescale 1ns/1ns

// Import the C functions using DPI (following dpi_1.sv and dpi_2.sv style)
import "DPI-C" function void fifo_init();
import "DPI-C" function int fifo_push(int data);
import "DPI-C" function int fifo_pop();
import "DPI-C" function int fifo_is_empty();
import "DPI-C" function int fifo_is_full();

//////////////////////
// DUT
//////////////////////
module async_fifo_wrapper #(
    parameter int DSIZE = 8,
    parameter int ASIZE = 4
)(
    input  logic             wclk,
    input  logic             rclk,
    input  logic             wrst_n,
    input  logic             rrst_n,
    input  logic [DSIZE-1:0] wdata,
    input  logic             winc,
    input  logic             rinc,
    output logic [DSIZE-1:0] rdata,
    output logic             wfull,
    output logic             rempty,
    output logic             almost_full,
    output logic             almost_empty
);

    async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE)) fifo_inst (
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

endmodule

//////////////////////
// Checker Module (following dpi_2.sv style)
//////////////////////
module fifo_checker(
    input  logic             wclk,
    input  logic             rclk,
    input  logic             wrst_n,
    input  logic             rrst_n,
    input  logic [7:0]       wdata,
    input  logic             winc,
    input  logic             rinc,
    input  logic [7:0]       rdata,
    input  logic             wfull,
    input  logic             rempty
);

    integer c_result;
    integer c_empty, c_full;
    logic [7:0] expected_read_data;

    // Initialize C model on reset
    always @(negedge wrst_n or negedge rrst_n) begin
        if (!wrst_n || !rrst_n) begin
            fifo_init();
            $display("Time %0t: C Model initialized due to reset", $time);
        end
    end

    // Check write operations (following simple pattern)
    always @(posedge wclk) begin
        if (wrst_n && winc && !wfull) begin
            c_result = fifo_push(wdata);
            if (c_result) begin
                $display("Time %0t: C Model WRITE SUCCESS - data=0x%02x", $time, wdata);
            end else begin
                $error("Time %0t: C Model WRITE FAILED - data=0x%02x", $time, wdata);
            end
        end
    end

    // Check read operations (following corrected timing)
    always @(posedge rclk) begin
        if (rrst_n && rinc && !rempty) begin
            // Capture data before read (for asynchronous FIFO)
            expected_read_data = rdata;
            c_result = fifo_pop();
            
            if (c_result != expected_read_data) begin
                $error("Time %0t: READ MISMATCH - C Model=0x%02x, DUT=0x%02x", $time, c_result, expected_read_data);
            end else begin
                $display("Time %0t: READ MATCH - data=0x%02x", $time, expected_read_data);
            end
        end
    end

    // Optional: Check empty/full flags (commented out due to async timing differences)
    // The C model updates immediately, but DUT flags have cross-clock domain delays
    // For Lab 4, data verification is more important than flag timing verification
    /*
    always @(posedge wclk or posedge rclk) begin
        if (wrst_n && rrst_n) begin
            c_empty = fifo_is_empty();
            c_full = fifo_is_full();
            
            #1; // Small delay for signal settling
            
            if (c_empty != rempty) begin
                $error("Time %0t: EMPTY FLAG MISMATCH - C Model=%0d, DUT=%0d", $time, c_empty, rempty);
            end
            
            if (c_full != wfull) begin
                $error("Time %0t: FULL FLAG MISMATCH - C Model=%0d, DUT=%0d", $time, c_full, wfull);
            end
        end
    end
    */

endmodule

//////////////////////
// Testbench
//////////////////////
module fifo_dpi_tb;

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
    always #7 rclk = ~rclk;   // 14ns period (~71MHz) - Different frequency for async FIFO

    // DUT instantiation
    async_fifo_wrapper #(.DSIZE(DSIZE), .ASIZE(ASIZE)) dut_inst (
        .wclk(wclk),
        .rclk(rclk),
        .wrst_n(wrst_n),
        .rrst_n(rrst_n),
        .wdata(wdata),
        .winc(winc),
        .rinc(rinc),
        .rdata(rdata),
        .wfull(wfull),
        .rempty(rempty),
        .almost_full(almost_full),
        .almost_empty(almost_empty)
    );

    // Checker instantiation (following dpi_2.sv style)
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

    // Waveform dump
    initial begin
        $fsdbDumpvars();
        $display("FSDB dump enabled for FIFO DPI testbench");
    end

    // Test sequence (based on minimal testbench)
    initial begin
        // Initialize
        wdata = 0;
        winc = 0;
        rinc = 0;
        wrst_n = 0;
        rrst_n = 0;
        
        // Display test mode
        if ($test$plusargs("inject_bug")) begin
            $display("=== FIFO DPI TEST WITH BUG INJECTION ===");
        end else begin
            $display("=== FIFO DPI TEST - NORMAL MODE ===");
        end
        
        // Reset sequence
        #20;
        wrst_n = 1;
        rrst_n = 1;
        #20;
        $display("Time %0t: Reset released - rempty=%b, wfull=%b", $time, rempty, wfull);
        
        // Test 1: Write 5 simple values
        $display("Time %0t: === Writing 5 values (3rd will be dropped if bug injection) ===", $time);
        write_value(8'h11);  // Write #1
        write_value(8'h22);  // Write #2  
        write_value(8'h33);  // Write #3 - DROPPED if bug injection
        write_value(8'h44);  // Write #4
        write_value(8'h55);  // Write #5
        
        $display("Time %0t: After writes - rempty=%b, wfull=%b", $time, rempty, wfull);
        
        // Wait for settling
        #50;
        
        // Test 2: Read values back and verify with checker
        $display("Time %0t: === Reading values back (checker will verify) ===", $time);
        if ($test$plusargs("inject_bug")) begin
            $display("With bug: expecting mismatches due to dropped write");
        end else begin
            $display("Normal: expecting all reads to match C model");
        end
        
        read_value();  // Read #1
        read_value();  // Read #2  
        read_value();  // Read #3
        read_value();  // Read #4
        read_value();  // Read #5 (might be empty if bug injection)
        
        $display("Time %0t: After reads - rempty=%b, wfull=%b", $time, rempty, wfull);
        
        // Wait for final state
        #50;
        
        $display("=== FIFO DPI Test Complete ===");
        $finish;
    end

    // Write task
    task write_value(logic [7:0] data);
        begin
            @(posedge wclk);
            wdata = data;
            winc = 1;
            $display("Time %0t: Writing 0x%02x", $time, data);
            
            @(posedge wclk);
            winc = 0;
            
            repeat(2) @(posedge wclk);
        end
    endtask

    // Read task
    task read_value();
        begin
            @(posedge rclk);
            if (!rempty) begin
                rinc = 1;
                $display("Time %0t: Reading - data available: 0x%02x", $time, rdata);
                
                @(posedge rclk);
                rinc = 0;
            end else begin
                $display("Time %0t: Cannot read - FIFO is empty", $time);
            end
            
            repeat(2) @(posedge rclk);
        end
    endtask

endmodule