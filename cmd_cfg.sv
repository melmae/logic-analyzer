module cmd_cfg(clk,rst_n,resp,send_resp,resp_sent,cmd,cmd_rdy,clr_cmd_rdy,
               set_capture_done,raddr,rdataCH1,rdataCH2,rdataCH3,rdataCH4,
			   rdataCH5,waddr,trig_pos,decimator,maskL,maskH,matchL,matchH,
			   baud_cntL,baud_cntH,TrigCfg,CH1TrigCfg,CH2TrigCfg,CH3TrigCfg,
			   CH4TrigCfg,CH5TrigCfg,VIH,VIL);
			   
  parameter ENTRIES = 384,	// defaults to 384 for simulation, use 12288 for DE-0
            LOG2 = 9;		// Log base 2 of number of entries
			
  input clk,rst_n;
  input [15:0] cmd;			// 16-bit command from UART (host) to be executed
  input cmd_rdy;			// indicates command is valid
  input resp_sent;			// indicates transmission of resp[7:0] to host is complete
  input set_capture_done;	// from the capture module (sets capture done bit in TrigCfg)
  input [LOG2-1:0] waddr;		// on a dump raddr is initialized to waddr
  input [7:0] rdataCH1;		// read data from RAMqueues
  input [7:0] rdataCH2,rdataCH3;
  input [7:0] rdataCH4,rdataCH5;
  
  output logic [7:0] resp;		// data to send to host as response (formed in SM)
  output reg send_resp;				// used to initiate transmission to host (via UART)
  output reg clr_cmd_rdy;			// when finished processing command use this to knock down cmd_rdy
  output reg [LOG2-1:0] raddr;		// read address to RAMqueues (same address to all queues)
  output reg [LOG2-1:0] trig_pos;	// how many sample after trigger to capture
  output reg [3:0] decimator;	// goes to clk_rst_smpl block
  output reg [7:0] maskL,maskH;				// to trigger logic for protocol triggering
  output reg [7:0] matchL,matchH;			// to trigger logic for protocol triggering
  output reg [7:0] baud_cntL,baud_cntH;		// to trigger logic for UART triggering
  output reg [5:0] TrigCfg;					// some bits to trigger logic, others to capture unit
  output reg [4:0] CH1TrigCfg,CH2TrigCfg;	// to channel trigger logic
  output reg [4:0] CH3TrigCfg,CH4TrigCfg;	// to channel trigger logic
  output reg [4:0] CH5TrigCfg;				// to channel trigger logic
  output reg [7:0] VIH,VIL;					// to dual_PWM to set thresholds
  
 
  typedef enum reg[3:0] {IDLE,DUMP,DUMP_CHECK,WAIT} state_t;
  
  state_t state,nstate;
  
  logic wrt_reg, inc, ld, done;
  
  // register flip flops
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  TrigCfg <= 6'h03;
	else if (set_capture_done)
	  TrigCfg[5] <= 1'b1;
	else if (cmd[13:8] == 6'b000000 && wrt_reg)
	  TrigCfg <= cmd[5:0];
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  CH1TrigCfg <= 5'h01;
	else if (cmd[13:8] == 6'b000001 && wrt_reg)
	  CH1TrigCfg <= cmd[4:0];
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  CH2TrigCfg <= 5'h01;
	else if (cmd[13:8] == 6'b000010 && wrt_reg)
	  CH2TrigCfg <= cmd[4:0];
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  CH3TrigCfg <= 5'h01;
	else if (cmd[13:8] == 6'b000011 && wrt_reg)
	  CH3TrigCfg <= cmd[4:0];
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  CH4TrigCfg <= 5'h01;
	else if (cmd[13:8] == 6'b000100 && wrt_reg)
	  CH4TrigCfg <= cmd[4:0];
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  CH5TrigCfg <= 5'h01;
	else if (cmd[13:8] == 6'b000101 && wrt_reg)
	  CH5TrigCfg <= cmd[4:0];
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  decimator <= 4'h0;
	else if (cmd[13:8] == 6'b000110 && wrt_reg)
	  decimator <= cmd[3:0];
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  VIH <= 8'hAA;
	else if (cmd[13:8] == 6'b000111 && wrt_reg)
	  VIH <= cmd[7:0];
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  VIL <= 8'h55;
	else if (cmd[13:8] == 6'b001000 && wrt_reg)
	  VIL <= cmd[7:0];
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  matchH <= 8'h00;
	else if (cmd[13:8] == 6'b001001 && wrt_reg)
	  matchH <= cmd[7:0];
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  matchL <= 8'h00;
	else if (cmd[13:8] == 6'b001010 && wrt_reg)
	  matchL <= cmd[7:0];
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  maskH <= 8'h00;
	else if (cmd[13:8] == 6'b001011 && wrt_reg)
	  maskH <= cmd[7:0];
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  maskL <= 8'h00;
	else if (cmd[13:8] == 6'b001100 && wrt_reg)
	  maskL <= cmd[7:0];
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  baud_cntH <= 8'h06;
	else if (cmd[13:8] == 6'b001101 && wrt_reg)
	  baud_cntH <= cmd[7:0];
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  baud_cntL <= 8'hC8;
	else if (cmd[13:8] == 6'b001110 && wrt_reg)
	  baud_cntL <= cmd[7:0];
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  trig_pos[LOG2-1:8] <= 8'h00;
	else if (cmd[13:8] == 6'b001111 && wrt_reg)
	  trig_pos[LOG2-1:8] <= cmd[7:0];
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  trig_pos[7:0] <= 8'h01;
	else if (cmd[13:8] == 6'b010000 && wrt_reg)
	  trig_pos[7:0] <= cmd[7:0];
  end
  
  // handling the dumping process
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  raddr <= 0;
	else if (ld)
	  raddr <= waddr;
	else if (inc)
	  raddr <= (raddr == ENTRIES - 1) ? 0 : raddr + 1; // handle wrap to 0
  end
  
  //assign done = (raddr == waddr) && resp_sent;
  
  // state machine
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  state <= IDLE;
	else
	  state <= nstate;
  end
  
  always_comb begin
    wrt_reg = 0;
	inc = 0;
	ld = 0;
	send_resp = 0;
	resp = resp;
	clr_cmd_rdy = 0;
    nstate = state;
	
    case(state)
	  IDLE: begin
	  ld = 1;
	  if (cmd_rdy) begin
	    if (cmd[15:14] == 2'b10) begin
		  if (cmd[10:8] <= 3'b101) begin
		    clr_cmd_rdy = 1;
			//ld = 1;
			case(cmd[10:8])
		    3'b001: resp = rdataCH1;
			3'b010: resp = rdataCH2;
			3'b011: resp = rdataCH3;
			3'b100: resp = rdataCH4;
			3'b101: resp = rdataCH5;
			default: resp = 8'hEE;
		    endcase
			
			nstate = DUMP;
		  end else begin
		    send_resp = 1;
			resp = 8'hEE;
		    nstate = WAIT;
		  end
		end else if (cmd[15:14] == 2'b01) begin // WRITE
		  wrt_reg = 1;
		  send_resp = 1;
		  clr_cmd_rdy = 1;
		  resp = (cmd[13:8] <= 6'h10) ? 8'hA5 : 8'hEE;
		  nstate = WAIT;
		end else if (cmd[15:14] == 2'b00) begin // READ
		  send_resp = 1;
		  clr_cmd_rdy = 1;
		  nstate = WAIT;
		  case(cmd[13:8])
		    6'b000000: resp = {2'b00, TrigCfg};
			6'b000001: resp = {3'b000, CH1TrigCfg};
			6'b000010: resp = {3'b000, CH2TrigCfg};
			6'b000011: resp = {3'b000, CH3TrigCfg};
			6'b000100: resp = {3'b000, CH4TrigCfg};
			6'b000101: resp = {3'b000, CH5TrigCfg};
			6'b000110: resp = {4'b0000, decimator};
			6'b000111: resp = {VIH};
			6'b001000: resp = {VIL};
			6'b001001: resp = {matchH};
			6'b001010: resp = {matchL};
			6'b001011: resp = {maskH};
			6'b001100: resp = {maskL};
			6'b001101: resp = {baud_cntH};
			6'b001110: resp = {baud_cntL};
			6'b001111: resp = {trig_pos[LOG2-1:(LOG2-1)/2]};
			6'b010000: resp = {trig_pos[((LOG2-1)/2):0]};
			default: resp = 8'hEE;
		  endcase
		end
	  end
	  end
	  DUMP: begin
	    //if (done)
		  //nstate = IDLE;
		//else begin
		  /* case(cmd[10:8])
		    3'b001: resp = rdataCH1;
			3'b010: resp = rdataCH2;
			3'b011: resp = rdataCH3;
			3'b100: resp = rdataCH4;
			3'b101: resp = rdataCH5;
			default: resp = 8'hEE;
		  endcase */
		  inc = 1;
		  send_resp = 1;
		  nstate = DUMP_CHECK;
	  end
		
	  DUMP_CHECK: begin
	    //send_resp = 1;
	    if (raddr == waddr)
		  nstate = IDLE;
	    else if (resp_sent) begin
		  case(cmd[10:8])
		    3'b001: resp = rdataCH1;
			3'b010: resp = rdataCH2;
			3'b011: resp = rdataCH3;
			3'b100: resp = rdataCH4;
			3'b101: resp = rdataCH5;
			default: resp = 8'hEE;
		  endcase
		  nstate = DUMP;
		end
	  end
  
	  default: // WAIT
	    if (resp_sent) begin
		  nstate = IDLE;
		end
		
	  
	endcase
  end

endmodule
  