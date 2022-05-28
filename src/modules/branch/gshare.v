// gshare.v

/* The Gshare predictor consists of the global branch history register (BHR)
 * and a pattern history table (PHT). Note that PC[1:0] is not used for
 * indexing.
 */

module gshare #(
  parameter DATA_WIDTH = 32,
  parameter COUNTER_WIDTH = 2,
  parameter NUM_ENTRIES = 256,
	parameter BHR_WIDTH = 8, // 2^BHR_WIDTH = NUM_ENTRIES
	parameter TAG_WIDTH = 22 // 30 - BHR_WIDTH
) (
  input clk,
  input rstn,

  // update interface
  input update,
  input actually_taken,
  input [DATA_WIDTH-1:0] resolved_pc,

  // access interface
  input [DATA_WIDTH-1:0] pc,

  output reg pred
);

// define Tag table, BHT, PHT
reg [BHR_WIDTH-1:0] branch_history;
reg [COUNTER_WIDTH-1:0] pattern_history [NUM_ENTRIES-1:0];

// define tag, index, gshare(index for tagtable-PHT)
wire [BHR_WIDTH-1:0] current_index = pc[BHR_WIDTH+1:2];
wire [BHR_WIDTH-1:0] resolved_index = resolved_pc[BHR_WIDTH+1:2];
wire [BHR_WIDTH-1:0] current_gshare = current_index ^ branch_history;
wire [BHR_WIDTH-1:0] resolved_gshare = resolved_index ^ branch_history;

integer i;

always @(posedge clk) begin 
	/* branch history register */
	// reset
	if (!rstn) begin 
		branch_history <= 0;
	end

	// update
	if (update) begin 
		branch_history <= {branch_history[BHR_WIDTH-2:0], actually_taken};
	end

	
	/* pattern history table */
	// reset
	if (!rstn) begin
		for (i = 0; i < NUM_ENTRIES; i = i + 1) begin // reset PHT (01: weakly NT)
      pattern_history[i] <= 2'b01;
    end
  end

	// update
	if (update) begin
		if (actually_taken) begin // resolved as T
			if (pattern_history[resolved_gshare] < 2'b11) begin
				pattern_history[resolved_gshare] <= pattern_history[resolved_gshare] + 2'b01;
			end
		end	
		else begin 
			if (pattern_history[resolved_gshare] > 2'b00) begin
				pattern_history[resolved_gshare] <= pattern_history[resolved_gshare] - 2'b01;
			end
		end
	end
end

always @(*) begin
	// access
	pred = pattern_history[current_gshare][1];
end


endmodule
