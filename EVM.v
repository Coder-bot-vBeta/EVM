`timescale 1ns / 1ps

module EVM(
    input [3:0] v,           // 4-bit vote input from switches
    input enable,            // Voting state or result state trigger
    input reset,             // Resets the voting counts to zero
    input clock,             // Clock signal
    input next_result,       // Trigger for displaying the next result
    output reg [3:0] to_display = 4'b0000, // Displayed value on seven-segment display
    output reg [1:0] ldsv,   // Candidate number display
    output reg [1:0] ldsc1,  // First digit of candidate vote count
    output reg [3:0] ldsc2,  // Second digit of candidate vote count
    output reg overflow      // Overflow indicator
);

    reg [4:0] c0 = 5'b00000, c1 = 5'b00000, c2 = 5'b00000, c3 = 5'b00000; // Vote counts for candidates
    reg enable_state_ff = 1'b0;     // State flip-flop for enable signal
    reg [1:0] next_result_ff = 2'b00; // State flip-flop for next_result signal
    reg enable_prev = 1'b0;         // Previous state of enable signal
    reg next_result_prev = 1'b0;    // Previous state of next_result signal
    reg [4:0] ldsc;                 // Candidate vote count display

    always @(posedge clock or posedge reset or posedge enable or posedge next_result) begin
        if (reset) begin
            // Reset all counters and state variables
            c0 = 5'b00000;
            c1 = 5'b00000;
            c2 = 5'b00000;
            c3 = 5'b00000;
            enable_state_ff = 1'b0;
            enable_prev = 1'b0;
            next_result_ff = 2'b00;
            overflow = 1'b0;
            next_result_prev = 1'b0;
        end else if (enable && !enable_prev) begin
            // Detect positive edge of enable
            enable_state_ff = ~enable_state_ff;
        end else if (enable_state_ff == 1'b1 && v != to_display) begin
            // Voting mode: update display and count votes
            to_display = v;
            case (v)
                4'b0001: if (c0 == 5'b11111) overflow = 1'b1; else c0 <= c0 + 5'b00001;
                4'b0010: if (c1 == 5'b11111) overflow = 1'b1; else c1 <= c1 + 5'b00001;
                4'b0100: if (c2 == 5'b11111) overflow = 1'b1; else c2 <= c2 + 5'b00001;
                4'b1000: if (c3 == 5'b11111) overflow = 1'b1; else c3 <= c3 + 5'b00001;
            endcase
        end else begin
            // Result display mode
            case (next_result_ff)
                2'b00: begin ldsv = 2'b00; ldsc = c0; end
                2'b01: begin ldsv = 2'b01; ldsc = c1; end
                2'b10: begin ldsv = 2'b10; ldsc = c2; end
                2'b11: begin ldsv = 2'b11; ldsc = c3; end
            endcase

            // Convert ldsc into two digits
            if (ldsc < 5'b01010) begin
                ldsc1 = 2'b00;
                ldsc2 = ldsc[3:0];
            end else if (ldsc < 5'b10100) begin
                ldsc1 = 2'b01;
                ldsc2 = ldsc - 5'b01010;
            end else if (ldsc < 5'b11110) begin
                ldsc1 = 2'b10;
                ldsc2 = ldsc - 5'b10100;
            end else begin
                ldsc1 = 2'b11;
                ldsc2 = ldsc - 5'b11110;
            end

            // Detect positive edge of next_result
            if (next_result && !next_result_prev) begin
                if (next_result_ff == 2'b11) next_result_ff = 2'b00; // Cycle back to candidate 1
                else next_result_ff = next_result_ff + 2'b01;
            end
        end

        // Update previous states
        enable_prev = enable;
        next_result_prev = next_result;
    end

endmodule
