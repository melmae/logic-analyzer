module UART_rx(clk, rst_n, RX, clr_rdy, rx_data, rdy);
  input clk, rst_n, RX, clr_rdy;
  output reg [7:0] rx_data;
  output reg rdy;
  
  typedef enum reg[1:0] {IDLE, REC} state_t;
  state_t state, nxt_state;
  
  logic [3:0] bit_cnt;
  logic [5:0] baud_cnt;
  logic start, set_rdy, receiving, shift;
  logic [8:0] rx_shft_reg;
  logic RX_ff1, RX_ff2;
  
  always @(posedge clk) begin // bit counter
    if ({start, shift} == 2'b01)
	  bit_cnt <= bit_cnt + 1;
	else if ({start, shift} == 2'b00)
	  bit_cnt <= bit_cnt;
	else
	  bit_cnt <= 0;
  end
  
  always @(posedge clk) begin // baud counter
	if (start)
      baud_cnt <= 6'd17;
    else if (shift)
      baud_cnt <= 6'd34;
    else if (receiving)
      baud_cnt <= baud_cnt-1;
  end
  
  assign shift = ~|baud_cnt; // shift assignment
  
  always_ff @(posedge clk) begin // shifter
    if (shift == 0) begin
	  rx_shft_reg <= rx_shft_reg;
	end else begin
	  rx_shft_reg <= {~RX, rx_shft_reg[8:1]};
	end
  end
  
  assign rx_data = rx_shft_reg[7:0]; // rx_data assignment
  
  always_ff @(posedge clk, negedge rst_n) begin // first RX flop
    if (!rst_n)
	  RX_ff1 <= 0;
	else
	  RX_ff1 <= RX;
  end
  
  always_ff @(posedge clk, negedge rst_n) begin // second RX flop
    if (!rst_n)
	  RX_ff2 <= 0;
	else
	  RX_ff2 <= RX_ff1;
  end
  
  always_ff @(posedge clk, negedge rst_n) begin // SM flop
    if (!rst_n)
	  state <= IDLE;
	else
	  state <= nxt_state;
  end
  
  always_comb begin // SM
    set_rdy = 0;
	start = 0;
	receiving = 0;
	nxt_state = state;
	
	case(state)
	  IDLE:
	    if (RX_ff2) begin
		  start = 1;
		  nxt_state = REC;
		end
	  default: begin // REC
	    if (bit_cnt == 10) begin
		  set_rdy = 1;
		  nxt_state = IDLE;
		end
		receiving = 1;
		end
	endcase
  end
  
  always_ff @(posedge clk, negedge rst_n) begin // determining rdy
    if (!rst_n)
	  rdy <= 0;
	else if (start || clr_rdy)
	  rdy <= 0;
	else if (set_rdy)
	  rdy <= 1;
  end
endmodule
