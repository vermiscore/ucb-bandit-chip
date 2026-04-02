// score_engine.v (rev8) - correct fixed-point scaling
// mu_hat: raw value (0~255)
// ln_out: FRAC-bit fixed-point (ln(t) * 2^FRAC)
// bonus_input = 2 * ln_out / n  (FRAC fixed-point)
// sqrt_out: sqrt(bonus_input) in FRAC/2 fixed-point
// score = (mu_hat << FRAC/2) + sqrt_out  (FRAC/2 scale)

module score_engine #(
    parameter N_ARMS       = 64,
    parameter WIDTH        = 16,
    parameter FRAC         = 8,
    parameter MODE         = 0,
    parameter N_DIV_CYCLES = 4
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

    localparam FRAC2 = FRAC / 2;  // =4

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

    localparam S_IDLE=3'd0, S_LN=3'd1, S_READ=3'd2,
               S_CALC=3'd3, S_SQRT=3'd4, S_ACC=3'd5, S_DONE=3'd6;

    reg [2:0]                    state;
    reg [$clog2(N_ARMS)-1:0]     arm_idx;
    reg [23:0]                   best_score;  // wider for scaled score
    reg [WIDTH-1:0]              ln_t;
    reg [WIDTH-1:0]              mu_lat;
    reg [WIDTH-1:0]              n_lat;
    reg [3:0]                    wait_cnt;
    reg                          first_arm;

    // score in FRAC/2 scale: (mu<<FRAC2) + sqrt_out
    wire [23:0] cur_score = ({8'b0, mu_lat} << FRAC2) + {8'b0, sqrt_out};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE; arm_idx <= 0;
            best_score <= 0; best_arm <= 0;
            done <= 0; ln_valid_in <= 0;
            sqrt_valid_in <= 0; rd_addr <= 0;
            wait_cnt <= 0; first_arm <= 1;
            mu_lat <= 0; n_lat <= 1;
        end else begin
            done          <= 0;
            ln_valid_in   <= 0;
            sqrt_valid_in <= 0;

            case (state)
                S_IDLE: begin
                    if (start) begin
                        arm_idx    <= 0;
                        rd_addr    <= 0;
                        best_score <= 0;
                        first_arm  <= 1;
                        ln_valid_in<= 1;
                        state      <= S_LN;
                    end
                end

                S_LN: begin
                    if (ln_valid) begin
                        ln_t  <= ln_out;
                        state <= S_READ;
                    end
                end

                S_READ: begin
                    mu_lat <= mu_hat;
                    n_lat  <= (n_pulls[WIDTH-1:0] > 0) ? n_pulls[WIDTH-1:0] : 1;
                    wait_cnt <= 0;
                    state  <= S_CALC;
                end

                S_CALC: begin
                    if (wait_cnt < N_DIV_CYCLES - 1) begin
                        wait_cnt <= wait_cnt + 1;
                    end else begin
                        // bonus_input in FRAC fixed-point
                        sqrt_x_in    <= (2 * ln_t) / (n_lat > 0 ? n_lat : 1);
                        sqrt_valid_in<= 1;
                        state        <= S_SQRT;
                    end
                end

                S_SQRT: begin
                    if (sqrt_valid) state <= S_ACC;
                end

                S_ACC: begin
                    if (first_arm || cur_score > best_score) begin
                        best_score <= cur_score;
                        best_arm   <= arm_idx;
                        first_arm  <= 0;
                    end

                    if (arm_idx == N_ARMS - 1) begin
                        state <= S_DONE;
                    end else begin
                        arm_idx <= arm_idx + 1;
                        rd_addr <= arm_idx + 1;
                        wait_cnt<= 0;
                        state   <= S_READ;
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
