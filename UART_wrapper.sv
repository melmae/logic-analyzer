module UART_wrapper(clk, rst_n, RX, TX, clr_cmd_rdy, send_resp, resp, cmd_rdy, resp_sent, cmd);
  input clk, rst_n, RX, clr_cmd_rdy, send_resp;
  input [7:0] resp;
  output logic cmd_rdy, resp_sent, TX;
  output logic [15:0] cmd;
  
  typedef enum reg [1:0] {IDLE, LOW} state_t;
  state_t state, nxt_state;
  
  logic rx_rdy, clr_rx_rdy, high;
  logic [7:0] rx_data, cmd_high;

  UART iUART(.clk(clk),.rst_n(rst_n),.RX(RX),.TX(TX),.rx_rdy(rx_rdy),
             .clr_rx_rdy(clr_rx_rdy),.rx_data(rx_data),.trmt(send_resp),
			 .tx_data(resp),.tx_done(resp_sent));
			 
  always_ff @(posedge clk) begin
    if (high) 
	  cmd_high <= rx_data;
	else
	  cmd_high <= cmd_high;
  end
  
  assign cmd[15:8] = cmd_high;
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  state <= IDLE;
	else
	  state <= nxt_state;
  end
  
  always_comb begin
    high = 0;
	cmd_rdy = 0;
	clr_rx_rdy = 0;
	cmd[7:0] = cmd[7:0];
    nxt_state = state;
	
	case (state)
	  IDLE:
	    if (rx_rdy) begin
		  high = 1;
		  clr_rx_rdy = 1;
		  nxt_state = LOW;
	    end
		
	  default: // LOW
	   if (rx_rdy) begin
	     clr_rx_rdy = 1;
		 cmd_rdy = 1;
		 cmd[7:0] = rx_data;
		 nxt_state = IDLE;
	   end
	  
	  //default: // LOW
	    //if (clr_cmd_rdy)
		  //nxt_state = IDLE;
	
	endcase
  
  end

endmodule
