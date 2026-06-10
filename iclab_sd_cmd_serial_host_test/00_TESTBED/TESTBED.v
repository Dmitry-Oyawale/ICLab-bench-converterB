`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "sd_cmd_serial_host.v"
`elsif GATE
    `include "Netlist/sd_cmd_serial_host_SYN.v"
`endif

module TESTBED;

wire SD_CLK_IN;
wire RST_IN;
wire [15:0] SETTING_IN;
wire [39:0] CMD_IN;
wire REQ_IN;
wire ACK_IN;
wire cmd_dat_i;
wire [39:0] CMD_OUT;
wire ACK_OUT;
wire REQ_OUT;
wire [7:0] STATUS;
wire cmd_oe_o;
wire cmd_out_o;
wire [1:0] st_dat_t;

initial begin
	`ifdef RTL
		$fsdbDumpfile("sd_cmd_serial_host.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("Netlist/sd_cmd_serial_host_SYN.sdf", u_DUT);
		$fsdbDumpfile("sd_cmd_serial_host_SYN.fsdb");
		$fsdbDumpvars();
	`endif
end

`ifdef RTL
	sd_cmd_serial_host u_DUT(
		.SD_CLK_IN(SD_CLK_IN),
		.RST_IN(RST_IN),
		.SETTING_IN(SETTING_IN),
		.CMD_IN(CMD_IN),
		.REQ_IN(REQ_IN),
		.ACK_IN(ACK_IN),
		.cmd_dat_i(cmd_dat_i),
		.CMD_OUT(CMD_OUT),
		.ACK_OUT(ACK_OUT),
		.REQ_OUT(REQ_OUT),
		.STATUS(STATUS),
		.cmd_oe_o(cmd_oe_o),
		.cmd_out_o(cmd_out_o),
		.st_dat_t(st_dat_t)
	);
`elsif GATE
	sd_cmd_serial_host u_DUT(
		.SD_CLK_IN(SD_CLK_IN),
		.RST_IN(RST_IN),
		.SETTING_IN(SETTING_IN),
		.CMD_IN(CMD_IN),
		.REQ_IN(REQ_IN),
		.ACK_IN(ACK_IN),
		.cmd_dat_i(cmd_dat_i),
		.CMD_OUT(CMD_OUT),
		.ACK_OUT(ACK_OUT),
		.REQ_OUT(REQ_OUT),
		.STATUS(STATUS),
		.cmd_oe_o(cmd_oe_o),
		.cmd_out_o(cmd_out_o),
		.st_dat_t(st_dat_t)
	);
`endif

PATTERN u_PATTERN(
		.SD_CLK_IN(SD_CLK_IN),
		.RST_IN(RST_IN),
		.SETTING_IN(SETTING_IN),
		.CMD_IN(CMD_IN),
		.REQ_IN(REQ_IN),
		.ACK_IN(ACK_IN),
		.cmd_dat_i(cmd_dat_i),
		.CMD_OUT_dut(CMD_OUT),
		.ACK_OUT_dut(ACK_OUT),
		.REQ_OUT_dut(REQ_OUT),
		.STATUS_dut(STATUS),
		.cmd_oe_o_dut(cmd_oe_o),
		.cmd_out_o_dut(cmd_out_o),
		.st_dat_t_dut(st_dat_t)
);

endmodule
