// approx_ln.v (original)
module approx_ln #(
    parameter WIDTH = 16,
    parameter FRAC  = 8,
    parameter MODE  = 0
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  valid_in,
    input  wire [15:0]           t,
    output reg  [WIDTH-1:0]      ln_out,
    output reg                   valid_out
);

generate
if (MODE == 0) begin : lut_mode
    reg [WIDTH-1:0] lut [0:7];
    initial begin
        lut[0] = 0;
        lut[1] = (16'd693  * (1<<FRAC)) / 1000;
        lut[2] = (16'd1386 * (1<<FRAC)) / 1000;
        lut[3] = (16'd2079 * (1<<FRAC)) / 1000;
        lut[4] = (16'd2773 * (1<<FRAC)) / 1000;
        lut[5] = (16'd4159 * (1<<FRAC)) / 1000;
        lut[6] = (16'd5545 * (1<<FRAC)) / 1000;
        lut[7] = (16'd6931 * (1<<FRAC)) / 1000;
    end

    reg [2:0] idx;
    always @(*) begin
        if      (t >= 16'd1024) idx = 3'd7;
        else if (t >= 16'd256)  idx = 3'd6;
        else if (t >= 16'd64)   idx = 3'd5;
        else if (t >= 16'd16)   idx = 3'd4;
        else if (t >= 16'd8)    idx = 3'd3;
        else if (t >= 16'd4)    idx = 3'd2;
        else if (t >= 16'd2)    idx = 3'd1;
        else                    idx = 3'd0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ln_out <= 0; valid_out <= 0;
        end else begin
            valid_out <= valid_in;
            if (valid_in) ln_out <= lut[idx];
        end
    end

end else begin : cordic_mode
    reg [3:0]       k;
    reg [WIDTH-1:0] ln2_k;
    localparam [WIDTH-1:0] LN2 = (16'd693 * (1<<FRAC)) / 1000;
    integer i;
    always @(*) begin
        k = 0;
        for (i = 15; i >= 0; i = i - 1)
            if (t[i] && k == 0) k = i[3:0];
        ln2_k = LN2 * k;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin ln_out <= 0; valid_out <= 0; end
        else begin
            valid_out <= valid_in;
            if (valid_in) ln_out <= ln2_k;
        end
    end
end
endgenerate
endmodule
