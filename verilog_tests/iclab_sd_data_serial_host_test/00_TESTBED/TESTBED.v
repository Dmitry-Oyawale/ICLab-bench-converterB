`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "sd_data_serial_host.v"
`elsif GATE
    `include "Netlist/sd_data_serial_host_SYN.v"
`endif

module TESTBED;

wire sd_clk;
wire rst;
wire [31:0] data_in;
wire rd;
wire [`SD_BUS_W-1:0] data_out;
wire we;
wire DAT_oe_o;
wire reg;
wire [`SD_BUS_W-1:0] DAT_dat_i;
wire [1:0] start_dat;
wire ack_transfer;
wire busy_n;
wire transm_complete;
wire crc_ok;

initial begin
	`ifdef RTL
		$fsdbDumpfile("sd_data_serial_host.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("Netlist/sd_data_serial_host_SYN.sdf", u_DUT);
		$fsdbDumpfile("sd_data_serial_host_SYN.fsdb");
		$fsdbDumpvars();
	`endif
end

`ifdef RTL
	sd_data_serial_host u_DUT(
		.sd_clk(sd_clk),
		.rst(rst),
		.data_in(data_in),
		.rd(rd),
		.data_out(data_out),
		.we(we),
		.DAT_oe_o(DAT_oe_o),
		.reg(reg),
		.DAT_dat_i(DAT_dat_i),
		.start_dat(start_dat),
		.ack_transfer(ack_transfer),
		.busy_n(busy_n),
		.transm_complete(transm_complete),
		.crc_ok(crc_ok)
	);
`elsif GATE
	sd_data_serial_host u_DUT(
		.sd_clk(sd_clk),
		.rst(rst),
		.data_in(data_in),
		.rd(rd),
		.data_out(data_out),
		.we(we),
		.DAT_oe_o(DAT_oe_o),
		.reg(reg),
		.DAT_dat_i(DAT_dat_i),
		.start_dat(start_dat),
		.ack_transfer(ack_transfer),
		.busy_n(busy_n),
		.transm_complete(transm_complete),
		.crc_ok(crc_ok)
	);
`endif

PATTERN u_PATTERN(
		.sd_clk(sd_clk),
		.rst(rst),
		.data_in(data_in),
		.rd_dut(rd),
		.data_out_dut(data_out),
		.we_dut(we),
		.DAT_oe_o_dut(DAT_oe_o),
		.reg_dut(reg),
		.DAT_dat_i(DAT_dat_i),
		.start_dat(start_dat),
		.ack_transfer(ack_transfer),
		.busy_n_dut(busy_n),
		.transm_complete_dut(transm_complete),
		.crc_ok_dut(crc_ok)
);

endmodule
