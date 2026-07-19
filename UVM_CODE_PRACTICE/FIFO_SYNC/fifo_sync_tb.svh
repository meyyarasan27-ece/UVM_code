`include "uvm_macros.svh"
import uvm_pkg::* ;

interface fifo_sync_intf(input clk,input reset) ;

  logic wr_enb ;
  logic rd_enb ;
  logic [7:0]wr_data ;
  logic [7:0]rd_data ;
  logic full ;
  logic empty ;
  
  
  clocking drv_clk @(posedge clk ) ;
    input reset ;
    output wr_enb ;
    output rd_enb ; 
    output wr_data ;
    
    
  endclocking
  
  clocking mon_clk @(posedge clk ) ;
    input reset ;
    input wr_enb ;
    input rd_enb ;
    input wr_data ;
    input rd_data ;
    input full ;
    input empty ;
  
  endclocking
  
  modport DRIVER (clocking drv_clk);
    
  modport MONITOR (clocking mon_clk ); 
    
  
endinterface

class sequence_item extends uvm_sequence_item ;
  
  rand logic wr_enb ;
  rand logic rd_enb ;
  rand logic [7:0]wr_data ;
       logic [7:0]rd_data ;
       logic full ;
       logic empty ;  
  
  
  
  `uvm_object_utils_begin(sequence_item)
  
  `uvm_field_int(wr_enb ,UVM_ALL_ON)
  `uvm_field_int(rd_enb ,UVM_ALL_ON)
  `uvm_field_int(wr_data , UVM_ALL_ON)
  `uvm_field_int(rd_data , UVM_ALL_ON)
  `uvm_field_int(full,UVM_ALL_ON)
  `uvm_field_int(empty,UVM_ALL_ON)
  
  `uvm_object_utils_end
  
  function new(string name = "sequence_item") ;
    
    super.new(name);
    
  endfunction
  
  
  constraint wr_enb_constraint {
    wr_enb dist {1 := 50 ,
                 0 := 50};
  }
  
  
  constraint rd_enb_constraint {
    rd_enb dist {0 := 50 ,
                 1 := 50};
  }
  
  constraint wr_data_constraint{
    wr_data inside {[0:255]};
  }
  
endclass
    

class base_seq extends uvm_sequence #(sequence_item) ;
  sequence_item req ;
  
  `uvm_object_utils(base_seq)
  
  function new(string name = "base_seq");
    
    super.new(name);
    
  endfunction
  
  
  task body();
    `uvm_info(get_type_name(),"BODY TASK sequence",UVM_LOW);
    repeat(50)begin
      
      req = sequence_item :: type_id :: create("req");
      
      start_item(req);
      
      assert(req.randomize())
        else `uvm_fatal(get_type_name(),"RANDOMIZATION FAILED");
      
      finish_item(req);
      
    end
    
  endtask
    
    
  
endclass
    
    
class sequencer extends uvm_sequencer #(sequence_item) ;
  
  `uvm_component_utils(sequencer) 
  
  function new (string name = "sequencer" ,uvm_component parent = null);
    
    super.new(name,parent);
    
  endfunction
  
  
endclass
    

class driver extends uvm_driver #(sequence_item);
  sequence_item req ;
  
  virtual fifo_sync_intf.DRIVER vif ;
  
  `uvm_component_utils(driver)
  
  function new(string name = "driver" , uvm_component parent = null) ;
    
    super.new(name,parent);
    
  endfunction
  
  function void build_phase (uvm_phase phase) ;
    
    super.build_phase(phase);
    
    if(!uvm_config_db #(virtual fifo_sync_intf.DRIVER):: get(this,"","vif",vif))
      `uvm_fatal(get_type_name(),"DRIVER CONFIG DB DOESNOT GET");
    
  endfunction
  
  task run_phase (uvm_phase phase);
    wait(!vif.drv_clk.reset);
    forever begin
     
      
      seq_item_port.get_next_item(req);
      
      `uvm_info(get_type_name(),$sformatf("[DRIVER] : wr_enb = %0b | wr_data = %0d | rd_enb = %0b",req.wr_enb,req.wr_data,req.rd_enb),UVM_LOW);
      
      vif.drv_clk.wr_enb <= req.wr_enb ;
      vif.drv_clk.rd_enb <= req.rd_enb ;
      vif.drv_clk.wr_data <= req.wr_data ;
      
      @( vif.drv_clk ) ;
    //  #1step ;
      
      seq_item_port.item_done() ;
      
    end
    
  endtask
  
endclass
    
class coverage extends uvm_component ;
  uvm_analysis_imp #(sequence_item , coverage) cov_collect_export ;
  sequence_item cov_item ;
  
  `uvm_component_utils(coverage);
  
  covergroup cg ;
    
    option.per_instance = 1;
    
    wr_enb_cp : coverpoint cov_item.wr_enb {
      bins low = {0};
      bins high = {1} ;
    }
    
    
    rd_enb_cp : coverpoint cov_item.rd_enb {
      bins low = {0};
      bins high = {1} ;
    }
    
    wr_data_cp : coverpoint cov_item.wr_data {
      bins low = {[0:63]};
      bins mid = {[64:127]};
      bins high = {[128:255]};
    }
    
    rd_data_cp : coverpoint cov_item.rd_data {
      bins low = {[0:63]};
      bins mid = {[64:127]};
      bins high = {[128:255]};
    }
    
    full_cp : coverpoint cov_item.full {
      bins low = {0};
      bins high = {1} ;
    }
    
    empty_cp : coverpoint cov_item.empty {
      bins low = {0};
      bins high = {1} ;
    }
    
    
    cross_rd_wr_data : cross rd_data_cp ,wr_data_cp ;
    cross_empty_rd_data : cross rd_data_cp , empty_cp ;
    
    
  endgroup
 
  
  
  function new(string name = "coverage",uvm_component parent = null);
    
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
    
    $display("\n---------------------------------------------------------");
    $display(" |                 COVERGAE REPORT                        |");
    $display("\n---------------------------------------------------------");
    
    $display("wr_enb_cp  = %0.2f%%",cg.wr_enb_cp.get_coverage());
    $display("rd_enb_cp  = %0.2f%%",cg.rd_enb_cp.get_coverage());
    $display("wr_data_cp = %0.2f%%",cg.wr_data_cp.get_coverage());
    $display("rd_data_cp = %0.2f%%",cg.rd_data_cp.get_coverage());
    $display("full_cp    = %0.2f%%",cg.full_cp.get_coverage());
    $display("empty_cp   = %0.2f%%",cg.empty_cp.get_coverage());
    $display("cross:rd*wr_data     = %0.2f%%",cg.cross_rd_wr_data.get_coverage());
    $display("cross:empty_rd_data  = %0.2f%%",cg.cross_empty_rd_data.get_coverage());
    
    
    $display("\n---------------------------------------------------------");
    $display(" |         TOTAL COVERAGE = %0.2f%%     |",cg.get_coverage());
    $display("\n---------------------------------------------------------");
    
    
  endfunction
  
endclass    
    
class monitor extends uvm_monitor ;
  
  sequence_item mon_item ;
  virtual fifo_sync_intf.MONITOR vif ;
  uvm_analysis_port #(sequence_item) item_collect_port ;
  
  `uvm_component_utils(monitor)
  
  function new(string name = "monitor" , uvm_component parent = null);
    
    super.new(name,parent);
    item_collect_port = new("item_collect_port",this);
    
  endfunction
  
  
  function void build_phase(uvm_phase phase);
    
    super.build_phase(phase);
    
    if(!uvm_config_db #(virtual fifo_sync_intf.MONITOR)::get(this,"","vif",vif))
      `uvm_fatal(get_type_name(),"CONFIG DB FOR MONITOR FAILED");
    
  endfunction
  
  task run_phase(uvm_phase phase);
    wait(!vif.mon_clk.reset);
    forever begin
      
      mon_item = sequence_item :: type_id :: create("mon_item");
      
      @( vif.mon_clk);
     // #1step ;
      
      mon_item.wr_enb  = vif.mon_clk.wr_enb  ;
      mon_item.rd_enb  = vif.mon_clk.rd_enb  ;
      mon_item.wr_data = vif.mon_clk.wr_data ;
      mon_item.rd_data = vif.mon_clk.rd_data ;
      mon_item.full    = vif.mon_clk.full    ;
      mon_item.empty   = vif.mon_clk.empty   ;
      
      `uvm_info(get_type_name(),$sformatf("[MONITOR] : wr_enb = %0b | wr_data = %0d | full = %0b | rd_enb = %0b | rd_data = %0d | empty = %0b ",mon_item.wr_enb ,mon_item.wr_data,mon_item.full,mon_item.rd_enb  ,mon_item.rd_data,mon_item.empty),UVM_LOW);
      
      item_collect_port.write(mon_item);
      
    end
  endtask
  
endclass
    
class agent extends uvm_agent ;
  
  sequencer seqr ;
  driver drv ;
  monitor mon ;
  
  `uvm_component_utils(agent)
  
  function new(string name = "agent" , uvm_component parent = null);
    
    super.new(name,parent);
    
  endfunction
  
  function void build_phase (uvm_phase phase);
    
    super.build_phase(phase);
    
    if(get_is_active() == UVM_ACTIVE)begin
      seqr = sequencer :: type_id :: create("seqr",this);
      drv = driver :: type_id :: create("drv",this);
    end
    
    mon = monitor :: type_id :: create("mon",this);
    
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    if(get_is_active() == UVM_ACTIVE)begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
    
  endfunction
  
endclass
    
    
class scoreboard extends uvm_scoreboard;

  `uvm_component_utils(scoreboard)

  uvm_analysis_imp #(sequence_item, scoreboard) item_collect_export;

  localparam int FIFO_DEPTH = 8;

  logic [7:0] ref_queue[$];

  // Expected data waiting for comparison
  logic [7:0] expected_data;

  // Indicates that a read was requested in previous cycle
  bit read_pending;

  // Expected FIFO flags
  bit expected_empty;
  bit expected_full;


  function new(string name = "scoreboard",
               uvm_component parent = null);

    super.new(name, parent);

    item_collect_export =
      new("item_collect_export", this);

  endfunction


  function void write(sequence_item item);

    bit write_valid;
    bit read_valid;


    // 1. CHECK READ DATA FROM PREVIOUS READ OPERATION

    if (read_pending) begin

      if (item.rd_data === expected_data) begin

        `uvm_info(get_type_name(),

          $sformatf("[READ PASS] EXPECTED = %0d | ACTUAL = %0d", expected_data,item.rd_data), UVM_LOW);
        $display("-------------------------------------------------------");

      end

      else begin

        `uvm_error(get_type_name(),

          $sformatf("[READ FAIL] EXPECTED = %0d | ACTUAL = %0d",expected_data,item.rd_data));
        $display("-------------------------------------------------------");

      end

      read_pending = 0;

    end


    // 2. CHECK EMPTY FLAG

    expected_empty = (ref_queue.size() == 0);

    if (item.empty !== expected_empty) begin

      `uvm_error(get_type_name(),

        $sformatf("[EMPTY FLAG FAIL] REF_EMPTY = %0b | DUT_EMPTY = %0b | QUEUE_SIZE = %0d",expected_empty,item.empty,ref_queue.size()));
      $display("-------------------------------------------------------");

    end

    else begin

      `uvm_info(get_type_name(),

        $sformatf("[EMPTY FLAG PASS] empty = %0b",item.empty), UVM_LOW);
      $display("-------------------------------------------------------");

    end


    // 3. CHECK FULL FLAG

    expected_full = (ref_queue.size() == FIFO_DEPTH);

    if (item.full !== expected_full) begin

      `uvm_error(get_type_name(),

        $sformatf("[FULL FLAG FAIL] REF_FULL = %0b | DUT_FULL = %0b | QUEUE_SIZE = %0d", expected_full,item.full, ref_queue.size()));
      $display("-------------------------------------------------------");

    end

    else begin

      `uvm_info(get_type_name(),

        $sformatf("[FULL FLAG PASS] full = %0b | QUEUE_SIZE = %0d", item.full,ref_queue.size()), UVM_LOW);
      $display("-------------------------------------------------------");

    end


    // 4. DETERMINE VALID OPERATIONS

    write_valid = item.wr_enb && !item.full;

    read_valid  = item.rd_enb && !item.empty;

    // 5. INVALID WRITE CHECK

    if (item.wr_enb && item.full) begin

      `uvm_warning(get_type_name(),"[INVALID WRITE] WRITE ATTEMPTED WHEN FIFO IS FULL");
      $display("-------------------------------------------------------");

    end

    // 6. INVALID READ CHECK

    if (item.rd_enb && item.empty) begin

      `uvm_warning(get_type_name(),"[INVALID READ] READ ATTEMPTED WHEN FIFO IS EMPTY");
      $display("-------------------------------------------------------");

    end


    // 7. IDLE CHECK

    if (!item.wr_enb && !item.rd_enb) begin

      `uvm_info(get_type_name(), "[IDLE] NO READ OR WRITE OPERATION",UVM_LOW);
      $display("-------------------------------------------------------");

    end


    // 8. WRITE OPERATION

    if (write_valid) begin

      ref_queue.push_back(item.wr_data);

      `uvm_info(get_type_name(),

        $sformatf("[WRITE] DATA = %0d | QUEUE_SIZE = %0d",item.wr_data,ref_queue.size()),UVM_LOW);
      $display("-------------------------------------------------------");

    end


    // 9. READ OPERATION

    if (read_valid) begin

      if (ref_queue.size() == 0) begin

        `uvm_error(get_type_name(),"[READ ERROR] REFERENCE QUEUE EMPTY");
        $display("-------------------------------------------------------");

      end

      else begin

        expected_data = ref_queue.pop_front();
        read_pending = 1;

        `uvm_info(get_type_name(),

          $sformatf("[READ REQUEST] EXPECTED DATA = %0d",expected_data),UVM_LOW);
        $display("-------------------------------------------------------");

      end

    end

    // 10. BOTH READ AND WRITE ENABLED

    if (item.wr_enb && item.rd_enb) begin

      `uvm_warning(get_type_name(),"[READ/WRITE] BOTH READ AND WRITE ENABLED");
      $display("-------------------------------------------------------");

    end


  endfunction


endclass
    
    
class env extends uvm_env ;
  agent agnt ;
  scoreboard scb ;
  coverage cov ;
  
  `uvm_component_utils(env)
  
  function new (string name = "env" , uvm_component parent = null);
    
    super.new(name,parent);
    
  endfunction
  
  function void build_phase(uvm_phase phase );
    
    super.build_phase(phase);
    
    agnt = agent :: type_id :: create("agnt",this);
    scb  = scoreboard :: type_id :: create ("scb",this) ;
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
  
  function new(string name = "test", uvm_component parent = null);
    
    super.new(name,parent);
    
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    envh = env :: type_id :: create("envh",this);
    
  endfunction
  
  
  task run_phase (uvm_phase phase);
    bseq = base_seq :: type_id :: create("bseq");
    phase.raise_objection(this);
      
    bseq.start(envh.agnt.seqr);
      
    phase.drop_objection(this);
      
    `uvm_info(get_type_name(),"END OF TEST ",UVM_LOW);
      
    
  endtask
  
endclass
    
    
    
module top_tb ;
  
  logic clk ,reset ;
  
  
  always #5 clk = ~clk ;
  
  initial begin
    clk = 0 ;
    reset = 1 ;
    
    #5 reset = 0 ;
    
  end
  
  fifo_sync_intf intff(clk,reset);
  
  fifo_sync dut (intff);
  
  initial begin
    
    uvm_config_db #(virtual fifo_sync_intf.DRIVER)::set(null,"*drv*","vif",intff);
    
    uvm_config_db #(virtual fifo_sync_intf.MONITOR)::set(null,"*mon*","vif",intff);
    
  end
  
  
  initial begin
    run_test("test");
  end
  
endmodule
