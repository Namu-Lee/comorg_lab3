// simple_cpu.v
// a pipelined RISC-V microarchitecture (RV32I)

///////////////////////////////////////////////////////////////////////////////////////////
//// [*] In simple_cpu.v you should connect the correct wires to the correct ports
////     - All modules are given so there is no need to make new modules
////       (it does not mean you do not need to instantiate new modules)
////     - However, you may have to fix or add in / out ports for some modules
////     - In addition, you are still free to instantiate simple modules like multiplexers,
////       adders, etc.
///////////////////////////////////////////////////////////////////////////////////////////

module simple_cpu
#(parameter DATA_WIDTH = 32)(
  input clk,
  input rstn
);

//////////////////////////////////////////////////////////////////////////////////
// Hardware Counters
//////////////////////////////////////////////////////////////////////////////////

wire [31:0] CORE_CYCLE;
hardware_counter m_core_cycle(
  .clk(clk),
  .rstn(rstn),
  .cond(1'b1),

  .counter(CORE_CYCLE)
);

//////////////////////////////////////////////////////////////////////////////////
// reg & wires
//////////////////////////////////////////////////////////////////////////////////

reg [DATA_WIDTH-1:0] PC;    // program counter (32 bits)
wire [DATA_WIDTH-1:0] NEXT_PC;


wire [DATA_WIDTH-1:0] IF_pc_plus_4, IF_inst, IF_pred_target;
wire IF_hit, IF_pred_tmp, IF_update_predictor;


wire [DATA_WIDTH-1:0] ID_PC, ID_pc_plus_4, ID_inst, ID_imm,ID_readdata1, ID_readdata2;
wire [1:0] ID_jump, ID_alu_op, ID_utype;
wire ID_branch, ID_alu_src, ID_mem_read, ID_mem_to_reg, ID_mem_write, ID_reg_write, ID_target_fetch;


wire [DATA_WIDTH-1:0] EX_PC, EX_pc_plus_4, EX_imm, EX_readdata1, EX_readdata2, EX_target_base, EX_target, EX_alu_in_a, EX_alu_in_b, EX_alu_result, EX_alu_result_from_alu, EX_mem_writedata, EX_pc_plus_imm, EX_rs1_from_MEM, EX_rs2_from_MEM, EX_rs1_value, EX_rs2_value;

wire [6:0] EX_opcode, EX_funct7;
wire [4:0] EX_rs1, EX_rs2, EX_rd;
wire [3:0] EX_alu_func;
wire [2:0] EX_funct3;
wire [1:0] EX_jump, EX_alu_op, EX_utype, EX_fwd_a, EX_fwd_b; 
wire EX_branch, EX_taken, EX_alu_src, EX_mem_read, EX_mem_write, EX_mem_to_reg, EX_reg_write, EX_check, EX_target_fetch;

wire [DATA_WIDTH-1:0] 
wire [DATA_WIDTH-1:0] MEM_PC, MEM_pc_plus_4, MEM_target, MEM_rs2_value, MEM_alu_result, MEM_mem_readdata, MEM_imm, MEM_pc_plus_imm;
wire [4:0] MEM_rd;
wire [2:0] MEM_funct3;
wire [1:0] MEM_jump, MEM_utype;
wire MEM_taken, MEM_mem_read, MEM_mem_write, MEM_mem_to_reg, MEM_reg_write, MEM_target_fetch;


wire [DATA_WIDTH-1:0] WB_pc_plus_4, WB_mem_readdata, WB_alu_result, WB_writedata, WB_imm, WB_pc_plus_imm, WB_writedata_for_utype;
wire [4:0] WB_rd;
wire [1:0] WB_jump, WB_utype;
wire WB_mem_to_reg, WB_reg_write;


wire stall;
wire flush;


///////////////////////////////////////////////////////////////////////////////
// Instruction Fetch (IF)
///////////////////////////////////////////////////////////////////////////////

/* m_next_pc_adder */
adder m_pc_plus_4_adder(
  .in_a   (PC),
  .in_b   (32'd4),

  .result (IF_pc_plus_4)
);


/* reset: active low */
always @(posedge clk) begin
  if (rstn == 1'b0) begin
    PC <= 32'h00000000;
  end
  else PC <= NEXT_PC;
end


/* instruction: read current instruction from inst mem */
instruction_memory m_instruction_memory(
  .address    (PC),

  .instruction(IF_inst)
);


/* branch prediction hardware */
assign IF_update_predictor = MEM_branch & (~MEM_jump[1]);
branch_hardware m_branch_hardware (
	.clk								(clk),
	.rstn								(rstn),
	
	.update_predictor		(MEM_update_predictor),
	.update_btb					(MEM_taken),
	.actually_taken			(MEM_taken),
	.resolved_pc				(MEM_PC),
	.resolved_pc_target	(MEM_target),

	.pc									(PC),
	
	.hit								(IF_hit),
	.pred								(IF_pred_tmp),
	.branch_target			(IF_pred_target)
);

/* next pc source control signal generation module */
reg [1:0] IF_next_pc_src;
reg IF_target_fetch, IF_pred;
always @(*) begin
	case (IF_inst[6:0])
		7'b110_0011: IF_pred = IF_pred_tmp; // conditional
		7'b110_1111: IF_pred = 1; // jal 
		7'b110_0111: IF_pred = 1; // jalr
		default:		 IF_pred = 0; 
	endcase

	IF_target_fetch = IF_pred & IF_hit;

	casex ({flush, stall, IF_target_fetch})
		3'b1xx:  IF_next_pc_src = 2'b01; // flush
		3'b01x:  IF_next_pc_src = 2'b11; // stall
		3'b001:  IF_next_pc_src = 2'b10; // predicted target
		default: IF_next_pc_src = 2'b00; // general case, pred NT
	endcase
end


/* next pc source selector */
mux_4x1 mux_next_pc_select (
  .select	(IF_next_pc_src),
	.in1		(IF_pc_plus_4), // general case, or pred NT
  .in2		(MEM_target), // branch misprediction: flush
  .in3		(IF_pred_target), // pred T
  .in4		(PC), // data hazard: stall

  .out		(NEXT_PC)
);

/* forward to IF/ID stage registers */
ifid_reg m_ifid_reg(
  .clk            	(clk),
  .if_PC          	(PC),
  .if_pc_plus_4   	(IF_pc_plus_4),
  .if_instruction 	(IF_inst),
	.if_target_fetch	(IF_target_fetch),
  .flush 						(flush),
  .stall 						(stall),

  .id_PC          	(ID_PC),
  .id_pc_plus_4   	(ID_pc_plus_4),
  .id_instruction 	(ID_inst),
	.id_target_fetch	(ID_target_fetch)
);


//////////////////////////////////////////////////////////////////////////////////
// Instruction Decode (ID)
//////////////////////////////////////////////////////////////////////////////////


/* m_hazard: hazard detection unit */
hazard m_hazard(
  .taken				(MEM_taken),
  .branch 			(MEM_branch),
	.prediction		(MEM_target_fetch),
	.ID_rs1 			(ID_inst[19:15]),
  .ID_rs2 			(ID_inst[24:20]),
  .ID_opcode 		(ID_inst[6:0]),
  .EX_rd 				(EX_rd),
  .EX_reg_write (EX_reg_write),
  .EX_opcode 		(EX_opcode),
				
  .flush (flush),
  .stall (stall)
);


/* m_control: control unit */
control m_control(
  .opcode     (ID_inst[6:0]),

  .jump       (ID_jump),
  .branch     (ID_branch),
  .alu_op     (ID_alu_op),
  .alu_src    (ID_alu_src),
  .mem_read   (ID_mem_read),
  .mem_to_reg (ID_mem_to_reg),
  .mem_write  (ID_mem_write),
  .reg_write  (ID_reg_write),
  .u_type	  	(ID_utype)
);


/* m_imm_generator: immediate generator */
immediate_generator m_immediate_generator(
  .instruction	(ID_inst),

  .sextimm			(ID_imm)
);

/* m_register_file: register file */
register_file m_register_file(
  .clk        (clk),
  .readreg1   (ID_inst[19:15]),
  .readreg2   (ID_inst[24:20]),
  .writereg   (WB_rd),
  .wen        (WB_reg_write),
  .writedata  (WB_writedata),

  .readdata1  (ID_readdata1),
  .readdata2  (ID_readdata2)
);


/* forward to ID/EX stage registers */
idex_reg m_idex_reg(
  .clk							(clk),
  .id_PC						(ID_PC),
  .id_pc_plus_4			(ID_pc_plus_4),
  .id_jump					(ID_jump),
  .id_branch				(ID_branch),
  .id_aluop					(ID_alu_op),
  .id_alusrc				(ID_alu_src),
  .id_memread				(ID_mem_read),
  .id_memwrite			(ID_mem_write),
  .id_memtoreg			(ID_mem_to_reg),
  .id_regwrite			(ID_reg_write),
  .id_utype					(ID_utype),
  .id_sextimm				(ID_imm),
  .id_funct7				(ID_inst[31:25]),
  .id_funct3				(ID_inst[14:12]),
  .id_readdata1			(ID_readdata1),
  .id_readdata2			(ID_readdata2),
  .id_rs1						(ID_inst[19:15]),
  .id_rs2       		(ID_inst[24:20]),
  .id_rd        		(ID_inst[11:7]),
  .id_opcode    		(ID_inst[6:0]),
	.id_target_fetch	(ID_target_fetch),
  .flush						(flush),
  .stall 						(stall),

  .ex_PC						(EX_PC),
  .ex_pc_plus_4			(EX_pc_plus_4),
  .ex_jump					(EX_jump),
  .ex_branch				(EX_branch),
  .ex_aluop					(EX_alu_op),
  .ex_alusrc				(EX_alu_src),
  .ex_memread 			(EX_mem_read),
  .ex_memwrite			(EX_mem_write),
  .ex_memtoreg			(EX_mem_to_reg),
  .ex_regwrite			(EX_reg_write),
  .ex_utype					(EX_utype),
  .ex_sextimm				(EX_imm),
  .ex_funct7				(EX_funct7),
  .ex_funct3				(EX_funct3),
  .ex_readdata1			(EX_readdata1),
  .ex_readdata2			(EX_readdata2),
  .ex_rs1						(EX_rs1),
  .ex_rs2						(EX_rs2),
  .ex_rd						(EX_rd),
  .ex_opcode    		(EX_opcode),
	.ex_target_fetch	(EX_target_fetch)
);

//////////////////////////////////////////////////////////////////////////////////
// Execute (EX) 
//////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
// Data flow operaton (forwarding)
//////////////////////////////////////////////////////////////////////////////////

/* fowrading control unit */
forwarding m_forwarding(
  .EX_rs1					(EX_rs1),
  .EX_rs2					(EX_rs2),
  .MEM_rd					(MEM_rd),
  .WB_rd					(WB_rd),
  .MEM_reg_write	(MEM_reg_write),
  .WB_reg_write		(WB_reg_write),

  .fwd_a					(EX_fwd_a), // 00 not forwarding, 01 from MEM, 10 from WB
  .fwd_b					(EX_fwd_b)
);

/* rs1_from_MEM selector */
mux_4x1 mux_rs1_from_MEM (
	.select	({1'b0, EX_jump[1]} | EX_utype),
	.in1		(MEM_alu_result), 	// general case
	.in2		(MEM_pc_plus_4),		// jump (pc+4)
	.in3		(MEM_imm),					// lui (imm)
	.in4		(MEM_pc_plus_imm),	// auipc (pc+imm)
	
	.out		(EX_rs1_from_MEM)
);


/* rs2_from_MEM selector */
mux_4x1 mux_rs2_from_MEM (
  .select ({1'b0, EX_jump[1]} | EX_utype),
  .in1    (MEM_alu_result),   // general case
  .in2    (MEM_pc_plus_4),    // jump (pc+4)
  .in3    (MEM_imm),          // lui (imm)
  .in4    (MEM_pc_plus_imm),  // auipc (pc+imm)

  .out    (EX_rs2_from_MEM)
);


/* rs1 selector (forward or not) */
mux_3x1 mux_rs1 (
	.select (EX_fwd_a),
	.in1		(EX_readdata1),			// RF
	.in2		(EX_rs1_from_MEM),	// forward from MEM
	.in3		(WB_writedata),			// forward from WB

	.out		(EX_rs1_value)
);


/* rs2 selector (forward or not) */
mux_3x1 mux_rs2 (
  .select (EX_fwd_b),
  .in1    (EX_readdata2),
  .in2    (EX_rs2_from_MEM),
  .in3    (WB_writedata),

  .out    (EX_rs2_value)
);


//////////////////////////////////////////////////////////////////////////////////
// Arithmetic & Logic operation (ALU & adders)
//////////////////////////////////////////////////////////////////////////////////

/* pc+imm adder */
adder m_pc_plus_imm_adder (
	.in_a		(EX_PC),
	.in_b		(EX_imm),

	.result	(EX_pc_plus_imm)
);


/* alu control (generates alu_func) */
alu_control m_alu_control (
  .alu_op   (EX_alu_op),
  .funct7   (EX_funct7),
  .funct3   (EX_funct3),

  .alu_func (EX_alu_func)
);


/* alu input_1 selector (rs1) */
assign EX_alu_in_a = EX_rs1_value;


/* alu input_2 selector (rs2 or imm) */
mux_2x1 mux_alu_in_b (
	.select	(EX_alu_src),
	.in1		(EX_rs2_value),
	.in2		(EX_imm),

	.out		(EX_alu_in_b)
);


/* ALU */
alu m_alu(
  .alu_func (EX_alu_func),
  .in_a     (EX_alu_in_a), 
  .in_b     (EX_alu_in_b), 

  .result   (EX_alu_result),
  .check    (EX_check)
);


/*
mux_3x1 mux_alu_in_1(
  .select(EX_fwd_a),
  .in1(EX_readdata1), //00, RF
  .in2(MEM_alu_result), //01, fwd from MEM
  .in3(WB_writedata), //10, fwd from WB

  .out(EX_alu_in_a)
);
mux_4x1 mux_alu_in_2(
  .select({2{EX_alu_src}} | EX_fwd_b),
  .in1(EX_readdata2), // RF
  .in2(MEM_alu_result), // fwd from MEM
  .in3(WB_writedata), // fwd from WB
  .in4(EX_imm), // immediate

  .out(EX_alu_in_b)
);
mux_3x1 mem_writedata_select (
  .select (EX_fwd_b),
  .in1 (EX_readdata2),
  .in2 (MEM_alu_result),
  .in3 (WB_writedata),

  .out (EX_mem_writedata)
);
*/


//////////////////////////////////////////////////////////////////////////////////
// Control flow opeartion
//////////////////////////////////////////////////////////////////////////////////

/* branch target adder in_a selector */
mux_2x1 mux_target_base (
  .select	(EX_jump[0]),
  .in1		(EX_PC),											// pc
  .in2		({EX_rs1_value[31:1], 1'b0}),	// rs1

  .out		(EX_target_base)
);


/* branch target adder */
adder m_branch_target_adder(
  .in_a   (EX_target_base),
  .in_b   (EX_imm),

  .result (EX_target)
);


/* branch taken checker */
branch_control m_branch_control(
  .branch (EX_branch),
  .check  (EX_check),
  
  .taken  (EX_taken)
);

///////////////////////////////////////////////////////////////////////////////////

/* forward to EX/MEM stage registers */
exmem_reg m_exmem_reg(
  .clk            	(clk),
	.ex_pc						(EX_PC),
  .ex_pc_plus_4   	(EX_pc_plus_4),
  .ex_pc_target   	(EX_target),
  .ex_taken       	(EX_taken),
	.ex_branch				(EX_branch),
  .ex_jump        	(EX_jump),
  .ex_memread     	(EX_mem_read),
  .ex_memwrite    	(EX_mem_write),
  .ex_memtoreg    	(EX_mem_to_reg),
  .ex_regwrite    	(EX_reg_write),
  .ex_alu_result  	(EX_alu_result),
  .ex_writedata   	(EX_rs2_value),
  .ex_funct3      	(EX_funct3),
  .ex_rd          	(EX_rd),
	.ex_target_fetch	(EX_target_fetch),
	.ex_imm						(EX_imm),
	.ex_pc_plus_imm		(EX_pc_plus_imm),
	.ex_utype					(EX_utype),
  .flush          	(flush),
  
	.mem_pc						(MEM_PC),
  .mem_pc_plus_4  	(MEM_pc_plus_4),
  .mem_pc_target  	(MEM_target),
  .mem_taken      	(MEM_taken),
	.mem_branch				(MEM_branch),
  .mem_jump       	(MEM_jump),
  .mem_memread    	(MEM_mem_read),
  .mem_memwrite   	(MEM_mem_write),
  .mem_memtoreg   	(MEM_mem_to_reg),
  .mem_regwrite   	(MEM_reg_write),
  .mem_alu_result 	(MEM_alu_result),
  .mem_writedata  	(MEM_rs2_value),
  .mem_funct3     	(MEM_funct3),
  .mem_rd        		(MEM_rd),
	.mem_target_fetch	(MEM_target_fetch),
	.mem_imm					(MEM_imm),
	.mem_pc_plus_imm	(MEM_pc_plus_imm),
	.mem_utype				(MEM_utype)
);


//////////////////////////////////////////////////////////////////////////////////
// Memory (MEM) 
//////////////////////////////////////////////////////////////////////////////////

/* m_data_memory : main memory module */
data_memory m_data_memory(
  .clk         (clk),
  .address     (MEM_alu_result),
  .write_data  (MEM_rs2_value),
  .mem_read    (MEM_mem_read),
  .mem_write   (MEM_mem_write),
  .maskmode    (MEM_funct3[1:0]),
  .sext        (MEM_funct3[2]),

  .read_data   (MEM_mem_readdata)
);

/* forward to MEM/WB stage registers */
memwb_reg m_memwb_reg(
  .clk            	(clk),
  .mem_pc_plus_4  	(MEM_pc_plus_4),
  .mem_jump       	(MEM_jump),
  .mem_memtoreg   	(MEM_mem_to_reg),
  .mem_regwrite   	(MEM_reg_write),
  .mem_readdata   	(MEM_mem_readdata),
  .mem_alu_result 	(MEM_alu_result),
  .mem_rd         	(MEM_rd),
	.mem_imm					(MEM_imm),
	.mem_pc_plus_imm	(MEM_pc_plus_imm),
	.mem_utype				(MEM_utype),

  .wb_pc_plus_4   (WB_pc_plus_4),
  .wb_jump        (WB_jump),
  .wb_memtoreg    (WB_mem_to_reg),
  .wb_regwrite    (WB_reg_write),
  .wb_readdata    (WB_mem_readdata),
  .wb_alu_result  (WB_alu_result),
  .wb_rd          (WB_rd),
	.wb_imm					(WB_imm),
	.wb_pc_plus_imm	(WB_pc_plus_imm),
	.wb_utype				(WB_utype)
);

//////////////////////////////////////////////////////////////////////////////////
// Write Back (WB) 
//////////////////////////////////////////////////////////////////////////////////

/* u-type writeback data selector */
mux_2x1 mux_writeback_utype (
  .select	(WB_utype[0]),
  .in1		(WB_imm),					// lui (imm)
  .in2		(WB_pc_plus_imm),	// auipc (pc+imm)

  .out		(WB_writedata_for_utype)
);


/* writeback selector */
mux_4x1 mux_writeback_jump (
	.select	({(WB_utype[1] | WB_jump[1]), (WB_utype[1] | WB_mem_to_reg)}),
	.in1		(WB_alu_result),
	.in2		(WB_mem_readdata),
	.in3		(WB_pc_plus_4),
	.in4		(WB_writedata_for_utype),

	.out		(WB_writedata)
);

endmodule
