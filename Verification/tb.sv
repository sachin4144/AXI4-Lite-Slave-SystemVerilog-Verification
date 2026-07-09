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
  
  // Assertions
  axi_assertions sva(vif);

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
      
      sva.report();
    
    
    $display("");
$display("======================================================");
$display("           FINAL VERIFICATION SUMMARY");
$display("======================================================");

$display("Transactions        : %0d", env.gen.count);

if(env.sco.fail_count == 0)
    $display("Scoreboard Status   : PASS");
else
    $display("Scoreboard Status   : FAIL");

$display("Functional Coverage : %0.2f%%",
          env.mon.get_total_coverage());

if(sva.assertion_fail_count == 0)
    $display("Assertions          : PASS");
else
    $display("Assertions          : FAIL");

if(env.sco.fail_count == 0 &&
   sva.assertion_fail_count == 0)
    $display("Overall Result      : VERIFICATION PASSED");
else
    $display("Overall Result      : VERIFICATION FAILED");

$display("======================================================");

    //--------------------------------------------------

    $display("==============================================");
    $display("        SIMULATION COMPLETED");
    $display("==============================================");

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
