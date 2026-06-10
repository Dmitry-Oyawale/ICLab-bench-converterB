`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "sd_fifo_tx_filler.v"
`elsif GATE
    `include "Netlist/sd_fifo_tx_filler_SYN.v"
`endif

module TESTBED;

wire clk;
wire rst;
wire [31:0] m_wb_adr_o;
wire m_wb_we_o;
wire [31:0] m_wb_dat_i;
wire m_wb_cyc_o;
wire m_wb_stb_o;
wire m_wb_ack_i;
wire [2:0] m_wb_cti_o;
wire [1:0] m_wb_bte_o;
wire en;
wire [31:0] adr;
wire sd_clk;
wire [31:0] dat_o;
wire rd;
wire empty;
wire fe;

initial begin
	`ifdef RTL
		$fsdbDumpfile("sd_fifo_tx_filler.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("Netlist/sd_fifo_tx_filler_SYN.sdf", u_DUT);
		$fsdbDumpfile("sd_fifo_tx_filler_SYN.fsdb");
		$fsdbDumpvars();
	`endif
end

`ifdef RTL
	sd_fifo_tx_filler u_DUT(
		.clk(clk),
		.rst(rst),
		.m_wb_adr_o(m_wb_adr_o),
		.m_wb_we_o(m_wb_we_o),
		.m_wb_dat_i(m_wb_dat_i),
		.m_wb_cyc_o(m_wb_cyc_o),
		.m_wb_stb_o(m_wb_stb_o),
		.m_wb_ack_i(m_wb_ack_i),
		.m_wb_cti_o(m_wb_cti_o),
		.m_wb_bte_o(m_wb_bte_o),
		.en(en),
		.adr(adr),
		.sd_clk(sd_clk),
		.dat_o(dat_o),
		.rd(rd),
		.empty(empty),
		.fe(fe)
	);
`elsif GATE
	sd_fifo_tx_filler u_DUT(
		.clk(clk),
		.rst(rst),
		.m_wb_adr_o(m_wb_adr_o),
		.m_wb_we_o(m_wb_we_o),
		.m_wb_dat_i(m_wb_dat_i),
		.m_wb_cyc_o(m_wb_cyc_o),
		.m_wb_stb_o(m_wb_stb_o),
		.m_wb_ack_i(m_wb_ack_i),
		.m_wb_cti_o(m_wb_cti_o),
		.m_wb_bte_o(m_wb_bte_o),
		.en(en),
		.adr(adr),
		.sd_clk(sd_clk),
		.dat_o(dat_o),
		.rd(rd),
		.empty(empty),
		.fe(fe)
	);
`endif

PATTERN u_PATTERN(
		.clk(clk),
		.rst(rst),
		.m_wb_adr_o_dut(m_wb_adr_o),
		.m_wb_we_o_dut(m_wb_we_o),
		.m_wb_dat_i(m_wb_dat_i),
		.m_wb_cyc_o_dut(m_wb_cyc_o),
		.m_wb_stb_o_dut(m_wb_stb_o),
		.m_wb_ack_i(m_wb_ack_i),
		.m_wb_cti_o_dut(m_wb_cti_o),
		.m_wb_bte_o_dut(m_wb_bte_o),
		.en(en),
		.adr(adr),
		.sd_clk(sd_clk),
		.dat_o_dut(dat_o),
		.rd(rd),
		.empty_dut(empty),
		.fe_dut(fe)
);

endmodule
