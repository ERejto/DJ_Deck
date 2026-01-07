module i2c_engine # (
  parameter C_CLK_DIVISOR = 2,
  parameter 
  )(
  input clk,
  input rst,
  input [1:0] op,
  output scl,
  inout sda,
  
  );

  logic        sda_dir;
  logic        sda_out;
  logic        scl_en;
  logic        rnw_r;
  logic [ 7:0] shift_out_reg;
  logic [ 7:0] shift_in_reg;
  logic [ 3:0] bit_count;
  logic [15:0] scl_count; 
  
  assign sda = sda_dir ? 1'bz : sda_out; // default is writing data

  //shift out register
  always_ff @(posedge clk) begin
  end

  //shift in register
  always_ff @(posedge clk) begin
  end


  //clk divisor counter
  always_ff @(posedge clk) begin
    if (rst || !scl_en)                  
      scl_count <= 16'b0;
    else if (scl_count == C_CLK_DIVISOR) 
      scl_count <= 16'b0;
    else                                 
      scl_count <= scl_count + 1'b1;
  end

  //scl register
  always_ff @(posedge clk) begin
    if (rst || !scl_en)               
      scl <= 1'b1;
    else if (scl_count == C_CLK_DIVISOR/2) 
      scl <= 1'b0;
    else if (scl_count == C_CLK_DIVISOR)   
      scl <= 1'b1;
  end

  //bit count register
  always_ff @(posedge clk) begin
    if (rst)                        
      bit_count <= 4'b0;
    else if (bit_count == C_BYTE_LEN)          
      bit_count <= 4'b0;
    else if (scl_count == C_CLK_DIVISOR) 
      bit_count <= bit_count + 4'b1;
    end

endmodule
