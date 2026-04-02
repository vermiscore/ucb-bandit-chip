`timescale 1ns/1ps
module tb_ucb_top;
    parameter N_ARMS = 64;
    parameter WIDTH  = 16;
    parameter FRAC   = 8;
    parameter MODE   = 0;

    reg                        clk, rst_n, start;
    wire [$clog2(N_ARMS)-1:0]  selected_arm;
    wire                       valid_out;
    reg                        reward_valid;
    reg  [$clog2(N_ARMS)-1:0]  reward_arm;
    reg  [WIDTH-1:0]           reward_val;

    initial clk=0; always #5 clk=~clk;

    ucb_top #(.N_ARMS(N_ARMS),.WIDTH(WIDTH),.FRAC(FRAC),.MODE(MODE)) dut(
        .clk(clk),.rst_n(rst_n),.start(start),
        .selected_arm(selected_arm),.valid_out(valid_out),
        .reward_valid(reward_valid),.reward_arm(reward_arm),.reward_val(reward_val)
    );

    function [WIDTH-1:0] get_reward;
        input [$clog2(N_ARMS)-1:0] arm;
        get_reward = (arm==6'd5) ? 16'd230 : 16'd64;
    endfunction

    integer round, best_cnt, arm_i;
    reg [$clog2(N_ARMS)-1:0] cur_arm;

    task do_round;
        input [$clog2(N_ARMS)-1:0] forced_arm;
        input                      use_forced;
        begin
            @(posedge clk); #1;
            start=1;
            @(posedge clk); #1;
            start=0;
            @(posedge valid_out);
            @(posedge clk); #1;
            cur_arm = use_forced ? forced_arm : selected_arm;
            repeat(2) @(posedge clk); #1;
            reward_valid=1; reward_arm=cur_arm; reward_val=get_reward(cur_arm);
            repeat(2) @(posedge clk); #1;
            reward_valid=0;
            repeat(3) @(posedge clk);
        end
    endtask

    initial begin
        $display("=== UCB Chip Sim WIDTH=%0d MODE=%0d ===", WIDTH, MODE);
        rst_n=0; start=0; reward_valid=0; best_cnt=0;
        repeat(4) @(posedge clk); #1; rst_n=1;
        repeat(2) @(posedge clk);

        $display("-- init phase --");
        for (arm_i=0; arm_i<N_ARMS; arm_i=arm_i+1)
            do_round(arm_i[$clog2(N_ARMS)-1:0], 1);

        $display("-- ucb phase --");
        for (round=0; round<300; round=round+1) begin
            do_round(0, 0);
            if (selected_arm==6'd5) best_cnt=best_cnt+1;
            if (round<5 || round%50==0)
                $display("round=%3d arm=%2d %s", round, selected_arm,
                         (selected_arm==6'd5)?"<best":"");
        end

        $display("---");
        $display("Best arm (arm5) %0d/300 (%.1f%%)", best_cnt, best_cnt*100.0/300.0);
        $display("=== DONE ===");
        $finish;
    end
    initial begin #200_000_000; $display("TIMEOUT"); $finish; end
endmodule
