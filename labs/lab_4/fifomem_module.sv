`timescale 1ns/1ns

// =============================================================================
// FIFO Memory Buffer Module
// Dual-port synchronous memory for FIFO data storage
// =============================================================================

module fifomem #(
    parameter int DATASIZE = 8,  // Memory data word width
    parameter int ADDRSIZE = 4   // Number of memory address bits
)(
    output logic [DATASIZE-1:0] rdata,
    input  logic [DATASIZE-1:0] wdata,
    input  logic [ADDRSIZE-1:0] waddr, raddr,
    input  logic                wclken, wfull, wclk
);

    // Memory depth calculation
    localparam int DEPTH = 1 << ADDRSIZE;
    
    // Memory array declaration
    logic [DATASIZE-1:0] mem [0:DEPTH-1];
    
    // Bug injection variables
    int bug_drop_every = 0;
    logic inject_bug = 0;
    
    // Bug injection counter
    int write_count;

    // Check for plusargs during initialization
    initial begin
        if ($test$plusargs("inject_bug")) begin
            inject_bug = 1;
            if ($value$plusargs("bug_drop_every=%d", bug_drop_every)) begin
                $display("Bug injection enabled: dropping every %0d write", bug_drop_every);
            end else begin
                bug_drop_every = 3; // Default to every 3rd write
                $display("Bug injection enabled: dropping every %0d write (default)", bug_drop_every);
            end
    end else begin
            $display("Bug injection disabled");
        end
    end
    
    // Continuous read (asynchronous read)
    assign rdata = mem[raddr];
    
    // Synchronous write with enable and full protection
    always_ff @(posedge wclk) begin
        if (wclken && !wfull) begin
            write_count++;
            
            // Bug injection: drop every Nth write
            if (inject_bug && bug_drop_every > 0 && (write_count % bug_drop_every == 0)) begin
                $display("Time %0t: BUG INJECTED - Dropping write #%0d (data=0x%02x)", 
                        $time, write_count, wdata);
                // Don't write to memory - simulate dropped write
            end else begin
                mem[waddr] <= wdata;
            end
        end
    end

endmodule