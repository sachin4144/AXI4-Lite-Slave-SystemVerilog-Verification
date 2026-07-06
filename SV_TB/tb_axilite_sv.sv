class transaction;

  rand bit        op;
  rand bit [31:0] awaddr;
  rand bit [31:0] araddr;
  rand bit [31:0] wdata;

       bit [31:0] rdata;
       bit [1:0] bresp;
       bit [1:0] rresp;

  int txn_id;

  constraint addr_c {
      awaddr dist {
          [0:127]   := 90,
          [128:150] := 10
      };

      araddr dist {
        [0:127]   := 90,
        [128:150] := 10
      };
  }

  constraint data_c
{
    wdata dist
    {
        0   := 5,
        1   := 5,
        255 := 5,
        [2:254] := 85
    };
}

  constraint op_c {
    op dist {1 := 50, 0 := 50};  //1-write, 0-read
  }

  function void display(string tag);

    $display("[%s] ID=%0d OP=%0b AW=%0d AR=%0d WDATA=%0d RDATA=%0d BRESP=%0b RRESP=%0b",
          tag,
          txn_id,
          op,
          awaddr,
          araddr,
          wdata,
          rdata,
          bresp,
          rresp);

endfunction

endclass
 
 
 
//////////////////////////////////
class generator;

  transaction tr;

  mailbox #(transaction) mbxgd;

  event done;
  event sconext;

  int count = 0;

  // Store last successful write
  bit [31:0] last_addr;
  bit [31:0] last_data;
  bit        have_valid_write = 0;

  function new(mailbox #(transaction) mbxgd);
    this.mbxgd = mbxgd;
  endfunction


  task run();

    int sel;

    $display("---------------------------------------");
    $display("[GEN] Starting Transaction Generation");
    $display("---------------------------------------");

    for(int i=0;i<count;i++)
    begin

      tr = new();
      tr.txn_id = i+1;

      // Select transaction type
      // 0-5 : Valid Write (60%)
      // 6-7 : Read Last Written Address (20%)
      // 8   : Invalid Write (10%)
      // 9   : Invalid Read (10%)

      sel = $urandom_range(0,9);

      //////////////////////////////////////////////////////
      // VALID WRITE
      //////////////////////////////////////////////////////

      if(sel <= 5)
      begin

        assert(tr.randomize() with {
            op     == 1;
            awaddr inside {[0:127]};
        })
        else
          $fatal("[GEN] Randomization Failed");

        last_addr = tr.awaddr;
        last_data = tr.wdata;

        have_valid_write = 1;

      end

      //////////////////////////////////////////////////////
      // READ LAST WRITTEN ADDRESS
      //////////////////////////////////////////////////////

      else if(sel <= 7)
      begin

        if(have_valid_write)
        begin

          tr.op     = 0;
          tr.araddr = last_addr;

        end
        else
        begin

          // No valid write yet
          assert(tr.randomize() with {
              op == 1;
              awaddr inside {[0:127]};
          })
          else
            $fatal("[GEN] Randomization Failed");

          last_addr = tr.awaddr;
          last_data = tr.wdata;
          have_valid_write = 1;

        end

      end

      //////////////////////////////////////////////////////
      // INVALID WRITE
      //////////////////////////////////////////////////////

      else if(sel == 8)
      begin

        assert(tr.randomize() with {
            op     == 1;
            awaddr inside {[128:150]};
        })
        else
          $fatal("[GEN] Randomization Failed");

      end

      //////////////////////////////////////////////////////
      // INVALID READ
      //////////////////////////////////////////////////////

      else
      begin

        assert(tr.randomize() with {
            op     == 0;
            araddr inside {[128:150]};
        })
        else
          $fatal("[GEN] Randomization Failed");

      end

      tr.display("GEN");

      mbxgd.put(tr);

      @(sconext);

    end

    $display("---------------------------------------");
    $display("[GEN] Generated %0d Transactions", count);
    $display("---------------------------------------");

    ->done;

  endtask

endclass
 
 
/////////////////////////////////////
 
 
class driver;

  virtual axi_if vif;

  transaction tr;

  mailbox #(transaction) mbxgd;
  mailbox #(transaction) mbxdm;

  function new(mailbox #(transaction) mbxgd,
               mailbox #(transaction) mbxdm);
    this.mbxgd = mbxgd;
    this.mbxdm = mbxdm;
  endfunction

  //////////////////////////////////////////////////////
  // Reset
  //////////////////////////////////////////////////////

  task reset();

    vif.resetn  <= 0;

    vif.awvalid <= 0;
    vif.awaddr  <= 0;

    vif.wvalid  <= 0;
    vif.wdata   <= 0;

    vif.bready  <= 0;

    vif.arvalid <= 0;
    vif.araddr  <= 0;

    vif.rready  <= 0;

    repeat(5) @(posedge vif.clk);

    vif.resetn <= 1;

    $display("--------------------------------------------");
    $display("[DRV] RESET COMPLETED");
    $display("--------------------------------------------");

  endtask


  //////////////////////////////////////////////////////
  // Write Transaction
  //////////////////////////////////////////////////////

  task write_data(input transaction tr);

    int timeout;

    tr.display("DRV");

    mbxdm.put(tr);

    @(posedge vif.clk);

    //-------------------------------
    // Write Address Channel
    //-------------------------------

    vif.awaddr  <= tr.awaddr;
    vif.awvalid <= 1'b1;

    timeout = 20;

    while(!vif.awready && timeout > 0)
    begin
      timeout--;
      @(posedge vif.clk);
    end

    if(timeout == 0)
      $fatal("[DRV] Timeout waiting for AWREADY");

    vif.awvalid <= 0;
    vif.awaddr  <= 0;


    //-------------------------------
    // Write Data Channel
    //-------------------------------

    vif.wdata  <= tr.wdata;
    vif.wvalid <= 1'b1;

    timeout = 20;

    while(!vif.wready && timeout > 0)
    begin
      timeout--;
      @(posedge vif.clk);
    end

    if(timeout == 0)
      $fatal("[DRV] Timeout waiting for WREADY");

    vif.wvalid <= 0;
    vif.wdata  <= 0;


    //-------------------------------
    // Write Response Channel
    //-------------------------------

    vif.bready <= 1'b1;

    timeout = 20;

    while(!vif.bvalid && timeout > 0)
    begin
      timeout--;
      @(posedge vif.clk);
    end

    if(timeout == 0)
      $fatal("[DRV] Timeout waiting for BVALID");

    case(vif.bresp)

    2'b00:
        $display("[DRV] BRESP = OKAY (00)");

    2'b10:
        $display("[DRV] BRESP = SLVERR (10)");

    default:
        $display("[DRV] BRESP = UNKNOWN (%02b)", vif.bresp);

endcase

    @(posedge vif.clk);

    vif.bready <= 0;

  endtask


  //////////////////////////////////////////////////////
  // Read Transaction
  //////////////////////////////////////////////////////

  task read_data(input transaction tr);

    int timeout;

    tr.display("DRV");

    mbxdm.put(tr);

    @(posedge vif.clk);

    //-------------------------------
    // Read Address Channel
    //-------------------------------

    vif.araddr  <= tr.araddr;
    vif.arvalid <= 1'b1;

    timeout = 20;

    while(!vif.arready && timeout > 0)
    begin
      timeout--;
      @(posedge vif.clk);
    end

    if(timeout == 0)
      $fatal("[DRV] Timeout waiting for ARREADY");

    vif.arvalid <= 0;
    vif.araddr  <= 0;


    //-------------------------------
    // Read Data Channel
    //-------------------------------

    vif.rready <= 1'b1;

    timeout = 20;

    while(!vif.rvalid && timeout > 0)
    begin
      timeout--;
      @(posedge vif.clk);
    end

    if(timeout == 0)
      $fatal("[DRV] Timeout waiting for RVALID");

    case(vif.rresp)

    2'b00:
        $display("[DRV] RRESP = OKAY (00), RDATA = %0d", vif.rdata);

    2'b10:
        $display("[DRV] RRESP = SLVERR (10)");

    default:
        $display("[DRV] RRESP = UNKNOWN (%02b)", vif.rresp);

endcase
    @(posedge vif.clk);

    vif.rready <= 0;

  endtask


  //////////////////////////////////////////////////////
  // Run
  //////////////////////////////////////////////////////

  task run();

    forever
    begin

      mbxgd.get(tr);

      @(posedge vif.clk);

      if(tr.op)
        write_data(tr);
      else
        read_data(tr);

    end

  endtask

endclass
///////////////////////////////////////////////////////
 
 
/////////////////////////////////////////////////////////////
// Monitor
/////////////////////////////////////////////////////////////

class monitor;

  virtual axi_if vif;

  transaction tr;
  transaction trd;

  mailbox #(transaction) mbxms;
  mailbox #(transaction) mbxdm;

  /////////////////////////////////////////////////////////////
  // Functional Coverage
  /////////////////////////////////////////////////////////////

  covergroup cg_operation with function sample(transaction tr);

    option.per_instance = 1;

    cp_op : coverpoint tr.op
    {
        bins READ  = {0};
        bins WRITE = {1};

        bins RD_TO_WR = (0 => 1);
        bins WR_TO_RD = (1 => 0);
        bins RD_TO_RD = (0 => 0);
        bins WR_TO_WR = (1 => 1);
    }

endgroup
  
  covergroup cg_address with function sample(transaction tr);

    option.per_instance = 1;

    cp_addr : coverpoint (tr.op ? tr.awaddr : tr.araddr)
    {
        bins LOW     = {[0:31]};
        bins MID     = {[32:63]};
        bins HIGH    = {[64:127]};
        bins INVALID = {[128:255]};
    }

endgroup
  
  covergroup cg_data with function sample(transaction tr);

    option.per_instance = 1;

    cp_wdata : coverpoint tr.wdata
    {
        bins ZERO = {0};
        bins ONE  = {1};
        bins MAX  = {255};

        bins LOW  = {[2:63]};
        bins MID  = {[64:127]};
        bins HIGH = {[128:254]};
    }

    cp_rdata : coverpoint tr.rdata
    {
        bins ZERO    = {0};
        bins NONZERO = {[1:255]};
    }

endgroup
  
  covergroup cg_response with function sample(transaction tr);

    option.per_instance = 1;

    cp_bresp : coverpoint tr.bresp
    {
        bins OKAY   = {2'b00};
        bins SLVERR = {2'b10};

        illegal_bins RESERVED = {2'b01,2'b11};
    }

    cp_rresp : coverpoint tr.rresp
    {
        bins OKAY   = {2'b00};
        bins SLVERR = {2'b10};

        illegal_bins RESERVED = {2'b01,2'b11};
    }

endgroup
  
  covergroup cg_cross with function sample(transaction tr);

    option.per_instance = 1;

    //-----------------------------------------------------
    // Operation
    //-----------------------------------------------------

    cp_op : coverpoint tr.op;

    //-----------------------------------------------------
    // Address
    //-----------------------------------------------------

    cp_addr : coverpoint (tr.op ? tr.awaddr : tr.araddr)
    {
        bins LOW     = {[0:31]};
        bins MID     = {[32:63]};
        bins HIGH    = {[64:127]};
        bins INVALID = {[128:255]};
    }

    //-----------------------------------------------------
    // BRESP (Only for WRITE)
    //-----------------------------------------------------

    cp_bresp : coverpoint tr.bresp iff(tr.op)
    {
        bins OKAY   = {2'b00};
        bins SLVERR = {2'b10};
    }

    //-----------------------------------------------------
    // RRESP (Only for READ)
    //-----------------------------------------------------

    cp_rresp : coverpoint tr.rresp iff(!tr.op)
    {
        bins OKAY   = {2'b00};
        bins SLVERR = {2'b10};
    }

    //-----------------------------------------------------
    // Cross Coverage
    //-----------------------------------------------------

    // Read/Write vs Address
    cross cp_op, cp_addr;

    // Write Response Cross
    cross cp_addr, cp_bresp iff(tr.op);

    // Read Response Cross
    cross cp_addr, cp_rresp iff(!tr.op);

endgroup

  /////////////////////////////////////////////////////////////
  // Constructor
  /////////////////////////////////////////////////////////////

  function new(mailbox #(transaction) mbxms,
               mailbox #(transaction) mbxdm);

    this.mbxms = mbxms;
    this.mbxdm = mbxdm;

    cg_operation = new();

    cg_address = new();

    cg_data = new();

    cg_response = new();

    cg_cross = new();
  endfunction


  /////////////////////////////////////////////////////////////
  // Run
  /////////////////////////////////////////////////////////////

  task run();

    int timeout;

    forever
    begin

      tr = new();

      @(posedge vif.clk);

      mbxdm.get(trd);

      /////////////////////////////////////////////////////////
      // WRITE
      /////////////////////////////////////////////////////////

      if(trd.op)
      begin

        tr.txn_id = trd.txn_id;
        tr.op     = trd.op;
        tr.awaddr = trd.awaddr;
        tr.wdata  = trd.wdata;

        timeout = 20;

        while(!vif.bvalid && timeout > 0)
        begin
          timeout--;
          @(posedge vif.clk);
        end

        if(timeout == 0)
          $fatal("[MON] Timeout waiting for BVALID");

        tr.bresp = vif.bresp;

      end

      /////////////////////////////////////////////////////////
      // READ
      /////////////////////////////////////////////////////////

      else
      begin

        tr.txn_id = trd.txn_id;
        tr.op     = trd.op;
        tr.araddr = trd.araddr;

        timeout = 20;

        while(!vif.rvalid && timeout > 0)
        begin
          timeout--;
          @(posedge vif.clk);
        end

        if(timeout == 0)
          $fatal("[MON] Timeout waiting for RVALID");

        tr.rdata = vif.rdata;
        tr.rresp = vif.rresp;

      end

      /////////////////////////////////////////////////////////
      // Coverage
      /////////////////////////////////////////////////////////

      cg_operation.sample(tr);

      cg_address.sample(tr);

      cg_data.sample(tr);

      cg_response.sample(tr);

      cg_cross.sample(tr);

      /////////////////////////////////////////////////////////
      // Display
      /////////////////////////////////////////////////////////

      tr.display("MON");

      
      
      /////////////////////////////////////////////////////////
      // Send to Scoreboard
      /////////////////////////////////////////////////////////

      mbxms.put(tr);

    end

  endtask



  /////////////////////////////////////////////////////////////
// Overall Coverage
/////////////////////////////////////////////////////////////

function real get_total_coverage();

    return
    (
        cg_operation.get_inst_coverage() +
        cg_address.get_inst_coverage() +
        cg_data.get_inst_coverage() +
        cg_response.get_inst_coverage() +
        cg_cross.get_inst_coverage()
    ) / 5.0;

endfunction


/////////////////////////////////////////////////////////////
// Print Coverage Report
/////////////////////////////////////////////////////////////

function void print_coverage();

    $display("");
    $display("======================================================");
    $display("               COVERAGE SUMMARY");
    $display("======================================================");

    $display("Operation Coverage : %0.2f%%",
             cg_operation.get_inst_coverage());

    $display("Address Coverage   : %0.2f%%",
             cg_address.get_inst_coverage());

    $display("Data Coverage      : %0.2f%%",
             cg_data.get_inst_coverage());

    $display("Response Coverage  : %0.2f%%",
             cg_response.get_inst_coverage());

    $display("Cross Coverage     : %0.2f%%",
             cg_cross.get_inst_coverage());

    $display("------------------------------------------------------");

    $display("Overall Coverage   : %0.2f%%",
             get_total_coverage());

    $display("======================================================");

endfunction

endclass
 
///////////////////////////////////////
 
 
class scoreboard;

  transaction tr;

  mailbox #(transaction) mbxms;

  event sconext;

  //--------------------------------------------------
  // AXI Response Codes
  //--------------------------------------------------

  localparam OKAY   = 2'b00;
  localparam SLVERR = 2'b10;

  //--------------------------------------------------
  // Golden Reference Memory
  //--------------------------------------------------

  bit [31:0] data [0:127];
  bit [31:0] exp_data;

  //--------------------------------------------------
  // Statistics
  //--------------------------------------------------

  int total_txns = 0;
  int pass_count = 0;
  int fail_count = 0;

  //--------------------------------------------------
  // Constructor
  //--------------------------------------------------

  function new(mailbox #(transaction) mbxms);
      this.mbxms = mbxms;

      foreach(data[i])
          data[i] = 0;
  endfunction

  //--------------------------------------------------
  // Main Scoreboard
  //--------------------------------------------------

  task run();

      forever
      begin

          mbxms.get(tr);

          total_txns++;

          tr.display("SCO");

          /////////////////////////////////////////////
          // WRITE TRANSACTION
          /////////////////////////////////////////////

          if(tr.op)
          begin

            if(tr.bresp == OKAY)
              begin

                  if(tr.awaddr < 128)
                  begin
                      data[tr.awaddr] = tr.wdata;

                      pass_count++;

                      $display("[SCO][PASS] WRITE SUCCESS");
                      $display("[SCO] Memory[%0d] = %0d",
                               tr.awaddr,
                               tr.wdata);
                  end
                  else
                  begin
                      fail_count++;

                      $display("[SCO][FAIL] Invalid Address %0d",
                               tr.awaddr);
                  end

              end

            else if(tr.bresp == SLVERR)
              begin

                  $display("[SCO] WRITE SLAVE ERROR RECEIVED");

                  pass_count++;

              end

              else
              begin

                  fail_count++;

                  $display("[SCO][FAIL] Unknown BRESP = %0b",
                           tr.bresp);

              end

          end

          /////////////////////////////////////////////
          // READ TRANSACTION
          /////////////////////////////////////////////

          else
          begin

              if(tr.rresp == OKAY)
              begin

                  if(tr.araddr < 128)
                  begin

                      exp_data = data[tr.araddr];

                      if(exp_data == tr.rdata)
                      begin

                          pass_count++;

                          $display("[SCO][PASS] READ DATA MATCHED");

                      end
                      else
                      begin

                          fail_count++;

                          $display("[SCO][FAIL] DATA MISMATCH");
                          $display("[SCO] Address  : %0d",
                                    tr.araddr);
                          $display("[SCO] Expected : %0d",
                                    exp_data);
                          $display("[SCO] Actual   : %0d",
                                    tr.rdata);

                      end

                  end

                  else
                  begin

                      fail_count++;

                      $display("[SCO][FAIL] Invalid Address %0d",
                               tr.araddr);

                  end

              end

              else if(tr.rresp == SLVERR)
              begin

                  $display("[SCO] READ SLAVE ERROR RECEIVED");

                  pass_count++;

              end

              else
              begin

                  fail_count++;

                  $display("[SCO][FAIL] Unknown RRESP = %0b",
                           tr.rresp);

              end

          end

          $display("------------------------------------------------");

          ->sconext;

      end

  endtask


  //--------------------------------------------------
  // Final Report
  //--------------------------------------------------

  task report();

      $display("\n");
      $display("======================================================");
      $display("              SCOREBOARD SUMMARY");
      $display("======================================================");
      $display("Total Transactions : %0d", total_txns);
      $display("PASS               : %0d", pass_count);
      $display("FAIL               : %0d", fail_count);

      if(fail_count == 0)
          $display("RESULT             : TEST PASSED");
      else
          $display("RESULT             : TEST FAILED");

      $display("======================================================");

  endtask

endclass

/////////////////////////////////////////////////////////////
// Environment
/////////////////////////////////////////////////////////////

class environment;

  //----------------------------------------------------------
  // Component Handles
  //----------------------------------------------------------

  generator  gen;
  driver     drv;
  monitor    mon;
  scoreboard sco;

  //----------------------------------------------------------
  // Mailboxes
  //----------------------------------------------------------

  mailbox #(transaction) mbxgd;
  mailbox #(transaction) mbxms;
  mailbox #(transaction) mbxdm;

  //----------------------------------------------------------
  // Event
  //----------------------------------------------------------

  event nextgm;

  //----------------------------------------------------------
  // Virtual Interface
  //----------------------------------------------------------

  virtual axi_if vif;

  //----------------------------------------------------------
  // Constructor
  //----------------------------------------------------------

  function new();

      mbxgd = new();
      mbxms = new();
      mbxdm = new();

      gen = new(mbxgd);
      drv = new(mbxgd, mbxdm);
      mon = new(mbxms, mbxdm);
      sco = new(mbxms);

  endfunction

  //----------------------------------------------------------
  // Build Phase
  //----------------------------------------------------------

  task build();

      drv.vif = vif;
      mon.vif = vif;

      gen.sconext = nextgm;
      sco.sconext = nextgm;

      // Number of Transactions
      gen.count = 500;

  endtask

  //----------------------------------------------------------
  // Run Phase
  //----------------------------------------------------------

  task run();

      $display("==============================================");
      $display("      AXI4-Lite Verification Started");
      $display("==============================================");

      drv.reset();

      fork

          gen.run();

          drv.run();

          mon.run();

          sco.run();

      join_any

      wait(gen.done.triggered);

#20;

sco.report();

mon.print_coverage();

$display("==============================================");
$display("        SIMULATION COMPLETED");
$display("==============================================");

$finish;

  endtask

endclass
 

/////////////////////////////////////////////////////////////
// Top Testbench
/////////////////////////////////////////////////////////////

module tb;

  //----------------------------------------------------------
  // Environment
  //----------------------------------------------------------

  environment env;

  //----------------------------------------------------------
  // Interface
  //----------------------------------------------------------

  axi_if vif();

  //----------------------------------------------------------
  // DUT
  //----------------------------------------------------------

  axilite_s dut (

      .s_axi_aclk    (vif.clk),
      .s_axi_aresetn (vif.resetn),

      .s_axi_awvalid (vif.awvalid),
      .s_axi_awready (vif.awready),
      .s_axi_awaddr  (vif.awaddr),

      .s_axi_wvalid  (vif.wvalid),
      .s_axi_wready  (vif.wready),
      .s_axi_wdata   (vif.wdata),

      .s_axi_bvalid  (vif.bvalid),
      .s_axi_bready  (vif.bready),
      .s_axi_bresp   (vif.bresp),

      .s_axi_arvalid (vif.arvalid),
      .s_axi_arready (vif.arready),
      .s_axi_araddr  (vif.araddr),

      .s_axi_rvalid  (vif.rvalid),
      .s_axi_rready  (vif.rready),
      .s_axi_rdata   (vif.rdata),
      .s_axi_rresp   (vif.rresp)

  );

  //----------------------------------------------------------
  // Clock Generation
  //----------------------------------------------------------

  initial
      vif.clk = 0;

  always #5
      vif.clk = ~vif.clk;

  //----------------------------------------------------------
  // Test
  //----------------------------------------------------------

  initial
  begin

      env = new();

      env.vif = vif;

      env.build();

      env.run();

      $finish;

  end

  //----------------------------------------------------------
  // Waveform
  //----------------------------------------------------------

  initial
  begin
      $dumpfile("dump.vcd");
      $dumpvars(0, tb);
  end

endmodule
