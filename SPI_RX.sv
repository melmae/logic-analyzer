module SPI_RX(clk, rst_n, SS_n, SCLK, MOSI, edg, len8, mask, match, SPItrig);
  input clk, rst_n, SS_n, SCLK, MOSI, edg, len8;
  input [15:0] mask, match;
  output SPItrig;
  
  typedef enum reg {IDLE, RX} state_t;
  state_t state, nxt_state;
  
  logic shift, done;
  logic SS_ff1, SS_ff2;
  logic SCLK_ff1, SCLK_ff2, SCLK_ff3, SCLK_rise, SCLK_fall;
  logic MOSI_ff1, MOSI_ff2, MOSI_ff3;
  logic [15:0] shft_reg;
  logic shift_edge;
  
  always_ff @(posedge clk, negedge rst_n) begin // double flop SS_n
    if (!rst_n) begin
	  SS_ff1 <= 0;
	  SS_ff2 <= 0;
	end else begin
	  SS_ff1 <= SS_n;
	  SS_ff2 <= SS_ff1;
	end
  end
  
  always_ff @(posedge clk, negedge rst_n) begin // triple flop SCLK
    if (!rst_n) begin
	  SCLK_ff1 <= 0;
	  SCLK_ff2 <= 0;
	  SCLK_ff3 <= 0;
	end else begin
	  SCLK_ff1 <= SCLK;
	  SCLK_ff2 <= SCLK_ff1;
	  SCLK_ff3 <= SCLK_ff2;
	end
  end
  
  assign SCLK_rise = SCLK_ff2 && !SCLK_ff3; // rising edge detect
  assign SCLK_fall = !SCLK_ff2 && SCLK_ff3; // falling edge detect
  assign shift_edge = edg ? SCLK_rise : SCLK_fall; // which edge to shift on
  
  always_ff @(posedge clk, negedge rst_n) begin // triple flop MOSI
    if (!rst_n) begin
	  MOSI_ff1 <= 0;
	  MOSI_ff2 <= 0;
	  MOSI_ff3 <= 0;
	end else begin
	  MOSI_ff1 <= MOSI;
	  MOSI_ff2 <= MOSI_ff1;
	  MOSI_ff3 <= MOSI_ff2;
	end
  end
  
  always_ff @(posedge clk) begin // determine shift
    if (shift)
	  shft_reg <= {shft_reg[14:0], MOSI_ff3};
	else
	 shft_reg <= shft_reg;
  end
  
  assign SPItrig = (len8 && done) ? ((shft_reg[7:0] & mask[7:0]) == (match[7:0] & mask[7:0])) : // 8-bit comparison
                   (done) ? ((shft_reg & mask) == (match & mask)) : 0; // 16-bit comparison
  
  always_ff @(posedge clk, negedge rst_n) begin // SM reset
    if (!rst_n)
	  state <= IDLE;
	else
	  state <= nxt_state;
  end
  
  always_comb begin // SM
    shift = 0;
	done = 0;
	nxt_state = state;
	
	case (state)
	  IDLE: 
	    if (SS_ff2)
		  nxt_state = RX;
		  
	  default: // RX
	    if (shift_edge) begin
		  shift = 1;
		  nxt_state = RX;
		end else begin
		if (SS_ff2) begin
		  done = 1;
		  nxt_state = IDLE;
		end 
		end
		
	endcase
  end

endmodule
