//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   ICLAB 2025 Fall 
// Lab11 Exercise : Geometric Transform Engine (GTE)
//      File Name : GTE.v
//    Module Name : GTE
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "aes_cipher_top.v"
`elsif GATE
    `include "aes_cipher_top_SYN.v"
`endif

	  		  	
module TESTBED;



wire          clk;
wire          rst;
wire          ld;
wire          done;
wire  [127:0]  key;
wire  [127:0]  text_in;
wire  [127:0]  text_out;

initial begin
	`ifdef RTL
		$fsdbDumpfile("aes_cipher_top.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("aes_cipher_top_SYN.sdf", u_AES);
		$fsdbDumpfile("aes_cipher_top_SYN.fsdb");
		$fsdbDumpvars();  // 指定要 dump 的模組
	`endif
end

`ifdef RTL
	aes_cipher_top u_AES(
		// input signals
		.clk(clk),
		.rst(rst),
		.ld(ld),
		.done(done),
		.key(key),
		.text_in(text_in),
		.text_out(text_out)
	);
`elsif GATE
	aes_cipher_top u_AES(
		// input signals
		.clk(clk),
		.rst(rst),
		.ld(ld),
		.done(done),
		.key(key),
		.text_in(text_in),
		.text_out(text_out)
	);
`endif

PATTERN u_PATTERN(
    .clk(clk),
	.rst(rst),
	.ld(ld),
	.done_dut(done),
	.key(key),
	.text_in(text_in),
	.text_out_dut(text_out)
);
 
endmodule
