// branch_hardware.v

/* This module comprises a branch predictor and a branch target buffer.
 * Our CPU will use the branch target address only when BTB is hit.
 */

module branch_hardware #(
  parameter DATA_WIDTH = 32,
  parameter COUNTER_WIDTH = 2,
  parameter NUM_ENTRIES = 256 // 2^8
) (
  input clk,
  input rstn,

  // update interface
  input update_predictor,
  input update_btb,
  input actually_taken,
  input [DATA_WIDTH-1:0] resolved_pc,
  input [DATA_WIDTH-1:0] resolved_pc_target,  // actual target address when the branch is resolved.

  // access interface
  input [DATA_WIDTH-1:0] pc,

  output reg hit,          // btb hit or not
  output reg pred,         // predicted taken or not
  output reg [DATA_WIDTH-1:0] branch_target  // branch target address for a hit
);

wire hit_wire, pred_wire;
wire [DATA_WIDTH-1:0] branch_target_wire;

branch_target_buffer m_branch_target_buffer (
  .clk								(clk),
  .rstn								(rstn),

  .update							(update_btb),
  .resolved_pc				(resolved_pc),
  .resolved_pc_target	(resolved_pc_target),

  .pc									(pc),

  .hit								(hit_wire),
  .target_address			(branch_target_wire)
);

gshare m_predictor (
  .clk						(clk),
  .rstn						(rstn),

  .update					(update_predictor),
  .actually_taken	(actually_taken),
  .resolved_pc		(resolved_pc),

  .pc							(pc),

  .pred						(pred_wire)
);

always @(*) begin
	hit = hit_wire;
	pred = pred_wire;
	branch_target = branch_target_wire;
end


endmodule
