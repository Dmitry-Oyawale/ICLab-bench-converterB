`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "aes_rcon.v"
`elsif GATE
    `include "Netlist/aes_rcon_SYN.v"
`endif

module TESTBED;

wire clk;
wire kld;
wire [31:0] out;

initial begin
	`ifdef RTL
		$fsdbDumpfile("aes_rcon.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("Netlist/aes_rcon_SYN.sdf", u_DUT);
		$fsdbDumpfile("aes_rcon_SYN.fsdb");
		$fsdbDumpvars();
	`endif
end

`ifdef RTL
	aes_rcon u_DUT(
		.clk(clk),
		.kld(kld),
		.out(out)
	);
`elsif GATE
	aes_rcon u_DUT(
		.clk(clk),
		.kld(kld),
		.out(out)
	);
`endif

PATTERN u_PATTERN(
		.clk(clk),
		.kld(kld),
		.out_dut(out)
);

endmodule
