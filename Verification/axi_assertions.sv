module axi_assertions(axi_if vif);

default clocking cb @(posedge vif.clk);
endclocking
  
localparam int TOTAL_ASSERTIONS = 7;

int assertion_fail_count = 0;
  
int awready_fail = 0;
int wready_fail  = 0;
int arready_fail = 0;

int bresp_fail   = 0;
int rresp_fail   = 0;

int bstable_fail = 0;
int rstable_fail = 0;

/////////////////////////////////////////////////////////////
// 1. AWREADY should only occur after AWVALID
/////////////////////////////////////////////////////////////

property p_awready;
    disable iff(!vif.resetn)
    vif.awready |-> $past(vif.awvalid);
endproperty

a_awready : assert property(p_awready)
else begin
    assertion_fail_count++;
    awready_fail++;
    $error("[SVA] AWREADY asserted without previous AWVALID");
end

c_awready : cover property(p_awready);

/////////////////////////////////////////////////////////////
// 2. WREADY should only occur after WVALID
/////////////////////////////////////////////////////////////

property p_wready;
    disable iff(!vif.resetn)
    vif.wready |-> $past(vif.wvalid);
endproperty

a_wready : assert property(p_wready)
else begin
    assertion_fail_count++;
    wready_fail++;
    $error("[SVA] WREADY asserted without previous WVALID");
end

c_wready : cover property(p_wready);

/////////////////////////////////////////////////////////////
// 3. ARREADY should only occur after ARVALID
/////////////////////////////////////////////////////////////

property p_arready;
    disable iff(!vif.resetn)
    vif.arready |-> $past(vif.arvalid);
endproperty

a_arready : assert property(p_arready)
else begin
    assertion_fail_count++;
    arready_fail++;
    $error("[SVA] ARREADY asserted without previous ARVALID");
end

c_arready : cover property(p_arready);

/////////////////////////////////////////////////////////////
// 4. BRESP must be legal
/////////////////////////////////////////////////////////////

property p_bresp_valid;

    disable iff(!vif.resetn)

    vif.bvalid |->

    (vif.bresp inside {2'b00,2'b10});

endproperty

a_bresp_valid : assert property(p_bresp_valid)
else begin
    assertion_fail_count++;
    bresp_fail++;
    $error("[SVA] Invalid BRESP");
end

c_bresp_valid : cover property(p_bresp_valid);

/////////////////////////////////////////////////////////////
// 5. RRESP must be legal
/////////////////////////////////////////////////////////////

property p_rresp_valid;

    disable iff(!vif.resetn)

    vif.rvalid |->

    (vif.rresp inside {2'b00,2'b10});

endproperty

a_rresp_valid : assert property(p_rresp_valid)
else begin
    assertion_fail_count++;
    rresp_fail++;
    $error("[SVA] Invalid RRESP");
end

c_rresp_valid : cover property(p_rresp_valid);

/////////////////////////////////////////////////////////////
// 6. BRESP must remain stable until accepted
/////////////////////////////////////////////////////////////

property p_bresp_stable;

    disable iff(!vif.resetn)

    (vif.bvalid && !vif.bready)

    |=>

    $stable(vif.bresp);

endproperty

a_bresp_stable : assert property(p_bresp_stable)
else begin
    assertion_fail_count++;
    bstable_fail++;
    $error("[SVA] BRESP changed before BREADY");
end

c_bresp_stable : cover property(p_bresp_stable);

/////////////////////////////////////////////////////////////
// 7. RDATA/RRESP must remain stable until accepted
/////////////////////////////////////////////////////////////

property p_rdata_stable;

    disable iff(!vif.resetn)

    (vif.rvalid && !vif.rready)

    |=>

    ($stable(vif.rdata) && $stable(vif.rresp));

endproperty

a_rdata_stable : assert property(p_rdata_stable)
else begin
    assertion_fail_count++;
    rstable_fail++;
    $error("[SVA] Read response changed before RREADY");
end

c_rdata_stable : cover property(p_rdata_stable);

/////////////////////////////////////////////////////////////
// Report
/////////////////////////////////////////////////////////////

task report();
    int assertion_pass_count;

    assertion_pass_count = TOTAL_ASSERTIONS - assertion_fail_count;

$display("");
$display("======================================================");
  $display("                ASSERTION SUMMARY           ");
$display("======================================================");

$display("%-30s %s","AWREADY Sequencing",
         (awready_fail==0) ? "PASS" : "FAIL");

$display("%-30s %s","WREADY Sequencing",
         (wready_fail==0) ? "PASS" : "FAIL");

$display("%-30s %s","ARREADY Sequencing",
         (arready_fail==0) ? "PASS" : "FAIL");

$display("%-30s %s","BRESP Validity",
         (bresp_fail==0) ? "PASS" : "FAIL");

$display("%-30s %s","RRESP Validity",
         (rresp_fail==0) ? "PASS" : "FAIL");

$display("%-30s %s","BRESP Stability",
         (bstable_fail==0) ? "PASS" : "FAIL");

$display("%-30s %s","RDATA Stability",
         (rstable_fail==0) ? "PASS" : "FAIL");

$display("------------------------------------------------------");
// $display("Total Assertion Failures : %0d",
//           assertion_fail_count);
    $display("Total Assertions   : %0d", TOTAL_ASSERTIONS);
    $display("Passed             : %0d", assertion_pass_count);
    $display("Failed             : %0d", assertion_fail_count);

if(assertion_fail_count==0)
    $display("RESULT : ALL ASSERTIONS PASSED");
else
    $display("RESULT : ASSERTIONS FAILED");

$display("======================================================");

endtask

endmodule
