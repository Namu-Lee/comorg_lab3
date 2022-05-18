// hazard.v

// This module determines if pipeline stalls or flushing are required

// TODO: declare propoer input and output ports and implement the
// hazard detection unit

module hazard (
  input taken, // branch misprediction penalty: flush

  // RAW data hazard of Load: stall
  input [4:0] ID_rs1,
  input [4:0] ID_rs2,
  input [6:0] ID_opcode,
  input [4:0] EX_rd,
  input EX_reg_write,
  input [6:0] EX_opcode, // check instruction type (Load or not)

  output reg flush,
  output reg stall
);

reg use_rs1, use_rs2, is_EX_load;

always @(*) begin
  /* branch misprediction flush */
  if (taken == 1) flush = 1;
  else flush = 0;

  /* Data hazard stall: Stall if EX_rs1 or EX_rs2 is forwarded from MEM & MEM_Load operation */
  // check if ID_inst uses rs1 or rs2 and it isnt' x0
  case (ID_opcode)
    7'b011_0011: {use_rs1, use_rs2} = {ID_rs1 != 0, ID_rs2 != 0}; // R-type
	7'b001_0011: {use_rs1, use_rs2} = {ID_rs1 != 0, 1'b0}; // I-type alu
	7'b000_0011: {use_rs1, use_rs2} = {ID_rs1 != 0, 1'b0}; // I-type load
	7'b010_0011: {use_rs1, use_rs2} = {ID_rs1 != 0, ID_rs2 != 0}; // S-type
	7'b110_0011: {use_rs1, use_rs2} = {ID_rs1 != 0, ID_rs2 != 0}; // B-type
	default: {use_rs1, use_rs2} = 2'b00;
  endcase

  is_EX_load = (EX_opcode[6:0] == 7'b000_0011); // check if EX_inst is Load op.

  if ( ( ((ID_rs1 == EX_rd) && use_rs1) || ((ID_rs2 == EX_rd) && use_rs2) ) && is_EX_load ) stall = 1;
  else stall = 0;

  if (flush == 1 && stall == 1) stall = 0;
end

endmodule
