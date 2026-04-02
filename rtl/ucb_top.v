// ucb_top.v (rev8) - mu stored raw, passed raw to score_engine
module ucb_top #(
    parameter N_ARMS = 64,
    parameter WIDTH  = 16,
    parameter FRAC   = 8,
    parameter MODE   = 0
)(
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire                       start,
    output wire [$clog2(N_ARMS)-1:0]  selected_arm,
    output wire                       valid_out,
    input  wire                       reward_valid,
    input  wire [$clog2(N_ARMS)-1:0]  reward_arm,
    input  wire [WIDTH-1:0]           reward_val
);

    reg [15:0] t;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)     t <= 0;
        else if (start) t <= t + 1;
    end

    // Single-cycle write on rising edge of reward_valid
    reg rv_d, wr_done;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin rv_d <= 0; wr_done <= 0; end
        else begin
            rv_d <= reward_valid;
            if (!reward_valid)       wr_done <= 0;
            else if (!wr_done)       wr_done <= 1;
        end
    end
    wire do_write = reward_valid & ~wr_done;

    // mu stored as raw integer (same scale as reward_val)
    // incremental mean: mu_new = mu_old + (r - mu_old)/(n+1)
    reg [23:0] mu_arr [0:N_ARMS-1];  // 24bit to avoid overflow during calc
    reg [15:0] n_arr  [0:N_ARMS-1];
    integer k;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k=0; k<N_ARMS; k=k+1) begin
                mu_arr[k] <= 0;
                n_arr[k]  <= 0;
            end
        end else if (do_write) begin
            if (n_arr[reward_arm] == 0)
                mu_arr[reward_arm] <= {8'b0, reward_val};
            else begin
                // incremental mean (integer arithmetic)
                mu_arr[reward_arm] <= mu_arr[reward_arm]
                    + (({8'b0,reward_val} - mu_arr[reward_arm])
                       / (n_arr[reward_arm] + 1));
            end
            n_arr[reward_arm] <= n_arr[reward_arm] + 1;
        end
    end

    wire [$clog2(N_ARMS)-1:0] rd_addr;
    wire [WIDTH-1:0]  mu_hat_rd  = mu_arr[rd_addr][WIDTH-1:0];
    wire [15:0]       n_pulls_rd = n_arr[rd_addr];

    score_engine #(.N_ARMS(N_ARMS),.WIDTH(WIDTH),.FRAC(FRAC),.MODE(MODE)) u_score (
        .clk(clk),.rst_n(rst_n),.start(start),.t(t),
        .rd_addr(rd_addr),.mu_hat(mu_hat_rd),.n_pulls(n_pulls_rd),
        .best_arm(selected_arm),.done(valid_out)
    );

endmodule
