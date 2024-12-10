module lfsr_random(
    input wire        clk,
    input wire        reset,
    input wire [7:0]  seed,         // External seed input
    output reg [31:0] random_num    // 32-bit output holding four distinct 8-bit random values
);

reg [7:0] lfsr;
wire feedback;
reg [1:0] sample_count; // 2-bit counter to select which 8-bit slice to store

// Feedback taps for an 8-bit LFSR using a primitive polynomial
// For 8 bits, one well-known primitive polynomial is x^8 + x^6 + x^5 + x^4 + 1
assign feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];

always @(posedge clk or posedge reset) begin
    if (reset) begin
        // Initialize the LFSR with the provided seed
        // Ensures variability in the sequence generated on each reset
        lfsr <= seed;
    end else begin
        // Shift the register and insert the feedback bit at LSB
        lfsr <= {lfsr[6:0], feedback};
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        random_num   <= 32'h0;
        sample_count <= 2'b00;
    end else begin
        // Store the current LFSR output into a segment of random_num
        case (sample_count)
            2'b00: random_num[7:0]   <= lfsr;
            2'b01: random_num[15:8]  <= lfsr;
            2'b10: random_num[23:16] <= lfsr;
            2'b11: random_num[31:24] <= lfsr;
        endcase
        
        // Increment the sample counter; after reaching '11', it cycles back to '00'
        sample_count <= sample_count + 1'b1;
    end
end

endmodule
