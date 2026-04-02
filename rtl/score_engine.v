// score_engine.v (original - sequential, combinational division)
module score_engine #(
    parameter N_ARMS = 64,
    parameter WIDTH  = 16,
    parameter FRAC   = 8,
    parameter MODE   = 0
)(
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire                       start,
    input  wire [15:0]                t,
    output reg  [$clog2(N_ARMS)-1:0]  rd_addr,
    input  wire [WIDTH-1:0]           mu_hat,
    input  wire [15:0]                n_pulls,
    output reg  [$clog2(N_ARMS)-1:0]  best_arm,
    output reg                        done
);

    wire [WIDTH-1:0] ln_out;
    wire             ln_valid;
    reg              ln_valid_in;

    approx_ln #(.WIDTH(WIDTH),.FRAC(FRAC),.MODE(MODE)) u_ln (
        .clk(clk),.rst_n(rst_n),
        .valid_in(ln_valid_in),.t(t),
        .ln_out(ln_out),.valid_out(ln_valid)
    );

    wire [WIDTH-1:0] sqrt_out;
    wire             sqrt_valid;
    reg  [WIDTH-1:0] sqrt_x_in;
    reg              sqrt_valid_in;

    approx_sqrt #(.WIDTH(WIDTH),.FRAC(FRAC),.MODE(MODE)) u_sqrt (
        .clk(clk),.rst_n(rst_n),
        .valid_in(sqrt_valid_in),.x_in(sqrt_x_in),
        .sqrt_out(sqrt_out),.valid_out(sqrt_valid)
    );

    localparam S_IDLE  = 2'd0,
               S_LN    = 2'd1,
               S_SCORE = 2'd2,
               S_DONE  = 2'd3;

    reg [1:0]                     state;
    reg [$clog2(N_ARMS)-1:0]      arm_idx;
    reg [WIDTH-1:0]               best_score;
    reg [WIDTH-1:0]               ln_t;
    reg [WIDTH-1:0]               ucb_score;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_IDLE;
            arm_idx       <= 0;
            best_arm      <= 0;
            best_score    <= 0;
            done          <= 0;
            ln_valid_in   <= 0;
            sqrt_valid_in <= 0;
            rd_addr       <= 0;
        end else begin
            done          <= 0;
            ln_valid_in   <= 0;
            sqrt_valid_in <= 0;

            case (state)
                S_IDLE: begin
                    if (start) begin
                        arm_idx    <= 0;
                        best_score <= 0;
                        ln_valid_in<= 1;
                        state      <= S_LN;
                    end
                end

                S_LN: begin
                    if (ln_valid) begin
                        ln_t  <= ln_out;
                        state <= S_SCORE;
                        rd_addr <= 0;
                    end
                end

                S_SCORE: begin
                    if (n_pulls > 0) begin
                        sqrt_x_in    <= (2 * ln_t) / n_pulls[7:0];
                        sqrt_valid_in<= 1;
                    end else begin
                        sqrt_x_in    <= {WIDTH{1'b1}};
                        sqrt_valid_in<= 1;
                    end

                    if (sqrt_valid) begin
                        ucb_score = mu_hat + sqrt_out;
                        if (ucb_score > best_score || arm_idx == 0) begin
                            best_score <= ucb_score;
                            best_arm   <= arm_idx;
                        end

                        if (arm_idx == N_ARMS - 1) begin
                            state <= S_DONE;
                        end else begin
                            arm_idx <= arm_idx + 1;
                            rd_addr <= arm_idx + 1;
                        end
                    end
                end

                S_DONE: begin
                    done  <= 1;
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule
