module ref_sd_fifo_tx_filler
( 
input clk,
input rst,
//WB Signals
output  [31:0]  m_wb_adr_o,//WB 地址输出，用于指定 Wishbone 总线上地址。

output  reg        m_wb_we_o,//WB 写使能信号，控制是否进行写操作
input   [31:0]  m_wb_dat_i,//

output    reg      m_wb_cyc_o,//WB 周期信号，表示开始一个新的总线周期
output   reg       m_wb_stb_o,//WB 选通信号，激活对总线的访问
input           m_wb_ack_i,//WB的ack信号，表示当前周期的写操作成功
output  reg	[2:0] m_wb_cti_o,//WB 周期类型，通常用于定义操作的特定类型
output	reg [1:0]	 m_wb_bte_o,//WB 总线类型扩展，用于定义总线突发传输模式

//Data Master Control signals
input en,//使能，高电平时启动fifo缓冲区填充
input [31:0] adr,//地址信号，指定要读取数据的地址


//Data Serial signals 
input sd_clk,//SD数据传输的时钟信号
output [31:0] dat_o, //输出数据
input rd,//读使能信号，用于控制从fifo读取数据
output empty,
output fe
//

);
reg reset_tx_fifo;//用于重置TX FIFO信号

reg [31:0] din;//要写入FIFO的数据
reg wr_tx;//写入FIFO的控制信号，高电平时向fifo写入数据
reg [8:0] we;//用于计数写入的数据字节
reg [8:0] offset;//偏移量
wire [5:0]mem_empt;//表示fifo的空状态


//fifo实例
sd_tx_fifo Tx_Fifo (
.d ( din ),
.wr  (  wr_tx ),
.wclk  (clk),
.q ( dat_o),
.rd (rd),
.full (fe),
.empty (empty),
.mem_empt (mem_empt),
.rclk (sd_clk),
.rst  (rst | reset_tx_fifo)
);

//地址计算，生成输出地址
assign  m_wb_adr_o = adr+offset;


reg first;//标记第一次操作，用于初始化

reg ackd;
reg delay;//用于管理和同步ack信号的状态

always @(posedge clk or posedge rst )begin
 if (rst) begin
	offset <=0;
	we <= 8'h1;
	m_wb_we_o <=0;
	m_wb_cyc_o <= 0;
	m_wb_stb_o <= 0;
	wr_tx<=0;
	ackd <=1;
	delay<=0;
	reset_tx_fifo<=1;

	first<=1;
	din<=0;
		m_wb_bte_o <= 2'b00;
		m_wb_cti_o <= 3'b000;

			
 end
 else if (en) begin //Start filling the TX buffer，启动填充操作
    reset_tx_fifo<=0;
    
	  if (m_wb_ack_i) begin//表示当前写操作成功	  
		  wr_tx <=1;
		  din <=m_wb_dat_i;	
		  					
		  m_wb_cyc_o <= 0;
		  m_wb_stb_o <= 0; 
		  delay<=~ delay;   
		end 
		else begin
			wr_tx <=0;
			
		end
	 
	  if (delay)begin
	     offset<=offset+`MEM_OFFSET;	
	     ackd<=~ackd;
	     delay<=~ delay;
	     wr_tx <=0; 
	  end
	  
		if ( !m_wb_ack_i & !fe & ackd  ) begin //If not full And no Ack  
		  m_wb_we_o <=0;
			m_wb_cyc_o <= 1;
			m_wb_stb_o <= 1; 
			ackd<=0;   
		end 
		
 
 end 
 else begin
   offset <=0;
   reset_tx_fifo<=1;
   m_wb_cyc_o <= 0;
   m_wb_stb_o <= 0; 
   m_wb_we_o <=0; 
		
		
 end 
end 
  
endmodule

module stimulus_gen (
    input clk,
    output reg rst,
    output reg en,
    output reg [31:0] adr,
    output reg sd_clk,
    output reg [31:0] m_wb_dat_i,
    output reg m_wb_ack_i,
    output reg rd,
    output reg [511:0] wavedrom_title,
    output reg wavedrom_enable,
    input tb_match
);

    // 保留必要的reset_test task
    task reset_test(async=0);
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
    endtask

    // 简化wavedrom相关task
    task wavedrom_start(input[511:0] title = "");
        wavedrom_title = title;
        wavedrom_enable = 1;
    endtask
    task wavedrom_stop; 
        wavedrom_enable = 0;
    endtask

    // 针对性测试offset和地址生成
    task test_offset_sequence;
        repeat(16) begin
            @(posedge clk);
            en = 1;
            m_wb_ack_i = 1;
            // 使用不同的基础地址
            adr = (32'h1000 * $random) & 32'hFFFF_FFF0;
            m_wb_dat_i = $random;
            
            // 确保数据传输完成
            repeat(4) @(posedge clk);
            m_wb_ack_i = 0;
            
            // 让offset有时间更新
            repeat(2) @(posedge clk);
        end
    endtask

    // 时钟生成
    reg [2:0] sd_clk_div;
    always @(posedge clk) begin
        sd_clk_div = sd_clk_div + 1;
        if(sd_clk_div == 3'b111) begin
            sd_clk = ~sd_clk;
        end
    end

    // 主测试序列
    initial begin
        // 初始化
        {rst, en, adr, sd_clk, m_wb_dat_i, m_wb_ack_i, rd, sd_clk_div} = 0;
        wavedrom_enable = 0;

        // 基本复位测试
        repeat(5) @(posedge clk);
        wavedrom_start("Reset test");
        reset_test(1);
        wavedrom_stop();

        // 地址偏移测试序列
        repeat(4) begin
            // offset测试序列
            wavedrom_start("Offset test");
            test_offset_sequence();
            wavedrom_stop();
            
            // FIFO操作
            repeat(8) begin
                @(posedge clk);
                en = 1;
                m_wb_ack_i = 1;
                m_wb_dat_i = $random;
                adr = $random;
                rd = $random % 2;
            end
        end

        // 随机测试序列
        repeat(2000) @(posedge clk) begin
            // 基本信号随机化
            rst = ($random % 100 < 2);  // 降低复位概率
            en = ($random % 100 < 95);  // 提高使能概率
            m_wb_dat_i = $random;
            
            case ($random % 4)
                0: begin // 连续传输
                    repeat(4) begin
                        @(posedge clk);
                        m_wb_ack_i = 1;
                        adr = $random & 32'hFFFF_FFF0;
                    end
                    @(posedge clk) m_wb_ack_i = 0;
                end
                
                1: begin // 读写交替
                    repeat(4) begin
                        @(posedge clk);
                        m_wb_ack_i = 1;
                        rd = !rd;
                        adr = adr + 4;
                    end
                end
                
                2: begin // offset变化测试
                    repeat(8) begin
                        @(posedge clk);
                        m_wb_ack_i = !m_wb_ack_i;
                        adr = (adr + 4) & 32'hFFFF_FFF0;
                    end
                end
                
                3: begin // FIFO边界测试
                    repeat(4) begin
                        @(posedge clk);
                        m_wb_ack_i = 1;
                        rd = 0;
                        @(posedge clk);
                        m_wb_ack_i = 0;
                        rd = 1;
                    end
                end
            endcase
        end

        // 结束序列
        repeat(10) @(posedge clk) begin
            rst = 1;
            en = 0;
            {rd, m_wb_ack_i} = 0;
        end

        #500 $finish;
    end

endmodule

module PATTERN(clk, rst, m_wb_dat_i, m_wb_ack_i, en, adr, sd_clk, rd, m_wb_adr_o_dut, m_wb_we_o_dut, m_wb_cyc_o_dut, m_wb_stb_o_dut, m_wb_cti_o_dut, m_wb_bte_o_dut, dat_o_dut, empty_dut, fe_dut);
    output logic clk;
    output logic rst;
    output logic [31:0] m_wb_dat_i;
    output logic m_wb_ack_i;
    output logic en;
    output logic [31:0] adr;
    output logic sd_clk;
    output logic rd;
    input  logic [31:0] m_wb_adr_o_dut;
    input  logic m_wb_we_o_dut;
    input  logic m_wb_cyc_o_dut;
    input  logic m_wb_stb_o_dut;
    input  logic [2:0] m_wb_cti_o_dut;
    input  logic [1:0] m_wb_bte_o_dut;
    input  logic [31:0] dat_o_dut;
    input  logic empty_dut;
    input  logic fe_dut;

    typedef struct packed {
        int errors;
        int errortime;
        int errors_m_wb_adr_o;
        int errortime_m_wb_adr_o;
        int errors_m_wb_we_o;
        int errortime_m_wb_we_o;
        int errors_m_wb_cyc_o;
        int errortime_m_wb_cyc_o;
        int errors_m_wb_stb_o;
        int errortime_m_wb_stb_o;
        int errors_m_wb_cti_o;
        int errortime_m_wb_cti_o;
        int errors_m_wb_bte_o;
        int errortime_m_wb_bte_o;
        int errors_dat_o;
        int errortime_dat_o;
        int errors_empty;
        int errortime_empty;
        int errors_fe;
        int errortime_fe;
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
    logic m_wb_cyc_o_ref;
    logic m_wb_stb_o_ref;
    logic [2:0] m_wb_cti_o_ref;
    logic [1:0] m_wb_bte_o_ref;
    logic [31:0] dat_o_ref;
    logic empty_ref;
    logic fe_ref;
    wire tb_match_m_wb_adr_o = (m_wb_adr_o_ref === m_wb_adr_o_dut);
    wire tb_match_m_wb_we_o = (m_wb_we_o_ref === m_wb_we_o_dut);
    wire tb_match_m_wb_cyc_o = (m_wb_cyc_o_ref === m_wb_cyc_o_dut);
    wire tb_match_m_wb_stb_o = (m_wb_stb_o_ref === m_wb_stb_o_dut);
    wire tb_match_m_wb_cti_o = (m_wb_cti_o_ref === m_wb_cti_o_dut);
    wire tb_match_m_wb_bte_o = (m_wb_bte_o_ref === m_wb_bte_o_dut);
    wire tb_match_dat_o = (dat_o_ref === dat_o_dut);
    wire tb_match_empty = (empty_ref === empty_dut);
    wire tb_match_fe = (fe_ref === fe_dut);
    wire tb_match = tb_match_m_wb_adr_o & tb_match_m_wb_we_o & tb_match_m_wb_cyc_o & tb_match_m_wb_stb_o & tb_match_m_wb_cti_o & tb_match_m_wb_bte_o & tb_match_dat_o & tb_match_empty & tb_match_fe;

    stimulus_gen stim1 (
		.clk(clk),
		.rst(rst),
		.en(en),
		.adr(adr),
		.sd_clk(sd_clk),
		.m_wb_dat_i(m_wb_dat_i),
		.m_wb_ack_i(m_wb_ack_i),
		.rd(rd),
		.wavedrom_title(wavedrom_title),
		.wavedrom_enable(wavedrom_enable),
		.tb_match(tb_match)
    );

    ref_sd_fifo_tx_filler good1 (
		.clk(clk),
		.rst(rst),
		.m_wb_adr_o(m_wb_adr_o_ref),
		.m_wb_we_o(m_wb_we_o_ref),
		.m_wb_dat_i(m_wb_dat_i),
		.m_wb_cyc_o(m_wb_cyc_o_ref),
		.m_wb_stb_o(m_wb_stb_o_ref),
		.m_wb_ack_i(m_wb_ack_i),
		.m_wb_cti_o(m_wb_cti_o_ref),
		.m_wb_bte_o(m_wb_bte_o_ref),
		.en(en),
		.adr(adr),
		.sd_clk(sd_clk),
		.dat_o(dat_o_ref),
		.rd(rd),
		.empty(empty_ref),
		.fe(fe_ref)
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
        if (stats1.clocks > 1 && !tb_match_dat_o) begin
            if (stats1.errors_dat_o == 0) stats1.errortime_dat_o = $time;
            stats1.errors_dat_o++;
        end
        if (stats1.clocks > 1 && !tb_match_empty) begin
            if (stats1.errors_empty == 0) stats1.errortime_empty = $time;
            stats1.errors_empty++;
        end
        if (stats1.clocks > 1 && !tb_match_fe) begin
            if (stats1.errors_fe == 0) stats1.errortime_fe = $time;
            stats1.errors_fe++;
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
        if (stats1.errors_dat_o)
            $display("Hint: Output dat_o has %0d mismatches. First at time %0d",
                    stats1.errors_dat_o, stats1.errortime_dat_o);
        else
            $display("Hint: Output 'dat_o' has no mismatches.");
        if (stats1.errors_empty)
            $display("Hint: Output empty has %0d mismatches. First at time %0d",
                    stats1.errors_empty, stats1.errortime_empty);
        else
            $display("Hint: Output 'empty' has no mismatches.");
        if (stats1.errors_fe)
            $display("Hint: Output fe has %0d mismatches. First at time %0d",
                    stats1.errors_fe, stats1.errortime_fe);
        else
            $display("Hint: Output 'fe' has no mismatches.");
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
