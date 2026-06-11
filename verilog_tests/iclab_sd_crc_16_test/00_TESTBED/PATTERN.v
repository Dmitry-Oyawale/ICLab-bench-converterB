module ref_sd_crc_16(BITVAL, Enable, CLK, RST, CRC);
 input        BITVAL;// Next input bit
   input Enable;
   input        CLK;                           // Current bit valid (Clock)
   input        RST;                             // Init CRC value
   output reg [15:0] CRC;                               // Current output CRC value

   
                     // We need output registers
   wire         inv;
   
   assign inv = BITVAL ^ CRC[15];                   // XOR required?
   
  always @(posedge CLK or posedge RST) begin
		if (RST) begin
			CRC <= 0;   
		
        end
      else begin
        if (Enable==1) begin
         CRC[15] <= CRC[14];
         CRC[14] <= CRC[13];
         CRC[13] <= CRC[12];
         CRC[12] <= CRC[11] ^ inv;
         CRC[11] <= CRC[10];
         CRC[10] <= CRC[9];
         CRC[9] <= CRC[8];
         CRC[8] <= CRC[7];
         CRC[7] <= CRC[6];
         CRC[6] <= CRC[5];
         CRC[5] <= CRC[4] ^ inv;
         CRC[4] <= CRC[3];
         CRC[3] <= CRC[2];
         CRC[2] <= CRC[1];
         CRC[1] <= CRC[0];
         CRC[0] <= inv;
        end
         end
      end
   
endmodule

module stimulus_gen (
	input CLK,
	output logic BITVAL, Enable, RST,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	input tb_match
);
	reg reset;
	assign RST = reset;

//	检测reset
	task reset_test(input async=0);
		bit arfail, srfail, datafail;
	
		@(posedge CLK);
		@(posedge CLK) reset = 0;
		repeat(3) @(posedge CLK);
	
		@(negedge CLK) begin datafail = !tb_match ; reset = 1; end
		@(posedge CLK) arfail = !tb_match;
		@(posedge CLK) begin
			srfail = !tb_match;
			reset = 0;
		end
		if (srfail)
			$display("Hint: Your reset doesn't seem to be working.");
		else if (arfail && (async || !datafail))
			$display("Hint: Your reset should be %0s, but doesn't appear to be.", async ? "asynchronous" : "synchronous");
		// Don't warn about synchronous reset if the half-cycle before is already wrong. It's more likely
		// a functionality error than the reset being implemented asynchronously.
	
	endtask

// Add two ports to module stimulus_gen:
//    output [511:0] wavedrom_title
//    output reg wavedrom_enable

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	

	initial begin
		reset = 1'b1;
		wavedrom_start("Asynchronous reset");
		reset_test(1);

		repeat(3) @(posedge CLK);
		{Enable,BITVAL} = 2'b11;
		repeat(3) @(posedge CLK);
		{Enable,BITVAL} = 2'b10;
		repeat(3) @(posedge CLK);
		{Enable,BITVAL} = 2'b01;
		repeat(3) @(posedge CLK);
		{Enable,BITVAL} = 2'b00;
		wavedrom_stop();

		@(posedge CLK);

		repeat(1000) @(posedge CLK, negedge CLK) begin
			{Enable, BITVAL} = $random & $random;
			reset = !($random & 31);
		end
		
		$finish;
	end
	
endmodule

module PATTERN(clk, BITVAL, Enable, CLK, RST, CRC_dut);
    output logic clk;
    output logic BITVAL;
    output logic Enable;
    output logic CLK;
    output logic RST;
    input  logic [15:0] CRC_dut;

    typedef struct packed {
        int errors;
        int errortime;
        int errors_CRC;
        int errortime_CRC;
        int clocks;
    } stats;

    stats stats1;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic [511:0] wavedrom_title;
    logic         wavedrom_enable;
    logic [15:0] CRC_ref;
    wire tb_match_CRC = (CRC_ref === CRC_dut);
    wire tb_match = tb_match_CRC;

    stimulus_gen stim1 (
		.CLK(CLK),
		.BITVAL(BITVAL),
		.reg(reg),
		.wavedrom_enable(wavedrom_enable),
		.tb_match(tb_match)
    );

    ref_sd_crc_16 good1 (
		.BITVAL(BITVAL),
		.Enable(Enable),
		.CLK(CLK),
		.RST(RST),
		.CRC(CRC_ref)
    );

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0);
    end

    always @(posedge clk) begin
        stats1.clocks++;
        if (stats1.clocks > 1 && !tb_match) begin
            if (stats1.errors == 0) stats1.errortime = $time;
            stats1.errors++;
        end
        if (stats1.clocks > 1 && !tb_match_CRC) begin
            if (stats1.errors_CRC == 0) stats1.errortime_CRC = $time;
            stats1.errors_CRC++;
        end
    end

    final begin
        $display("\nTest Results:");
        if (stats1.errors_CRC)
            $display("Hint: Output CRC has %0d mismatches. First at time %0d",
                    stats1.errors_CRC, stats1.errortime_CRC);
        else
            $display("Hint: Output 'CRC' has no mismatches.");
        $display("\nHint: Total mismatched samples is %1d out of %1d samples\n",
                stats1.errors, stats1.clocks);
        $display("Simulation finished at %0d ps", $time);
    end

    initial begin
        #1000000
        $display("TIMEOUT");
        $finish();
    end

endmodule
