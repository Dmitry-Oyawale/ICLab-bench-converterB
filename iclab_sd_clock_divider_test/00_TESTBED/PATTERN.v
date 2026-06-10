module ref_sd_clock_divider (
  input wire CLK,
  input wire [7:0] DIVIDER,
  input wire RST,
  output  SD_CLK 
  );
  
  reg [7:0] ClockDiv;
  reg SD_CLK_O;
`ifdef SYN
  `ifdef ACTEL
  CLKINT CLKA
  (.A (SD_CLK_O),
   .Y (SD_CLK) 
   );
   `endif
 `endif
 
 `ifdef SIM
   assign SD_CLK = SD_CLK_O;
`endif 
 
always @ (posedge CLK or posedge RST)
begin
 if (RST) begin
    ClockDiv <=8'b0000_0000;
    SD_CLK_O  <= 0;
 end 
 else if (ClockDiv == DIVIDER )begin
    ClockDiv  <= 0;
    SD_CLK_O <=  ~SD_CLK_O;
 end else begin
    ClockDiv  <= ClockDiv + 1;
    SD_CLK_O <=  SD_CLK_O;
end
 
end
 endmodule

module stimulus_gen (
    input wire clk,
    output logic [7:0] DIVIDER,
    output logic RST
);

    // Clock period definition for the simulation
    localparam CLK_PERIOD = 10; // 10 time units for the clock period

    // Stimulus generation
    initial begin
        // Initial values
        DIVIDER = 8'd0;
        RST = 1'b1; // Start with reset asserted

        // Wait for a few clock cycles with reset asserted
        #(CLK_PERIOD * 3);

        // Deassert reset
        RST = 1'b0;

        // Wait for a few clock cycles before changing DIVIDER
        #(CLK_PERIOD * 5);

        // Test various divider values
        repeat (5) begin
            DIVIDER = $urandom_range(1, 255); // Random divider value
            #(CLK_PERIOD * 1000); // Wait for some cycles to see the effect
        end

        // Test reset functionality
        RST = 1'b1;
        #(CLK_PERIOD * 3);
        RST = 1'b0;

        // Randomly change divider and reset
        repeat (20) begin
            DIVIDER = $urandom_range(1, 255);
            RST = $urandom_range(0, 1);
            #(CLK_PERIOD * $urandom_range(1, 10));
        end

        // Finish the simulation
        $finish;
    end

endmodule

module PATTERN(clk, CLK, DIVIDER, RST, SD_CLK_dut);
    output logic clk;
    output logic CLK;
    output logic [7:0] DIVIDER;
    output logic RST;
    input  logic SD_CLK_dut;

    typedef struct packed {
        int errors;
        int errortime;
        int errors_SD_CLK;
        int errortime_SD_CLK;
        int clocks;
    } stats;

    stats stats1;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic [511:0] wavedrom_title;
    logic         wavedrom_enable;
    logic SD_CLK_ref;
    wire tb_match_SD_CLK = (SD_CLK_ref === SD_CLK_dut);
    wire tb_match = tb_match_SD_CLK;

    stimulus_gen stim1 (
		.clk(clk),
		.DIVIDER(DIVIDER),
		.RST(RST)
    );

    ref_sd_clock_divider good1 (
		.CLK(CLK),
		.DIVIDER(DIVIDER),
		.RST(RST),
		.SD_CLK(SD_CLK_ref)
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
        if (stats1.clocks > 1 && !tb_match_SD_CLK) begin
            if (stats1.errors_SD_CLK == 0) stats1.errortime_SD_CLK = $time;
            stats1.errors_SD_CLK++;
        end
    end

    final begin
        $display("\nTest Results:");
        if (stats1.errors_SD_CLK)
            $display("Hint: Output SD_CLK has %0d mismatches. First at time %0d",
                    stats1.errors_SD_CLK, stats1.errortime_SD_CLK);
        else
            $display("Hint: Output 'SD_CLK' has no mismatches.");
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
