`include "sd_defines.v"

module sd_fifo_rx_filler
( 
    input clk,
    input rst,
    //WB Signals
    output  [31:0]  m_wb_adr_o,
    output  reg     m_wb_we_o,
    output reg [31:0] m_wb_dat_o,
    output reg      m_wb_cyc_o,
    output reg      m_wb_stb_o,
    input           m_wb_ack_i,
    output reg [2:0] m_wb_cti_o,
    output reg [1:0] m_wb_bte_o,

    //Data Master Control signals
    input en,
    input [31:0] adr,

    //Data Serial signals 
    input sd_clk,
    input [`SD_BUS_W-1:0] dat_i,
    input wr,
    output full,
    output empty
);

    // 内部信号定义与原模块相同
    wire [31:0] dat_o;
    reg rd;
    reg reset_rx_fifo;
    reg [8:0] offset;
    reg wb_free;

    // 实例化原始FIFO
    sd_rx_fifo Rx_Fifo (
        .d(dat_i),
        .wr(wr),
        .wclk(sd_clk),
        .q(dat_o),
        .rd(rd),
        .full(full),
        .empty(empty),
        .mem_empt(),
        .rclk(clk),
        .rst(rst | reset_rx_fifo)
    );

    // 地址计算逻辑
    assign m_wb_adr_o = adr + offset;

    // 主要状态机逻辑保持不变
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            offset <= 0;
            m_wb_we_o <= 0;
            m_wb_cyc_o <= 0;
            m_wb_stb_o <= 0;
            wb_free <= 1;
            m_wb_dat_o <= 0;
            rd <= 0;
            reset_rx_fifo <= 1;
            m_wb_bte_o <= 2'b00;
            m_wb_cti_o <= 3'b000;
        end
        else if (en) begin
            rd <= 0;
            reset_rx_fifo <= 0;
            
            if (!empty & wb_free) begin
                rd <= 1;
                m_wb_dat_o <= #1 dat_o;
                m_wb_we_o <= #1 1;
                m_wb_cyc_o <= #1 1;
                m_wb_stb_o <= #1 1; 
                wb_free <= 0;   
            end

            if (!wb_free & m_wb_ack_i) begin
                m_wb_we_o <= 0;
                m_wb_cyc_o <= 0;
                m_wb_stb_o <= 0;
                offset <= offset + `MEM_OFFSET;
                wb_free <= 1;
            end 
        end
        else begin
            reset_rx_fifo <= 1;
            rd <= 0;
            offset <= 0;
            m_wb_cyc_o <= 0;
            m_wb_stb_o <= 0; 
            m_wb_we_o <= 0; 
            wb_free <= 1;
        end
    end

    
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

