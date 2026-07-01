`include "uvm_macros.svh" ;
import uvm_pkg::* ;

class base_driver extends uvm_driver ;
  
  `uvm_component_utils(base_driver)
  
  function new(string name = "base_driver" , uvm_component parent);
    super.new(name,parent);
  endfunction
endclass

class driver1 extends base_driver ;
  `uvm_component_utils(driver1)
  
  function new( string name = "driver1" , uvm_component parent);
    super.new(name,parent);
  endfunction
endclass

class driver2 extends base_driver ;
  `uvm_component_utils(driver2)
  
  function new( string name = "driver2" , uvm_component parent);
    super.new(name,parent);
  endfunction
endclass

class base_agent extends uvm_agent ;
  
  `uvm_component_utils(base_agent)
  base_driver bdriver_h ;
  
  function new( string name = "base_agent" ,uvm_component parent) ;
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    bdriver_h = base_driver :: type_id :: create("bdriver_h",this);
  //  super.build_phase(phase);
  endfunction
  
endclass

class child_agent extends base_agent ;
  
  `uvm_component_utils(child_agent)
  
  function new(string name = "child_agent", uvm_component parent);
    super.new(name,parent);
    
  endfunction
  
endclass

class env extends uvm_env ;
  
  `uvm_component_utils(env)
  base_agent bagent_h ;

  
  function new(string name = "env" , uvm_component parent) ;
    
    super.new(name,parent);
    
  endfunction
  
  function void build_phase(uvm_phase phase);
    bagent_h = base_agent :: type_id :: create("bagent_h" ,this);
    super.build_phase(phase) ;
  endfunction
endclass

class test extends uvm_test ;
  `uvm_component_utils(test)
  env envh ;
  function new(string name = "test" , uvm_component parent) ;
    
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase) ;
    uvm_factory factory = uvm_factory :: get() ;
    envh = env :: type_id :: create("envh",this);
    super.build_phase(phase);
    //set_type_override_by_type(base_agent::get_type() , child_agent :: get_type()) ;
    `ifdef DRV1
    set_type_override_by_type(base_driver :: get_type() ,driver1 :: get_type()) ;
    `elsif DRV2
    set_type_override_by_type(base_driver :: get_type() ,driver2 :: get_type()) ;
    `endif
  //  set_inst_override_by_type("envh.bagent_h",base_driver :: get_type() , driver1 :: get_type());
    factory.print();
  endfunction
endclass

module top ;
  
  initial begin
    run_test("test");
  end
  
endmodule
