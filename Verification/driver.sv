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
