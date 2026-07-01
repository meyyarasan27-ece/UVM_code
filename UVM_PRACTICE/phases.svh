`include "uvm_macros.svh"
import uvm_pkg::* ;

class driver extends uvm_driver ;
  `uvm_component_utils(driver)
  
  function new(string name = "driver" , uvm_component parent = null);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("BUILD_PHASE","BUILD PHASE CALLED FROM DRIVER COMPONENT",UVM_LOW);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase) ;
    `uvm_info("CONNECT_PHASE","CONNECT PHASE CALLED FROM DRIVER COMPONENT",UVM_LOW);
  endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    
      `uvm_info("END_OF_ELABORATION_PHASE","END OF ELABORATION PHASE CALLED FROM DRIVER COMPONENT",UVM_LOW);
    
  endfunction 
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info("RUN_PHASE","RUN PHASE CALLED FROM DRIVER COMPONENT",UVM_LOW);
  endtask

endclass




class monitor extends uvm_monitor ;
  `uvm_component_utils(monitor)
  
  function new(string name = "monitor" , uvm_component parent = null);
    super.new(name,parent);
    endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("BUILD_PHASE","BUILD PHASE CALLED FROM MONITOR COMPONENT",UVM_LOW);
  endfunction
  
    function void connect_phase(uvm_phase phase);
    super.connect_phase(phase) ;
      `uvm_info("CONNECT_PHASE","CONNECT PHASE CALLED FROM MONITOR COMPONENT",UVM_LOW);
  endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    
      `uvm_info("END_OF_ELABORATION_PHASE","END OF ELABORATION PHASE CALLED FROM MONITOR COMPONENT",UVM_LOW);
    
  endfunction  
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info("RUN_PHASE","RUN PHASE CALLED FROM MONITOR COMPONENT",UVM_LOW);
  endtask
  
endclass




class agent extends uvm_agent ;
  `uvm_component_utils(agent)
  driver drv_h ;
  monitor mon_h ;
  
  function new(string name = "agent" , uvm_component parent = null );
    super.new(name,parent);
  endfunction
  
  
  function void build_phase(uvm_phase phase);
    
    super.build_phase(phase);
    `uvm_info("BUILD_PHASE","BUILD PHASE CALLED FROM AGENT CLASS",UVM_LOW);
      drv_h = driver::type_id::create("drv_h",this);
      mon_h = monitor::type_id::create("mon_h",this);
  endfunction
  
    function void connect_phase(uvm_phase phase);
    super.connect_phase(phase) ;
      `uvm_info("CONNECT_PHASE","CONNECT PHASE CALLED FROM AGENT COMPONENT",UVM_LOW);
  endfunction
  
  
    function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    
      `uvm_info("END_OF_ELABORATION_PHASE","END OF ELABORATION PHASE CALLED FROM AGENT COMPONENT",UVM_LOW);
    
  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info("RUN_PHASE","RUN PHASE CALLED FROM AGENT COMPONENT",UVM_LOW);
  endtask
  
endclass



class environment extends uvm_env ;
  `uvm_component_utils(environment)
  agent agnt_h ;
  function new(string name = "environment",uvm_component parent = null) ;
    super.new(name,parent);
    
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("BUILD_PHASE","BUILD PHASE CALLED FROM ENVIRONMENT",UVM_LOW);
      agnt_h = agent::type_id::create("agnt_h",this);
  endfunction

    function void connect_phase(uvm_phase phase);
    super.connect_phase(phase) ;
      `uvm_info("CONNECT_PHASE","CONNECT PHASE CALLED FROM ENVIRONMENT COMPONENT",UVM_LOW);
  endfunction
  
    function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    
      `uvm_info("END_OF_ELABORATION_PHASE","END OF ELABORATION PHASE CALLED FROM ENVIRONMENT COMPONENT",UVM_LOW);
    
  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info("RUN_PHASE","RUN PHASE CALLED FROM ENVIRONMENT COMPONENT",UVM_LOW);
  endtask
  
endclass




class test extends uvm_test ;
  `uvm_component_utils(test)
  environment env_h ;
  
  function new(string name = "test" , uvm_component parent = null);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("BUILD_PHASE","BUILD PHASE CALLED FROM TEST",UVM_LOW);
      env_h = environment::type_id::create("env_h",this);
  endfunction
  
    function void connect_phase(uvm_phase phase);
    super.connect_phase(phase) ;
      `uvm_info("CONNECT_PHASE","CONNECT PHASE CALLED FROM TEST COMPONENT",UVM_LOW);
  endfunction
  
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
    `uvm_info("END_OF_ELABORATION_PHASE","END OF ELABORATION PHASE CALLED FROM TEST COMPONENT",UVM_LOW);
    
  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    `uvm_info("RUN_PHASE","RUN PHASE CALLED FROM TEST COMPONENT",UVM_LOW);
  endtask
  
endclass
    
    
module top ;
   
  initial begin
    run_test("test");
  end
  
endmodule
