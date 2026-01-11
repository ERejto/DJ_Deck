module i2c_engine # (
  parameter logic [15:0] C_CLK_DIVISOR = 16'd2
  )(
  input              clk,
  input              rst,
  input        [1:0] op,
  input        [7:0] wdata,
  output logic [7:0] rdata,
  output logic       scl,
  inout              sda,
  output logic       ack);

  localparam logic [1:0] C_OP_IDLE      = 2'd0;
  localparam logic [1:0] C_OP_WRITE     = 2'd1;
  localparam logic [1:0] C_OP_READ      = 2'd2;

  localparam logic [7:0] C_BYTE_LEN = 8'd7;

  logic        sda_dir;
  logic        sda_in;
  logic        sda_out;
  logic        scl_en;
  logic [ 7:0] shift_out_reg;
  logic [ 7:0] shift_in_reg;
  logic [ 3:0] bit_count;
  logic [15:0] scl_count; 

  assign sda = sda_dir ? 1'bz : sda_out; // default is writing data
  assign sda_in = sda;

  //sda_dir reg
  always_ff @(posedge clk) begin
    if (rst)
      sda_dir <= 1'b0; //default write
    else if (op == C_OP_IDLE || op == C_OP_READ)
      sda_dir <= 1'b1;
    else if (bit_count == C_BYTE_LEN+1) 
      sda_dir <= 1'b1; //ack bit
    else
      sda_dir <= 1'b0;
  end

  //shift in register
  always_ff @(posedge clk) begin
    if (rst)
      shift_in_reg <= 8'b0;
    else if (op == C_OP_IDLE)
      shift_in_reg <= 8'b0; 
    else if (op == C_OP_READ && scl_count == C_CLK_DIVISOR-1)
      shift_in_reg <= {shift_in_reg[6:0], sda_in};
  end

  //shift out register
  always_ff @(posedge clk) begin
    if (rst) 
      shift_out_reg <= 8'b0;
    else if (op == C_OP_IDLE)
      shift_out_reg <= wdata;
    else if (scl_count == C_CLK_DIVISOR/2-1)
      shift_out_reg <= {1'b0, shift_out_reg[7:1]};
  end
  
  //output data reg
  always_ff @(posedge clk) begin
    if (rst)
      sda_out <= 1'b1;
    else if (op == C_OP_IDLE)
      sda_out <= 1'b1;
    else if (op == C_OP_WRITE && scl_count == C_CLK_DIVISOR/2-1)
      sda_out <= shift_out_reg[0];
  end

  //counter enable bit
  always_ff @(posedge clk) begin
    if (rst) 
      scl_en <= 1'b0;
    else if (op == C_OP_IDLE) 
      scl_en <= 1'b0;
    else
      scl_en <= 1'b1;
  end

  //clk divisor counter
  always_ff @(posedge clk) begin
    if (rst || !scl_en)                  
      scl_count <= 16'b0;
    else if (scl_count == C_CLK_DIVISOR-1) 
      scl_count <= 16'b0;
    else                                 
      scl_count <= scl_count + 1'b1;
  end

  //scl register
  always_ff @(posedge clk) begin
    if (rst || !scl_en)               
      scl <= 1'b1;
    else if (scl_count == C_CLK_DIVISOR/2-1) 
      scl <= 1'b0;
    else if (scl_count == C_CLK_DIVISOR-1)   
      scl <= 1'b1;
  end

  //bit count register
  always_ff @(posedge clk) begin
    if (rst)                        
      bit_count <= 4'b0;
    else if (scl_count == C_CLK_DIVISOR-1) 
      if (bit_count == C_BYTE_LEN+1)
        bit_count <= 4'b0;
      else
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

endmodule
