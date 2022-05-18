// forwarding.v

// This module determines if the values need to be forwarded to the EX stage.

// TODO: declare propoer input and output ports and implement the
// forwarding unit

module forwarding (
  input [4:0] EX_rs1,
  input [4:0] EX_rs2,
  input [4:0] MEM_rd,
  input [4:0] WB_rd,
  input MEM_reg_write,
  input WB_reg_write,

  output reg [1:0] fwd_a,
  output reg [1:0] fwd_b
);
always @(*) begin
// fwd A
if ((EX_rs1 != 0) && (EX_rs1 == MEM_rd) && MEM_reg_write) // fwd MEM to EX
  fwd_a = 2'b01;
else if((EX_rs1 != 0) && (EX_rs1 == WB_rd) && WB_reg_write) //fwd WB to EX
  fwd_a = 2'b10;
else
  fwd_a = 2'b00;

// fwd B
if ((EX_rs2 != 0) && (EX_rs2 == MEM_rd) && MEM_reg_write) // fwd MEM to EX
  fwd_b = 2'b01;
else if((EX_rs2 != 0) && (EX_rs2 == WB_rd) && WB_reg_write) //fwd WB to EX
  fwd_b = 2'b10;
else
  fwd_b = 2'b00;

end
endmodule
