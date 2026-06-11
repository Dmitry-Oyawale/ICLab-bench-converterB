`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "sd_rx_fifo.v"
`elsif GATE
    `include "Netlist/sd_rx_fifo_SYN.v"
`endif

module TESTBED;

wire [4-1:0] d;
wire wr;
wire wclk;
wire [32-1:0] q;
wire rd;
wire full;
wire empty;
wire [1:0] mem_empt;
wire rclk;
wire rst;

initial begin
	`ifdef RTL
		$fsdbDumpfile("sd_rx_fifo.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("Netlist/sd_rx_fifo_SYN.sdf", u_DUT);
		$fsdbDumpfile("sd_rx_fifo_SYN.fsdb");
		$fsdbDumpvars();
	`endif
end

`ifdef RTL
	sd_rx_fifo u_DUT(
		.d(d),
		.wr(wr),
		.wclk(wclk),
		.q(q),
		.rd(rd),
		.full(full),
		.empty(empty),
		.mem_empt(mem_empt),
		.rclk(rclk),
		.rst(rst)
	);
`elsif GATE
	sd_rx_fifo u_DUT(
		.d(d),
		.wr(wr),
		.wclk(wclk),
		.q(q),
		.rd(rd),
		.full(full),
		.empty(empty),
		.mem_empt(mem_empt),
		.rclk(rclk),
		.rst(rst)
	);
`endif

PATTERN u_PATTERN(
		.d(d),
		.wr(wr),
		.wclk(wclk),
		.q_dut(q),
		.rd(rd),
		.full_dut(full),
		.empty_dut(empty),
		.mem_empt_dut(mem_empt),
		.rclk(rclk),
		.rst(rst)
);

endmodule
