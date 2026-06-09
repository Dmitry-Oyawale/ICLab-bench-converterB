module stimulus_gen (
    input clk,
    output logic kld  // key load signal
);
    initial begin
        kld = 1'b0;
        @(negedge clk);

        // 测试1：完整的单轮运行（确保所有case都被触发）
        kld = 1'b1;
        @(posedge clk);
        kld = 1'b0;
        repeat(200) @(posedge clk);  // 让计数器运行完整个序列0-9

        // 测试2：中断序列并重新开始
        repeat(10) begin
            kld = 1'b1;
            @(posedge clk);
            kld = 1'b0;
            repeat(5) @(posedge clk);  // 运行一半后重置
        end

        // 测试3：完整序列重复
        repeat(10) begin
            kld = 1'b1;
            @(posedge clk);
            kld = 1'b0;
            repeat(10) @(posedge clk);  // 完整运行0-9
        end

        // 测试4：快速重置
        repeat(5) begin
            kld = 1'b1;
            @(posedge clk);
            kld = 1'b0;
            @(posedge clk);  // 只运行一个周期就重置
        end

        // 最后一次完整运行
        kld = 1'b1;
        @(posedge clk);
        kld = 1'b0;
        repeat(15) @(posedge clk);  // 确保运行超过完整序列长度

        $finish;
    end
endmodule

module ref_aes_rcon(clk, kld, out);
input		clk;
input		kld;
output	[31:0]	out;
reg	[31:0]	out;
reg	[3:0]	rcnt;
wire	[3:0]	rcnt_next;

always @(posedge clk)
	if(kld)		out <=  32'h01_00_00_00;
	else		out <=  frcon(rcnt_next);

assign rcnt_next = rcnt + 4'h1;
always @(posedge clk)
	if(kld)		rcnt <=  4'h0;
	else		rcnt <=  rcnt_next;

function [31:0]	frcon;
input	[3:0]	i;
case(i)	// synopsys parallel_case
   4'h0: frcon=32'h01_00_00_00;
   4'h1: frcon=32'h02_00_00_00;
   4'h2: frcon=32'h04_00_00_00;
   4'h3: frcon=32'h08_00_00_00;
   4'h4: frcon=32'h10_00_00_00;
   4'h5: frcon=32'h20_00_00_00;
   4'h6: frcon=32'h40_00_00_00;
   4'h7: frcon=32'h80_00_00_00;
   4'h8: frcon=32'h1b_00_00_00;
   4'h9: frcon=32'h36_00_00_00;
   default: frcon=32'h00_00_00_00;
endcase
endfunction

endmodule

module PATTERN(clk, kld, out_dut);
    output logic clk;
    output logic kld;
    input  logic [31:0] out_dut;

    typedef struct packed {
        int errors;
        int errortime;
        int errors_out;
        int errortime_out;
        int clocks;
    } stats;

    stats stats1;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic [511:0] wavedrom_title;
    logic         wavedrom_enable;
    logic [31:0] out_ref;
    wire tb_match_out = (out_ref === out_dut);
    wire tb_match = tb_match_out;

    stimulus_gen stim1 (
		.clk(clk),
		.kld(kld)
    );

    ref_aes_rcon good1 (
		.clk(clk),
		.kld(kld),
		.out(out_ref)
    );

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0);
    end

    always @(posedge clk) begin
        stats1.clocks++;
        if (!tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (!tb_match_out) begin
            if (stats1.errors_out == 0) stats1.errortime_out = $time;
            stats1.errors_out++;
        end
    end

    final begin
        $display("\nTest Results:");
        if (stats1.errors_out)
            $display("Hint: Output out has %0d mismatches. First at time %0d",
                    stats1.errors_out, stats1.errortime_out);
        else
            $display("Hint: Output 'out' has no mismatches.");
        $display("\nHint: Total mismatched samples is %1d out of %1d samples\n",
                stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
    end

    initial begin
        #1000000
        $display("TIMEOUT");
        $finish();
    end

endmodule
