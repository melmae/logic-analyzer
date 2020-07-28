module trigger_logic (CH1Trig, CH2Trig, CH3Trig, CH4Trig, CH5Trig, protTrig, 
                      armed, set_capture_done, rst_n, clk, triggered);
  input CH1Trig, CH2Trig, CH3Trig, CH4Trig, CH5Trig, protTrig;
  input armed, set_capture_done, rst_n, clk;
  output reg triggered;
  
  reg d;
  
  assign d = (&{CH1Trig, CH2Trig, CH3Trig, CH4Trig, CH5Trig, protTrig, armed});
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
	  triggered <= 1'b0;
	else if (set_capture_done)
	  triggered <= 1'b0;
	else if (triggered == 1'b1)
	  triggered <= triggered;
	else
	  triggered <= d;
	
  end
  
endmodule
