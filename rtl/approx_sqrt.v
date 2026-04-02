// approx_sqrt.v
// -------------
// Approximate sqrt computation for UCB score engine.
//
// Parameters:
//   WIDTH : fixed-point bit width (8, 12, 16)
//   FRAC  : fractional bits (WIDTH/2)
//   MODE  : 0 = LUT, 1 = CORDIC (Newton-Raphson)
//
// Input:  x_in     (fixed-point, 2*ln(t)/n)
// Output: sqrt_out (fixed-point result)

module approx_sqrt #(
    parameter WIDTH = 16,
    parameter FRAC  = 8,
    parameter MODE  = 0   // 0: LUT, 1: CORDIC
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  valid_in,
    input  wire [WIDTH-1:0]      x_in,
    output reg  [WIDTH-1:0]      sqrt_out,
    output reg                   valid_out
);

generate
if (MODE == 0) begin : lut_mode

    // ---------------------------------------------------------------------------
    // LUT mode: 8-entry table covering sqrt at log-spaced breakpoints
    // Values scaled by 2^FRAC
    // ---------------------------------------------------------------------------
    reg [WIDTH-1:0] lut [0:7];
    initial begin
        // sqrt(0)=0, sqrt(0.5)=0.707, sqrt(1)=1, sqrt(2)=1.414
        // sqrt(4)=2, sqrt(8)=2.828,   sqrt(16)=4, sqrt(20)=4.472
        lut[0] = 0;
        lut[1] = (16'd707  * (1<<FRAC)) / 1000;  // sqrt(0.5)
        lut[2] = (16'd1000 * (1<<FRAC)) / 1000;  // sqrt(1)
        lut[3] = (16'd1414 * (1<<FRAC)) / 1000;  // sqrt(2)
        lut[4] = (16'd2000 * (1<<FRAC)) / 1000;  // sqrt(4)
        lut[5] = (16'd2828 * (1<<FRAC)) / 1000;  // sqrt(8)
        lut[6] = (16'd4000 * (1<<FRAC)) / 1000;  // sqrt(16)
        lut[7] = (16'd4472 * (1<<FRAC)) / 1000;  // sqrt(20)
    end

    reg [2:0] idx;
    always @(*) begin
        if      (x_in >= (16'd20 << FRAC)) idx = 3'd7;
        else if (x_in >= (16'd16 << FRAC)) idx = 3'd6;
        else if (x_in >= (16'd8  << FRAC)) idx = 3'd5;
        else if (x_in >= (16'd4  << FRAC)) idx = 3'd4;
        else if (x_in >= (16'd2  << FRAC)) idx = 3'd3;
        else if (x_in >= (16'd1  << FRAC)) idx = 3'd2;
        else if (x_in >= (16'd1  << (FRAC-1))) idx = 3'd1;
        else                                idx = 3'd0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sqrt_out  <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= valid_in;
            if (valid_in)
                sqrt_out <= lut[idx];
        end
    end

end
else begin : cordic_mode

    // ---------------------------------------------------------------------------
    // CORDIC mode: 2-iteration Newton-Raphson
    // sqrt(x): y_{n+1} = (y_n + x/y_n) / 2
    // Initial estimate: leading-bit approximation
    // ---------------------------------------------------------------------------

    reg [WIDTH-1:0] y0, y1, y2;
    reg [3:0]       msb;
    integer j;

    always @(*) begin
        // Initial estimate: 2^(msb/2)
        msb = 0;
        for (j = WIDTH-1; j >= 0; j = j - 1)
            if (x_in[j] && msb == 0) msb = j[3:0];
        y0 = 1 << (msb >> 1);

        // Iteration 1: y1 = (y0 + x/y0) / 2
        y1 = (y0 > 0) ? ((y0 + (x_in / y0)) >> 1) : 0;

        // Iteration 2: y2 = (y1 + x/y1) / 2
        y2 = (y1 > 0) ? ((y1 + (x_in / y1)) >> 1) : 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sqrt_out  <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= valid_in;
            if (valid_in)
                sqrt_out <= y2;
        end
    end

end
endgenerate

endmodule
