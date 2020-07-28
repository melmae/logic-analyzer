module UART_tx(clk, rst_n, TX, trmt, tx_data, tx_done);
  input clk, rst_n, trmt;
  input [7:0] tx_data;
  output reg TX, tx_done;
  
  typedef enum reg [1:0] {IDLE, TRMT} state_t;
  state_t state, nxt_state;
  
  logic [3:0] bit_cnt;
  logic [5:0] baud_cnt;
  logic shift, load, transmitting;
  logic [8:0] tx_shft_reg;
  
  always_ff @(posedge clk) begin // bit counter
    if ({load, shift} == 2'b01)
	  bit_cnt <= bit_cnt + 1;
	else if ({load, shift} == 2'b00)
	  bit_cnt <= bit_cnt;
	else
	  bit_cnt <= 0;
  end
  
  always_ff @(posedge clk) begin // baud counter
	if (load || shift)
      baud_cnt <= 6'd34;	
    else if (transmitting)
      baud_cnt <= baud_cnt-1;	
  end
  
  assign shift = ~|baud_cnt; // shift assignment
  
  always @(posedge clk) begin // shifter 
	if (load)
      tx_shft_reg <= {tx_data,1'b0};
    else if (shift)
      tx_shft_reg <= {1'b1,tx_shft_reg[8:1]};
  end
  
  assign TX = ~tx_shft_reg[0]; // TX assignment
  
  always_ff @(posedge clk, negedge rst_n) begin // SM flop
    if(!rst_n)
	  state <= IDLE;
	else
	  state <= nxt_state;
  end
  
  always_comb begin // SM
	load = 0;
	transmitting = 0;
	nxt_state = state;
	
	case(state)
	  IDLE: 
	    if (trmt) begin
		  load = 1;
		  nxt_state = TRMT;
		end
	   default: begin // TRMT
	     if (bit_cnt == 10) begin
		   nxt_state = IDLE;
		 end else begin
		   nxt_state = TRMT;
		 end
		 transmitting = 1;
		 end
	endcase
  end
  
  always_ff @(posedge clk, negedge rst_n) begin // setting tx_done
	if (!rst_n)
	  tx_done <= 0;
	else if (trmt)
	  tx_done <= 0;
	else if (bit_cnt == 10)
	  tx_done <= 1;
  end

endmodule
