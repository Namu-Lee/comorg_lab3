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

///////////////////////////////////////////////////////////////////////////////
// TODO:  Declare all wires / registers that are needed
///////////////////////////////////////////////////////////////////////////////
// e.g., wire [DATA_WIDTH-1:0] if_pc_plus_4;
// 1) Pipeline registers (wires to / from pipeline register modules)
// 2) In / Out ports for other modules
// 3) Additional wires for multiplexers or other mdoules you instantiate

///////////////////////////////////////////////////////////////////////////////
// Instruction Fetch (IF)
///////////////////////////////////////////////////////////////////////////////

reg [DATA_WIDTH-1:0] PC;    // program counter (32 bits)

wire [DATA_WIDTH-1:0] NEXT_PC;

wire [DATA_WIDTH-1:0] IF_pc_plus_4;

wire stall;

/* m_next_pc_adder */
adder m_pc_plus_4_adder(
  .in_a   (PC),
  .in_b   (32'd4),

  .result (IF_pc_plus_4)
);

always @(posedge clk) begin
  if (rstn == 1'b0) begin
    PC <= 32'h00000000;
  end
  else PC <= NEXT_PC;
end

wire [DATA_WIDTH-1:0] IF_inst;

/* instruction: read current instruction from inst mem */
instruction_memory m_instruction_memory(
  .address    (PC),

  .instruction(IF_inst)
);

wire [DATA_WIDTH-1:0] ID_PC;
wire [DATA_WIDTH-1:0] ID_pc_plus_4;
wire [DATA_WIDTH-1:0] ID_inst;
wire flush;

/* forward to IF/ID stage registers */
ifid_reg m_ifid_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .if_PC          (PC),
  .if_pc_plus_4   (IF_pc_plus_4),
  .if_instruction (IF_inst),
  .flush (flush),
  .stall (stall),

  .id_PC          (ID_PC),
  .id_pc_plus_4   (ID_pc_plus_4),
  .id_instruction (ID_inst)
);


//////////////////////////////////////////////////////////////////////////////////
// Instruction Decode (ID)
//////////////////////////////////////////////////////////////////////////////////

wire MEM_taken, EX_taken, EX_reg_write;
wire [4:0] EX_rd;
wire [6:0] EX_opcode;

/* m_hazard: hazard detection unit */
hazard m_hazard(
  // TODO: implement hazard detection unit & do wiring
  .taken (MEM_taken),
  .ID_rs1 (ID_inst[19:15]),
  .ID_rs2 (ID_inst[24:20]),
  .ID_opcode (ID_inst[6:0]),
  .EX_rd (EX_rd),
  .EX_reg_write (EX_reg_write),
  .EX_opcode (EX_opcode),
				
  .flush (flush),
  .stall (stall)
);

wire ID_branch_tmp, ID_alu_src_tmp, ID_mem_read_tmp, ID_mem_to_reg_tmp, ID_mem_write_tmp, ID_reg_write_tmp;
wire [1:0] ID_jump_tmp, ID_alu_op_tmp;
wire ID_branch, ID_alu_src, ID_mem_read, ID_mem_to_reg, ID_mem_write, ID_reg_write;
wire [1:0] ID_jump, ID_alu_op;

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
  .reg_write  (ID_reg_write)
);

wire [DATA_WIDTH-1:0] ID_imm;

/* m_imm_generator: immediate generator */
immediate_generator m_immediate_generator(
  .instruction(ID_inst),

  .sextimm    (ID_imm)
);

wire [DATA_WIDTH-1:0] WB_writedata, ID_readdata1, ID_readdata2;
wire [4:0] WB_rd;
wire WB_reg_write;

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

wire [DATA_WIDTH-1:0] EX_PC, EX_pc_plus_4, EX_imm, EX_readdata1, EX_readdata2;
wire EX_branch, EX_alu_src, EX_mem_read, EX_mem_write, EX_mem_to_reg;
wire [1:0] EX_jump, EX_alu_op;
wire [6:0] EX_funct7;
wire [2:0] EX_funct3;
wire [4:0] EX_rs1, EX_rs2;

/* forward to ID/EX stage registers */
idex_reg m_idex_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk          (clk),
  .id_PC        (ID_PC),
  .id_pc_plus_4 (ID_pc_plus_4),
  .id_jump      (ID_jump),
  .id_branch    (ID_branch),
  .id_aluop     (ID_alu_op),
  .id_alusrc    (ID_alu_src),
  .id_memread   (ID_mem_read),
  .id_memwrite  (ID_mem_write),
  .id_memtoreg  (ID_mem_to_reg),
  .id_regwrite  (ID_reg_write),
  .id_sextimm   (ID_imm),
  .id_funct7    (ID_inst[31:25]),
  .id_funct3    (ID_inst[14:12]),
  .id_readdata1 (ID_readdata1),
  .id_readdata2 (ID_readdata2),
  .id_rs1       (ID_inst[19:15]),
  .id_rs2       (ID_inst[24:20]),
  .id_rd        (ID_inst[11:7]),
  .id_opcode    (ID_inst[6:0]),
  .flush (flush),
  .stall (stall),

  .ex_PC        (EX_PC),
  .ex_pc_plus_4 (EX_pc_plus_4),
  .ex_jump      (EX_jump),
  .ex_branch    (EX_branch),
  .ex_aluop     (EX_alu_op),
  .ex_alusrc    (EX_alu_src),
  .ex_memread   (EX_mem_read),
  .ex_memwrite  (EX_mem_write),
  .ex_memtoreg  (EX_mem_to_reg),
  .ex_regwrite  (EX_reg_write),
  .ex_sextimm   (EX_imm),
  .ex_funct7    (EX_funct7),
  .ex_funct3    (EX_funct3),
  .ex_readdata1 (EX_readdata1),
  .ex_readdata2 (EX_readdata2),
  .ex_rs1       (EX_rs1),
  .ex_rs2       (EX_rs2),
  .ex_rd        (EX_rd),
  .ex_opcode    (EX_opcode)
);

//////////////////////////////////////////////////////////////////////////////////
// Execute (EX) 
//////////////////////////////////////////////////////////////////////////////////

wire [DATA_WIDTH-1:0] EX_target_base;

/* input selector for 'm_branch_target_adder': PC=imm+PC for direct(=branch, jal), PC=imm+rs1 (LSB=0) for indirect(=jalr) */
mux_2x1 mux_target_base_selector(
  .select(EX_jump[0]), //jump = 00 for conditional, 10 for jal, 11 for jalr
  .in1(EX_PC),
  .in2({EX_readdata1[31:1], 1'b0}),

  .out(EX_target_base)
);

wire [DATA_WIDTH-1:0] EX_target;

/* m_branch_target_adder: PC + imm for branch address */
adder m_branch_target_adder(
  .in_a   (EX_target_base),
  .in_b   (EX_imm),

  .result (EX_target)
);

wire EX_check;

/* m_branch_control : checks T/NT */
branch_control m_branch_control(
  .branch (EX_branch),
  .check  (EX_check),
  
  .taken  (EX_taken)
);

wire [3:0] EX_alu_func;

/* alu control : generates alu_func signal */
alu_control m_alu_control(
  .alu_op   (EX_alu_op),
  .funct7   (EX_funct7),
  .funct3   (EX_funct3),

  .alu_func (EX_alu_func)
);

wire [DATA_WIDTH-1:0] EX_alu_in_a, EX_alu_in_b_stage1, EX_alu_in_b, EX_alu_result, MEM_alu_result;
wire [1:0] EX_fwd_a, EX_fwd_b; //2-bit forwarding signal : 00 not forwarding, 01 from MEM, 10 from WB

/* alu input_1 selection */
mux_3x1 mux_alu_in_1(
  .select(EX_fwd_a),
  .in1(EX_readdata1), //00
  .in2(MEM_alu_result), //01
  .in3(WB_writedata), //10

  .out(EX_alu_in_a)
);

/* alu input_2 selection */
mux_4x1 mux_alu_in_2(
  .select({2{EX_alu_src}} | EX_fwd_b),
  .in1(EX_readdata2),
  .in2(MEM_alu_result),
  .in3(WB_writedata),
  .in4(EX_imm),

  .out(EX_alu_in_b)
);

/* m_alu */
alu m_alu(
  .alu_func (EX_alu_func),
  .in_a     (EX_alu_in_a), 
  .in_b     (EX_alu_in_b), 

  .result   (EX_alu_result),
  .check    (EX_check)
);

wire [4:0] MEM_rd;
wire MEM_reg_write;

forwarding m_forwarding(
  // TODO: implement forwarding unit & do wiring
  .EX_rs1(EX_rs1),
  .EX_rs2(EX_rs2),
  .MEM_rd(MEM_rd),
  .WB_rd(WB_rd),
  .MEM_reg_write(MEM_reg_write),
  .WB_reg_write(WB_reg_write),

  .fwd_a(EX_fwd_a),
  .fwd_b(EX_fwd_b)
);



wire [DATA_WIDTH-1:0] EX_mem_writedata, MEM_pc_plus_4, MEM_target, MEM_mem_writedata;
wire MEM_mem_read, MEM_mem_write, MEM_mem_to_reg;
wire [1:0] MEM_jump;
wire [2:0] MEM_funct3;
/* forwarding rs2 from MEM, WB (rs2: mem write data) */
mux_3x1 mem_writedata_select (
  .select (EX_fwd_b),
  .in1 (EX_readdata2),
  .in2 (MEM_alu_result),
  .in3 (WB_writedata),

  .out (EX_mem_writedata)
);

/* forward to EX/MEM stage registers */
exmem_reg m_exmem_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .ex_pc_plus_4   (EX_pc_plus_4),
  .ex_pc_target   (EX_target),
  .ex_taken       (EX_taken), 
  .ex_jump        (EX_jump),
  .ex_memread     (EX_mem_read),
  .ex_memwrite    (EX_mem_write),
  .ex_memtoreg    (EX_mem_to_reg),
  .ex_regwrite    (EX_reg_write),
  .ex_alu_result  (EX_alu_result),
  .ex_writedata   (EX_mem_writedata),
  .ex_funct3      (EX_funct3),
  .ex_rd          (EX_rd),
  .flush          (flush),
  
  .mem_pc_plus_4  (MEM_pc_plus_4),
  .mem_pc_target  (MEM_target),
  .mem_taken      (MEM_taken), 
  .mem_jump       (MEM_jump),
  .mem_memread    (MEM_mem_read),
  .mem_memwrite   (MEM_mem_write),
  .mem_memtoreg   (MEM_mem_to_reg),
  .mem_regwrite   (MEM_reg_write),
  .mem_alu_result (MEM_alu_result),
  .mem_writedata  (MEM_mem_writedata),
  .mem_funct3     (MEM_funct3),
  .mem_rd         (MEM_rd)
);


//////////////////////////////////////////////////////////////////////////////////
// Memory (MEM) 
//////////////////////////////////////////////////////////////////////////////////

/* PC source selector : NEXT_PC=target if taken, pc+4 if not taken, pc if stall*/
mux_4x1 mux_PC_source(
  .select({(~flush & stall),MEM_taken}), //flush has priority
  .in1(IF_pc_plus_4),
  .in2(MEM_target),
  .in3(PC),
  .in4(PC),

  .out(NEXT_PC)
);


wire [DATA_WIDTH-1:0] MEM_mem_readdata;

/* m_data_memory : main memory module */
data_memory m_data_memory(
  .clk         (clk),
  .address     (MEM_alu_result),
  .write_data  (MEM_mem_writedata),
  .mem_read    (MEM_mem_read),
  .mem_write   (MEM_mem_write),
  .maskmode    (MEM_funct3[1:0]),
  .sext        (MEM_funct3[2]),

  .read_data   (MEM_mem_readdata)
);

wire [DATA_WIDTH-1:0] WB_pc_plus_4, WB_mem_readdata, WB_alu_result;
wire [1:0] WB_jump;
wire WB_mem_to_reg;

/* forward to MEM/WB stage registers */
memwb_reg m_memwb_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .mem_pc_plus_4  (MEM_pc_plus_4),
  .mem_jump       (MEM_jump),
  .mem_memtoreg   (MEM_mem_to_reg),
  .mem_regwrite   (MEM_reg_write),
  .mem_readdata   (MEM_mem_readdata),
  .mem_alu_result (MEM_alu_result),
  .mem_rd         (MEM_rd),

  .wb_pc_plus_4   (WB_pc_plus_4),
  .wb_jump        (WB_jump),
  .wb_memtoreg    (WB_mem_to_reg),
  .wb_regwrite    (WB_reg_write),
  .wb_readdata    (WB_mem_readdata),
  .wb_alu_result  (WB_alu_result),
  .wb_rd          (WB_rd)
);

//////////////////////////////////////////////////////////////////////////////////
// Write Back (WB) 
//////////////////////////////////////////////////////////////////////////////////

mux_3x1 mux_WriteBack(
  .select({WB_jump[1],WB_mem_to_reg}),
  .in1(WB_alu_result),
  .in2(WB_mem_readdata),	
  .in3(WB_pc_plus_4),

  .out(WB_writedata)
);

endmodule
