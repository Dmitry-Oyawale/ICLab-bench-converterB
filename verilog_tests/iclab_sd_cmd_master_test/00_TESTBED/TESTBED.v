`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "sd_cmd_master.v"
`elsif GATE
    `include "Netlist/sd_cmd_master_SYN.v"
`endif

module TESTBED;

wire CLK_PAD_IO;
wire RST_PAD_I;
wire New_CMD;
wire data_write;
wire data_read;
wire [31:0] ARG_REG;
wire [13:0] CMD_SET_REG;
wire [15:0] TIMEOUT_REG;
wire [15:0] STATUS_REG;
wire [31:0] RESP_1_REG;
wire [4:0] ERR_INT_REG;
wire [15:0] NORMAL_INT_REG;
wire ERR_INT_RST;
wire NORMAL_INT_RST;
wire [15:0] settings;
wire go_idle_o;
wire [39:0] cmd_out;
wire req_out;
wire ack_out;
wire req_in;
wire ack_in;
wire [39:0] cmd_in;
wire [7:0] serial_status;
wire card_detect;

initial begin
	`ifdef RTL
		$fsdbDumpfile("sd_cmd_master.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("Netlist/sd_cmd_master_SYN.sdf", u_DUT);
		$fsdbDumpfile("sd_cmd_master_SYN.fsdb");
		$fsdbDumpvars();
	`endif
end

`ifdef RTL
	sd_cmd_master u_DUT(
		.CLK_PAD_IO(CLK_PAD_IO),
		.RST_PAD_I(RST_PAD_I),
		.New_CMD(New_CMD),
		.data_write(data_write),
		.data_read(data_read),
		.ARG_REG(ARG_REG),
		.CMD_SET_REG(CMD_SET_REG),
		.TIMEOUT_REG(TIMEOUT_REG),
		.STATUS_REG(STATUS_REG),
		.RESP_1_REG(RESP_1_REG),
		.ERR_INT_REG(ERR_INT_REG),
		.NORMAL_INT_REG(NORMAL_INT_REG),
		.ERR_INT_RST(ERR_INT_RST),
		.NORMAL_INT_RST(NORMAL_INT_RST),
		.settings(settings),
		.go_idle_o(go_idle_o),
		.cmd_out(cmd_out),
		.req_out(req_out),
		.ack_out(ack_out),
		.req_in(req_in),
		.ack_in(ack_in),
		.cmd_in(cmd_in),
		.serial_status(serial_status),
		.card_detect(card_detect)
	);
`elsif GATE
	sd_cmd_master u_DUT(
		.CLK_PAD_IO(CLK_PAD_IO),
		.RST_PAD_I(RST_PAD_I),
		.New_CMD(New_CMD),
		.data_write(data_write),
		.data_read(data_read),
		.ARG_REG(ARG_REG),
		.CMD_SET_REG(CMD_SET_REG),
		.TIMEOUT_REG(TIMEOUT_REG),
		.STATUS_REG(STATUS_REG),
		.RESP_1_REG(RESP_1_REG),
		.ERR_INT_REG(ERR_INT_REG),
		.NORMAL_INT_REG(NORMAL_INT_REG),
		.ERR_INT_RST(ERR_INT_RST),
		.NORMAL_INT_RST(NORMAL_INT_RST),
		.settings(settings),
		.go_idle_o(go_idle_o),
		.cmd_out(cmd_out),
		.req_out(req_out),
		.ack_out(ack_out),
		.req_in(req_in),
		.ack_in(ack_in),
		.cmd_in(cmd_in),
		.serial_status(serial_status),
		.card_detect(card_detect)
	);
`endif

PATTERN u_PATTERN(
		.CLK_PAD_IO(CLK_PAD_IO),
		.RST_PAD_I(RST_PAD_I),
		.New_CMD(New_CMD),
		.data_write(data_write),
		.data_read(data_read),
		.ARG_REG(ARG_REG),
		.CMD_SET_REG(CMD_SET_REG),
		.TIMEOUT_REG(TIMEOUT_REG),
		.STATUS_REG_dut(STATUS_REG),
		.RESP_1_REG_dut(RESP_1_REG),
		.ERR_INT_REG_dut(ERR_INT_REG),
		.NORMAL_INT_REG_dut(NORMAL_INT_REG),
		.ERR_INT_RST(ERR_INT_RST),
		.NORMAL_INT_RST(NORMAL_INT_RST),
		.settings_dut(settings),
		.go_idle_o_dut(go_idle_o),
		.cmd_out_dut(cmd_out),
		.req_out_dut(req_out),
		.ack_out_dut(ack_out),
		.req_in(req_in),
		.ack_in(ack_in),
		.cmd_in(cmd_in),
		.serial_status(serial_status),
		.card_detect(card_detect)
);

endmodule
