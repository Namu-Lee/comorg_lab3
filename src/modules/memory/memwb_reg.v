// memwb_reg.v
// This module is the MEM/WB pipeline register.


module memwb_reg #(
  parameter DATA_WIDTH = 32
)(
  // TODO: Add flush or stall signal if it is needed

  //////////////////////////////////////
  // Inputs
  //////////////////////////////////////
  input clk,

  input [DATA_WIDTH-1:0] mem_pc_plus_4,

  // wb control
  input [1:0] mem_jump,
  input mem_memtoreg,
  input mem_regwrite,
  
  input [DATA_WIDTH-1:0] mem_readdata,
  input [DATA_WIDTH-1:0] mem_alu_result,
  input [4:0] mem_rd,

	input [DATA_WIDTH-1:0] mem_imm,
	input [DATA_WIDTH-1:0] mem_pc_plus_imm,
	input [1:0]	mem_utype,
  
  //////////////////////////////////////
  // Outputs
  //////////////////////////////////////
  output reg [DATA_WIDTH-1:0] wb_pc_plus_4,

  // wb control
  output reg [1:0] wb_jump,
  output reg wb_memtoreg,
  output reg wb_regwrite,
  
  output reg [DATA_WIDTH-1:0] wb_readdata,
  output reg [DATA_WIDTH-1:0] wb_alu_result,
  output reg [4:0] wb_rd,

	output reg [DATA_WIDTH-1:0] wb_imm,
  output reg [DATA_WIDTH-1:0] wb_pc_plus_imm,
  output reg [1:0] wb_utype
);


always @(posedge clk) begin // No need to flush or stall
	wb_pc_plus_4		<= mem_pc_plus_4;
	wb_jump					<= mem_jump;
	wb_memtoreg			<= mem_memtoreg;
	wb_regwrite			<= mem_regwrite;
	wb_readdata			<= mem_readdata;
	wb_alu_result		<= mem_alu_result;
	wb_rd						<= mem_rd;
	wb_imm					<= mem_imm;
	wb_pc_plus_imm	<= mem_pc_plus_imm;
	wb_utype				<= mem_utype;

end

endmodule
