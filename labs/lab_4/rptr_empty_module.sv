// =============================================================================
// Read Pointer and Empty Generation Logic
// Generates read address, empty flag, and almost_empty flag
// =============================================================================

module rptr_empty #(
    parameter int ASIZE = 4
)(
    output logic             rempty,
    output logic             almost_empty,
    output logic [ASIZE-1:0] raddr,
    output logic [ASIZE:0]   rptr,
    input  logic [ASIZE:0]   rq2_wptr,
    input  logic             rinc, rclk, rrst_n
);

    // Internal signals
    logic [ASIZE:0] rbin;
    logic [ASIZE:0] rgraynext, rbinnext;
    logic           rempty_val, almost_empty_val;
    
    // FIFO depth for almost_empty calculation (3/4 empty means 1/4 full)
    localparam int FIFO_DEPTH = 1 << ASIZE;
    localparam int ALMOST_EMPTY_THRESH = FIFO_DEPTH >> 2; // 1/4 of depth

    // ==========================================================================
    // GRAYSTYLE2 pointer (dual binary/gray counter)
    // ==========================================================================
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            {rbin, rptr} <= '0;
        end else begin
            {rbin, rptr} <= {rbinnext, rgraynext};
        end
    end

    // Memory read-address pointer (binary addressing)
    assign raddr = rbin[ASIZE-1:0];
    
    // Next binary value (increment only if not empty and read enabled)
    assign rbinnext = rbin + (rinc & ~rempty);
    
    // Binary to Gray code conversion
    assign rgraynext = (rbinnext >> 1) ^ rbinnext;

    // ==========================================================================
    // FIFO empty generation
    // FIFO empty when next rptr == synchronized wptr
    // ==========================================================================
    assign rempty_val = (rgraynext == rq2_wptr);
    
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty <= 1'b1;  // Start empty
        end else begin
            rempty <= rempty_val;
        end
    end

    // ==========================================================================
    // Almost empty generation (3/4 empty = 1/4 full)
    // Compare current fill level with threshold
    // ==========================================================================
    always_comb begin
        // Calculate current fill level using Gray to Binary conversion
        logic [ASIZE:0] wptr_bin, rptr_bin;
        logic [ASIZE:0] fill_count;
        
        // Convert synchronized write pointer to binary for calculation
        wptr_bin = gray_to_bin(rq2_wptr);
        rptr_bin = rbin;
        
        // Calculate fill count (handle wrap-around)
        if (wptr_bin >= rptr_bin) begin
            fill_count = wptr_bin - rptr_bin;
        end else begin
            fill_count = (FIFO_DEPTH) - (rptr_bin - wptr_bin);
        end
        
        // Assert almost_empty when fill count <= threshold
        almost_empty_val = (fill_count <= ALMOST_EMPTY_THRESH);
    end
    
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            almost_empty <= 1'b1;  // Start almost empty
        end else begin
            almost_empty <= almost_empty_val;
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