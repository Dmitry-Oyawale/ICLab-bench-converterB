`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "sd_bd.v"
`elsif GATE
    `include "Netlist/sd_bd_SYN.v"
`endif

module TESTBED;

wire clk;
wire rst;
wire stb_m;
wire we_m;
wire [`RAM_MEM_WIDTH-1:0] dat_in_m;
wire [`BD_WIDTH-1 :0] free_bd;
wire re_s;
wire ack_o_s;
wire a_cmp;
wire reg;

initial begin
	`ifdef RTL
		$fsdbDumpfile("sd_bd.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("Netlist/sd_bd_SYN.sdf", u_DUT);
		$fsdbDumpfile("sd_bd_SYN.fsdb");
		$fsdbDumpvars();
	`endif
end

`ifdef RTL
	sd_bd u_DUT(
		.clk(clk),
		.rst(rst),
		.stb_m(stb_m),
		.we_m(we_m),
		.dat_in_m(dat_in_m),
		.free_bd(free_bd),
		.re_s(re_s),
		.ack_o_s(ack_o_s),
		.a_cmp(a_cmp),
		.reg(reg)
	);
`elsif GATE
	sd_bd u_DUT(
		.clk(clk),
		.rst(rst),
		.stb_m(stb_m),
		.we_m(we_m),
		.dat_in_m(dat_in_m),
		.free_bd(free_bd),
		.re_s(re_s),
		.ack_o_s(ack_o_s),
		.a_cmp(a_cmp),
		.reg(reg)
	);
`endif

PATTERN u_PATTERN(
		.clk(clk),
		.rst(rst),
		.stb_m(stb_m),
		.we_m(we_m),
		.dat_in_m(dat_in_m),
		.free_bd_dut(free_bd),
		.re_s(re_s),
		.ack_o_s_dut(ack_o_s),
		.a_cmp(a_cmp),
		.reg_dut(reg)
);

endmodule
