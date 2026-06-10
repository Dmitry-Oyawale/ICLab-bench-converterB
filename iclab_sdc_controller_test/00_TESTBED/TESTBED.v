`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "sdc_controller.v"
`elsif GATE
    `include "Netlist/sdc_controller_SYN.v"
`endif

module TESTBED;

wire wb_clk_i;
wire wb_rst_i;
wire [31:0] wb_dat_i;
wire [31:0] wb_dat_o;
wire card_detect;
wire [7:0] wb_adr_i;
wire [3:0] wb_sel_i;
wire wb_we_i;
wire wb_cyc_i;
wire wb_stb_i;
wire wb_ack_o;
wire [31:0] m_wb_adr_o;
wire [3:0] m_wb_sel_o;
wire m_wb_we_o;
wire [31:0] m_wb_dat_i;
wire [31:0] m_wb_dat_o;
wire m_wb_cyc_o;
wire m_wb_stb_o;
wire m_wb_ack_i;
wire [2:0] m_wb_cti_o;
wire [1:0] m_wb_bte_o;
wire [3:0] sd_dat_dat_i;
wire [3:0] sd_dat_out_o;
wire sd_dat_oe_o;
wire sd_cmd_dat_i;
wire sd_cmd_out_o;
wire sd_cmd_oe_o;
wire sd_clk_o_pad;
wire sd_clk_i_pad;
wire int_a;
wire int_b;
wire int_c;

initial begin
	`ifdef RTL
		$fsdbDumpfile("sdc_controller.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("Netlist/sdc_controller_SYN.sdf", u_DUT);
		$fsdbDumpfile("sdc_controller_SYN.fsdb");
		$fsdbDumpvars();
	`endif
end

`ifdef RTL
	sdc_controller u_DUT(
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_dat_i(wb_dat_i),
		.wb_dat_o(wb_dat_o),
		.card_detect(card_detect),
		.wb_adr_i(wb_adr_i),
		.wb_sel_i(wb_sel_i),
		.wb_we_i(wb_we_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_stb_i(wb_stb_i),
		.wb_ack_o(wb_ack_o),
		.m_wb_adr_o(m_wb_adr_o),
		.m_wb_sel_o(m_wb_sel_o),
		.m_wb_we_o(m_wb_we_o),
		.m_wb_dat_i(m_wb_dat_i),
		.m_wb_dat_o(m_wb_dat_o),
		.m_wb_cyc_o(m_wb_cyc_o),
		.m_wb_stb_o(m_wb_stb_o),
		.m_wb_ack_i(m_wb_ack_i),
		.m_wb_cti_o(m_wb_cti_o),
		.m_wb_bte_o(m_wb_bte_o),
		.sd_dat_dat_i(sd_dat_dat_i),
		.sd_dat_out_o(sd_dat_out_o),
		.sd_dat_oe_o(sd_dat_oe_o),
		.sd_cmd_dat_i(sd_cmd_dat_i),
		.sd_cmd_out_o(sd_cmd_out_o),
		.sd_cmd_oe_o(sd_cmd_oe_o),
		.sd_clk_o_pad(sd_clk_o_pad),
		.sd_clk_i_pad(sd_clk_i_pad),
		.int_a(int_a),
		.int_b(int_b),
		.int_c(int_c)
	);
`elsif GATE
	sdc_controller u_DUT(
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_dat_i(wb_dat_i),
		.wb_dat_o(wb_dat_o),
		.card_detect(card_detect),
		.wb_adr_i(wb_adr_i),
		.wb_sel_i(wb_sel_i),
		.wb_we_i(wb_we_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_stb_i(wb_stb_i),
		.wb_ack_o(wb_ack_o),
		.m_wb_adr_o(m_wb_adr_o),
		.m_wb_sel_o(m_wb_sel_o),
		.m_wb_we_o(m_wb_we_o),
		.m_wb_dat_i(m_wb_dat_i),
		.m_wb_dat_o(m_wb_dat_o),
		.m_wb_cyc_o(m_wb_cyc_o),
		.m_wb_stb_o(m_wb_stb_o),
		.m_wb_ack_i(m_wb_ack_i),
		.m_wb_cti_o(m_wb_cti_o),
		.m_wb_bte_o(m_wb_bte_o),
		.sd_dat_dat_i(sd_dat_dat_i),
		.sd_dat_out_o(sd_dat_out_o),
		.sd_dat_oe_o(sd_dat_oe_o),
		.sd_cmd_dat_i(sd_cmd_dat_i),
		.sd_cmd_out_o(sd_cmd_out_o),
		.sd_cmd_oe_o(sd_cmd_oe_o),
		.sd_clk_o_pad(sd_clk_o_pad),
		.sd_clk_i_pad(sd_clk_i_pad),
		.int_a(int_a),
		.int_b(int_b),
		.int_c(int_c)
	);
`endif

PATTERN u_PATTERN(
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_dat_i(wb_dat_i),
		.wb_dat_o_dut(wb_dat_o),
		.card_detect(card_detect),
		.wb_adr_i(wb_adr_i),
		.wb_sel_i(wb_sel_i),
		.wb_we_i(wb_we_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_stb_i(wb_stb_i),
		.wb_ack_o_dut(wb_ack_o),
		.m_wb_adr_o_dut(m_wb_adr_o),
		.m_wb_sel_o_dut(m_wb_sel_o),
		.m_wb_we_o_dut(m_wb_we_o),
		.m_wb_dat_i(m_wb_dat_i),
		.m_wb_dat_o_dut(m_wb_dat_o),
		.m_wb_cyc_o_dut(m_wb_cyc_o),
		.m_wb_stb_o_dut(m_wb_stb_o),
		.m_wb_ack_i(m_wb_ack_i),
		.m_wb_cti_o_dut(m_wb_cti_o),
		.m_wb_bte_o_dut(m_wb_bte_o),
		.sd_dat_dat_i(sd_dat_dat_i),
		.sd_dat_out_o_dut(sd_dat_out_o),
		.sd_dat_oe_o_dut(sd_dat_oe_o),
		.sd_cmd_dat_i(sd_cmd_dat_i),
		.sd_cmd_out_o_dut(sd_cmd_out_o),
		.sd_cmd_oe_o_dut(sd_cmd_oe_o),
		.sd_clk_o_pad_dut(sd_clk_o_pad),
		.sd_clk_i_pad(sd_clk_i_pad),
		.int_a_dut(int_a),
		.int_b_dut(int_b),
		.int_c_dut(int_c)
);

endmodule
