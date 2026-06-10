
`include "sd_defines.v"



module sd_bd (
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



`define BIG_ENDIAN
//`define LITLE_ENDIAN

`define SIM
//`define SYN

`define SDC_IRQ_ENABLE

`define ACTEL

//`define CUSTOM
//`define ALTERA
//`define XLINX
//`define SIMULATOR

`define RESEND_MAX_CNT 3

//MAX 255 BD
//BD size/4 

`ifdef ACTEL
	`define BD_WIDTH 5
	`define BD_SIZE 32      
	`define RAM_MEM_WIDTH_16
	`define RAM_MEM_WIDTH 16
  
`endif

//`ifdef CUSTOM
 //  `define NR_O_BD_4 
//   `define BD_WIDTH 5
//   `define BD_SIZE 32      
//   `define RAM_MEM_WIDTH_32
//   `define RAM_MEM_WIDTH 32
//`endif



`ifdef SYN
  `define RESET_CLK_DIV 0
  `define MEM_OFFSET 4
`endif

`ifdef SIM
  `define RESET_CLK_DIV 0
  `define MEM_OFFSET 4
`endif

//SD-Clock Defines ---------
//Use bus clock or a seperate clock
`define SDC_CLK_BUS_CLK
//`define SDC_CLK_SEP

// Use of internal clock divider
//`define SDC_CLK_STATIC
`define SDC_CLK_DYNAMIC


//SD DATA-transfer defines---
`define BLOCK_SIZE 512
`define SD_BUS_WIDTH_4
`define SD_BUS_W 4

//at 512 bytes per block, equal 1024 4 bytes writings with a bus width of 4, add 2 for startbit and Z bit.
//Add 18 for crc, endbit and z.
`define BIT_BLOCK 1044
`define CRC_OFF 19
`define BIT_BLOCK_REC 1024
`define BIT_CRC_CYCLE 16


//FIFO defines---------------
`define FIFO_RX_MEM_DEPTH 8
`define FIFO_RX_MEM_ADR_SIZE 4

`define FIFO_TX_MEM_DEPTH 8
`define FIFO_TX_MEM_ADR_SIZE 4
//---------------------------

