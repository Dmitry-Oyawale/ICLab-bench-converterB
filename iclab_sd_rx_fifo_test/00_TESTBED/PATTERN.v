module ref_sd_rx_fifo
  (
   input [4-1:0] d,//4位宽的数据输入端口
   input wr,//写使能信号
   input wclk,//写时钟信号
   output [32-1:0] q,//32位宽的数据输出端口
   input rd,//读使能信号
   output full,//表示FIFO是否满
   output empty,//表示FIFO是否空
   output [1:0] mem_empt,//表示内存的剩余空间
   input rclk,//读时钟信号
   input rst
   );
   reg [32-1:0] ram [0:`FIFO_RX_MEM_DEPTH-1]; //synthesis syn_ramstyle = "no_rw_check
   //一个二维数组，表示FIFO存储空间
   reg [`FIFO_RX_MEM_ADR_SIZE-1:0] adr_i, adr_o;//写地址和读地址寄存器
   wire ram_we;//写使能信号
   wire [32-1:0] ram_din;//写入ram的数据
   reg [8-1:0] we;//8位的写使能信号，用于指示哪些字节可以写入
   reg [4*(8)-1:0] tmp;//临时存储的寄存器，32位
   reg ft;//表示是否已写入数据的标志位

   //写使能逻辑
   always @ (posedge wclk or posedge rst)
     if (rst)
       we <= 8'h1;//表示第一个字节可以写入
     else
       if (wr)
	 we <= {we[8-2:0],we[8-1]};//进行移位，使得下一位字节可以写入

   //数据写入逻辑
   always @ (posedge wclk or posedge rst)
     if (rst) begin
       tmp <= {4*(8-1){1'b0}};
         ft<=0; 
   end    
     else//根据大端或小端格式，将输入数据写入tmp
       begin
	 `ifdef BIG_ENDIAN
	   
     //ft 只在 (wr & we[7]) == 1 时设为 1，是为了确保只有在完整数据写入完成时，
     //标志位才会被更新，以此保证数据的一致性和完整性。
     //其他情况下（如 (wr & we[6])）并未写入整个数据块，因此不应设置为 1
	  if (wr & we[7]) begin
	    tmp[4*1-1:4*0] <= d;	 
	    ft<=1; end 
	  if (wr & we[6])
	    tmp[4*2-1:4*1] <= d; 
	  if (wr & we[5])
	    tmp[4*3-1:4*2] <= d;	  
	  if (wr & we[4])
	    tmp[4*4-1:4*3] <= d;	  
	  if (wr & we[3])
	    tmp[4*5-1:4*4] <= d;	  
	  if (wr & we[2])
	    tmp[4*6-1:4*5] <= d;	  
	  if (wr & we[1]) 
	    tmp[4*7-1:4*6] <= d;	 
 	  if (wr & we[0]) 
	    tmp[4*8-1:4*7] <= d;	 
	 `endif 
	 `ifdef LITTLE_ENDIAN 
	  if (wr & we[0])
	   tmp[4*1-1:4*0] <= d;	 
	  if (wr & we[1])
	    tmp[4*2-1:4*1] <= d;   
	  if (wr & we[2])
	    tmp[4*3-1:4*2] <= d;   
	  if (wr & we[3])
	   tmp[4*4-1:4*3] <= d;	     
	  if (wr & we[4])
	   tmp[4*5-1:4*4] <= d; 
	  if (wr & we[5])
	   tmp[4*6-1:4*5] <= d;	 
	  if (wr & we[6]) 
	   tmp[4*7-1:4*6] <= d;	  	  
	  if (wr & we[7]) begin
	   tmp[4*8-1:4*7] <= d;
	       ft<=1; 
     end
      `endif 
  end

    //ram写入操作 
   assign ram_we = wr & we[0] &ft;//表示在写使能、最小字节使能和数据标志均为真时有效
   assign ram_din = tmp;
   always @ (posedge wclk)
     if (ram_we)
       ram[adr_i[`FIFO_RX_MEM_ADR_SIZE-2:0]] <= ram_din;


  //写地址递增逻辑
   always @ (posedge wclk or posedge rst)
     if (rst)
       adr_i <= `FIFO_RX_MEM_ADR_SIZE'h0;
     else
       if (ram_we)
	 if (adr_i == `FIFO_RX_MEM_DEPTH-1) begin
	   adr_i[`FIFO_RX_MEM_ADR_SIZE-2:0] <=0;	   
	   adr_i[`FIFO_RX_MEM_ADR_SIZE-1]<=~adr_i[`FIFO_RX_MEM_ADR_SIZE-1];
	 end  
	 else
	   adr_i <= adr_i + `FIFO_RX_MEM_ADR_SIZE'h1;
	   

  //读地址逻辑
   always @ (posedge rclk or posedge rst)
     if (rst)
       adr_o <= `FIFO_RX_MEM_ADR_SIZE'h0;
     else
       if (!empty & rd)
	
	 if (adr_o == `FIFO_RX_MEM_DEPTH-1) begin
	    adr_o[`FIFO_RX_MEM_ADR_SIZE-2:0] <=0;
	    adr_o[`FIFO_RX_MEM_ADR_SIZE-1] <=~adr_o[`FIFO_RX_MEM_ADR_SIZE-1];
	 end  
	 else
	   adr_o <= adr_o + `FIFO_RX_MEM_ADR_SIZE'h1;
	 
//------------------------------------------------------------------
// Simplified version of the three necessary full-tests:
// assign wfull_val=((wgnext[ADDRSIZE] !=wq2_rptr[ADDRSIZE] ) &&
// (wgnext[ADDRSIZE-1] !=wq2_rptr[ADDRSIZE-1]) &&
// (wgnext[ADDRSIZE-2:0]==wq2_rptr[ADDRSIZE-2:0]));
//------------------------------------------------------------------
	//FIFO状态信号   
  //如果低位相同且高位不同，说明fifo已满
   assign full =  (adr_i[`FIFO_RX_MEM_ADR_SIZE-2:0] == adr_o[`FIFO_RX_MEM_ADR_SIZE-2:0] ) & (adr_i[`FIFO_RX_MEM_ADR_SIZE-1] ^ adr_o[`FIFO_RX_MEM_ADR_SIZE-1]) ;
   assign empty = (adr_i == adr_o) ;
   
   assign mem_empt = ( adr_i-adr_o);
   assign q = ram[adr_o[`FIFO_RX_MEM_ADR_SIZE-2:0]];
endmodule

module stimulus_gen (
    input wclk,
    input rclk,
    input tb_match,
    output reg [3:0] d,
    output reg wr,
    output reg rd,
    output reg rst,
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

    task reset_test(async=0);
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
    endtask

    // 新增：测试FIFO写满和地址回环
    task test_fifo_full_and_wrap;
        // 先清空FIFO
        rst = 1;
        @(posedge wclk);
        rst = 0;
        
        // 连续写入直到FIFO满
        repeat(64) begin  // 写入超过FIFO深度的数据
            @(posedge wclk);
            wr = 1;
            d = $random;
            @(posedge wclk);
        end
        wr = 0;
        
        // 等待一段时间
        repeat(4) @(posedge wclk);
        
        // 读出一些数据后继续写入，测试地址回环
        fork
            begin
                repeat(32) @(posedge rclk) begin
                    rd = 1;
                end
                @(posedge rclk) rd = 0;
            end
            begin
                repeat(8) @(posedge wclk);
                repeat(32) @(posedge wclk) begin
                    wr = 1;
                    d = $random;
                end
                @(posedge wclk) wr = 0;
            end
        join
    endtask

    // 新增：测试读地址回环
    task test_read_wrap;
        // 先填充数据
        rst = 1;
        @(posedge wclk);
        rst = 0;
        
        repeat(32) @(posedge wclk) begin
            wr = 1;
            d = $random;
        end
        @(posedge wclk) wr = 0;
        
        // 连续读出超过FIFO深度的数据
        repeat(64) @(posedge rclk) begin
            rd = 1;
        end
        @(posedge rclk) rd = 0;
    endtask

    initial begin
        // 初始化
        {rst, wr, rd, d} = 0;
        wavedrom_enable = 0;

        // 基本复位测试
        repeat(5) @(posedge wclk);
        wavedrom_start("Reset test");
        reset_test(1);
        wavedrom_stop();

        // 测试FIFO满状态和地址回环
        wavedrom_start("FIFO full and wrap test");
        repeat(4) begin  // 多次测试以确保覆盖
            test_fifo_full_and_wrap();
            // 间隔等待
            repeat(10) @(posedge wclk);
        end
        wavedrom_stop();

        // 测试读地址回环
        wavedrom_start("Read wrap test");
        repeat(4) begin
            test_read_wrap();
            // 间隔等待
            repeat(10) @(posedge wclk);
        end
        wavedrom_stop();

        // 随机测试，重点测试边界条件
        wavedrom_start("Random corner cases");
        repeat(2000) @(posedge wclk) begin
            case ($random % 4)
                0: begin // 写满测试
                    repeat(16) @(posedge wclk) begin
                        wr = 1;
                        d = $random;
                    end
                    @(posedge wclk) wr = 0;
                end
                
                1: begin // 读空测试
                    @(posedge rclk);
                    repeat(16) @(posedge rclk) begin
                        rd = 1;
                    end
                    @(posedge rclk) rd = 0;
                end
                
                2: begin // 交替读写
                    fork
                        begin
                            repeat(8) @(posedge wclk) begin
                                wr = 1;
                                d = $random;
                                @(posedge wclk);
                                wr = 0;
                                @(posedge wclk);
                            end
                        end
                        begin
                            repeat(8) @(posedge rclk) begin
                                rd = 1;
                                @(posedge rclk);
                                rd = 0;
                                @(posedge rclk);
                            end
                        end
                    join
                end
                
                3: begin // 快速切换读写
                    repeat(8) begin
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
                end
            endcase

            // 随机插入复位
            if ($random % 50 == 0) begin
                rst = 1;
                @(posedge wclk);
                rst = 0;
            end
        end
        wavedrom_stop();

        // 结束序列
        repeat(10) @(posedge wclk) begin
            rst = 1;
            {wr, rd} = 0;
        end

        #500 $finish;
    end

endmodule

module PATTERN(clk, d, wr, wclk, rd, rclk, rst, q_dut, full_dut, empty_dut, mem_empt_dut);
    output logic clk;
    output logic [4-1:0] d;
    output logic wr;
    output logic wclk;
    output logic rd;
    output logic rclk;
    output logic rst;
    input  logic [32-1:0] q_dut;
    input  logic full_dut;
    input  logic empty_dut;
    input  logic [1:0] mem_empt_dut;

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
    logic [1:0] mem_empt_ref;
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

    ref_sd_rx_fifo good1 (
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
