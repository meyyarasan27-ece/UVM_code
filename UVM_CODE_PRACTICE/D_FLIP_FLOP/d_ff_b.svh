`include "uvm_macros.svh" 
import uvm_pkg::* ;



interface dff_intf(input clk ,input reset);
  
  logic data ;
  logic q ;
  
endinterface


class seq_item extends uvm_sequence_item ;
  rand logic data ;
   logic q ;
  
  `uvm_object_utils_begin(seq_item)
  
  `uvm_field_int(data,UVM_ALL_ON) 
  `uvm_field_int(q,UVM_ALL_ON)
  
  `uvm_object_utils_end
  
  
  function new(string name = "seq_item");
    super.new(name);
  endfunction
  
  
  constraint data_c {
    data dist {1 := 50 ,
               0:= 50};}

  
endclass


class base_seq extends uvm_sequence #(seq_item);
  seq_item req ;
  `uvm_object_utils(base_seq)
  
  function new(string name = "base_seq");
    super.new(name);
  endfunction
  
  
  task body() ;
    `uvm_info(get_type_name(),"base_sequence task body",UVM_LOW);
    
    repeat(10) begin
      req = seq_item :: type_id :: create("req");
      
      start_item(req) ;
      
      assert(req.randomize())
        else `uvm_fatal(get_type_name(),"RANDOMIZATION FAILED");
      
      finish_item(req);
      
    end
    
  endtask
  
endclass

class sequencer extends uvm_sequencer #(seq_item)  ;
  `uvm_component_utils(sequencer)
  
  function new(string name = "sequencer",uvm_component parent = null) ;
    
    super.new(name,parent);
  
    
  endfunction
 
  
endclass


class driver extends uvm_driver #(seq_item) ;
  virtual dff_intf vif ;

  
  `uvm_component_utils(driver)
  
  function new(string name = "driver" , uvm_component parent = null);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    
    if(!uvm_config_db #(virtual dff_intf)::get(this,"","vif",vif))
      `uvm_fatal("driver class","config database failed");
    
  endfunction
  
  task run_phase (uvm_phase phase) ;
    vif.data <= 0 ;
    wait(!vif.reset);
    
    forever begin
      seq_item_port.get_next_item(req);
      
     
      `uvm_info(get_type_name(),$sformatf("driver class  data = %0d",req.data),UVM_LOW);
      
      vif.data <= req.data ;
       @(posedge vif.clk) ;
      #1step ;
      seq_item_port.item_done() ;
    end
    
  endtask
  
endclass


class coverage extends uvm_subscriber #(seq_item);
  seq_item cov_item ;
  
  `uvm_component_utils(coverage)
  
  
  covergroup cg ;
    option.per_instance = 1 ;
    
    data_cp : coverpoint cov_item.data{
      bins b1 = {0,1};
    }
    
    q_cp : coverpoint cov_item.q {
      bins b1 = {0,1};
    }
    
  
  endgroup
  
  function new(string name = "coverage",uvm_component parent = null);
    
    super.new(name,parent);
    cg = new() ;
    
  endfunction
  
  function void write(seq_item t);
    
    cov_item = t ;
    cg.sample();
    
    endfunction
  
  
  
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info(get_type_name(),$sformatf("TOTAL COVERAGE IS %0.2f%%",cg.get_coverage()),UVM_LOW);
    
  endfunction
  
  
endclass



class monitor extends uvm_monitor ;
  virtual dff_intf vif ;
  uvm_analysis_port #(seq_item) item_collected_port ;
  seq_item mon_item ;
  
  `uvm_component_utils(monitor)
  
  function new (string name = "monitor", uvm_component parent = null) ;
    super.new(name,parent);
    item_collected_port = new("item_collected_port",this);
  endfunction
  
  
    function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if(!uvm_config_db #(virtual dff_intf)::get(this,"","vif",vif))
      `uvm_fatal("monitor class","config database failed");
    
  endfunction
  
  task run_phase(uvm_phase phase) ;
    
    forever begin
      
      mon_item = seq_item :: type_id :: create("mon_item");
      wait(!vif.reset) ;
      @(posedge vif.clk) ;
      #1step ;
      
      mon_item.data = vif.data ;
      mon_item.q    = vif.q ;
      
      `uvm_info(get_type_name(),$sformatf("class monitor data = %0b | q = %0b",mon_item.data,mon_item.q),UVM_LOW);
      item_collected_port.write(mon_item);
      
    end
  endtask
  
endclass

class agent extends uvm_agent ;
  sequencer seqr ;
  driver    drv  ;
  monitor   mon  ;
  
  `uvm_component_utils(agent)
  
  function new(string name = "agent" , uvm_component parent = null);
    super.new(name,parent) ;
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if(get_is_active() == UVM_ACTIVE)begin
      seqr = sequencer :: type_id :: create("seqr" ,this);
      drv = driver :: type_id :: create("drv",this);
    end
    
    mon = monitor :: type_id :: create("mon",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    
    super.connect_phase(phase);
    
    if(get_is_active() == UVM_ACTIVE)begin
      drv.seq_item_port.connect(seqr.seq_item_export) ;
    end
    
  endfunction
  
endclass


class scoreboard extends uvm_scoreboard ;
  `uvm_component_utils(scoreboard)
  uvm_analysis_imp #(seq_item , scoreboard) item_collected_export ;
  
  function new (string name = "scoreboard" , uvm_component parent = null);
    super.new(name,parent) ;
    
    item_collected_export = new("item_collected_export",this);
    
  endfunction
  
  function void write(seq_item scb_item) ;
    
    if(scb_item.data == scb_item.q)begin
      
      `uvm_info(get_type_name(),$sformatf("[PASS] : data = %0b | q = %0b",scb_item.data,scb_item.q),UVM_LOW);
      $display("----------------------------------------");
    end
    else begin
      
      `uvm_error(get_type_name(),$sformatf("[FAIL] : data = %0b | q = %0b",scb_item.data,scb_item.q));
      $display("----------------------------------------");
    end 
  endfunction
    
    
  
endclass


class env extends uvm_env ;
  agent agnt ;
  scoreboard scb ;
  coverage cov ;
  
  `uvm_component_utils(env) 
  
  function new(string name = "env" , uvm_component parent = null);
    super.new(name,parent) ;
    
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    agnt = agent :: type_id :: create("agnt",this);
    scb  = scoreboard :: type_id :: create("scb",this);
    cov = coverage :: type_id :: create("cov",this);
    
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    agnt.mon.item_collected_port.connect(scb.item_collected_export);
    agnt.mon.item_collected_port.connect(cov.analysis_export) ;
  endfunction
  
endclass

class test extends uvm_test ;
  env envh  ;
  base_seq bseq ;
  `uvm_component_utils(test)
  
  function new (string name = "test",uvm_component parent = null);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    envh = env :: type_id :: create("envh",this);
    
  endfunction
  
  task run_phase(uvm_phase phase);
    phase.raise_objection(this) ;
    
    bseq = base_seq :: type_id :: create("bseq");
    
    
      
      bseq.start(envh.agnt.seqr);
    
    
    phase.drop_objection(this);
    `uvm_info(get_type_name(), "End of testcase", UVM_LOW);
    
  endtask
  
  
endclass


module top_tb ;
  
  logic clk ;
  logic reset  ;
  
  always #5 clk = ~clk ;
  
  initial begin
    clk = 0 ;
    
    reset = 1 ;
    
    #5 reset = 0 ;
    
  end
  
  dff_intf intff(clk,reset) ;
  
  dff dut (.clk(intff.clk) ,.reset(intff.reset), .data(intff.data), .q(intff.q));
  
  
  initial begin
    uvm_config_db #(virtual dff_intf)::set(null,"*","vif",intff);
  end
  
  initial begin
    run_test("test");
  end
  
endmodule
