`include "sd_defines.v"

module ref_sd_fifo_rx_filler
( 
input clk,
input rst,
//WB Signals
output  [31:0]  m_wb_adr_o,//wishbone接口的地址输出

output  reg        m_wb_we_o,//写使能信号

output reg [31:0]  m_wb_dat_o,//wishbone接口的地址输出
output    reg      m_wb_cyc_o,
output   reg       m_wb_stb_o,//wishbone接口控制信号
input           m_wb_ack_i,//表示从设备已经成功接收了主设备的请求
output  reg	[2:0] m_wb_cti_o,
output	reg [1:0]	 m_wb_bte_o,//传输类型和突发类信号

//Data Master Control signals
input en,//使能信号，用于控制FIFO的填充
input [31:0] adr,//地址信号，用于写入数据的地址

//Data Serial signals 
input sd_clk,//SD数据时钟信号
input [`SD_BUS_W-1:0] dat_i, //输入数据
input wr,//写使能信号
output full,//指示FIFO已满的状态
output empty//

);
 wire [31:0] dat_o;
reg rd;
reg reset_rx_fifo;
sd_rx_fifo Rx_Fifo (//用于接收输入数据
.d ( dat_i ),
.wr  (  wr ),
.wclk  (sd_clk),
.q ( dat_o),
.rd (rd),
.full (full),
.empty (empty),
.mem_empt (),
.rclk (clk),
.rst  (rst | reset_rx_fifo)
);

//reg [31:0] tmp_dat;
reg [8:0] offset;//用于地址偏移
assign  m_wb_adr_o = adr+offset;//地址输出：由基地址adr和偏移地址计算得出的地址
//assign  m_wb_dat_o = dat_o;

reg wb_free;
always @(posedge clk or posedge rst )begin

 if (rst) begin
  offset<=0;
  m_wb_we_o <=0;
	m_wb_cyc_o <= 0;
	m_wb_stb_o <= 0;
	wb_free<=1;
	m_wb_dat_o<=0;
	rd<=0;
	reset_rx_fifo<=1;
	m_wb_bte_o <= 2'b00;
		m_wb_cti_o <= 3'b000;

 end
 else if (en)  begin//Start filling the RX buffer，开始填充RX FIFO
    rd<=0;
    reset_rx_fifo<=0;
  if (!empty & wb_free) begin
    rd<=1;
    
    m_wb_dat_o<=#1 dat_o;
    m_wb_we_o <=#1 1;
		m_wb_cyc_o <=#1 1;
		m_wb_stb_o <=#1 1; 
    wb_free<=0;   
  end

 //当前没有空闲且接收到ack信号，表示写入完成
 //重置相关控制信号并更新offset 
  if(  !wb_free & m_wb_ack_i) begin
    m_wb_we_o <=0;
		m_wb_cyc_o <= 0;
		m_wb_stb_o <= 0;
		offset<=offset+`MEM_OFFSET;
		wb_free<=1;
	end	 
end
else begin//如果en为假，重置相关信号并清空FIFO
   reset_rx_fifo<=1;
    rd<=0;
   offset<=0;
    	m_wb_cyc_o <= 0;
			m_wb_stb_o <= 0; 
			m_wb_we_o <=0; 
			wb_free<=1;
  end

end  
endmodule

module stimulus_gen (
    input clk,
    output reg rst,
    output reg en,
    output reg [31:0] adr,
    output reg sd_clk,
    output reg [`SD_BUS_W-1:0] dat_i,
    output reg wr,
    output reg m_wb_ack_i,
    output reg [511:0] wavedrom_title,
    output reg wavedrom_enable,
    input tb_match
);
    
    initial sd_clk = 0;
    always #10 sd_clk = ~sd_clk;

    task wavedrom_start(input[511:0] title = "");
        wavedrom_title = title;
        wavedrom_enable = 1;
    endtask

    task wavedrom_stop;
        #1 wavedrom_enable = 0;
    endtask

    task reset_test(input async = 0);
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
            $display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
    endtask

    task test_main;
        integer i;
        begin
            en = 1;
            
            // 阶段1: 让offset累积，测试adr组合
            for(i=0; i<512; i=i+1) begin  // 覆盖所有9位offset值
                // 交替使用固定和随机地址
                adr = (i % 2) ? 32'hFFFF_FFF0 : $random;
                
                // 写入并传输以更新offset
                @(posedge sd_clk);
                wr = 1;
                dat_i = $random;
                @(posedge sd_clk);
                wr = 0;
                
                @(posedge clk);
                m_wb_ack_i = 1;
                @(posedge clk);
                m_wb_ack_i = 0;
                
                // 适度的使能切换
                if(i % 64 == 63) begin
                    en = 0;
                    @(posedge clk);
                    en = 1;
                end
                
                // 最小化的复位操作
                if(i % 256 == 255) begin
                    rst = 1;
                    @(posedge clk);
                    rst = 0;
                end
            end
            
            // 阶段2: 密集的数据传输
            repeat(128) begin
                @(posedge sd_clk);
                wr = 1;
                dat_i = $random;
                @(posedge sd_clk);
                wr = 0;
            end
        end
    endtask

    initial begin
        // 初始化
        rst = 0;
        en = 0;
        adr = 0;
        wr = 0;
        dat_i = 0;
        m_wb_ack_i = 0;

        // 1. 基础复位测试
        repeat(10) begin
            wavedrom_start("Reset Test");
            reset_test(1);
            wavedrom_stop();
            repeat(5) @(posedge clk);
        end

        // 2. 主要测试序列
        repeat(8) begin
            wavedrom_start("Main Test");
            test_main();
            wavedrom_stop();
            
            // 每轮之间的复位
            rst = 1;
            @(posedge clk);
            rst = 0;
            repeat(5) @(posedge clk);
        end

        // 3. 随机测试
        repeat(1000) @(posedge clk) begin
            // 地址和数据操作
            if($random % 2 == 0) begin
                adr = $random;
                @(posedge sd_clk);
                wr = 1;
                dat_i = $random;
                @(posedge sd_clk);
                wr = 0;
            end
            
            // 总线控制
            if($random % 3 == 0) begin
                m_wb_ack_i = 1;
                @(posedge clk);
                m_wb_ack_i = 0;
            end
            
            // 最小化控制信号切换
            if($random % 32 == 0) en = !en;
            if($random % 64 == 0) begin
                rst = 1;
                @(posedge clk);
                rst = 0;
            end
        end

        #100 $finish;
    end

endmodule

module PATTERN(clk, rst, m_wb_ack_i, en, adr, sd_clk, dat_i, wr, m_wb_adr_o_dut, m_wb_we_o_dut, m_wb_dat_o_dut, m_wb_cyc_o_dut, m_wb_stb_o_dut, m_wb_cti_o_dut, m_wb_bte_o_dut, full_dut, empty_dut);
    output logic clk;
    output logic rst;
    output logic m_wb_ack_i;
    output logic en;
    output logic [31:0] adr;
    output logic sd_clk;
    output logic [`SD_BUS_W-1:0] dat_i;
    output logic wr;
    input  logic [31:0] m_wb_adr_o_dut;
    input  logic m_wb_we_o_dut;
    input  logic [31:0] m_wb_dat_o_dut;
    input  logic m_wb_cyc_o_dut;
    input  logic m_wb_stb_o_dut;
    input  logic [2:0] m_wb_cti_o_dut;
    input  logic [1:0] m_wb_bte_o_dut;
    input  logic full_dut;
    input  logic empty_dut;

    typedef struct packed {
        int errors;
        int errortime;
        int errors_m_wb_adr_o;
        int errortime_m_wb_adr_o;
        int errors_m_wb_we_o;
        int errortime_m_wb_we_o;
        int errors_m_wb_dat_o;
        int errortime_m_wb_dat_o;
        int errors_m_wb_cyc_o;
        int errortime_m_wb_cyc_o;
        int errors_m_wb_stb_o;
        int errortime_m_wb_stb_o;
        int errors_m_wb_cti_o;
        int errortime_m_wb_cti_o;
        int errors_m_wb_bte_o;
        int errortime_m_wb_bte_o;
        int errors_full;
        int errortime_full;
        int errors_empty;
        int errortime_empty;
        int clocks;
    } stats;

    stats stats1;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic [511:0] wavedrom_title;
    logic         wavedrom_enable;
    logic [31:0] m_wb_adr_o_ref;
    logic m_wb_we_o_ref;
    logic [31:0] m_wb_dat_o_ref;
    logic m_wb_cyc_o_ref;
    logic m_wb_stb_o_ref;
    logic [2:0] m_wb_cti_o_ref;
    logic [1:0] m_wb_bte_o_ref;
    logic full_ref;
    logic empty_ref;
    wire tb_match_m_wb_adr_o = (m_wb_adr_o_ref === m_wb_adr_o_dut);
    wire tb_match_m_wb_we_o = (m_wb_we_o_ref === m_wb_we_o_dut);
    wire tb_match_m_wb_dat_o = (m_wb_dat_o_ref === m_wb_dat_o_dut);
    wire tb_match_m_wb_cyc_o = (m_wb_cyc_o_ref === m_wb_cyc_o_dut);
    wire tb_match_m_wb_stb_o = (m_wb_stb_o_ref === m_wb_stb_o_dut);
    wire tb_match_m_wb_cti_o = (m_wb_cti_o_ref === m_wb_cti_o_dut);
    wire tb_match_m_wb_bte_o = (m_wb_bte_o_ref === m_wb_bte_o_dut);
    wire tb_match_full = (full_ref === full_dut);
    wire tb_match_empty = (empty_ref === empty_dut);
    wire tb_match = tb_match_m_wb_adr_o & tb_match_m_wb_we_o & tb_match_m_wb_dat_o & tb_match_m_wb_cyc_o & tb_match_m_wb_stb_o & tb_match_m_wb_cti_o & tb_match_m_wb_bte_o & tb_match_full & tb_match_empty;

    stimulus_gen stim1 (
		.clk(clk),
		.rst(rst),
		.en(en),
		.adr(adr),
		.sd_clk(sd_clk),
		.dat_i(dat_i),
		.wr(wr),
		.m_wb_ack_i(m_wb_ack_i),
		.wavedrom_title(wavedrom_title),
		.wavedrom_enable(wavedrom_enable),
		.tb_match(tb_match)
    );

    ref_sd_fifo_rx_filler good1 (
		.clk(clk),
		.rst(rst),
		.m_wb_adr_o(m_wb_adr_o_ref),
		.m_wb_we_o(m_wb_we_o_ref),
		.m_wb_dat_o(m_wb_dat_o_ref),
		.m_wb_cyc_o(m_wb_cyc_o_ref),
		.m_wb_stb_o(m_wb_stb_o_ref),
		.m_wb_ack_i(m_wb_ack_i),
		.m_wb_cti_o(m_wb_cti_o_ref),
		.m_wb_bte_o(m_wb_bte_o_ref),
		.en(en),
		.adr(adr),
		.sd_clk(sd_clk),
		.dat_i(dat_i),
		.wr(wr),
		.full(full_ref),
		.empty(empty_ref)
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
        if (stats1.clocks > 1 && !tb_match_m_wb_adr_o) begin
            if (stats1.errors_m_wb_adr_o == 0) stats1.errortime_m_wb_adr_o = $time;
            stats1.errors_m_wb_adr_o++;
        end
        if (stats1.clocks > 1 && !tb_match_m_wb_we_o) begin
            if (stats1.errors_m_wb_we_o == 0) stats1.errortime_m_wb_we_o = $time;
            stats1.errors_m_wb_we_o++;
        end
        if (stats1.clocks > 1 && !tb_match_m_wb_dat_o) begin
            if (stats1.errors_m_wb_dat_o == 0) stats1.errortime_m_wb_dat_o = $time;
            stats1.errors_m_wb_dat_o++;
        end
        if (stats1.clocks > 1 && !tb_match_m_wb_cyc_o) begin
            if (stats1.errors_m_wb_cyc_o == 0) stats1.errortime_m_wb_cyc_o = $time;
            stats1.errors_m_wb_cyc_o++;
        end
        if (stats1.clocks > 1 && !tb_match_m_wb_stb_o) begin
            if (stats1.errors_m_wb_stb_o == 0) stats1.errortime_m_wb_stb_o = $time;
            stats1.errors_m_wb_stb_o++;
        end
        if (stats1.clocks > 1 && !tb_match_m_wb_cti_o) begin
            if (stats1.errors_m_wb_cti_o == 0) stats1.errortime_m_wb_cti_o = $time;
            stats1.errors_m_wb_cti_o++;
        end
        if (stats1.clocks > 1 && !tb_match_m_wb_bte_o) begin
            if (stats1.errors_m_wb_bte_o == 0) stats1.errortime_m_wb_bte_o = $time;
            stats1.errors_m_wb_bte_o++;
        end
        if (stats1.clocks > 1 && !tb_match_full) begin
            if (stats1.errors_full == 0) stats1.errortime_full = $time;
            stats1.errors_full++;
        end
        if (stats1.clocks > 1 && !tb_match_empty) begin
            if (stats1.errors_empty == 0) stats1.errortime_empty = $time;
            stats1.errors_empty++;
        end
    end

    final begin
        $display("\nTest Results:");
        if (stats1.errors_m_wb_adr_o)
            $display("Hint: Output m_wb_adr_o has %0d mismatches. First at time %0d",
                    stats1.errors_m_wb_adr_o, stats1.errortime_m_wb_adr_o);
        else
            $display("Hint: Output 'm_wb_adr_o' has no mismatches.");
        if (stats1.errors_m_wb_we_o)
            $display("Hint: Output m_wb_we_o has %0d mismatches. First at time %0d",
                    stats1.errors_m_wb_we_o, stats1.errortime_m_wb_we_o);
        else
            $display("Hint: Output 'm_wb_we_o' has no mismatches.");
        if (stats1.errors_m_wb_dat_o)
            $display("Hint: Output m_wb_dat_o has %0d mismatches. First at time %0d",
                    stats1.errors_m_wb_dat_o, stats1.errortime_m_wb_dat_o);
        else
            $display("Hint: Output 'm_wb_dat_o' has no mismatches.");
        if (stats1.errors_m_wb_cyc_o)
            $display("Hint: Output m_wb_cyc_o has %0d mismatches. First at time %0d",
                    stats1.errors_m_wb_cyc_o, stats1.errortime_m_wb_cyc_o);
        else
            $display("Hint: Output 'm_wb_cyc_o' has no mismatches.");
        if (stats1.errors_m_wb_stb_o)
            $display("Hint: Output m_wb_stb_o has %0d mismatches. First at time %0d",
                    stats1.errors_m_wb_stb_o, stats1.errortime_m_wb_stb_o);
        else
            $display("Hint: Output 'm_wb_stb_o' has no mismatches.");
        if (stats1.errors_m_wb_cti_o)
            $display("Hint: Output m_wb_cti_o has %0d mismatches. First at time %0d",
                    stats1.errors_m_wb_cti_o, stats1.errortime_m_wb_cti_o);
        else
            $display("Hint: Output 'm_wb_cti_o' has no mismatches.");
        if (stats1.errors_m_wb_bte_o)
            $display("Hint: Output m_wb_bte_o has %0d mismatches. First at time %0d",
                    stats1.errors_m_wb_bte_o, stats1.errortime_m_wb_bte_o);
        else
            $display("Hint: Output 'm_wb_bte_o' has no mismatches.");
        if (stats1.errors_full)
            $display("Hint: Output full has %0d mismatches. First at time %0d",
                    stats1.errors_full, stats1.errortime_full);
        else
            $display("Hint: Output 'full' has no mismatches.");
        if (stats1.errors_empty)
            $display("Hint: Output empty has %0d mismatches. First at time %0d",
                    stats1.errors_empty, stats1.errortime_empty);
        else
            $display("Hint: Output 'empty' has no mismatches.");
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
