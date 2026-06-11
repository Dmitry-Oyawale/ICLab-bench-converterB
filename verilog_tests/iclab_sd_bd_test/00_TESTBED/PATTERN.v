
`include "sd_defines.v"



module ref_sd_bd (
input clk,
input rst,
//input stb_m,
input we_m,

input [`RAM_MEM_WIDTH-1:0] dat_in_m, 

output reg [`BD_WIDTH-1 :0] free_bd,

input  re_s,
output reg ack_o_s,
input a_cmp,
output reg[`RAM_MEM_WIDTH-1:0] dat_out_s
);
 
 reg new_bw;
reg last_a_cmp;
 
`ifdef RAM_MEM_WIDTH_32   
`ifdef ACTEL
reg [`RAM_MEM_WIDTH -1:0] bd_mem [ `BD_SIZE -1 :0]; /* synthesis syn_ramstyle = "no_rw_check"*/
`else
reg [`RAM_MEM_WIDTH -1:0] bd_mem [ `BD_SIZE -1 :0];
`endif 

reg write_cnt; 
reg read_cnt;
reg [`BD_WIDTH -1 :0] m_wr_pnt;

reg [`BD_WIDTH -1 :0] s_rd_pnt ;
 
 //Main side read/write  
always @(posedge clk or posedge rst )
begin
   new_bw <=0;  
  
  if (rst) begin
    m_wr_pnt<=0;
    
    write_cnt<=0;
    new_bw <=0; 

   
  end
  else if (we_m) begin    
    if (free_bd >0) begin
      write_cnt <=~ write_cnt;
      m_wr_pnt<=m_wr_pnt+1;
      if (!write_cnt) begin  //First write indicate source buffer addr
        bd_mem[m_wr_pnt]<=dat_in_m;            
      end
      else begin        //Second write indicate SD card block addr
        bd_mem[m_wr_pnt]<=dat_in_m;
        new_bw <=1;     
      end
     end
  end   
  
        
          
        
end  



always @ (posedge clk or posedge rst)
begin
  if (rst) begin  
    free_bd <=(`BD_SIZE  /2);
  end
  else if (new_bw ) begin
    free_bd <= free_bd-1;
  end  
  else if  (a_cmp) begin
     free_bd <= free_bd+1;
    
  end
  
end


//Second side read
always @(posedge clk or posedge rst)
begin
   
  if (rst) begin
    s_rd_pnt<=0;
	
  end
  else if (re_s) begin    
    s_rd_pnt<=s_rd_pnt+1;
    dat_out_s<= bd_mem[s_rd_pnt];            
  
   
  end  
end

`else `ifdef RAM_MEM_WIDTH_16   
`ifdef ACTEL
reg [ `RAM_MEM_WIDTH -1:0] bd_mem [ `BD_SIZE -1 :0];  //synthesis syn_ramstyle = "no_rw_check"
`else
reg [ `RAM_MEM_WIDTH -1:0] bd_mem [ `BD_SIZE -1 :0];
`endif 

reg [1:0]write_cnt; 
reg [1:0]read_s_cnt;
reg read_cnt;

reg [`BD_WIDTH -1 :0] m_wr_pnt;

reg [`BD_WIDTH -1 :0] s_rd_pnt ;
 
 //Main side read/write  
always @(posedge clk or posedge rst )
begin
   new_bw <=0;  
  
  if (rst) begin
    m_wr_pnt<=0;
    
    write_cnt<=0;
    new_bw <=0; 
    read_cnt<=0;
   
  end
  else if (we_m) begin    
    if (free_bd >0) begin
      write_cnt <=write_cnt+1;
      m_wr_pnt<=m_wr_pnt+1;
      if (!write_cnt[1]) begin      //First write indicate source buffer addr (2x16)
        bd_mem[m_wr_pnt]<=dat_in_m;             
      end
      else begin        //Second write indicate SD card block addr (2x16)
        bd_mem[m_wr_pnt]<=dat_in_m;
        new_bw <=write_cnt[0];      //Second 16 bytes writen, complete BD
      end
     end
  end   
   
    

end

always @(posedge clk or posedge rst)
begin
  if (rst) begin  
    free_bd <=(`BD_SIZE  /4);
    last_a_cmp<=0;
  end
  else if (new_bw ) begin
    free_bd <= free_bd-1;
  end  
  else if  (a_cmp) begin
    last_a_cmp <=a_cmp;
    if (!last_a_cmp)
     free_bd <= free_bd+1;
     
  end
 else
  last_a_cmp <=a_cmp;
end


//Second side read
always @(posedge clk or posedge rst)
begin
   
  if (rst) begin
    s_rd_pnt<=0;
	  read_s_cnt<=0;
	  ack_o_s<=0;
  end
  else if (re_s) begin
    read_s_cnt <=read_s_cnt+1;
    s_rd_pnt<=s_rd_pnt+1;
    ack_o_s<=1;
     if (!read_s_cnt[1])       //First read indicate source buffer addr (2x16)
        dat_out_s<= bd_mem[s_rd_pnt];           
      
      else         //Second read indicate SD card block addr (2x16)
        dat_out_s<= bd_mem[s_rd_pnt];
      
  end  
  else
    ack_o_s<=0;
end

 `endif

`endif


endmodule

module stimulus_gen (
    input clk,
    input tb_match,
    output reg rst,
    output reg we_m,
    output reg [`RAM_MEM_WIDTH-1:0] dat_in_m,
    output reg re_s,
    output reg a_cmp,
    output reg [511:0] wavedrom_title,
    output reg wavedrom_enable
);

    // 保持原有的任务
    task wavedrom_start(input[511:0] title = "");
        wavedrom_title = title;
        wavedrom_enable = 1;
    endtask

    task wavedrom_stop;
        wavedrom_enable = 0;
    endtask

    // 保持原有的reset_test
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
        {rst, we_m, re_s, a_cmp, dat_in_m} = 0;
        wavedrom_enable = 0;

        // 1. 复位测试
        repeat(5) @(posedge clk);
        wavedrom_start("Reset test");
        reset_test(1);
        
        // 复位后立即读写操作
        @(posedge clk);
        re_s = 1;
        @(posedge clk);
        re_s = 0;
        @(posedge clk);
        we_m = 1;
        dat_in_m = $random;
        @(posedge clk);
        we_m = 0;
        wavedrom_stop();

        // 2. 交替读写测试
        wavedrom_start("Write-Read test");
        repeat(32) begin
            // 先写入
            repeat(2) begin
                we_m = 1;
                dat_in_m = $random;
                repeat(2) @(posedge clk);
                we_m = 0;
                @(posedge clk);
            end
            
            // 然后读出
            repeat(2) begin
                re_s = 1;
                repeat(2) @(posedge clk);
                re_s = 0;
                @(posedge clk);
            end

            // 发送完成信号
            if($random % 2) begin
                a_cmp = 1;
                @(posedge clk);
                a_cmp = 0;
                repeat(2) @(posedge clk);
            end
        end
        wavedrom_stop();

        // 3. 边界测试
        wavedrom_start("Edge test");
        repeat(20) begin
            // 连续写入
            repeat(8) begin
                we_m = 1;
                dat_in_m = $random;
                @(posedge clk);
                we_m = 0;
                @(posedge clk);
            end
            
            // 连续读出
            repeat(8) begin
                re_s = 1;
                @(posedge clk);
                re_s = 0;
                @(posedge clk);
            end
            
            // 多个完成信号
            repeat(4) begin
                a_cmp = 1;
                @(posedge clk);
                a_cmp = 0;
                @(posedge clk);
            end
            
            // 复位测试
            reset_test(1);
        end
        wavedrom_stop();

        // 4. 随机测试
        repeat(1000) @(posedge clk) begin
            // 随机生成操作组合
            if($random % 2) we_m = 1;
            else we_m = 0;
            
            if($random % 2) re_s = 1;
            else re_s = 0;
            
            if($random % 2) a_cmp = 1;
            else a_cmp = 0;
            
            dat_in_m = $random;
            
            // 每隔一段时间插入复位
            if($random % 50 == 0) begin
                reset_test(1);
            end
            
            // 随机延迟
            repeat($random % 3) @(posedge clk);
        end

        // 5. 快速切换测试
        wavedrom_start("Fast switch test");
        repeat(50) begin
            we_m = 1;
            re_s = 1;
            dat_in_m = $random;
            @(posedge clk);
            we_m = 0;
            re_s = 0;
            @(posedge clk);
            a_cmp = 1;
            @(posedge clk);
            a_cmp = 0;
            @(posedge clk);
        end
        wavedrom_stop();

        // 最终清理
        repeat(10) @(posedge clk);
        reset_test(1);

        #100 $finish;
    end

endmodule

module PATTERN(clk, rst, stb_m, we_m, dat_in_m, re_s, a_cmp, free_bd_dut, ack_o_s_dut, reg_dut);
    output logic clk;
    output logic rst;
    output logic stb_m;
    output logic we_m;
    output logic [`RAM_MEM_WIDTH-1:0] dat_in_m;
    output logic re_s;
    output logic a_cmp;
    input  logic [`BD_WIDTH-1 :0] free_bd_dut;
    input  logic ack_o_s_dut;
    input  logic reg_dut;

    typedef struct packed {
        int errors;
        int errortime;
        int errors_free_bd;
        int errortime_free_bd;
        int errors_ack_o_s;
        int errortime_ack_o_s;
        int errors_reg;
        int errortime_reg;
        int clocks;
    } stats;

    stats stats1;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic [511:0] wavedrom_title;
    logic         wavedrom_enable;
    logic [`BD_WIDTH-1 :0] free_bd_ref;
    logic ack_o_s_ref;
    logic reg_ref;
    wire tb_match_free_bd = (free_bd_ref === free_bd_dut);
    wire tb_match_ack_o_s = (ack_o_s_ref === ack_o_s_dut);
    wire tb_match_reg = (reg_ref === reg_dut);
    wire tb_match = tb_match_free_bd & tb_match_ack_o_s & tb_match_reg;

    stimulus_gen stim1 (
		.clk(clk),
		.tb_match(tb_match),
		.rst(rst),
		.we_m(we_m),
		.dat_in_m(dat_in_m),
		.re_s(re_s),
		.a_cmp(a_cmp),
		.wavedrom_title(wavedrom_title),
		.wavedrom_enable(wavedrom_enable)
    );

    ref_sd_bd good1 (
		.clk(clk),
		.rst(rst),
		.stb_m(stb_m),
		.we_m(we_m),
		.dat_in_m(dat_in_m),
		.free_bd(free_bd_ref),
		.re_s(re_s),
		.ack_o_s(ack_o_s_ref),
		.a_cmp(a_cmp),
		.reg(reg_ref)
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
        if (stats1.clocks > 1 && !tb_match_free_bd) begin
            if (stats1.errors_free_bd == 0) stats1.errortime_free_bd = $time;
            stats1.errors_free_bd++;
        end
        if (stats1.clocks > 1 && !tb_match_ack_o_s) begin
            if (stats1.errors_ack_o_s == 0) stats1.errortime_ack_o_s = $time;
            stats1.errors_ack_o_s++;
        end
        if (stats1.clocks > 1 && !tb_match_reg) begin
            if (stats1.errors_reg == 0) stats1.errortime_reg = $time;
            stats1.errors_reg++;
        end
    end

    final begin
        $display("\nTest Results:");
        if (stats1.errors_free_bd)
            $display("Hint: Output free_bd has %0d mismatches. First at time %0d",
                    stats1.errors_free_bd, stats1.errortime_free_bd);
        else
            $display("Hint: Output 'free_bd' has no mismatches.");
        if (stats1.errors_ack_o_s)
            $display("Hint: Output ack_o_s has %0d mismatches. First at time %0d",
                    stats1.errors_ack_o_s, stats1.errortime_ack_o_s);
        else
            $display("Hint: Output 'ack_o_s' has no mismatches.");
        if (stats1.errors_reg)
            $display("Hint: Output reg has %0d mismatches. First at time %0d",
                    stats1.errors_reg, stats1.errortime_reg);
        else
            $display("Hint: Output 'reg' has no mismatches.");
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
