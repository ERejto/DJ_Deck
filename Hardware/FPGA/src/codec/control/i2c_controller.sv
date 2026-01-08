//ADAU1761
//sends 16 bit address in 8 bit bursts
//MSB first
//
//start with single word r/w then do auto incrementing?

module i2c_controller #(
  parameter     C_CLK_DIVISOR = 16'd2
  )(
  input         clk,
  input         rst,
  input         rnw,
  input         start,
  input  [15:0] address,
  input  [ 7:0] wdata,
  output [ 7:0] rdata,
  inout         sda,
  output        scl);

  localparam logic [1:0] C_OP_IDLE      = 2'd0;
  localparam logic [1:0] C_OP_WRITE     = 2'd1;
  localparam logic [1:0] C_OP_READ      = 2'd2;
  localparam logic [6:0] C_CHIP_ADDRESS = 7'h38;

  //state typedef
  typedef enum logic [7:0] {S_IDLE, S_TX_CHIP_ADDRESS, S_TX_ADDRESS, S_TX_SUB_ADDRESS, S_TX_WDATA, S_RX_RDATA} statetype_t;
  statetype_t curr_state, next_state;

  logic ack;
  logic [1:0] op;
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
        if (start)  
          next_state = S_TX_CHIP_ADDRESS;
      S_TX_CHIP_ADDRESS: 
        if (ack) 
          next_state = S_TX_ADDRESS;
      S_TX_ADDRESS: 
        if (ack)
          next_state = S_TX_SUB_ADDRESS;
      S_TX_SUB_ADDRESS: 
        if (ack)
          if (rnw)
            next_state = S_RX_RDATA;
          else 
            next_state = S_TX_WDATA;
      S_TX_WDATA:
        if (ack) 
          next_state = S_IDLE;
      S_RX_RDATA:
        if (ack) 
          next_state = S_IDLE;
      default: 
        next_state = S_IDLE;
    endcase
  end

  //state dependent signals
  always_ff @(posedge clk) begin
    if (rst)
      op <= C_OP_IDLE;
    else if (curr_state == S_IDLE)
      op <= C_OP_IDLE;
    else if (curr_state == S_RX_RDATA)
      op <= C_OP_READ;
    else 
      op <= C_OP_WRITE;

    if (rst)
      txdata <= 8'b0;
    else if (curr_state == S_TX_CHIP_ADDRESS)
      txdata <= {C_CHIP_ADDRESS, rnw};
    else 
      txdata <= wdata;

  end

  i2c_engine #(
    .C_CLK_DIVISOR(C_CLK_DIVISOR)) 
  i2c_engine_i (
    .clk(clk),
    .rst(rst),
    .op(op),
    .wdata(txdata),
    .rdata(rdata),
    .scl(scl),
    .sda(sda),
    .ack(ack));

endmodule
