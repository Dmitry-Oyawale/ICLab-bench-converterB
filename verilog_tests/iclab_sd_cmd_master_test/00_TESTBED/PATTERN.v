`include "sd_defines.v"
module ref_sd_cmd_master(
input CLK_PAD_IO,

input RST_PAD_I,
input New_CMD,
input data_write,
input data_read,



input [31:0] ARG_REG,
input [13:0] CMD_SET_REG,
input [15:0] TIMEOUT_REG,
output reg [15:0] STATUS_REG,
output reg [31:0] RESP_1_REG,

output reg [4:0] ERR_INT_REG, 
output reg [15:0] NORMAL_INT_REG, 
input ERR_INT_RST,
input NORMAL_INT_RST,

output reg [15:0] settings,
output reg go_idle_o,
output reg  [39:0] cmd_out,
output reg req_out,
output reg ack_out,
input req_in,
input ack_in,
input [39:0] cmd_in,
input [7:0] serial_status,
input card_detect
);
 


`define dat_ava status[6]
`define crc_valid status[5] 
`define small_rsp 7'b0101000
`define big_rsp 7'b1111111

`define CMDI CMD_SET_REG[13:8]
`define WORD_SELECT CMD_SET_REG[7:6]
`define CICE CMD_SET_REG[4]
`define CRCE CMD_SET_REG[3]
`define RTS CMD_SET_REG[1:0]
`define CTE ERR_INT_REG[0]
`define CCRCE ERR_INT_REG[1]
`define CIE  ERR_INT_REG[3]
`define EI NORMAL_INT_REG[15]
`define CC  NORMAL_INT_REG[0]
`define CICMD STATUS_REG[0]
             

//-----------Types--------------------------------------------------------

reg CRC_check_enable;
reg index_check_enable;
reg [6:0]response_size;


reg card_present;


reg [3:0]debounce;

reg [15:0]status;
reg [15:0]  Watchdog_Cnt;
reg complete;



parameter SIZE = 3;
reg [SIZE-1:0] state;
reg [SIZE-1:0] next_state;

parameter IDLE   =  3'b001;
parameter SETUP   =  3'b010;
parameter EXECUTE  =  3'b100;
reg ack_in_int;
reg ack_q;
reg req_q;
reg req_in_int;

always @ (posedge CLK_PAD_IO or posedge RST_PAD_I   )
begin
  if (RST_PAD_I) begin
    req_q<=0;
    req_in_int<=0;
 end 
else begin
  req_q<=req_in;  
  req_in_int<=req_q;
end
end  

//---------------Input ports---------------


always @ (posedge CLK_PAD_IO or posedge RST_PAD_I   )
begin
  if (RST_PAD_I) begin
    debounce<=0;
    card_present<=0;
 end 
else begin
	if (!card_detect) begin//Card present
		if (debounce!=4'b1111)
			debounce<=debounce+1'b1;
	end
	else	
		 debounce<=0;

	if (debounce==4'b1111)
       card_present<=1'b1;
	else 
	   card_present<=1'b0;
end
end  



always @ (posedge CLK_PAD_IO or posedge RST_PAD_I   )
begin
  if (RST_PAD_I) begin
    ack_q<=0;
    ack_in_int<=0;
 end 
else begin
  ack_q<=ack_in;
  ack_in_int<=ack_q;
end
  
  
end



always @ ( state or New_CMD or complete or ack_in_int )
begin : FSM_COMBO
    next_state = 0;

 case(state)
 IDLE:   begin
      if (New_CMD) begin
          next_state = SETUP;
      end     
      else begin
         next_state = IDLE;
      end   
 end       
 SETUP:begin
    if (ack_in_int)             
       next_state = EXECUTE;  
     else   
       next_state = SETUP;
   end  
 EXECUTE:    begin
       if (complete) begin
          next_state = IDLE;
      end     
      else begin
         next_state = EXECUTE;
      end
 end       
   
  
 default : next_state  = IDLE;
 
 endcase 
    
end

 
 

always @ (posedge CLK_PAD_IO or posedge RST_PAD_I   )
begin : FSM_SEQ
  if (RST_PAD_I ) begin
    state <= #1 IDLE;
 end 
 else begin
    state <= #1 next_state;
 end
end



always @ (posedge CLK_PAD_IO or posedge RST_PAD_I   )
begin  
 if (RST_PAD_I ) begin 
    CRC_check_enable=0;
    complete =0;
    RESP_1_REG = 0;
 
    ERR_INT_REG =0;
    NORMAL_INT_REG=0;
    STATUS_REG=0;
    status=0; 
    cmd_out =0 ;
    settings=0;
    response_size=0;
    req_out=0;
    index_check_enable=0; 
    ack_out=0; 
    Watchdog_Cnt=0;
    
    `CCRCE=0;
    `EI = 0;
    `CC = 0; 
     go_idle_o=0;  
 end 
 else begin
 NORMAL_INT_REG[1] = card_present;
 NORMAL_INT_REG[2] = ~card_present;
 complete=0;
 case(state)
 IDLE: begin
    go_idle_o=0;  
    req_out=0;
		ack_out =0;
		`CICMD =0; 
    if ( req_in_int == 1) begin     //Status change
        status=serial_status;
        ack_out = 1;
      
        
    end
 end
 SETUP:  begin
     
     NORMAL_INT_REG=0; 
     ERR_INT_REG =0;
  
     index_check_enable = `CICE; 
     CRC_check_enable = `CRCE;
    
    if ( (`RTS  == 2'b10 ) || ( `RTS == 2'b11)) begin
      response_size =  7'b0101000; 
    end
    else if (`RTS == 2'b01) begin
      response_size = 7'b1111111; 
    end    
    else begin
       response_size=0;
    end    
    
    cmd_out[39:38]=2'b01;         
    cmd_out[37:32]=`CMDI;  //CMD_INDEX
    cmd_out[31:0]= ARG_REG;           //CMD_Argument      
    settings[14:13]=`WORD_SELECT;             //Reserved
    settings[12] = data_read; //Type of command
    settings[11] = data_write;
    settings[10:8]=3'b111;            //Delay
    settings[7]=`CRCE;         //CRC-check
    settings[6:0]=response_size;   //response size    
    Watchdog_Cnt = 0;
    
    `CICMD =1;    
 end   
 
 EXECUTE: begin   
    Watchdog_Cnt = Watchdog_Cnt +1;
    if (Watchdog_Cnt>TIMEOUT_REG) begin
      `CTE=1;
      `EI = 1;
      if (ack_in == 1) begin
         complete=1;
      end   
      go_idle_o=1; 
    end
    
    //Default
    req_out=0;
		ack_out =0;
    
    //Start sending when serial module is ready
   	if (ack_in_int == 1) begin	    	     
	    		req_out =1;	   			   		
	  end	
	   //Incoming New Status 
	  else if ( req_in_int == 1) begin   
        status=serial_status;
      
        ack_out = 1; 
        if ( `dat_ava ) begin //Data avaible
           complete=1;
            `EI = 0;
             
           if (CRC_check_enable & ~`crc_valid) begin 
            `CCRCE=1;
            `EI = 1;
             
           end 
           if (index_check_enable &  (cmd_out[37:32] != cmd_in [37:32]) ) begin
            `CIE=1;
            `EI = 1;
            
           end
          
             
             `CC = 1;  
            
             if (response_size !=0)
              RESP_1_REG=cmd_in[31:0];
            
          // end 
         end ////Data avaible
       end //Status change
     end //EXECUTE state
   endcase
   if (ERR_INT_RST)
     ERR_INT_REG=0;
   if (NORMAL_INT_RST)
     NORMAL_INT_REG=0;
  end
end

endmodule

module stimulus_gen (
	input CLK_PAD_IO,

	output logic RST_PAD_I, New_CMD, 
    output logic data_write, data_read, 
    output logic ERR_INT_RST, NORMAL_INT_RST, 
    output logic req_in, ack_in, card_detect,

    output [31:0] ARG_REG,
    output [13:0] CMD_SET_REG,
    output [15:0] TIMEOUT_REG,
    output [39:0] cmd_in,
    output [7:0] serial_status,

	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable,
	tb_match
);
	reg reset;
	assign RST_PAD_I = reset;


	task reset_test(async=0);
		bit arfail, srfail, datafail;
	
		@(posedge CLK_PAD_IO);
		@(posedge CLK_PAD_IO) reset = 0;
		repeat(3) @(posedge CLK_PAD_IO);
	
		@(negedge CLK_PAD_IO) begin datafail = !tb_match ; reset = 1; end
		@(posedge CLK_PAD_IO) arfail = !tb_match;
		@(posedge CLK_PAD_IO) begin
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
		repeat(3)@(posedge CLK_PAD_IO) reset = 0;
		repeat(3)@(posedge CLK_PAD_IO) reset = 1;
		New_CMD = 0;
		data_write = 0;
		data_read = 0;
		ERR_INT_RST = 0;
		NORMAL_INT_RST = 0;
		req_in = 0;
		ack_in = 0;
		card_detect = 0;
		cmd_in = 0;
		serial_status = 0;
		ARG_REG = 0;
		CMD_SET_REG = 0;
		TIMEOUT_REG = 0;

		repeat(3)@(posedge CLK_PAD_IO) reset = 0;

		wavedrom_start("Asynchronous reset");
		reset_test(1);
		wavedrom_stop();


		repeat(10)@(posedge CLK_PAD_IO) reset = 1;
		repeat(10)@(posedge CLK_PAD_IO) reset = 0;
		repeat(10)@(posedge CLK_PAD_IO) TIMEOUT_REG = 15'h10;
		repeat(10)@(posedge CLK_PAD_IO) New_CMD = 1;
		repeat(10)@(posedge CLK_PAD_IO) ack_in = 1;
		repeat(10)@(posedge CLK_PAD_IO) ack_in = 0;
		repeat(10)@(posedge CLK_PAD_IO) ack_in = 1;
		repeat(10)@(posedge CLK_PAD_IO) ERR_INT_RST= 1;
		repeat(10)@(posedge CLK_PAD_IO) NORMAL_INT_RST=1;


        @(posedge CLK_PAD_IO);
		repeat(5000) @(posedge CLK_PAD_IO, negedge CLK_PAD_IO) begin
			New_CMD = ($random%2);
            data_write = ($random%2);
            data_read = ($random%2);
            ERR_INT_RST = ($random%2);
            NORMAL_INT_RST = ($random%2);
            req_in = ($random%2);
            ack_in = ($random%2);
            card_detect = ($random%2);

            ARG_REG = $random;
            CMD_SET_REG = $random;
            TIMEOUT_REG = $random;
            cmd_in = {$random, ($random)[7:0]};
            serial_status = $random;
			reset = !($random & 31);
		end
		
		#1 $finish;
	end
	
endmodule

module PATTERN(clk, CLK_PAD_IO, RST_PAD_I, New_CMD, data_write, data_read, ARG_REG, CMD_SET_REG, TIMEOUT_REG, ERR_INT_RST, NORMAL_INT_RST, req_in, ack_in, cmd_in, serial_status, card_detect, STATUS_REG_dut, RESP_1_REG_dut, ERR_INT_REG_dut, NORMAL_INT_REG_dut, settings_dut, go_idle_o_dut, cmd_out_dut, req_out_dut, ack_out_dut);
    output logic clk;
    output logic CLK_PAD_IO;
    output logic RST_PAD_I;
    output logic New_CMD;
    output logic data_write;
    output logic data_read;
    output logic [31:0] ARG_REG;
    output logic [13:0] CMD_SET_REG;
    output logic [15:0] TIMEOUT_REG;
    output logic ERR_INT_RST;
    output logic NORMAL_INT_RST;
    output logic req_in;
    output logic ack_in;
    output logic [39:0] cmd_in;
    output logic [7:0] serial_status;
    output logic card_detect;
    input  logic [15:0] STATUS_REG_dut;
    input  logic [31:0] RESP_1_REG_dut;
    input  logic [4:0] ERR_INT_REG_dut;
    input  logic [15:0] NORMAL_INT_REG_dut;
    input  logic [15:0] settings_dut;
    input  logic go_idle_o_dut;
    input  logic [39:0] cmd_out_dut;
    input  logic req_out_dut;
    input  logic ack_out_dut;

    typedef struct packed {
        int errors;
        int errortime;
        int errors_STATUS_REG;
        int errortime_STATUS_REG;
        int errors_RESP_1_REG;
        int errortime_RESP_1_REG;
        int errors_ERR_INT_REG;
        int errortime_ERR_INT_REG;
        int errors_NORMAL_INT_REG;
        int errortime_NORMAL_INT_REG;
        int errors_settings;
        int errortime_settings;
        int errors_go_idle_o;
        int errortime_go_idle_o;
        int errors_cmd_out;
        int errortime_cmd_out;
        int errors_req_out;
        int errortime_req_out;
        int errors_ack_out;
        int errortime_ack_out;
        int clocks;
    } stats;

    stats stats1;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic [511:0] wavedrom_title;
    logic         wavedrom_enable;
    logic [15:0] STATUS_REG_ref;
    logic [31:0] RESP_1_REG_ref;
    logic [4:0] ERR_INT_REG_ref;
    logic [15:0] NORMAL_INT_REG_ref;
    logic [15:0] settings_ref;
    logic go_idle_o_ref;
    logic [39:0] cmd_out_ref;
    logic req_out_ref;
    logic ack_out_ref;
    wire tb_match_STATUS_REG = (STATUS_REG_ref === STATUS_REG_dut);
    wire tb_match_RESP_1_REG = (RESP_1_REG_ref === RESP_1_REG_dut);
    wire tb_match_ERR_INT_REG = (ERR_INT_REG_ref === ERR_INT_REG_dut);
    wire tb_match_NORMAL_INT_REG = (NORMAL_INT_REG_ref === NORMAL_INT_REG_dut);
    wire tb_match_settings = (settings_ref === settings_dut);
    wire tb_match_go_idle_o = (go_idle_o_ref === go_idle_o_dut);
    wire tb_match_cmd_out = (cmd_out_ref === cmd_out_dut);
    wire tb_match_req_out = (req_out_ref === req_out_dut);
    wire tb_match_ack_out = (ack_out_ref === ack_out_dut);
    wire tb_match = tb_match_STATUS_REG & tb_match_RESP_1_REG & tb_match_ERR_INT_REG & tb_match_NORMAL_INT_REG & tb_match_settings & tb_match_go_idle_o & tb_match_cmd_out & tb_match_req_out & tb_match_ack_out;

    stimulus_gen stim1 (
		.CLK_PAD_IO(CLK_PAD_IO),
		.RST_PAD_I(RST_PAD_I),
		.data_write(data_write),
		.ERR_INT_RST(ERR_INT_RST),
		.req_in(req_in),
		.ARG_REG(ARG_REG),
		.CMD_SET_REG(CMD_SET_REG),
		.TIMEOUT_REG(TIMEOUT_REG),
		.cmd_in(cmd_in),
		.serial_status(serial_status),
		.reg(reg),
		.wavedrom_enable(wavedrom_enable)
    );

    ref_sd_cmd_master good1 (
		.CLK_PAD_IO(CLK_PAD_IO),
		.RST_PAD_I(RST_PAD_I),
		.New_CMD(New_CMD),
		.data_write(data_write),
		.data_read(data_read),
		.ARG_REG(ARG_REG),
		.CMD_SET_REG(CMD_SET_REG),
		.TIMEOUT_REG(TIMEOUT_REG),
		.STATUS_REG(STATUS_REG_ref),
		.RESP_1_REG(RESP_1_REG_ref),
		.ERR_INT_REG(ERR_INT_REG_ref),
		.NORMAL_INT_REG(NORMAL_INT_REG_ref),
		.ERR_INT_RST(ERR_INT_RST),
		.NORMAL_INT_RST(NORMAL_INT_RST),
		.settings(settings_ref),
		.go_idle_o(go_idle_o_ref),
		.cmd_out(cmd_out_ref),
		.req_out(req_out_ref),
		.ack_out(ack_out_ref),
		.req_in(req_in),
		.ack_in(ack_in),
		.cmd_in(cmd_in),
		.serial_status(serial_status),
		.card_detect(card_detect)
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
        if (stats1.clocks > 1 && !tb_match_STATUS_REG) begin
            if (stats1.errors_STATUS_REG == 0) stats1.errortime_STATUS_REG = $time;
            stats1.errors_STATUS_REG++;
        end
        if (stats1.clocks > 1 && !tb_match_RESP_1_REG) begin
            if (stats1.errors_RESP_1_REG == 0) stats1.errortime_RESP_1_REG = $time;
            stats1.errors_RESP_1_REG++;
        end
        if (stats1.clocks > 1 && !tb_match_ERR_INT_REG) begin
            if (stats1.errors_ERR_INT_REG == 0) stats1.errortime_ERR_INT_REG = $time;
            stats1.errors_ERR_INT_REG++;
        end
        if (stats1.clocks > 1 && !tb_match_NORMAL_INT_REG) begin
            if (stats1.errors_NORMAL_INT_REG == 0) stats1.errortime_NORMAL_INT_REG = $time;
            stats1.errors_NORMAL_INT_REG++;
        end
        if (stats1.clocks > 1 && !tb_match_settings) begin
            if (stats1.errors_settings == 0) stats1.errortime_settings = $time;
            stats1.errors_settings++;
        end
        if (stats1.clocks > 1 && !tb_match_go_idle_o) begin
            if (stats1.errors_go_idle_o == 0) stats1.errortime_go_idle_o = $time;
            stats1.errors_go_idle_o++;
        end
        if (stats1.clocks > 1 && !tb_match_cmd_out) begin
            if (stats1.errors_cmd_out == 0) stats1.errortime_cmd_out = $time;
            stats1.errors_cmd_out++;
        end
        if (stats1.clocks > 1 && !tb_match_req_out) begin
            if (stats1.errors_req_out == 0) stats1.errortime_req_out = $time;
            stats1.errors_req_out++;
        end
        if (stats1.clocks > 1 && !tb_match_ack_out) begin
            if (stats1.errors_ack_out == 0) stats1.errortime_ack_out = $time;
            stats1.errors_ack_out++;
        end
    end

    final begin
        $display("\nTest Results:");
        if (stats1.errors_STATUS_REG)
            $display("Hint: Output STATUS_REG has %0d mismatches. First at time %0d",
                    stats1.errors_STATUS_REG, stats1.errortime_STATUS_REG);
        else
            $display("Hint: Output 'STATUS_REG' has no mismatches.");
        if (stats1.errors_RESP_1_REG)
            $display("Hint: Output RESP_1_REG has %0d mismatches. First at time %0d",
                    stats1.errors_RESP_1_REG, stats1.errortime_RESP_1_REG);
        else
            $display("Hint: Output 'RESP_1_REG' has no mismatches.");
        if (stats1.errors_ERR_INT_REG)
            $display("Hint: Output ERR_INT_REG has %0d mismatches. First at time %0d",
                    stats1.errors_ERR_INT_REG, stats1.errortime_ERR_INT_REG);
        else
            $display("Hint: Output 'ERR_INT_REG' has no mismatches.");
        if (stats1.errors_NORMAL_INT_REG)
            $display("Hint: Output NORMAL_INT_REG has %0d mismatches. First at time %0d",
                    stats1.errors_NORMAL_INT_REG, stats1.errortime_NORMAL_INT_REG);
        else
            $display("Hint: Output 'NORMAL_INT_REG' has no mismatches.");
        if (stats1.errors_settings)
            $display("Hint: Output settings has %0d mismatches. First at time %0d",
                    stats1.errors_settings, stats1.errortime_settings);
        else
            $display("Hint: Output 'settings' has no mismatches.");
        if (stats1.errors_go_idle_o)
            $display("Hint: Output go_idle_o has %0d mismatches. First at time %0d",
                    stats1.errors_go_idle_o, stats1.errortime_go_idle_o);
        else
            $display("Hint: Output 'go_idle_o' has no mismatches.");
        if (stats1.errors_cmd_out)
            $display("Hint: Output cmd_out has %0d mismatches. First at time %0d",
                    stats1.errors_cmd_out, stats1.errortime_cmd_out);
        else
            $display("Hint: Output 'cmd_out' has no mismatches.");
        if (stats1.errors_req_out)
            $display("Hint: Output req_out has %0d mismatches. First at time %0d",
                    stats1.errors_req_out, stats1.errortime_req_out);
        else
            $display("Hint: Output 'req_out' has no mismatches.");
        if (stats1.errors_ack_out)
            $display("Hint: Output ack_out has %0d mismatches. First at time %0d",
                    stats1.errors_ack_out, stats1.errortime_ack_out);
        else
            $display("Hint: Output 'ack_out' has no mismatches.");
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
