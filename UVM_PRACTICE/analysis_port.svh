`include "uvm_macros.svh"
import uvm_pkg::* ;

class transaction extends uvm_object ;
  rand int data  ;
  
  `uvm_object_utils(transaction)
  
  function new(string name = "transaction");
    
    super.new(name);
    
  endfunction
  
endclass



class producer extends uvm_component ;
  uvm_analysis_port #(transaction) producer_put ;
  transaction t_h ;
  `uvm_component_utils(producer)
  
  function new(string name = "producer",uvm_component parent = null);
    super.new(name,parent);
    producer_put = new("producer_put",this);
  endfunction
  
  task run_phase (uvm_phase phase);
    super.run_phase(phase);
    
    t_h = transaction::type_id::create("t_h");
    assert(t_h.randomize()) 
      else `uvm_fatal("RAND_FAIL","randomization failed");
    `uvm_info(get_type_name(),$sformatf("the value of data is %0d",t_h.data),UVM_LOW);
    
    producer_put.write(t_h);
    
  endtask
endclass



class consumer_a extends uvm_component ;
  
  uvm_analysis_imp #(transaction,consumer_a) consumer_a_imp ;
  transaction t_h ;
  `uvm_component_utils(consumer_a)
  
  function new(string name = "consumer_a" , uvm_component parent = null);
    super.new(name,parent);
    consumer_a_imp = new("consumer_a_imp",this);
  endfunction
  
  function void write(transaction t_h);
    `uvm_info(get_type_name(),$sformatf("the recived value is %0d",t_h.data),UVM_LOW);
    
  endfunction
endclass


class consumer_b extends uvm_component ;
  
  uvm_analysis_imp #(transaction,consumer_b) consumer_b_imp ;
  transaction t_h ;
  `uvm_component_utils(consumer_b)
  
  function new(string name = "consumer_b" , uvm_component parent = null);
    super.new(name,parent);
    consumer_b_imp = new("consumer_b_imp",this);
  endfunction
  
  function void write(transaction t_h);
    `uvm_info(get_type_name(),$sformatf("the recived value is %0d",t_h.data),UVM_LOW);
    
  endfunction
endclass

class consumer_c extends uvm_component ;
  
  uvm_analysis_imp #(transaction,consumer_c) consumer_c_imp ;
  transaction t_h ;
  `uvm_component_utils(consumer_c)
  
  function new(string name = "consumer_c" , uvm_component parent = null);
    super.new(name,parent);
    consumer_c_imp = new("consumer_c_imp",this);
  endfunction
  
  function void write(transaction t_h);
    `uvm_info(get_type_name(),$sformatf("the recived value is %0d",t_h.data),UVM_LOW);
    
  endfunction
endclass


class env extends uvm_env ;
  `uvm_component_utils(env);
  producer prdh ;
  consumer_a   ah ;
  consumer_b   bh ;
  consumer_c   ch ;
  
  function new(string name = "env" , uvm_component parent = null);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    prdh = producer::type_id::create("prdh",this);
    ah = consumer_a::type_id::create("ah",this);
    bh = consumer_b::type_id::create("bh",this);
    ch = consumer_c::type_id::create("ch",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    prdh.producer_put.connect(ah.consumer_a_imp);
    prdh.producer_put.connect(bh.consumer_b_imp);
    prdh.producer_put.connect(ch.consumer_c_imp);
    
  endfunction
endclass


class test extends uvm_test ;
  env envh ;
  `uvm_component_utils(test)
  
  function new(string name = "test" , uvm_component parent = null);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    envh = env::type_id::create("envh",this);
  endfunction
    
endclass

module top ;
  initial begin
    run_test("test");
  end
endmodule
