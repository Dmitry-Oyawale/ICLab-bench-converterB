module ref_sd_data_master (
  input clk,
  input rst,
  //Tx Bd
 
  input [`RAM_MEM_WIDTH-1:0] dat_in_tx,
  input [`BD_WIDTH-1:0] free_tx_bd,
  input ack_i_s_tx,
  output reg re_s_tx,
  output reg a_cmp_tx,
  //Rx Bd

  input [`RAM_MEM_WIDTH-1:0] dat_in_rx,
  input [`BD_WIDTH-1:0] free_rx_bd,
  input ack_i_s_rx,
  output reg re_s_rx,
  output reg a_cmp_rx,
  //Input from SD-Host Reg
  input  cmd_busy, //STATUS_REG[0] and mux  
  //Output to SD-Host Reg
  output reg we_req,
  input we_ack,
  output reg d_write,
  output reg d_read,
  output reg [31:0] cmd_arg,
  output reg [15:0] cmd_set,
  input cmd_tsf_err,
  input [4:0] card_status,
  //To fifo filler
  output reg start_tx_fifo,
  output reg start_rx_fifo,
  output reg [31:0] sys_adr,
  input tx_empt,
  input tx_full,
  input rx_full,

  //SD-DATA_Host
  input busy_n     ,
  input transm_complete ,
  input crc_ok,
  output reg ack_transfer, 
  //status output
  output reg  [7:0] Dat_Int_Status ,
  input Dat_Int_Status_rst,
  output reg  CIDAT,
  input [1:0] transfer_type
  
    
  );
`define RESEND_MAX_CNT 3
`ifdef RAM_MEM_WIDTH_32
      `define READ_CYCLE 2
       reg [1:0]bd_cnt  ;
       `define BD_EMPTY (`BD_SIZE  /2) 
`else `ifdef  RAM_MEM_WIDTH_16
      `define READ_CYCLE 4
       reg [2:0] bd_cnt;
       `define BD_EMPTY (`BD_SIZE  /4) 
   `endif
`endif 

reg send_done;
reg rec_done;
reg rec_failed;
reg tx_cycle;
reg rx_cycle;
reg [2:0] resend_try_cnt;

parameter CMD24 = 16'h181A ; // 011000 0001 1010
parameter CMD17 = 16'h111A; //  010001 0001 1010
parameter CMD12 = 16'hC1A ; //  001100 0001 1010
parameter ACMD13 = 16'hD1A ; // 001101 0001 1010  //SD STATUS
parameter ACMD51 = 16'h331A ; //110011 0001 1010 //SCR Register

parameter SIZE = 9;
reg [SIZE-1:0] state;
reg [SIZE-1:0] next_state;  
parameter IDLE             =  9'b000000001;
parameter GET_TX_BD        =  9'b000000010;
parameter GET_RX_BD        =  9'b000000100;
parameter SEND_CMD         =  9'b000001000;
parameter RECIVE_CMD       =  9'b000010000;
parameter DATA_TRANSFER    =  9'b000100000;
parameter STOP             =  9'b001000000;
parameter STOP_SEND        =  9'b010000000;
parameter STOP_RECIVE_CMD  =  9'b100000000;

reg trans_done;
reg trans_failed;
reg internal_transm_complete;
reg transm_complete_q;

always @ (posedge clk or posedge rst )
begin
	if  (rst) begin
		internal_transm_complete <=1'b0;
		transm_complete_q<=0;
	end
	else begin  
		transm_complete_q<=transm_complete;
		internal_transm_complete<=transm_complete_q;
	end


end




always @ (state or resend_try_cnt or tx_full or free_tx_bd or free_rx_bd or bd_cnt or send_done or rec_done or rec_failed or trans_done or trans_failed)
begin : FSM_COMBO
 next_state  = 0;   
case(state)  
  
  IDLE: begin
   if (free_tx_bd !=`BD_EMPTY)begin
      next_state = GET_TX_BD;
   end
   else if (free_rx_bd !=`BD_EMPTY) begin
      next_state = GET_RX_BD;
   end  
   else begin
      next_state = IDLE;
   end
  end
  GET_TX_BD: begin
    if ( ( bd_cnt> `READ_CYCLE-1) && (tx_full==1) )begin
     next_state = SEND_CMD;
    end   
    else begin
     next_state = GET_TX_BD;
    end
  end   
  
  GET_RX_BD: begin  
    if (bd_cnt >= (`READ_CYCLE-1))begin
     next_state = SEND_CMD;
    end   
    else begin
     next_state = GET_RX_BD;
    end
  end
  
  SEND_CMD: begin 
   if (send_done)begin
     next_state = RECIVE_CMD;
    end   
    else begin
     next_state = SEND_CMD;
    end 
  end
    
  
 RECIVE_CMD: begin 
    if (rec_done)
      next_state = DATA_TRANSFER;       
    else if (rec_failed)
      next_state =  SEND_CMD;
    else 
      next_state = RECIVE_CMD;    
   end 

  DATA_TRANSFER: begin
    if (trans_done)
      next_state = IDLE;
   else if (trans_failed)
      next_state = STOP;
   else
      next_state = DATA_TRANSFER;
   end
  
  STOP: begin 
     next_state = STOP_SEND;     
   end
   
   STOP_SEND: begin
    if (send_done)begin
     next_state =IDLE;
    end   
    else begin
     next_state = STOP_SEND;
    end  
   end
   
   STOP_RECIVE_CMD : begin
    if (rec_done)
      next_state = SEND_CMD;       
    else if (rec_failed)
      next_state =  STOP;
    else if (resend_try_cnt>=`RESEND_MAX_CNT)
      next_state = IDLE;
    else 
      next_state = STOP_RECIVE_CMD;    
   end 
 
   
 
 default : next_state  = IDLE; 
 endcase

end

//----------------Seq logic------------
always @ (posedge clk or posedge rst   )
begin : FSM_SEQ
  if (rst ) begin
    state <= #1 IDLE;
 end 
 else begin
    state <= #1 next_state;
 end
end



//Output logic-----------------


always @ (posedge clk or posedge rst   )
begin  
 if (rst) begin
      send_done<=0;
      bd_cnt<=0;
      sys_adr<=0;
      cmd_arg<=0;
      rec_done<=0;
      start_tx_fifo<=0;
      start_rx_fifo<=0;
      send_done<=0;
      rec_failed<=0;
      d_write <=0;  
      d_read <=0;  
      trans_failed<=0;
      trans_done<=0;
      tx_cycle <=0;
      rx_cycle <=0;
      ack_transfer<=0;
      a_cmp_tx<=0;           
      a_cmp_rx<=0;
      CIDAT<=0;
      Dat_Int_Status<=0;
      we_req<=0;
      re_s_tx<=0;
      re_s_rx<=0;
      cmd_set<=0;
      resend_try_cnt=0;
 end
 else begin
  case(state)
     IDLE: begin
      send_done<=0;
      bd_cnt<=0;
      sys_adr<=0;
      cmd_arg<=0;
      rec_done<=0;
      rec_failed<=0;
      start_tx_fifo<=0;
      start_rx_fifo<=0;
      send_done<=0;     
      d_write <=0;  
      d_read <=0; 
      trans_failed<=0;
      trans_done<=0;
      tx_cycle <=0;
      rx_cycle <=0;
      ack_transfer<=0;
      a_cmp_tx<=0;           
      a_cmp_rx<=0;
      resend_try_cnt=0;
     end
     
     GET_RX_BD: begin                 
        //0,1,2,3...
      re_s_rx <= 1;
     `ifdef  RAM_MEM_WIDTH_32
     	if (ack_i_s_rx) begin        
	        if( bd_cnt == 2'b0) begin
	           sys_adr  <= dat_in_rx;
	           bd_cnt <= bd_cnt+1;   
	     	end           
	        else if ( bd_cnt == 2'b1) begin  
	           cmd_arg  <= dat_in_rx;
	           re_s_rx <= 0; 
	        end
	   end
      `endif
      
      
      `ifdef  RAM_MEM_WIDTH_16
      	if (ack_i_s_rx) begin        
	        if( bd_cnt == 2'b00) begin
	           sys_adr [15:0] <= dat_in_rx; 
	        end
	        else if ( bd_cnt == 2'b01)  begin
	           sys_adr [31:16] <= dat_in_rx; 
	        end
	        else if ( bd_cnt == 2) begin
	          cmd_arg [15:0] <= dat_in_rx;
	          re_s_rx <= 0; 
	        end
	        else if ( bd_cnt == 3) begin
	           cmd_arg [31:16] <= dat_in_rx;
	           re_s_rx <= 0;
	         end
	         bd_cnt <= bd_cnt+1;       
	   	end
       `endif
     //Add Later Save last block addres for comparison with current (For multiple block cmd)
     //Add support for Pre-erased
      if (transfer_type==2'b00)
		   cmd_set <= CMD17;
		else if (transfer_type==2'b01)
		   cmd_set <= ACMD13;	 
		else 
      	   cmd_set <= ACMD51;

      rx_cycle<=1;  
     end
          
     GET_TX_BD:  begin             
        //0,1,2,3...
      re_s_tx <= 1;
      if ( bd_cnt == `READ_CYCLE)
        re_s_tx <= 0;
        
       `ifdef  RAM_MEM_WIDTH_32
     	 if (ack_i_s_tx) begin
        
	        if( bd_cnt == 2'b0) begin
	           sys_adr  <= dat_in_tx;
	           bd_cnt <= bd_cnt+1;   
	     	end           
	        else if ( bd_cnt == 2'b1) begin  
	           cmd_arg  <= dat_in_tx;
	           re_s_tx <= 0; 
			   start_tx_fifo<=1;  
        end
	   end
       `endif
      
      `ifdef  RAM_MEM_WIDTH_16
      if (ack_i_s_tx) begin
        
        if( bd_cnt == 0) begin
           sys_adr [15:0] <= dat_in_tx; 
           bd_cnt <= bd_cnt+1;   end
        else if ( bd_cnt == 1)  begin
           sys_adr [31:16] <= dat_in_tx;
           bd_cnt <= bd_cnt+1;    end
        else if ( bd_cnt == 2) begin
          cmd_arg [15:0] <= dat_in_tx;
          re_s_tx <= 0;
          bd_cnt <= bd_cnt+1;    end
        else if ( bd_cnt == 3) begin
           cmd_arg [31:16] <= dat_in_tx;
           re_s_tx <= 0;
           bd_cnt <= bd_cnt+1;
		   start_tx_fifo<=1;  
         end
       end
       `endif
     //Add Later Save last block addres for comparison with current (For multiple block cmd)
     //Add support for Pre-erased
      cmd_set <= CMD24;  
      tx_cycle <=1;   
        
   end  
   
     SEND_CMD : begin  
       rec_done<=0;     
       if (rx_cycle)    begin     
         re_s_rx <=0; 
         d_read<=1;
       end
       else begin
         re_s_tx <=0; 
         d_write<=1;
        end
       start_rx_fifo<=0; //Reset FIFO  
      // start_tx_fifo<=0;  //Reset FIFO 
       if (!cmd_busy) begin
         we_req <= 1;  
         
       end  //When send complete change state and wait for reply
       if (we_ack) begin     
           send_done<=1;
           we_req <= 1;  
          
       end       
    end   
   
   
    RECIVE_CMD : begin
         //When waiting for reply fill TX fifo
        if (rx_cycle)
         start_rx_fifo<=1; //start_fifo prebuffering
       //else
         //start_rx_fifo <=1;
        
         we_req <= 0;  
          
         send_done<=0;
       if (!cmd_busy) begin //Means the sending is completed,
         d_read<=0; 
         d_write<=0;  
         if (!cmd_tsf_err) begin
           if (card_status[0]) begin
               
                if ( (card_status[4:1] == 4'b0100) || (card_status[4:1] == 4'b0110) || (card_status[4:1] == 4'b0101) )
                    rec_done<=1;
                else begin
                    rec_failed<=1;
                    Dat_Int_Status[4] <=1; 
                       start_tx_fifo<=0;  
                end 
                
                 
                                     
               //Check card_status[5:1] for state 4 or 6... 
               //If wrong state change interupt status reg,so software can put card in
               // transfer state and restart/cancel Data transfer
          end
          
         end
         else begin
             rec_failed<=1;  //CRC-Error, CIC-Error or timeout 
                start_tx_fifo<=0;  
                end
       end  
    end
    
    DATA_TRANSFER: begin
       CIDAT<=1;
     if (tx_cycle) begin 
      if (tx_empt) begin
         Dat_Int_Status[2] <=1;
         trans_failed<=1;  
       end
     end
     else begin 
       if (rx_full) begin
         Dat_Int_Status[2] <=1; 
         trans_failed<=1; 
      end
    end            
      //Check for fifo underflow, 
      //2 DO: if deteced stop transfer, reset data host
      if (internal_transm_complete) begin //Transfer complete
         ack_transfer<=1;
        
         if ((!crc_ok) && (busy_n))  begin //Wrong CRC and Data line free.
            Dat_Int_Status[5] <=1; 
            trans_failed<=1;
         end 
         else if ((crc_ok) && (busy_n)) begin //Data Line free
           trans_done <=1;       

			if (tx_cycle) begin
				a_cmp_tx<=1;
				if (free_tx_bd ==`BD_EMPTY-1 )
					Dat_Int_Status[0]<=1;
			end 
			else begin
				a_cmp_rx<=1;                        
				if (free_rx_bd ==`BD_EMPTY-1)
					Dat_Int_Status[0]<=1;
			end
    
 
       end
   
  end
  end
  STOP: begin
    cmd_set <= CMD12;
    rec_done<=0;
    rec_failed<=0;     
    send_done<=0;  
    trans_failed<=0;
    trans_done<=0;    
    d_read<=1; 
    d_write<=1; 
    start_rx_fifo <=0;
    start_tx_fifo <=0;         
     
  end
   STOP_SEND: begin
      resend_try_cnt=resend_try_cnt+1;
      if (resend_try_cnt==`RESEND_MAX_CNT)
          Dat_Int_Status[1]<=1;
      if (!cmd_busy) 
         we_req <= 1;      
      if (we_ack)      
           send_done<=1;    
   end  
  
   STOP_RECIVE_CMD: begin
     we_req <= 0; 
    end
  
  endcase  
  if (Dat_Int_Status_rst)
    Dat_Int_Status<=0;
 end 
  
end  
  
endmodule

`include "sd_defines.v"

module stimulus_gen (
	input clk,
	output logic rst,
	output [`RAM_MEM_WIDTH-1:0] dat_in_tx,
	output [`BD_WIDTH-1:0] free_tx_bd,
  	output logic ack_i_s_tx,
  	output [`RAM_MEM_WIDTH-1:0] dat_in_rx,
  	output [`BD_WIDTH-1:0] free_rx_bd,
  	output logic ack_i_s_rx,
  	output logic cmd_busy,
  	output logic we_ack,
  	output logic cmd_tsf_err,
  	output [4:0] card_status,
  	output logic tx_empt,
  	output logic tx_full,
  	output logic rx_full,
  	output logic busy_n     ,
  	output logic transm_complete ,
  	output logic crc_ok,
  	output logic Dat_Int_Status_rst,
  	output [1:0] transfer_type,
	output reg[511:0] wavedrom_title,
	output reg wavedrom_enable, 
	tb_match
);
	reg reset;
	assign rst = reset;


	task reset_test(input async = 0);
		bit arfail, srfail, datafail;
	
		@(posedge clk);
		@(posedge clk) reset = 0;
		repeat(3) @(posedge clk);
	
		@(negedge clk) begin datafail = !tb_match ; reset = 1; end
		@(posedge clk) arfail = !tb_match;
		@(posedge clk) begin
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

	task wavedrom_start(input[511:0] title = "");
	endtask
	
	task wavedrom_stop;
		#1;
	endtask	


	initial begin
		repeat(3)@(posedge clk) reset = 1;
		repeat(3)@(posedge clk) reset = 0;
		dat_in_tx = $random;
		free_tx_bd = 0;
		ack_i_s_tx = 0;
		dat_in_rx = 0;
		free_rx_bd = 0;
		ack_i_s_rx = 0;   
		cmd_busy = 0;	 
		we_ack = 0;  
		cmd_tsf_err = 0;
		card_status = 0;  
		tx_empt = 0;
		tx_full = 0;
		rx_full = 0;  
		busy_n = 0;
		transm_complete = 0;
		crc_ok = 0;
		Dat_Int_Status_rst = 0;   
		transfer_type = 0;

		wavedrom_start("Asynchronous reset");
		reset_test(1);
		wavedrom_stop();

		//IDLE -> GET_RX_BD -> SEND_CMD -> RECIVE_CMD -> DATA_TRANSFER
		@(posedge clk) free_rx_bd = `BD_EMPTY - 1;

		repeat(10)@(posedge clk)	ack_i_s_rx = 1;

		repeat(10)@(posedge clk)	we_ack = 1;
		repeat(10)@(posedge clk) 	card_status = 5'b01001;
		repeat(10)@(posedge clk) 	rx_full = 1;
		repeat(10)@(posedge clk) 	crc_ok = 1; busy_n = 1;
		repeat(3)@(posedge clk) reset = 1;

		//IDLE -> GET_TX_BD -> SEND_CMD -> RECIVE_CMD -> SEND_CMD -> RECIVE_CMD ->SEND_CMD -> RECIVE_CMD
		// -> DATA_TRANSFER -> STOP -> STOP_SEND
		@(posedge clk) free_tx_bd = `BD_EMPTY - 1;
			ack_i_s_tx = 1;
		repeat(100) @(posedge clk);
		@(posedge clk) tx_full = 1;
		repeat(10) @(posedge clk);
		@(posedge clk) we_ack = 1; cmd_tsf_err = 1;
		@(posedge clk) we_ack = 0;
		@(posedge clk) cmd_tsf_err = 0;
		repeat(5) @(posedge clk);
		@(posedge clk) we_ack = 1;
 		@(posedge clk) we_ack = 0;
		repeat(10) @(posedge clk);
		@(posedge clk) we_ack = 1; transm_complete = 1;
		@(posedge clk) card_status = 5'b01001;
		@(posedge clk) tx_empt = 1; crc_ok = 0; busy_n = 1; we_ack = 0;
		repeat(10) @(posedge clk);
		@(posedge clk) cmd_busy = 0; 
		repeat(10) @(posedge clk) reset = 1;
		
		repeat(10000) @(posedge clk, negedge clk) begin
			dat_in_tx = $random;
			free_tx_bd =`BD_EMPTY-1;
			ack_i_s_tx = ($random%2);
			dat_in_rx = $random;
			free_rx_bd = $random;
			ack_i_s_rx = ($random%2);   
			cmd_busy = ($random%2);	 
			we_ack = ($random%2); 
			cmd_tsf_err = ($random%2);
			card_status = $random;
			tx_empt = ($random%2);
			tx_full = ($random%2);
			rx_full = ($random%2);  
			busy_n = ($random%2);
			transm_complete = ($random%2);
			crc_ok = ($random%2);
			Dat_Int_Status_rst = ($random%2);   
			transfer_type = $random;
			//reset = 1;
			reset = !($random & 31);
		end

		@(posedge clk);
		repeat(50000) @(posedge clk, negedge clk) begin
			dat_in_tx = $random;
			//free_tx_bd = $random;
			free_tx_bd =`BD_EMPTY;
			ack_i_s_tx = ($random%2);
			dat_in_rx = $random;
			//free_rx_bd = $random;
			free_rx_bd =`BD_EMPTY - 1;
			ack_i_s_rx = ($random%2);   
			cmd_busy = ($random%2);	 
			we_ack = ($random%2); 
			cmd_tsf_err = ($random%2);
			card_status = $random;
			tx_empt = ($random%2);
			tx_full = ($random%2);
			rx_full = ($random%2);  
			busy_n = ($random%2);
			transm_complete = ($random%2);
			crc_ok = ($random%2);
			Dat_Int_Status_rst = ($random%2);   
			transfer_type = $random;
			//reset = 1;
			reset = !($random & 31);
		end

		@(posedge clk);
		repeat(30000) @(posedge clk, negedge clk) begin
			dat_in_tx = $random;
			free_tx_bd = $random;
			ack_i_s_tx = ($random%2);
			dat_in_rx = $random;
			free_rx_bd = $random;
			ack_i_s_rx = ($random%2);   
			cmd_busy = ($random%2);	 
			we_ack = ($random%2); 
			cmd_tsf_err = ($random%2);
			card_status = $random;
			tx_empt = ($random%2);
			tx_full = ($random%2);
			rx_full = ($random%2);  
			busy_n = ($random%2);
			transm_complete = ($random%2);
			crc_ok = ($random%2);
			Dat_Int_Status_rst = ($random%2);   
			transfer_type = $random;
			//reset = 1;
			reset = !($random & 31);
		end

		$finish;
	end
	
endmodule

module PATTERN(clk, rst, dat_in_tx, free_tx_bd, ack_i_s_tx, dat_in_rx, free_rx_bd, ack_i_s_rx, cmd_busy, we_ack, cmd_tsf_err, card_status, tx_empt, tx_full, rx_full, busy_n, transm_complete, crc_ok, Dat_Int_Status_rst, transfer_type, re_s_tx_dut, a_cmp_tx_dut, re_s_rx_dut, a_cmp_rx_dut, we_req_dut, d_write_dut, d_read_dut, cmd_arg_dut, cmd_set_dut, start_tx_fifo_dut, start_rx_fifo_dut, sys_adr_dut, ack_transfer_dut, output_dut, CIDAT_dut);
    output logic clk;
    output logic rst;
    output logic [`RAM_MEM_WIDTH-1:0] dat_in_tx;
    output logic [`BD_WIDTH-1:0] free_tx_bd;
    output logic ack_i_s_tx;
    output logic [`RAM_MEM_WIDTH-1:0] dat_in_rx;
    output logic [`BD_WIDTH-1:0] free_rx_bd;
    output logic ack_i_s_rx;
    output logic cmd_busy;
    output logic we_ack;
    output logic cmd_tsf_err;
    output logic [4:0] card_status;
    output logic tx_empt;
    output logic tx_full;
    output logic rx_full;
    output logic busy_n;
    output logic transm_complete;
    output logic crc_ok;
    output logic Dat_Int_Status_rst;
    output logic [1:0] transfer_type;
    input  logic re_s_tx_dut;
    input  logic a_cmp_tx_dut;
    input  logic re_s_rx_dut;
    input  logic a_cmp_rx_dut;
    input  logic we_req_dut;
    input  logic d_write_dut;
    input  logic d_read_dut;
    input  logic [31:0] cmd_arg_dut;
    input  logic [15:0] cmd_set_dut;
    input  logic start_tx_fifo_dut;
    input  logic start_rx_fifo_dut;
    input  logic [31:0] sys_adr_dut;
    input  logic ack_transfer_dut;
    input  logic output_dut;
    input  logic CIDAT_dut;

    typedef struct packed {
        int errors;
        int errortime;
        int errors_re_s_tx;
        int errortime_re_s_tx;
        int errors_a_cmp_tx;
        int errortime_a_cmp_tx;
        int errors_re_s_rx;
        int errortime_re_s_rx;
        int errors_a_cmp_rx;
        int errortime_a_cmp_rx;
        int errors_we_req;
        int errortime_we_req;
        int errors_d_write;
        int errortime_d_write;
        int errors_d_read;
        int errortime_d_read;
        int errors_cmd_arg;
        int errortime_cmd_arg;
        int errors_cmd_set;
        int errortime_cmd_set;
        int errors_start_tx_fifo;
        int errortime_start_tx_fifo;
        int errors_start_rx_fifo;
        int errortime_start_rx_fifo;
        int errors_sys_adr;
        int errortime_sys_adr;
        int errors_ack_transfer;
        int errortime_ack_transfer;
        int errors_output;
        int errortime_output;
        int errors_CIDAT;
        int errortime_CIDAT;
        int clocks;
    } stats;

    stats stats1;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    logic [511:0] wavedrom_title;
    logic         wavedrom_enable;
    logic re_s_tx_ref;
    logic a_cmp_tx_ref;
    logic re_s_rx_ref;
    logic a_cmp_rx_ref;
    logic we_req_ref;
    logic d_write_ref;
    logic d_read_ref;
    logic [31:0] cmd_arg_ref;
    logic [15:0] cmd_set_ref;
    logic start_tx_fifo_ref;
    logic start_rx_fifo_ref;
    logic [31:0] sys_adr_ref;
    logic ack_transfer_ref;
    logic output_ref;
    logic CIDAT_ref;
    wire tb_match_re_s_tx = (re_s_tx_ref === re_s_tx_dut);
    wire tb_match_a_cmp_tx = (a_cmp_tx_ref === a_cmp_tx_dut);
    wire tb_match_re_s_rx = (re_s_rx_ref === re_s_rx_dut);
    wire tb_match_a_cmp_rx = (a_cmp_rx_ref === a_cmp_rx_dut);
    wire tb_match_we_req = (we_req_ref === we_req_dut);
    wire tb_match_d_write = (d_write_ref === d_write_dut);
    wire tb_match_d_read = (d_read_ref === d_read_dut);
    wire tb_match_cmd_arg = (cmd_arg_ref === cmd_arg_dut);
    wire tb_match_cmd_set = (cmd_set_ref === cmd_set_dut);
    wire tb_match_start_tx_fifo = (start_tx_fifo_ref === start_tx_fifo_dut);
    wire tb_match_start_rx_fifo = (start_rx_fifo_ref === start_rx_fifo_dut);
    wire tb_match_sys_adr = (sys_adr_ref === sys_adr_dut);
    wire tb_match_ack_transfer = (ack_transfer_ref === ack_transfer_dut);
    wire tb_match_output = (output_ref === output_dut);
    wire tb_match_CIDAT = (CIDAT_ref === CIDAT_dut);
    wire tb_match = tb_match_re_s_tx & tb_match_a_cmp_tx & tb_match_re_s_rx & tb_match_a_cmp_rx & tb_match_we_req & tb_match_d_write & tb_match_d_read & tb_match_cmd_arg & tb_match_cmd_set & tb_match_start_tx_fifo & tb_match_start_rx_fifo & tb_match_sys_adr & tb_match_ack_transfer & tb_match_output & tb_match_CIDAT;

    stimulus_gen stim1 (
		.clk(clk),
		.rst(rst),
		.dat_in_tx(dat_in_tx),
		.free_tx_bd(free_tx_bd),
		.ack_i_s_tx(ack_i_s_tx),
		.dat_in_rx(dat_in_rx),
		.free_rx_bd(free_rx_bd),
		.ack_i_s_rx(ack_i_s_rx),
		.cmd_busy(cmd_busy),
		.we_ack(we_ack),
		.cmd_tsf_err(cmd_tsf_err),
		.card_status(card_status),
		.tx_empt(tx_empt),
		.tx_full(tx_full),
		.rx_full(rx_full),
		.busy_n(busy_n),
		.transm_complete(transm_complete),
		.crc_ok(crc_ok),
		.Dat_Int_Status_rst(Dat_Int_Status_rst),
		.transfer_type(transfer_type),
		.reg(reg),
		.wavedrom_enable(wavedrom_enable)
    );

    ref_sd_data_master good1 (
		.clk(clk),
		.rst(rst),
		.dat_in_tx(dat_in_tx),
		.free_tx_bd(free_tx_bd),
		.ack_i_s_tx(ack_i_s_tx),
		.re_s_tx(re_s_tx_ref),
		.a_cmp_tx(a_cmp_tx_ref),
		.dat_in_rx(dat_in_rx),
		.free_rx_bd(free_rx_bd),
		.ack_i_s_rx(ack_i_s_rx),
		.re_s_rx(re_s_rx_ref),
		.a_cmp_rx(a_cmp_rx_ref),
		.cmd_busy(cmd_busy),
		.we_req(we_req_ref),
		.we_ack(we_ack),
		.d_write(d_write_ref),
		.d_read(d_read_ref),
		.cmd_arg(cmd_arg_ref),
		.cmd_set(cmd_set_ref),
		.cmd_tsf_err(cmd_tsf_err),
		.card_status(card_status),
		.start_tx_fifo(start_tx_fifo_ref),
		.start_rx_fifo(start_rx_fifo_ref),
		.sys_adr(sys_adr_ref),
		.tx_empt(tx_empt),
		.tx_full(tx_full),
		.rx_full(rx_full),
		.busy_n(busy_n),
		.transm_complete(transm_complete),
		.crc_ok(crc_ok),
		.ack_transfer(ack_transfer_ref),
		.output(output_ref),
		.Dat_Int_Status_rst(Dat_Int_Status_rst),
		.CIDAT(CIDAT_ref),
		.transfer_type(transfer_type)
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
        if (stats1.clocks > 1 && !tb_match_re_s_tx) begin
            if (stats1.errors_re_s_tx == 0) stats1.errortime_re_s_tx = $time;
            stats1.errors_re_s_tx++;
        end
        if (stats1.clocks > 1 && !tb_match_a_cmp_tx) begin
            if (stats1.errors_a_cmp_tx == 0) stats1.errortime_a_cmp_tx = $time;
            stats1.errors_a_cmp_tx++;
        end
        if (stats1.clocks > 1 && !tb_match_re_s_rx) begin
            if (stats1.errors_re_s_rx == 0) stats1.errortime_re_s_rx = $time;
            stats1.errors_re_s_rx++;
        end
        if (stats1.clocks > 1 && !tb_match_a_cmp_rx) begin
            if (stats1.errors_a_cmp_rx == 0) stats1.errortime_a_cmp_rx = $time;
            stats1.errors_a_cmp_rx++;
        end
        if (stats1.clocks > 1 && !tb_match_we_req) begin
            if (stats1.errors_we_req == 0) stats1.errortime_we_req = $time;
            stats1.errors_we_req++;
        end
        if (stats1.clocks > 1 && !tb_match_d_write) begin
            if (stats1.errors_d_write == 0) stats1.errortime_d_write = $time;
            stats1.errors_d_write++;
        end
        if (stats1.clocks > 1 && !tb_match_d_read) begin
            if (stats1.errors_d_read == 0) stats1.errortime_d_read = $time;
            stats1.errors_d_read++;
        end
        if (stats1.clocks > 1 && !tb_match_cmd_arg) begin
            if (stats1.errors_cmd_arg == 0) stats1.errortime_cmd_arg = $time;
            stats1.errors_cmd_arg++;
        end
        if (stats1.clocks > 1 && !tb_match_cmd_set) begin
            if (stats1.errors_cmd_set == 0) stats1.errortime_cmd_set = $time;
            stats1.errors_cmd_set++;
        end
        if (stats1.clocks > 1 && !tb_match_start_tx_fifo) begin
            if (stats1.errors_start_tx_fifo == 0) stats1.errortime_start_tx_fifo = $time;
            stats1.errors_start_tx_fifo++;
        end
        if (stats1.clocks > 1 && !tb_match_start_rx_fifo) begin
            if (stats1.errors_start_rx_fifo == 0) stats1.errortime_start_rx_fifo = $time;
            stats1.errors_start_rx_fifo++;
        end
        if (stats1.clocks > 1 && !tb_match_sys_adr) begin
            if (stats1.errors_sys_adr == 0) stats1.errortime_sys_adr = $time;
            stats1.errors_sys_adr++;
        end
        if (stats1.clocks > 1 && !tb_match_ack_transfer) begin
            if (stats1.errors_ack_transfer == 0) stats1.errortime_ack_transfer = $time;
            stats1.errors_ack_transfer++;
        end
        if (stats1.clocks > 1 && !tb_match_output) begin
            if (stats1.errors_output == 0) stats1.errortime_output = $time;
            stats1.errors_output++;
        end
        if (stats1.clocks > 1 && !tb_match_CIDAT) begin
            if (stats1.errors_CIDAT == 0) stats1.errortime_CIDAT = $time;
            stats1.errors_CIDAT++;
        end
    end

    final begin
        $display("\nTest Results:");
        if (stats1.errors_re_s_tx)
            $display("Hint: Output re_s_tx has %0d mismatches. First at time %0d",
                    stats1.errors_re_s_tx, stats1.errortime_re_s_tx);
        else
            $display("Hint: Output 're_s_tx' has no mismatches.");
        if (stats1.errors_a_cmp_tx)
            $display("Hint: Output a_cmp_tx has %0d mismatches. First at time %0d",
                    stats1.errors_a_cmp_tx, stats1.errortime_a_cmp_tx);
        else
            $display("Hint: Output 'a_cmp_tx' has no mismatches.");
        if (stats1.errors_re_s_rx)
            $display("Hint: Output re_s_rx has %0d mismatches. First at time %0d",
                    stats1.errors_re_s_rx, stats1.errortime_re_s_rx);
        else
            $display("Hint: Output 're_s_rx' has no mismatches.");
        if (stats1.errors_a_cmp_rx)
            $display("Hint: Output a_cmp_rx has %0d mismatches. First at time %0d",
                    stats1.errors_a_cmp_rx, stats1.errortime_a_cmp_rx);
        else
            $display("Hint: Output 'a_cmp_rx' has no mismatches.");
        if (stats1.errors_we_req)
            $display("Hint: Output we_req has %0d mismatches. First at time %0d",
                    stats1.errors_we_req, stats1.errortime_we_req);
        else
            $display("Hint: Output 'we_req' has no mismatches.");
        if (stats1.errors_d_write)
            $display("Hint: Output d_write has %0d mismatches. First at time %0d",
                    stats1.errors_d_write, stats1.errortime_d_write);
        else
            $display("Hint: Output 'd_write' has no mismatches.");
        if (stats1.errors_d_read)
            $display("Hint: Output d_read has %0d mismatches. First at time %0d",
                    stats1.errors_d_read, stats1.errortime_d_read);
        else
            $display("Hint: Output 'd_read' has no mismatches.");
        if (stats1.errors_cmd_arg)
            $display("Hint: Output cmd_arg has %0d mismatches. First at time %0d",
                    stats1.errors_cmd_arg, stats1.errortime_cmd_arg);
        else
            $display("Hint: Output 'cmd_arg' has no mismatches.");
        if (stats1.errors_cmd_set)
            $display("Hint: Output cmd_set has %0d mismatches. First at time %0d",
                    stats1.errors_cmd_set, stats1.errortime_cmd_set);
        else
            $display("Hint: Output 'cmd_set' has no mismatches.");
        if (stats1.errors_start_tx_fifo)
            $display("Hint: Output start_tx_fifo has %0d mismatches. First at time %0d",
                    stats1.errors_start_tx_fifo, stats1.errortime_start_tx_fifo);
        else
            $display("Hint: Output 'start_tx_fifo' has no mismatches.");
        if (stats1.errors_start_rx_fifo)
            $display("Hint: Output start_rx_fifo has %0d mismatches. First at time %0d",
                    stats1.errors_start_rx_fifo, stats1.errortime_start_rx_fifo);
        else
            $display("Hint: Output 'start_rx_fifo' has no mismatches.");
        if (stats1.errors_sys_adr)
            $display("Hint: Output sys_adr has %0d mismatches. First at time %0d",
                    stats1.errors_sys_adr, stats1.errortime_sys_adr);
        else
            $display("Hint: Output 'sys_adr' has no mismatches.");
        if (stats1.errors_ack_transfer)
            $display("Hint: Output ack_transfer has %0d mismatches. First at time %0d",
                    stats1.errors_ack_transfer, stats1.errortime_ack_transfer);
        else
            $display("Hint: Output 'ack_transfer' has no mismatches.");
        if (stats1.errors_output)
            $display("Hint: Output output has %0d mismatches. First at time %0d",
                    stats1.errors_output, stats1.errortime_output);
        else
            $display("Hint: Output 'output' has no mismatches.");
        if (stats1.errors_CIDAT)
            $display("Hint: Output CIDAT has %0d mismatches. First at time %0d",
                    stats1.errors_CIDAT, stats1.errortime_CIDAT);
        else
            $display("Hint: Output 'CIDAT' has no mismatches.");
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
