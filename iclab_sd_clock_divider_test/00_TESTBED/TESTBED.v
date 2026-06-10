`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "sd_clock_divider.v"
`elsif GATE
    `include "Netlist/sd_clock_divider_SYN.v"
`endif

module TESTBED;

wire CLK;
wire [7:0] DIVIDER;
wire RST;
wire SD_CLK;

initial begin
	`ifdef RTL
		$fsdbDumpfile("sd_clock_divider.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("Netlist/sd_clock_divider_SYN.sdf", u_DUT);
		$fsdbDumpfile("sd_clock_divider_SYN.fsdb");
		$fsdbDumpvars();
	`endif
end

`ifdef RTL
	sd_clock_divider u_DUT(
		.CLK(CLK),
		.DIVIDER(DIVIDER),
		.RST(RST),
		.SD_CLK(SD_CLK)
	);
`elsif GATE
	sd_clock_divider u_DUT(
		.CLK(CLK),
		.DIVIDER(DIVIDER),
		.RST(RST),
		.SD_CLK(SD_CLK)
	);
`endif

PATTERN u_PATTERN(
		.CLK(CLK),
		.DIVIDER(DIVIDER),
		.RST(RST),
		.SD_CLK_dut(SD_CLK)
);

endmodule
