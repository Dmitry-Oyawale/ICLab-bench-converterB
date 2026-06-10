`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "sd_controller_wb.v"
`elsif GATE
    `include "Netlist/sd_controller_wb_SYN.v"
`endif

module TESTBED;

wire wb_clk_i;
wire wb_rst_i;
wire [31:0] wb_dat_i;
wire [31:0] wb_dat_o;
wire [7:0] wb_adr_i;
wire [3:0] wb_sel_i;
wire wb_we_i;
wire wb_cyc_i;
wire wb_stb_i;
wire wb_ack_o;
wire we_m_tx_bd;
wire we_m_rx_bd;
wire new_cmd;
wire we_ack;
wire int_ack;
wire cmd_int_busy;
wire int_busy;
wire write_req_s;
wire [15:0] cmd_set_s;
wire [31:0] cmd_arg_s;
wire [31:0] argument_reg;
wire [15:0] cmd_setting_reg;
wire [15:0] status_reg;
wire [31:0] cmd_resp_1;
wire [7:0] software_reset_reg;
wire [15:0] time_out_reg;
wire [15:0] normal_int_status_reg;
wire [15:0] error_int_status_reg;
wire [15:0] normal_int_signal_enable_reg;
wire [15:0] error_int_signal_enable_reg;
wire [7:0] clock_divider;
wire [15:0] Bd_Status_reg;
wire [7:0] Bd_isr_reg;
wire [7:0] Bd_isr_enable_reg;
wire Bd_isr_reset;
wire normal_isr_reset;
wire error_isr_reset;
wire [`RAM_MEM_WIDTH-1:0] dat_in_m_rx_bd;
wire [`RAM_MEM_WIDTH-1:0] dat_in_m_tx_bd;

initial begin
	`ifdef RTL
		$fsdbDumpfile("sd_controller_wb.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("Netlist/sd_controller_wb_SYN.sdf", u_DUT);
		$fsdbDumpfile("sd_controller_wb_SYN.fsdb");
		$fsdbDumpvars();
	`endif
end

`ifdef RTL
	sd_controller_wb u_DUT(
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_dat_i(wb_dat_i),
		.wb_dat_o(wb_dat_o),
		.wb_adr_i(wb_adr_i),
		.wb_sel_i(wb_sel_i),
		.wb_we_i(wb_we_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_stb_i(wb_stb_i),
		.wb_ack_o(wb_ack_o),
		.we_m_tx_bd(we_m_tx_bd),
		.we_m_rx_bd(we_m_rx_bd),
		.new_cmd(new_cmd),
		.we_ack(we_ack),
		.int_ack(int_ack),
		.cmd_int_busy(cmd_int_busy),
		.int_busy(int_busy),
		.write_req_s(write_req_s),
		.cmd_set_s(cmd_set_s),
		.cmd_arg_s(cmd_arg_s),
		.argument_reg(argument_reg),
		.cmd_setting_reg(cmd_setting_reg),
		.status_reg(status_reg),
		.cmd_resp_1(cmd_resp_1),
		.software_reset_reg(software_reset_reg),
		.time_out_reg(time_out_reg),
		.normal_int_status_reg(normal_int_status_reg),
		.error_int_status_reg(error_int_status_reg),
		.normal_int_signal_enable_reg(normal_int_signal_enable_reg),
		.error_int_signal_enable_reg(error_int_signal_enable_reg),
		.clock_divider(clock_divider),
		.Bd_Status_reg(Bd_Status_reg),
		.Bd_isr_reg(Bd_isr_reg),
		.Bd_isr_enable_reg(Bd_isr_enable_reg),
		.Bd_isr_reset(Bd_isr_reset),
		.normal_isr_reset(normal_isr_reset),
		.error_isr_reset(error_isr_reset),
		.dat_in_m_rx_bd(dat_in_m_rx_bd),
		.dat_in_m_tx_bd(dat_in_m_tx_bd)
	);
`elsif GATE
	sd_controller_wb u_DUT(
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_dat_i(wb_dat_i),
		.wb_dat_o(wb_dat_o),
		.wb_adr_i(wb_adr_i),
		.wb_sel_i(wb_sel_i),
		.wb_we_i(wb_we_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_stb_i(wb_stb_i),
		.wb_ack_o(wb_ack_o),
		.we_m_tx_bd(we_m_tx_bd),
		.we_m_rx_bd(we_m_rx_bd),
		.new_cmd(new_cmd),
		.we_ack(we_ack),
		.int_ack(int_ack),
		.cmd_int_busy(cmd_int_busy),
		.int_busy(int_busy),
		.write_req_s(write_req_s),
		.cmd_set_s(cmd_set_s),
		.cmd_arg_s(cmd_arg_s),
		.argument_reg(argument_reg),
		.cmd_setting_reg(cmd_setting_reg),
		.status_reg(status_reg),
		.cmd_resp_1(cmd_resp_1),
		.software_reset_reg(software_reset_reg),
		.time_out_reg(time_out_reg),
		.normal_int_status_reg(normal_int_status_reg),
		.error_int_status_reg(error_int_status_reg),
		.normal_int_signal_enable_reg(normal_int_signal_enable_reg),
		.error_int_signal_enable_reg(error_int_signal_enable_reg),
		.clock_divider(clock_divider),
		.Bd_Status_reg(Bd_Status_reg),
		.Bd_isr_reg(Bd_isr_reg),
		.Bd_isr_enable_reg(Bd_isr_enable_reg),
		.Bd_isr_reset(Bd_isr_reset),
		.normal_isr_reset(normal_isr_reset),
		.error_isr_reset(error_isr_reset),
		.dat_in_m_rx_bd(dat_in_m_rx_bd),
		.dat_in_m_tx_bd(dat_in_m_tx_bd)
	);
`endif

PATTERN u_PATTERN(
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_dat_i(wb_dat_i),
		.wb_dat_o_dut(wb_dat_o),
		.wb_adr_i(wb_adr_i),
		.wb_sel_i(wb_sel_i),
		.wb_we_i(wb_we_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_stb_i(wb_stb_i),
		.wb_ack_o_dut(wb_ack_o),
		.we_m_tx_bd_dut(we_m_tx_bd),
		.we_m_rx_bd_dut(we_m_rx_bd),
		.new_cmd_dut(new_cmd),
		.we_ack_dut(we_ack),
		.int_ack_dut(int_ack),
		.cmd_int_busy_dut(cmd_int_busy),
		.int_busy_dut(int_busy),
		.write_req_s(write_req_s),
		.cmd_set_s(cmd_set_s),
		.cmd_arg_s(cmd_arg_s),
		.argument_reg_dut(argument_reg),
		.cmd_setting_reg_dut(cmd_setting_reg),
		.status_reg(status_reg),
		.cmd_resp_1(cmd_resp_1),
		.software_reset_reg_dut(software_reset_reg),
		.time_out_reg_dut(time_out_reg),
		.normal_int_status_reg(normal_int_status_reg),
		.error_int_status_reg(error_int_status_reg),
		.normal_int_signal_enable_reg_dut(normal_int_signal_enable_reg),
		.error_int_signal_enable_reg_dut(error_int_signal_enable_reg),
		.clock_divider_dut(clock_divider),
		.Bd_Status_reg(Bd_Status_reg),
		.Bd_isr_reg(Bd_isr_reg),
		.Bd_isr_enable_reg_dut(Bd_isr_enable_reg),
		.Bd_isr_reset_dut(Bd_isr_reset),
		.normal_isr_reset_dut(normal_isr_reset),
		.error_isr_reset_dut(error_isr_reset),
		.dat_in_m_rx_bd_dut(dat_in_m_rx_bd),
		.dat_in_m_tx_bd_dut(dat_in_m_tx_bd)
);

endmodule
