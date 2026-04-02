// argmax.v
// --------
// Finds the arm index with the maximum UCB score.
// Used as a standalone module for pipelined extension.
// In the current sequential design this logic lives inside
// score_engine.v; this module is kept for future parallel use.
//
// Parameters:
//   N_ARMS : number of arms
//   WIDTH  : score bit width

module argmax #(
    parameter N_ARMS = 64,
    parameter WIDTH  = 16
)(
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire                       valid_in,
    input  wire [$clog2(N_ARMS)-1:0]  arm_idx,
    input  wire [WIDTH-1:0]           score,
    input  wire                       last,        // high on final arm
    output reg  [$clog2(N_ARMS)-1:0]  best_arm,
    output reg                        valid_out
);

    reg [WIDTH-1:0] best_score;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            best_arm   <= 0;
            best_score <= 0;
            valid_out  <= 0;
        end else begin
            valid_out <= 0;
            if (valid_in) begin
                if (score > best_score || arm_idx == 0) begin
                    best_score <= score;
                    best_arm   <= arm_idx;
                end
                if (last) begin
                    valid_out  <= 1;
                    best_score <= 0;  // reset for next round
                end
            end
        end
    end

endmodule
