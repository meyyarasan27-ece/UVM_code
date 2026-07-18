`include "uvm_macros.svh"
import uvm_pkg::*;

interface alu_intf  ;
  
  logic [7:0]A  ;
  logic [7:0]B  ;
  logic [2:0]opcode  ;
  logic [8:0]result ;
  
  modport DRIVER(output A ,
                 output B ,
                 output opcode) ;
  
  modport MONITOR(input A ,
                  input B ,
                  input opcode ,
                  input result );
  
  
endinterface


class sequence_item extends uvm_sequence_item ;
  
  
  rand logic [7:0] A ;
  rand logic [7:0] B ;
  rand logic [2:0] opcode ;


  logic [8:0] result ;
  
  `uvm_object_utils_begin(sequence_item)
  `uvm_field_int(A,UVM_ALL_ON)
  `uvm_field_int(B,UVM_ALL_ON)
  `uvm_field_int(opcode,UVM_ALL_ON)
  `uvm_field_int(result,UVM_ALL_ON)
  
  `uvm_object_utils_end
  
  
  function new(string name = "sequence_item");
    super.new(name) ;
    
  endfunction
  
  constraint A_constraint { 
    A inside {[0:255]};
  }
  
  constraint B_constraint { 
    B inside {[0:255]};
  }
  
  constraint opcode_constraint { 
    opcode inside {[0:7]};
  }
  
endclass


class base_seq extends uvm_sequence #(sequence_item);
  sequence_item req ;
  
  `uvm_object_utils(base_seq)
  
  function new(string name = "base_seq");
    super.new(name) ;
  endfunction
  
  task body();
    repeat(100)
      begin
        req = sequence_item::type_id::create("req");
      
        `uvm_info(get_type_name() , "Base sequence inside body",UVM_LOW);
        start_item(req);
      
       assert(req.randomize())
         else `uvm_fatal(get_type_name(),"RANDOMIZARION FAILED");
      
       finish_item(req);
      end
  endtask
  
endclass

class sequencer extends uvm_sequencer #(sequence_item) ;
  `uvm_component_utils(sequencer)
  
  function new(string name = "sequencer", uvm_component parent = null);
    super.new(name,parent);
  endfunction
  

endclass
    
class driver extends uvm_driver #(sequence_item) ;
 sequence_item req;
 virtual alu_intf.DRIVER vif ;
  
  `uvm_component_utils(driver) 
  
  function new(string name = "driver " , uvm_component parent = null );
  
    super.new(name,parent);
    
  endfunction
  
  function void build_phase(uvm_phase phase) ;
    super.build_phase(phase);
    
    if(!uvm_config_db #(virtual alu_intf.DRIVER) :: get(this,"","vif",vif))
      `uvm_error(get_type_name(),"uvm_config db failure") ;
    
  endfunction
      
      
 task run_phase (uvm_phase phase) ;
   
   forever begin
     seq_item_port.get_next_item(req) ;
    
     `uvm_info(get_type_name() ,$sformatf("[DRIVER] : A = %0d , B = %0d",req.A ,req.B),UVM_LOW);
    
     vif.A      <= req.A ;
     vif.B      <= req.B ;
     vif.opcode <= req.opcode ;
     
     #1step;
     seq_item_port.item_done() ;
     
   end
 endtask
  
endclass 


class coverage extends uvm_subscriber #(sequence_item);
  
  sequence_item cov_item ;
  
  `uvm_component_utils(coverage)
  
  
  
  covergroup cg ;
    option.per_instance = 1 ;
    
    cp_A : coverpoint cov_item.A {
      bins b_zeo = {0} ;
      bins b_low = {[1:63]};
      bins b_mid = {[64 :191]};
      bins b_high = {[192 : 254]};
      bins b_max = {255};
    }
    
    cp_B : coverpoint cov_item.B{
      bins b_zero ={0};
      bins b_low = {[1:63]};
      bins b_mid = {[64 : 191]};
      bins b_high = {[192 : 254]};
      bins b_max = {255};
    }
    
    cp_opcode : coverpoint cov_item.opcode{
      bins add = {3'b000} ;
      bins sub = {3'b001} ;
      bins log_and = {3'b010};
      bins log_or = {3'b011} ;
      bins log_xor = {3'b100};
      bins log_not = {3'b101};
      bins rsh = {3'b110};
      bins lsh = {3'b111};
    }
    
    
    cp_result : coverpoint cov_item.result {
      bins b_zero = {0};
      bins b_low  = {[1:63]} ;
      bins b_mid = {[64:191]};
      bins b_high = {[192:254]};
      bins b_maax = {255};
    }
    
    
    cross_a_opcode : cross cp_A , cp_opcode ;
    cross_opcode_result : cross cp_opcode , cp_result ;
    
    
  endgroup
  
  function new(string name = "coverage" , uvm_component parent = null);
    super.new(name,parent);
    
    cg = new() ;
    
  endfunction
  
  
  function void write(sequence_item t);
    cov_item = t ;
    cg.sample() ;
    
  endfunction
  
  
  
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info(get_type_name(),$sformatf("THE TOTAL COVERAGE IS %0.2f%%",cg.get_coverage()),UVM_NONE);
    
  endfunction
  
  
endclass

    
class monitor extends uvm_monitor ;
  `uvm_component_utils(monitor)
  virtual alu_intf.MONITOR vif ;
  
  uvm_analysis_port #(sequence_item) item_collect_port ;
  sequence_item mon_item ;
  
  function new (string name = "monitor" , uvm_component parent = null) ;
    super.new(name,parent) ;
    item_collect_port = new("item_collect_port" , this);
    
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if(!uvm_config_db #(virtual alu_intf.MONITOR)::get(this,"","vif",vif))
      
      `uvm_fatal(get_type_name() ," monitor doesnot get db");
    
  endfunction
  
  task run_phase(uvm_phase phase ) ;
    
    forever begin

       #1step; 
       mon_item  = sequence_item :: type_id::create("mon_item") ;
      
      mon_item.A = vif.A ;
      mon_item.B = vif.B ;
      mon_item.opcode = vif.opcode ;
      mon_item.result = vif.result ;
      
      `uvm_info(get_type_name() ,$sformatf("[MONITOR] A = %0d | B = %0d | opcode = %0b| result = %0d",mon_item.A ,mon_item.B,mon_item.opcode,mon_item.result),UVM_LOW);
      
      item_collect_port.write(mon_item);
     
      
    end
    
  endtask
  
  
endclass

class agent extends uvm_agent ;
  
  sequencer seqr ;
  driver    drv  ;
  monitor   mon  ;
  
  `uvm_component_utils(agent) 
  
  function new (string name = "agent" , uvm_component parent = null) ;
    
    super.new(name,parent);
    
  endfunction
  
  function void build_phase(uvm_phase phase);
    
    super.build_phase(phase);
    
    if(get_is_active() == UVM_ACTIVE)begin
      seqr = sequencer :: type_id :: create ("seqr", this) ;
      drv  = driver :: type_id :: create("drv",this);
    end
      
    mon  = monitor :: type_id :: create("mon",this);
    
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(get_is_active() == UVM_ACTIVE)begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction
  
endclass


class scoreboard extends uvm_scoreboard ;
  
  sequence_item scb_item[$] ;
  
  uvm_analysis_imp #(sequence_item,scoreboard) item_collect_export ;
  `uvm_component_utils(scoreboard)
  
  function new(string name = "scoreboard" , uvm_component parent = null);
    
    super.new(name,parent) ;
    
    item_collect_export = new("item_collect_export",this) ;
    
  endfunction
  
  function void write(sequence_item req);
    scb_item.push_back(req) ;
    
  endfunction
  
  task run_phase (uvm_phase phase);
    
    sequence_item seq_item ;
    
    forever begin
      
      wait(scb_item.size() > 0);
      
      if(scb_item.size() > 0) 
        seq_item = scb_item.pop_front();
      
      
      if(((seq_item.A + seq_item.B) == seq_item.result ) && seq_item.opcode == 0 ) begin
        
        `uvm_info(get_type_name(),$sformatf("[PASS] : A =  %0d | B = %0d | OPCODE = %0b | result = %0d",seq_item.A,seq_item.B,seq_item.opcode,seq_item.result),UVM_LOW) ;
        $display("-------------------------------------------------");
        
      end
      else if(((seq_item.A - seq_item.B) == seq_item.result ) && seq_item.opcode == 1 ) begin
        
        `uvm_info(get_type_name(),$sformatf("[PASS] : A =  %0d | B = %0d | OPCODE = %0b | result = %0d",seq_item.A,seq_item.B,seq_item.opcode,seq_item.result),UVM_LOW) ;
        $display("-------------------------------------------------");
        
      end
      else if(((seq_item.A & seq_item.B) == seq_item.result ) && seq_item.opcode == 2 ) begin
        
        `uvm_info(get_type_name(),$sformatf("[PASS] : A =  %0d | B = %0d | OPCODE = %0b | result = %0d",seq_item.A,seq_item.B,seq_item.opcode,seq_item.result),UVM_LOW) ;
        $display("-------------------------------------------------");
        
      end
      else if(((seq_item.A | seq_item.B) == seq_item.result ) && seq_item.opcode == 3 ) begin
        
        `uvm_info(get_type_name(),$sformatf("[PASS] : A =  %0d | B = %0d | OPCODE = %0b | result = %0d",seq_item.A,seq_item.B,seq_item.opcode,seq_item.result),UVM_LOW) ;
        $display("-------------------------------------------------");
        
      end
      else if(((seq_item.A ^ seq_item.B) == seq_item.result ) && seq_item.opcode == 4 ) begin
        
        `uvm_info(get_type_name(),$sformatf("[PASS] : A =  %0d | B = %0d | OPCODE = %0b | result = %0d",seq_item.A,seq_item.B,seq_item.opcode,seq_item.result),UVM_LOW) ;
        $display("-------------------------------------------------");
        
      end
      else if(((~seq_item.A)  == seq_item.result ) && seq_item.opcode == 5 ) begin
        
        `uvm_info(get_type_name(),$sformatf("[PASS] : A =  %0d | OPCODE = %0b | result = %0d",seq_item.A,seq_item.opcode,seq_item.result),UVM_LOW) ;
        $display("-------------------------------------------------");
        
      end
      else if(((seq_item.A >>1)  == seq_item.result ) && seq_item.opcode == 6 ) begin
        
        `uvm_info(get_type_name(),$sformatf("[PASS] : A =  %0d | OPCODE = %0b | result = %0d",seq_item.A,seq_item.opcode,seq_item.result),UVM_LOW) ;
        $display("-------------------------------------------------");
        
      end
      else if(((seq_item.A << 1)  == seq_item.result ) && seq_item.opcode == 7 ) begin
        
        `uvm_info(get_type_name(),$sformatf("[PASS] : A =  %0d | OPCODE = %0b | result = %0d",seq_item.A,seq_item.opcode,seq_item.result),UVM_LOW) ;
        $display("-------------------------------------------------");
        
      end
      else begin
        
        `uvm_error(get_type_name(),$sformatf("[ERROR] : A =  %0d | B = %0d OPCODE = %0b | result = %0d",seq_item.A,seq_item.B,seq_item.opcode,seq_item.result)) ;
        $display("-------------------------------------------------");
        
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
    
    super.new(name,parent) ;
    
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    agnt = agent :: type_id :: create("agnt",this);
    scb  = scoreboard :: type_id :: create("scb" ,this);
    cov = coverage :: type_id :: create("cov",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    
    super.connect_phase(phase);
    
    agnt.mon.item_collect_port.connect(scb.item_collect_export);
    agnt.mon.item_collect_port.connect(cov.analysis_export);
  endfunction
  
endclass


class test extends uvm_test ;
  env envh ;
  base_seq bseq ;
  
  `uvm_component_utils(test) 
  
  function new(string name = " test" , uvm_component parent = null  ) ;
    super.new(name,parent);
    
  endfunction
  
  function void build_phase(uvm_phase phase );
    super.build_phase(phase) ;
    
    envh = env :: type_id :: create("envh",this);
    
  endfunction
  
  
  task run_phase(uvm_phase phase ) ;
    
    phase.raise_objection(this);
    
    bseq = base_seq :: type_id :: create("bseq");
    
    bseq.start(envh.agnt.seqr) ;
    
    phase.drop_objection(this);
    
    `uvm_info(get_type_name() ,"End of testcase",UVM_LOW);
  endtask
  
endclass


module top_tb ;
  
  alu_intf intff() ;
  
  alu dut (intff);

  initial begin
    uvm_config_db #(virtual alu_intf.DRIVER)::set(null,"*drv*","vif",intff);
    uvm_config_db #(virtual alu_intf.MONITOR)::set(null,"*mon*","vif",intff);
  end
  
  
  initial begin
    
    run_test("test");
  end
endmodule


