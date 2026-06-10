module ref_aes_key_expand_128(clk, kld, key, wo_0, wo_1, wo_2, wo_3);
input		clk;
input		kld;
input	[127:0]	key;
output	[31:0]	wo_0, wo_1, wo_2, wo_3;
reg	[31:0]	w[3:0];
wire	[31:0]	tmp_w;
wire	[31:0]	subword;
wire	[31:0]	rcon;

assign wo_0 = w[0];
assign wo_1 = w[1];
assign wo_2 = w[2];
assign wo_3 = w[3];
always @(posedge clk)	w[0] <=  kld ? key[127:096] : w[0]^subword^rcon;
always @(posedge clk)	w[1] <=  kld ? key[095:064] : w[0]^w[1]^subword^rcon;
always @(posedge clk)	w[2] <=  kld ? key[063:032] : w[0]^w[2]^w[1]^subword^rcon;
always @(posedge clk)	w[3] <=  kld ? key[031:000] : w[0]^w[3]^w[2]^w[1]^subword^rcon;
assign tmp_w = w[3];
aes_sbox u0(	.a(tmp_w[23:16]), .b(subword[31:24]));
aes_sbox u1(	.a(tmp_w[15:08]), .b(subword[23:16]));
aes_sbox u2(	.a(tmp_w[07:00]), .b(subword[15:08]));
aes_sbox u3(	.a(tmp_w[31:24]), .b(subword[07:00]));
aes_rcon r0(	.clk(clk), .kld(kld), .out(rcon));
endmodule

module stimulus_gen (
    input clk,
    output logic kld,                // key load signal
    output logic [127:0] key        // input key
);
    // 一些典型的测试密钥
    const logic [127:0] TEST_KEYS [4] = '{
        128'h000102030405060708090a0b0c0d0e0f,  // AES标准文档中的例子
        128'h2b7e151628aed2a6abf7158809cf4f3c,  // NIST测试向量
        128'hffffffffffffffffffffffffffffffff,    // 全1
        128'h00000000000000000000000000000000    // 全0
    };
    
    initial begin
        // 初始化
        kld = 1'bx;
        key = 'x;
        @(negedge clk);
        
        // 第一轮：基本功能测试，测试所有预定义的密钥
        for(int i=0; i<4; i++) begin
            // 加载新密钥
            key = TEST_KEYS[i];
            kld = 1'b1;
            @(posedge clk);
            
            // 生成扩展密钥
            kld = 1'b0;
            repeat(12) @(posedge clk);  // 等待足够的时间让密钥完全扩展
        end
        
        // 第二轮：中途重载测试
        key = TEST_KEYS[0];
        kld = 1'b1;
        @(posedge clk);
        kld = 1'b0;
        repeat(5) @(posedge clk);
        
        // 中途重新加载另一个密钥
        key = TEST_KEYS[1];
        kld = 1'b1;
        @(posedge clk);
        kld = 1'b0;
        repeat(12) @(posedge clk);
        
        // 第三轮：快速切换测试
        repeat(4) begin
            key = TEST_KEYS[2];
            kld = 1'b1;
            @(posedge clk);
            kld = 1'b0;
            @(posedge clk);
            
            key = TEST_KEYS[3];
            kld = 1'b1;
            @(posedge clk);
            kld = 1'b0;
            @(posedge clk);
        end
        
        // 完成测试
        @(posedge clk);
        $finish;
    end
endmodule

module PATTERN(clk, kld, key, wo_0_dut, wo_1_dut, wo_2_dut, wo_3_dut);
    output logic clk;
    output logic kld;
    output logic [127:0] key;
    input  logic [31:0] wo_0_dut;
    input  logic [31:0] wo_1_dut;
    input  logic [31:0] wo_2_dut;
    input  logic [31:0] wo_3_dut;

    typedef struct packed {
        int errors;
        int errortime;
        int errors_wo_0;
        int errortime_wo_0;
        int errors_wo_1;
        int errortime_wo_1;
        int errors_wo_2;
        int errortime_wo_2;
        int errors_wo_3;
        int errortime_wo_3;
        int clocks;
    } stats;

    stats stats1;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic [511:0] wavedrom_title;
    logic         wavedrom_enable;
    logic [31:0] wo_0_ref;
    logic [31:0] wo_1_ref;
    logic [31:0] wo_2_ref;
    logic [31:0] wo_3_ref;
    wire tb_match_wo_0 = (wo_0_ref === wo_0_dut);
    wire tb_match_wo_1 = (wo_1_ref === wo_1_dut);
    wire tb_match_wo_2 = (wo_2_ref === wo_2_dut);
    wire tb_match_wo_3 = (wo_3_ref === wo_3_dut);
    wire tb_match = tb_match_wo_0 & tb_match_wo_1 & tb_match_wo_2 & tb_match_wo_3;

    stimulus_gen stim1 (
		.clk(clk),
		.kld(kld),
		.key(key),
		.key(key)
    );

    ref_aes_key_expand_128 good1 (
		.clk(clk),
		.kld(kld),
		.key(key),
		.wo_0(wo_0_ref),
		.wo_1(wo_1_ref),
		.wo_2(wo_2_ref),
		.wo_3(wo_3_ref)
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
        if (stats1.clocks > 1 && !tb_match_wo_0) begin
            if (stats1.errors_wo_0 == 0) stats1.errortime_wo_0 = $time;
            stats1.errors_wo_0++;
        end
        if (stats1.clocks > 1 && !tb_match_wo_1) begin
            if (stats1.errors_wo_1 == 0) stats1.errortime_wo_1 = $time;
            stats1.errors_wo_1++;
        end
        if (stats1.clocks > 1 && !tb_match_wo_2) begin
            if (stats1.errors_wo_2 == 0) stats1.errortime_wo_2 = $time;
            stats1.errors_wo_2++;
        end
        if (stats1.clocks > 1 && !tb_match_wo_3) begin
            if (stats1.errors_wo_3 == 0) stats1.errortime_wo_3 = $time;
            stats1.errors_wo_3++;
        end
    end

    final begin
        $display("\nTest Results:");
        if (stats1.errors_wo_0)
            $display("Hint: Output wo_0 has %0d mismatches. First at time %0d",
                    stats1.errors_wo_0, stats1.errortime_wo_0);
        else
            $display("Hint: Output 'wo_0' has no mismatches.");
        if (stats1.errors_wo_1)
            $display("Hint: Output wo_1 has %0d mismatches. First at time %0d",
                    stats1.errors_wo_1, stats1.errortime_wo_1);
        else
            $display("Hint: Output 'wo_1' has no mismatches.");
        if (stats1.errors_wo_2)
            $display("Hint: Output wo_2 has %0d mismatches. First at time %0d",
                    stats1.errors_wo_2, stats1.errortime_wo_2);
        else
            $display("Hint: Output 'wo_2' has no mismatches.");
        if (stats1.errors_wo_3)
            $display("Hint: Output wo_3 has %0d mismatches. First at time %0d",
                    stats1.errors_wo_3, stats1.errortime_wo_3);
        else
            $display("Hint: Output 'wo_3' has no mismatches.");
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
