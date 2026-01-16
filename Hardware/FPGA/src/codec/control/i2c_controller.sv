//ADAU1761
//sends 16 bit address in 8 bit bursts
//MSB first
//
//start with single word r/w then do auto incrementing?

module i2c_controller #(
  parameter     C_CLK_DIVISOR = 16'd8
  )(
  input         clk,
  input         rst,
  input         rnw,
  input         valid,
  input  [15:0] address,
  input  [ 7:0] wdata,
  output [ 7:0] rdata,
  output logic  ready,
  inout         sda,
  output        scl);

  localparam logic [1:0] C_OP_IDLE      = 2'd0;
  localparam logic [1:0] C_OP_WRITE     = 2'd1;
  localparam logic [1:0] C_OP_READ      = 2'd2;
  localparam logic [1:0] C_OP_START     = 2'd3;
  localparam logic [6:0] C_CHIP_ADDRESS = 7'h38;

  //state typedef
  typedef enum logic [7:0] {S_IDLE, 
                            S_TX_CHIP_ADDRESS, 
                            S_RX_CHIP_ADDRESS_ACK, 
                            S_TX_ADDRESS, 
                            S_RX_ADDRESS_ACK, 
                            S_TX_SUB_ADDRESS, 
                            S_RX_SUB_ADDRESS_ACK, 
                            S_TX_WDATA, 
                            S_RX_WDATA_ACK, 
                            S_RX_RDATA, 
                            S_TX_RDATA_ACK} statetype_t;
  statetype_t curr_state, next_state;

  logic ack;
  logic go;
  logic op;
  logic [7:0] txdata;


  //state register
  always_ff @(posedge clk) begin
    if (rst) 
      curr_state <= S_IDLE;
    else     
      curr_state <= next_state;
  end

  //next state logic
  always_comb begin
    next_state = curr_state;
    case (curr_state)
      S_IDLE: 
        if (valid && ready)  
          next_state = S_TX_CHIP_ADDRESS;
      S_TX_CHIP_ADDRESS: 
        if (done)
          next_state = S_RX_CHIP_ADDRESS_ACK;
      S_RX_CHIP_ADDRESS_ACK:
        if (ack) 
          next_state = S_TX_ADDRESS;
      S_TX_ADDRESS: 
        if (done)
          next_state = S_RX_ADDRESS_ACK;
      S_RX_ADDRESS_ACK:
        if (ack)
          next_state = S_TX_SUB_ADDRESS;
      S_TX_SUB_ADDRESS: 
        if (done)
          next_state = S_RX_SUB_ADDRESS_ACK;
      S_RX_SUB_ADDRESS_ACK:
        if (ack)
          if (rnw)
            next_state = S_RX_RDATA;
          else 
            next_state = S_TX_WDATA;
      S_TX_WDATA:
        if (done)
          next_state = S_RX_WDATA_ACK;
      S_RX_WDATA_ACK:
        if (ack) 
          next_state = S_IDLE;
      S_RX_RDATA:
        if (done)
          next_state = S_TX_RDATA_ACK;
      S_TX_RDATA_ACK:
        if (ack) 
          next_state = S_IDLE;
      default: 
        next_state = S_IDLE;
    endcase
  end

  //state dependent signals
  always_ff @(posedge clk) begin
    if (rst)
      op <= 1'b0;
    else if (curr_state == S_RX_SUB_ADDRESS_ACK)
      op <= rnw;
    else 
      op <= 1'b0;

    if (rst)
      go <= 1'b0;
    else if (curr_state == S_IDLE || curr_state == S_RX_WDATA_ACK || curr_state == S_TX_RDATA_ACK)
      go <= 1'b0;
    else 
      go <= 1'b1;

    if (rst)
      txdata <= 8'b0;
    else if (next_state == S_TX_CHIP_ADDRESS)
      txdata <= {C_CHIP_ADDRESS, rnw};
    else if (next_state == S_RX_CHIP_ADDRESS_ACK)
      txdata <= address[15:8];
    else if (next_state == S_RX_ADDRESS_ACK)
      txdata <= address[7:0];
    else if (next_state == S_RX_SUB_ADDRESS_ACK)
      txdata <= wdata;

    if (rst)
      ready <= 1'b1;
    else if (curr_state == S_IDLE)
      ready <= 1'b1;
    else 
      ready <= 1'b0;


  end

  i2c_engine #(
    .C_CLK_DIVISOR(C_CLK_DIVISOR)) 
  i2c_engine_i (
    .clk(clk),
    .rst(rst),
    .rnw(op),
    .go(go),
    .wdata(txdata),
    .rdata(rdata),
    .done(done),
    .scl(scl),
    .sda(sda),
    .ack(ack));

endmodule
