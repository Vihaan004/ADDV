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
    
    // Continuous read (asynchronous read)
    assign rdata = mem[raddr];
    
    // Synchronous write with enable and full protection
    always_ff @(posedge wclk) begin
        if (wclken && !wfull) begin
            mem[waddr] <= wdata;
        end
    end

endmodule