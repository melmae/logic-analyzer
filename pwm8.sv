module pwm8 (clk, rst_n, duty, PWM_sig);
  input clk, rst_n;
  input [7:0] duty;
  output reg PWM_sig;
  
  reg [7:0] cnt;
  reg comparison;
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  cnt <= 0;
	else
	  cnt <= cnt + 1;
  end
  
  always_comb begin
    if (cnt <= duty)
	  comparison = 1;
	else
	  comparison = 0;
  end
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  PWM_sig <= 0;
	else
	  PWM_sig <= comparison;
  end

endmodule
