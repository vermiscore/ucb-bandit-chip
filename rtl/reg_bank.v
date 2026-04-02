// reg_bank.v
// ----------
// Register bank storing mu_hat and n_pulls for N_ARMS arms.
//
// Parameters:
//   N_ARMS : number of arms (64)
//   WIDTH  : fixed-point bit width
//
// Operations:
//   - Read  : output mu_hat[addr] and n_pulls[addr]
//   - Write : update mu_hat and n_pulls after reward observation

module reg_bank #(
    parameter N_ARMS = 64,
    parameter WIDTH  = 16
)(
    input  wire                       clk,
    input  wire                       rst_n,

    // Read port (for score engine)
    input  wire [$clog2(N_ARMS)-1:0]  rd_addr,
    output reg  [WIDTH-1:0]           mu_hat_out,
    output reg  [15:0]                n_pulls_out,

    // Write port (after reward observation)
    input  wire                       wr_en,
    input  wire [$clog2(N_ARMS)-1:0]  wr_addr,
    input  wire [WIDTH-1:0]           mu_hat_in,
    input  wire [15:0]                n_pulls_in
);

    reg [WIDTH-1:0] mu_hat  [0:N_ARMS-1];
    reg [15:0]      n_pulls [0:N_ARMS-1];

    integer i;

    // Reset + write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < N_ARMS; i = i + 1) begin
                mu_hat[i]  <= 0;
                n_pulls[i] <= 0;
            end
        end else if (wr_en) begin
            mu_hat[wr_addr]  <= mu_hat_in;
            n_pulls[wr_addr] <= n_pulls_in;
        end
    end

    // Read (combinational)
    always @(*) begin
        mu_hat_out  = mu_hat[rd_addr];
        n_pulls_out = n_pulls[rd_addr];
    end

endmodule
