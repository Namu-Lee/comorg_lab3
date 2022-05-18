// ifid_reg.v
// This module is the IF/ID pipeline register.


module ifid_reg #(
  parameter DATA_WIDTH = 32
)(
  // TODO: Add flush or stall signal if it is needed

  //////////////////////////////////////
  // Inputs
  //////////////////////////////////////
  input clk,

  input [DATA_WIDTH-1:0] if_PC,
  input [DATA_WIDTH-1:0] if_pc_plus_4,
  input [DATA_WIDTH-1:0] if_instruction,

  input flush,
  input stall,

  //////////////////////////////////////
  // Outputs
  //////////////////////////////////////
  output reg [DATA_WIDTH-1:0] id_PC,
  output reg [DATA_WIDTH-1:0] id_pc_plus_4,
  output reg [DATA_WIDTH-1:0] id_instruction
);

// TODO: Implement IF/ID pipeline register module

always @(posedge clk) begin
  if (flush == 0 && stall == 0) begin //Normal operation
    id_PC <= if_PC;
	id_pc_plus_4 <= if_pc_plus_4;
	id_instruction <= if_instruction;
  end
  else if (flush == 1) begin // flush operation: insert NOP to ID stage
    id_instruction <= 32'b0000_0000_0000_00000_000_00000_0010011;
  end
  // stall operation: do not change reg values
end

endmodule
