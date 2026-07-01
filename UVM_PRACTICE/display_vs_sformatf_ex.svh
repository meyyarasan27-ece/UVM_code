module tb ;
  
  int a = 10 ;
  int b = 20 ;
  string msg ;
  
  initial begin
    $display("the value of a is %0d",a);
   msg =  $sformatf("using $sformatf statement : b = %0d" ,b);
    $display(msg);
  end
endmodule
