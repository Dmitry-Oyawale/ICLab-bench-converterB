module ref_sd_controller_wb(
  wb_clk_i, wb_rst_i, wb_dat_i, wb_dat_o, 

  // WISHBONE slave
  wb_adr_i, wb_sel_i, wb_we_i, wb_cyc_i, wb_stb_i, wb_ack_o, 

  // WISHBONE master

 
  we_m_tx_bd, new_cmd,
  we_m_rx_bd, 
  we_ack, int_ack, cmd_int_busy,
  Bd_isr_reset,
  normal_isr_reset,
  error_isr_reset,
  int_busy,
  dat_in_m_tx_bd,
  dat_in_m_rx_bd,
  write_req_s,
  cmd_set_s,
  cmd_arg_s,
  argument_reg,
  cmd_setting_reg,
  status_reg,
  cmd_resp_1,
  software_reset_reg,
  time_out_reg,
  normal_int_status_reg,
  error_int_status_reg,
  normal_int_signal_enable_reg,
  error_int_signal_enable_reg,
  clock_divider,
  Bd_Status_reg,
  Bd_isr_reg,
  Bd_isr_enable_reg
  );
  
  // WISHBONE common
input           wb_clk_i;     // WISHBONE clock
input           wb_rst_i;     // WISHBONE reset
input   [31:0]  wb_dat_i;     // WISHBONE data input
output reg [31:0]  wb_dat_o;     // WISHBONE data output
     // WISHBONE error output

// WISHBONE slave
input   [7:0]  wb_adr_i;     // WISHBONE address input
input    [3:0]  wb_sel_i;     // WISHBONE byte select input
input           wb_we_i;      // WISHBONE write enable input
input           wb_cyc_i;     // WISHBONE cycle input
input           wb_stb_i;     // WISHBONE strobe input

output reg         wb_ack_o;     // WISHBONE acknowledge output


  
output reg we_m_tx_bd;

output reg new_cmd;
output reg we_ack; //CMD acces granted 
output reg int_ack; //Internal Delayed Ack;
output reg cmd_int_busy;

output reg we_m_rx_bd; //Write enable Master side Rx_bd
  //Read enable Master side Rx_bd
output reg int_busy;
input write_req_s;
input wire [15:0] cmd_set_s;
input wire [31:0] cmd_arg_s;


//
`define SUPPLY_VOLTAGE_3_3
`define SD_CARD_2_0

//Register Addreses 
`define argument 8'h00
`define command 8'h04
`define status 8'h08
`define resp1 8'h0c
`define controller 8'h1c
`define block 8'h20
`define power 8'h24
`define software 8'h28
`define timeout 8'h2c  
`define normal_isr 8'h30   
`define error_isr 8'h34  
`define normal_iser 8'h38
`define error_iser 8'h3c
`define capa 8'h48
`define clock_d 8'h4c
`define bd_status 8'h50
`define bd_isr 8'h54 
`define bd_iser 8'h58 
`define bd_rx 8'h60  
`define bd_tx 8'h80  



`ifdef SUPPLY_VOLTAGE_3_3
   parameter power_controll_reg  = 8'b0000_111_1;
`elsif SUPPLY_VOLTAGE_3_0
   parameter power_controll_reg  = 8'b0000_110_1;
`elsif SUPPLY_VOLTAGE_1_8
   parameter power_controll_reg  = 8'b0000_101_1;
`endif 

parameter block_size_reg = `BLOCK_SIZE ; //512-Bytes

`ifdef SD_BUS_WIDTH_4
     parameter controll_setting_reg =16'b0000_0000_0000_0010;
`else  
     parameter controll_setting_reg =16'b0000_0000_0000_0000;
`endif
     parameter capabilies_reg =16'b0000_0000_0000_0000;
   
//Buss accessible registers    
output reg [31:0] argument_reg;
output reg [15:0] cmd_setting_reg;
input  wire [15:0] status_reg;
input wire [31:0] cmd_resp_1;
output reg [7:0] software_reset_reg; 
output reg [15:0] time_out_reg;   
input wire [15:0]normal_int_status_reg; 
input wire [15:0]error_int_status_reg;
output reg [15:0]normal_int_signal_enable_reg;
output reg [15:0]error_int_signal_enable_reg;
output reg [7:0] clock_divider;
input  wire [15:0] Bd_Status_reg;   
input  wire [7:0] Bd_isr_reg;
output reg [7:0] Bd_isr_enable_reg;

//Register Controll
output reg Bd_isr_reset;
output reg normal_isr_reset;
output reg error_isr_reset;
output reg [`RAM_MEM_WIDTH-1:0] dat_in_m_rx_bd; //Data in to Rx_bd from Master
output reg [`RAM_MEM_WIDTH-1:0] dat_in_m_tx_bd;


//internal reg
reg [1:0] we;


always @(posedge wb_clk_i or posedge wb_rst_i)
	begin
	  we_m_rx_bd <= 0;
   	  we_m_tx_bd <= 0;
	  new_cmd<= 1'b0 ;
	  we_ack <= 0;
	  int_ack =  1;
	  cmd_int_busy<=0;
     if ( wb_rst_i )begin
	    argument_reg <=0;
        cmd_setting_reg <= 0;
	    software_reset_reg <= 0;
	    time_out_reg <= 0;
	    normal_int_signal_enable_reg <= 0;
	    error_int_signal_enable_reg <= 0;	  
	    clock_divider <=`RESET_CLK_DIV;
	    int_ack=1 ;
	    we<=0;
	    int_busy <=0;
	    we_ack <=0;
	    wb_ack_o=0;
	    cmd_int_busy<=0;
	    Bd_isr_reset<=0;
	    dat_in_m_tx_bd<=0;
	    dat_in_m_rx_bd<=0;
	    Bd_isr_enable_reg<=0;
	    normal_isr_reset<=0;
	    error_isr_reset<=0;
	  end
	  else begin
		if ((wb_stb_i  & wb_cyc_i) || wb_ack_o )begin 
	    Bd_isr_reset<=0; 
	    normal_isr_reset<=  0;
	    error_isr_reset<=  0;
	    if (wb_we_i) begin
	      case (wb_adr_i) 
	        `argument: begin  
	            argument_reg  <=  wb_dat_i;
	            new_cmd <=  1'b1 ;	            
	         end
	        `command : begin 
	            cmd_setting_reg  <=  wb_dat_i;
	            int_busy <= 1;
	        end
          `software : software_reset_reg <=  wb_dat_i;
          `timeout : time_out_reg  <=  wb_dat_i;
          `normal_iser : normal_int_signal_enable_reg <=  wb_dat_i;
          `error_iser : error_int_signal_enable_reg  <=  wb_dat_i;
          `normal_isr : normal_isr_reset<=  1;
          `error_isr:  error_isr_reset<=  1;
	        `clock_d: clock_divider  <=  wb_dat_i;
	        `bd_isr: Bd_isr_reset<=  1;	    
	        `bd_iser : Bd_isr_enable_reg <= wb_dat_i ;     
	        `ifdef RAM_MEM_WIDTH_32
	          `bd_rx: begin
	             we <= we+1;	           
	             we_m_rx_bd <= 1;
	             int_ack =  0;	
	           if  (we[1:0]==2'b00)
	             we_m_rx_bd <= 0;
	           else if  (we[1:0]==2'b01) 
	            dat_in_m_rx_bd <=  wb_dat_i;	                   
	           else begin
	              int_ack =  1; 
	              we<= 0;
	              we_m_rx_bd <= 0;
	            end
	           
	        end
	        `bd_tx: begin
	           we <= we+1;	           
	           we_m_tx_bd <= 1;
	           int_ack =  0;	
	           if  (we[1:0]==2'b00)
	             we_m_tx_bd <= 0;
	           else if  (we[1:0]==2'b01) 
	            dat_in_m_tx_bd <=  wb_dat_i;                   
	           else begin
	             int_ack =  1; 
	              we<= 0;
	              we_m_tx_bd <= 0;
	            end
	        end
	        
	        `endif
	        `ifdef RAM_MEM_WIDTH_16
	        `bd_rx: begin
	             we <= we+1;	           
	             we_m_rx_bd <= 1;
	             int_ack =  0;	
	           if  (we[1:0]==2'b00)
	             we_m_rx_bd <= 0;
	           else if  (we[1:0]==2'b01) 
	            dat_in_m_rx_bd <=  wb_dat_i[15:0];	                    
	           else if ( we[1:0]==2'b10) 
	             dat_in_m_rx_bd <=  wb_dat_i[31:16];	            
	           else begin
	             int_ack =  1; 
	              we<= 0;
	              we_m_rx_bd <= 0;
	            end
	           
	        end
	        `bd_tx: begin
	           we <= we+1;	           
	           we_m_tx_bd <= 1;
	           int_ack =  0;	
	           if  (we[1:0]==2'b00)
	             we_m_tx_bd <= 0;
	           else if  (we[1:0]==2'b01) 
	            dat_in_m_tx_bd <=  wb_dat_i[15:0];	                    
	           else if ( we[1:0]==2'b10) 
	             dat_in_m_tx_bd <=  wb_dat_i[31:16];	            
	           else begin
	             int_ack =  1; 
	              we<= 0;
	              we_m_tx_bd <= 0;
	            end
	        end
	        `endif
	        
	      endcase
	    end     	     
	wb_ack_o =   wb_cyc_i & wb_stb_i & ~wb_ack_o & int_ack; 
	 end
	    else if (write_req_s) begin
	       new_cmd <=  1'b1 ; 
	       cmd_setting_reg <=   cmd_set_s; 
	       argument_reg  <=  cmd_arg_s ; 
	       cmd_int_busy<=  1; 
	       we_ack <= 1;
	    end  
	 
	 if (status_reg[0])
	    int_busy <=  0; 
	  end
	//wb_ack_o =   wb_cyc_i & wb_stb_i & ~wb_ack_o & int_ack; 
end

always @(posedge wb_clk_i )begin
   if (wb_stb_i  & wb_cyc_i) begin //CS
      case (wb_adr_i)
	         `argument:  wb_dat_o  <=   argument_reg ;
	         `command : wb_dat_o <=  cmd_setting_reg ;
	         `status : wb_dat_o <=  status_reg ;
           `resp1 : wb_dat_o <=  cmd_resp_1 ;   
           
           `controller : wb_dat_o <=  controll_setting_reg ;
           `block :  wb_dat_o <=  block_size_reg ;
           `power : wb_dat_o <=  power_controll_reg ;
           `software : wb_dat_o  <=  software_reset_reg ;
           `timeout : wb_dat_o  <=  time_out_reg ;
           `normal_isr : wb_dat_o <=  normal_int_status_reg ;
           `error_isr : wb_dat_o  <=  error_int_status_reg ;
           `normal_iser : wb_dat_o <=  normal_int_signal_enable_reg ;
           `error_iser : wb_dat_o  <=  error_int_signal_enable_reg ;
            `clock_d : wb_dat_o  <= clock_divider;
	         `capa  : wb_dat_o  <=  capabilies_reg ; 
	         `bd_status : wb_dat_o  <=  Bd_Status_reg; 
	         `bd_isr : wb_dat_o  <=  Bd_isr_reg ; 
	         `bd_iser : wb_dat_o  <=  Bd_isr_enable_reg ; 
	    endcase
	  end 
end

  
  
endmodule

module stimulus_gen (
    input wire clk,
    // WISHBONE common
    output logic           wb_clk_i,     // WISHBONE clock
    output logic           wb_rst_i,     // WISHBONE reset
    output logic   [31:0]  wb_dat_i,     // WISHBONE data input

    // WISHBONE slave
    output logic   [7:0]  wb_adr_i,     // WISHBONE address input
    output logic    [3:0]  wb_sel_i,     // WISHBONE byte select input
    output logic           wb_we_i,      // WISHBONE write enable input
    output logic           wb_cyc_i,     // WISHBONE cycle input
    output logic           wb_stb_i,     // WISHBONE strobe input

    //Read enable Master side Rx_bd
    output logic write_req_s,
    output logic [15:0] cmd_set_s,
    output logic [31:0] cmd_arg_s,

    //Buss accessible registers    
    output logic [15:0] status_reg,
    output logic [31:0] cmd_resp_1,
    output logic [15:0]normal_int_status_reg, 
    output logic [15:0]error_int_status_reg,
    output logic [15:0] Bd_Status_reg,   
    output logic [7:0] Bd_isr_reg
);

// register adress
`define argument 8'h00
`define command 8'h04
`define status 8'h08
`define resp1 8'h0c
`define controller 8'h1c
`define block 8'h20
`define power 8'h24
`define software 8'h28
`define timeout 8'h2c  
`define normal_isr 8'h30   
`define error_isr 8'h34  
`define normal_iser 8'h38
`define error_iser 8'h3c
`define capa 8'h48
`define clock_d 8'h4c
`define bd_status 8'h50
`define bd_isr 8'h54 
`define bd_iser 8'h58 
`define bd_rx 8'h60  
`define bd_tx 8'h80  

logic [7:0] all_registers[] = {
    `argument, `command, `status, `resp1, `controller, `block,
    `power, `software, `timeout, `normal_isr, `error_isr, 
    `normal_iser, `error_iser, `capa, `clock_d, `bd_status, 
    `bd_isr, `bd_iser, `bd_rx, `bd_tx
};

// Clock period definition for the simulation
localparam CLK_PERIOD = 10; // 10 time units for the clock period

assign wb_clk_i = clk;

task test_reset();
    @(posedge clk);
    wb_rst_i = 1'b1;
    #(CLK_PERIOD/2);

    repeat(3) @(posedge clk);

    wb_rst_i = 1'b0;
    repeat(3) @(posedge clk);

    @(posedge clk);
    wb_rst_i = 1'b1;
    @(posedge clk);
    wb_rst_i = 1'b0;
    @(posedge clk);
endtask

task test_sequential_register_access();
    wb_stb_i = 1'b1;
    wb_cyc_i = 1'b1;
    
    wb_we_i = 1'b1;
    
    foreach(all_registers[i]) begin
        wb_sel_i = $urandom;
        wb_dat_i = $urandom;
        wb_adr_i = all_registers[i];
        #(CLK_PERIOD);
    end
    
    wb_we_i = 1'b0;
    
    foreach(all_registers[i]) begin
        wb_sel_i = $urandom;
        wb_adr_i = all_registers[i];
        #(CLK_PERIOD);
    end
    
    wb_stb_i = 1'b0;
    wb_cyc_i = 1'b0;
    #(CLK_PERIOD);
endtask

task test_sd_controller_operations();
    write_req_s = 1'b0;
    cmd_set_s = 16'h0000;
    cmd_arg_s = 32'h00000000;
    
    repeat(10) begin
        cmd_set_s = $urandom;
        cmd_arg_s = $urandom;
        
        wb_stb_i = 1'b1;
        wb_cyc_i = 1'b1;
        wb_we_i = 1'b1;
        wb_sel_i = 4'b1111;
        
        wb_adr_i = `argument;
        wb_dat_i = cmd_arg_s;
        #(CLK_PERIOD);
        
        wb_adr_i = `command;
        wb_dat_i = {16'h0000, cmd_set_s};
        #(CLK_PERIOD);
        
        wb_stb_i = 1'b0;
        wb_cyc_i = 1'b0;
        #(CLK_PERIOD * 5);
        
        write_req_s = 1'b1;
        #(CLK_PERIOD * 2);
        write_req_s = 1'b0;
        
        status_reg = $urandom;
        normal_int_status_reg = $urandom;
        error_int_status_reg = $urandom;
        cmd_resp_1 = $urandom;
        #(CLK_PERIOD * 3);
        
        wb_stb_i = 1'b1;
        wb_cyc_i = 1'b1;
        wb_we_i = 1'b0;
        
        wb_adr_i = `status;
        #(CLK_PERIOD);
        
        wb_adr_i = `resp1;
        #(CLK_PERIOD);
        
        wb_adr_i = `normal_isr;
        #(CLK_PERIOD);
        
        wb_adr_i = `error_isr;
        #(CLK_PERIOD);
        
        wb_stb_i = 1'b0;
        wb_cyc_i = 1'b0;
        #(CLK_PERIOD * 2);
    end
endtask

task test_boundary_conditions();
    wb_stb_i = 1'b1;
    wb_cyc_i = 1'b1;
    wb_we_i = 1'b1;
    wb_dat_i = $urandom;
    wb_adr_i = `argument;
    #(CLK_PERIOD/2);

    wb_cyc_i = 1'b0;
    #(CLK_PERIOD/2);
    wb_stb_i = 1'b0;
    #(CLK_PERIOD);

    wb_stb_i = 1'b1;
    wb_cyc_i = 1'b1;
    wb_adr_i = 8'hFF;
    #(CLK_PERIOD * 2);
    
    wb_adr_i = `argument;
    repeat(16) begin
        wb_sel_i = $urandom;
        wb_dat_i = $urandom;
        #(CLK_PERIOD);
    end
    
    wb_stb_i = 1'b0;
    wb_cyc_i = 1'b0;
    #(CLK_PERIOD);
endtask

task test_random_stimulus(int iterations);
    repeat(iterations) begin
        wb_rst_i = ($urandom % 20 == 0);
        wb_stb_i = $random;
        wb_cyc_i = $random;
        wb_we_i = $random;
        wb_sel_i = $urandom;
        wb_dat_i = $urandom;
        wb_adr_i = all_registers[$urandom % $size(all_registers)];
        
        write_req_s = $random;
        cmd_set_s = $urandom;
        cmd_arg_s = $urandom;

        if ($urandom % 10 == 0) begin
            status_reg = $urandom;
            cmd_resp_1 = $urandom;
            normal_int_status_reg = $urandom;
            error_int_status_reg = $urandom;
            Bd_Status_reg = $urandom;
            Bd_isr_reg = $urandom;
        end
        
        #(CLK_PERIOD);
    end
endtask

// Stimulus generation
initial begin
    wb_rst_i = 1'b0;
    wb_stb_i = 1'b0;
    wb_cyc_i = 1'b0;
    wb_we_i = 1'b0;
    wb_sel_i = 4'b0000;
    wb_dat_i = 32'h00000000;
    wb_adr_i = 8'h00;
    write_req_s = 1'b0;
    cmd_set_s = 16'h0000;
    cmd_arg_s = 32'h00000000;
    status_reg = 16'h0000;
    cmd_resp_1 = 32'h00000000;
    normal_int_status_reg = 16'h0000;
    error_int_status_reg = 16'h0000;
    Bd_Status_reg = 16'h0000;
    Bd_isr_reg = 8'h00;

    // reset
    wb_rst_i = 1'b1;
    #(CLK_PERIOD *3);
    wb_rst_i = 1'b0;
    #(CLK_PERIOD * 3);

    // select this slave
    wb_stb_i = 1'b1;
    wb_cyc_i = 1'b1;
    wb_sel_i = 4'b1111; 

    wb_we_i = 1'b1;
    wb_dat_i = $urandom;
    wb_adr_i = `argument;
    #(CLK_PERIOD);
    wb_adr_i = `command;
    #(CLK_PERIOD);
    wb_adr_i = `software;
    #(CLK_PERIOD);
    
    #(CLK_PERIOD * 5);
    
    test_reset();
    #(CLK_PERIOD * 5);
    
    test_sequential_register_access();
    #(CLK_PERIOD * 5);
    
    test_sd_controller_operations();
    #(CLK_PERIOD * 5);
    
    test_boundary_conditions();
    #(CLK_PERIOD * 5);

    test_random_stimulus(5000);

    #(CLK_PERIOD * 10);
    $finish;
end

endmodule

module PATTERN(clk, wb_clk_i, wb_rst_i, wb_dat_i, wb_adr_i, wb_sel_i, wb_we_i, wb_cyc_i, wb_stb_i, write_req_s, cmd_set_s, cmd_arg_s, status_reg, cmd_resp_1, normal_int_status_reg, error_int_status_reg, Bd_Status_reg, Bd_isr_reg, wb_dat_o_dut, wb_ack_o_dut, we_m_tx_bd_dut, we_m_rx_bd_dut, new_cmd_dut, we_ack_dut, int_ack_dut, cmd_int_busy_dut, int_busy_dut, argument_reg_dut, cmd_setting_reg_dut, software_reset_reg_dut, time_out_reg_dut, normal_int_signal_enable_reg_dut, error_int_signal_enable_reg_dut, clock_divider_dut, Bd_isr_enable_reg_dut, Bd_isr_reset_dut, normal_isr_reset_dut, error_isr_reset_dut, dat_in_m_rx_bd_dut, dat_in_m_tx_bd_dut);
    output logic clk;
    output logic wb_clk_i;
    output logic wb_rst_i;
    output logic [31:0] wb_dat_i;
    output logic [7:0] wb_adr_i;
    output logic [3:0] wb_sel_i;
    output logic wb_we_i;
    output logic wb_cyc_i;
    output logic wb_stb_i;
    output logic write_req_s;
    output logic [15:0] cmd_set_s;
    output logic [31:0] cmd_arg_s;
    output logic [15:0] status_reg;
    output logic [31:0] cmd_resp_1;
    output logic [15:0] normal_int_status_reg;
    output logic [15:0] error_int_status_reg;
    output logic [15:0] Bd_Status_reg;
    output logic [7:0] Bd_isr_reg;
    input  logic [31:0] wb_dat_o_dut;
    input  logic wb_ack_o_dut;
    input  logic we_m_tx_bd_dut;
    input  logic we_m_rx_bd_dut;
    input  logic new_cmd_dut;
    input  logic we_ack_dut;
    input  logic int_ack_dut;
    input  logic cmd_int_busy_dut;
    input  logic int_busy_dut;
    input  logic [31:0] argument_reg_dut;
    input  logic [15:0] cmd_setting_reg_dut;
    input  logic [7:0] software_reset_reg_dut;
    input  logic [15:0] time_out_reg_dut;
    input  logic [15:0] normal_int_signal_enable_reg_dut;
    input  logic [15:0] error_int_signal_enable_reg_dut;
    input  logic [7:0] clock_divider_dut;
    input  logic [7:0] Bd_isr_enable_reg_dut;
    input  logic Bd_isr_reset_dut;
    input  logic normal_isr_reset_dut;
    input  logic error_isr_reset_dut;
    input  logic [`RAM_MEM_WIDTH-1:0] dat_in_m_rx_bd_dut;
    input  logic [`RAM_MEM_WIDTH-1:0] dat_in_m_tx_bd_dut;

    typedef struct packed {
        int errors;
        int errortime;
        int errors_wb_dat_o;
        int errortime_wb_dat_o;
        int errors_wb_ack_o;
        int errortime_wb_ack_o;
        int errors_we_m_tx_bd;
        int errortime_we_m_tx_bd;
        int errors_we_m_rx_bd;
        int errortime_we_m_rx_bd;
        int errors_new_cmd;
        int errortime_new_cmd;
        int errors_we_ack;
        int errortime_we_ack;
        int errors_int_ack;
        int errortime_int_ack;
        int errors_cmd_int_busy;
        int errortime_cmd_int_busy;
        int errors_int_busy;
        int errortime_int_busy;
        int errors_argument_reg;
        int errortime_argument_reg;
        int errors_cmd_setting_reg;
        int errortime_cmd_setting_reg;
        int errors_software_reset_reg;
        int errortime_software_reset_reg;
        int errors_time_out_reg;
        int errortime_time_out_reg;
        int errors_normal_int_signal_enable_reg;
        int errortime_normal_int_signal_enable_reg;
        int errors_error_int_signal_enable_reg;
        int errortime_error_int_signal_enable_reg;
        int errors_clock_divider;
        int errortime_clock_divider;
        int errors_Bd_isr_enable_reg;
        int errortime_Bd_isr_enable_reg;
        int errors_Bd_isr_reset;
        int errortime_Bd_isr_reset;
        int errors_normal_isr_reset;
        int errortime_normal_isr_reset;
        int errors_error_isr_reset;
        int errortime_error_isr_reset;
        int errors_dat_in_m_rx_bd;
        int errortime_dat_in_m_rx_bd;
        int errors_dat_in_m_tx_bd;
        int errortime_dat_in_m_tx_bd;
        int clocks;
    } stats;

    stats stats1;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic [511:0] wavedrom_title;
    logic         wavedrom_enable;
    logic [31:0] wb_dat_o_ref;
    logic wb_ack_o_ref;
    logic we_m_tx_bd_ref;
    logic we_m_rx_bd_ref;
    logic new_cmd_ref;
    logic we_ack_ref;
    logic int_ack_ref;
    logic cmd_int_busy_ref;
    logic int_busy_ref;
    logic [31:0] argument_reg_ref;
    logic [15:0] cmd_setting_reg_ref;
    logic [7:0] software_reset_reg_ref;
    logic [15:0] time_out_reg_ref;
    logic [15:0] normal_int_signal_enable_reg_ref;
    logic [15:0] error_int_signal_enable_reg_ref;
    logic [7:0] clock_divider_ref;
    logic [7:0] Bd_isr_enable_reg_ref;
    logic Bd_isr_reset_ref;
    logic normal_isr_reset_ref;
    logic error_isr_reset_ref;
    logic [`RAM_MEM_WIDTH-1:0] dat_in_m_rx_bd_ref;
    logic [`RAM_MEM_WIDTH-1:0] dat_in_m_tx_bd_ref;
    wire tb_match_wb_dat_o = (wb_dat_o_ref === wb_dat_o_dut);
    wire tb_match_wb_ack_o = (wb_ack_o_ref === wb_ack_o_dut);
    wire tb_match_we_m_tx_bd = (we_m_tx_bd_ref === we_m_tx_bd_dut);
    wire tb_match_we_m_rx_bd = (we_m_rx_bd_ref === we_m_rx_bd_dut);
    wire tb_match_new_cmd = (new_cmd_ref === new_cmd_dut);
    wire tb_match_we_ack = (we_ack_ref === we_ack_dut);
    wire tb_match_int_ack = (int_ack_ref === int_ack_dut);
    wire tb_match_cmd_int_busy = (cmd_int_busy_ref === cmd_int_busy_dut);
    wire tb_match_int_busy = (int_busy_ref === int_busy_dut);
    wire tb_match_argument_reg = (argument_reg_ref === argument_reg_dut);
    wire tb_match_cmd_setting_reg = (cmd_setting_reg_ref === cmd_setting_reg_dut);
    wire tb_match_software_reset_reg = (software_reset_reg_ref === software_reset_reg_dut);
    wire tb_match_time_out_reg = (time_out_reg_ref === time_out_reg_dut);
    wire tb_match_normal_int_signal_enable_reg = (normal_int_signal_enable_reg_ref === normal_int_signal_enable_reg_dut);
    wire tb_match_error_int_signal_enable_reg = (error_int_signal_enable_reg_ref === error_int_signal_enable_reg_dut);
    wire tb_match_clock_divider = (clock_divider_ref === clock_divider_dut);
    wire tb_match_Bd_isr_enable_reg = (Bd_isr_enable_reg_ref === Bd_isr_enable_reg_dut);
    wire tb_match_Bd_isr_reset = (Bd_isr_reset_ref === Bd_isr_reset_dut);
    wire tb_match_normal_isr_reset = (normal_isr_reset_ref === normal_isr_reset_dut);
    wire tb_match_error_isr_reset = (error_isr_reset_ref === error_isr_reset_dut);
    wire tb_match_dat_in_m_rx_bd = (dat_in_m_rx_bd_ref === dat_in_m_rx_bd_dut);
    wire tb_match_dat_in_m_tx_bd = (dat_in_m_tx_bd_ref === dat_in_m_tx_bd_dut);
    wire tb_match = tb_match_wb_dat_o & tb_match_wb_ack_o & tb_match_we_m_tx_bd & tb_match_we_m_rx_bd & tb_match_new_cmd & tb_match_we_ack & tb_match_int_ack & tb_match_cmd_int_busy & tb_match_int_busy & tb_match_argument_reg & tb_match_cmd_setting_reg & tb_match_software_reset_reg & tb_match_time_out_reg & tb_match_normal_int_signal_enable_reg & tb_match_error_int_signal_enable_reg & tb_match_clock_divider & tb_match_Bd_isr_enable_reg & tb_match_Bd_isr_reset & tb_match_normal_isr_reset & tb_match_error_isr_reset & tb_match_dat_in_m_rx_bd & tb_match_dat_in_m_tx_bd;

    stimulus_gen stim1 (
		.clk(clk),
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_dat_i(wb_dat_i),
		.wb_adr_i(wb_adr_i),
		.output(output),
		.output(output),
		.output(output),
		.output(output),
		.write_req_s(write_req_s),
		.cmd_set_s(cmd_set_s),
		.cmd_arg_s(cmd_arg_s),
		.status_reg(status_reg),
		.cmd_resp_1(cmd_resp_1),
		.normal_int_status_reg(normal_int_status_reg),
		.error_int_status_reg(error_int_status_reg),
		.Bd_Status_reg(Bd_Status_reg),
		.Bd_isr_reg(Bd_isr_reg)
    );

    ref_sd_controller_wb good1 (
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wb_dat_i(wb_dat_i),
		.wb_dat_o(wb_dat_o_ref),
		.wb_adr_i(wb_adr_i),
		.wb_sel_i(wb_sel_i),
		.wb_we_i(wb_we_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_stb_i(wb_stb_i),
		.wb_ack_o(wb_ack_o_ref),
		.we_m_tx_bd(we_m_tx_bd_ref),
		.new_cmd(new_cmd_ref),
		.we_ack(we_ack_ref),
		.int_ack(int_ack_ref),
		.cmd_int_busy(cmd_int_busy_ref),
		.we_m_rx_bd(we_m_rx_bd_ref),
		.int_busy(int_busy_ref),
		.write_req_s(write_req_s),
		.cmd_set_s(cmd_set_s),
		.cmd_arg_s(cmd_arg_s),
		.argument_reg(argument_reg_ref),
		.cmd_setting_reg(cmd_setting_reg_ref),
		.status_reg(status_reg),
		.cmd_resp_1(cmd_resp_1),
		.software_reset_reg(software_reset_reg_ref),
		.time_out_reg(time_out_reg_ref),
		.normal_int_status_reg(normal_int_status_reg),
		.error_int_status_reg(error_int_status_reg),
		.normal_int_signal_enable_reg(normal_int_signal_enable_reg_ref),
		.error_int_signal_enable_reg(error_int_signal_enable_reg_ref),
		.clock_divider(clock_divider_ref),
		.Bd_Status_reg(Bd_Status_reg),
		.Bd_isr_reg(Bd_isr_reg),
		.Bd_isr_enable_reg(Bd_isr_enable_reg_ref),
		.Bd_isr_reset(Bd_isr_reset_ref),
		.normal_isr_reset(normal_isr_reset_ref),
		.error_isr_reset(error_isr_reset_ref),
		.dat_in_m_rx_bd(dat_in_m_rx_bd_ref),
		.dat_in_m_tx_bd(dat_in_m_tx_bd_ref)
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
        if (stats1.clocks > 1 && !tb_match_wb_dat_o) begin
            if (stats1.errors_wb_dat_o == 0) stats1.errortime_wb_dat_o = $time;
            stats1.errors_wb_dat_o++;
        end
        if (stats1.clocks > 1 && !tb_match_wb_ack_o) begin
            if (stats1.errors_wb_ack_o == 0) stats1.errortime_wb_ack_o = $time;
            stats1.errors_wb_ack_o++;
        end
        if (stats1.clocks > 1 && !tb_match_we_m_tx_bd) begin
            if (stats1.errors_we_m_tx_bd == 0) stats1.errortime_we_m_tx_bd = $time;
            stats1.errors_we_m_tx_bd++;
        end
        if (stats1.clocks > 1 && !tb_match_we_m_rx_bd) begin
            if (stats1.errors_we_m_rx_bd == 0) stats1.errortime_we_m_rx_bd = $time;
            stats1.errors_we_m_rx_bd++;
        end
        if (stats1.clocks > 1 && !tb_match_new_cmd) begin
            if (stats1.errors_new_cmd == 0) stats1.errortime_new_cmd = $time;
            stats1.errors_new_cmd++;
        end
        if (stats1.clocks > 1 && !tb_match_we_ack) begin
            if (stats1.errors_we_ack == 0) stats1.errortime_we_ack = $time;
            stats1.errors_we_ack++;
        end
        if (stats1.clocks > 1 && !tb_match_int_ack) begin
            if (stats1.errors_int_ack == 0) stats1.errortime_int_ack = $time;
            stats1.errors_int_ack++;
        end
        if (stats1.clocks > 1 && !tb_match_cmd_int_busy) begin
            if (stats1.errors_cmd_int_busy == 0) stats1.errortime_cmd_int_busy = $time;
            stats1.errors_cmd_int_busy++;
        end
        if (stats1.clocks > 1 && !tb_match_int_busy) begin
            if (stats1.errors_int_busy == 0) stats1.errortime_int_busy = $time;
            stats1.errors_int_busy++;
        end
        if (stats1.clocks > 1 && !tb_match_argument_reg) begin
            if (stats1.errors_argument_reg == 0) stats1.errortime_argument_reg = $time;
            stats1.errors_argument_reg++;
        end
        if (stats1.clocks > 1 && !tb_match_cmd_setting_reg) begin
            if (stats1.errors_cmd_setting_reg == 0) stats1.errortime_cmd_setting_reg = $time;
            stats1.errors_cmd_setting_reg++;
        end
        if (stats1.clocks > 1 && !tb_match_software_reset_reg) begin
            if (stats1.errors_software_reset_reg == 0) stats1.errortime_software_reset_reg = $time;
            stats1.errors_software_reset_reg++;
        end
        if (stats1.clocks > 1 && !tb_match_time_out_reg) begin
            if (stats1.errors_time_out_reg == 0) stats1.errortime_time_out_reg = $time;
            stats1.errors_time_out_reg++;
        end
        if (stats1.clocks > 1 && !tb_match_normal_int_signal_enable_reg) begin
            if (stats1.errors_normal_int_signal_enable_reg == 0) stats1.errortime_normal_int_signal_enable_reg = $time;
            stats1.errors_normal_int_signal_enable_reg++;
        end
        if (stats1.clocks > 1 && !tb_match_error_int_signal_enable_reg) begin
            if (stats1.errors_error_int_signal_enable_reg == 0) stats1.errortime_error_int_signal_enable_reg = $time;
            stats1.errors_error_int_signal_enable_reg++;
        end
        if (stats1.clocks > 1 && !tb_match_clock_divider) begin
            if (stats1.errors_clock_divider == 0) stats1.errortime_clock_divider = $time;
            stats1.errors_clock_divider++;
        end
        if (stats1.clocks > 1 && !tb_match_Bd_isr_enable_reg) begin
            if (stats1.errors_Bd_isr_enable_reg == 0) stats1.errortime_Bd_isr_enable_reg = $time;
            stats1.errors_Bd_isr_enable_reg++;
        end
        if (stats1.clocks > 1 && !tb_match_Bd_isr_reset) begin
            if (stats1.errors_Bd_isr_reset == 0) stats1.errortime_Bd_isr_reset = $time;
            stats1.errors_Bd_isr_reset++;
        end
        if (stats1.clocks > 1 && !tb_match_normal_isr_reset) begin
            if (stats1.errors_normal_isr_reset == 0) stats1.errortime_normal_isr_reset = $time;
            stats1.errors_normal_isr_reset++;
        end
        if (stats1.clocks > 1 && !tb_match_error_isr_reset) begin
            if (stats1.errors_error_isr_reset == 0) stats1.errortime_error_isr_reset = $time;
            stats1.errors_error_isr_reset++;
        end
        if (stats1.clocks > 1 && !tb_match_dat_in_m_rx_bd) begin
            if (stats1.errors_dat_in_m_rx_bd == 0) stats1.errortime_dat_in_m_rx_bd = $time;
            stats1.errors_dat_in_m_rx_bd++;
        end
        if (stats1.clocks > 1 && !tb_match_dat_in_m_tx_bd) begin
            if (stats1.errors_dat_in_m_tx_bd == 0) stats1.errortime_dat_in_m_tx_bd = $time;
            stats1.errors_dat_in_m_tx_bd++;
        end
    end

    final begin
        $display("\nTest Results:");
        if (stats1.errors_wb_dat_o)
            $display("Hint: Output wb_dat_o has %0d mismatches. First at time %0d",
                    stats1.errors_wb_dat_o, stats1.errortime_wb_dat_o);
        else
            $display("Hint: Output 'wb_dat_o' has no mismatches.");
        if (stats1.errors_wb_ack_o)
            $display("Hint: Output wb_ack_o has %0d mismatches. First at time %0d",
                    stats1.errors_wb_ack_o, stats1.errortime_wb_ack_o);
        else
            $display("Hint: Output 'wb_ack_o' has no mismatches.");
        if (stats1.errors_we_m_tx_bd)
            $display("Hint: Output we_m_tx_bd has %0d mismatches. First at time %0d",
                    stats1.errors_we_m_tx_bd, stats1.errortime_we_m_tx_bd);
        else
            $display("Hint: Output 'we_m_tx_bd' has no mismatches.");
        if (stats1.errors_we_m_rx_bd)
            $display("Hint: Output we_m_rx_bd has %0d mismatches. First at time %0d",
                    stats1.errors_we_m_rx_bd, stats1.errortime_we_m_rx_bd);
        else
            $display("Hint: Output 'we_m_rx_bd' has no mismatches.");
        if (stats1.errors_new_cmd)
            $display("Hint: Output new_cmd has %0d mismatches. First at time %0d",
                    stats1.errors_new_cmd, stats1.errortime_new_cmd);
        else
            $display("Hint: Output 'new_cmd' has no mismatches.");
        if (stats1.errors_we_ack)
            $display("Hint: Output we_ack has %0d mismatches. First at time %0d",
                    stats1.errors_we_ack, stats1.errortime_we_ack);
        else
            $display("Hint: Output 'we_ack' has no mismatches.");
        if (stats1.errors_int_ack)
            $display("Hint: Output int_ack has %0d mismatches. First at time %0d",
                    stats1.errors_int_ack, stats1.errortime_int_ack);
        else
            $display("Hint: Output 'int_ack' has no mismatches.");
        if (stats1.errors_cmd_int_busy)
            $display("Hint: Output cmd_int_busy has %0d mismatches. First at time %0d",
                    stats1.errors_cmd_int_busy, stats1.errortime_cmd_int_busy);
        else
            $display("Hint: Output 'cmd_int_busy' has no mismatches.");
        if (stats1.errors_int_busy)
            $display("Hint: Output int_busy has %0d mismatches. First at time %0d",
                    stats1.errors_int_busy, stats1.errortime_int_busy);
        else
            $display("Hint: Output 'int_busy' has no mismatches.");
        if (stats1.errors_argument_reg)
            $display("Hint: Output argument_reg has %0d mismatches. First at time %0d",
                    stats1.errors_argument_reg, stats1.errortime_argument_reg);
        else
            $display("Hint: Output 'argument_reg' has no mismatches.");
        if (stats1.errors_cmd_setting_reg)
            $display("Hint: Output cmd_setting_reg has %0d mismatches. First at time %0d",
                    stats1.errors_cmd_setting_reg, stats1.errortime_cmd_setting_reg);
        else
            $display("Hint: Output 'cmd_setting_reg' has no mismatches.");
        if (stats1.errors_software_reset_reg)
            $display("Hint: Output software_reset_reg has %0d mismatches. First at time %0d",
                    stats1.errors_software_reset_reg, stats1.errortime_software_reset_reg);
        else
            $display("Hint: Output 'software_reset_reg' has no mismatches.");
        if (stats1.errors_time_out_reg)
            $display("Hint: Output time_out_reg has %0d mismatches. First at time %0d",
                    stats1.errors_time_out_reg, stats1.errortime_time_out_reg);
        else
            $display("Hint: Output 'time_out_reg' has no mismatches.");
        if (stats1.errors_normal_int_signal_enable_reg)
            $display("Hint: Output normal_int_signal_enable_reg has %0d mismatches. First at time %0d",
                    stats1.errors_normal_int_signal_enable_reg, stats1.errortime_normal_int_signal_enable_reg);
        else
            $display("Hint: Output 'normal_int_signal_enable_reg' has no mismatches.");
        if (stats1.errors_error_int_signal_enable_reg)
            $display("Hint: Output error_int_signal_enable_reg has %0d mismatches. First at time %0d",
                    stats1.errors_error_int_signal_enable_reg, stats1.errortime_error_int_signal_enable_reg);
        else
            $display("Hint: Output 'error_int_signal_enable_reg' has no mismatches.");
        if (stats1.errors_clock_divider)
            $display("Hint: Output clock_divider has %0d mismatches. First at time %0d",
                    stats1.errors_clock_divider, stats1.errortime_clock_divider);
        else
            $display("Hint: Output 'clock_divider' has no mismatches.");
        if (stats1.errors_Bd_isr_enable_reg)
            $display("Hint: Output Bd_isr_enable_reg has %0d mismatches. First at time %0d",
                    stats1.errors_Bd_isr_enable_reg, stats1.errortime_Bd_isr_enable_reg);
        else
            $display("Hint: Output 'Bd_isr_enable_reg' has no mismatches.");
        if (stats1.errors_Bd_isr_reset)
            $display("Hint: Output Bd_isr_reset has %0d mismatches. First at time %0d",
                    stats1.errors_Bd_isr_reset, stats1.errortime_Bd_isr_reset);
        else
            $display("Hint: Output 'Bd_isr_reset' has no mismatches.");
        if (stats1.errors_normal_isr_reset)
            $display("Hint: Output normal_isr_reset has %0d mismatches. First at time %0d",
                    stats1.errors_normal_isr_reset, stats1.errortime_normal_isr_reset);
        else
            $display("Hint: Output 'normal_isr_reset' has no mismatches.");
        if (stats1.errors_error_isr_reset)
            $display("Hint: Output error_isr_reset has %0d mismatches. First at time %0d",
                    stats1.errors_error_isr_reset, stats1.errortime_error_isr_reset);
        else
            $display("Hint: Output 'error_isr_reset' has no mismatches.");
        if (stats1.errors_dat_in_m_rx_bd)
            $display("Hint: Output dat_in_m_rx_bd has %0d mismatches. First at time %0d",
                    stats1.errors_dat_in_m_rx_bd, stats1.errortime_dat_in_m_rx_bd);
        else
            $display("Hint: Output 'dat_in_m_rx_bd' has no mismatches.");
        if (stats1.errors_dat_in_m_tx_bd)
            $display("Hint: Output dat_in_m_tx_bd has %0d mismatches. First at time %0d",
                    stats1.errors_dat_in_m_tx_bd, stats1.errortime_dat_in_m_tx_bd);
        else
            $display("Hint: Output 'dat_in_m_tx_bd' has no mismatches.");
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
