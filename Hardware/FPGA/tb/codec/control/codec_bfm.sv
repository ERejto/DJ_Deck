module codec_bfm (
  input  logic scl,
  inout  logic sda
);

  localparam int C_BIT_COUNT = 8;

  logic       sda_in;
  logic       sda_out;
  logic       sda_en;
  int         bit_count;

  logic [7:0] rdata;
  logic [7:0] wdata;
  logic       rnw;

  assign sda    = (sda_en) ? sda_out : 1'bz;
  assign sda_in = sda;

  task automatic wait_start();
    @(negedge sda_in iff (scl === 1'b1));
  endtask

  task automatic sample_byte;
    for (int i = 7; i >= 0; i--) begin
      @(posedge scl);
      rdata[i] = sda_in; 
    end
  endtask

  task automatic drive_byte;
    sda_en = 1'b1;
    for (int i = 7; i >= 0; i--) begin
      @(negedge scl);
      sda_out = wdata[i];
      @(posedge scl);
    end
  endtask

  task automatic send_ack;
    @(negedge scl);
    sda_en  = 1'b1;
    sda_out = 1'b0;
    @(posedge scl);
    @(negedge scl);
    sda_en  = 1'b0;
    sda_out = 1'b1;
  endtask

  task automatic get_ack;
    @(negedge scl);
    sda_en = 1'b0; // release so master can drive
    @(posedge scl);
  endtask

  // ----------------------------
  // “Protocol” behavior
  // ----------------------------

  task automatic decode_address_byte();
    logic [7:0] addr;
    sample_byte;
    rnw = addr[0];     // LSB is R/W
  endtask

  initial begin
    // default released
    sda_en  = 1'b0;
    sda_out = 1'b1;
    wdata   = 8'hA5;   // example data to return on reads

    forever begin
      wait_start();

      // Address byte
      decode_address_byte(); send_ack();

      sample_byte; send_ack();  // "register address" maybe
      sample_byte; send_ack();  // "subaddress" maybe

      if (rnw) begin
        // Read: slave drives data, master ACKs/NACKs
        drive_byte;
        get_ack;
        // if NACK, master ended read; ignore for now
      end else begin
        // Write: master drives data, slave ACKs
        sample_byte;
        send_ack;
      end
    end end

endmodule

