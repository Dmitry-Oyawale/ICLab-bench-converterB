module sd_fifo_tx_filler
( 
    input clk,
    input rst,
    //WB Signals
    output  [31:0]  m_wb_adr_o,
    output  reg     m_wb_we_o,
    input   [31:0]  m_wb_dat_i,
    output  reg     m_wb_cyc_o,
    output  reg     m_wb_stb_o,
    input          m_wb_ack_i,
    output  reg    [2:0] m_wb_cti_o,
    output  reg    [1:0] m_wb_bte_o,

    //Data Master Control signals
    input en,
    input [31:0] adr,

    //Data Serial signals 
    input sd_clk,
    output [31:0] dat_o,
    input rd,
    output empty,
    output fe
);

// 内部信号声明
reg reset_tx_fifo;
reg [31:0] din;
reg wr_tx;
reg [8:0] we;
reg [8:0] offset;
wire [5:0] mem_empt;
reg first;
reg ackd;
reg delay;

// 原始模块实例化
sd_tx_fifo Tx_Fifo (
    .d(din),
    .wr(wr_tx),
    .wclk(clk),
    .q(dat_o),
    .rd(rd),
    .full(fe),
    .empty(empty),
    .mem_empt(mem_empt),
    .rclk(sd_clk),
    .rst(rst | reset_tx_fifo)
);

// 地址计算
assign m_wb_adr_o = adr + offset;

// 主状态机逻辑
always @(posedge clk or posedge rst) begin
    if (rst) begin
        offset <= 0;
        we <= 8'h1;
        m_wb_we_o <= 0;
        m_wb_cyc_o <= 0;
        m_wb_stb_o <= 0;
        wr_tx <= 0;
        ackd <= 1;
        delay <= 0;
        reset_tx_fifo <= 1;
        first <= 1;
        din <= 0;
        m_wb_bte_o <= 2'b00;
        m_wb_cti_o <= 3'b000;
    end
    else if (en) begin
        reset_tx_fifo <= 0;
        
        if (m_wb_ack_i) begin
            wr_tx <= 1;
            din <= m_wb_dat_i;
            m_wb_cyc_o <= 0;
            m_wb_stb_o <= 0;
            delay <= ~delay;
        end
        else begin
            wr_tx <= 0;
        end
        
        if (delay) begin
            offset <= offset + `MEM_OFFSET;
            ackd <= ~ackd;
            delay <= ~delay;
            wr_tx <= 0;
        end
        
        if (!m_wb_ack_i && !fe && ackd) begin
            m_wb_we_o <= 0;
            m_wb_cyc_o <= 1;
            m_wb_stb_o <= 1;
            ackd <= 0;
        end
    end
    else begin
        offset <= 0;
        reset_tx_fifo <= 1;
        m_wb_cyc_o <= 0;
        m_wb_stb_o <= 0;
        m_wb_we_o <= 0;
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

