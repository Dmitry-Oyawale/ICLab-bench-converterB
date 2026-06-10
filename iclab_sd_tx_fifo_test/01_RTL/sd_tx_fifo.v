
`include "sd_defines.v"
module sd_tx_fifo
  (
   input [32-1:0] d,
   input wr,
   input wclk,
   output [32-1:0] q,
   input rd,
   output full,
   output empty,
   output [5:0] mem_empt,
   input rclk,
   input rst
   );
   
   reg [32-1:0] ram [0:`FIFO_TX_MEM_DEPTH-1]; //synthesis syn_ramstyle = "no_rw_check"
   reg [`FIFO_TX_MEM_ADR_SIZE-1:0] adr_i, adr_o;
   wire ram_we;
   wire [32-1:0] ram_din;
    

       
   assign ram_we = wr & ~full;
   assign ram_din = d;
   
   always @ (posedge wclk)
     if (ram_we)
       ram[adr_i[`FIFO_TX_MEM_ADR_SIZE-2:0]] <= ram_din;
   
   always @ (posedge wclk or posedge rst)
     if (rst)
       adr_i <= `FIFO_TX_MEM_ADR_SIZE'h0;
     else
       if (ram_we)
      	 if (adr_i == `FIFO_TX_MEM_DEPTH-1) begin
	        adr_i[`FIFO_TX_MEM_ADR_SIZE-2:0] <=0;	   
	        adr_i[`FIFO_TX_MEM_ADR_SIZE-1]<=~adr_i[`FIFO_TX_MEM_ADR_SIZE-1];
	    end  
	     else
	      adr_i <= adr_i + `FIFO_TX_MEM_ADR_SIZE'h1;
	   
	   
   always @ (posedge rclk or posedge rst)
     if (rst)
       adr_o <= `FIFO_TX_MEM_ADR_SIZE'h0;
     else
       if (!empty & rd) begin
	
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
	   
	   
   assign full=  ( adr_i[`FIFO_TX_MEM_ADR_SIZE-2:0] == adr_o[`FIFO_TX_MEM_ADR_SIZE-2:0] ) &  (adr_i[`FIFO_TX_MEM_ADR_SIZE-1] ^ adr_o[`FIFO_TX_MEM_ADR_SIZE-1]) ;
   assign empty = (adr_i == adr_o) ;
   
   assign mem_empt = ( adr_i-adr_o);
   assign q = ram[adr_o[`FIFO_TX_MEM_ADR_SIZE-2:0]];
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

