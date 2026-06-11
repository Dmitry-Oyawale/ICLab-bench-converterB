`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "aes_key_expand_128.v"
`elsif GATE
    `include "Netlist/aes_key_expand_128_SYN.v"
`endif

module TESTBED;

wire clk;
wire kld;
wire [127:0] key;
wire [31:0] wo_0;
wire [31:0] wo_1;
wire [31:0] wo_2;
wire [31:0] wo_3;

initial begin
	`ifdef RTL
		$fsdbDumpfile("aes_key_expand_128.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("Netlist/aes_key_expand_128_SYN.sdf", u_DUT);
		$fsdbDumpfile("aes_key_expand_128_SYN.fsdb");
		$fsdbDumpvars();
	`endif
end

`ifdef RTL
	aes_key_expand_128 u_DUT(
		.clk(clk),
		.kld(kld),
		.key(key),
		.wo_0(wo_0),
		.wo_1(wo_1),
		.wo_2(wo_2),
		.wo_3(wo_3)
	);
`elsif GATE
	aes_key_expand_128 u_DUT(
		.clk(clk),
		.kld(kld),
		.key(key),
		.wo_0(wo_0),
		.wo_1(wo_1),
		.wo_2(wo_2),
		.wo_3(wo_3)
	);
`endif

PATTERN u_PATTERN(
		.clk(clk),
		.kld(kld),
		.key(key),
		.wo_0_dut(wo_0),
		.wo_1_dut(wo_1),
		.wo_2_dut(wo_2),
		.wo_3_dut(wo_3)
);

endmodule
