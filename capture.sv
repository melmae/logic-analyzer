module capture(clk,rst_n,wrt_smpl,run,capture_done,triggered,trig_pos,
               we,waddr,set_capture_done,armed);

  parameter ENTRIES = 384,		// defaults to 384 for simulation, use 12288 for DE-0
            LOG2 = 9;			// Log base 2 of number of entries
  
  input clk;					// system clock.
  input rst_n;					// active low asynch reset
  input wrt_smpl;				// from clk_rst_smpl.  Lets us know valid sample ready
  input run;					// signal from cmd_cfg that indicates we are in run mode
  input capture_done;			// signal from cmd_cfg register.
  input triggered;				// from trigger unit...we are triggered
  input [LOG2-1:0] trig_pos;	// How many samples after trigger do we capture
  
  output we;					// write enable to RAMs
  output reg [LOG2-1:0] waddr;	// write addr to RAMs
  output reg set_capture_done;		// asserted to set bit in cmd_cfg
  output reg armed;				// we have enough samples to accept a trigger

  typedef enum reg[1:0] {IDLE,CAPTURE,WAIT_RD} state_t;
  state_t state,nxt_state;
  
  reg [LOG2-1:0] trig_cnt;						// how many samples post trigger?
  
  logic clr, clr_armed;
  
  always_ff @(posedge clk, negedge rst_n) begin // armed flop
    if (!rst_n)
	  armed <= 0;
    else if (clr_armed)
	  armed <= 0;
	else if (waddr + trig_pos == ENTRIES - 1)
	  armed <= 1;
  end
  
  always_ff @(posedge clk, negedge rst_n) begin // trig_cnt flop
    if (!rst_n)
	  trig_cnt <= 0;
	else if (clr)
	  trig_cnt <= 0;
	else if (we && triggered)
	  trig_cnt <= trig_cnt + 1;
  end
  
  always_ff @(posedge clk, negedge rst_n) begin // waddr flop
    if (!rst_n)
	  waddr <= 0;
    else if (clr)
	  waddr <= 0;
	else if (we)
	  waddr <= (waddr == ENTRIES - 1) ? 0 : waddr + 1;
  end
  
  always_ff @(posedge clk, negedge rst_n) begin // SM flop
    if (!rst_n)
	  state <= IDLE;
	else 
	  state <= nxt_state;
  end
  
  assign we = wrt_smpl && run && !capture_done;
  
  assign set_capture_done = triggered && (trig_cnt == trig_pos);
  
  always_comb begin // SM
    clr = 0;
	clr_armed = 0;
	nxt_state = state;
	
    case(state)
	  IDLE:
	    if (run) begin
		  clr = 1;
		  nxt_state = CAPTURE;
		end
	  
	  CAPTURE:
	    if (we) begin
	      if (triggered) begin
		    if (trig_cnt == trig_pos) begin
			  clr_armed = 1;
			  nxt_state = WAIT_RD;
		    end
		  end
	    end
		
	  default: // WAIT_RD
	    if (!capture_done)
		  nxt_state = IDLE;
	
	endcase
	
  end
  
endmodule
