module ref_sd_data_serial_host(
input sd_clk,
input rst,
//Tx Fifo
input [31:0] data_in ,

output reg rd,
//Rx Fifo
output  reg  [`SD_BUS_W-1:0] data_out ,
output reg we,
//tristate data
output reg DAT_oe_o,
output reg[`SD_BUS_W-1:0] DAT_dat_o,
input  [`SD_BUS_W-1:0] DAT_dat_i,
//Controll signals
input [1:0] start_dat,
input ack_transfer,

output reg busy_n,
output reg transm_complete,
output reg crc_ok
);

//CRC16 
reg [`SD_BUS_W-1:0] crc_in;
reg crc_en;
reg crc_rst;
wire [15:0] crc_out [`SD_BUS_W-1:0];
reg  [`SD_BUS_W-1:0] temp_in;
  
reg [10:0] transf_cnt;
parameter SIZE = 6;
reg [SIZE-1:0] state;
reg [SIZE-1:0] next_state;
parameter IDLE        = 6'b000001;
parameter WRITE_DAT   = 6'b000010;
parameter WRITE_CRC   = 6'b000100;
parameter WRITE_BUSY  = 6'b001000;
parameter READ_WAIT   = 6'b010000;      
parameter READ_DAT    = 6'b100000;
reg [2:0] crc_status; 
reg busy_int;   

genvar i;
generate
for(i=0; i<`SD_BUS_W; i=i+1) begin:CRC_16_gen
  sd_crc_16 CRC_16_i (crc_in[i],crc_en, sd_clk, crc_rst, crc_out[i]);
end
endgenerate

reg ack_transfer_int;
reg ack_q;
always @ (posedge sd_clk or posedge rst   )
begin: ACK_SYNC
if (rst) begin
  ack_transfer_int <=0;
  ack_q<=0;end
else begin
  ack_q<=ack_transfer;
  ack_transfer_int<=ack_q;
  end
end

reg q_start_bit;
always @ (state or start_dat or q_start_bit or  transf_cnt or crc_status or busy_int or DAT_dat_i or ack_transfer_int)
begin : FSM_COMBO
 next_state  = 0;   
case(state)
  IDLE: begin
   if (start_dat == 2'b01) 
      next_state=WRITE_DAT;
    else if  (start_dat == 2'b10) 
      next_state=READ_WAIT;
    else 
      next_state=IDLE;
    end
  WRITE_DAT: begin
    if (transf_cnt >= `BIT_BLOCK) 
       next_state= WRITE_CRC;
   else if (start_dat == 2'b11)
        next_state=IDLE;
    else 
       next_state=WRITE_DAT;
  end

  WRITE_CRC: begin
    if (crc_status ==0) 
       next_state= WRITE_BUSY;
    else 
       next_state=WRITE_CRC;
    
  end
  WRITE_BUSY: begin
      if ( (busy_int ==1)  & ack_transfer_int)
       next_state= IDLE;
    else 
       next_state  = WRITE_BUSY;
  end
  
  READ_WAIT: begin
    if (q_start_bit== 0 ) 
       next_state= READ_DAT;
    else 
       next_state=READ_WAIT;
  end
  
  READ_DAT: begin
    if ( ack_transfer_int)  //Startbit consumed...
       next_state= IDLE;
    else if (start_dat == 2'b11)
        next_state=IDLE;   
    else 
       next_state=READ_DAT;
    end
    
    
    
 
  
 endcase
end 

always @ (posedge sd_clk or posedge rst   )
 begin :START_SYNC
  if (rst ) begin
    q_start_bit<=1;
 end 
 else begin
    if (!DAT_dat_i[0] & state == READ_WAIT)
    q_start_bit <= 0;
    else
    q_start_bit <= 1;
    
 end
end


//----------------Seq logic------------
always @ (posedge sd_clk or posedge rst   )
begin : FSM_SEQ
  if (rst ) begin
    state <= #1 IDLE;
 end 
 else begin
    state <= #1 next_state;
 end
end

reg [4:0] crc_c;
reg [3:0] last_din;
reg [2:0] crc_s ;
reg [31:0] write_buf_0,write_buf_1, sd_data_out;
reg out_buff_ptr,in_buff_ptr;
reg [2:0] data_send_index;
         
always @ (negedge sd_clk or posedge rst   )
begin  : FSM_OUT
 if (rst) begin
write_buf_0<=0;
write_buf_1<=0;
   DAT_oe_o<=0;
   crc_en<=0;
   crc_rst<=1;
   transf_cnt<=0;
   crc_c<=15;
   rd<=0;
   last_din<=0;
   crc_c<=0;
   crc_in<=0;
   DAT_dat_o<=0;
   crc_status<=7;
   crc_s<=0;
   transm_complete<=0;
   busy_n<=1;
   we<=0;
   data_out<=0;
   crc_ok<=0;
   busy_int<=0;
     data_send_index<=0;
        out_buff_ptr<=0;
        in_buff_ptr<=0;
 end
 else begin
 case(state)
   IDLE: begin
      DAT_oe_o<=0;
      DAT_dat_o<=4'b1111;
      crc_en<=0;
      crc_rst<=1;
      transf_cnt<=0;
      crc_c<=16;
      crc_status<=7;
      crc_s<=0;
      we<=0;
      rd<=0;
      busy_n<=1;
        data_send_index<=0;
        out_buff_ptr<=0;
        in_buff_ptr<=0;
     
   end
   WRITE_DAT: begin    
      transm_complete <=0;  
      busy_n<=0;
      crc_ok<=0;
      transf_cnt<=transf_cnt+1; 
       rd<=0; 
       
      
        
      if ( (in_buff_ptr != out_buff_ptr) ||  (!transf_cnt) ) begin
        rd <=1;           
       if (!in_buff_ptr)
         write_buf_0<=data_in;         
       else
        write_buf_1 <=data_in;    
        
       in_buff_ptr<=in_buff_ptr+1;
     end
     
      if (!out_buff_ptr)
        sd_data_out<=write_buf_0;
      else
       sd_data_out<=write_buf_1;
        
        if (transf_cnt==1) begin
          
          crc_rst<=0;
          crc_en<=1;
          `ifdef LITLE_ENDIAN 
          	last_din <=write_buf_0[3:0]; 
          	crc_in<= write_buf_0[3:0]; 
          `endif
          `ifdef BIG_ENDIAN 
          	last_din <=write_buf_0[31:28]; 
          	crc_in<= write_buf_0[31:28]; 
          `endif
          
          DAT_oe_o<=1;  
          DAT_dat_o<=0;
          
          data_send_index<=1;    
        end
        else if ( (transf_cnt>=2) && (transf_cnt<=`BIT_BLOCK-`CRC_OFF )) begin                 
          DAT_oe_o<=1;    
        case (data_send_index) 
          `ifdef LITLE_ENDIAN 
           0:begin 
              last_din <=sd_data_out[3:0];
              crc_in <=sd_data_out[3:0];
           end
           1:begin 
              last_din <=sd_data_out[7:4];
              crc_in <=sd_data_out[7:4];
           end
           2:begin 
              last_din <=sd_data_out[11:8];
              crc_in <=sd_data_out[11:8];
           end
           3:begin 
              last_din <=sd_data_out[15:12];
              crc_in <=sd_data_out[15:12];
           end
           4:begin 
              last_din <=sd_data_out[19:16];
              crc_in <=sd_data_out[19:16];
           end
           5:begin 
              last_din <=sd_data_out[23:20];
              crc_in <=sd_data_out[23:20];
           end
           6:begin 
              last_din <=sd_data_out[27:24];
              crc_in <=sd_data_out[27:24];
              out_buff_ptr<=out_buff_ptr+1;
           end
           7:begin 
              last_din <=sd_data_out[31:28];
              crc_in <=sd_data_out[31:28];              
           end
          `endif  
          `ifdef BIG_ENDIAN 
           0:begin 
              last_din <=sd_data_out[31:28];
              crc_in <=sd_data_out[31:28];
           end
           1:begin 
              last_din <=sd_data_out[27:24];
              crc_in <=sd_data_out[27:24];
           end
           2:begin 
              last_din <=sd_data_out[23:20];
              crc_in <=sd_data_out[23:20];
           end
           3:begin 
              last_din <=sd_data_out[19:16];
              crc_in <=sd_data_out[19:16];
           end
           4:begin 
              last_din <=sd_data_out[15:12];
              crc_in <=sd_data_out[15:12];
           end
           5:begin 
              last_din <=sd_data_out[11:8];
              crc_in <=sd_data_out[11:8];
           end
           6:begin 
              last_din <=sd_data_out[7:4];
              crc_in <=sd_data_out[7:4];
              out_buff_ptr<=out_buff_ptr+1;
           end
           7:begin 
              last_din <=sd_data_out[3:0];
              crc_in <=sd_data_out[3:0];              
           end
          `endif  
          
           
         endcase 
          data_send_index<=data_send_index+1;
                   
          DAT_dat_o<= last_din; 
          
            
                    
          if ( transf_cnt >=`BIT_BLOCK-`CRC_OFF ) begin
             crc_en<=0;             
         end
       end
       else if (transf_cnt>`BIT_BLOCK-`CRC_OFF & crc_c!=0) begin
        rd<=0;
         crc_en<=0;
         crc_c<=crc_c-1;      
         DAT_oe_o<=1; 
         DAT_dat_o[0]<=crc_out[0][crc_c-1];
         DAT_dat_o[1]<=crc_out[1][crc_c-1];
         DAT_dat_o[2]<=crc_out[2][crc_c-1];
         DAT_dat_o[3]<=crc_out[3][crc_c-1];         
       end
       else if (transf_cnt==`BIT_BLOCK-2) begin
          DAT_oe_o<=1; 
          DAT_dat_o<=4'b1111;
           rd<=0;
      end   
       else if (transf_cnt !=0) begin
         DAT_oe_o<=0; 
         rd<=0;
         end
   end
   WRITE_CRC : begin
      rd<=0;
      DAT_oe_o<=0; 
      crc_status<=crc_status-1;
      if  (( crc_status<=4) && ( crc_status>=2) )
      crc_s[crc_status-2] <=DAT_dat_i[0];    
   end
   WRITE_BUSY : begin
      transm_complete <=1;
      if(crc_s == 3'b010) 
         crc_ok<=1;     
      else 
         crc_ok<=0;  
            
      busy_int<=DAT_dat_i[0];
      
   end
   READ_WAIT:begin
      DAT_oe_o<=0;
      crc_rst<=0;
      crc_en<=1;
      crc_in<=0; 
      crc_c<=15;// end 
      busy_n<=0;
      transm_complete<=0; 
   end
   
   READ_DAT: begin
     
       
     if (transf_cnt<`BIT_BLOCK_REC) begin
       we<=1;
     
       data_out<=DAT_dat_i;
       crc_in<=DAT_dat_i;
       crc_ok<=1;
       transf_cnt<=transf_cnt+1; 
              
     end  
     else if  ( transf_cnt <= (`BIT_BLOCK_REC +`BIT_CRC_CYCLE)) begin
       transf_cnt<=transf_cnt+1; 
       crc_en<=0;  
       last_din <=DAT_dat_i; 
       
       if (transf_cnt> `BIT_BLOCK_REC) begin       
        crc_c<=crc_c-1;
          we<=0;
        `ifdef SD_BUS_WIDTH_1
         if  (crc_out[0][crc_status] == last_din[0])
           crc_ok<=0;
        `endif
        
       `ifdef SD_BUS_WIDTH_4
          if  (crc_out[0][crc_c] != last_din[0])
           crc_ok<=0;
          if  (crc_out[1][crc_c] != last_din[1])
           crc_ok<=0;
          if  (crc_out[2][crc_c] != last_din[2])
           crc_ok<=0;
          if  (crc_out[3][crc_c] != last_din[3])
           crc_ok<=0;  
         
        `endif   
         `ifdef SIM
          crc_ok<=1;
       `endif
         if (crc_c==0) begin
          transm_complete <=1;
          busy_n<=0;
           we<=0;
         end
      end
    end  
    
      
        
  end
   
   
  
 endcase 
 
 end

end 
   








//Sync





  
  
endmodule

`include "sd_defines.v"

module stimulus_gen (
	input sd_clk,
	output logic rst,
	output [31:0] data_in ,
	output [`SD_BUS_W-1:0] DAT_dat_i,
	output [1:0] start_dat,
	output logic ack_transfer,

	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	tb_match
);
	reg reset;
	assign rst = reset;


	task reset_test(input async = 0);
		bit arfail, srfail, datafail;
	
		@(posedge sd_clk);
		@(posedge sd_clk) reset = 0;
		repeat(3) @(posedge sd_clk);
	
		@(negedge sd_clk) begin datafail = !tb_match ; reset = 1; end
		@(posedge sd_clk) arfail = !tb_match;
		@(posedge sd_clk) begin
			srfail = !tb_match;
			reset = 0;
		end
		if (srfail)
			$display("Hint: Your reset doesn't seem to be working.");
		else if (arfail && (async || !datafail))
			$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
		// Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
		// a functionality error than the reset being implemented asynchronously.
	
	endtask

	task wavedrom_start(input[511:0] title = "");
	endtask

	task wavedrom_stop;
		#1;
	endtask	


	initial begin
		repeat(3)@(posedge sd_clk) reset = 0;
		repeat(3)@(posedge sd_clk) reset = 1;
		reset = 0;
		data_in = 0;
		DAT_dat_i = 0;
		start_dat = 0;
		ack_transfer = 0;

		repeat(3)@(posedge sd_clk) reset = 0;

		wavedrom_start("Asynchronous reset");
		reset_test(1);
		wavedrom_stop();

		// IDLE -> WRITE_DAT -> WRITE_CRC -> WRITE_BUSY -> IDLE
		@(posedge sd_clk) data_in = 31'h1010;
			start_dat = 2'b01;
			ack_transfer = 1;

		repeat(1000) @(posedge sd_clk);
		repeat(1000) @(posedge sd_clk) DAT_dat_i[0] = ~DAT_dat_i[0];
		repeat(10) @(posedge sd_clk) reset = 1;
		repeat(10) @(posedge sd_clk) reset = 0;

		// IDLE -> WRITE_DAT -> WRITE_CRC -> WRITE_BUSY -> IDLE
		@(posedge sd_clk) data_in = 31'h1010;
			start_dat = 2'b01;
			ack_transfer = 1;

		repeat(2000) @(posedge sd_clk);
		repeat(10) @(posedge sd_clk) reset = 1;
		repeat(10) @(posedge sd_clk) reset = 0;
		
		// IDLE -> READ_WAIT -> READ_DAT -> IDLE
		@(posedge sd_clk) data_in = 31'h1010;
			start_dat = 2'b10;
			ack_transfer = 1;
			DAT_dat_i[0] = 0;
		repeat(10) @(posedge sd_clk);
		repeat(10) @(posedge sd_clk) reset = 1;
		repeat(10) @(posedge sd_clk) reset = 0;

		// IDLE -> READ_WAIT -> READ_DAT -> IDLE
		@(posedge sd_clk) data_in = 31'h1010;
			start_dat = 2'b10;
			ack_transfer = 0;
			DAT_dat_i = 0;
		repeat(1000) @(posedge sd_clk);
		repeat(500)@(posedge sd_clk) DAT_dat_i = DAT_dat_i + 1;
		repeat(10) @(posedge sd_clk) start_dat = 2'b11;
		repeat(10) @(posedge sd_clk) reset = 1;
		repeat(10) @(posedge sd_clk) reset = 0;

		// IDLE -> WRITE_DAT -> IDLE
		@(posedge sd_clk) data_in = 31'h1010;
			start_dat = 2'b01;
			ack_transfer = 1;

		repeat(1000) @(posedge sd_clk);
		repeat(10) @(posedge sd_clk) start_dat = 2'b11;
		repeat(10) @(posedge sd_clk) reset = 1;
		repeat(10) @(posedge sd_clk) reset = 0;

		//random
		repeat(2000) @(posedge sd_clk, negedge sd_clk) begin
			ack_transfer = ($random%2);

            data_in = $random;
            DAT_dat_i = $random;
            start_dat = $random;
			reset = !($random & 31);
		end
		#1
		$finish;
	end
	
endmodule

module PATTERN(clk, sd_clk, rst, data_in, DAT_dat_i, start_dat, ack_transfer, rd_dut, data_out_dut, we_dut, DAT_oe_o_dut, reg_dut, busy_n_dut, transm_complete_dut, crc_ok_dut);
    output logic clk;
    output logic sd_clk;
    output logic rst;
    output logic [31:0] data_in;
    output logic [`SD_BUS_W-1:0] DAT_dat_i;
    output logic [1:0] start_dat;
    output logic ack_transfer;
    input  logic rd_dut;
    input  logic [`SD_BUS_W-1:0] data_out_dut;
    input  logic we_dut;
    input  logic DAT_oe_o_dut;
    input  logic reg_dut;
    input  logic busy_n_dut;
    input  logic transm_complete_dut;
    input  logic crc_ok_dut;

    typedef struct packed {
        int errors;
        int errortime;
        int errors_rd;
        int errortime_rd;
        int errors_data_out;
        int errortime_data_out;
        int errors_we;
        int errortime_we;
        int errors_DAT_oe_o;
        int errortime_DAT_oe_o;
        int errors_reg;
        int errortime_reg;
        int errors_busy_n;
        int errortime_busy_n;
        int errors_transm_complete;
        int errortime_transm_complete;
        int errors_crc_ok;
        int errortime_crc_ok;
        int clocks;
    } stats;

    stats stats1;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic [511:0] wavedrom_title;
    logic         wavedrom_enable;
    logic rd_ref;
    logic [`SD_BUS_W-1:0] data_out_ref;
    logic we_ref;
    logic DAT_oe_o_ref;
    logic reg_ref;
    logic busy_n_ref;
    logic transm_complete_ref;
    logic crc_ok_ref;
    wire tb_match_rd = (rd_ref === rd_dut);
    wire tb_match_data_out = (data_out_ref === data_out_dut);
    wire tb_match_we = (we_ref === we_dut);
    wire tb_match_DAT_oe_o = (DAT_oe_o_ref === DAT_oe_o_dut);
    wire tb_match_reg = (reg_ref === reg_dut);
    wire tb_match_busy_n = (busy_n_ref === busy_n_dut);
    wire tb_match_transm_complete = (transm_complete_ref === transm_complete_dut);
    wire tb_match_crc_ok = (crc_ok_ref === crc_ok_dut);
    wire tb_match = tb_match_rd & tb_match_data_out & tb_match_we & tb_match_DAT_oe_o & tb_match_reg & tb_match_busy_n & tb_match_transm_complete & tb_match_crc_ok;

    stimulus_gen stim1 (
		.sd_clk(sd_clk),
		.rst(rst),
		.data_in(data_in),
		.DAT_dat_i(DAT_dat_i),
		.start_dat(start_dat),
		.ack_transfer(ack_transfer),
		.reg(reg),
		.wavedrom_enable(wavedrom_enable)
    );

    ref_sd_data_serial_host good1 (
		.sd_clk(sd_clk),
		.rst(rst),
		.data_in(data_in),
		.rd(rd_ref),
		.data_out(data_out_ref),
		.we(we_ref),
		.DAT_oe_o(DAT_oe_o_ref),
		.reg(reg_ref),
		.DAT_dat_i(DAT_dat_i),
		.start_dat(start_dat),
		.ack_transfer(ack_transfer),
		.busy_n(busy_n_ref),
		.transm_complete(transm_complete_ref),
		.crc_ok(crc_ok_ref)
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
        if (stats1.clocks > 1 && !tb_match_rd) begin
            if (stats1.errors_rd == 0) stats1.errortime_rd = $time;
            stats1.errors_rd++;
        end
        if (stats1.clocks > 1 && !tb_match_data_out) begin
            if (stats1.errors_data_out == 0) stats1.errortime_data_out = $time;
            stats1.errors_data_out++;
        end
        if (stats1.clocks > 1 && !tb_match_we) begin
            if (stats1.errors_we == 0) stats1.errortime_we = $time;
            stats1.errors_we++;
        end
        if (stats1.clocks > 1 && !tb_match_DAT_oe_o) begin
            if (stats1.errors_DAT_oe_o == 0) stats1.errortime_DAT_oe_o = $time;
            stats1.errors_DAT_oe_o++;
        end
        if (stats1.clocks > 1 && !tb_match_reg) begin
            if (stats1.errors_reg == 0) stats1.errortime_reg = $time;
            stats1.errors_reg++;
        end
        if (stats1.clocks > 1 && !tb_match_busy_n) begin
            if (stats1.errors_busy_n == 0) stats1.errortime_busy_n = $time;
            stats1.errors_busy_n++;
        end
        if (stats1.clocks > 1 && !tb_match_transm_complete) begin
            if (stats1.errors_transm_complete == 0) stats1.errortime_transm_complete = $time;
            stats1.errors_transm_complete++;
        end
        if (stats1.clocks > 1 && !tb_match_crc_ok) begin
            if (stats1.errors_crc_ok == 0) stats1.errortime_crc_ok = $time;
            stats1.errors_crc_ok++;
        end
    end

    final begin
        $display("\nTest Results:");
        if (stats1.errors_rd)
            $display("Hint: Output rd has %0d mismatches. First at time %0d",
                    stats1.errors_rd, stats1.errortime_rd);
        else
            $display("Hint: Output 'rd' has no mismatches.");
        if (stats1.errors_data_out)
            $display("Hint: Output data_out has %0d mismatches. First at time %0d",
                    stats1.errors_data_out, stats1.errortime_data_out);
        else
            $display("Hint: Output 'data_out' has no mismatches.");
        if (stats1.errors_we)
            $display("Hint: Output we has %0d mismatches. First at time %0d",
                    stats1.errors_we, stats1.errortime_we);
        else
            $display("Hint: Output 'we' has no mismatches.");
        if (stats1.errors_DAT_oe_o)
            $display("Hint: Output DAT_oe_o has %0d mismatches. First at time %0d",
                    stats1.errors_DAT_oe_o, stats1.errortime_DAT_oe_o);
        else
            $display("Hint: Output 'DAT_oe_o' has no mismatches.");
        if (stats1.errors_reg)
            $display("Hint: Output reg has %0d mismatches. First at time %0d",
                    stats1.errors_reg, stats1.errortime_reg);
        else
            $display("Hint: Output 'reg' has no mismatches.");
        if (stats1.errors_busy_n)
            $display("Hint: Output busy_n has %0d mismatches. First at time %0d",
                    stats1.errors_busy_n, stats1.errortime_busy_n);
        else
            $display("Hint: Output 'busy_n' has no mismatches.");
        if (stats1.errors_transm_complete)
            $display("Hint: Output transm_complete has %0d mismatches. First at time %0d",
                    stats1.errors_transm_complete, stats1.errortime_transm_complete);
        else
            $display("Hint: Output 'transm_complete' has no mismatches.");
        if (stats1.errors_crc_ok)
            $display("Hint: Output crc_ok has %0d mismatches. First at time %0d",
                    stats1.errors_crc_ok, stats1.errortime_crc_ok);
        else
            $display("Hint: Output 'crc_ok' has no mismatches.");
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
