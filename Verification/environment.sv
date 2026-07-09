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
      gen.count = 100;

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

  endtask

endclass
