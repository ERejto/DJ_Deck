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
  logic        ready;

  initial begin
    clk = 1'b0;
    forever #(C_CLK_PERIOD_100MHZ/2) clk = ~clk;
  end

  task automatic i2c_write (input [15:0] addr, input [7:0] data); 
      wait(ready);
      valid = 1'b1;
      wdata = data;
      address = addr;
      rnw = 1'b0;
      @(posedge clk);
      valid = 1'b0;
      @(posedge ready);
  endtask

  task automatic i2c_read (input [15:0] addr);
      wait(ready);
      valid = 1'b1;
      address = addr;
      rnw = 1'b1;
      @(posedge clk);
      valid = 1'b1;
      @(posedge ready);
  endtask


  initial begin
    rst = 1'b1;
    repeat(10) @(posedge clk);
    rst = 1'b0;
    
    codec_bfm_i.wdata = 8'h12;
    i2c_read(16'h1212);

    //for (int i = 0; i < 16'hFFFF; i+=16'h10) begin
    //    i2c_write(i,i[7:0]);
    //    assert(codec_bfm_i.rdata == i);
    //end
    //for (int i = 0; i < 16'hFFFF; i+=16'h10) begin
    //    codec_bfm_i.wdata = i;
    //    i2c_read(i);
    //    assert(rdata == i[7:0]);
    //end
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
    .ready(ready),
    .sda(sda),
    .scl(scl)
  );

  codec_bfm codec_bfm_i (
    .scl(scl),
    .sda(sda)
  );

endmodule
