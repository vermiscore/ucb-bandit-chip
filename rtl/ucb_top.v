// ucb_top.v (rev3) - original working version
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

    reg [WIDTH-1:0] mu_arr  [0:N_ARMS-1];
    reg [15:0]      n_arr   [0:N_ARMS-1];
    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k=0; k<N_ARMS; k=k+1) begin
                mu_arr[k] <= 0;
                n_arr[k]  <= 0;
            end
        end else if (reward_valid) begin
            n_arr[reward_arm]  <= n_arr[reward_arm] + 1;
            mu_arr[reward_arm] <= mu_arr[reward_arm]
                + ((reward_val - mu_arr[reward_arm]) >> 4);
        end
    end

    wire [$clog2(N_ARMS)-1:0] rd_addr;
    wire [WIDTH-1:0]          mu_hat_rd  = mu_arr[rd_addr];
    wire [15:0]               n_pulls_rd = n_arr[rd_addr];

    score_engine #(.N_ARMS(N_ARMS),.WIDTH(WIDTH),.FRAC(FRAC),.MODE(MODE)) u_score (
        .clk(clk),.rst_n(rst_n),.start(start),.t(t),
        .rd_addr(rd_addr),.mu_hat(mu_hat_rd),.n_pulls(n_pulls_rd),
        .best_arm(selected_arm),.done(valid_out)
    );

endmodule
