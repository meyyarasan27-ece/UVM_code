`include "uvm_macros.svh"
import uvm_pkg::* ;

class packet extends uvm_object ;
 rand int data ;
 rand reg [3:0] addr ;
 rand logic enable ;
  
  `uvm_object_utils_begin(packet)
  
  `uvm_field_int(data,UVM_ALL_ON)
  `uvm_field_int(addr,UVM_NOCOPY)
  `uvm_field_int(enable,UVM_NOCOMPARE)
  
  `uvm_object_utils_end
  
  function new(string name ="packet") ;
    super.new(name) ;
  endfunction
  
  function void display(string  handle) ;
    $display("%s the value of data %d and the value of address %d and value of enable is %d",handle,data,addr,enable);
  endfunction
endclass

module top ;
  packet p_h1 , p_h2;
  
  initial begin
    p_h1 = packet::type_id::create("p_h1");
    p_h2 = packet::type_id::create("p_h2");
    
    p_h1.randomize();
    
    p_h2.copy(p_h1);
    p_h1.display("p_h1") ;
    p_h2.display("p_h2") ;
  end
  
endmodule
