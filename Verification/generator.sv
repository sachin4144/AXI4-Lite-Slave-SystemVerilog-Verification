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
