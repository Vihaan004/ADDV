`timescale 1ns/1ns

// =============================================================================
// Read-domain to Write-domain Synchronizer
// Synchronizes read pointer into write clock domain
// =============================================================================

module sync_r2w #(
    parameter int ASIZE = 4
)(
    output logic [ASIZE:0] wq2_rptr,
    input  logic [ASIZE:0] rptr,
    input  logic           wclk, wrst_n
);

    // Two-stage synchronizer for metastability prevention
    logic [ASIZE:0] wq1_rptr;
    
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            {wq2_rptr, wq1_rptr} <= '0;
        end else begin
            {wq2_rptr, wq1_rptr} <= {wq1_rptr, rptr};
        end
    end

endmodule

// =============================================================================
// Write-domain to Read-domain Synchronizer  
// Synchronizes write pointer into read clock domain
// =============================================================================

module sync_w2r #(
    parameter int ASIZE = 4
)(
    output logic [ASIZE:0] rq2_wptr,
    input  logic [ASIZE:0] wptr,
    input  logic           rclk, rrst_n
);

    // Two-stage synchronizer for metastability prevention
    logic [ASIZE:0] rq1_wptr;
    
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            {rq2_wptr, rq1_wptr} <= '0;
        end else begin
            {rq2_wptr, rq1_wptr} <= {rq1_wptr, wptr};
        end
    end

endmodule