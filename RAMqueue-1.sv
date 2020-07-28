module RAMqueue (clk, we, waddr, wdata, raddr, rdata);

  parameter ENTRIES = 384;
  parameter LOG2 = 9;
  
  input clk, we;
  input [LOG2-1:0] waddr;
  input [7:0] wdata;
  input [LOG2-1:0] raddr;
  output reg [7:0] rdata;
  
  // synopsys translate_off
  reg [7:0]mem[0:ENTRIES-1];

  always@(posedge clk) begin
    if (we == 1'b1) begin
	  mem[waddr] <= wdata;
	end
	rdata <= mem[raddr];
  end
  // synopsys translate_on

endmodule
