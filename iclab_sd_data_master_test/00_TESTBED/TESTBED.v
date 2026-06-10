`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "sd_data_master.v"
`elsif GATE
    `include "Netlist/sd_data_master_SYN.v"
`endif

module TESTBED;

wire clk;
wire rst;
wire [`RAM_MEM_WIDTH-1:0] dat_in_tx;
wire [`BD_WIDTH-1:0] free_tx_bd;
wire ack_i_s_tx;
wire re_s_tx;
wire a_cmp_tx;
wire [`RAM_MEM_WIDTH-1:0] dat_in_rx;
wire [`BD_WIDTH-1:0] free_rx_bd;
wire ack_i_s_rx;
wire re_s_rx;
wire a_cmp_rx;
wire cmd_busy;
wire we_req;
wire we_ack;
wire d_write;
wire d_read;
wire [31:0] cmd_arg;
wire [15:0] cmd_set;
wire cmd_tsf_err;
wire [4:0] card_status;
wire start_tx_fifo;
wire start_rx_fifo;
wire [31:0] sys_adr;
wire tx_empt;
wire tx_full;
wire rx_full;
wire busy_n;
wire transm_complete;
wire crc_ok;
wire ack_transfer;
wire output;
wire Dat_Int_Status_rst;
wire CIDAT;
wire [1:0] transfer_type;

initial begin
	`ifdef RTL
		$fsdbDumpfile("sd_data_master.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("Netlist/sd_data_master_SYN.sdf", u_DUT);
		$fsdbDumpfile("sd_data_master_SYN.fsdb");
		$fsdbDumpvars();
	`endif
end

`ifdef RTL
	sd_data_master u_DUT(
		.clk(clk),
		.rst(rst),
		.dat_in_tx(dat_in_tx),
		.free_tx_bd(free_tx_bd),
		.ack_i_s_tx(ack_i_s_tx),
		.re_s_tx(re_s_tx),
		.a_cmp_tx(a_cmp_tx),
		.dat_in_rx(dat_in_rx),
		.free_rx_bd(free_rx_bd),
		.ack_i_s_rx(ack_i_s_rx),
		.re_s_rx(re_s_rx),
		.a_cmp_rx(a_cmp_rx),
		.cmd_busy(cmd_busy),
		.we_req(we_req),
		.we_ack(we_ack),
		.d_write(d_write),
		.d_read(d_read),
		.cmd_arg(cmd_arg),
		.cmd_set(cmd_set),
		.cmd_tsf_err(cmd_tsf_err),
		.card_status(card_status),
		.start_tx_fifo(start_tx_fifo),
		.start_rx_fifo(start_rx_fifo),
		.sys_adr(sys_adr),
		.tx_empt(tx_empt),
		.tx_full(tx_full),
		.rx_full(rx_full),
		.busy_n(busy_n),
		.transm_complete(transm_complete),
		.crc_ok(crc_ok),
		.ack_transfer(ack_transfer),
		.output(output),
		.Dat_Int_Status_rst(Dat_Int_Status_rst),
		.CIDAT(CIDAT),
		.transfer_type(transfer_type)
	);
`elsif GATE
	sd_data_master u_DUT(
		.clk(clk),
		.rst(rst),
		.dat_in_tx(dat_in_tx),
		.free_tx_bd(free_tx_bd),
		.ack_i_s_tx(ack_i_s_tx),
		.re_s_tx(re_s_tx),
		.a_cmp_tx(a_cmp_tx),
		.dat_in_rx(dat_in_rx),
		.free_rx_bd(free_rx_bd),
		.ack_i_s_rx(ack_i_s_rx),
		.re_s_rx(re_s_rx),
		.a_cmp_rx(a_cmp_rx),
		.cmd_busy(cmd_busy),
		.we_req(we_req),
		.we_ack(we_ack),
		.d_write(d_write),
		.d_read(d_read),
		.cmd_arg(cmd_arg),
		.cmd_set(cmd_set),
		.cmd_tsf_err(cmd_tsf_err),
		.card_status(card_status),
		.start_tx_fifo(start_tx_fifo),
		.start_rx_fifo(start_rx_fifo),
		.sys_adr(sys_adr),
		.tx_empt(tx_empt),
		.tx_full(tx_full),
		.rx_full(rx_full),
		.busy_n(busy_n),
		.transm_complete(transm_complete),
		.crc_ok(crc_ok),
		.ack_transfer(ack_transfer),
		.output(output),
		.Dat_Int_Status_rst(Dat_Int_Status_rst),
		.CIDAT(CIDAT),
		.transfer_type(transfer_type)
	);
`endif

PATTERN u_PATTERN(
		.clk(clk),
		.rst(rst),
		.dat_in_tx(dat_in_tx),
		.free_tx_bd(free_tx_bd),
		.ack_i_s_tx(ack_i_s_tx),
		.re_s_tx_dut(re_s_tx),
		.a_cmp_tx_dut(a_cmp_tx),
		.dat_in_rx(dat_in_rx),
		.free_rx_bd(free_rx_bd),
		.ack_i_s_rx(ack_i_s_rx),
		.re_s_rx_dut(re_s_rx),
		.a_cmp_rx_dut(a_cmp_rx),
		.cmd_busy(cmd_busy),
		.we_req_dut(we_req),
		.we_ack(we_ack),
		.d_write_dut(d_write),
		.d_read_dut(d_read),
		.cmd_arg_dut(cmd_arg),
		.cmd_set_dut(cmd_set),
		.cmd_tsf_err(cmd_tsf_err),
		.card_status(card_status),
		.start_tx_fifo_dut(start_tx_fifo),
		.start_rx_fifo_dut(start_rx_fifo),
		.sys_adr_dut(sys_adr),
		.tx_empt(tx_empt),
		.tx_full(tx_full),
		.rx_full(rx_full),
		.busy_n(busy_n),
		.transm_complete(transm_complete),
		.crc_ok(crc_ok),
		.ack_transfer_dut(ack_transfer),
		.output_dut(output),
		.Dat_Int_Status_rst(Dat_Int_Status_rst),
		.CIDAT_dut(CIDAT),
		.transfer_type(transfer_type)
);

endmodule
