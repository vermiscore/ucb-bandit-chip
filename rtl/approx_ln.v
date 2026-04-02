// approx_ln.v (rev2) - improved LUT with wider range
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
    // 16-entry LUT, log-spaced, FRAC=8 fixed-point
    // ln(x) * 256
    reg [WIDTH-1:0] lut [0:15];
    initial begin
        lut[0]  = 16'd0;    // ln(1)=0
        lut[1]  = 16'd178;  // ln(2)=0.693*256=177.4
        lut[2]  = 16'd355;  // ln(4)=1.386*256
        lut[3]  = 16'd533;  // ln(8)=2.079*256
        lut[4]  = 16'd710;  // ln(16)=2.773*256
        lut[5]  = 16'd888;  // ln(32)=3.466*256
        lut[6]  = 16'd1065; // ln(64)=4.159*256
        lut[7]  = 16'd1243; // ln(128)=4.852*256
        lut[8]  = 16'd1420; // ln(256)=5.545*256
        lut[9]  = 16'd1598; // ln(512)=6.238*256
        lut[10] = 16'd1775; // ln(1024)=6.931*256
        lut[11] = 16'd1953; // ln(2048)=7.625*256
        lut[12] = 16'd2130; // ln(4096)=8.318*256
        lut[13] = 16'd2308; // ln(8192)=9.011*256
        lut[14] = 16'd2485; // ln(16384)=9.704*256
        lut[15] = 16'd2663; // ln(32768)=10.397*256
    end

    reg [3:0] idx;
    always @(*) begin
        if      (t >= 16'd32768) idx = 4'd15;
        else if (t >= 16'd16384) idx = 4'd14;
        else if (t >= 16'd8192)  idx = 4'd13;
        else if (t >= 16'd4096)  idx = 4'd12;
        else if (t >= 16'd2048)  idx = 4'd11;
        else if (t >= 16'd1024)  idx = 4'd10;
        else if (t >= 16'd512)   idx = 4'd9;
        else if (t >= 16'd256)   idx = 4'd8;
        else if (t >= 16'd128)   idx = 4'd7;
        else if (t >= 16'd64)    idx = 4'd6;
        else if (t >= 16'd32)    idx = 4'd5;
        else if (t >= 16'd16)    idx = 4'd4;
        else if (t >= 16'd8)     idx = 4'd3;
        else if (t >= 16'd4)     idx = 4'd2;
        else if (t >= 16'd2)     idx = 4'd1;
        else                     idx = 4'd0;
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
