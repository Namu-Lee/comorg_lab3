// branch_target_buffer.v

/* The branch target buffer (BTB) stores the branch target address for
 * a branch PC. Our BTB is essentially a direct-mapped cache.
 */

module branch_target_buffer #(
  parameter DATA_WIDTH = 32,
  parameter NUM_ENTRIES = 256,
	parameter BHR_WIDTH = 8,
  parameter TAG_WIDTH = 22 // 30 - BHR_WIDTH
) (
  input clk,
  input rstn,

  // update interface
  input update,                              // when 'update' is true, we update the BTB entry
  input [DATA_WIDTH-1:0] resolved_pc,
  input [DATA_WIDTH-1:0] resolved_pc_target,

  // access interface
  input [DATA_WIDTH-1:0] pc,

  output reg hit,
  output reg [DATA_WIDTH-1:0] target_address
);

// define tag_table, branch target, valid bit
reg [TAG_WIDTH-1:0] tag_table [NUM_ENTRIES-1:0];
reg [DATA_WIDTH-1:0] target_buffer [NUM_ENTRIES-1:0];
reg [NUM_ENTRIES-1:0] valid;

// hash PC into tag and BTB index
wire [TAG_WIDTH-1:0] current_tag = pc[DATA_WIDTH-1 : DATA_WIDTH - TAG_WIDTH];
wire [TAG_WIDTH-1:0] resolved_tag = resolved_pc[DATA_WIDTH-1 : DATA_WIDTH - TAG_WIDTH];
wire [BHR_WIDTH-1:0] current_index = pc[BHR_WIDTH+1:2];
wire [BHR_WIDTH-1:0] resolved_index = resolved_pc[BHR_WIDTH+1:2];

// check signal: does the tag of pc match to the tag in the table?
wire tag_matched = (current_tag == tag_table[current_index]) ? 1:0;


always @(posedge clk) begin
	// reset
	if (!rstn) begin
		valid <= 0;
	end

	// update
	if (update) begin
		tag_table[resolved_index] <= resolved_tag;
		valid[resolved_index] <= 1;
		target_buffer[resolved_index] <= resolved_pc_target;
	end
end

always @(*) begin
	// access
	hit = tag_matched & valid;
	target_address = target_buffer[current_index];
end

endmodule
