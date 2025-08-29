// =============================================================================
// Asynchronous FIFO - Top Level Module
// Based on Cliff Cummings SNUG 2002 paper, modified for Lab #1 requirements
// =============================================================================

module async_fifo #(
    parameter int DSIZE = 8,    // Data width
    parameter int ASIZE = 4     // Address bits (FIFO depth = 2^ASIZE)
)(
    // Write interface (wclk domain)
    output logic [DSIZE-1:0] rdata,
    output logic             wfull,
    output logic             rempty,
    output logic             almost_full,
    output logic             almost_empty,
    
    // Read interface (rclk domain)  
    input  logic [DSIZE-1:0] wdata,
    input  logic             winc,
    input  logic             wclk,
    input  logic             wrst_n,
    input  logic             rinc,
    input  logic             rclk,
    input  logic             rrst_n
);

    // Internal signals
    logic [ASIZE-1:0] waddr, raddr;
    logic [ASIZE:0]   wptr, rptr, wq2_rptr, rq2_wptr;

    // Instantiate synchronizers using .* for named port connections
    sync_r2w #(.ASIZE(ASIZE)) sync_r2w_inst (
        .wq2_rptr(wq2_rptr),
        .rptr(rptr),
        .wclk(wclk),
        .wrst_n(wrst_n)
    );

    sync_w2r #(.ASIZE(ASIZE)) sync_w2r_inst (
        .rq2_wptr(rq2_wptr),
        .wptr(wptr),
        .rclk(rclk),
        .rrst_n(rrst_n)
    );

    // FIFO memory instantiation
    fifomem #(.DATASIZE(DSIZE), .ADDRSIZE(ASIZE)) fifomem_inst (
        .rdata(rdata),
        .wdata(wdata),
        .waddr(waddr),
        .raddr(raddr),
        .wclken(winc),
        .wfull(wfull),
        .wclk(wclk)
    );

    // Read pointer and empty logic
    rptr_empty #(.ASIZE(ASIZE)) rptr_empty_inst (
        .rempty(rempty),
        .almost_empty(almost_empty),
        .raddr(raddr),
        .rptr(rptr),
        .rq2_wptr(rq2_wptr),
        .rinc(rinc),
        .rclk(rclk),
        .rrst_n(rrst_n)
    );

    // Write pointer and full logic  
    wptr_full #(.ASIZE(ASIZE)) wptr_full_inst (
        .wfull(wfull),
        .almost_full(almost_full),
        .waddr(waddr),
        .wptr(wptr),
        .wq2_rptr(wq2_rptr),
        .winc(winc),
        .wclk(wclk),
        .wrst_n(wrst_n)
    );

endmodule