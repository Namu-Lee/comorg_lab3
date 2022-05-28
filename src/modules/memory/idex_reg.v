// idex_reg.v
// This module is the ID/EX pipeline register.


module idex_reg #(
  parameter DATA_WIDTH = 32
)(
  //////////////////////////////////////
  // Inputs
  //////////////////////////////////////
  input clk,

  input [DATA_WIDTH-1:0] id_PC,
  input [DATA_WIDTH-1:0] id_pc_plus_4,

  // ex control
  input [1:0] id_jump,
  input id_branch,
  input [1:0] id_aluop,
  input id_alusrc,

  // mem control
  input id_memread,
  input id_memwrite,

  // wb control
  input id_memtoreg,
  input id_regwrite,

  // u-type
  input [1:0] id_utype,

  input [DATA_WIDTH-1:0] id_sextimm,
  input [6:0] id_funct7,
  input [2:0] id_funct3,
  input [DATA_WIDTH-1:0] id_readdata1,
  input [DATA_WIDTH-1:0] id_readdata2,
  input [4:0] id_rs1,
  input [4:0] id_rs2,
  input [4:0] id_rd,
  input [6:0] id_opcode,

	input id_target_fetch,	
  input flush,
  input stall,

  //////////////////////////////////////
  // Outputs
  //////////////////////////////////////
  output reg [DATA_WIDTH-1:0] ex_PC,
  output reg [DATA_WIDTH-1:0] ex_pc_plus_4,

  // ex control
  output reg ex_branch,
  output reg [1:0] ex_aluop,
  output reg ex_alusrc,
  output reg [1:0] ex_jump,

  // mem control
  output reg ex_memread,
  output reg ex_memwrite,

  // wb control
  output reg ex_memtoreg,
  output reg ex_regwrite,

  // u-type
  output reg [1:0] ex_utype,

  output reg [DATA_WIDTH-1:0] ex_sextimm,
  output reg [6:0] ex_funct7,
  output reg [2:0] ex_funct3,
  output reg [DATA_WIDTH-1:0] ex_readdata1,
  output reg [DATA_WIDTH-1:0] ex_readdata2,
  output reg [4:0] ex_rs1,
  output reg [4:0] ex_rs2,
  output reg [4:0] ex_rd,
  output reg [6:0] ex_opcode,

	output reg ex_target_fetch
);

always @(posedge clk) begin 
  if(flush == 0 && stall == 0) begin
		ex_PC						<= id_PC;
		ex_pc_plus_4		<= id_pc_plus_4;
		ex_branch				<= id_branch;
		ex_aluop				<= id_aluop;
		ex_alusrc				<= id_alusrc;
		ex_jump					<= id_jump;
		ex_memread			<= id_memread;
		ex_memwrite			<= id_memwrite;
		ex_memtoreg			<= id_memtoreg;
		ex_regwrite			<= id_regwrite;
		ex_utype				<= id_utype;
		ex_sextimm			<= id_sextimm;
		ex_funct7				<= id_funct7;
		ex_funct3				<= id_funct3;
		ex_readdata1		<= id_readdata1;
		ex_readdata2		<= id_readdata2;
		ex_rs1					<= id_rs1;
		ex_rs2					<= id_rs2;
		ex_rd						<= id_rd;
		ex_opcode				<= id_opcode;
		ex_target_fetch	<= id_target_fetch;
  end
  else begin // flush(or stall) operation: insert NOP to EX
    ex_branch				<= 0;
    ex_memread			<= 0;
    ex_memwrite			<= 0;
    ex_memtoreg			<= 0;
    ex_regwrite			<= 0;
    ex_opcode				<= 7'b001_0011;
		ex_target_fetch	<= 0;
		ex_utype				<= 0;
  end 
  
end

endmodule
