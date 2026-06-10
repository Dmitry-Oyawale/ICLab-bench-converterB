`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "sd_crc_16.v"
`elsif GATE
    `include "Netlist/sd_crc_16_SYN.v"
`endif

module TESTBED;

wire BITVAL;
wire Enable;
wire CLK;
wire RST;
wire [15:0] CRC;

initial begin
	`ifdef RTL
		$fsdbDumpfile("sd_crc_16.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("Netlist/sd_crc_16_SYN.sdf", u_DUT);
		$fsdbDumpfile("sd_crc_16_SYN.fsdb");
		$fsdbDumpvars();
	`endif
end

`ifdef RTL
	sd_crc_16 u_DUT(
		.BITVAL(BITVAL),
		.Enable(Enable),
		.CLK(CLK),
		.RST(RST),
		.CRC(CRC)
	);
`elsif GATE
	sd_crc_16 u_DUT(
		.BITVAL(BITVAL),
		.Enable(Enable),
		.CLK(CLK),
		.RST(RST),
		.CRC(CRC)
	);
`endif

PATTERN u_PATTERN(
		.BITVAL(BITVAL),
		.Enable(Enable),
		.CLK(CLK),
		.RST(RST),
		.CRC_dut(CRC)
);

endmodule
