// =============================================================================
// Write Pointer and Full Generation Logic  
// Generates write address, full flag, and almost_full flag
// =============================================================================

module wptr_full #(
    parameter int ASIZE = 4
)(
    output logic             wfull,
    output logic             almost_full,
    output logic [ASIZE-1:0] waddr,
    output logic [ASIZE:0]   wptr,
    input  logic [ASIZE:0]   wq2_rptr,
    input  logic             winc, wclk, wrst_n
);

    // Internal signals
    logic [ASIZE:0] wbin;
    logic [ASIZE:0] wgraynext, wbinnext;
    logic           wfull_val, almost_full_val;
    
    // FIFO depth for almost_full calculation (3/4 full)
    localparam int FIFO_DEPTH = 1 << ASIZE;
    localparam int ALMOST_FULL_THRESH = (FIFO_DEPTH * 3) >> 2; // 3/4 of depth

    // ==========================================================================
    // GRAYSTYLE2 pointer (dual binary/gray counter)
    // ==========================================================================
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            {wbin, wptr} <= '0;
        end else begin
            {wbin, wptr} <= {wbinnext, wgraynext};
        end
    end

    // Memory write-address pointer (binary addressing)
    assign waddr = wbin[ASIZE-1:0];
    
    // Next binary value (increment only if not full and write enabled)
    assign wbinnext = wbin + (winc & ~wfull);
    
    // Binary to Gray code conversion
    assign wgraynext = (wbinnext >> 1) ^ wbinnext;

    // ==========================================================================
    // FIFO full generation
    // Full when next wptr catches up to synchronized rptr (with MSB differences)
    // From Cummings paper: three conditions must be met:
    // 1. MSBs are different (wptr wrapped one more time than rptr)
    // 2. Second MSBs are different 
    // 3. All other bits are equal
    // ==========================================================================
    assign wfull_val = (wgraynext == {~wq2_rptr[ASIZE:ASIZE-1], wq2_rptr[ASIZE-2:0]});
    
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull <= 1'b0;  // Start not full
        end else begin
            wfull <= wfull_val;
        end
    end

    // ==========================================================================
    // Almost full generation (3/4 full)
    // Compare current fill level with threshold
    // ==========================================================================
    always_comb begin
        // Calculate current fill level using binary pointers
        logic [ASIZE:0] rptr_bin, wptr_bin;
        logic [ASIZE:0] fill_count;
        
        // Convert synchronized read pointer to binary for calculation
        rptr_bin = gray_to_bin(wq2_rptr);
        wptr_bin = wbin;
        
        // Calculate fill count (handle wrap-around)
        if (wptr_bin >= rptr_bin) begin
            fill_count = wptr_bin - rptr_bin;
        end else begin
            fill_count = (FIFO_DEPTH) - (rptr_bin - wptr_bin);
        end
        
        // Assert almost_full when fill count >= threshold
        almost_full_val = (fill_count >= ALMOST_FULL_THRESH);
    end
    
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            almost_full <= 1'b0;  // Start not almost full
        end else begin
            almost_full <= almost_full_val;
        end
    end

    // ==========================================================================
    // Gray to Binary conversion function
    // ==========================================================================
    function automatic logic [ASIZE:0] gray_to_bin(input logic [ASIZE:0] gray);
        logic [ASIZE:0] bin;
        bin[ASIZE] = gray[ASIZE];
        for (int i = ASIZE-1; i >= 0; i--) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        return bin;
    endfunction

endmodule