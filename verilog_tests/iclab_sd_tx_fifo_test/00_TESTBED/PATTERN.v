
`include "sd_defines.v"
module ref_sd_tx_fifo
  (
   input [32-1:0] d,//写入数据，宽度32位
   input wr,//输入写使能
   input wclk,//写时钟信号
   output [32-1:0] q,//读取输出的数据，宽度32位
   input rd,//读使能信号
   output full,//FIFO满信号
   output empty,//FIFO空信号
   output [5:0] mem_empt,//当前FIFO中的空余空间，6位
   input rclk,//读时钟信号
   input rst
   );
   
   reg [32-1:0] ram [0:`FIFO_TX_MEM_DEPTH-1]; //synthesis syn_ramstyle = "no_rw_check"
   //存储数据的RAM，大小由FIFO_TX_MEM_DEPTH定义
   reg [`FIFO_TX_MEM_ADR_SIZE-1:0] adr_i, adr_o;//分别用于写地址和读地址的寄存器
   wire ram_we;//最终的写使能信号，用于控制是否写入数据
   wire [32-1:0] ram_din;//进入RAM的数据
    

    //写操作   
   assign ram_we = wr & ~full;
   assign ram_din = d;
   
   always @ (posedge wclk)
     if (ram_we)
       ram[adr_i[`FIFO_TX_MEM_ADR_SIZE-2:0]] <= ram_din;
   

   //写地址管理
   always @ (posedge wclk or posedge rst)
     if (rst)
       adr_i <= `FIFO_TX_MEM_ADR_SIZE'h0;
     else
       if (ram_we)//如果可以写入，并且当前地址到达 FIFO_TX_MEM_DEPTH-1，则重置地址并翻转高位；否则，地址加 1
      	 if (adr_i == `FIFO_TX_MEM_DEPTH-1) begin
	        adr_i[`FIFO_TX_MEM_ADR_SIZE-2:0] <=0;	   
	        adr_i[`FIFO_TX_MEM_ADR_SIZE-1]<=~adr_i[`FIFO_TX_MEM_ADR_SIZE-1];
	    end  
	     else
	      adr_i <= adr_i + `FIFO_TX_MEM_ADR_SIZE'h1;
	   
	  //读操作
   always @ (posedge rclk or posedge rst)
     if (rst)
       adr_o <= `FIFO_TX_MEM_ADR_SIZE'h0;
     else
       if (!empty & rd) begin//FIFO不空切读使能信号有效，进行读地址更新
	
	 if (adr_o == `FIFO_TX_MEM_DEPTH-1) begin
	    adr_o[`FIFO_TX_MEM_ADR_SIZE-2:0] <=0;
	    adr_o[`FIFO_TX_MEM_ADR_SIZE-1] <=~adr_o[`FIFO_TX_MEM_ADR_SIZE-1];
	 end  
	 else
	   adr_o <= adr_o + `FIFO_TX_MEM_ADR_SIZE'h1;
	 end
//------------------------------------------------------------------
// Simplified version of the three necessary full-tests:
// assign wfull_val=((wgnext[ADDRSIZE] !=wq2_rptr[ADDRSIZE] ) &&
// (wgnext[ADDRSIZE-1] !=wq2_rptr[ADDRSIZE-1]) &&
// (wgnext[ADDRSIZE-2:0]==wq2_rptr[ADDRSIZE-2:0]));
//------------------------------------------------------------------
	   
	 //状态信号和输出  
   assign full=  ( adr_i[`FIFO_TX_MEM_ADR_SIZE-2:0] == adr_o[`FIFO_TX_MEM_ADR_SIZE-2:0] ) &  (adr_i[`FIFO_TX_MEM_ADR_SIZE-1] ^ adr_o[`FIFO_TX_MEM_ADR_SIZE-1]) ;
   //当写地址和读地址相同且高位不同（表示循环回绕）时，FIFO 被视为满。
   assign empty = (adr_i == adr_o) ;
   //当写地址和读地址相同时，FIFO 被视为空
   assign mem_empt = ( adr_i-adr_o);
   //计算当前 FIFO 中的空余空间。
   assign q = ram[adr_o[`FIFO_TX_MEM_ADR_SIZE-2:0]];
   //根据读地址从 RAM 中读取数据。
endmodule

module stimulus_gen (
    input wclk,
    input rclk,
    input tb_match,
    // DUT输入信号
    output reg [31:0] d,       // 32位数据输入
    output reg wr,
    output reg rd,
    output reg rst,
    // 波形显示信号
    output reg [511:0] wavedrom_title,
    output reg wavedrom_enable
);

    task wavedrom_start(input[511:0] title = "");
        wavedrom_title = title;
        wavedrom_enable = 1;
    endtask

    task wavedrom_stop;
        wavedrom_enable = 0;
    endtask

    task reset_test(input async=0);
        bit arfail, srfail, datafail;
   
        @(posedge wclk);
        @(posedge wclk) rst = 0;
        repeat(3) @(posedge wclk);
   
        @(negedge wclk) begin datafail = !tb_match; rst = 1; end
        @(posedge wclk) arfail = !tb_match;
        @(posedge wclk) begin
            srfail = !tb_match;
            rst = 0;
        end
        if (srfail)
            $display("Hint: Your reset doesn't seem to be working.");
        else if (arfail && (async || !datafail))
            $display("Hint: Your reset should be %0s, but doesn't appear to be.", 
                    async ? "asynchronous" : "synchronous");
    endtask

    // 新增：写指针回环测试
    task test_write_wrap;
        repeat(2) begin
            // 连续写直到回环
            repeat(`FIFO_TX_MEM_DEPTH + 2) begin
                @(posedge wclk);
                wr = 1;
                d = $random;
                @(posedge wclk);
                wr = 0;
                @(posedge wclk);
            end
            
            // 等待一些时钟周期
            repeat(10) @(posedge wclk);
        end
    endtask

    // 新增：读指针回环测试
    task test_read_wrap;
        // 先写入足够的数据
        repeat(`FIFO_TX_MEM_DEPTH) begin
            @(posedge wclk);
            wr = 1;
            d = $random;
            @(posedge wclk);
            wr = 0;
        end
        
        // 连续读直到回环
        repeat(`FIFO_TX_MEM_DEPTH + 2) begin
            @(posedge rclk);
            rd = 1;
            @(posedge rclk);
            rd = 0;
            @(posedge rclk);
        end
    endtask

    initial begin
        // 初始化
        rst = 1'b1;
        wr = 0;
        rd = 0;
        d = 32'h0;
        wavedrom_enable = 0;

        // 复位测试
        repeat(10) @(posedge wclk);
        wavedrom_start("Reset test");
        reset_test(1);
        wavedrom_stop();

        // 基本写读测试
        wavedrom_start("Basic write/read test");
        // 写入一些数据
        repeat(8) begin
            @(posedge wclk);
            wr = 1;
            d = $random;
            @(posedge wclk);
            wr = 0;
        end
        // 读出数据
        repeat(8) begin
            @(posedge rclk);
            rd = 1;
            @(posedge rclk);
            rd = 0;
        end
        wavedrom_stop();

        // 写指针回环测试
        wavedrom_start("Write pointer wrap test");
        test_write_wrap();
        wavedrom_stop();

        // 读指针回环测试
        wavedrom_start("Read pointer wrap test");
        test_read_wrap();
        wavedrom_stop();

        // 满状态测试
        wavedrom_start("Full state test");
        rst = 0;
        repeat(`FIFO_TX_MEM_DEPTH + 4) begin
            @(posedge wclk);
            wr = 1;
            d = $random;
        end
        wr = 0;
        wavedrom_stop();

        // 空状态测试
        wavedrom_start("Empty state test");
        repeat(`FIFO_TX_MEM_DEPTH + 4) begin
            @(posedge rclk);
            rd = 1;
        end
        rd = 0;
        wavedrom_stop();

        // 交替读写测试
        wavedrom_start("Alternate read/write test");
        repeat(50) begin
            fork
                begin
                    @(posedge wclk);
                    wr = 1;
                    d = $random;
                    @(posedge wclk);
                    wr = 0;
                end
                begin
                    @(posedge rclk);
                    rd = 1;
                    @(posedge rclk);
                    rd = 0;
                end
            join
        end
        wavedrom_stop();

        // 随机测试
        wavedrom_start("Random operations test");
        repeat(1000) begin
            case ($random % 4)
                0: begin // 连续写
                    repeat(4) begin
                        @(posedge wclk);
                        wr = 1;
                        d = $random;
                        @(posedge wclk);
                        wr = 0;
                    end
                end
                
                1: begin // 连续读
                    repeat(4) begin
                        @(posedge rclk);
                        rd = 1;
                        @(posedge rclk);
                        rd = 0;
                    end
                end
                
                2: begin // 交替读写
                    @(posedge wclk);
                    wr = 1;
                    d = $random;
                    @(posedge wclk);
                    wr = 0;
                    @(posedge rclk);
                    rd = 1;
                    @(posedge rclk);
                    rd = 0;
                end
                
                3: begin // 复位
                    if ($random % 20 == 0) begin
                        rst = 1;
                        @(posedge wclk);
                        rst = 0;
                    end
                end
            endcase
        end
        wavedrom_stop();

        // 结束测试
        repeat(10) @(posedge wclk);
        rst = 1;
        {wr, rd} = 0;
        
        #500 $finish;
    end

endmodule

module PATTERN(clk, d, wr, wclk, rd, rclk, rst, q_dut, full_dut, empty_dut, mem_empt_dut);
    output logic clk;
    output logic [32-1:0] d;
    output logic wr;
    output logic wclk;
    output logic rd;
    output logic rclk;
    output logic rst;
    input  logic [32-1:0] q_dut;
    input  logic full_dut;
    input  logic empty_dut;
    input  logic [5:0] mem_empt_dut;

    typedef struct packed {
        int errors;
        int errortime;
        int errors_q;
        int errortime_q;
        int errors_full;
        int errortime_full;
        int errors_empty;
        int errortime_empty;
        int errors_mem_empt;
        int errortime_mem_empt;
        int clocks;
    } stats;

    stats stats1;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic [511:0] wavedrom_title;
    logic         wavedrom_enable;
    logic [32-1:0] q_ref;
    logic full_ref;
    logic empty_ref;
    logic [5:0] mem_empt_ref;
    wire tb_match_q = (q_ref === q_dut);
    wire tb_match_full = (full_ref === full_dut);
    wire tb_match_empty = (empty_ref === empty_dut);
    wire tb_match_mem_empt = (mem_empt_ref === mem_empt_dut);
    wire tb_match = tb_match_q & tb_match_full & tb_match_empty & tb_match_mem_empt;

    stimulus_gen stim1 (
		.wclk(wclk),
		.rclk(rclk),
		.tb_match(tb_match),
		.d(d),
		.wr(wr),
		.rd(rd),
		.rst(rst),
		.wavedrom_title(wavedrom_title),
		.wavedrom_enable(wavedrom_enable)
    );

    ref_sd_tx_fifo good1 (
		.d(d),
		.wr(wr),
		.wclk(wclk),
		.q(q_ref),
		.rd(rd),
		.full(full_ref),
		.empty(empty_ref),
		.mem_empt(mem_empt_ref),
		.rclk(rclk),
		.rst(rst)
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
        if (stats1.clocks > 1 && !tb_match_q) begin
            if (stats1.errors_q == 0) stats1.errortime_q = $time;
            stats1.errors_q++;
        end
        if (stats1.clocks > 1 && !tb_match_full) begin
            if (stats1.errors_full == 0) stats1.errortime_full = $time;
            stats1.errors_full++;
        end
        if (stats1.clocks > 1 && !tb_match_empty) begin
            if (stats1.errors_empty == 0) stats1.errortime_empty = $time;
            stats1.errors_empty++;
        end
        if (stats1.clocks > 1 && !tb_match_mem_empt) begin
            if (stats1.errors_mem_empt == 0) stats1.errortime_mem_empt = $time;
            stats1.errors_mem_empt++;
        end
    end

    final begin
        $display("\nTest Results:");
        if (stats1.errors_q)
            $display("Hint: Output q has %0d mismatches. First at time %0d",
                    stats1.errors_q, stats1.errortime_q);
        else
            $display("Hint: Output 'q' has no mismatches.");
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
        if (stats1.errors_mem_empt)
            $display("Hint: Output mem_empt has %0d mismatches. First at time %0d",
                    stats1.errors_mem_empt, stats1.errortime_mem_empt);
        else
            $display("Hint: Output 'mem_empt' has no mismatches.");
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
