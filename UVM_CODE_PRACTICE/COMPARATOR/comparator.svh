module comparator(comparator_intf intff) ;
  
  
  always_comb begin
    
      intff.greater = 1'b0 ;
      intff.lesser  = 1'b0 ;
      intff.equal   = 1'b0 ;
    
    if(intff.data1 < intff.data2)begin
      
      intff.lesser  = 1'b1 ;
      
    end
      
    else if(intff.data1 > intff.data2)begin
      
      intff.greater = 1'b1 ;
      
    end
    
    else begin
      
      intff.equal   = 1'b1 ;
      
    end
    
      
    
  end
  
endmodule
