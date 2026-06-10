//`include "timescale.v"

module ref_aes_cipher_top(clk, rst, ld, done, key, text_in, text_out );
input		clk, rst;
input		ld;
output		done;
input	[127:0]	key;
input	[127:0]	text_in;
output	[127:0]	text_out;

////////////////////////////////////////////////////////////////////
//
// Local Wires
//

wire	[31:0]	w0, w1, w2, w3;
reg	[127:0]	text_in_r;
reg	[127:0]	text_out;

//状态矩阵的组织
reg	[7:0]	sa00, sa01, sa02, sa03;//第0行
reg	[7:0]	sa10, sa11, sa12, sa13;//第1行
reg	[7:0]	sa20, sa21, sa22, sa23;//第2行
reg	[7:0]	sa30, sa31, sa32, sa33;//第3行

wire	[7:0]	sa00_next, sa01_next, sa02_next, sa03_next;
wire	[7:0]	sa10_next, sa11_next, sa12_next, sa13_next;
wire	[7:0]	sa20_next, sa21_next, sa22_next, sa23_next;
wire	[7:0]	sa30_next, sa31_next, sa32_next, sa33_next;
wire	[7:0]	sa00_sub, sa01_sub, sa02_sub, sa03_sub;
wire	[7:0]	sa10_sub, sa11_sub, sa12_sub, sa13_sub;
wire	[7:0]	sa20_sub, sa21_sub, sa22_sub, sa23_sub;
wire	[7:0]	sa30_sub, sa31_sub, sa32_sub, sa33_sub;
wire	[7:0]	sa00_sr, sa01_sr, sa02_sr, sa03_sr;
wire	[7:0]	sa10_sr, sa11_sr, sa12_sr, sa13_sr;
wire	[7:0]	sa20_sr, sa21_sr, sa22_sr, sa23_sr;
wire	[7:0]	sa30_sr, sa31_sr, sa32_sr, sa33_sr;
wire	[7:0]	sa00_mc, sa01_mc, sa02_mc, sa03_mc;
wire	[7:0]	sa10_mc, sa11_mc, sa12_mc, sa13_mc;
wire	[7:0]	sa20_mc, sa21_mc, sa22_mc, sa23_mc;
wire	[7:0]	sa30_mc, sa31_mc, sa32_mc, sa33_mc;
reg		done, ld_r;
reg	[3:0]	dcnt;

////////////////////////////////////////////////////////////////////
//
// Misc Logic
//轮计数控制

always @(posedge clk)
	if(!rst)	dcnt <=  4'h0;
	else
	if(ld)		dcnt <=  4'hb;//加载新数据时设为11（10轮加密+1轮初始轮密钥加）
	else
	if(|dcnt)	dcnt <=  dcnt - 4'h1;//每个时钟周期递减，直到完成所有轮
//“|”是归约运算符，对所有位进行或运算
//当dcnt不为0时即还有位是1时进行减1，为0时保持为0，防止计数器从0减到负数

always @(posedge clk) done <=  !(|dcnt[3:1]) & dcnt[0] & !ld;
always @(posedge clk) if(ld) text_in_r <=  text_in;//输入数据缓存到text_in_r寄存器，当初始轮密钥加时使用
always @(posedge clk) ld_r <=  ld;

////////////////////////////////////////////////////////////////////
//
// Initial Permutation (AddRoundKey)
//
//初始轮密钥加操作
//
always @(posedge clk)	sa33 <=  ld_r ? text_in_r[007:000] ^ w3[07:00] : sa33_next;
//当ld_r=1时：输入数据的最低字节与轮密钥w3的最低字节异或；当ld_r=0时：使用轮变换的结果sa33_next
always @(posedge clk)	sa23 <=  ld_r ? text_in_r[015:008] ^ w3[15:08] : sa23_next;
always @(posedge clk)	sa13 <=  ld_r ? text_in_r[023:016] ^ w3[23:16] : sa13_next;
always @(posedge clk)	sa03 <=  ld_r ? text_in_r[031:024] ^ w3[31:24] : sa03_next;
always @(posedge clk)	sa32 <=  ld_r ? text_in_r[039:032] ^ w2[07:00] : sa32_next;
always @(posedge clk)	sa22 <=  ld_r ? text_in_r[047:040] ^ w2[15:08] : sa22_next;
always @(posedge clk)	sa12 <=  ld_r ? text_in_r[055:048] ^ w2[23:16] : sa12_next;
always @(posedge clk)	sa02 <=  ld_r ? text_in_r[063:056] ^ w2[31:24] : sa02_next;
always @(posedge clk)	sa31 <=  ld_r ? text_in_r[071:064] ^ w1[07:00] : sa31_next;
always @(posedge clk)	sa21 <=  ld_r ? text_in_r[079:072] ^ w1[15:08] : sa21_next;
always @(posedge clk)	sa11 <=  ld_r ? text_in_r[087:080] ^ w1[23:16] : sa11_next;
always @(posedge clk)	sa01 <=  ld_r ? text_in_r[095:088] ^ w1[31:24] : sa01_next;
always @(posedge clk)	sa30 <=  ld_r ? text_in_r[103:096] ^ w0[07:00] : sa30_next;
always @(posedge clk)	sa20 <=  ld_r ? text_in_r[111:104] ^ w0[15:08] : sa20_next;
always @(posedge clk)	sa10 <=  ld_r ? text_in_r[119:112] ^ w0[23:16] : sa10_next;
always @(posedge clk)	sa00 <=  ld_r ? text_in_r[127:120] ^ w0[31:24] : sa00_next;

////////////////////////////////////////////////////////////////////
//
// Round Permutations
//
//加密轮变换流程
//2.shiftrows变换
assign sa00_sr = sa00_sub;//第0行，不移位
assign sa01_sr = sa01_sub;
assign sa02_sr = sa02_sub;
assign sa03_sr = sa03_sub;
assign sa10_sr = sa11_sub;//第1行，循环左移1字节
assign sa11_sr = sa12_sub;
assign sa12_sr = sa13_sub;
assign sa13_sr = sa10_sub;
assign sa20_sr = sa22_sub;//第2行，循环左移2字节
assign sa21_sr = sa23_sub;
assign sa22_sr = sa20_sub;
assign sa23_sr = sa21_sub;
assign sa30_sr = sa33_sub;//第3行，循环左移3字节
assign sa31_sr = sa30_sub;
assign sa32_sr = sa31_sub;
assign sa33_sr = sa32_sub;

//加密轮变换流程
//3.MixColumns变换
wire [31:0] mix_col_out0, mix_col_out1, mix_col_out2, mix_col_out3;

assign mix_col_out0 = mix_col(sa00_sr,sa10_sr,sa20_sr,sa30_sr);
assign mix_col_out1 = mix_col(sa01_sr,sa11_sr,sa21_sr,sa31_sr);
assign mix_col_out2 = mix_col(sa02_sr,sa12_sr,sa22_sr,sa32_sr);
assign mix_col_out3 = mix_col(sa03_sr,sa13_sr,sa23_sr,sa33_sr);

assign {sa00_mc, sa10_mc, sa20_mc, sa30_mc} = mix_col_out0;
assign {sa01_mc, sa11_mc, sa21_mc, sa31_mc} = mix_col_out1;
assign {sa02_mc, sa12_mc, sa22_mc, sa32_mc} = mix_col_out2;
assign {sa03_mc, sa13_mc, sa23_mc, sa33_mc} = mix_col_out3;

//加密轮变换流程
//4.轮密钥加
assign sa00_next = sa00_mc ^ w0[31:24];
assign sa01_next = sa01_mc ^ w1[31:24];
assign sa02_next = sa02_mc ^ w2[31:24];
assign sa03_next = sa03_mc ^ w3[31:24];
assign sa10_next = sa10_mc ^ w0[23:16];
assign sa11_next = sa11_mc ^ w1[23:16];
assign sa12_next = sa12_mc ^ w2[23:16];
assign sa13_next = sa13_mc ^ w3[23:16];
assign sa20_next = sa20_mc ^ w0[15:08];
assign sa21_next = sa21_mc ^ w1[15:08];
assign sa22_next = sa22_mc ^ w2[15:08];
assign sa23_next = sa23_mc ^ w3[15:08];
assign sa30_next = sa30_mc ^ w0[07:00];
assign sa31_next = sa31_mc ^ w1[07:00];
assign sa32_next = sa32_mc ^ w2[07:00];
assign sa33_next = sa33_mc ^ w3[07:00];

////////////////////////////////////////////////////////////////////
//
// Final text output
//
//输出处理，最后一轮后的状态与最终轮密钥异或
always @(posedge clk) text_out[127:120] <=  sa00_sr ^ w0[31:24];
always @(posedge clk) text_out[095:088] <=  sa01_sr ^ w1[31:24];
always @(posedge clk) text_out[063:056] <=  sa02_sr ^ w2[31:24];
always @(posedge clk) text_out[031:024] <=  sa03_sr ^ w3[31:24];
always @(posedge clk) text_out[119:112] <=  sa10_sr ^ w0[23:16];
always @(posedge clk) text_out[087:080] <=  sa11_sr ^ w1[23:16];
always @(posedge clk) text_out[055:048] <=  sa12_sr ^ w2[23:16];
always @(posedge clk) text_out[023:016] <=  sa13_sr ^ w3[23:16];
always @(posedge clk) text_out[111:104] <=  sa20_sr ^ w0[15:08];
always @(posedge clk) text_out[079:072] <=  sa21_sr ^ w1[15:08];
always @(posedge clk) text_out[047:040] <=  sa22_sr ^ w2[15:08];
always @(posedge clk) text_out[015:008] <=  sa23_sr ^ w3[15:08];
always @(posedge clk) text_out[103:096] <=  sa30_sr ^ w0[07:00];
always @(posedge clk) text_out[071:064] <=  sa31_sr ^ w1[07:00];
always @(posedge clk) text_out[039:032] <=  sa32_sr ^ w2[07:00];
always @(posedge clk) text_out[007:000] <=  sa33_sr ^ w3[07:00];

////////////////////////////////////////////////////////////////////
//
// Generic Functions
//

function [31:0] mix_col;//实现GF(2^8)上的矩阵乘法
input	[7:0]	s0,s1,s2,s3;
reg	[7:0]	s0_o,s1_o,s2_o,s3_o;
begin
mix_col[31:24]=xtime(s0)^xtime(s1)^s1^s2^s3;
mix_col[23:16]=s0^xtime(s1)^xtime(s2)^s2^s3;
mix_col[15:08]=s0^s1^xtime(s2)^xtime(s3)^s3;
mix_col[07:00]=xtime(s0)^s0^s1^s2^xtime(s3);
end
endfunction

function [7:0] xtime;//实现GF(2^8)上的×2运算
input [7:0] b; xtime={b[6:0],1'b0}^(8'h1b&{8{b[7]}});
endfunction

////////////////////////////////////////////////////////////////////
//
// Modules
//

aes_key_expand_128 u0(
	.clk(		clk	),
	.kld(		ld	),
	.key(		key	),
	.wo_0(		w0	),
	.wo_1(		w1	),
	.wo_2(		w2	),
	.wo_3(		w3	));

//加密轮变换流程
//1.subbyte变换
aes_sbox us00(	.a(	sa00	), .b(	sa00_sub	));
aes_sbox us01(	.a(	sa01	), .b(	sa01_sub	));
aes_sbox us02(	.a(	sa02	), .b(	sa02_sub	));
aes_sbox us03(	.a(	sa03	), .b(	sa03_sub	));
aes_sbox us10(	.a(	sa10	), .b(	sa10_sub	));
aes_sbox us11(	.a(	sa11	), .b(	sa11_sub	));
aes_sbox us12(	.a(	sa12	), .b(	sa12_sub	));
aes_sbox us13(	.a(	sa13	), .b(	sa13_sub	));
aes_sbox us20(	.a(	sa20	), .b(	sa20_sub	));
aes_sbox us21(	.a(	sa21	), .b(	sa21_sub	));
aes_sbox us22(	.a(	sa22	), .b(	sa22_sub	));
aes_sbox us23(	.a(	sa23	), .b(	sa23_sub	));
aes_sbox us30(	.a(	sa30	), .b(	sa30_sub	));
aes_sbox us31(	.a(	sa31	), .b(	sa31_sub	));
aes_sbox us32(	.a(	sa32	), .b(	sa32_sub	));
aes_sbox us33(	.a(	sa33	), .b(	sa33_sub	));

endmodule

module stimulus_gen (
    input clk,
    input tb_match,
    output logic rst,
    output logic ld,
    output logic [127:0] key,
    output logic [127:0] text_in,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);
    // 核心测试向量：包含所有必要的边界条件和关键模式
    const logic [127:0] TEST_KEYS [6] = '{
        128'h000102030405060708090a0b0c0d0e0f,  // 标准测试向量
        128'hffffffffffffffffffffffffffffffff,    // 全1
        128'h00000000000000000000000000000000,   // 全0
        128'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa,   // 交替1010
        128'h5555555555555555555555555555555,    // 交替0101
        128'h0123456789abcdef0123456789abcdef    // 递增
    };
    
    task wavedrom_start(input[511:0] title = "");
        wavedrom_title = title;
        wavedrom_enable = 1;
    endtask

    task wavedrom_stop;
        wavedrom_enable = 0;
    endtask

    task reset_test(input async=0);
        bit arfail, srfail, datafail;
   
        @(posedge clk);
        @(posedge clk) rst = 0;
        repeat(3) @(posedge clk);
   
        @(negedge clk) begin datafail = !tb_match; rst = 1; end
        @(posedge clk) arfail = !tb_match;
        @(posedge clk) begin
            srfail = !tb_match;
            rst = 0;
        end
        if (srfail)
            $display("Hint: Your reset doesn't seem to be working.");
        else if (arfail && (async || !datafail))
            $display("Hint: Your reset should be %0s, but doesn't appear to be.", 
                    async ? "asynchronous" : "synchronous");
    endtask

    initial begin
        // 初始化
        {rst, ld, key, text_in, wavedrom_enable} = '0;
        wavedrom_title = "";
        
        // 复位测试
        reset_test(0);  // 同步复位测试
        repeat(2) @(posedge clk);
        reset_test(0);  // 异步复位测试
        repeat(2) @(posedge clk);
        
        // 记录核心加密过程
        wavedrom_start("Complete AES Encryption Process");
        @(negedge clk);
        key = TEST_KEYS[0];
        text_in = TEST_KEYS[1];
        {rst, ld} = 2'b11;
        @(posedge clk);
        ld = 0;
        repeat(15) @(posedge clk);
        wavedrom_stop();

        // 主要测试向量和边界条件测试
        for(int i=0; i<6; i++) begin
            @(negedge clk);
            key = TEST_KEYS[i];
            text_in = TEST_KEYS[(i+1)%6];  // 错位使用测试向量，增加组合
            rst = 1'b1;
            ld = 1'b1;
            @(posedge clk);
            ld = 1'b0;
            // 每两轮进行一次复位打断
            if(i[0]) begin
                repeat(5) @(posedge clk);
                rst = 1'b0;
                @(posedge clk);
                rst = 1'b1;
            end
            repeat(15) @(posedge clk);
        end

        // 随机测试和位翻转
        repeat(8) begin
            @(negedge clk);
            key = $random;
            text_in = {~key[126:0], key[127]};  // 创建互补模式
            rst = 1'b1;
            ld = 1'b1;
            @(posedge clk);
            ld = 1'b0;
            repeat(15) @(posedge clk);
        end

        // 最终复位测试
        reset_test(0);
        repeat(5) @(posedge clk);
        $finish;
    end
endmodule

module PATTERN(clk, rst, ld, key, text_in, done_dut, text_out_dut);
    output logic clk;
    output logic rst;
    output logic ld;
    output logic [127:0] key;
    output logic [127:0] text_in;
    input  logic done_dut;
    input  logic [127:0] text_out_dut;

    typedef struct packed {
        int errors;
        int errortime;
        int errors_done;
        int errortime_done;
        int errors_text_out;
        int errortime_text_out;
        int clocks;
    } stats;

    stats stats1;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic [511:0] wavedrom_title;
    logic         wavedrom_enable;
    logic done_ref;
    logic [127:0] text_out_ref;
    wire tb_match_done = (done_ref === done_dut);
    wire tb_match_text_out = (text_out_ref === text_out_dut);
    wire tb_match = tb_match_done & tb_match_text_out;

    stimulus_gen stim1 (
		.clk(clk),
		.tb_match(tb_match),
		.rst(rst),
		.ld(ld),
		.key(key),
		.text_in(text_in),
		.wavedrom_title(wavedrom_title),
		.wavedrom_enable(wavedrom_enable)
    );

    ref_aes_cipher_top good1 (
		.clk(clk),
		.rst(rst),
		.ld(ld),
		.done(done_ref),
		.key(key),
		.text_in(text_in),
		.text_out(text_out_ref)
    );

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0);
    end

    always @(posedge clk) begin
        stats1.clocks++;
        if (stats1.clocks > 1 && !tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (stats1.clocks > 1 && !tb_match_done) begin
            if (stats1.errors_done == 0) stats1.errortime_done = $time;
            stats1.errors_done++;
        end
        if (stats1.clocks > 1 && !tb_match_text_out) begin
            if (stats1.errors_text_out == 0) stats1.errortime_text_out = $time;
            stats1.errors_text_out++;
        end
    end

    final begin
        $display("\nTest Results:");
        if (stats1.errors_done)
            $display("Hint: Output done has %0d mismatches. First at time %0d",
                    stats1.errors_done, stats1.errortime_done);
        else
            $display("Hint: Output 'done' has no mismatches.");
        if (stats1.errors_text_out)
            $display("Hint: Output text_out has %0d mismatches. First at time %0d",
                    stats1.errors_text_out, stats1.errortime_text_out);
        else
            $display("Hint: Output 'text_out' has no mismatches.");
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
