`include "uvm_macros.svh"
import uvm_pkg::* ;

class base_packet extends uvm_object ;
    int a ,b ;
  `uvm_object_utils(base_packet)
  
  
  function new(string name = "base_packet");
    super.new(name);
  endfunction
  
  function bit do_compare(uvm_object rhs , uvm_comparer comparer) ;
    base_packet bph ;
    if(!($cast(bph,rhs)))
      return 0 ;
    return (this.a == bph.a && this.b == bph.b );
  endfunction
  
  function void do_print(uvm_printer printer);
    printer.print_field("the value of a :",a,$bits(a),UVM_DEC);
    printer.print_field("the value of b :",b,$bits(b),UVM_DEC) ;
  endfunction
  
endclass



module top ;
  base_packet  bph1 ,bph2 ;
  
  initial begin
    bph1 = base_packet ::type_id::create("bph1");
    bph2 = base_packet ::type_id::create("bph2");
    
    bph1.a = 10 ;
    bph1.b = 20 ;
    
    bph2.a = 10 ;
    bph2.b = 10 ;
    
    bph1.print(uvm_default_tree_printer);
    bph2.print(uvm_default_line_printer) ;
    if(bph1.compare(bph2))
      $display("true");
    else
      $display("false");
    
  end
endmodule
