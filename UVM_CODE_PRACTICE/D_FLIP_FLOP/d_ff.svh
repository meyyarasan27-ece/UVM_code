module dff (input logic clk ,reset ,data ,output logic q);
  
  always_ff @(posedge clk or posedge reset) begin
    
    if(reset) 
      q <= 1'b0 ;
    
    else
      q <= data ;
      
    
  end
  
  
endmodule
