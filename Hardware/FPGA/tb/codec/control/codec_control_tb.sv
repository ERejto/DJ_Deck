module codec_control_tb;
  localparam   C_CLK_PERIOD_100MHZ = 10;

  logic        clk;
  logic        rst;
  logic        valid;
  logic [15:0] address;
  logic [ 7:0] wdata;
  logic [ 7:0] rdata;
  wire         sda;
  logic        scl;
  logic        rnw;

  initial begin
    clk = 1'b0;
    forever #(C_CLK_PERIOD_100MHZ/2) clk = ~clk;
  end


  initial begin
    rst = 1'b1;
    repeat(10) @(posedge clk);
    rst = 1'b0;
    address = 16'h1234;
    wdata = 8'h12;
    rnw   = 1'b0;
    repeat(1) @(posedge clk);
    valid = 1'b1;
    repeat(1) @(posedge clk);
    valid = 1'b0;
    repeat(36) @(posedge scl);
    $stop;
  end

  i2c_controller i2c_controller_i (
    .clk(clk),
    .rst(rst),
    .rnw(rnw),
    .valid(valid),
    .address(address),
    .wdata(wdata),
    .rdata(rdata),
    .sda(sda),
    .scl(scl)
  );

  codec_bfm codec_bfm_i (
    .scl(scl),
    .sda(sda)
  );

endmodule
