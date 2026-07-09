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
