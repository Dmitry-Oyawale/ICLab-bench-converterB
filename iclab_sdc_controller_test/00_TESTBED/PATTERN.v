module ref_sdc_controller(
  
  // WISHBONE common
  wb_clk_i, wb_rst_i, wb_dat_i, wb_dat_o, 

  // WISHBONE slave
  wb_adr_i, wb_sel_i, wb_we_i, wb_cyc_i, wb_stb_i, wb_ack_o, 

  // WISHBONE master
  m_wb_adr_o, m_wb_sel_o, m_wb_we_o, 
  m_wb_dat_o, m_wb_dat_i, m_wb_cyc_o, 
  m_wb_stb_o, m_wb_ack_i, 
  m_wb_cti_o, m_wb_bte_o,
  //SD BUS
  
  sd_cmd_dat_i,sd_cmd_out_o,  sd_cmd_oe_o, card_detect,
  sd_dat_dat_i, sd_dat_out_o , sd_dat_oe_o, sd_clk_o_pad
  `ifdef SDC_CLK_SEP
   ,sd_clk_i_pad
  `endif
  `ifdef SDC_IRQ_ENABLE
   ,int_a, int_b, int_c  
  `endif
);



// WISHBONE common
input           wb_clk_i;     // WISHBONE clock
input           wb_rst_i;     // WISHBONE reset
input   [31:0]  wb_dat_i;     // WISHBONE data input
output  [31:0]  wb_dat_o;     // WISHBONE data output
     // WISHBONE error output
input 			card_detect;
// WISHBONE slave
input   [7:0]  wb_adr_i;     // WISHBONE address input
input   [3:0]  wb_sel_i;     // WISHBONE byte select input
input          wb_we_i;      // WISHBONE write enable input
input          wb_cyc_i;     // WISHBONE cycle input
input          wb_stb_i;     // WISHBONE strobe input

output          wb_ack_o;     // WISHBONE acknowledge output

// WISHBONE master
output  [31:0]  m_wb_adr_o;
output  [3:0]   m_wb_sel_o;
output          m_wb_we_o;

input   [31:0]  m_wb_dat_i;
output  [31:0]  m_wb_dat_o;
output          m_wb_cyc_o;
output          m_wb_stb_o;
input           m_wb_ack_i;
output  [2:0]   m_wb_cti_o;
output	[1:0]	m_wb_bte_o;
//SD port

input  wire [3:0] sd_dat_dat_i;   //Data in from SDcard
output wire [3:0] sd_dat_out_o; //Data out to SDcard
output wire sd_dat_oe_o; //SD Card tristate Data Output enable (Connects on the SoC TopLevel)

input  wire sd_cmd_dat_i; //Command in from SDcard
output wire sd_cmd_out_o; //Command out to SDcard
output wire sd_cmd_oe_o; //SD Card tristate CMD Output enable (Connects on the SoC TopLevel)
output sd_clk_o_pad;
  `ifdef SDC_CLK_SEP
   input wire sd_clk_i_pad;
  `endif
//IRQ
`ifdef SDC_IRQ_ENABLE
   output int_a, int_b, int_c ; 
  `endif
  

// signal definition completion
wire new_cmd;
wire d_write;
wire d_read;
wire error_isr_reset;
wire normal_isr_reset;
wire go_idle;
wire req_out_master;
wire ack_out_master;
wire req_in_host;
wire ack_in_host;
wire rd;
wire we_rx;
wire start_tx_fifo;
wire start_rx_fifo;
wire tx_e;
wire tx_f;
wire full_rx;
wire busy_n;
wire trans_complete;
wire crc_ok;
wire ack_transfer;
wire ack_o_s_tx;
wire ack_o_s_rx;
wire cidat_w;
wire cmd_int_busy;
wire Bd_isr_reset;
wire we_m_tx_bd;
wire we_m_rx_bd;
wire we_ack;
wire int_ack;
wire m_wb_we_o_tx;
wire m_wb_cyc_o_tx;
wire m_wb_stb_o_tx;
wire m_wb_cti_o_tx;
wire m_wb_bte_o_tx;
wire m_wb_we_o_rx;
wire m_wb_cyc_o_rx;
wire m_wb_stb_o_rx;
wire m_wb_cti_o_rx;
wire m_wb_bte_o_rx;
wire m_wb_bte;
wire int_busy;



//Wires from SD_CMD_MASTER Module 
wire [15:0] status_reg_w;
wire [31:0] cmd_resp_1_w;
wire [15:0]normal_int_status_reg_w;
wire [4:0]error_int_status_reg_w; 
 

wire[31:0]  argument_reg;
wire[15:0]  cmd_setting_reg;
reg[15:0]   status_reg;
reg[31:0]   cmd_resp_1;
wire[7:0]   software_reset_reg; 
wire[15:0]  time_out_reg;   
reg[15:0]   normal_int_status_reg; 
reg[15:0]   error_int_status_reg;
wire[15:0]  normal_int_signal_enable_reg;
wire[15:0]  error_int_signal_enable_reg;
wire[7:0]   clock_divider;
reg[15:0]   Bd_Status_reg;   
reg[7:0]    Bd_isr_reg;
wire[7:0]   Bd_isr_enable_reg;

 
//Rx Buffer  Descriptor internal signals



wire [`BD_WIDTH-1 :0] free_bd_rx_bd; //NO free Rx_bd
wire new_rx_bd;  // New Bd writen
wire [`RAM_MEM_WIDTH-1:0] dat_out_s_rx_bd; //Data out from Rx_bd to Slave

//Tx Buffer Descriptor internal signals
wire [`RAM_MEM_WIDTH-1:0] dat_in_m_rx_bd; //Data in to Rx_bd from Master
wire [`RAM_MEM_WIDTH-1:0] dat_in_m_tx_bd;
wire [`BD_WIDTH-1 :0] free_bd_tx_bd;
wire new_tx_bd;
wire [`RAM_MEM_WIDTH-1:0] dat_out_s_tx_bd;
wire [7:0] bd_int_st_w; //Wire to BD status register

//Wires for connecting Bd registers with the SD_Data_master module
wire re_s_tx_bd_w;
wire a_cmp_tx_bd_w;
wire re_s_rx_bd_w;
wire a_cmp_rx_bd_w;
wire write_req_s; //SD_Data_master want acces to the CMD line.
wire cmd_busy; //CMD line busy no access granted

wire [31:0] cmd_arg_s; //SD_Data_master CMD Argument
wire [15:0] cmd_set_s; //SD_Data_master Settings Argument
wire [31:0] sys_adr; //System addres the DMA whil Read/Write to/from
wire [1:0]start_dat_t; //Start data transfer

//Signals to Syncronize busy signaling betwen Wishbone access and SD_Data_master access to the CMD line (Also manage the status reg uppdate)

assign cmd_busy = int_busy | status_reg[0];
wire status_reg_busy;


//Wires from SD_DATA_SERIAL_HOST_1 to the FIFO
wire [`SD_BUS_W -1 : 0 ]data_in_rx_fifo;
wire [31: 0 ] data_fout_tx_fifo;
wire [31:0] m_wb_dat_o_rx;
wire [3:0] m_wb_sel_o_tx;
wire [31:0] m_wb_adr_o_tx;
wire [31:0] m_wb_adr_o_rx;

//SD clock 
wire sd_clk_i; //Sd_clk provided to the system
wire sd_clk_o; //Sd_clk used in the system 


//sd_clk_o to be used i set here
`ifdef SDC_CLK_BUS_CLK
  assign sd_clk_i = wb_clk_i;
`endif 
`ifdef SDC_CLK_SEP
   assign sd_clk_i = sd_clk_i_pad;
  `endif

`ifdef SDC_CLK_STATIC
   assign sd_clk_o = sd_clk_i;
`endif
   
`ifdef SDC_CLK_DYNAMIC
  sd_clock_divider clock_divider_1 (
 .CLK (sd_clk_i),
 .DIVIDER (clock_divider),
 .RST  (wb_rst_i | software_reset_reg[0]),
 .SD_CLK  (sd_clk_o)  
);
`endif
assign sd_clk_o_pad  = sd_clk_o ;

wire [15:0] settings;
wire [7:0] serial_status;
wire [39:0] cmd_out_master;
wire [39:0] cmd_in_host;

sd_cmd_master cmd_master_1
(
    .CLK_PAD_IO     (wb_clk_i),
    .RST_PAD_I      (wb_rst_i | software_reset_reg[0]),
    .New_CMD        (new_cmd),
    .data_write     (d_write),
    .data_read      (d_read),
    .ARG_REG        (argument_reg),
    .CMD_SET_REG    (cmd_setting_reg[13:0]),
    .STATUS_REG     (status_reg_w),
    .TIMEOUT_REG    (time_out_reg),
    .RESP_1_REG     (cmd_resp_1_w),
    .ERR_INT_REG    (error_int_status_reg_w),
    .NORMAL_INT_REG (normal_int_status_reg_w),
    .ERR_INT_RST    (error_isr_reset),
    .NORMAL_INT_RST (normal_isr_reset),
    .settings       (settings),
    .go_idle_o      (go_idle),
    .cmd_out        (cmd_out_master ),
    .req_out        (req_out_master ),
    .ack_out        (ack_out_master ),
    .req_in         (req_in_host),
    .ack_in         (ack_in_host),
    .cmd_in         (cmd_in_host),
    .serial_status (serial_status),
    .card_detect (card_detect)

);


sd_cmd_serial_host cmd_serial_host_1(
    .SD_CLK_IN  (sd_clk_o), 
    .RST_IN     (wb_rst_i | software_reset_reg[0] | go_idle),
    .SETTING_IN (settings),
    .CMD_IN     (cmd_out_master),
    .REQ_IN     (req_out_master),
    .ACK_IN     (ack_out_master),
    .REQ_OUT    (req_in_host), 
    .ACK_OUT    (ack_in_host),
    .CMD_OUT    (cmd_in_host),
    .STATUS     (serial_status),
    .cmd_dat_i  (sd_cmd_dat_i),
    .cmd_out_o  (sd_cmd_out_o),
    .cmd_oe_o   ( sd_cmd_oe_o),
    .st_dat_t   (start_dat_t)
);


sd_data_master data_master_1 
(
    .clk            (wb_clk_i),
    .rst            (wb_rst_i | software_reset_reg[0]),
    .dat_in_tx      (dat_out_s_tx_bd),
    .free_tx_bd     (free_bd_tx_bd),
    .ack_i_s_tx     (ack_o_s_tx ),
    .re_s_tx        (re_s_tx_bd_w), 
    .a_cmp_tx       (a_cmp_tx_bd_w),
    .dat_in_rx      (dat_out_s_rx_bd),
    .free_rx_bd     (free_bd_rx_bd),
    .ack_i_s_rx     (ack_o_s_rx),
    .re_s_rx        (re_s_rx_bd_w), 
    .a_cmp_rx       (a_cmp_rx_bd_w),
    .cmd_busy       (cmd_busy),
    .we_req         (write_req_s),
    .we_ack         (we_ack),
    .d_write        (d_write),
    .d_read         (d_read),
    .cmd_arg        (cmd_arg_s),
    .cmd_set        (cmd_set_s),
    .cmd_tsf_err    (normal_int_status_reg[15]) ,
    .card_status    (cmd_resp_1[12:8])   ,
    .start_tx_fifo  (start_tx_fifo),
    .start_rx_fifo  (start_rx_fifo),
    .sys_adr        (sys_adr),
    .tx_empt        (tx_e ),
    .tx_full        (tx_f ),
    .rx_full        (full_rx ),
    .busy_n         (busy_n),
    .transm_complete(trans_complete ),
    .crc_ok         (crc_ok),
    .ack_transfer   (ack_transfer),
    .Dat_Int_Status (bd_int_st_w),
    .Dat_Int_Status_rst (Bd_isr_reset),
    .CIDAT           (cidat_w),
	.transfer_type  (cmd_setting_reg[15:14])
);
 
wire [31:0] data_out_tx_fifo;
sd_data_serial_host sd_data_serial_host_1(
    .sd_clk         (sd_clk_o),
    .rst            (wb_rst_i | software_reset_reg[0]),
    .data_in        (data_out_tx_fifo),
    .rd             (rd), 
    .data_out       (data_in_rx_fifo),
    .we             (we_rx),
    .DAT_oe_o       (sd_dat_oe_o),
    .DAT_dat_o      (sd_dat_out_o),
    .DAT_dat_i      (sd_dat_dat_i),
    .start_dat      (start_dat_t),
    .ack_transfer   (ack_transfer),
    .busy_n         (busy_n),
    .transm_complete(trans_complete ),
    .crc_ok         (crc_ok)
);


sd_bd rx_bd
(
    .clk        (wb_clk_i),
    .rst       (wb_rst_i | software_reset_reg[0]),
    .we_m      (we_m_rx_bd),
    .dat_in_m  (dat_in_m_rx_bd),
    .free_bd   (free_bd_rx_bd),
    .re_s      (re_s_rx_bd_w),
    .ack_o_s   (ack_o_s_rx),
    .a_cmp     (a_cmp_rx_bd_w),
    .dat_out_s (dat_out_s_rx_bd)

);

sd_bd tx_bd
(
    .clk       (wb_clk_i),
    .rst       (wb_rst_i | software_reset_reg[0]),
    .we_m      (we_m_tx_bd),
    .dat_in_m  (dat_in_m_tx_bd),
    .free_bd   (free_bd_tx_bd),
    .ack_o_s   (ack_o_s_tx),
    .re_s      (re_s_tx_bd_w),
    .a_cmp     (a_cmp_tx_bd_w),
    .dat_out_s (dat_out_s_tx_bd)
);


sd_fifo_tx_filler fifo_filer_tx (
    .clk        (wb_clk_i),
    .rst        (wb_rst_i | software_reset_reg[0]),
    .m_wb_adr_o (m_wb_adr_o_tx),
    .m_wb_we_o  (m_wb_we_o_tx),
    .m_wb_dat_i (m_wb_dat_i),
    .m_wb_cyc_o (m_wb_cyc_o_tx),
    .m_wb_stb_o (m_wb_stb_o_tx),
    .m_wb_ack_i (m_wb_ack_i),
    .m_wb_cti_o (m_wb_cti_o_tx),
	.m_wb_bte_o (m_wb_bte_o_tx),
    .en         (start_tx_fifo),
    .adr        (sys_adr),
    .sd_clk     (sd_clk_o),
    .dat_o      (data_out_tx_fifo   ),
    .rd         (rd),
    .empty      (tx_e),
    .fe         (tx_f)
);

sd_fifo_rx_filler fifo_filer_rx (
    .clk        (wb_clk_i),
    .rst        (wb_rst_i | software_reset_reg[0]),
    .m_wb_adr_o (m_wb_adr_o_rx),
    .m_wb_we_o  (m_wb_we_o_rx),
    .m_wb_dat_o (m_wb_dat_o),
    .m_wb_cyc_o (m_wb_cyc_o_rx),
    .m_wb_stb_o (m_wb_stb_o_rx),
    .m_wb_ack_i (m_wb_ack_i),
    .m_wb_cti_o (m_wb_cti_o_rx),
	.m_wb_bte_o (m_wb_bte_o_rx),
    .en         (start_rx_fifo),
    .adr        (sys_adr),
    .sd_clk     (sd_clk_o),
    .dat_i      (data_in_rx_fifo   ),
    .wr         (we_rx),
    .full       (full_rx)
);

sd_controller_wb sd_controller_wb0
	(
	 .wb_clk_i          (wb_clk_i),
	 .wb_rst_i          (wb_rst_i),
	 .wb_dat_i          (wb_dat_i),
	 .wb_dat_o          (wb_dat_o),
	 .wb_adr_i          (wb_adr_i[7:0]),
	 .wb_sel_i          (wb_sel_i),
	 .wb_we_i           (wb_we_i),
	 .wb_stb_i          (wb_stb_i),
	 .wb_cyc_i          (wb_cyc_i),
	 .wb_ack_o          (wb_ack_o),
   	 .we_m_tx_bd        (we_m_tx_bd),
     .new_cmd           (new_cmd), 
     .we_m_rx_bd        (we_m_rx_bd),   
    .we_ack             (we_ack),
    .int_ack            (int_ack),
    .cmd_int_busy       (cmd_int_busy),
    .Bd_isr_reset       (Bd_isr_reset),     
    .normal_isr_reset   (normal_isr_reset),
    .error_isr_reset    (error_isr_reset),
    .int_busy           (int_busy),
    .dat_in_m_tx_bd     (dat_in_m_tx_bd),
    .dat_in_m_rx_bd     (dat_in_m_rx_bd),
    .write_req_s        (write_req_s),
    .cmd_set_s          (cmd_set_s),
    .cmd_arg_s          (cmd_arg_s),
    .argument_reg       (argument_reg),
    .cmd_setting_reg    (cmd_setting_reg),
    .status_reg         (status_reg),
    .cmd_resp_1         (cmd_resp_1),
    .software_reset_reg (software_reset_reg ),
    .time_out_reg       (time_out_reg ),
    .normal_int_status_reg  (normal_int_status_reg),
    .error_int_status_reg   (error_int_status_reg ),
    .normal_int_signal_enable_reg   (normal_int_signal_enable_reg),
    .error_int_signal_enable_reg    (error_int_signal_enable_reg),
    .clock_divider                  (clock_divider ),
    .Bd_Status_reg                  (Bd_Status_reg),
    .Bd_isr_reg                     (Bd_isr_reg ),
    .Bd_isr_enable_reg              (Bd_isr_enable_reg)
	 );





//MUX For WB master acces granted to RX or TX FIFO filler
assign m_wb_cyc_o = start_tx_fifo ? m_wb_cyc_o_tx :start_rx_fifo ?m_wb_cyc_o_rx: 0;
assign m_wb_stb_o = start_tx_fifo ? m_wb_stb_o_tx :start_rx_fifo ?m_wb_stb_o_rx: 0;

assign m_wb_cti_o = start_tx_fifo ? m_wb_cti_o_tx :start_rx_fifo ?m_wb_cti_o_rx: 0;
assign m_wb_bte = start_tx_fifo ? m_wb_bte_o_tx :start_rx_fifo ?m_wb_bte_o_rx: 0;
//assign m_wb_dat_o = m_wb_dat_o_rx;
assign m_wb_we_o = start_tx_fifo ? m_wb_we_o_tx :start_rx_fifo ?m_wb_we_o_rx: 0;
assign m_wb_adr_o = start_tx_fifo ? m_wb_adr_o_tx :start_rx_fifo ?m_wb_adr_o_rx: 0;

`ifdef SDC_IRQ_ENABLE
assign int_a =  |(normal_int_status_reg &  normal_int_signal_enable_reg) ;
assign int_b =  |(error_int_status_reg & error_int_signal_enable_reg);
assign int_c =  |(Bd_isr_reg & Bd_isr_enable_reg);
`endif

assign m_wb_sel_o = 4'b1111;

//Set Bd_Status_reg
always @ (posedge wb_clk_i ) begin
  Bd_Status_reg[15:8]=free_bd_rx_bd;
  Bd_Status_reg[7:0]=free_bd_tx_bd;
  cmd_resp_1<= cmd_resp_1_w;
  normal_int_status_reg<= normal_int_status_reg_w  ;
  error_int_status_reg<= error_int_status_reg_w  ;
  status_reg[0]<= status_reg_busy;
  status_reg[15:1]<=  status_reg_w[15:1]; 
  status_reg[1] <= cidat_w; 
  Bd_isr_reg<=bd_int_st_w;

end


 
//cmd_int_busy is set when an internal access to the CMD buss is granted then immidetly uppdate the status busy bit to prevent buss access to cmd
assign status_reg_busy = cmd_int_busy ? 1'b1: status_reg_w[0];





endmodule

`include "sd_defines.v"
module stimulus_gen (
    input wire clk,
    // WISHBONE common
    output   logic        wb_clk_i,     // WISHBONE clock
    output   logic        wb_rst_i,     // WISHBONE reset
    output   logic   [31:0]  wb_dat_i,     // WISHBONE data input
    // WISHBONE error output
    output   logic       card_detect,
    // WISHBONE slave
    output   logic   [7:0]  wb_adr_i,     // WISHBONE address input
    output   logic   [3:0]  wb_sel_i,     // WISHBONE byte select input
    output   logic       wb_we_i,      // WISHBONE write enable input
    output   logic       wb_cyc_i,     // WISHBONE cycle input
    output   logic       wb_stb_i,     // WISHBONE strobe input

    // WISHBONE master
    output   logic   [31:0]  m_wb_dat_i,
    output   logic        m_wb_ack_i,

    // SD port
    output  logic [3:0] sd_dat_dat_i,   // Data in from SD card
    output  logic sd_cmd_dat_i         // Command in from SD card
    `ifdef SDC_CLK_SEP
        ,output logic sd_clk_i_pad
    `endif
);

// register adress
`define argument 8'h00
`define command 8'h04
`define status 8'h08
`define resp1 8'h0c
`define controller 8'h1c
`define block 8'h20
`define power 8'h24
`define software 8'h28
`define timeout 8'h2c  
`define normal_isr 8'h30   
`define error_isr 8'h34  
`define normal_iser 8'h38
`define error_iser 8'h3c
`define capa 8'h48
`define clock_d 8'h4c
`define bd_status 8'h50
`define bd_isr 8'h54 
`define bd_iser 8'h58 
`define bd_rx 8'h60  
`define bd_tx 8'h80  

// Clock period definition for the simulation
localparam CLK_PERIOD = 10; // 10 time units for the clock period

assign wb_clk_i = clk;

// Stimulus generation
initial begin

    // reset
    wb_rst_i = 1'b1;
    #(CLK_PERIOD*3);   
    wb_rst_i = 1'b0;
    #(CLK_PERIOD*3);          
    
    // select 
    wb_stb_i = 1'b1;
    wb_cyc_i = 1'b1;
    wb_sel_i = 4'b1000; // non-sense

    // wishbone slave
    repeat (20) @(negedge wb_clk_i) begin
        // change wb_adr_i
        wb_we_i = 1'b1;
        wb_dat_i = $random;
        wb_adr_i = `argument;
        #(CLK_PERIOD);
        wb_adr_i = `command;
        #(CLK_PERIOD);
        wb_adr_i = `software;
        #(CLK_PERIOD);
        wb_adr_i = `timeout;
        #(CLK_PERIOD);
        wb_adr_i = `normal_iser;
        #(CLK_PERIOD);
        wb_adr_i = `error_iser;
        #(CLK_PERIOD);
        wb_adr_i = `normal_isr;
        #(CLK_PERIOD);
        wb_adr_i = `error_isr;
        #(CLK_PERIOD);
        wb_adr_i = `clock_d;
        #(CLK_PERIOD);
        wb_adr_i = `bd_isr;
        #(CLK_PERIOD);
        wb_adr_i = `bd_iser;
        #(CLK_PERIOD);

        // bd_rx,bd_tx
        wb_adr_i = `bd_rx;
        #(CLK_PERIOD*4);
        wb_adr_i = `bd_tx;
        #(CLK_PERIOD*4);
        
        // output
        wb_cyc_i = 1'b1;
        wb_adr_i = `status;
        #(CLK_PERIOD);
        wb_adr_i = `resp1;
        #(CLK_PERIOD);
        wb_adr_i = `controller;
        #(CLK_PERIOD);
        wb_adr_i = `block;
        #(CLK_PERIOD);
        wb_adr_i = `power;
        #(CLK_PERIOD);
        wb_adr_i = `capa;
        #(CLK_PERIOD);
        wb_adr_i = `bd_status;
        #(CLK_PERIOD);
    end

    // wishbone master
    repeat (20) @(negedge wb_clk_i) begin
        m_wb_dat_i = $random;
        m_wb_ack_i = 1'b1;
        #(CLK_PERIOD*10); 
        m_wb_ack_i = 1'b0;
        #(CLK_PERIOD*10); 
    end
    
    repeat (1000) @(negedge wb_clk_i) begin
        sd_dat_dat_i = $random;
        sd_cmd_dat_i = $random;
        #(CLK_PERIOD*10); 
    end

    // Finish the simulation
    $finish;
end

endmodule

module PATTERN(clk, wb_clk_i, wb_rst_i, wb_dat_i, card_detect, wb_adr_i, wb_sel_i, wb_we_i, wb_cyc_i, wb_stb_i, m_wb_dat_i, m_wb_ack_i, sd_dat_dat_i, sd_cmd_dat_i, sd_clk_i_pad, wb_dat_o_dut, wb_ack_o_dut, m_wb_adr_o_dut, m_wb_sel_o_dut, m_wb_we_o_dut, m_wb_dat_o_dut, m_wb_cyc_o_dut, m_wb_stb_o_dut, m_wb_cti_o_dut, m_wb_bte_o_dut, sd_dat_out_o_dut, sd_dat_oe_o_dut, sd_cmd_out_o_dut, sd_cmd_oe_o_dut, sd_clk_o_pad_dut, int_a_dut, int_b_dut, int_c_dut);
    output logic clk;
    output logic wb_clk_i;
    output logic wb_rst_i;
    output logic [31:0] wb_dat_i;
    output logic card_detect;
    output logic [7:0] wb_adr_i;
    output logic [3:0] wb_sel_i;
    output logic wb_we_i;
    output logic wb_cyc_i;
    output logic wb_stb_i;
    output logic [31:0] m_wb_dat_i;
    output logic m_wb_ack_i;
    output logic [3:0] sd_dat_dat_i;
    output logic sd_cmd_dat_i;
    output logic sd_clk_i_pad;
    input  logic [31:0] wb_dat_o_dut;
    input  logic wb_ack_o_dut;
    input  logic [31:0] m_wb_adr_o_dut;
    input  logic [3:0] m_wb_sel_o_dut;
    input  logic m_wb_we_o_dut;
    input  logic [31:0] m_wb_dat_o_dut;
    input  logic m_wb_cyc_o_dut;
    input  logic m_wb_stb_o_dut;
    input  logic [2:0] m_wb_cti_o_dut;
    input  logic [1:0] m_wb_bte_o_dut;
    input  logic [3:0] sd_dat_out_o_dut;
    input  logic sd_dat_oe_o_dut;
    input  logic sd_cmd_out_o_dut;
    input  logic sd_cmd_oe_o_dut;
    input  logic sd_clk_o_pad_dut;
    input  logic int_a_dut;
    input  logic int_b_dut;
    input  logic int_c_dut;

    typedef struct packed {
        int errors;
        int errortime;
        int errors_wb_dat_o;
        int errortime_wb_dat_o;
        int errors_wb_ack_o;
        int errortime_wb_ack_o;
        int errors_m_wb_adr_o;
        int errortime_m_wb_adr_o;
        int errors_m_wb_sel_o;
        int errortime_m_wb_sel_o;
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
        int errors_sd_dat_out_o;
        int errortime_sd_dat_out_o;
        int errors_sd_dat_oe_o;
        int errortime_sd_dat_oe_o;
        int errors_sd_cmd_out_o;
        int errortime_sd_cmd_out_o;
        int errors_sd_cmd_oe_o;
        int errortime_sd_cmd_oe_o;
        int errors_sd_clk_o_pad;
        int errortime_sd_clk_o_pad;
        int errors_int_a;
        int errortime_int_a;
        int errors_int_b;
        int errortime_int_b;
        int errors_int_c;
        int errortime_int_c;
        int clocks;
    } stats;

    stats stats1;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic [511:0] wavedrom_title;
    logic         wavedrom_enable;
    logic [31:0] wb_dat_o_ref;
    logic wb_ack_o_ref;
    logic [31:0] m_wb_adr_o_ref;
    logic [3:0] m_wb_sel_o_ref;
    logic m_wb_we_o_ref;
    logic [31:0] m_wb_dat_o_ref;
    logic m_wb_cyc_o_ref;
    logic m_wb_stb_o_ref;
    logic [2:0] m_wb_cti_o_ref;
    logic [1:0] m_wb_bte_o_ref;
    logic [3:0] sd_dat_out_o_ref;
    logic sd_dat_oe_o_ref;
    logic sd_cmd_out_o_ref;
    logic sd_cmd_oe_o_ref;
    logic sd_clk_o_pad_ref;
    logic int_a_ref;
    logic int_b_ref;
    logic int_c_ref;
    wire tb_match_wb_dat_o = (wb_dat_o_ref === wb_dat_o_dut);
    wire tb_match_wb_ack_o = (wb_ack_o_ref === wb_ack_o_dut);
    wire tb_match_m_wb_adr_o = (m_wb_adr_o_ref === m_wb_adr_o_dut);
    wire tb_match_m_wb_sel_o = (m_wb_sel_o_ref === m_wb_sel_o_dut);
    wire tb_match_m_wb_we_o = (m_wb_we_o_ref === m_wb_we_o_dut);
    wire tb_match_m_wb_dat_o = (m_wb_dat_o_ref === m_wb_dat_o_dut);
    wire tb_match_m_wb_cyc_o = (m_wb_cyc_o_ref === m_wb_cyc_o_dut);
    wire tb_match_m_wb_stb_o = (m_wb_stb_o_ref === m_wb_stb_o_dut);
    wire tb_match_m_wb_cti_o = (m_wb_cti_o_ref === m_wb_cti_o_dut);
    wire tb_match_m_wb_bte_o = (m_wb_bte_o_ref === m_wb_bte_o_dut);
    wire tb_match_sd_dat_out_o = (sd_dat_out_o_ref === sd_dat_out_o_dut);
    wire tb_match_sd_dat_oe_o = (sd_dat_oe_o_ref === sd_dat_oe_o_dut);
    wire tb_match_sd_cmd_out_o = (sd_cmd_out_o_ref === sd_cmd_out_o_dut);
    wire tb_match_sd_cmd_oe_o = (sd_cmd_oe_o_ref === sd_cmd_oe_o_dut);
    wire tb_match_sd_clk_o_pad = (sd_clk_o_pad_ref === sd_clk_o_pad_dut);
    wire tb_match_int_a = (int_a_ref === int_a_dut);
    wire tb_match_int_b = (int_b_ref === int_b_dut);
    wire tb_match_int_c = (int_c_ref === int_c_dut);
    wire tb_match = tb_match_wb_dat_o & tb_match_wb_ack_o & tb_match_m_wb_adr_o & tb_match_m_wb_sel_o & tb_match_m_wb_we_o & tb_match_m_wb_dat_o & tb_match_m_wb_cyc_o & tb_match_m_wb_stb_o & tb_match_m_wb_cti_o & tb_match_m_wb_bte_o & tb_match_sd_dat_out_o & tb_match_sd_dat_oe_o & tb_match_sd_cmd_out_o & tb_match_sd_cmd_oe_o & tb_match_sd_clk_o_pad & tb_match_int_a & tb_match_int_b & tb_match_int_c;

    stimulus_gen stim1 (
		.clk(clk),
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_dat_i(wb_dat_i),
		.output(output),
		.wb_adr_i(wb_adr_i),
		.output(output),
		.output(output),
		.output(output),
		.output(output),
		.m_wb_dat_i(m_wb_dat_i),
		.m_wb_ack_i(m_wb_ack_i),
		.sd_dat_dat_i(sd_dat_dat_i),
		.sd_cmd_dat_i(sd_cmd_dat_i),
		.sd_clk_i_pad(sd_clk_i_pad)
    );

    ref_sdc_controller good1 (
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_dat_i(wb_dat_i),
		.wb_dat_o(wb_dat_o_ref),
		.card_detect(card_detect),
		.wb_adr_i(wb_adr_i),
		.wb_sel_i(wb_sel_i),
		.wb_we_i(wb_we_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_stb_i(wb_stb_i),
		.wb_ack_o(wb_ack_o_ref),
		.m_wb_adr_o(m_wb_adr_o_ref),
		.m_wb_sel_o(m_wb_sel_o_ref),
		.m_wb_we_o(m_wb_we_o_ref),
		.m_wb_dat_i(m_wb_dat_i),
		.m_wb_dat_o(m_wb_dat_o_ref),
		.m_wb_cyc_o(m_wb_cyc_o_ref),
		.m_wb_stb_o(m_wb_stb_o_ref),
		.m_wb_ack_i(m_wb_ack_i),
		.m_wb_cti_o(m_wb_cti_o_ref),
		.m_wb_bte_o(m_wb_bte_o_ref),
		.sd_dat_dat_i(sd_dat_dat_i),
		.sd_dat_out_o(sd_dat_out_o_ref),
		.sd_dat_oe_o(sd_dat_oe_o_ref),
		.sd_cmd_dat_i(sd_cmd_dat_i),
		.sd_cmd_out_o(sd_cmd_out_o_ref),
		.sd_cmd_oe_o(sd_cmd_oe_o_ref),
		.sd_clk_o_pad(sd_clk_o_pad_ref),
		.sd_clk_i_pad(sd_clk_i_pad),
		.int_a(int_a_ref),
		.int_b(int_b_ref),
		.int_c(int_c_ref)
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
        if (stats1.clocks > 1 && !tb_match_wb_dat_o) begin
            if (stats1.errors_wb_dat_o == 0) stats1.errortime_wb_dat_o = $time;
            stats1.errors_wb_dat_o++;
        end
        if (stats1.clocks > 1 && !tb_match_wb_ack_o) begin
            if (stats1.errors_wb_ack_o == 0) stats1.errortime_wb_ack_o = $time;
            stats1.errors_wb_ack_o++;
        end
        if (stats1.clocks > 1 && !tb_match_m_wb_adr_o) begin
            if (stats1.errors_m_wb_adr_o == 0) stats1.errortime_m_wb_adr_o = $time;
            stats1.errors_m_wb_adr_o++;
        end
        if (stats1.clocks > 1 && !tb_match_m_wb_sel_o) begin
            if (stats1.errors_m_wb_sel_o == 0) stats1.errortime_m_wb_sel_o = $time;
            stats1.errors_m_wb_sel_o++;
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
        if (stats1.clocks > 1 && !tb_match_sd_dat_out_o) begin
            if (stats1.errors_sd_dat_out_o == 0) stats1.errortime_sd_dat_out_o = $time;
            stats1.errors_sd_dat_out_o++;
        end
        if (stats1.clocks > 1 && !tb_match_sd_dat_oe_o) begin
            if (stats1.errors_sd_dat_oe_o == 0) stats1.errortime_sd_dat_oe_o = $time;
            stats1.errors_sd_dat_oe_o++;
        end
        if (stats1.clocks > 1 && !tb_match_sd_cmd_out_o) begin
            if (stats1.errors_sd_cmd_out_o == 0) stats1.errortime_sd_cmd_out_o = $time;
            stats1.errors_sd_cmd_out_o++;
        end
        if (stats1.clocks > 1 && !tb_match_sd_cmd_oe_o) begin
            if (stats1.errors_sd_cmd_oe_o == 0) stats1.errortime_sd_cmd_oe_o = $time;
            stats1.errors_sd_cmd_oe_o++;
        end
        if (stats1.clocks > 1 && !tb_match_sd_clk_o_pad) begin
            if (stats1.errors_sd_clk_o_pad == 0) stats1.errortime_sd_clk_o_pad = $time;
            stats1.errors_sd_clk_o_pad++;
        end
        if (stats1.clocks > 1 && !tb_match_int_a) begin
            if (stats1.errors_int_a == 0) stats1.errortime_int_a = $time;
            stats1.errors_int_a++;
        end
        if (stats1.clocks > 1 && !tb_match_int_b) begin
            if (stats1.errors_int_b == 0) stats1.errortime_int_b = $time;
            stats1.errors_int_b++;
        end
        if (stats1.clocks > 1 && !tb_match_int_c) begin
            if (stats1.errors_int_c == 0) stats1.errortime_int_c = $time;
            stats1.errors_int_c++;
        end
    end

    final begin
        $display("\nTest Results:");
        if (stats1.errors_wb_dat_o)
            $display("Hint: Output wb_dat_o has %0d mismatches. First at time %0d",
                    stats1.errors_wb_dat_o, stats1.errortime_wb_dat_o);
        else
            $display("Hint: Output 'wb_dat_o' has no mismatches.");
        if (stats1.errors_wb_ack_o)
            $display("Hint: Output wb_ack_o has %0d mismatches. First at time %0d",
                    stats1.errors_wb_ack_o, stats1.errortime_wb_ack_o);
        else
            $display("Hint: Output 'wb_ack_o' has no mismatches.");
        if (stats1.errors_m_wb_adr_o)
            $display("Hint: Output m_wb_adr_o has %0d mismatches. First at time %0d",
                    stats1.errors_m_wb_adr_o, stats1.errortime_m_wb_adr_o);
        else
            $display("Hint: Output 'm_wb_adr_o' has no mismatches.");
        if (stats1.errors_m_wb_sel_o)
            $display("Hint: Output m_wb_sel_o has %0d mismatches. First at time %0d",
                    stats1.errors_m_wb_sel_o, stats1.errortime_m_wb_sel_o);
        else
            $display("Hint: Output 'm_wb_sel_o' has no mismatches.");
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
        if (stats1.errors_sd_dat_out_o)
            $display("Hint: Output sd_dat_out_o has %0d mismatches. First at time %0d",
                    stats1.errors_sd_dat_out_o, stats1.errortime_sd_dat_out_o);
        else
            $display("Hint: Output 'sd_dat_out_o' has no mismatches.");
        if (stats1.errors_sd_dat_oe_o)
            $display("Hint: Output sd_dat_oe_o has %0d mismatches. First at time %0d",
                    stats1.errors_sd_dat_oe_o, stats1.errortime_sd_dat_oe_o);
        else
            $display("Hint: Output 'sd_dat_oe_o' has no mismatches.");
        if (stats1.errors_sd_cmd_out_o)
            $display("Hint: Output sd_cmd_out_o has %0d mismatches. First at time %0d",
                    stats1.errors_sd_cmd_out_o, stats1.errortime_sd_cmd_out_o);
        else
            $display("Hint: Output 'sd_cmd_out_o' has no mismatches.");
        if (stats1.errors_sd_cmd_oe_o)
            $display("Hint: Output sd_cmd_oe_o has %0d mismatches. First at time %0d",
                    stats1.errors_sd_cmd_oe_o, stats1.errortime_sd_cmd_oe_o);
        else
            $display("Hint: Output 'sd_cmd_oe_o' has no mismatches.");
        if (stats1.errors_sd_clk_o_pad)
            $display("Hint: Output sd_clk_o_pad has %0d mismatches. First at time %0d",
                    stats1.errors_sd_clk_o_pad, stats1.errortime_sd_clk_o_pad);
        else
            $display("Hint: Output 'sd_clk_o_pad' has no mismatches.");
        if (stats1.errors_int_a)
            $display("Hint: Output int_a has %0d mismatches. First at time %0d",
                    stats1.errors_int_a, stats1.errortime_int_a);
        else
            $display("Hint: Output 'int_a' has no mismatches.");
        if (stats1.errors_int_b)
            $display("Hint: Output int_b has %0d mismatches. First at time %0d",
                    stats1.errors_int_b, stats1.errortime_int_b);
        else
            $display("Hint: Output 'int_b' has no mismatches.");
        if (stats1.errors_int_c)
            $display("Hint: Output int_c has %0d mismatches. First at time %0d",
                    stats1.errors_int_c, stats1.errortime_int_c);
        else
            $display("Hint: Output 'int_c' has no mismatches.");
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
