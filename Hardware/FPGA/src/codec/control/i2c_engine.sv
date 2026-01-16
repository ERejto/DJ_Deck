module i2c_engine # (
  parameter logic [15:0] C_CLK_DIVISOR = 16'd2
  )(
  input              clk,
  input              rst,
  input              go,
  input              rnw,
  output logic       done,
  input        [7:0] wdata,
  output logic [7:0] rdata,
  output logic       scl,
  inout              sda,
  output logic       ack);


  localparam logic [15:0] C_FALLING_EDGE = C_CLK_DIVISOR/2-1;
  localparam logic [15:0] C_RISING_EDGE  = C_CLK_DIVISOR-1;
  localparam logic [7:0] C_BYTE_LEN = 8'd8;
  typedef enum logic [7:0] {S_IDLE, 
                            S_START,
                            S_GET_BYTE, 
                            S_SET_BYTE, 
                            S_GET_ACK, 
                            S_SET_ACK,
                            S_STOP} statetype_t;
  statetype_t curr_state, next_state;

  logic        sda_dir;
  logic        sda_in;
  logic        sda_out;
  logic [ 7:0] shift_out_reg;
  logic [ 7:0] shift_in_reg;
  logic [ 3:0] bit_count;
  logic [15:0] scl_count; 

  assign sda = sda_dir ? 1'bz : sda_out; // default is writing data
  assign sda_out = (curr_state == S_START || curr_state == S_SET_ACK) ? 1'b0 : 
                   (curr_state == S_STOP  || curr_state == S_IDLE)    ? 1'b1 : shift_out_reg[7];
  assign sda_in = sda;
  assign rdata = shift_in_reg;

  always_ff @(posedge clk) begin
    if (rst)
      curr_state <= S_IDLE;
    else
      curr_state <= next_state;
  end

  always_comb begin
    next_state = curr_state;
    case(curr_state)
      S_IDLE:
        if (go)
          next_state = S_START;
      S_START:
        if (scl_count == C_FALLING_EDGE)
          if (rnw)
            next_state = S_GET_BYTE;
          else
            next_state = S_SET_BYTE;
      S_GET_BYTE:
        if (bit_count == C_BYTE_LEN)
          next_state = S_SET_ACK;
      S_SET_BYTE:
        if (bit_count == C_BYTE_LEN)
          next_state = S_GET_ACK;
      S_GET_ACK:
        if (scl_count == C_RISING_EDGE)
          if (!go)
            next_state = S_STOP;
          else if (rnw)
            next_state = S_GET_BYTE;
          else 
            next_state = S_SET_BYTE;
      S_SET_ACK:
        if (scl_count == C_RISING_EDGE)
          if (!go)
            next_state = S_STOP;
          else if (rnw)
            next_state = S_GET_BYTE;
          else 
            next_state = S_SET_BYTE;
      S_STOP:
        if (scl_count == C_FALLING_EDGE)
          next_state = S_IDLE;
      default:
        next_state = S_IDLE;
    endcase
  end


  //sda_dir reg
  always_ff @(posedge clk) begin
    if (rst)
      sda_dir <= 1'b0; //default write
    else if (next_state == S_GET_BYTE || next_state == S_GET_ACK || next_state == S_STOP)
      sda_dir <= 1'b1;
    else
      sda_dir <= 1'b0;
  end

  //shift in register
  always_ff @(posedge clk) begin
    if (rst)
      shift_in_reg <= 8'b0;
    else if (curr_state == S_IDLE)
      shift_in_reg <= 8'b0; 
    else if (curr_state == S_GET_BYTE && scl_count == C_RISING_EDGE)
      shift_in_reg <= {shift_in_reg[6:0], sda_in};
  end

  //shift out register
  always_ff @(posedge clk) begin
    if (rst) 
      shift_out_reg <= 8'b0;
    else if (curr_state == S_START || curr_state == S_GET_ACK)
      shift_out_reg <= wdata;
    else if (curr_state == S_SET_BYTE && scl_count == C_FALLING_EDGE && bit_count != 0)
      shift_out_reg <= {shift_out_reg[6:0], 1'b0};
  end
  

  //clk divisor counter
  always_ff @(posedge clk) begin
    if (rst || curr_state == S_IDLE)                  
      scl_count <= 16'b0;
    else if (scl_count == C_CLK_DIVISOR-1) 
      scl_count <= 16'b0;
    else                                 
      scl_count <= scl_count + 1'b1;
  end

  //scl register
  always_ff @(posedge clk) begin
    if (rst || curr_state == S_IDLE || curr_state == S_STOP)               
      scl <= 1'b1;
    else if (scl_count == C_FALLING_EDGE) 
      scl <= 1'b0;
    else if (scl_count == C_RISING_EDGE) 
      scl <= 1'b1;
  end

  //bit count register
  always_ff @(posedge clk) begin
    if (rst)                        
      bit_count <= 4'b0;
    else if (scl_count == C_RISING_EDGE) 
      if (bit_count == C_BYTE_LEN)
        bit_count <= 4'b0;
      else if (curr_state != S_IDLE && curr_state != S_START && curr_state != S_STOP) 
        bit_count <= bit_count + 4'b1;
    end

  //ack reg
  always_ff @(posedge clk) begin
    if (rst)
      ack <= 1'b0;
    else if (bit_count == C_BYTE_LEN && scl_count == C_CLK_DIVISOR-1)
      ack <= ~sda_in;
    else 
      ack <= 1'b0;
  end

  //done reg
  always_ff @(posedge clk) begin
    if (rst)
      done <= 1'b0;
    else if (next_state == S_GET_ACK || next_state == S_SET_ACK)
      done <= 1'b1;
    else
      done <= 1'b0;
  end

endmodule

