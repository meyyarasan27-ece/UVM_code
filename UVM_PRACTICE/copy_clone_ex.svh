`include "uvm_macros.svh"
import uvm_pkg::* ;
  
  class transaction extends uvm_object ;
    `uvm_object_utils(transaction)
    bit [3:0] addr; 
    bit [7:0] data ;
    function new(string name ="transaction");
      super.new(name);
    endfunction
    
    virtual function void do_copy(uvm_object rhs);
      transaction t_h ;
      $cast(t_h,rhs) ;
    this.addr =  t_h.addr ;
    this.data =  t_h.data ;
      
      super.do_copy(t_h);
    endfunction 
    
    function void display(string message);
      $display("[%s] : the value of addr : %0d and the value of data : %0d ",message ,addr,data);
    endfunction
    
  endclass

module test ;
  transaction t_h1 , t_h2 ;
  
  initial begin
    t_h1 = transaction::type_id::create("t_h1");
   // t_h2 = transaction::type_id::create("t_h2"); 
    
    t_h1.data = 50 ;
    t_h1.addr = 10 ;
    
  //  t_h2.copy(t_h1) ;
    $cast(t_h2,t_h1.clone());
    
    t_h1.display("t_h1");
    t_h2.display("t_h2");
    
  end
endmodule
