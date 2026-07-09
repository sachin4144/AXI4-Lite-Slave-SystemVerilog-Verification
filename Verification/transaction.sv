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
