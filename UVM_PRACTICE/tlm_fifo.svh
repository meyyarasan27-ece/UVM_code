`include "uvm_macros.svh"
import uvm_pkg::* ;

class packet extends uvm_object ;
  `uvm_object_utils(packet);
  
  rand int data ;
  
  function new(string name = "packet");
    super.new(name);
  endfunction
  
  function void display(string msg);
    $display("%s the value of data is %d",msg,data);
  endfunction
  
endclass

class generator extends uvm_component ;
  uvm_blocking_put_port #(packet) put_port ;
  
  `uvm_component_utils(generator);
  packet pkt ;
  
  function new(string name = "generator" , uvm_component parent = null);
    
    super.new(name,parent);
    
    put_port = new("put_port",this);
  endfunction
  
  
  task run_phase(uvm_phase phase) ;
    
    phase.raise_objection(this);
    
    repeat(5)begin
      pkt = packet::type_id::create("pkt");
      assert(pkt.randomize())
        else `uvm_fatal("RAND_FAIL","randomization error");
      
      put_port.put(pkt);
      
    end
    
    phase.drop_objection(this);
    
  endtask
  
endclass

class driver extends uvm_component ;
  
  uvm_blocking_get_port #(packet) get_port ;
  
  `uvm_component_utils(driver) ;
   packet pkt ;
  
  
  function new(string name = "driver" , uvm_component parent = null);
    
    super.new(name,parent);
    get_port = new("get_port" , this);
  endfunction
  
  
  task run_phase(uvm_phase phase);
    
    repeat(5)begin
      get_port.get(pkt);
      pkt.display("driver") ;
    end
    
  endtask
  
endclass

class agent extends uvm_component ;
  
  `uvm_component_utils(agent)
  generator genh ;
  driver drvh ;
  
  uvm_tlm_fifo #(packet) fifo ;
  
  function new(string name = "agent",uvm_component parent = null);
    
    super.new(name,parent);

    fifo = new("fifo",this);
    
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    genh = generator::type_id::create("genh",this);
    drvh = driver::type_id::create("drvh",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    genh.put_port.connect(fifo.put_export);
    drvh.get_port.connect(fifo.get_export);
  endfunction
  
endclass


class test extends uvm_test ;
  agent agnth ;
  
  `uvm_component_utils(test);
  
  function new(string name = "test" , uvm_component parent = null) ;
    
    super.new(name ,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agnth = agent::type_id::create("agnth",this);
  endfunction
endclass

module top ;
  initial begin
    run_test("test");
  end
endmodule
