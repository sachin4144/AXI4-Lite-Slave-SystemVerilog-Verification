module tb_axilite_s;

reg         tb_s_axi_aclk;
reg         tb_s_axi_aresetn;

reg         tb_s_axi_awvalid;
wire        tb_s_axi_awready;
reg [31:0]  tb_s_axi_awaddr;

reg         tb_s_axi_wvalid;
wire        tb_s_axi_wready;
reg [31:0]  tb_s_axi_wdata;

wire        tb_s_axi_bvalid;
reg         tb_s_axi_bready;
wire [1:0]  tb_s_axi_bresp;

reg         tb_s_axi_arvalid;
wire        tb_s_axi_arready;
reg [31:0]  tb_s_axi_araddr;

wire        tb_s_axi_rvalid;
reg         tb_s_axi_rready;
wire [31:0] tb_s_axi_rdata;
wire [1:0]  tb_s_axi_rresp;

//////////////////////////////////////////////////////////
// DUT
//////////////////////////////////////////////////////////

axilite_s uut(
.s_axi_aclk(tb_s_axi_aclk),
.s_axi_aresetn(tb_s_axi_aresetn),

.s_axi_awvalid(tb_s_axi_awvalid),
.s_axi_awready(tb_s_axi_awready),
.s_axi_awaddr(tb_s_axi_awaddr),

.s_axi_wvalid(tb_s_axi_wvalid),
.s_axi_wready(tb_s_axi_wready),
.s_axi_wdata(tb_s_axi_wdata),

.s_axi_bvalid(tb_s_axi_bvalid),
.s_axi_bready(tb_s_axi_bready),
.s_axi_bresp(tb_s_axi_bresp),

.s_axi_arvalid(tb_s_axi_arvalid),
.s_axi_arready(tb_s_axi_arready),
.s_axi_araddr(tb_s_axi_araddr),

.s_axi_rvalid(tb_s_axi_rvalid),
.s_axi_rready(tb_s_axi_rready),
.s_axi_rdata(tb_s_axi_rdata),
.s_axi_rresp(tb_s_axi_rresp)
);

//////////////////////////////////////////////////////////
// CLOCK
//////////////////////////////////////////////////////////

initial
begin
    tb_s_axi_aclk = 0;
    forever #5 tb_s_axi_aclk = ~tb_s_axi_aclk;
end

//////////////////////////////////////////////////////////
// WAVES
//////////////////////////////////////////////////////////

initial
begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb_axilite_s);
end

//////////////////////////////////////////////////////////
// MONITOR
//////////////////////////////////////////////////////////

initial
begin
$display("--------------------------------------------");
$display(" AXI LITE TEST STARTED ");
$display("--------------------------------------------");

$monitor("TIME=%0t AWV=%b AWR=%b WV=%b WR=%b BV=%b BR=%b ARV=%b ARR=%b RV=%b RR=%b RDATA=%h",
$time,
tb_s_axi_awvalid,
tb_s_axi_awready,
tb_s_axi_wvalid,
tb_s_axi_wready,
tb_s_axi_bvalid,
tb_s_axi_bready,
tb_s_axi_arvalid,
tb_s_axi_arready,
tb_s_axi_rvalid,
tb_s_axi_rready,
tb_s_axi_rdata);

end

//////////////////////////////////////////////////////////
// TEST
//////////////////////////////////////////////////////////

initial
begin

tb_s_axi_aresetn = 0;

tb_s_axi_awvalid = 0;
tb_s_axi_wvalid  = 0;
tb_s_axi_bready  = 0;
tb_s_axi_arvalid = 0;
tb_s_axi_rready  = 0;

repeat(5) @(posedge tb_s_axi_aclk);

tb_s_axi_aresetn = 1;

$display("Reset Released");

//////////////////////////////////////////////////////
// WRITE
//////////////////////////////////////////////////////

repeat(2) @(posedge tb_s_axi_aclk);

$display("WRITE START");

tb_s_axi_awaddr  = 32'h20;
tb_s_axi_awvalid = 1;

wait(tb_s_axi_awready);

@(posedge tb_s_axi_aclk);

tb_s_axi_awvalid = 0;

tb_s_axi_wdata  = 32'hC0DECAFE;
tb_s_axi_wvalid = 1;

wait(tb_s_axi_wready);

@(posedge tb_s_axi_aclk);

tb_s_axi_wvalid = 0;

tb_s_axi_bready = 1;

wait(tb_s_axi_bvalid);

$display("WRITE RESPONSE = %b",tb_s_axi_bresp);

@(posedge tb_s_axi_aclk);

tb_s_axi_bready = 0;

//////////////////////////////////////////////////////
// READ
//////////////////////////////////////////////////////

repeat(2) @(posedge tb_s_axi_aclk);

$display("READ START");

tb_s_axi_araddr  = 32'h20;
tb_s_axi_arvalid = 1;

wait(tb_s_axi_arready);

@(posedge tb_s_axi_aclk);

tb_s_axi_arvalid = 0;

tb_s_axi_rready = 1;

wait(tb_s_axi_rvalid);

$display("READ DATA = %h",tb_s_axi_rdata);

@(posedge tb_s_axi_aclk);

tb_s_axi_rready = 0;

#50;

$display("--------------------------------------------");
$display("TEST COMPLETED");
$display("--------------------------------------------");

$finish;

end

endmodule
