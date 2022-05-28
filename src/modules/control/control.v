// control.v

// The main control module takes as input the opcode field of an instruction
// (i.e., instruction[6:0]) and generates a set of control signals.

// Description
// jump			  | 00: not jump				 					 | 10: JAL				
//						| 11: JALR

// branch     | 0: not branch   			 			 | 1 : branch
// mem_read   | 0: disable read mem 		 		 | 1: enable read mem
// mem_to_reg | 0: disable write RF from mem | 1: enable write RF from mem

// alu_op 	  | 00: load/store				 			 | 01: branch
//			  		| 10: R-type					 				 | 11: I-type

// mem_write  | 0: disable write mem		 		 | 1: enable write mem
// alu_src	  | 0: alu src_b from RF  		 	 | 1: alu src_b from immediate
// reg_write  | 0: disable write RF			 		 | 1: enable write RF

// u_type	  	| 00: not U					 					 | 01: X
//			  		| 10: lui						 					 | 11: auipc

module control(
  input [6:0] opcode,

  output [1:0] jump,
  output branch,
  output mem_read,
  output mem_to_reg,
  output [1:0] alu_op,
  output mem_write,
  output alu_src,
  output reg_write,
  output [1:0] u_type
);

reg [11:0] controls;

always @(*) begin
  case (opcode)
    7'b0110011: controls = 12'b00_000_10_001_00; // R-type
		7'b0010011: controls = 12'b00_000_11_011_00; // I-type
		7'b0000011: controls = 12'b00_011_00_011_00; // Load (I)
		7'b0100011: controls = 12'b00_00x_00_110_00; // Store (S)
		7'b1100011: controls = 12'b00_10x_01_000_00; // B-type
		7'b1101111: controls = 12'b10_100_xx_0x1_00; // JAL (J)
		7'b1100111: controls = 12'b11_100_xx_0x1_00; // JALR (I)
		7'b0110111: controls = 12'b00_000_xx_0x1_10; // LUI (U)
		7'b0010111: controls = 12'b00_000_xx_0x1_11; // AUIPC (U)
    default:    controls = 12'b00_000_00_000_00;
  endcase
end

assign {jump, 
		branch, mem_read, mem_to_reg, 
		alu_op, 
		mem_write, alu_src, reg_write,
		u_type} = controls;

endmodule
