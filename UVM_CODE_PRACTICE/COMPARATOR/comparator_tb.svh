`include "uvm_macros.svh"
import uvm_pkg::* ;


interface comparator_intf ;
  
  logic [7:0]data1 ;
  logic [7:0]data2 ;
  logic greater ;
  logic lesser  ;
  logic equal  ;
  
  
  modport DRIVER (output data1 , output data2);
  
  modport MONITOR (input data1 , input data2 , input greater ,input lesser ,input equal) ;
  
endinterface



class sequence_item extends uvm_sequence_item ;
  
  rand logic [7:0]data1 ;
  rand logic [7:0]data2 ;
  
  logic greater ;
  logic lesser  ;
  logic equal   ;
  
  `uvm_object_utils_begin(sequence_item)
  
  `uvm_field_int(data1,UVM_ALL_ON)
  `uvm_field_int(data2,UVM_ALL_ON)
  `uvm_field_int(greater,UVM_ALL_ON)
  `uvm_field_int(lesser,UVM_ALL_ON)
  `uvm_field_int(equal,UVM_ALL_ON)
  
  `uvm_object_utils_end
  
  function new(string name = "sequence_item") ;
    
    super.new(name);
  endfunction
  
  
  constraint data1_consrtraint {
    data1 inside {[0:255]};
  }
  
  constraint data2_constraint {
    data2 inside {[0:255]};
  }
  
endclass


class base_seq extends uvm_sequence #(sequence_item) ;
  
  sequence_item req ;
  
  `uvm_object_utils(base_seq) 
  
  function new(string name = "base_seq");
    
    super.new(name);
    
  endfunction
  
  task body() ; 
    
    repeat (50) begin
      
      req = sequence_item :: type_id :: create ("req") ;
      
      start_item(req) ;
      
      assert(req.randomize())
        else `uvm_fatal(get_type_name(),"RANDOMIZATION FAILED");
      
      finish_item(req) ;
      
      `uvm_info(get_type_name(),"base sequence task body",UVM_LOW);
      
    end
  endtask
  
endclass


class sequencer extends uvm_sequencer #(sequence_item) ;
  
  `uvm_component_utils(sequencer)
  
  function new(string name = "sequencer", uvm_component parent = null);
    
    super.new(name,parent);
    
  endfunction
  
endclass


class driver extends uvm_driver #(sequence_item);
  virtual comparator_intf.DRIVER vif ;
  
  `uvm_component_utils(driver)
  
  function new(string name = "driver" ,uvm_component parent = null);
    
    super.new(name,parent);
    
  endfunction
  
  function void build_phase (uvm_phase phase);
    
    super.build_phase(phase);
    
    if(!uvm_config_db #(virtual comparator_intf.DRIVER )::get(this,"","vif",vif))
      `uvm_fatal(get_type_name(),"CONFIG DB FAILED IN DRIVER");
    
  endfunction
  
  task run_phase(uvm_phase phase) ;
    
    forever begin
     
      
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(),$sformatf("driver data1 = %0d | data2 = %0d",req.data1,req.data2),UVM_LOW);
      
      vif.data1 <= req.data1 ;
      vif.data2 <= req.data2 ;
      
      #1step ;
      
      seq_item_port.item_done() ;
      
      
      
    end
    
    
  endtask
  
endclass


class coverage extends uvm_component ;
  
  sequence_item cov_item ;
  uvm_analysis_imp #(sequence_item , coverage) cov_collect_export ;
  
  `uvm_component_utils(coverage)
  
  
  
  covergroup cg ;
    
    option.per_instance = 1 ;
    
    cp_data1 : coverpoint cov_item.data1 {
      bins blow = {[0:63]};
      bins b_mid = {[64:127]};
      bins b_high = {[128:255]};
    }
    
    cp_data2 : coverpoint cov_item.data2 {
      bins blow = {[0:63]};
      bins b_mid = {[64:127]};
      bins b_high = {[128:255]};
    }
    
    cp_greater : coverpoint cov_item.greater{
      bins b_low ={0};
      bins b_high = {1};
    }
    
    cp_lesser : coverpoint cov_item.lesser{
      bins b1 ={0};
      bins b_high = {1};
    }
    
    cp_equal : coverpoint cov_item.equal{
      bins b1 ={0};
      bins b_high = {1};
    }
    
    cross_in1_in2 : cross cp_data1,cp_data2 ;
    
  endgroup
  
  function new(string name = "coverage" , uvm_component parent = null );
    
    super.new(name,parent);
    cov_collect_export = new("cov_collect_export",this);
    cg = new() ;
    
  endfunction
  
  
  function void write(sequence_item item);
    
    cov_item = item ;
    cg.sample() ;
    
  endfunction
  
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    $display("\n-------------------------------------------------------");
    
    $display("DATA 1  : %0.2f%%",cg.cp_data1.get_coverage());
    $display("DATA 2  : %0.2f%%",cg.cp_data2.get_coverage());
    $display("GREATER : %0.2f%%",cg.cp_greater.get_coverage());
    $display("LESSER  : %0.2f%%",cg.cp_lesser.get_coverage());
    $display("EQUAL   : %0.2f%%",cg.cp_equal.get_coverage());
    $display("CROSS DATA 1 and 2 : %0.2f%%",cg.cross_in1_in2.get_coverage());
    
    $display("\n-------------------------------------------------------");
    $display("TOTAL COVERAGE   : %0.2f%%",cg.get_coverage());
    $display("\n-------------------------------------------------------");
    
  endfunction
  
  
endclass


class monitor extends uvm_monitor ;
  sequence_item mon_item ;
  
  virtual comparator_intf.MONITOR vif ;
  uvm_analysis_port #(sequence_item) item_collect_port ;
  
  `uvm_component_utils(monitor)
  
  function new(string name = "monitor",uvm_component parent = null);
    
    super.new(name,parent);
    item_collect_port = new("item_collect_port",this);
    
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if(!uvm_config_db #(virtual comparator_intf.MONITOR)::get(this,"","vif",vif))
    `uvm_fatal(get_type_name(),"CONFIG DB FAILED ") ;
    
  endfunction
  
  task run_phase(uvm_phase phase) ;
    forever begin
      
      mon_item = sequence_item :: type_id :: create("mon_item");
      @(vif.data1 or vif.data2);
      #1step ;
      mon_item.data1 = vif.data1 ;
      mon_item.data2 = vif.data2 ;
      mon_item.greater = vif.greater ;
      mon_item.lesser = vif.lesser ;
      mon_item.equal  = vif.equal ;
      
      
      `uvm_info(get_type_name(),$sformatf("monitor data1 = %0d | data2 = %0d greater = %0b | lesser = %0b | equal = %0b ",vif.data1,vif.data2,vif.greater,vif.lesser,vif.equal),UVM_LOW);
      
      item_collect_port.write(mon_item);
      
      

    end
    
  endtask
  
endclass

class agent extends uvm_agent ;
  
  sequencer seqr ;
  driver drv ;
  monitor mon ;
  
  `uvm_component_utils(agent) 
  
  function new (string name = "agent" , uvm_component parent = null);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if(get_is_active() == UVM_ACTIVE)begin
      seqr = sequencer :: type_id :: create("seqr",this);
      drv  = driver :: type_id :: create("drv",this);
    end
    mon  = monitor :: type_id :: create("mon",this) ;
    
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    if(get_is_active() == UVM_ACTIVE)begin
      
      drv.seq_item_port.connect(seqr.seq_item_export);
      
    end
  endfunction
  
endclass


class scoreboard extends uvm_scoreboard ;
  
  
  uvm_analysis_imp #(sequence_item,scoreboard) item_collect_export ;
  
  `uvm_component_utils(scoreboard)
  
  function new(string name = "scoreboard",uvm_component parent = null);
    
    super.new(name,parent);
    item_collect_export = new("item_collect_export",this);
    
  endfunction
  
  function void write(sequence_item scb_item);
    
    if((scb_item.data1 < scb_item.data2) && (!scb_item.greater) && scb_item.lesser && (!scb_item.equal) )begin
      
      `uvm_info(get_type_name(),$sformatf("scb [PASS]: data1 = %0d | data2 = %0d | lesser = %0b | greater = %0b | equal = %0b",scb_item.data1 , scb_item.data2,scb_item.lesser,scb_item.greater,scb_item.equal),UVM_LOW);
      $display("----------------------------------------");
      
    end
    
    else if((scb_item.data1 > scb_item.data2) && scb_item.greater && (!scb_item.lesser) && (!scb_item.equal))begin
      
      `uvm_info(get_type_name(),$sformatf("scb [PASS]: data1 = %0d | data2 = %0d | lesser = %0b | greater = %0b | equal = %0b",scb_item.data1 , scb_item.data2,scb_item.lesser,scb_item.greater,scb_item.equal),UVM_LOW);
      $display("----------------------------------------");
      
    end
    
    else if((scb_item.data1 == scb_item.data2 ) && (!scb_item.greater) && (!scb_item.lesser) && scb_item.equal ) begin
      
      `uvm_info(get_type_name(),$sformatf("scb [PASS]: data1 = %0d | data2 = %0d | lesser = %0b | greater = %0b | equal = %0b",scb_item.data1 , scb_item.data2,scb_item.lesser,scb_item.greater,scb_item.equal),UVM_LOW);
      $display("----------------------------------------");
      
    end
    
    else begin
      
      `uvm_error(get_type_name(),$sformatf("scb [FAIL]: data1 = %0d | data2 = %0d | lesser = %0b | greater = %0b | equal = %0b",scb_item.data1 , scb_item.data2,scb_item.lesser,scb_item.greater,scb_item.equal));
      $display("----------------------------------------");
      
    end
    
  endfunction
  
  
endclass


class env extends uvm_env ;
  
  agent agnt ;
  scoreboard scb ;
  coverage cov ;
  
  `uvm_component_utils(env)
  
  function new (string name = "env",uvm_component parent = null);
    
    super.new(name,parent);
    
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    agnt = agent :: type_id :: create("agnt",this);
    scb  = scoreboard :: type_id :: create("scb",this);
    cov  = coverage :: type_id :: create("cov",this);
    
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    agnt.mon.item_collect_port.connect(scb.item_collect_export);
    agnt.mon.item_collect_port.connect(cov.cov_collect_export);
    
  endfunction
  
endclass

class test extends uvm_test ;
  env envh ;
  base_seq bseq ;
  `uvm_component_utils(test)
  
  function new(string name = "test" ,uvm_component parent = null);
    super.new(name,parent);
  endfunction
  
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    
    envh = env :: type_id :: create("envh",this);
    bseq = base_seq :: type_id :: create("bseq");
    
  endfunction
  
  task run_phase(uvm_phase phase);
    
    phase.raise_objection(this);
    
    bseq.start(envh.agnt.seqr);
    
    phase.drop_objection(this);
    `uvm_info(get_type_name(), "End of testcase", UVM_LOW);
  endtask
  
  
endclass


module top_tb ;
  
  comparator_intf intff() ;
  
  comparator dut (intff);
  
  initial begin
    
    uvm_config_db #(virtual comparator_intf.DRIVER) :: set(null,"*drv*","vif",intff);
    uvm_config_db #(virtual comparator_intf.MONITOR) :: set(null,"*mon*","vif",intff);
  end
  
  
  initial begin
    
    run_test("test");
  end
  
endmodule
