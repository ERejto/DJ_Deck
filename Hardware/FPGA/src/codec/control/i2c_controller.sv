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

  localparam C_CHIP_ADDRESS_LEN = 7;
  localparam C_BYTE_LEN         = 8;

  //state typedef
  typedef enum logic [7:0] {S_IDLE, S_TX_CHIP_ADDRESS, S_TX_RBIT, S_TX_WBIT, S_TX_ADDRESS, S_TX_SUB_ADDRESS, S_TX_WDATA, S_RX_RDATA} statetype_t;
  statetype_t curr_state, next_state;

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
        if (bit_count == C_CHIP_ADDRESS_LEN) 
          if (rnw_r) 
            next_state = S_TX_RBIT;
          else
            next_state = S_TX_WBIT;
      S_TX_RBIT: 
        if (bit_count == C_BYTE_LEN) 
          next_state = S_TX_ADDRESS;
      S_TX_WBIT: 
        if (bit_count == C_BYTE_LEN) 
          next_state = S_TX_ADDRESS;
      S_TX_ADDRESS: 
        if (bit_count == C_BYTE_LEN)
          next_state = S_TX_SUB_ADDRESS;
      S_TX_SUB_ADDRESS: 
        if (bit_count == C_BYTE_LEN)
          if (rnw_r)
            next_state = S_RX_RDATA;
          else 
            next_state = S_TX_WDATA;
      S_TX_WDATA:
        if (bit_count == C_BYTE_LEN) 
          next_state = S_IDLE;
      S_RX_RDATA:
        if (bit_count == C_BYTE_LEN) 
          next_state = S_IDLE;
      default: 
        next_state = S_IDLE;
    endcase
  end

  //state outputs
  always_ff @(posedge clk) begin
    if (rst) 
      scl_en <= 1'b0;
    else if (curr_state == S_IDLE) 
      scl_en <= 1'b0;
    else 
      scl_en <= 1'b1;

    if (rst) 
      sda_dir <= 1'b0;
    else if (curr_state == S_RX_RDATA) 
      sda_dir <= 1'b1;

    if (rst)
      rnw_r <= 1'b0;
    else if (next_state == S_TX_CHIP_ADDRESS)
      rnw_r <= rnw;
  end

endmodule
