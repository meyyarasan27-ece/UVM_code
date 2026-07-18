`include "uvm_macros.svh"
import uvm_pkg::*;

class seq_item extends uvm_sequence_item ;
  
  
  rand logic [7:0] in1 , in2 ;
  logic [8:0] out ;
  
  `uvm_object_utils_begin(seq_item)
  `uvm_field_int(in1,UVM_ALL_ON)
  `uvm_field_int(in2,UVM_ALL_ON)
  `uvm_field_int(out,UVM_ALL_ON)
  
  `uvm_object_utils_end
  
  
  function new(string name = "seq_item");
    super.new(name) ;
    
  endfunction
  
  constraint inp_c { in1 inside {[0:255]}; 
                     in2 inside {[0:255]};
                     }
  
  
endclass


class base_seq extends uvm_sequence #(seq_item);
  seq_item req ;
  
  `uvm_object_utils(base_seq)
  
  function new(string name = "base_seq");
    super.new(name) ;
  endfunction
  
task body();
  repeat(100)
    begin
      req = seq_item::type_id::create("req");
      `uvm_info(get_type_name() , "Base sequence inside body",UVM_LOW) ;
      start_item(req);
      assert(req.randomize());
      finish_item(req);
end

endtask
  
endclass

class sequencer extends uvm_sequencer #(seq_item) ;
  `uvm_component_utils(sequencer)
  
  function new(string name = "sequencer", uvm_component parent = null);
    super.new(name,parent);
  endfunction
  
    function void build_phase(uvm_phase phase) ;
      super.build_phase(phase) ;
      
    endfunction
endclass
    
class driver extends uvm_driver #(seq_item) ;
 virtual add_intf vif ;
  seq_item req ;
  
  `uvm_component_utils(driver) 
  
  function new(string name = "driver " , uvm_component parent = null );
  
    super.new(name,parent);
    
  endfunction
  
  function void build_phase(uvm_phase phase) ;
    super.build_phase(phase);
    
    if(!uvm_config_db #(virtual add_intf) :: get(this,"","vif",vif))
      `uvm_fatal(get_type_name(),"uvm_config db failure") ;
    
  endfunction
      
      
 task run_phase (uvm_phase phase) ;
   vif.in1 <= 0;
   vif.in2 <= 0;
   
   
   wait(!vif.reset);
   forever begin
     seq_item_port.get_next_item(req) ;
    
     `uvm_info(get_type_name() ,$sformatf(" in1 = %0d , in2 = %0d",req.in1 ,req.in2),UVM_LOW);
    
     vif.in1 <= req.in1 ;
     vif.in2 <= req.in2 ;
     @(posedge vif.clk) ;
     #1step;
     seq_item_port.item_done() ;
     
   end
 endtask
  
endclass



class coverage extends uvm_component ;
  uvm_analysis_imp #(seq_item,coverage) cov_collect_export ;
  seq_item cov_item ;
  
  `uvm_component_utils(coverage)
  
  
  covergroup cg ;
    option.per_instance = 1;
    
    cp_data1 : coverpoint cov_item.in1{
      bins b_low  = {[0:63]};
      bins b_mid  = {[64:123]};
      bins b_high = {[124:255]};
    }
    
    
    cp_data2 : coverpoint cov_item.in2{
      bins b_low  = {[0:63]};
      bins b_mid  = {[64:123]};
      bins b_high = {[124:255]};
    }
    
    cp_out : coverpoint cov_item.out{
      bins b_low  = {[0:123]};
      bins b_mid  = {[124:255]};
      bins b_high = {[256:511]};
    }
    
    cross_out_in1 : cross cp_out , cp_data2 ;
    
  endgroup
  
  
  
  function new(string name = "coverage", uvm_component parent = null);
    
    super.new(name,parent);
    cov_collect_export = new("cov_collect_export",this);
    cg = new() ;
    
  endfunction
  
  
  function void write(seq_item item);
   
    cov_item = item ;
    cg.sample() ;
    
  endfunction
  
  
  
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
  $display("\n----------------------------------------");
  $display("          COVERAGE REPORT");
  $display("----------------------------------------");

  $display("DATA1 COVERAGE  = %0.2f%%",
           cg.cp_data1.get_coverage());

  $display("DATA2 COVERAGE  = %0.2f%%",
           cg.cp_data2.get_coverage());

  $display("OUTPUT COVERAGE  = %0.2f%%",
           cg.cp_out.get_coverage());

  $display("CROSS COVERAGE   = %0.2f%%",
           cg.cross_out_in1.get_coverage());

  $display("TOTAL COVERAGE   = %0.2f%%",
           cg.get_coverage());

  $display("----------------------------------------");
    
  endfunction
  
endclass

    
class monitor extends uvm_monitor ;
  `uvm_component_utils(monitor)
  virtual add_intf vif ;
  
  uvm_analysis_port #(seq_item) item_collect_port ;
  seq_item mon_item ;
  
  function new (string name = "monitor" , uvm_component parent = null) ;
    super.new(name,parent) ;
    item_collect_port = new("item_collect_port" , this);
    
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if(!uvm_config_db #(virtual add_intf)::get(this,"","vif",vif))
      
      `uvm_fatal(get_type_name() ," monitor doesnot get db");
    
  endfunction
  
  task run_phase(uvm_phase phase ) ;
    
     wait(!vif.reset);
    forever begin
     
      @(posedge vif.clk );
       #1step; 
       mon_item  = seq_item :: type_id::create("mon_item") ;
      
      mon_item.in1 = vif.in1 ;
      mon_item.in2 = vif.in2 ;
      mon_item.out = vif.out ;
      
       `uvm_info(get_type_name() ,$sformatf("in1 = %0d | in2 = %0d | out = %0d",mon_item.in1 ,mon_item.in2,mon_item.out),UVM_LOW);
      
      item_collect_port.write(mon_item);
     
      
    end
    
  endtask
  
  
endclass
    
    
    
    
class agent extends uvm_agent ;
  `uvm_component_utils(agent)
  
  sequencer seqr ;
  driver    drv ;
  monitor   mon ;
  
  
  
  function new(string name = "agent " , uvm_component parent = null);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase );
    super.build_phase(phase);
    
    if(get_is_active() == UVM_ACTIVE) begin
      seqr = sequencer :: type_id :: create("seqr",this);
      drv  = driver    :: type_id :: create("drv",this) ;
    end
    
    mon  = monitor   :: type_id :: create("mon",this) ;
    
  endfunction
  
  function void connect_phase (uvm_phase phase) ;
    super.connect_phase(phase);
    
    if(get_is_active() == UVM_ACTIVE) begin 
      drv.seq_item_port.connect(seqr.seq_item_export) ;
    end
    
  endfunction
  
  
endclass
    
    
class scoreboard extends uvm_scoreboard ;
  `uvm_component_utils(scoreboard)
  seq_item item_q[$] ;
  
  uvm_analysis_imp #(seq_item , scoreboard) item_collect_export ;
  
  function new(string name = "component" , uvm_component parent = null) ;
    
    super.new(name,parent);
    item_collect_export = new("item_collect_export",this);
  endfunction
  
  function void build_phase (uvm_phase phase);
    super.build_phase(phase) ;
    
  endfunction
  
  function void write(seq_item req);
    item_q.push_back(req);
  endfunction
  
  task run_phase(uvm_phase phase) ;
    seq_item sb_item ;
    forever begin
      wait(item_q.size() > 0);
      if(item_q.size() > 0) begin
        sb_item = item_q.pop_front() ;
        
        $display("--------------------------------------------");
      
        if((sb_item.in1 + sb_item.in2) == sb_item.out)begin
          `uvm_info(get_type_name(),$sformatf("[Matched] in1 =%0d | in2 = %0d | out = %0d",sb_item.in1,sb_item.in2,sb_item.out),UVM_LOW);
        end
        else begin
          `uvm_info(get_type_name(),$sformatf("[FAILED] in1 =%0d | in2 = %0d | out = %0d",sb_item.in1,sb_item.in2,sb_item.out),UVM_LOW);
        end
        $display("------------------------------------------");
      end
      
    end
    
  endtask
  
endclass
 
    
class env extends uvm_env ;
  agent agnt ;
  scoreboard scb ;
  coverage cov ;
  
  `uvm_component_utils(env)
  
  function new(string name = "env" , uvm_component parent = null);
    super.new(name,parent);
  endfunction
  
  function void build_phase (uvm_phase phase );
    super.build_phase(phase);
    
    agnt = agent :: type_id :: create("agnt",this);
    scb = scoreboard :: type_id :: create ("scb",this) ;
    cov = coverage :: type_id :: create("cov",this);
    
  endfunction
  
  function void connect_phase (uvm_phase phase) ;
    super.connect_phase(phase);
    
   agnt.mon.item_collect_port.connect(scb.item_collect_export);
    agnt.mon.item_collect_port.connect(cov.cov_collect_export);
    
  endfunction
endclass
    
 
    
class test extends uvm_test ;
  
  env envh ;
  base_seq bseq ;
  `uvm_component_utils(test)
  
  function new(string name = "test" , uvm_component parent = null) ;
    super.new(name, parent);
  endfunction
  
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    envh = env :: type_id :: create("envh",this) ;
  endfunction
  
  task run_phase (uvm_phase phase);
    phase.raise_objection(this);
    bseq = base_seq :: type_id :: create("bseq");
    
      bseq.start(envh.agnt.seqr);
    phase.drop_objection(this);
    `uvm_info(get_type_name(), "End of testcase", UVM_LOW);
  endtask
      
endclass
    

interface add_intf(input clk , input reset) ;
  
  logic [7:0]in1  ;
  logic [7:0]in2  ;
  logic [8:0]out  ;
  
  
endinterface
    
    
module top_tb ;
  
  logic clk ;
  logic reset ;
  
  always #5 clk = ~clk ;
  
  initial begin 
    clk = 0 ;
    reset = 1 ;
    #5 reset = 0 ;
    
  end
  
  add_intf vif(clk,reset) ;
  
  adder dut (.clk(vif.clk), .reset(vif.reset), .in1(vif.in1), .in2(vif.in2), .out(vif.out));
  
  
  initial begin 
    uvm_config_db #(virtual add_intf) :: set(null,"*","vif",vif);
  end
  
  initial begin
    run_test("test");
  end
  
endmodule
