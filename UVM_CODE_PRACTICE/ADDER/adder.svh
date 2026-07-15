module adder(input clk , reset , 
             input [7:0] in1 , in2 ,
             output logic [8:0]out);
  
  
  always_ff @(posedge clk or posedge reset) begin
    
    if(reset)
      out <= 9'b0 ;
    else 
      out <= in1 + in2 ;
    
  end
  
  
endmodule 
