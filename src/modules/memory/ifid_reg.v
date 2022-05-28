// ifid_reg.v
// This module is the IF/ID pipeline register.


module ifid_reg #(
  parameter DATA_WIDTH = 32
)(

  //////////////////////////////////////
  // Inputs
  //////////////////////////////////////
  input clk,

  input [DATA_WIDTH-1:0] if_PC,
  input [DATA_WIDTH-1:0] if_pc_plus_4,
  input [DATA_WIDTH-1:0] if_instruction,

  input if_target_fetch,
	input flush,
  input stall,

  //////////////////////////////////////
  // Outputs
  //////////////////////////////////////
  output reg [DATA_WIDTH-1:0] id_PC,
  output reg [DATA_WIDTH-1:0] id_pc_plus_4,
  output reg [DATA_WIDTH-1:0] id_instruction,
	output reg id_target_fetch
);


always @(posedge clk) begin
  if (flush == 0 && stall == 0) begin //Normal operation
    id_PC 					<= if_PC;
		id_pc_plus_4 		<= if_pc_plus_4;
		id_instruction	<= if_instruction;
		id_target_fetch	<= if_target_fetch;
  end
	else if (flush == 1) begin // flush operation: insert NOP to ID stage
    id_instruction	<= 32'b0000_0000_0000_00000_000_00000_0010011;
		id_target_fetch	<= 0;
  end

	
  // stall operation: do not change reg values
end

endmodule
