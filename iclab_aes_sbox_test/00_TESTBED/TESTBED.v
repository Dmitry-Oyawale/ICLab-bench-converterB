`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "aes_sbox.v"
`elsif GATE
    `include "Netlist/aes_sbox_SYN.v"
`endif

module TESTBED;

wire [7:0] a;
wire [7:0] b;

initial begin
	`ifdef RTL
		$fsdbDumpfile("aes_sbox.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("Netlist/aes_sbox_SYN.sdf", u_DUT);
		$fsdbDumpfile("aes_sbox_SYN.fsdb");
		$fsdbDumpvars();
	`endif
end

`ifdef RTL
	aes_sbox u_DUT(
		.a(a),
		.b(b)
	);
`elsif GATE
	aes_sbox u_DUT(
		.a(a),
		.b(b)
	);
`endif

PATTERN u_PATTERN(
		.a(a),
		.b_dut(b)
);

endmodule
