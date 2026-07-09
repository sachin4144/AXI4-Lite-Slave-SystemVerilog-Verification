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
